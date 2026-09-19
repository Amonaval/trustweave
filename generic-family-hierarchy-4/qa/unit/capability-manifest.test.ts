import {test} from "node:test";
import {strict as assert} from "node:assert";
import {existsSync,readFileSync,readdirSync} from "node:fs";
import {CAPABILITY_MANIFEST,getCapabilityContract} from "../../core/verticals/capability-manifest";
import {NETWORK_VERTICAL_KINDS} from "../../core/verticals/kinds";
import {getVerticalManifest} from "../../app-shell/vertical-manifest";

test("each advertised capability resolves to one owned contract with real source and API route references",()=>{
 const ownedRoutes=new Map<string,string>();
 const schema=readdirSync("supabase/migrations").filter(file=>file.endsWith(".sql")).map(file=>readFileSync(`supabase/migrations/${file}`,"utf8")).join("\n").toLowerCase();
 for(const [id,entry] of Object.entries(CAPABILITY_MANIFEST)){
  assert.equal(getCapabilityContract(id),entry);
  assert.ok(entry.owner&&existsSync(entry.source),`${id}: source missing`);
  if(entry.policyAdapter)assert.ok(existsSync(entry.policyAdapter),`${id}: policy adapter missing`);
  assert.equal(entry.loadingBoundary,"current-shared-bundle");
  assert.equal(entry.observability,"not-standardized");
  for(const table of entry.persistenceNamespace){
   assert.match(table,/^public\.[a-z_]+$/);
   assert.ok(schema.includes(table),`${id}: unknown persistence reference: ${table}`);
  }
  for(const route of entry.apiRoutes){
   assert.ok(existsSync(route),`${id}: route missing: ${route}`);
   assert.equal(ownedRoutes.has(route),false,`${id}: route also owned by ${ownedRoutes.get(route)}`);
   ownedRoutes.set(route,id);
  }
 }
 for(const kind of NETWORK_VERTICAL_KINDS){
  for(const id of getVerticalManifest(kind).definition.capabilities){
   assert.equal(getCapabilityContract(id),CAPABILITY_MANIFEST[id]);
  }
 }
});

test("unknown capability strings are denied, including object prototype keys",()=>{
 for(const id of ["domain.school","__proto__","constructor",""]){
  assert.throws(()=>getCapabilityContract(id),/Unknown capability/);
 }
});
