import {test,expect} from '@playwright/test';import {authenticatedClient,seedState} from '../lib/role-client';

test('Mission 2 — tenant B cannot read tenant A network activities',async()=>{
 const s=seedState();const b=await authenticatedClient('tenantB');const set=await b.client.rpc('set_active_network',{p_network_id:s.networks['family-association'].id});expect(set.error).not.toBeNull();
 const activities=await b.client.rpc('get_network_activities',{p_activity_type:null});expect(activities.error||activities.data==null||activities.data.length===0).toBeTruthy();
});
