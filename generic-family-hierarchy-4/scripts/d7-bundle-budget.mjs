import {existsSync,readFileSync,statSync} from "node:fs";
import {join} from "node:path";

const appManifestPath=".next/app-build-manifest.json";
const loadableManifestPath=".next/react-loadable-manifest.json";
if(!existsSync(appManifestPath))throw new Error("D7 bundle budget requires .next/app-build-manifest.json after next build.");
if(!existsSync(loadableManifestPath))throw new Error("D7 bundle budget requires .next/react-loadable-manifest.json after next build.");

const appManifest=JSON.parse(readFileSync(appManifestPath,"utf8"));
const loadableManifest=JSON.parse(readFileSync(loadableManifestPath,"utf8"));
const pages=appManifest.pages||{};
const routeKey=pages["/page"]?"/page":Object.keys(pages).filter(k=>k.endsWith("/page")).sort((a,b)=>a.length-b.length)[0];
if(!routeKey)throw new Error(`D7 bundle budget could not find root app page. Keys: ${Object.keys(pages).join(", ")}`);

const routeFiles=[...new Set((pages[routeKey]||[]).filter((f)=>f.endsWith(".js")))];
if(!routeFiles.length)throw new Error("D7 bundle budget found no root-route JavaScript files.");

const lazyFiles=new Set();
for(const entry of Object.values(loadableManifest)){
 for(const file of entry?.files||[])if(file.endsWith(".js"))lazyFiles.add(file);
}
const startupFiles=routeFiles.filter(file=>!lazyFiles.has(file));
if(!startupFiles.length)throw new Error("D7 bundle budget could not distinguish startup JavaScript from dynamic chunks.");

const sized=startupFiles.map(file=>({file,bytes:statSync(join(".next",file)).size}));
const total=sized.reduce((sum,row)=>sum+row.bytes,0);
const budget=Number(process.env.TRUSTWEAVE_ROOT_ROUTE_JS_BUDGET_BYTES||1_200_000);
console.log(`D7 root startup JS: ${total} raw bytes across ${sized.length} initial chunks; excluded ${routeFiles.length-startupFiles.length} dynamic chunks (budget ${budget}).`);
for(const row of sized.sort((a,b)=>b.bytes-a.bytes).slice(0,8))console.log(`  ${row.bytes}  ${row.file}`);

const startupSource=startupFiles.map(file=>readFileSync(join(".next",file),"utf8")).join("\n");
for(const marker of ["qa-fca-admin-panel","ComplaintSubmittedTxt"]){
 if(startupSource.includes(marker))throw new Error(`D7 lazy vertical marker leaked into root startup chunk: ${marker}`);
}
console.log("D7 lazy vertical startup-marker check: PASS");
if(total>budget)throw new Error(`D7 root startup JavaScript budget exceeded: ${total} > ${budget} bytes.`);
