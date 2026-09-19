import {test} from "node:test";
import {strict as assert} from "node:assert";
import {existsSync,readFileSync,readdirSync} from "node:fs";
import {DATA_BOUNDARY_MANIFEST} from "../../core/api/data-boundary-manifest";

test("D6 migrated data boundaries have owned routes/services, real schema references and no client RPC leakage",()=>{
 const schema=readdirSync("supabase/migrations").filter(f=>f.endsWith(".sql")).map(f=>readFileSync(`supabase/migrations/${f}`,"utf8")).join("\n").toLowerCase();
 for(const [id,boundary] of Object.entries(DATA_BOUNDARY_MANIFEST)){
  for(const path of [boundary.clientAdapter,boundary.serverService,boundary.queryRoute,boundary.commandRoute])assert.ok(existsSync(path),`${id}: missing ${path}`);
  assert.equal(boundary.idempotency,"required");
  assert.equal(boundary.privacy,"authenticated-network-context-rpc-rls");
  for(const table of boundary.persistenceNamespace)assert.ok(schema.includes(table.toLowerCase()),`${id}: missing table ${table}`);
  const client=readFileSync(boundary.clientAdapter,"utf8");
  const service=readFileSync(boundary.serverService,"utf8");
  for(const rpc of boundary.rpcs){
   assert.ok(schema.includes(rpc.toLowerCase()),`${id}: unknown RPC ${rpc}`);
   assert.equal(client.includes(`.rpc("${rpc}"`),false,`${id}: migrated RPC leaked back into client adapter: ${rpc}`);
   assert.ok(service.includes(`"${rpc}"`),`${id}: server service does not own migrated RPC ${rpc}`);
  }
  const commandRoute=readFileSync(boundary.commandRoute,"utf8");
  assert.match(commandRoute,/idempotency:"required"/);
  const queryRoute=readFileSync(boundary.queryRoute,"utf8");
  assert.match(queryRoute,/executeQuery/);
 }
});

test("FCA admin responsibilities no longer live in generic template-product remote",()=>{
 const generic=readFileSync("capabilities/template-product/remote.ts","utf8");
 for(const name of ["get_fca_admin_snapshot","update_fca_settings","upsert_fca_membership_year","set_fca_family_membership","assign_fca_role","add_fca_finance_entry"]){
  assert.equal(generic.includes(name),false,`generic remote still owns FCA RPC: ${name}`);
 }
});
