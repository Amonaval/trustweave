import fs from 'node:fs';import path from 'node:path';import {execFileSync} from 'node:child_process';import {parseArgs,readJson,treeHash,ROOT,printChecks,resolveMissionPath} from './lib.mjs';
const a=parseArgs();const missionPath=resolveMissionPath(a.mission);const m=readJson(missionPath);const checks=[];const ok=(n,v,d='')=>checks.push([n,!!v,d]);
function globRx(glob){let s=glob.replace(/[.+^${}()|[\]\\]/g,'\\$&');s=s.replaceAll('**','@@ALL@@').replaceAll('*','[^/]*').replaceAll('@@ALL@@','.*');return new RegExp(`^${s}$`)}
const allowed=(m.scope.allowedWrites||[]).map(globRx),forbidden=(m.scope.forbiddenWrites||[]).map(globRx);let changed=[];let mode='protected-hash';
try{const base=m.execution?.baseRef||'main';const committed=execFileSync('git',['diff','--name-only',`${base}...HEAD`],{cwd:ROOT,encoding:'utf8',stdio:['ignore','pipe','ignore']}).trim().split(/\r?\n/).filter(Boolean);const working=execFileSync('git',['status','--porcelain'],{cwd:ROOT,encoding:'utf8',stdio:['ignore','pipe','ignore']}).split(/\r?\n/).filter(Boolean).map(x=>x.slice(3).trim()).filter(Boolean);changed=[...new Set([...committed,...working])];mode='git';}catch{
}
if(mode==='git'){
 const badForbidden=changed.filter(f=>forbidden.some(rx=>rx.test(f)));const outOfScope=changed.filter(f=>!allowed.some(rx=>rx.test(f))&&!f.startsWith('release-evidence/'));
 ok('no forbidden paths changed',badForbidden.length===0,badForbidden.join(', '));ok('all changed files are mission-scoped',outOfScope.length===0,outOfScope.join(', '));console.log(`INFO scope mode=git changed=${changed.length}`);
}else{
 for(const [dir,expected] of Object.entries(m.baseline?.protectedTreeHashes||{})){const actual=treeHash(dir);ok(`protected tree unchanged: ${dir}`,actual===expected,`${actual} vs ${expected}`)}console.log('INFO scope mode=protected-hash (full changed-file scope requires Git; protected trees are still enforced)');
}
printChecks('Mission scope gate',checks);
