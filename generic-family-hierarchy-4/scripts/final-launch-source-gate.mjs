import fs from 'node:fs';
const read=p=>fs.readFileSync(new URL(`../${p}`,import.meta.url),'utf8');
const exists=p=>fs.existsSync(new URL(`../${p}`,import.meta.url));
const publicPortal=read('components/PublicDiscoveryPortal.tsx');
const networkApp=read('components/NetworkApp.tsx');
const loader=read('components/shared/LaunchDemoDataLoader.tsx');
const template=read('components/TemplateNetworkApp.tsx');
const dataset=read('capabilities/launch-seed/dataset.ts');
const orchestrator=read('capabilities/launch-seed/index.ts');
const housing=read('capabilities/launch-seed/housing.ts');
const family=read('capabilities/launch-seed/family-community.ts');
const importer=read('capabilities/import/productized-workbook.ts');
const migration=read('supabase/migrations/113_final_launch_demo_seed_lineage.sql');
const checks=[
 ['anonymous shell delegates to public Discovery portal',networkApp.includes('<PublicDiscoveryPortal')&&networkApp.includes('onSignIn={()=>setShowAuth(true)}')],
 ['public front door exposes Housing, Community, Playground, Guide and sign-in anchors',['qa-explore-housing','qa-explore-community','qa-public-playground','qa-product-guide','qa-open-auth'].every(x=>publicPortal.includes(x))],
 ['public guide has Simple/Detailed/Deep progressive depth',publicPortal.includes('guideLevel==="simple"')&&publicPortal.includes('guideLevel==="detailed"')&&publicPortal.includes('guideLevel==="deep"')],
 ['public guide explicitly excludes confidential/unreleased material',/founder-private strategy, confidential architecture, anti-abuse internals or unreleased IP material/i.test(publicPortal)],
 ['bundled residential and family-community JSON/XLSX datasets exist',['public/launch-demo/residential-25-flats.json','public/launch-demo/residential-25-flats.xlsx','public/launch-demo/family-community-20-families.json','public/launch-demo/family-community-20-families.xlsx'].every(exists)],
 ['dataset parser requires exact version + synthetic=true',dataset.includes('input.version!==expected')&&dataset.includes('input.synthetic!==true')],
 ['cross-reference dry run is wired before commit',dataset.includes('validateLaunchReferences')&&orchestrator.includes('if(!dryRun.valid)throw new Error')],
 ['seed authorization is active-network scoped and exact-name confirmed',migration.includes("nid uuid:=public.current_network_id()")&&migration.includes("trim(coalesce(p_confirm_network_name,''))<>nname")],
 ['real-looking networks require explicit override',migration.includes('if not demo_like and not coalesce(p_allow_real_network,false)')],
 ['direct seed lineage table access is closed',migration.includes('revoke all on public.launch_demo_seed_authorizations,public.launch_demo_seed_lineage from anon,authenticated')],
 ['lineage stores stable row reference + payload hash',migration.includes('row_ref varchar')&&migration.includes('payload_hash varchar')&&migration.includes('primary key(network_id,dataset_version,section_key,row_ref)')],
 ['loader requires explicit synthetic confirmation and exact network name',loader.includes('qa-launch-synthetic-confirm')&&loader.includes('qa-launch-confirm-name')&&loader.includes('confirmName===networkName')],
 ['loader exposes pre-commit create/update/skip/errors dry run',loader.includes('qa-launch-dry-run')&&loader.includes('dryRun.totals.create')&&loader.includes('dryRun.totals.update')&&loader.includes('dryRun.totals.skip')],
 ['loader is only attached to persisted Residential / Family Community admin',template.includes('kind==="housing-society"&&<HousingSocietyManageWorkspace')&&template.includes('kind==="family-association"&&<LaunchDemoDataLoader')&&template.includes('!demo')],
 ['FCA guided importer persists annual association membership',importer.includes('association_membership')&&importer.includes('upsertFcaMembershipYear')&&importer.includes('setFcaFamilyMembership')],
 ['Residential adapter uses guided core and real domain APIs',housing.includes('commitHousingWorkbook')&&housing.includes('createHsComplaint')&&housing.includes('recordHsPayment')&&housing.includes('saveNetworkBallot')&&housing.includes('uploadMediaAsset')],
 ['Family Community adapter uses guided core and real domain APIs',family.includes('commitProductizedWorkbook')&&family.includes('setFcaFamilyMembership')&&family.includes('recordNetworkFundTransaction')&&family.includes('saveNetworkBallot')&&family.includes('createNetworkPost')&&family.includes('uploadMediaAsset')],
 ['seed adapters do not insert notification rows directly',!housing.includes('.from("network_notifications")')&&!family.includes('.from("network_notifications")')&&!housing.includes(".from('network_notifications')")&&!family.includes(".from('network_notifications')")],
 ['account-only RSVP/group intent is constrained instead of fabricating auth users',family.includes('Synthetic directory people are not fabricated as login accounts')&&family.includes('Network groups are account memberships')],
 ['no destructive launch reset RPC exists',!migration.includes('reset_launch_demo')&&!migration.includes('truncate ')],
 ['launch closure documentation exists',['LAUNCH-READINESS-REPORT.md','PILOT-DEMO-RUNBOOK.md','DATA-SEED-RUNBOOK.md','RUNTIME-VERIFICATION-CHECKLIST.md','FINAL-RELEASE-MANIFEST.md','MISSION-1-RUNTIME-SEED-INTEGRITY-CLOSURE.md','MISSION-1-APPLY-RETEST-RUNBOOK.md','MISSION-2-SLOW-USER-REGRESSION-CLOSURE.md'].every(exists)],
 ['launch-specific runtime certification specs exist',exists('qa/e2e/25-final-launch-discovery.spec.ts')&&exists('qa/e2e/26-final-launch-seed-runtime.spec.ts')],
 ['release evidence directory exists',exists('release-evidence/FINAL-LAUNCH-SOURCE-GATES.txt')&&exists('release-evidence/STATIC-EXTRA-GATES.txt')&&exists('release-evidence/NPM-DEPENDENCY-BLOCKER.txt')],
 ['superseded discovery handoffs archived',exists('archive/docs/missions/launch/NEXT-MISSION-DISCOVERY-PRODUCT-EXPLORATION.md')&&exists('archive/docs/missions/launch/NEXT-SESSION-DISCOVERY-PRODUCT-EXPLORATION.md')&&!exists('NEXT-MISSION-DISCOVERY-PRODUCT-EXPLORATION.md')&&!exists('NEXT-SESSION-DISCOVERY-PRODUCT-EXPLORATION.md')],
];
let failed=0;for(const [name,ok] of checks){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)failed++}
console.log(`Final launch source gate: ${checks.length-failed}/${checks.length}`);if(failed)process.exit(1);
