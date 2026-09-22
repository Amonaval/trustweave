import {test} from "node:test";
import {strict as assert} from "node:assert";
import {readFileSync} from "node:fs";
import {ERROR_BUDGET_POLICY,SLO_MANIFEST,evaluateSloWindow,operationMeta} from "../../core/observability/contracts";
import {processTelemetrySnapshot,recordApiObservation,recordOperationalEvent,resetProcessTelemetryForTests,telemetryTag} from "../../server/observability/telemetry";
import {backgroundRuntimeHealth} from "../../server/jobs/dispatcher";

test("D9 telemetry uses privacy-safe tags and never emits raw actor/network identifiers",()=>{
 resetProcessTelemetryForTests();
 const lines:string[]=[];const original=console.info;console.info=(v?:unknown)=>lines.push(String(v));
 try{
  recordApiObservation({kind:"query",name:"housingOperations.snapshot",requestId:"req-1",actorId:"user-sensitive-123",networkId:"network-sensitive-456",outcome:"success",durationMs:1300});
  recordOperationalEvent("sample",{actorId:"user-sensitive-123",networkId:"network-sensitive-456",email:"private@example.com",message:"secret"});
 }finally{console.info=original}
 const joined=lines.join("\n");
 assert.equal(joined.includes("user-sensitive-123"),false);
 assert.equal(joined.includes("network-sensitive-456"),false);
 assert.equal(joined.includes("private@example.com"),false);
 assert.equal(joined.includes("secret"),false);
 assert.match(joined,/actorTag/);assert.match(joined,/networkTag/);assert.match(joined,/\[redacted\]/);
 assert.equal(telemetryTag("abc"),telemetryTag("abc"));
 assert.notEqual(telemetryTag("abc"),"abc");
});

test("D9 operation metadata supplies capability, journey and slow threshold",()=>{
 const known=operationMeta("query","housingOperations.snapshot");
 assert.equal(known.capability,"domain.housing-society");
 assert.equal(known.journey,"housing.operations");
 assert.equal(known.slowMs,1200);
 const fallback=operationMeta("query","future.unknown");
 assert.equal(fallback.capability,"unmapped");
 assert.equal(fallback.journey,"api.read");
});

test("D9 bounded process telemetry produces slow/failure journey signals",()=>{
 resetProcessTelemetryForTests();const original=console.info;console.info=()=>{};
 try{
  recordApiObservation({kind:"query",name:"housingOperations.snapshot",requestId:"r1",actorId:"u1",networkId:"n1",outcome:"success",durationMs:1400});
  recordApiObservation({kind:"query",name:"housingOperations.snapshot",requestId:"r2",actorId:"u2",networkId:"n1",outcome:"failure",durationMs:200,errorCode:"COMMAND_FAILED"});
 }finally{console.info=original}
 const snap=processTelemetrySnapshot();
 assert.equal(snap.samples,2);assert.equal(snap.failures,1);assert.equal(snap.slow,1);
 assert.deepEqual(snap.byJourney.find(x=>x.journey==="housing.operations"),{journey:"housing.operations",total:2,failures:1,slow:1});
});

test("D9 SLO evaluation exposes error-budget exhaustion and insufficient samples",()=>{
 const housing=SLO_MANIFEST.find(x=>x.id==="housing-operations")!;
 const insufficient=evaluateSloWindow(housing,[{journey:"housing.operations",outcome:"success",durationMs:100}]);
 assert.equal(insufficient.status,"insufficient-samples");
 const events=Array.from({length:100},(_,i)=>({journey:"housing.operations",outcome:i===0?"failure" as const:"success" as const,durationMs:500}));
 const breached=evaluateSloWindow(housing,events);
 assert.equal(breached.status,"slo-breached");
 assert.ok(breached.errorBudgetConsumedPct>100);
 assert.equal(ERROR_BUDGET_POLICY.releaseFreezeAtConsumedPct,100);
 assert.equal(SLO_MANIFEST.find(x=>x.id==="direct-entry")?.measurement,"external-browser-required");
});

test("D9 health and background contracts are honest about current durability",()=>{
 assert.deepEqual(backgroundRuntimeHealth(),{status:"unconfigured",durable:false,mode:"none"});
 const health=readFileSync("app/api/health/route.ts","utf8");
 assert.match(health,/operationalHealthSnapshot/);
 assert.doesNotMatch(health,/processTelemetrySnapshot/);
});

test("D9 query/command logging delegates to the standardized observation runtime",()=>{
 const response=readFileSync("server/shared/response.ts","utf8");
 assert.match(response,/recordApiObservation/);
 assert.doesNotMatch(response,/type:"network_os_command"/);
 assert.doesNotMatch(response,/type:"network_os_query"/);
 const telemetry=readFileSync("server/observability/telemetry.ts","utf8");
 assert.match(telemetry,/network_os_observation/);
 assert.match(telemetry,/MAX_EVENTS=2000/);
});
