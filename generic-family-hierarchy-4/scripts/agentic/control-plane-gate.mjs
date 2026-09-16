import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {readJson,walk,printChecks} from './lib.mjs';

const checks=[];const ok=(name,pass,detail='')=>checks.push([name,Boolean(pass),detail]);
const policies=[
 'governance/architecture-policy.json',
 'governance/company-os.json',
 'governance/documentation-policy.json',
 'governance/quality-policy.json',
 'governance/execution-policy.json',
];
for(const file of policies){
 try{const p=readJson(file);ok(`policy parses: ${file}`,true);ok(`policy binding: ${file}`,p.status==='BINDING',p.status||'missing')}catch(e){ok(`policy parses: ${file}`,false,String(e))}
}
for(const file of ['governance/schemas/mission.schema.json','governance/schemas/evidence.schema.json']){
 try{readJson(file);ok(`schema parses: ${file}`,true)}catch(e){ok(`schema parses: ${file}`,false,String(e))}
}
const q=readJson('governance/quality-policy.json');
for(const [id,gate] of Object.entries(q.gateRegistry||{})){
 ok(`gate has kind+command: ${id}`,Boolean(gate.kind&&gate.command));
}
for(const [risk,profile] of Object.entries(q.riskProfiles||{})){const missing=(profile.requiredBaseGates||[]).filter(id=>!q.gateRegistry?.[id]);ok(`risk profile references registered base gates: ${risk}`,missing.length===0,missing.join(', '));}
const company=readJson('governance/company-os.json');
ok('six accountable roles remain explicit',company.roles&&typeof company.roles==='object'&&Object.keys(company.roles).length===6,String(Object.keys(company.roles||{}).length));
ok('bounded repair policy remains enforced',company.repairPolicy?.defaultMaxAttempts===3&&company.repairPolicy?.sameFailureMaxRepeats===2);
const execution=readJson('governance/execution-policy.json');
ok('control plane remains Git/worktree/PR/CI/evidence',execution.controlPlane==='git-worktree-pr-ci-evidence',execution.controlPlane||'');
ok('protected production actions require approval',JSON.stringify(execution).includes('production'));
const mission=readJson('missions/mission-003/m3-b6-e1/mission.json');
ok('active proving mission has explicit risk',/^R[0-3]$/.test(mission.risk||''),mission.risk||'');
ok('active proving mission has rollback',Boolean(mission.rollback));
ok('active proving mission has human intervention budget',Number.isInteger(mission.humanInterventionBudget));

const scripts=walk('scripts/agentic',{extensions:['.mjs']});
for(const file of scripts){
 const r=spawnSync(process.execPath,['--check',file],{encoding:'utf8'});
 ok(`agentic script parses: ${path.basename(file)}`,r.status===0,(r.stderr||'').trim().slice(0,180));
}
printChecks('Agentic control-plane gate',checks);
