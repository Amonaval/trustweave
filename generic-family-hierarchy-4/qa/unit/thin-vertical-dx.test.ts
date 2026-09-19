import {test} from "node:test";
import {strict as assert} from "node:assert";
import {mkdtempSync,readFileSync,existsSync,readdirSync} from "node:fs";
import {tmpdir} from "node:os";
import {join} from "node:path";
import {spawnSync} from "node:child_process";
import {NETWORK_VERTICAL_KINDS} from "../../core/verticals/kinds";
import {thinVerticalIntegrationPlan,thinVerticalPlaygroundSeed,thinVerticalReleaseReadiness,validateThinVerticalBlueprint,type ThinVerticalBlueprint} from "../../core/verticals/thin-sdk";

const fixture=JSON.parse(readFileSync("qa/fixtures/d10-thin-vertical.json","utf8")) as ThinVerticalBlueprint;

test("D10 blueprint validation is deterministic and School stays unregistered",()=>{
 const result=validateThinVerticalBlueprint(fixture);
 assert.deepEqual(result.errors,[]);
 assert.equal(result.valid,true);
 assert.deepEqual(result.releaseBlockers,[
  "implement and independently test the vertical policy adapter",
  "implement server-owned query/command API boundary before activation",
 ]);
 assert.equal(NETWORK_VERTICAL_KINDS.includes("school" as never),false);
});

test("D10 route registration and central integration touchpoints are explicit",()=>{
 const plan=thinVerticalIntegrationPlan(fixture);
 assert.equal(plan.loadingBoundary,"lazy-vertical-ui");
 assert.equal(plan.routePattern,"/network/{networkId}/{surface}");
 assert.deepEqual(plan.routeSurfaces,["home","directory","events","admin"]);
 assert.deepEqual(plan.requiredCentralEdits.map(x=>x.file),[
  "core/verticals/kinds.ts",
  "core/verticals/capability-manifest.ts",
  "templates/productized/runtime-meta.ts",
  "app-shell/vertical-manifest.ts",
  "qa/runtime/catalog.mjs",
 ]);
 assert.equal(plan.generatedFiles.length,6);
});

test("D10 release readiness fails closed until owned adapters are implemented",()=>{
 assert.deepEqual(thinVerticalReleaseReadiness(fixture).blockers,[
  "policy adapter not implemented",
  "server API boundary not implemented",
 ]);
 assert.equal(thinVerticalReleaseReadiness(fixture,{policyImplemented:true,apiBoundaryImplemented:true}).ready,true);
 const active={...fixture,status:"active" as const};
 const validation=validateThinVerticalBlueprint(active);
 assert.equal(validation.valid,false);
 assert.ok(validation.errors.includes("active vertical cannot have unresolved release blockers"));
});

test("D10 scaffold rejects hidden capability and route mistakes",()=>{
 const bad={...fixture,surfaces:[...fixture.surfaces,{viewId:"Bad Route",iconToken:"x",label:{en:"Bad",hi:"Bad",mr:"Bad"},capability:"domain.secret"}]};
 const result=validateThinVerticalBlueprint(bad);
 assert.equal(result.valid,false);
 assert.ok(result.errors.some(x=>x.includes("invalid surface viewId")));
 assert.ok(result.errors.some(x=>x.includes("undeclared capability")));
});

test("D10 playground harness is synthetic, bounded and deterministic",()=>{
 const first=thinVerticalPlaygroundSeed(fixture);
 const second=thinVerticalPlaygroundSeed(fixture);
 assert.deepEqual(first,second);
 assert.equal(first.synthetic,true);
 assert.equal(first.network.verticalKind,"civic-circle");
 assert.equal(first.entities.length,3);
 assert.equal(first.relationships.length,2);
});

test("D10 CLI check reports the same plan without writing product files",()=>{
 const result=spawnSync(process.execPath,["--import","tsx","scripts/vertical-scaffold.ts","--spec","qa/fixtures/d10-thin-vertical.json","--check"],{encoding:"utf8"});
 assert.equal(result.status,0,result.stderr);
 const output=JSON.parse(result.stdout);
 assert.equal(output.validation.valid,true);
 assert.equal(output.plan.kind,"civic-circle");
 assert.equal(output.plan.loadingBoundary,"lazy-vertical-ui");
 assert.equal(output.readiness.ready,false);
 assert.equal(existsSync("verticals/civic-circle"),false);
});

test("D10 CLI write produces only deterministic vertical-local scaffold files plus integration plan",()=>{
 const out=mkdtempSync(join(tmpdir(),"trustweave-d10-"));
 const result=spawnSync(process.execPath,["--import","tsx","scripts/vertical-scaffold.ts","--spec","qa/fixtures/d10-thin-vertical.json","--write","--out",out],{encoding:"utf8"});
 assert.equal(result.status,0,result.stderr);
 const base=join(out,"verticals","civic-circle");
 assert.equal(existsSync(join(base,"definition.ts")),true);
 assert.equal(existsSync(join(base,"runtime","composition.ts")),true);
 assert.equal(existsSync(join(base,"runtime","adapters.ts")),true);
 assert.equal(existsSync(join(base,"playground","seed.ts")),true);
 assert.equal(existsSync(join(base,"qa","contracts.test.ts")),true);
 assert.equal(existsSync(join(base,"INTEGRATION-PLAN.json")),true);
 const definition=readFileSync(join(base,"definition.ts"),"utf8");
 const composition=readFileSync(join(base,"runtime","composition.ts"),"utf8");
 const adapters=readFileSync(join(base,"runtime","adapters.ts"),"utf8");
 assert.match(definition,/satisfies VerticalDefinition/);
 assert.match(composition,/satisfies VerticalAppComposition/);
 assert.match(adapters,/ThinVerticalAdapters/);
 assert.match(adapters,/vertical-required/);
 for(const file of [definition,composition,adapters])assert.doesNotMatch(file,/\.rpc\(|school/i);
 const generated=readdirSync(base).sort();
 assert.deepEqual(generated,["INTEGRATION-PLAN.json","definition.ts","features","playground","qa","runtime"]);
});
