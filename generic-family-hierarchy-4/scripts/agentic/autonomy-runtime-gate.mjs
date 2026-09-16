import fs from 'node:fs';
import {missionRegistry,resolveMissionPath,readJson,exists,printChecks} from './lib.mjs';
const checks=[];const ok=(n,v,d='')=>checks.push([n,!!v,d]);const reg=missionRegistry();
ok('mission registry exists',exists('missions/registry.json'));
ok('registry has active mission',Boolean(reg.activeId),reg.activeId||'');
const ids=(reg.missions||[]).map(x=>x.id);ok('mission ids unique',new Set(ids).size===ids.length,ids.join(', '));
for(const m of reg.missions||[])ok(`registered mission exists: ${m.id}`,exists(m.path),m.path);
let active=null;try{active=resolveMissionPath();ok('active mission resolves',true,active)}catch(e){ok('active mission resolves',false,String(e))}
if(active){const m=readJson(active);ok('resolved mission matches registry active id',m.id===reg.activeId,`${m.id} vs ${reg.activeId}`)}
const packageJson=readJson('package.json');const scriptText=JSON.stringify(packageJson.scripts||{});ok('package agentic commands are not B6-hardcoded',!scriptText.includes('m3-b6-e1/mission.json'));
const agenticFiles=fs.readdirSync('scripts/agentic').filter(x=>x.endsWith('.mjs')&&x!=='autonomy-runtime-gate.mjs');let hardcoded=[];for(const f of agenticFiles){const s=fs.readFileSync(`scripts/agentic/${f}`,'utf8');if(/\|\|\s*['\"]missions\/mission-003\/m3-b6-e1\/mission\.json/.test(s))hardcoded.push(f)}ok('agentic runtime contains no B6 default path',hardcoded.length===0,hardcoded.join(', '));
const rootMd=fs.readdirSync('.').filter(x=>x.endsWith('.md'));ok('root markdown control surface <= 10',rootMd.length<=10,String(rootMd.length));
ok('autonomy policy exists',exists('governance/autonomy-policy.json'));
ok('autonomy mission set exists',exists('missions/mission-003/m3-c/mission-set.json'));
const closeScript=fs.readFileSync('scripts/agentic/mission-close.mjs','utf8');ok('close requires APPROVED independent review',closeScript.includes("r.status==='APPROVED'")&&closeScript.includes('reviewer differs from builder'));ok('close requires every mandatory gate PASS',closeScript.includes('all mandatory gates PASS')&&closeScript.includes("g!=='evidence'"));
printChecks('Autonomous company runtime gate',checks);
