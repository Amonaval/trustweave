import fs from "node:fs";

const read=path=>fs.readFileSync(path,"utf8");
const checks=[];
const ok=(name,condition)=>checks.push([name,Boolean(condition)]);

const css=read("app/globals.css");
const shell=read("components/NetworkApp.tsx");
const template=read("components/TemplateNetworkApp.tsx");
const publicDiscovery=read("components/PublicDiscoveryPortal.tsx");
const detail=read("components/shared/CommunityObjectDetail.tsx");
const activityRemote=read("capabilities/activity/remote.ts");
const fundsPanel=read("components/shared/NetworkFundsPanel.tsx");
const votingPanel=read("components/shared/NetworkVotingPanel.tsx");
const voting=read("components/shared/NetworkVotingPanel.tsx");
const runner=read("capabilities/launch-seed/runner.ts");
const lineageMigration=read("supabase/migrations/113_final_launch_demo_seed_lineage.sql");
const config=read("templates/productized/config.ts");
const adapter=read("showcase-data/family-community-playground.ts");
const launch=JSON.parse(read("public/launch-demo/family-community-20-families.json"));

ok("1 residential mobile hero has narrow-screen stabilization",
 css.includes(".hs-chairman-hero")&&
 css.includes(".hs-chairman-actions")&&
 css.includes("@media(max-width:560px)")
);

ok("2 Family Playground clears stale vertical demos before using explicit Family composition",
 shell.includes('const familyComposition=getRenderableVerticalRuntime("family").app')&&
 shell.includes("setProductizedDemo(null)")&&
 shell.includes("setAlumniDemo(false)")
);

ok("3 signed-out Discovery exposes theme/language controls and dark-surface styling",
 publicDiscovery.includes("<ThemeSwitcher compact/>")&&
 publicDiscovery.includes("<LanguageSwitcher compact/>")&&
 css.includes('[data-theme="dark"] .public-discovery-topbar')
);

ok("4 event detail exposes Going and Tentative participant identities",
 detail.includes("fetchNetworkEventRsvps")&&
 detail.includes("Who’s coming")&&
 detail.includes('"Tentative"')&&
 detail.includes("row.memberLabel")
);

ok("5 mobile More navigation accounts for device safe area",
 template.includes('data-testid="qa-mobile-nav-more"')&&
 css.includes("padding-bottom:max(6px,env(safe-area-inset-bottom))")
);

ok("6 Housing statutory committee election is distinct from ordinary member poll",
 voting.includes("Maharashtra committee-election process")&&
 voting.includes("statutoryHousingElection")&&
 voting.includes("TrustWeave does not currently cast the statutory housing-society poll online")&&
 voting.includes("!statutoryHousingElection")
);

ok("7 launch seed reruns consume network-scoped lineage and reuse existing remote ids",
 runner.includes("for(const row of lineage)this.prior.set")&&
 runner.includes("mutate(prior?.remoteId||null)")&&
 runner.includes("Skipped ${rowRef} — unchanged.")&&
 lineageMigration.includes("on conflict(network_id,dataset_version,section_key,row_ref)")
);

ok("FCA-P1 Playground is wired to canonical launch dataset",
 config.includes("familyCommunityPlaygroundEntities")&&
 adapter.includes("family-community-20-families.json")&&
 launch.version==="trustweave-launch-family-community.v1"
);

ok("FCA-P1 read-only object detail stays local and preserves preview member evidence",
 detail.includes("if(readOnly){setComments([])")&&
 detail.includes("activity?.metadata?.preview_rsvps")&&
 detail.includes("group?.previewMembers||[]")&&
 detail.includes("disabled={readOnly}")&&
 activityRemote.includes("previewMembers?:NetworkGroupMember[]")&&
 adapter.includes("preview_rsvps")&&
 adapter.includes("previewMembers:")
);

ok("FCA-P2 Playground Me persona is explicit and demo editing is disabled",
 template.includes('if(demo&&kind==="family-association")')&&
 template.includes('relationships.find(r=>r.relationshipType==="represented_by")')&&
 template.includes('{!demo&&<button className="btn small" onClick={()=>openEditor(myEntity)}')
);

ok("FCA-P2 Funds and Member Decisions use config-backed read-only snapshots",
 config.includes("sampleFunds?:NetworkFundsSnapshot")&&
 config.includes("sampleBallots?:BallotsSnapshot")&&
 adapter.includes("familyCommunityPlaygroundFunds:NetworkFundsSnapshot")&&
 adapter.includes("familyCommunityPlaygroundBallots:BallotsSnapshot")&&
 fundsPanel.includes("if(readOnly){setData(previewData||emptyPreview);return}")&&
 votingPanel.includes("if(readOnly){setData(previewData||emptyPreview);return}")&&
 template.includes("readOnly={demo} previewData={demo?cfg.sampleFunds:null}")&&
 template.includes("readOnly={demo} previewData={demo?cfg.sampleBallots:null}")
);

ok("FCA-P2 demo sharing stays on the public Playground rather than fake sample-network routes",
 read("components/shared/NetworkActivityHub.tsx").includes("readOnly?window.location.href")&&
 detail.includes("readOnly?window.location.href")
);

ok("FCA-P1 canonical MPF dataset has representative pilot depth",
 launch.core_import.families.length===20&&
 launch.core_import.people.length>=60&&
 launch.family_detail.family_relationships.length>=100&&
 launch.membership.role_assignments.length>=8&&
 launch.community.events.length>=6&&
 launch.community.posts.length>=10&&
 launch.community.groups.length>=4
);

for(const [name,pass] of checks)console.log(`${pass?"PASS":"FAIL"} ${name}`);
const failures=checks.filter(([,pass])=>!pass);
if(failures.length){
 console.error(`\nFCA-L1 source gate failed: ${failures.length}`);
 process.exit(1);
}
console.log(`\nFCA-L1 pilot-proof source gate passed (${checks.length} checks).`);
