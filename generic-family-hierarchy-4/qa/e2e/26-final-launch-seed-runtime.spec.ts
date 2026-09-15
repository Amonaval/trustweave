import {test,expect} from '@playwright/test';
import {login} from '../lib/login';
import {authenticatedClient} from '../lib/role-client';

const enabled=process.env.TW_QA_FINAL_LAUNCH_SEED==='1';

test.describe('Final launch persisted synthetic seed runtime',()=>{
 test.skip(!enabled,'Set TW_QA_FINAL_LAUNCH_SEED=1 only on an approved staging QA tenant with migration 113 applied.');
 for(const spec of [
  {kind:'housing-society',name:'QA Final Launch Residential Pilot',anchor:'A-101'},
  {kind:'family-association',name:'QA Final Launch Community Pilot',anchor:'Bajaj Family'},
 ] as const){
  test(`${spec.kind}: fresh network seeds through guarded loader and rerun becomes idempotent`,async({page})=>{
   const owner=await authenticatedClient('owner');
   const name=`${spec.name} ${Date.now()}`;
   const created=await owner.client.rpc('create_productized_network',{p_vertical_kind:spec.kind,p_name:name,p_context_value:'Pune',p_description:'Final launch runtime certification — synthetic QA only'});
   expect(created.error).toBeNull();const networkId=String(created.data);expect(networkId).toBeTruthy();
   try{
    expect((await owner.client.rpc('set_active_network',{p_network_id:networkId})).error).toBeNull();
    await login(page,'owner');
    await expect(page.getByTestId(`qa-vertical-shell-${spec.kind}`)).toBeVisible({timeout:30_000});
    await page.getByTestId('qa-nav-admin').click();
    const loader=page.getByTestId('qa-launch-data-loader');await expect(loader).toBeVisible({timeout:20_000});
    await loader.getByTestId('qa-launch-confirm-name').fill(name);await loader.getByTestId('qa-launch-synthetic-confirm').check();
    await loader.getByTestId('qa-launch-authorize').click();await expect(loader.getByText('Authorized')).toBeVisible({timeout:20_000});
    await loader.getByTestId('qa-launch-commit').click();await expect(loader.getByTestId('qa-launch-result')).toContainText('0 errors',{timeout:120_000});
    const entities=await owner.client.rpc('get_network_affiliated_entities');expect(entities.error).toBeNull();expect(JSON.stringify(entities.data)).toContain(spec.anchor);
    await loader.getByTestId('qa-launch-commit').click();await expect(loader.getByTestId('qa-launch-result')).toContainText(/0 created/i,{timeout:120_000});
    const lineage=await owner.client.rpc('get_launch_demo_seed_lineage',{p_dataset_version:spec.kind==='housing-society'?'trustweave-launch-residential.v1':'trustweave-launch-family-community.v1'});expect(lineage.error).toBeNull();expect((lineage.data||[]).length).toBeGreaterThan(20);
   }finally{
    await owner.client.rpc('set_active_network',{p_network_id:networkId});
    const deleted=await owner.client.rpc('delete_productized_network_permanently',{p_confirm_name:name});
    expect(deleted.error).toBeNull();
   }
  });
 }
});
