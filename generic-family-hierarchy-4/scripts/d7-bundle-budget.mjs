import {existsSync,readFileSync,statSync} from "node:fs";
import {join} from "node:path";

const manifestPath=".next/app-build-manifest.json";
if(!existsSync(manifestPath))throw new Error("D7 bundle budget requires .next/app-build-manifest.json after next build.");
const manifest=JSON.parse(readFileSync(manifestPath,"utf8"));
const pages=manifest.pages||{};
const routeKey=pages["/page"]?"/page":Object.keys(pages).filter(k=>k.endsWith("/page")).sort((a,b)=>a.length-b.length)[0];
if(!routeKey)throw new Error(`D7 bundle budget could not find root app page. Keys: ${Object.keys(pages).join(", ")}`);
const files=[...new Set((pages[routeKey]||[]).filter((f)=>f.endsWith(".js")))];
if(!files.length)throw new Error("D7 bundle budget found no root-route JavaScript files.");
const sized=files.map(file=>({file,bytes:statSync(join(".next",file)).size}));
const total=sized.reduce((sum,row)=>sum+row.bytes,0);
const budget=Number(process.env.TRUSTWEAVE_ROOT_ROUTE_JS_BUDGET_BYTES||2_400_000);
console.log(`D7 root route JS: ${total} bytes across ${sized.length} chunks (budget ${budget}).`);
for(const row of sized.sort((a,b)=>b.bytes-a.bytes).slice(0,8))console.log(`  ${row.bytes}  ${row.file}`);

const rootSource=files.map(file=>readFileSync(join(".next",file),"utf8")).join("\n");
for(const marker of ["qa-fca-admin-panel","ComplaintSubmittedTxt"]){
 if(rootSource.includes(marker))throw new Error(`D7 lazy vertical marker leaked into root route chunk: ${marker}`);
}
console.log("D7 lazy vertical marker check: PASS");
if(total>budget)throw new Error(`D7 root route JavaScript budget exceeded: ${total} > ${budget} bytes.`);
