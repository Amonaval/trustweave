import fs from 'node:fs';
import {spawn} from 'node:child_process';
import {loadQaEnv,assertMutationAllowed,writeJson} from './runtime/env.mjs';
import {QA_VERTICAL_KINDS} from './runtime/scope.mjs';

process.env.QA_ENV_FILE=process.env.QA_ENV_FILE||'.env.d12-candidate';
loadQaEnv();

const root='.d12-work/candidate';
const catalogPath=`${root}/catalog-parity.json`;
const applyPath=`${root}/apply-receipt.json`;
if(!fs.existsSync(catalogPath))throw new Error(`Missing D12 catalog parity report: ${catalogPath}`);
if(!fs.existsSync(applyPath))throw new Error(`Missing D12 disposable apply receipt: ${applyPath}`);
const catalog=JSON.parse(fs.readFileSync(catalogPath,'utf8'));
const apply=JSON.parse(fs.readFileSync(applyPath,'utf8'));
if(catalog.status!=='PASS')throw new Error('D12 behavioral parity requires catalog parity PASS first.');
if(apply.status!=='APPLIED_TO_DISPOSABLE_CANDIDATE')throw new Error('D12 apply receipt is not a disposable candidate PASS.');

const expectedVerticals=['family-association','housing-society'];
const configured=[...QA_VERTICAL_KINDS].sort();
if(JSON.stringify(configured)!==JSON.stringify(expectedVerticals)){
 throw new Error(`D12 candidate QA scope must be exactly ${expectedVerticals.join(', ')}; got ${configured.join(', ')}`);
}
const qaRef=(process.env.QA_STAGING_PROJECT_REF||'').trim().toLowerCase();
if(!qaRef)throw new Error('D12 candidate QA requires QA_STAGING_PROJECT_REF in .env.d12-candidate.');
if(qaRef!==String(apply.candidate_project_ref||'').toLowerCase()){
 throw new Error(`QA staging ref ${qaRef} does not match D12 candidate apply receipt.`);
}
if(qaRef===String(apply.golden_project_ref||'').toLowerCase()){
 throw new Error('REFUSING D12 behavioral parity: QA target equals golden project.');
}
assertMutationAllowed();

const steps=[];
async function run(name,cmd,args,{required=true,env={}}={}){
 const started=Date.now();
 const result=await new Promise(resolve=>{
  const child=spawn(cmd,args,{stdio:'inherit',env:{...process.env,...env},shell:process.platform==='win32'});
  child.on('close',code=>resolve({code:code??1}));
  child.on('error',error=>resolve({code:127,error:error.message}));
 });
 const row={name,status:result.code===0?'passed':'failed',exitCode:result.code,durationMs:Date.now()-started,required,error:result.error||null};
 steps.push(row);return row.status==='passed';
}

// Existing reliability runner already executes static/build gates, creates/reuses the
// configured two-vertical deterministic seed, runs critical Playwright journeys and
// resilient crawl with owner/admin/member roles.
await run('two-vertical-connected-reliability','npm',['run','qa:reliability','--','--headless']);

// Directly prove the two D12-restored notification mutators, their read-after-write
// behavior, cleanup, and member denial in both configured verticals.
if(!steps.some(x=>x.required&&x.status==='failed')){
 await run('notification-role-drift-repair','node',['qa/db/d12-notification-role-contract.mjs']);
}

const failed=steps.some(x=>x.required&&x.status==='failed');
const status=failed?'FAILED':'D12_BEHAVIOR_BROWSER_PARITY_PASS';
const report={
 generatedAt:new Date().toISOString(),
 status,
 candidateProjectRef:apply.candidate_project_ref,
 goldenProjectRef:apply.golden_project_ref,
 catalogParity:'PASS',
 scope:{verticals:expectedVerticals,roles:['owner','admin','member'],browser:'chromium-desktop',resilientCrawl:true},
 steps,
 secretsIncluded:false,
 nextGate:failed?'resolve-behavior-browser-parity':'canonical-promotion-review'
};
writeJson('qa-results/d12-candidate-parity/SUMMARY.json',report);
console.log(`\nTrustWeave D12 candidate behavioral/browser parity: ${status}`);
console.log('Evidence: qa-results/d12-candidate-parity/SUMMARY.json');
if(failed)process.exit(1);
