import fs from 'node:fs';import {spawn} from 'node:child_process';import {loadQaEnv,isStaging,mutationAllowed,writeJson} from './runtime/env.mjs';
loadQaEnv();fs.mkdirSync('qa-results/mission2',{recursive:true});
const cli=process.argv.slice(2);if(cli.includes('--headed'))process.env.QA_M2_HEADED='true';const paceArg=cli.find(x=>x.startsWith('--pace='));if(paceArg){const pace=paceArg.split('=')[1];process.env.QA_USER_PACE_MS=pace;process.env.QA_CRAWL_PACE_MS=pace;}
process.env.QA_USER_PACE_MS=process.env.QA_USER_PACE_MS||'700';process.env.QA_CRAWL_PACE_MS=process.env.QA_CRAWL_PACE_MS||'700';process.env.QA_M2_CRAWL_ACTIONS=process.env.QA_M2_CRAWL_ACTIONS||'22';
const steps=[];
async function run(name,cmd,args,{required=true,env={}}={}){const started=Date.now();const result=await new Promise(resolve=>{const c=spawn(cmd,args,{stdio:'inherit',env:{...process.env,...env},shell:process.platform==='win32'});c.on('close',code=>resolve({code:code??1}));c.on('error',e=>resolve({code:127,error:e.message}))});const row={name,status:result.code===0?'passed':'failed',exitCode:result.code,durationMs:Date.now()-started,required,error:result.error||null};steps.push(row);return row.status==='passed'}
const pw=(files,project='chromium-desktop',extra=[])=>['playwright','test',...files,`--project=${project}`,'--workers=1',...(process.env.QA_M2_HEADED==='true'?['--headed']:[]),...extra];
await run('mission2-source-contract','node',['scripts/mission2-slow-user-regression-gate.mjs']);
await run('preflight','node',['qa/run-preflight.mjs']);
if(!isStaging()||!mutationAllowed()){
 steps.push({name:'staging-mutation-foundation',status:'blocked',required:true,reason:'Mission 2 requires QA_MODE=staging and QA_ALLOW_MUTATION=true.'});
}else{
 if(fs.existsSync('qa-results/fixtures/seed-state.json'))steps.push({name:'deterministic-qa-fixture',status:'reused',required:true,reason:'Existing QA fixture reused to minimize Auth/API writes.'});
 else await run('deterministic-qa-fixture','node',['qa/setup/seed.mjs']);
 // Mission 1 persisted proof is intentionally the first runtime gate. It creates fresh networks once,
 // exercises both launch datasets, requires zero errors, proves rerun idempotency, and cleans them up.
 await run('mission1-persisted-seed-retest','npx',pw(['qa/e2e/26-final-launch-seed-runtime.spec.ts']),{env:{TW_QA_FINAL_LAUNCH_SEED:'1'}});
 await run('mission2-desktop-user-journeys','npx',pw([
  'qa/e2e/27-mission2-shared-user-journeys.spec.ts',
  'qa/e2e/28-mission2-housing-user-journeys.spec.ts',
  'qa/e2e/29-mission2-family-community-admin.spec.ts',
  'qa/e2e/30-mission2-family-and-mobile.spec.ts',
  'qa/e2e/31-mission2-isolation-permissions.spec.ts',
  'qa/e2e/32-mission2-role-crawl.spec.ts',
  'qa/e2e/33-mission2-all-surface-inventory.spec.ts'
 ]));
 await run('mission2-existing-product-regression','npx',pw([
  'qa/e2e/20-vertical-smoke-matrix.spec.ts',
  'qa/e2e/30-authorization-matrix.spec.ts',
  'qa/e2e/35-api-integration.spec.ts',
  'qa/e2e/40-golden-shared-flows.spec.ts',
  'qa/e2e/45-guided-workbook-roundtrip.spec.ts',
  'qa/e2e/50-vertical-deep-flows.spec.ts',
  'qa/e2e/55-vertical-capability-matrix.spec.ts',
  'qa/e2e/60-accessibility-responsive.spec.ts',
  'qa/e2e/70-destructive-lifecycle-import.spec.ts',
  'qa/e2e/80-data-volume-resilience.spec.ts',
  'qa/e2e/81-resilience-runtime.spec.ts'
 ]));
 await run('mission2-mobile-user-journey','npx',pw(['qa/e2e/30-mission2-family-and-mobile.spec.ts'],'chromium-mobile'));
}
await run('mission2-evidence','node',['qa/report-mission2-summary.mjs'],{required:false});
const requiredFailed=steps.some(x=>x.required&&(x.status==='failed'||x.status==='blocked'));
const status=requiredFailed?'FAILED':'MISSION2_CERTIFIED';
writeJson('qa-results/mission2/run.json',{generatedAt:new Date().toISOString(),status,pacing:{userMs:Number(process.env.QA_USER_PACE_MS),crawlMs:Number(process.env.QA_CRAWL_PACE_MS),workers:1},scope:{verticals:['family','family-association','housing-society'],roles:['owner','admin','member','tenantB'],mission1SeedRetest:true,mobile:true},steps});
console.log(`\nTrustWeave Mission 2 slow user regression: ${status}`);console.log('Evidence: qa-results/mission2/, qa-results/BUG-REPORT.md, qa-results/issues/runtime.ndjson');if(requiredFailed)process.exit(1);
