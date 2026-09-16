import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {ROOT,parseArgs,missionRegistry,resolveMissionPath,readJson,exists} from './lib.mjs';

const a=parseArgs();const cmd=a._[0]||'status';const registry=missionRegistry();
const missionPath=()=>resolveMissionPath(a.mission||a._[1]||null);
const run=(script,args=[])=>{const r=spawnSync(process.execPath,[path.resolve(ROOT,script),...args],{cwd:ROOT,stdio:'inherit',env:process.env});process.exit(r.status??1)};
function latestEvidence(id){const root=path.resolve(ROOT,'release-evidence',id);if(!fs.existsSync(root))return null;const candidates=[];for(const entry of fs.readdirSync(root,{withFileTypes:true})){if(entry.isDirectory()){const f=path.join(root,entry.name,'evidence.json');if(fs.existsSync(f))candidates.push(f)}}return candidates.sort().at(-1)||null}

if(cmd==='list'){
  for(const m of registry.missions||[])console.log(`${m.id===registry.activeId?'*':' '} ${m.id.padEnd(12)} ${String(m.state||'').padEnd(10)} ${m.title||''}\n    ${m.path}`);
  process.exit(0);
}
if(cmd==='show'||cmd==='status'){
  const p=missionPath(),m=readJson(p);console.log(JSON.stringify({active:m.id===registry.activeId,id:m.id,title:m.title,state:m.state,risk:m.risk,path:p,humanInterventionBudget:m.humanInterventionBudget,gates:m.gates,latestEvidence:latestEvidence(m.id)},null,2));process.exit(0);
}
if(cmd==='run'){const p=missionPath();run('scripts/agentic/run-mission.mjs',['--mission',p,'--profile',a.profile||'source'])}
if(cmd==='check'){const p=missionPath();run('scripts/agentic/mission-contract-gate.mjs',['--mission',p])}
if(cmd==='scope'){const p=missionPath();run('scripts/agentic/scope-gate.mjs',['--mission',p])}
if(cmd==='preflight'){const p=missionPath();run('scripts/agentic/runtime-preflight.mjs',['--mission',p])}
if(cmd==='worktree'){const p=missionPath();run('scripts/agentic/mission-worktree.mjs',['--mission',p])}
if(cmd==='review'){const p=missionPath();run('scripts/agentic/review-gate.mjs',['--mission',p])}
if(cmd==='close'){const p=missionPath();if(!a.evidence){console.error('close requires --evidence <path>');process.exit(2)};const args=['--mission',p,'--evidence',a.evidence];if(a.apply)args.push('--apply');run('scripts/agentic/mission-close.mjs',args)}
console.error('Usage: mission-cli <list|status|show|check|run|scope|preflight|worktree|review|close> [mission-id|path] [--profile source|static|runtime]');process.exit(2);
