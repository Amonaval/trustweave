const BOOTSTRAP_FORMAT='trustweave-d12-bootstrap-replay-apply-receipt-v1';
const MANAGED_FORMAT='trustweave-d12-managed-sql-apply-receipt-v1';
const MANAGED_STATUS='MANAGED_SQL_BOOTSTRAP_APPLIED_TO_FRESH_DISPOSABLE';
const APPROVED_MANAGED_PROJECT='yqwitkoxyrujbzpjwuji';
const APPROVED_MANAGED_COMMIT='ce5eddfbedd2a1ab3a92bbd58ac24ca78e57bfe1';
const APPROVED_OWNER_MIGRATION='d12_final_storage_owner_context';
// The founder's original corrected supplement CSV predates the promoted
// manifest fingerprint. Both hashes are fixed; neither is a wildcard.
const PROMOTED_SUPPLEMENT_SHA256='5a2a2c5f301ef9606a90f254b98fafae5a8477ab13ccb5ce68052dd66d639c47';
const ORIGINAL_SUPPLEMENT_SHA256='0ce6507dc57ae79d96820800f76b5b38ba91e1be82004b3f51591295aaed4743';
const LEGACY_STATUS='APPLIED_TO_DISPOSABLE_CANDIDATE';

export function isD12BootstrapReceipt(apply){
 return apply?.format===BOOTSTRAP_FORMAT||apply?.format===MANAGED_FORMAT;
}

export function d12EvidencePaths(root){
 return {
  catalog:`${root}/catalog-parity.json`,
  apply:`${root}/apply-receipt.json`,
  recapture:`${root}/recapture/recapture-receipt.json`,
  primary:`${root}/recapture/candidate-primary.csv`,
  supplement:`${root}/recapture/candidate-supplement.csv`
 };
}

export function validateD12Evidence({catalog,apply,recapture,manifest,manifestSha256,qaProjectRef}){
 const fail=message=>{throw new Error(`D12 parity preflight: ${message}`)};
 if(catalog?.format!=='trustweave-d12-catalog-parity-v1'||catalog.status!=='PASS')fail('catalog parity report is not PASS');
 for(const layer of ['structural','security','api_contract']){
  if(catalog.layers?.[layer]?.status!=='PASS')fail(`${layer} catalog layer is not PASS`);
 }
 const candidate=String(apply?.candidate_project_ref||'').trim().toLowerCase();
 const golden=String(apply?.golden_project_ref||'').trim().toLowerCase();
 const qaRef=String(qaProjectRef||'').trim().toLowerCase();
 if(!candidate||!golden||candidate===golden)fail('apply receipt does not identify distinct candidate and golden projects');
 if(!qaRef||qaRef!==candidate)fail('QA project ref does not match the apply receipt');

 const managed=apply.format===MANAGED_FORMAT;
 if(isD12BootstrapReceipt(apply)){
  if(managed){
   if(apply.status!==MANAGED_STATUS)fail('managed-SQL bootstrap receipt is not PASS');
   if(candidate!==APPROVED_MANAGED_PROJECT||apply.source_commit!==APPROVED_MANAGED_COMMIT)fail('managed-SQL receipt is not the reviewed final replay');
   if(apply.psql_receipt!==false||apply.direct_apply_transactions!==8||
      apply.owner_context_migration!==APPROVED_OWNER_MIGRATION)fail('managed-SQL apply provenance does not match the reviewed replay');
  }else if(apply.status!=='DIRECT_BOOTSTRAP_APPLIED_TO_FRESH_DISPOSABLE'){
   fail('committed bootstrap receipt is not PASS');
  }
  if(!manifest||manifest.status!=='CANONICAL_CURRENT_STATE'||manifest.golden_project_ref!==golden)fail('release manifest does not identify the protected golden project');
  if(!manifestSha256||apply.manifest_sha256!==manifestSha256)fail('bootstrap receipt does not match the committed manifest bytes');
  if(apply.secrets_recorded!==false)fail('bootstrap receipt may contain secrets');
  for(const key of ['relations','functions','sequences']){
   if(apply.freshness_preflight?.[key]!==0)fail(`bootstrap freshness preflight is not empty: ${key}`);
  }
  if(apply.direct_sql_files!==manifest.direct_apply_order?.length)fail('bootstrap applied file count differs from the manifest');
  if(JSON.stringify(apply.owner_context_files)!==JSON.stringify(manifest.storage_owner_context_files))fail('Storage owner-context files differ from the manifest');
  if(recapture?.format!=='trustweave-d12-candidate-recapture-v1'||
    recapture.candidate_project_ref!==candidate||recapture.golden_project_ref!==golden||
    recapture.secrets_recorded!==false)fail('candidate recapture does not match the protected project refs');
  const inputs=catalog.inputs||{};
  for(const [actual,expected] of [
   [inputs.candidate_primary_sha256,recapture.primary_sha256],
   [inputs.candidate_supplement_sha256,recapture.supplement_sha256],
   [inputs.golden_primary_sha256,manifest.primary_capture_sha256],
  ]){
   if(!actual||actual!==expected)fail('catalog input hashes do not match the recapture and release manifest');
  }
  const originalSupplement=manifest.supplement_capture_sha256===PROMOTED_SUPPLEMENT_SHA256 &&
    inputs.golden_supplement_sha256===ORIGINAL_SUPPLEMENT_SHA256;
  if(managed ? !originalSupplement :
     inputs.golden_supplement_sha256!==manifest.supplement_capture_sha256&&!originalSupplement){
   fail('golden supplement hash is not an approved captured source');
  }
 }else if(apply.status!==LEGACY_STATUS){
  fail('apply receipt is neither an accepted candidate nor a reviewed bootstrap replay');
 }
 return {candidateProjectRef:candidate,goldenProjectRef:golden,mode:managed?'managed-bootstrap':apply.format===BOOTSTRAP_FORMAT?'committed-bootstrap':'legacy-candidate'};
}
