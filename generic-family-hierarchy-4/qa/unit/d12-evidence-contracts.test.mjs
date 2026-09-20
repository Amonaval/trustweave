import test from 'node:test';
import assert from 'node:assert/strict';
import {d12EvidencePaths,validateD12Evidence} from '../runtime/d12-evidence.mjs';

const golden='yyhwcqpzplebittvxzzl',candidate='freshcandidate';
test('reads the receipt from the verifier recapture subdirectory',()=>{
 assert.equal(d12EvidencePaths('.d12-work/bootstrap-replay').recapture,'.d12-work/bootstrap-replay/recapture/recapture-receipt.json');
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
