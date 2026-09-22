import {test} from "node:test";
import {strict as assert} from "node:assert";
import {existsSync,mkdtempSync,readFileSync} from "node:fs";
import {tmpdir} from "node:os";
import {join} from "node:path";
import {spawnSync} from "node:child_process";
import {CAPABILITY_MANIFEST} from "../../core/verticals/capability-manifest";
import {NETWORK_VERTICAL_KINDS} from "../../core/verticals/kinds";
import {VERTICAL_MANIFEST} from "../../app-shell/vertical-manifest";
import {thinVerticalIntegrationPlan,thinVerticalReleaseReadiness,validateThinVerticalBlueprint,type ThinVerticalBlueprint} from "../../core/verticals/thin-sdk";

type WorkflowEntry={
 id:string;label:string;category:"A"|"B"|"C"|"D";existingCapabilities:string[];platformPrimitives:string[];
 schoolAdapter:string;schoolOwnedData:string[];routeSurface:string;evidence:string[];rationale:string;
 ownedModule?:string;schoolSpecificDependencies?:string[];
};
type WorkflowMap={version:number;certification:string;summary:Record<"A"|"B"|"C"|"D",number>;newPlatformPrimitives:string[];cDecision:string;workflows:WorkflowEntry[]};

const blueprint=JSON.parse(readFileSync("qa/fixtures/d11-school-blueprint.json","utf8")) as ThinVerticalBlueprint;
const map=JSON.parse(readFileSync("missions/mission-003/m3-d/D11-SCHOOL-WORKFLOW-MAP.json","utf8")) as WorkflowMap;
const requiredRepresentative=[
 "student-guardian-relationships","class-teacher-scoping","notices-actions","field-trip-consent",
 "absence-recovery","homework-tasks","ptm-continuity","school-events","transport-pickup",
 "parent-concerns","student-journey-history"
];

test("D11 representative School workflows are fully classified with evidence",()=>{
 assert.equal(map.version,1);
 assert.equal(map.certification,"architecture-ready-for-bounded-implementation");
 const ids=new Set(map.workflows.map(x=>x.id));
 for(const id of requiredRepresentative)assert.equal(ids.has(id),true,`missing representative workflow ${id}`);
 const counts={A:0,B:0,C:0,D:0};
 for(const item of map.workflows){
  counts[item.category]++;
  assert.ok(item.rationale.length>20,`${item.id} needs rationale`);
  assert.ok(item.evidence.length>0,`${item.id} needs evidence`);
  assert.ok(item.routeSurface.length>0,`${item.id} needs route surface`);
  for(const capability of item.existingCapabilities)assert.ok(Object.prototype.hasOwnProperty.call(CAPABILITY_MANIFEST,capability),`${item.id} references unknown capability ${capability}`);
  if(item.category==="D")assert.match(item.ownedModule||"",/^school\./);
 }
 assert.deepEqual(counts,map.summary);
 assert.deepEqual(map.summary,{A:1,B:9,C:0,D:2});
});

test("D11 records that D4/D5 closed the earlier generic lifecycle gap",()=>{
 assert.deepEqual(map.newPlatformPrimitives,[]);
 assert.equal(map.summary.C,0);
 assert.match(map.cDecision,/D5 workflow\/consent\/audit primitives closed the lifecycle gap/);
});

test("D11 School blueprint passes structural proof but stays fail-closed for implementation adapters",()=>{
 const validation=validateThinVerticalBlueprint(blueprint);
 assert.equal(validation.valid,true,validation.errors.join("; "));
 assert.deepEqual(validation.releaseBlockers,[
  "implement and independently test the vertical policy adapter",
  "implement server-owned query/command API boundary before activation",
  "implement thin workflow adapter over shared primitives before activation",
 ]);
 const readiness=thinVerticalReleaseReadiness(blueprint);
 assert.equal(readiness.ready,false);
 assert.deepEqual(readiness.blockers,[
  "policy adapter not implemented",
  "server API boundary not implemented",
  "workflow adapter not implemented",
 ]);
});

test("D11 School remains absent from production runtime registries and QA activation",()=>{
 assert.equal(NETWORK_VERTICAL_KINDS.includes("school" as never),false);
 assert.equal(Object.prototype.hasOwnProperty.call(VERTICAL_MANIFEST,"school"),false);
 assert.equal(readFileSync("app-shell/vertical-manifest.ts","utf8").includes('"school"'),false);
 assert.equal(readFileSync("templates/productized/runtime-meta.ts","utf8").includes('"school"'),false);
 const qaCatalog=readFileSync("qa/runtime/catalog.mjs","utf8");
 assert.doesNotMatch(qaCatalog,/kind:\s*['"]school['"]/);
 assert.equal(existsSync("verticals/school"),false);
});

test("D11 uses the existing D1 route grammar and D7 lazy boundary",()=>{
 const plan=thinVerticalIntegrationPlan(blueprint);
 assert.equal(plan.kind,"school");
 assert.equal(plan.routePattern,"/network/{networkId}/{surface}");
 assert.equal(plan.loadingBoundary,"lazy-vertical-ui");
 assert.deepEqual(plan.routeSurfaces,["home","students","classes","notices","tasks","ptm","events","attendance","transport","concerns","guide","admin"]);
 assert.deepEqual(plan.requiredCentralEdits.map(x=>x.file),[
  "core/verticals/kinds.ts",
  "core/verticals/capability-manifest.ts",
  "templates/productized/runtime-meta.ts",
  "app-shell/vertical-manifest.ts",
  "qa/runtime/catalog.mjs",
 ]);
});

test("D11 synthetic School proof contains no real-person/institutional records",()=>{
 assert.equal(blueprint.playground.synthetic,true);
 assert.ok(blueprint.playground.entities.length<=50);
 for(const entity of blueprint.playground.entities)assert.match(entity.label,/^Synthetic /);
 assert.match(blueprint.runtimeMeta.sampleDescription,/Synthetic/i);
 assert.match(blueprint.runtimeMeta.sampleDescription,/no real student/i);
});

test("D11 scaffold check and write prove School can be generated without modifying the product tree",()=>{
 const check=spawnSync(process.execPath,["--import","tsx","scripts/vertical-scaffold.ts","--spec","qa/fixtures/d11-school-blueprint.json","--check"],{encoding:"utf8"});
 assert.equal(check.status,0,check.stderr);
 const report=JSON.parse(check.stdout);
 assert.equal(report.validation.valid,true);
 assert.equal(report.plan.kind,"school");
 assert.equal(report.plan.loadingBoundary,"lazy-vertical-ui");
 assert.equal(report.readiness.ready,false);
 assert.equal(existsSync("verticals/school"),false);

 const out=mkdtempSync(join(tmpdir(),"trustweave-d11-school-"));
 const write=spawnSync(process.execPath,["--import","tsx","scripts/vertical-scaffold.ts","--spec","qa/fixtures/d11-school-blueprint.json","--write","--out",out],{encoding:"utf8"});
 assert.equal(write.status,0,write.stderr);
 const generated=join(out,"verticals","school");
 assert.equal(existsSync(join(generated,"definition.ts")),true);
 assert.equal(existsSync(join(generated,"runtime","composition.ts")),true);
 assert.equal(existsSync(join(generated,"runtime","adapters.ts")),true);
 assert.equal(existsSync(join(generated,"playground","seed.ts")),true);
 assert.equal(existsSync(join(generated,"INTEGRATION-PLAN.json")),true);
 for(const file of ["definition.ts","runtime/composition.ts","runtime/adapters.ts"]){
  const source=readFileSync(join(generated,file),"utf8");
  assert.doesNotMatch(source,/\.rpc\(/);
 }
 assert.equal(existsSync("verticals/school"),false);
});

test("D11 School-only capability boundary is narrow",()=>{
 const d=map.workflows.filter(x=>x.category==="D");
 assert.deepEqual(d.map(x=>x.ownedModule).sort(),["school.attendance","school.transport"]);
 const absence=map.workflows.find(x=>x.id==="absence-recovery")!;
 assert.deepEqual(absence.schoolSpecificDependencies,["attendance-recording"]);
});
