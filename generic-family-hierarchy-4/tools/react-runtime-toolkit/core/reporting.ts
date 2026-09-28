import type {Finding,RuntimeSnapshot} from './types';

export type PinpointIssue={
  id:string; component:string; filePath:string; lineNumber:number|null;
  issueType:string; severity:'info'|'warning'|'critical'; details:string;
  recommendation:string; evidence:string[]; callStacks:string[];
  relatedComponents:string[]; readHint:string; claudePrompt:string;
};

export type InvestigationReport=RuntimeSnapshot&{
  reportVersion:1; reportTime:string; sessionId:string; note:string;
  health:ReturnType<typeof health>; findings:Finding[]; pinpointIssues:PinpointIssue[];
};

export function health(s:RuntimeSnapshot,findings:Finding[]){
  const dom=s.dom.at(-1), mem=s.memory.at(-1);
  const failed=s.network.filter(x=>x.ok===false).length;
  const slow=s.network.filter(x=>x.durationMs>=1000).length;
  const expensive=s.commits.flatMap(c=>c.components).filter(x=>(x.actualDurationMs||0)>=50).length;
  const churn=s.commits.flatMap(c=>c.components).reduce((n,x)=>n+x.referentialChurn.length,0);
  const blocking=s.loafs.filter(x=>x.blockingDurationMs>=100).length+s.longTasks.filter(x=>x.durationMs>=100).length;
  const critical=findings.filter(x=>x.severity==='critical').length;
  const dimensions=[
    dimension('Stability',100-critical*25-Math.min(s.errors.length*12,40),s.errors.length+' runtime/resource error(s)'),
    dimension('Responsiveness',100-Math.min(blocking*12,50)-((s.vitals.inpMs||0)>=500?30:0),s.loafs.length+' LoAF(s), '+s.longTasks.length+' long task(s)'),
    dimension('React',100-Math.min(expensive*8,40)-Math.min(churn*2,30),expensive+' expensive sample(s), '+churn+' ref-churn signal(s)'),
    dimension('Network',100-Math.min(failed*18,50)-Math.min(slow*5,30),failed+' failed, '+slow+' slow request(s)'),
    dimension('DOM / memory',100-(dom?.nodes>=10000?35:dom?.nodes>=5000?18:0)-Math.min((dom?.detachedSuspects||0)*2,30),(dom?.nodes||0)+' nodes, '+(dom?.detachedSuspects||0)+' detached suspect(s), '+(mem?.jsHeapUsedMB!=null?mem.jsHeapUsedMB+'MB heap':'heap n/a')),
  ];
  const score=Math.max(0,Math.min(100,Math.round(dimensions.reduce((n,x)=>n+x.score,0)/dimensions.length)));
  return {score,grade:score>=85?'A':score>=70?'B':score>=55?'C':score>=40?'D':'F',dimensions};
}
function dimension(name:string,score:number,summary:string){return{name,score:Math.max(0,Math.min(100,Math.round(score))),summary}}

export function pinpoint(s:RuntimeSnapshot,findings:Finding[]):PinpointIssue[]{
  const out:PinpointIssue[]=[]; let seq=0;
  const add=(x:{component:string;issueType:string;severity:'info'|'warning'|'critical';details:string;recommendation:string;filePath?:string;lineNumber?:number|null;evidence?:string[];callStacks?:string[];relatedComponents?:string[]})=>{
    const stack=(x.callStacks||[])[0]||'';
    const frame=firstFrame(stack);
    const filePath=x.filePath||frame.path||'';
    const lineNumber=x.lineNumber??frame.line??lineFrom(filePath);
    const evidence=(x.evidence||[]).filter(Boolean);
    const relatedComponents=x.relatedComponents||[];
    const readHint=filePath?(lineNumber?'Read '+filePath+' lines '+Math.max(1,lineNumber-12)+' to '+(lineNumber+12)+' for context':'Read '+filePath):'Use runtime evidence and the call stack to locate the source';
    const claudePrompt=[
      'Investigate and fix a '+x.severity+' '+x.issueType+' issue in '+x.component+'.',
      filePath?'File: '+filePath+(lineNumber?' around line '+lineNumber:'')+'.':'',
      x.details.split('\n')[0],
      evidence.length?'Evidence: '+evidence.slice(0,3).join(' | ')+'.':'',
      'Recommendation: '+x.recommendation,
      relatedComponents.length?'Related components: '+relatedComponents.join(', ')+'.':'',
      'Verify the runtime hypothesis against source code before changing behavior. Make the smallest safe fix and explain how to rerun the same flow to prove improvement.'
    ].filter(Boolean).join(' ');
    out.push({id:'issue-'+(++seq),component:x.component,filePath,lineNumber,issueType:x.issueType,severity:x.severity,details:x.details,recommendation:x.recommendation,evidence,callStacks:x.callStacks||[],relatedComponents,readHint,claudePrompt});
  };

  const samples=s.commits.flatMap(c=>c.components.map(x=>({c,x})));
  const groups=new Map<string,typeof samples>();
  for(const sample of samples){const a=groups.get(sample.x.name)||[];a.push(sample);groups.set(sample.x.name,a)}
  for(const [name,a] of groups){
    const slow=a.filter(q=>(q.x.actualDurationMs||0)>=50);
    if(slow.length){
      const worst=slow.reduce((p,q)=>(p.x.actualDurationMs||0)>(q.x.actualDurationMs||0)?p:q);
      add({component:name,filePath:worst.x.source,issueType:'expensive-react-update',severity:(worst.x.actualDurationMs||0)>=150?'critical':'warning',details:slow.length+'/'+a.length+' changed samples took >=50ms; worst '+(worst.x.actualDurationMs||0).toFixed(1)+'ms.',recommendation:'Inspect synchronous render work, large lists, derived calculations and expensive descendants.',evidence:['worst '+(worst.x.actualDurationMs||0).toFixed(1)+'ms','reason '+worst.x.reason],relatedComponents:worst.c.components.map(z=>z.name).filter(z=>z!==name).slice(0,8)});
    }
    const counts=new Map<string,number>();
    for(const q of a)for(const prop of q.x.referentialChurn)counts.set(prop,(counts.get(prop)||0)+1);
    for(const [prop,count] of counts)if(count>=4)add({component:name,filePath:a.at(-1)?.x.source,issueType:'referential-prop-churn',severity:'warning',details:'Prop "'+prop+'" changed reference '+count+' times while remaining shallow-equivalent.',recommendation:'Stabilize this prop only if runtime evidence shows it causes measurable downstream work.',evidence:[count+' shallow-equivalent reference changes']});
  }

  for(const action of s.interactions){
    const commits=s.commits.filter(c=>c.interactionId===action.id);
    if(commits.length>=5){
      const names=topComponents(commits);
      add({component:names[0]||'React tree',filePath:firstSource(commits,names[0]),issueType:'interaction-commit-burst',severity:commits.length>=10?'critical':'warning',details:commits.length+' React commits followed one '+action.type+' on '+action.target+'.',recommendation:'Trace the first state change and look for cascading effects, duplicated effects/subscriptions, or state that can be derived or batched.',evidence:[commits.length+' commits',commits.reduce((n,c)=>n+c.changedCount,0)+' changed summaries',action.type+' '+action.target],relatedComponents:names.slice(1,8)});
    }
  }

  for(const n of s.network.filter(x=>x.ok===false).slice(-8))add({component:'Network',issueType:'failed-request',severity:'critical',details:n.method+' '+n.url+' failed with '+(n.status??'network error')+' after '+n.durationMs.toFixed(0)+'ms.',recommendation:'Inspect the initiator, authentication/authorization, request payload and backend response.',callStacks:n.requestStack?[n.requestStack]:[],evidence:[String(n.status??'ERR'),n.durationMs.toFixed(0)+'ms']});

  for(const f of findings)if(f.severity!=='info'&&!out.some(i=>i.issueType===slug(f.title)))add({component:f.category,issueType:slug(f.title),severity:f.severity,details:f.detail,recommendation:f.recommendation,evidence:[f.evidence]});
  return out;
}

export function report(s:RuntimeSnapshot,findings:Finding[],note='',sessionId=session()):InvestigationReport{
  return {...s,reportVersion:1,reportTime:new Date().toISOString(),sessionId,note,health:health(s,findings),findings,pinpointIssues:pinpoint(s,findings)};
}

export function fixTable(r:InvestigationReport){
  return r.pinpointIssues.map(i=>({id:i.id,component:i.component,filePath:i.filePath,issueType:i.issueType,severity:i.severity,details:i.details,recommendation:i.recommendation,lineNumber:i.lineNumber,readHint:i.readHint,relatedComponents:i.relatedComponents,claudePrompt:i.claudePrompt,filteredCallStack:i.callStacks[0]?filterStack(i.callStacks[0]):null,callStack:i.callStacks[0]||null,evidence:i.evidence,reportedAt:r.reportTime,sessionId:r.sessionId}));
}

export function claudePrompt(r:InvestigationReport){
  return ['You are investigating a React runtime issue from a captured evidence report. Runtime heuristics are observations, not source-code proof.','For every Fix Table entry, use filePath/lineNumber/readHint and call-stack evidence to inspect the smallest relevant source area. Verify causality, distinguish root cause from downstream symptoms, make the smallest safe fix, and state how the same flow should be rerun to confirm improvement.','Session: '+r.sessionId,'URL: '+String(r.environment.url||''),'Heuristic health: '+r.health.grade+' '+r.health.score+'/100','','FIX TABLE:',JSON.stringify(fixTable(r),null,2)].join('\n');
}

export function html(r:InvestigationReport){
  const e=esc;
  const issues=r.pinpointIssues.map(i=>'<div class="issue"><b>'+e(i.severity.toUpperCase())+' · '+e(i.component)+' · '+e(i.issueType)+'</b>'+(i.filePath?'<div class="path">'+e(i.filePath)+(i.lineNumber?':'+i.lineNumber:'')+'</div>':'')+'<p>'+e(i.details)+'</p><div class="rec">💡 '+e(i.recommendation)+'</div><p>'+i.evidence.map(x=>'<code>'+e(x)+'</code>').join(' ')+'</p>'+(i.callStacks[0]?'<details><summary>Call stack</summary><pre>'+e(filterStack(i.callStacks[0]))+'</pre></details>':'')+'<details><summary>Claude prompt</summary><pre>'+e(i.claudePrompt)+'</pre></details></div>').join('')||'<p>None</p>';
  const findings=r.findings.map(f=>'<div class="finding '+f.severity+'"><b>'+e(f.category)+' · '+e(f.title)+'</b><span>'+e(f.detail)+'</span><code>'+e(f.evidence)+'</code><i>💡 '+e(f.recommendation)+'</i></div>').join('')||'<p>None</p>';
  const componentRows=r.commits.flatMap(c=>c.components.map(x=>[x.name,x.reason,(x.actualDurationMs||0).toFixed(1)+'ms',x.source||''])).slice(-200).reverse();
  const networkRows=r.network.slice(-150).reverse().map(x=>[x.method,x.url,String(x.status??'ERR'),x.durationMs.toFixed(0)+'ms']);
  return '<!doctype html><html><head><meta charset="utf-8"><title>React Runtime Investigation</title><style>'+CSS+'</style></head><body><h1>⚛ React Runtime Investigation Report</h1><div class="meta">'+e(r.sessionId)+' · '+e(r.reportTime)+' · '+e(String(r.environment.url||''))+'</div>'+(r.note?'<div class="note">📝 '+e(r.note)+'</div>':'')+'<div class="health"><b class="grade">'+r.health.grade+'</b><div><strong>'+r.health.score+'/100</strong><small>Heuristic Page Health</small></div>'+r.health.dimensions.map(x=>'<div class="dim"><b>'+e(x.name)+' '+x.score+'</b><small>'+e(x.summary)+'</small></div>').join('')+'</div><h2>Findings</h2>'+findings+'<h2>Pinpoint Issues</h2>'+issues+section('React component evidence',table(['Component','Reason','Duration','Source'],componentRows))+section('Network evidence',table(['Method','URL','Status','Duration'],networkRows))+section('DOM / Memory','<pre>'+e(JSON.stringify({dom:r.dom.at(-1),memory:r.memory.at(-1),timers:r.timers.at(-1)},null,2))+'</pre>')+section('Errors','<pre>'+e(JSON.stringify(r.errors,null,2))+'</pre>')+'<h2>Environment</h2><pre>'+e(JSON.stringify(r.environment,null,2))+'</pre><h2>Raw report</h2><details><summary>Embedded JSON</summary><pre>'+e(JSON.stringify(r,null,2))+'</pre></details><script type="application/json" id="react-runtime-report">'+JSON.stringify(r).replace(/<\//g,'<\\/')+'</script></body></html>';
}

function topComponents(commits:RuntimeSnapshot['commits']){const m=new Map<string,number>();for(const c of commits)for(const x of c.components)m.set(x.name,(m.get(x.name)||0)+1);return[...m.entries()].sort((a,b)=>b[1]-a[1]).map(x=>x[0])}
function firstSource(commits:RuntimeSnapshot['commits'],name?:string){for(const c of commits)for(const x of c.components)if((!name||x.name===name)&&x.source)return x.source;return''}
function firstFrame(stack:string){for(const line of filterStack(stack).split('\n')){const m=line.match(/(?:\(|at\s+)([^()\s]+):(\d+):(\d+)\)?/);if(m)return{path:m[1],line:Number(m[2])}}return{path:'',line:null as number|null}}
function lineFrom(path:string){const m=path.match(/:(\d+)(?::\d+)?$/);return m?Number(m[1]):null}
function filterStack(stack:string){return stack.split('\n').filter(x=>!/(react-runtime-toolkit|node_modules\/react|next\/dist|webpack-internal)/i.test(x)).slice(0,30).join('\n')}
function slug(s:string){return s.toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/(^-|-$)/g,'')}
function session(){return'rrt-'+Date.now().toString(36)+'-'+Math.random().toString(36).slice(2,8)}
function esc(v:any){return String(v??'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;')}
function section(title:string,body:string){return body?'<details open><summary>'+esc(title)+'</summary>'+body+'</details>':''}
function table(headers:string[],rows:any[][]){if(!rows.length)return'';return'<table><tr>'+headers.map(x=>'<th>'+esc(x)+'</th>').join('')+'</tr>'+rows.map(r=>'<tr>'+r.map(x=>'<td>'+esc(x)+'</td>').join('')+'</tr>').join('')+'</table>'}
const CSS='*{box-sizing:border-box}body{font:12px Consolas,monospace;background:#111827;color:#e5e7eb;padding:24px}h1,h2,summary{color:#93c5fd}.meta,small{color:#94a3b8}.note,.rec{padding:8px;background:#10251d;border-radius:6px}.health{display:flex;gap:16px;align-items:center;flex-wrap:wrap;background:#0f172a;padding:14px;border-radius:8px;margin:16px 0}.grade{font-size:50px;color:#a7f3d0}.health strong,.health small,.dim b,.dim small,.finding span,.finding code,.finding i{display:block}.dim{padding-left:12px;border-left:1px solid #334155}.finding,.issue{padding:10px;margin:8px 0;background:#172033;border:1px solid #334155;border-radius:7px}.critical{border-left:3px solid #f87171}.warning{border-left:3px solid #fbbf24}.path{color:#86efac}code{background:#0b1020;padding:3px;margin:3px;display:inline-block}pre{white-space:pre-wrap;overflow:auto;background:#0b1020;padding:10px}table{width:100%;border-collapse:collapse}th,td{text-align:left;border-bottom:1px solid #263247;padding:5px;vertical-align:top;word-break:break-word}';
