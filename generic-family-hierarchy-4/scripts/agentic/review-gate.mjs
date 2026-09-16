import {parseArgs,readJson,exists,printChecks} from './lib.mjs';
const a=parseArgs();const mission=a.mission||'missions/mission-003/m3-b6-e1/mission.json';const m=readJson(mission);const review=m.reviewArtifact||`${mission.slice(0,mission.lastIndexOf('/'))}/review.json`;const c=[];const ok=(n,v,d='')=>c.push([n,!!v,d]);
ok('independent review artifact exists',exists(review),review);
if(exists(review)){const r=readJson(review);ok('review status APPROVED',r.status==='APPROVED',r.status);ok('blocking findings are zero',Number(r.blockingFindings||0)===0,String(r.blockingFindings));ok('reviewer differs from builder',Boolean(r.reviewer&&r.builder&&r.reviewer!==r.builder),`${r.builder||'?'} / ${r.reviewer||'?'}`);ok('review is candidate-bound',Boolean(r.candidateSha),r.candidateSha||'')}
printChecks('Independent review gate',c);
