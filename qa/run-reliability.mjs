import fs from 'node:fs';
import {spawn} from 'node:child_process';
import {loadQaEnv,isStaging,mutationAllowed,writeJson} from './runtime/env.mjs';
import {QA_ROLES,QA_VERTICAL_KINDS} from './runtime/scope.mjs';

loadQaEnv();
const connected=process.argv.includes('--connected');
const headed=!process.argv.includes('--headless');
const steps=[];

async function run(name,command,args,{required=true,env={}}={}){
 const started=Date.now();
 const result=await new Promise(resolve=>{
  const child=spawn(command,args,{stdio:'inherit',env:{...process.env,...env},shell:process.platform==='win32'});
  child.on('close',code=>resolve({code:code??1}));
  child.on('error',error=>resolve({code:127,error:error.message}));
 });
 const row={name,status:result.code===0?'passed':'failed',exitCode:result.code,durationMs:Date.now()-started,required,error:result.error||null};
 steps.push(row);return row.status==='passed';
}

const localChecks=[
 ['architecture-and-product-contracts','npm',['run','validate:mission2']],
 ['qa-contracts','npm',['run','qa:unit']],
 ['full-types','npm',['run','check:types']],
 ['production-build','npm',['run','build']]
];
for(const [name,command,args] of localChecks){
 await run(name,command,args);
}

if(connected&&!steps.some(step=>step.required&&step.status==='failed')){
 if(!isStaging()||!mutationAllowed()){
  steps.push({name:'staging-safety',status:'blocked',required:true,reason:'Set QA_MODE=staging and QA_ALLOW_MUTATION=true in ignored .env.qa.'});
 }else{
  const seed='qa-results/fixtures/seed-state.json';
  if(fs.existsSync(seed))steps.push({name:'deterministic-fixture',status:'reused',required:true});
  else await run('deterministic-fixture','npm',['run','qa:seed'],{env:{QA_SEED_SCOPE:'configured'}});
  if(!steps.some(step=>step.name==='deterministic-fixture'&&(step.status==='failed'||step.status==='blocked'))){
   await run('configured-critical-journeys','npx',['playwright','test',
    'qa/e2e/20-vertical-smoke-matrix.spec.ts',
    'qa/e2e/27-mission2-shared-user-journeys.spec.ts',
    'qa/e2e/28-mission2-housing-user-journeys.spec.ts',
    'qa/e2e/29-mission2-family-community-admin.spec.ts',
    'qa/e2e/31-mission2-isolation-permissions.spec.ts',
    'qa/e2e/32-mission2-role-crawl.spec.ts',
    'qa/e2e/33-mission2-all-surface-inventory.spec.ts',
    'qa/e2e/50-vertical-deep-flows.spec.ts',
    'qa/e2e/55-vertical-capability-matrix.spec.ts',
    'qa/e2e/60-accessibility-responsive.spec.ts',
    'qa/e2e/81-resilience-runtime.spec.ts',
    '--project=chromium-desktop','--workers=1',...(headed?['--headed']:[])]);
   await run('configured-resilient-crawl','npm',['run','qa:crawl:robust',...(headed?[]:['--','--headless'])]);
  }
 }
}

const failed=steps.some(step=>step.required&&(step.status==='failed'||step.status==='blocked'));
const status=failed?'FAILED':connected?'CERTIFIED':'LOCAL_PASS';
writeJson('qa-results/reliability/SUMMARY.json',{generatedAt:new Date().toISOString(),status,mode:connected?'connected':'local',configuration:'qa.config.mjs',scope:{verticals:QA_VERTICAL_KINDS,roles:QA_ROLES},steps,credentialsIncluded:false});
console.log(`\nTrustWeave configured reliability: ${status}`);
console.log(`Scope: ${QA_VERTICAL_KINDS.join(', ')} × ${QA_ROLES.join(', ')}`);
console.log('Evidence: qa-results/reliability/SUMMARY.json');
if(failed)process.exit(1);
