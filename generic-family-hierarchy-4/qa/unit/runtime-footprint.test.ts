import {test} from "node:test";
import {strict as assert} from "node:assert";
import {readFileSync,statSync} from "node:fs";

const read=(path:string)=>readFileSync(path,"utf8");

test("D7 universal shell does not statically import productized/alumni UI or heavy productized showcase config",()=>{
 const shell=read("components/NetworkApp.tsx");
 assert.doesNotMatch(shell,/import\s+AlumniNetworkApp\s+from/);
 assert.doesNotMatch(shell,/import\s+TemplateNetworkApp\s+from/);
 assert.doesNotMatch(shell,/templates\/productized\/config/);
 assert.match(shell,/dynamic\(\(\) => import\("\.\/AlumniNetworkApp"\)/);
 assert.match(shell,/dynamic\(\(\) => import\("\.\/TemplateNetworkApp"\)/);
 assert.match(shell,/PRODUCTIZED_RUNTIME_META/);
});

test("D7 productized shell lazy-loads vertical-heavy panels",()=>{
 const shell=read("components/TemplateNetworkApp.tsx");
 for(const name of ["AssociationHome","FamilyAssociationAdminPanel","HousingSocietyCorePanel","HousingSocietyHome","HousingSocietyOperationsPanel","HousingSocietyFinancePanel","HousingSocietyGovernancePanel","HousingSocietySecurityPanel","HousingSocietyPilotPanel","HousingSocietyManageWorkspace"]){
  assert.doesNotMatch(shell,new RegExp(`import\\s+${name}\\s+from`),`${name} must not return to a static productized-shell import`);
  assert.match(shell,new RegExp(`dynamic\\(\\(\\) => import\\("\\.\\/${name}"\\)`),`${name} must stay lazy`);
 }
 assert.doesNotMatch(shell,/import\s+\{recordHsPilotUsageEvent\}\s+from/);
 assert.match(shell,/import\("\.\.\/verticals\/housing-society\/runtime\/pilot-remote"\)/);
});

test("D7 manifest/composition startup metadata cannot import the heavy productized showcase dataset",()=>{
 const paths=[
  "app-shell/vertical-manifest.ts",
  "verticals/association/runtime/composition.ts",
  "verticals/family-association/runtime/composition.ts",
  "verticals/housing-society/runtime/composition.ts",
  "verticals/organization/runtime/composition.ts",
  "verticals/business-trust/runtime/composition.ts",
  "verticals/franchise/runtime/composition.ts",
  "verticals/professional/runtime/composition.ts",
 ];
 for(const path of paths)assert.doesNotMatch(read(path),/templates\/productized\/config/,`${path} reintroduced heavy showcase config into startup metadata`);
 assert.ok(statSync("templates/productized/runtime-meta.ts").size<12_000,"lightweight runtime metadata exceeded 12 KB source budget");
});

test("D7 heavy showcase config remains behind the lazy productized shell",()=>{
 const heavyImporters=["components/TemplateNetworkApp.tsx"];
 for(const path of heavyImporters)assert.match(read(path),/templates\/productized\/config/);
});

test("D7 production budget distinguishes Next dynamic chunks from startup chunks",()=>{
 const budget=read("scripts/d7-bundle-budget.mjs");
 assert.match(budget,/react-loadable-manifest\.json/);
 assert.match(budget,/routeFiles\.filter\(file=>!lazyFiles\.has\(file\)\)/);
 assert.match(budget,/lazy vertical startup-marker check/);
});
