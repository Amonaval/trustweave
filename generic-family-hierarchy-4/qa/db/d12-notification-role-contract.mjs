import fs from 'node:fs';
import {assertMutationAllowed,loadQaEnv,writeJson} from '../runtime/env.mjs';
import {roleClient,setActiveNetwork} from '../runtime/supabase.mjs';

process.env.QA_ENV_FILE=process.env.QA_ENV_FILE||'.env.d12-candidate';
loadQaEnv();
assertMutationAllowed();

const seedPath='qa-results/fixtures/seed-state.json';
if(!fs.existsSync(seedPath))throw new Error('D12 notification-role proof requires the deterministic QA seed.');
const state=JSON.parse(fs.readFileSync(seedPath,'utf8'));
const verticals=['housing-society','family-association'];
for(const kind of verticals){
 if(!state.networks?.[kind]?.id)throw new Error(`Seed state is missing required D12 vertical: ${kind}`);
}
if(!state.users?.member?.id)throw new Error('Seed state is missing QA member identity.');

const owner=(await roleClient('owner')).client;
const member=(await roleClient('member')).client;
const assigneeId=state.users.member.id;
const roleKey='d12-parity-proof';
const label='D12 parity proof';
const checks=[];

function record(kind,name,ok,error=null,details={}){checks.push({vertical:kind,name,status:ok?'passed':'failed',error,...details});}
async function rpc(client,name,args){return client.rpc(name,args)}

for(const kind of verticals){
 const networkId=state.networks[kind].id;
 await setActiveNetwork(owner,networkId);
 await setActiveNetwork(member,networkId);

 // Start clean in case a previous interrupted run left the proof assignment behind.
 const cleanup=await rpc(owner,'remove_network_notification_role',{p_role_key:roleKey,p_user_id:assigneeId});
 if(cleanup.error&&!/not found/i.test(cleanup.error.message||''))record(kind,'pre-cleanup',false,cleanup.error.message);
 else record(kind,'pre-cleanup',true);

 const setResult=await rpc(owner,'set_network_notification_role',{
  p_role_key:roleKey,p_label:label,p_user_id:assigneeId,p_active:true
 });
 record(kind,'owner-can-assign',!setResult.error,setResult.error?.message||null);

 const readAfterSet=await rpc(owner,'get_network_notification_roles');
 const assigned=!readAfterSet.error&&Array.isArray(readAfterSet.data)&&readAfterSet.data.some(
  row=>row.role_key===roleKey&&row.user_id===assigneeId&&row.active===true
 );
 record(kind,'assignment-is-readable',assigned,readAfterSet.error?.message||null,{rows:Array.isArray(readAfterSet.data)?readAfterSet.data.length:0});

 const unauthorizedSet=await rpc(member,'set_network_notification_role',{
  p_role_key:roleKey,p_label:label,p_user_id:assigneeId,p_active:true
 });
 record(kind,'member-cannot-assign',!!unauthorizedSet.error,unauthorizedSet.error?.message||null);

 const removeResult=await rpc(owner,'remove_network_notification_role',{p_role_key:roleKey,p_user_id:assigneeId});
 record(kind,'owner-can-remove',!removeResult.error,removeResult.error?.message||null);

 const readAfterRemove=await rpc(owner,'get_network_notification_roles');
 const removed=!readAfterRemove.error&&Array.isArray(readAfterRemove.data)&&!readAfterRemove.data.some(
  row=>row.role_key===roleKey&&row.user_id===assigneeId&&row.active===true
 );
 record(kind,'removal-is-readable',removed,readAfterRemove.error?.message||null);

 const unauthorizedRemove=await rpc(member,'remove_network_notification_role',{p_role_key:roleKey,p_user_id:assigneeId});
 record(kind,'member-cannot-remove',!!unauthorizedRemove.error,unauthorizedRemove.error?.message||null);

 // Idempotent final cleanup under owner context.
 await rpc(owner,'remove_network_notification_role',{p_role_key:roleKey,p_user_id:assigneeId});
}

const failed=checks.filter(x=>x.status==='failed');
const report={
 generatedAt:new Date().toISOString(),
 profile:'d12-notification-role-contract',
 status:failed.length?'FAILED':'PASSED',
 scope:{verticals,actorSuccess:'owner',actorDenied:'member'},
 checks,
 secretsIncluded:false
};
writeJson('qa-results/d12-candidate-parity/notification-role-contract.json',report);
console.log(`D12 notification-role behavioral contract: ${report.status} (${checks.length} checks)`);
if(failed.length)process.exit(1);
