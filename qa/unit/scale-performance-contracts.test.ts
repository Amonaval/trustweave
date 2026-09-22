import {test} from "node:test";
import {strict as assert} from "node:assert";
import {readFileSync} from "node:fs";
import {boundedPageSize,evaluateScaleEscalation,SCALE_BUDGETS} from "../../core/scale/contracts";
import {SCALE_INDEX_REQUIREMENTS} from "../../core/scale/index-manifest";
import {boundedGraphWalk} from "../../core/graph/scale";
import {planBackgroundWork} from "../../server/jobs/planner";
import {enforceScopedBurstLimit} from "../../server/shared/rate-limit";

test("D8 page and graph budgets are bounded",()=>{
 assert.equal(boundedPageSize(undefined),50);
 assert.equal(boundedPageSize(0),1);
 assert.equal(boundedPageSize(999),200);
 const edges=Array.from({length:50_000},(_,i)=>({fromEntityId:"root",toEntityId:`n-${i}`}));
 const walk=boundedGraphWalk(edges,"root");
 assert.equal(walk.examinedEdges,SCALE_BUDGETS.graphMaxExaminedEdges);
 assert.ok(walk.nodeIds.length<=SCALE_BUDGETS.graphMaxVisitedNodes);
 assert.equal(walk.truncated,true);
});

test("D8 background work and architecture escalation triggers are explicit",()=>{
 assert.equal(planBackgroundWork(500).mode,"inline");
 assert.equal(planBackgroundWork(501).mode,"external-required");
 assert.equal(evaluateScaleEscalation({tenantTableRows:24_999_999,tenantQueryP95Ms:400,dbPoolUtilization:.8,noisyTenantWorkloadShare:.2,appInstanceCount:1}).partitioningReview,false);
 const signal=evaluateScaleEscalation({tenantTableRows:25_000_000,tenantQueryP95Ms:250,dbPoolUtilization:.70,noisyTenantWorkloadShare:.15,appInstanceCount:2});
 assert.deepEqual(signal,{partitioningReview:true,deploymentStampReview:true,sharedRateLimiterRequired:true});
});

test("D8 tenant burst guard protects a network across different actors",()=>{
 const suffix="d8-scale-contract";
 const common={networkId:`network-${suffix}`,operation:`op-${suffix}`,actorLimit:10,networkLimit:2,windowMs:60_000};
 enforceScopedBurstLimit({...common,actorId:"actor-a"});
 enforceScopedBurstLimit({...common,actorId:"actor-b"});
 assert.throws(()=>enforceScopedBurstLimit({...common,actorId:"actor-c"}),(e:any)=>e?.code==="RATE_LIMITED");
});

test("D8 additive migration supplies network-first indexes and clamped keyset RPCs without partitioning",()=>{
 const sql=readFileSync("supabase/migrations/123_m3d8_multi_tenant_scale_performance.sql","utf8").toLowerCase();
 for(const index of SCALE_INDEX_REQUIREMENTS){
  assert.ok(sql.includes(index.name.toLowerCase()),`missing scale index ${index.name}`);
  assert.ok(sql.includes(index.table.toLowerCase()),`missing scale table ${index.table}`);
 }
 for(const rpc of ["get_network_affiliated_entities_page","get_productized_network_relationships_page","get_productized_network_memberships_page"])assert.ok(sql.includes(rpc));
 assert.match(sql,/limit least\(greatest\(coalesce\(p_limit,/);
 assert.doesNotMatch(sql,/partition\s+by|create\s+table[\s\S]+partition\s+of/);
});

test("D8 paged reads stay behind server API boundaries",()=>{
 const clientA=readFileSync("capabilities/affiliation/remote.ts","utf8");
 const clientT=readFileSync("capabilities/template-product/remote.ts","utf8");
 const service=readFileSync("server/network/scale-service.ts","utf8");
 assert.doesNotMatch(clientA,/\.rpc\("get_network_affiliated_entities_page"/);
 assert.doesNotMatch(clientT,/\.rpc\("get_productized_network_(relationships|memberships)_page"/);
 for(const rpc of ["get_network_affiliated_entities_page","get_productized_network_relationships_page","get_productized_network_memberships_page"])assert.ok(service.includes(rpc));
 for(const route of ["app/api/v1/network/entities/route.ts","app/api/v1/network/relationships/route.ts","app/api/v1/network/members/route.ts"]){
  const source=readFileSync(route,"utf8");assert.match(source,/executeQuery/);assert.match(source,/networkLimit:/);
 }
});

test("D8 bounds synchronous import/export and scopes shared query/command throttling by tenant",()=>{
 const bootstrap=readFileSync("app/api/v1/institutional/bootstrap/route.ts","utf8");
 const exporter=readFileSync("server/network/export-service.ts","utf8");
 const query=readFileSync("server/shared/query-runtime.ts","utf8");
 const command=readFileSync("server/shared/command-runtime.ts","utf8");
 assert.match(bootstrap,/SCALE_BUDGETS\.bootstrapRows/);
 assert.match(exporter,/syncExportStorageObjects/);
 assert.match(exporter,/syncExportDirectories/);
 assert.match(exporter,/EXPORT_REQUIRES_BACKGROUND/);
 assert.match(query,/enforceScopedBurstLimit/);
 assert.match(command,/enforceScopedBurstLimit/);
});
