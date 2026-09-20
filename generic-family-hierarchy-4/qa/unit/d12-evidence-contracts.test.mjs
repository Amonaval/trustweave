import test from 'node:test';
import assert from 'node:assert/strict';
import {d12EvidencePaths,isD12BootstrapReceipt,validateD12Evidence} from '../runtime/d12-evidence.mjs';

const golden='yyhwcqpzplebittvxzzl',candidate='freshcandidate';
test('reads the receipt from the verifier recapture subdirectory',()=>{
 assert.equal(d12EvidencePaths('.d12-work/bootstrap-replay').recapture,'.d12-work/bootstrap-replay/recapture/recapture-receipt.json');
 assert.equal(d12EvidencePaths('.d12-work/bootstrap-replay').primary,'.d12-work/bootstrap-replay/recapture/candidate-primary.csv');
 assert.equal(d12EvidencePaths('.d12-work/bootstrap-replay').supplement,'.d12-work/bootstrap-replay/recapture/candidate-supplement.csv');
});
function fixture(){
 const manifest={status:'CANONICAL_CURRENT_STATE',golden_project_ref:golden,primary_capture_sha256:'gp',supplement_capture_sha256:'gs',direct_apply_order:['one.sql'],storage_owner_context_files:['storage.sql']};
 return {
  catalog:{format:'trustweave-d12-catalog-parity-v1',status:'PASS',layers:{structural:{status:'PASS'},security:{status:'PASS'},api_contract:{status:'PASS'}},inputs:{golden_primary_sha256:'gp',golden_supplement_sha256:'gs',candidate_primary_sha256:'cp',candidate_supplement_sha256:'cs'}},
  apply:{format:'trustweave-d12-bootstrap-replay-apply-receipt-v1',status:'DIRECT_BOOTSTRAP_APPLIED_TO_FRESH_DISPOSABLE',candidate_project_ref:candidate,golden_project_ref:golden,manifest_sha256:'manifest',direct_sql_files:1,owner_context_files:['storage.sql'],freshness_preflight:{relations:0,functions:0,sequences:0},secrets_recorded:false},
  recapture:{format:'trustweave-d12-candidate-recapture-v1',candidate_project_ref:candidate,golden_project_ref:golden,primary_sha256:'cp',supplement_sha256:'cs',secrets_recorded:false},
  manifest,manifestSha256:'manifest',qaProjectRef:candidate
 };
}

test('accepts a matching fresh committed bootstrap with bound capture inputs',()=>{
 assert.equal(validateD12Evidence(fixture()).mode,'committed-bootstrap');
});
test('keeps the original disposable candidate receipt supported',()=>{
 const value=fixture();value.apply={status:'APPLIED_TO_DISPOSABLE_CANDIDATE',candidate_project_ref:candidate,golden_project_ref:golden};
 assert.equal(validateD12Evidence(value).mode,'legacy-candidate');
});
for(const [name,change] of [
 ['golden QA target',v=>{v.qaProjectRef=golden}],
 ['stale manifest',v=>{v.apply.manifest_sha256='old'}],
 ['nonempty database',v=>{v.apply.freshness_preflight.relations=1}],
 ['wrong recapture',v=>{v.recapture.candidate_project_ref='other'}],
 ['stale candidate catalog',v=>{v.catalog.inputs.candidate_primary_sha256='old'}],
 ['stale golden catalog',v=>{v.catalog.inputs.golden_primary_sha256='old'}],
 ['missing security PASS',v=>{v.catalog.layers.security.status='FAIL'}],
 ['unrecognized receipt',v=>{v.apply.format='other';v.apply.status='OTHER'}],
])test(`rejects ${name}`,()=>{const value=fixture();change(value);assert.throws(()=>validateD12Evidence(value),/D12 parity preflight/)});

function managedFixture(){
 const value=fixture();
 value.apply={
  ...value.apply,
  format:'trustweave-d12-managed-sql-apply-receipt-v1',
  status:'MANAGED_SQL_BOOTSTRAP_APPLIED_TO_FRESH_DISPOSABLE',
  candidate_project_ref:'yqwitkoxyrujbzpjwuji',
  source_commit:'ce5eddfbedd2a1ab3a92bbd58ac24ca78e57bfe1',
  direct_apply_transactions:8,
  owner_context_migration:'d12_final_storage_owner_context',
  psql_receipt:false
 };
 value.qaProjectRef=value.apply.candidate_project_ref;
 value.recapture.candidate_project_ref=value.apply.candidate_project_ref;
 value.manifest.supplement_capture_sha256='5a2a2c5f301ef9606a90f254b98fafae5a8477ab13ccb5ce68052dd66d639c47';
 value.catalog.inputs.golden_supplement_sha256='0ce6507dc57ae79d96820800f76b5b38ba91e1be82004b3f51591295aaed4743';
 return value;
}
test('accepts the reviewed managed-SQL replay and founder golden supplement',()=>{
 const value=managedFixture();
 assert.equal(isD12BootstrapReceipt(value.apply),true);
 assert.equal(validateD12Evidence(value).mode,'managed-bootstrap');
});
for(const [name,change] of [
 ['different managed project',v=>{v.apply.candidate_project_ref='another'}],
 ['different source commit',v=>{v.apply.source_commit='older'}],
 ['missing Storage owner migration',v=>{delete v.apply.owner_context_migration}],
 ['psql receipt claim',v=>{v.apply.psql_receipt=true}],
 ['wrong managed transaction count',v=>{v.apply.direct_apply_transactions=7}],
 ['different raw golden supplement',v=>{v.catalog.inputs.golden_supplement_sha256='other'}],
 ['unreviewed promoted fingerprint',v=>{v.manifest.supplement_capture_sha256='other'}],
 ['stale managed manifest',v=>{v.apply.manifest_sha256='old'}],
 ['different managed QA target',v=>{v.qaProjectRef='other'}],
 ['different candidate capture',v=>{v.recapture.primary_sha256='other'}],
 ['failed managed status',v=>{v.apply.status='FAILED'}],
])test(`rejects ${name}`,()=>{
 const value=managedFixture();change(value);
 assert.throws(()=>validateD12Evidence(value),/D12 parity preflight/);
});
