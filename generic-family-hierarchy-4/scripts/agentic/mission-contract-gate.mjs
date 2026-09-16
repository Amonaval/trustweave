import {parseArgs,readJson,exists,printChecks} from './lib.mjs';
const args=parseArgs();const missionPath=args.mission||'missions/mission-003/mission.json';const q=readJson('governance/quality-policy.json');const checks=[];const ok=(n,v,d='')=>checks.push([n,!!v,d]);
if(!exists(missionPath)){ok('mission exists',false,missionPath);printChecks('Mission contract gate',checks);process.exit(1)}
const m=readJson(missionPath);const states=['INTAKE','DISCOVERY','ARCHITECTURE','PLAN','IMPLEMENT','VERIFY','REVIEW','HARDEN','DOCUMENT','RELEASE','OBSERVE','CLOSE'];
ok('mission id',typeof m.id==='string'&&m.id.length>2,m.id);
ok('risk class',Object.hasOwn(q.riskProfiles,m.risk),m.risk);const risk=q.riskProfiles[m.risk]||{};
ok('lifecycle state',states.includes(m.state),m.state);
ok('bounded include scope',Array.isArray(m.scope?.include)&&m.scope.include.length>0);
ok('explicit exclusions',Array.isArray(m.scope?.exclude)&&m.scope.exclude.length>0);
ok('allowed writes declared',Array.isArray(m.scope?.allowedWrites)&&m.scope.allowedWrites.length>0);
ok('acceptance criteria declared',Array.isArray(m.acceptance)&&m.acceptance.length>0);
ok('rollback declared',typeof m.rollback==='string'&&m.rollback.length>2);
ok('human intervention budget declared',Number.isInteger(m.humanInterventionBudget)&&m.humanInterventionBudget>=0);
const unknown=(m.gates||[]).filter(g=>!q.gateRegistry[g]);ok('all gates are registered',unknown.length===0,unknown.join(', '));
const missingBase=(risk.requiredBaseGates||[]).filter(g=>!(m.gates||[]).includes(g));ok('risk-profile base gates declared',missingBase.length===0,missingBase.join(', '));
if(m.risk==='R0'||m.risk==='R1'){const bad=(m.scope?.allowedWrites||[]).filter(x=>x.startsWith('supabase/migrations'));ok(`${m.risk} does not authorize migration writes`,bad.length===0,bad.join(', '))}
if(m.runtimeEvidenceRequired){const runtime=(m.gates||[]).filter(g=>q.gateRegistry[g]?.kind==='runtime');ok('runtime-required mission declares runtime gates',runtime.length>0,runtime.join(', '))}
ok('independent review is declared when required',!q.releasePolicy.requireIndependentReview||(m.gates||[]).includes('independent-review'));
printChecks('Mission contract gate',checks);
