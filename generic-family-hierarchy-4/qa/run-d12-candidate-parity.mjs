import fs from 'node:fs';
import {spawn} from 'node:child_process';
import {createHash} from 'node:crypto';
import {loadQaEnv,assertMutationAllowed,writeJson} from './runtime/env.mjs';
import {QA_VERTICAL_KINDS} from './runtime/scope.mjs';
import {validateD12Evidence} from './runtime/d12-evidence.mjs';

process.env.QA_ENV_FILE=process.env.QA_ENV_FILE||'.env.d12-candidate';
loadQaEnv();

const root=process.env.D12_PARITY_EVIDENCE_ROOT||'.d12-work/candidate';
const catalogPath=`${root}/catalog-parity.json`;
const applyPath=`${root}/apply-receipt.json`;
if(!fs.existsSync(catalogPath))throw new Error(`Missing D12 catalog parity report: ${catalogPath}`);
if(!fs.existsSync(applyPath))throw new Error(`Missing D12 disposable apply receipt: ${applyPath}`);
const catalog=JSON.parse(fs.readFileSync(catalogPath,'utf8'));
const apply=JSON.parse(fs.readFileSync(applyPath,'utf8'));
const bootstrap=apply.format==='trustweave-d12-bootstrap-replay-apply-receipt-v1';
const recapturePath=`${root}/recapture-receipt.json`;
const releaseName=fs.readFileSync('supabase/bootstrap/CURRENT','utf8').trim();
if(!/^[a-zA-Z0-9._-]+$/.test(releaseName))throw new Error('Invalid committed bootstrap release name.');
const manifestPath=`supabase/bootstrap/releases/${releaseName}/manifest.json`;
const manifestBytes=bootstrap?fs.readFileSync(manifestPath):null;
const evidence=validateD12Evidence({
 catalog,apply,
 recapture:bootstrap?JSON.parse(fs.readFileSync(recapturePath,'utf8')):null,
 manifest:bootstrap?JSON.parse(manifestBytes.toString('utf8')):null,
 manifestSha256:bootstrap?createHash('sha256').update(manifestBytes).digest('hex'):null,
 qaProjectRef:process.env.QA_STAGING_PROJECT_REF
});

const expectedVerticals=['family-association','housing-society'];
const configured=[...QA_VERTICAL_KINDS].sort();
if(JSON.stringify(configured)!==JSON.stringify(expectedVerticals)){
 throw new Error(`D12 candidate QA scope must be exactly ${expectedVerticals.join(', ')}; got ${configured.join(', ')}`);
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
 candidateProjectRef:evidence.candidateProjectRef,
 goldenProjectRef:evidence.goldenProjectRef,
 applyMode:evidence.mode,
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
