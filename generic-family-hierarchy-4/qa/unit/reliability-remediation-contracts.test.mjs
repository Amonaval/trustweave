import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

const read=path=>fs.readFileSync(path,'utf8');
const migration=read('supabase/migrations/122_reliability_snapshot_notification_contract_repair.sql');
const helper=read('qa/lib/mission2-regression.ts');
const css=read('app/globals.css');
const apiClient=read('lib/api-client.ts');
const responseRuntime=read('server/shared/response.ts');
const crawler=read('qa/lib/crawler.ts');
const pushRoute=read('app/api/notifications/push/route.ts');
const d12Workflow=read('../.github/workflows/d12-connected-certification.yml');

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
 assert.match(css,/\.housing-society-network \.hs-all-clear small\{color:var\(--muted-contrast\)\}/);
 assert.match(css,/\.housing-society-network \.hs-finance-summary small\{display:block;color:var\(--muted-contrast\);font-size:9px\}/);
});

test('authenticated query reads fail closed against stale browser or intermediary caches',()=>{
 assert.match(apiClient,/fetch\(path,\{headers,cache:"no-store"\}\)/);
 assert.match(responseRuntime,/"cache-control":"private, no-store, max-age=0"/);
});

test('crawler enforces its budget inside the candidate-action loop',()=>{
 assert.match(crawler,/if\(Date\.now\(\)-started>=timeBudgetMs\)\{budgetExhausted=true;break;\}/);
 assert.match(crawler,/timeout:Math\.min\(3500,remaining\)/);
});

test('surface navigation confirms React hydration before returning',()=>{
 assert.match(helper,/for\(let attempt=0;attempt<3;attempt\+\+\)/);
 assert.match(helper,/classList\.contains\('active'\)/);
 assert.match(helper,/should become active after navigation/);
});

test('late-hydrated navigation activates the surface after waiting',()=>{
 assert.match(helper,/target=visible\(`qa-nav-\$\{id\}`\)/);
 assert.match(helper,/await activate\(target,`surface \$\{id\}`\)/);
});

test('optional push infrastructure is a clean suppression, not a service outage',()=>{
 assert.match(pushRoute,/suppressed:"push_server_unconfigured"/);
 assert.match(pushRoute,/suppressed:"vapid_unconfigured"/);
 assert.doesNotMatch(pushRoute,/Push server is not configured\."\},\{status:503/);
});

test('D12 connected certification serializes the shared disposable QA identity',()=>{
 assert.match(d12Workflow,/group: d12-connected-certification\n\s+cancel-in-progress: false/);
 assert.match(d12Workflow,/head_match/);
});
