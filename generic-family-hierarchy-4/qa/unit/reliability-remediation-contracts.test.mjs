import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

const read=path=>fs.readFileSync(path,'utf8');
const migration=read('supabase/migrations/122_reliability_snapshot_notification_contract_repair.sql');
const helper=read('qa/lib/mission2-regression.ts');
const css=read('app/globals.css');

test('migration 122 restores every Housing operations collection',()=>{
 for(const table of ['hs_notices','hs_complaints','hs_vendors','hs_amenities','hs_amenity_bookings'])assert.match(migration,new RegExp(`public\\.${table}`));
 for(const key of ['notices','complaints','vendors','amenities','bookings'])assert.doesNotMatch(migration,new RegExp(`'${key}'\\s*,\\s*'\\[\\]'::jsonb`));
});

test('migration 122 restores the authenticated notification-role RPC safely',()=>{
 assert.match(migration,/create or replace function public\.get_network_notification_roles\(\)/);
 assert.match(migration,/revoke all on function public\.get_network_notification_roles\(\) from public/);
 assert.match(migration,/grant execute on function public\.get_network_notification_roles\(\) to authenticated/);
 assert.match(migration,/notify pgrst, 'reload schema'/);
});

test('persistence wait does not classify a success banner as failure',()=>{
 assert.match(helper,/reported success but did not render/);
 assert.match(helper,/failed\|could not\|error\|denied/);
 assert.doesNotMatch(helper,/result\?\.kind==='message'/);
});

test('measured flagship muted text uses the accessible contrast token',()=>{
 assert.match(css,/--muted-contrast:#59645d/);
 assert.match(css,/\.association-announcement-list p,.housing-society-network \.hs-all-clear small,.housing-society-network \.hs-finance-summary small\{color:var\(--muted-contrast\)\}/);
});
