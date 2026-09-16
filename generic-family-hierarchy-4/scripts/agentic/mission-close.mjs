import {parseArgs,readJson,writeJson,exists,printChecks,resolveMissionPath} from './lib.mjs';
const a=parseArgs();const mission=resolveMissionPath(a.mission);const evidence=a.evidence;const m=readJson(mission),c=[];const ok=(n,v,d='')=>c.push([n,!!v,d]);let e=null;
ok('evidence path supplied',Boolean(evidence),evidence||'');
if(evidence&&exists(evidence)){
  e=readJson(evidence);
  ok('evidence mission matches',e.missionId===m.id,`${e.missionId||'?'} vs ${m.id}`);
  ok('no failed gates',e.summary?.fail===0,String(e.summary?.fail));
  ok('no blocked gates',e.summary?.blocked===0,String(e.summary?.blocked));
  const by=new Map((e.results||[]).map(x=>[x.gate,x]));
  const mandatory=(m.gates||[]).filter(g=>g!=='evidence');
  const missing=mandatory.filter(g=>!by.has(g));
  const notPass=mandatory.filter(g=>by.has(g)&&by.get(g)?.status!=='PASS');
  ok('all mandatory gates recorded',missing.length===0,missing.join(', '));
  ok('all mandatory gates PASS',notPass.length===0,notPass.map(g=>`${g}:${by.get(g)?.status}`).join(', '));
  ok('runtime pass exists when required',!m.runtimeEvidenceRequired||(e.results||[]).some(x=>x.kind==='runtime'&&x.status==='PASS'));
}else if(evidence)ok('evidence exists',false,evidence);
const review=m.reviewArtifact;
ok('independent review artifact declared',Boolean(review),review||'');
ok('independent review artifact exists',Boolean(review&&exists(review)),review||'');
if(review&&exists(review)){
  const r=readJson(review);
  ok('independent review APPROVED',r.status==='APPROVED',r.status||'');
  ok('blocking review findings are zero',Number.isInteger(r.blockingFindings)&&r.blockingFindings===0,String(r.blockingFindings));
  ok('reviewer differs from builder',Boolean(r.reviewer&&r.builder&&r.reviewer!==r.builder),`${r.builder||'?'} / ${r.reviewer||'?'}`);
  ok('review is candidate-bound',Boolean(r.candidateSha),r.candidateSha||'');
  if(e?.candidateSha&&r.candidateSha)ok('review candidate matches evidence',r.candidateSha===e.candidateSha,`${r.candidateSha} vs ${e.candidateSha}`);
}
const pass=printChecks('Mission close gate',c);if(pass&&a.apply){m.state='CLOSE';m.candidateSha=e?.candidateSha||m.candidateSha;writeJson(mission,m);console.log(`Mission ${m.id} marked CLOSE.`)}
