import fs from "node:fs";

const read=p=>fs.readFileSync(p,"utf8");
const en=read("lib/i18n/messages/en.ts");
const runner=read("capabilities/launch-seed/runner.ts");
const remote=read("capabilities/launch-seed/remote.ts");
const family=read("capabilities/launch-seed/family-community.ts");
const housing=read("capabilities/launch-seed/housing.ts");
const loader=read("components/shared/LaunchDemoDataLoader.tsx");
const migration=read("supabase/migrations/115_mission1_runtime_seed_integrity.sql");
const dataset=read("capabilities/launch-seed/dataset.ts");
const checks=[];
const ok=(name,pass)=>checks.push([name,Boolean(pass)]);

for(const key of ["PendingApprovalsTxt","NeedsAttentionTxt","ComingUpTxt","ImportantTxt"]){
 const count=(en.match(new RegExp(`\\b${key}\\s*:`,"g"))||[]).length;
 ok(`English token ${key} has exactly one definition`,count===1);
}
ok("lineage supports partial/error recovery",runner.includes('"partial"')&&runner.includes('"error"')&&migration.includes("'partial','error'"));
ok("seed runner checkpoints created ids before follow-up state",runner.includes("async checkpoint("));
ok("seed runner records structured action errors",runner.includes("async action(")&&runner.includes("recordLaunchSeedRunIssue"));
ok("dry run retries partial/error lineage",dataset.includes('prior.status==="committed"||prior.status==="skipped"||prior.status==="warning"'));
ok("persistent seed run tables exist",migration.includes("create table if not exists public.launch_demo_seed_runs")&&migration.includes("create table if not exists public.launch_demo_seed_issues"));
ok("persistent seed report RPC exists",migration.includes("get_launch_demo_seed_run_report"));
ok("seed relationship adapter requires authorization",migration.includes("launch_demo_create_relationship")&&migration.includes("Authorized launch dataset required."));
ok("Family seed bypasses interactive 40/min relationship command",family.includes("createLaunchSeedRelationship")&&!family.includes("createNetworkEntityRelationship"));
ok("Family ballot options precede state transition",family.indexOf('sectionRows(data,"governance.ballot_options")')<family.indexOf('runner.action("governance.ballot_state"'));
ok("Housing ballot options precede state transition",housing.indexOf('sectionRows(data,"governance.ballot_options")')<housing.indexOf('runner.action("governance.ballot_state"'));
ok("ballot seeding adopts existing draft/options",family.includes("reusableBallot")&&family.includes("existingOption")&&housing.includes("reusableBallot")&&housing.includes("existingOption"));
ok("authorized demo ballot fallback is narrow",migration.includes("launch_demo_open_ballot")&&migration.includes("family_representatives")&&migration.includes("launch_demo_seed_operator"));
ok("storage metadata size helper accepts multiple storage-api shapes",migration.includes("storage_object_metadata_bytes")&&migration.includes("contentLength")&&migration.includes("content_length"));
const guardBody=migration.slice(migration.indexOf("create or replace function public.a5_storage_guard"),migration.indexOf("create or replace function public.a5_storage_account"));
ok("storage guard no longer rejects unknown BEFORE-trigger byte size",!guardBody.includes("bytes<=0")&&!guardBody.includes("bytes <= 0"));
ok("media registry revalidates uploaded object and concrete bytes",migration.includes("Uploaded media object was not found")&&migration.includes("Uploaded image size could not be verified after upload"));
ok("seed UI exposes run id + downloadable structured report",loader.includes("qa-launch-download-report")&&loader.includes("Seed run:")&&loader.includes("result.report"));
ok("seed remote exposes run diagnostics + launch adapters",remote.includes("startLaunchSeedRun")&&remote.includes("recordLaunchSeedRunIssue")&&remote.includes("createLaunchSeedRelationship")&&remote.includes("openLaunchSeedBallot"));
ok("PostgREST schema cache reload follows Mission 1 RPCs",migration.includes("notify pgrst, 'reload schema'"));

let failed=0;for(const [name,pass] of checks){console.log(`${pass?"PASS":"FAIL"}  ${name}`);if(!pass)failed++;}
console.log(`\nMission 1 runtime/seed integrity gate: ${checks.length-failed}/${checks.length} passed.`);
if(failed)process.exit(1);
