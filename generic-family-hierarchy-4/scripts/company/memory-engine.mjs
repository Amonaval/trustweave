import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const tokenize=value=>[...new Set(String(value).toLowerCase().match(/[a-z0-9-]{3,}/g)||[])];
const idFor=(source,index)=>crypto.createHash('sha256').update(`${source}:${index}`).digest('hex').slice(0,16);

export function buildMemory({root=process.cwd(),out='company-state/memory.json'}={}){
  const records=[];
  const add=(kind,source,title,body,metadata={})=>records.push({id:idFor(source,records.length),kind,source,title,body,terms:tokenize(`${title} ${body}`),metadata});
  const opportunities=path.join(root,'company-state/opportunities.json');
  if(fs.existsSync(opportunities))for(const item of JSON.parse(fs.readFileSync(opportunities,'utf8')).opportunities||[])add('user-evidence','company-state/opportunities.json',item.title,JSON.stringify(item.evidence),{rank:item.rank,persona:item.sourcePersona});
  const missionRoot=path.join(root,'missions/mission-003/m3-c');
  if(fs.existsSync(missionRoot))for(const dir of fs.readdirSync(missionRoot).filter(x=>/^c\d\d$/.test(x)).sort()){
    const missionFile=path.join(missionRoot,dir,'mission.json'),evidenceFile=path.join(missionRoot,dir,'EVIDENCE.md'),reviewFile=path.join(missionRoot,dir,'review.json');
    if(fs.existsSync(missionFile)){const m=JSON.parse(fs.readFileSync(missionFile,'utf8'));add('mission-outcome',path.relative(root,missionFile),m.title,`${m.state}: ${(m.acceptance||[]).join('; ')}`,{missionId:m.id,state:m.state});}
    if(fs.existsSync(evidenceFile))add('evidence',path.relative(root,evidenceFile),`${dir.toUpperCase()} evidence`,fs.readFileSync(evidenceFile,'utf8'));
    if(fs.existsSync(reviewFile)){const r=JSON.parse(fs.readFileSync(reviewFile,'utf8'));add('risk-review',path.relative(root,reviewFile),`${dir.toUpperCase()} independent review`,`${r.status}; blockers=${r.blockingFindings}; ${(r.findings||[]).map(x=>`${x.dimension}:${x.severity}:${x.summary}`).join('; ')}`);}
  }
  const index={version:1,generatedAt:new Date().toISOString(),recordCount:records.length,records};
  const target=path.resolve(root,out);fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,JSON.stringify(index,null,2)+'\n');return index;
}

export function searchMemory(index,query,{limit=5}={}){
  const terms=tokenize(query);return index.records.map(record=>({record,score:terms.reduce((score,term)=>score+(record.terms.includes(term)?3:record.body.toLowerCase().includes(term)?1:0),0)})).filter(x=>x.score>0).sort((a,b)=>b.score-a.score||a.record.id.localeCompare(b.record.id)).slice(0,limit);
}

export function planWithMemory(index,intent){
  const matches=searchMemory(index,intent,{limit:6});return {intent,generatedAt:new Date().toISOString(),lessons:matches.map(x=>({id:x.record.id,kind:x.record.kind,title:x.record.title,source:x.record.source,score:x.score})),appliedConstraints:[...new Set(matches.flatMap(x=>x.record.kind==='user-evidence'?['minimum-44px-action-targets']:x.record.body.toLowerCase().includes('rollback')?['preview-smoke-rollback-before-release']:[]))],memoryApplied:matches.length>0};
}
