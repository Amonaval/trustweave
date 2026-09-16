import {parseArgs,readJson,exists,printChecks} from './lib.mjs';
const a=parseArgs();const missionPath=a.mission;const evidencePath=a.evidence;if(!missionPath||!evidencePath){console.error('Usage: --mission <mission.json> --evidence <evidence.json>');process.exit(2)}
const m=readJson(missionPath),q=readJson('governance/quality-policy.json'),c=[];const ok=(n,v,d='')=>c.push([n,!!v,d]);ok('evidence exists',exists(evidencePath),evidencePath);if(!exists(evidencePath)){printChecks('Evidence gate',c);process.exit(1)}const e=readJson(evidencePath);
ok('evidence mission matches',e.missionId===m.id,`${e.missionId} vs ${m.id}`);ok('candidate id present',typeof e.candidateSha==='string'&&e.candidateSha.length>5,e.candidateSha);
const by=new Map((e.results||[]).map(x=>[x.gate,x]));for(const g of m.gates.filter(x=>!['evidence'].includes(x))){const r=by.get(g);ok(`mandatory gate recorded: ${g}`,Boolean(r),r?.status||'missing');if(r)ok(`mandatory gate not failed: ${g}`,!q.releasePolicy.blockingStatuses.includes(r.status),r.status)}
if(m.runtimeEvidenceRequired){const runtime=(e.results||[]).filter(x=>x.kind==='runtime');ok('runtime proof present',runtime.some(x=>x.status==='PASS'),runtime.map(x=>`${x.gate}:${x.status}`).join(', '))}
printChecks('Evidence gate',c);
