import fs from 'node:fs';
import path from 'node:path';

const root=process.cwd();
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const runtime=read('tools/trustweave_tool/TrustWeaveRuntime.tsx');
const layout=read('app/layout.tsx');
const page=read('app/page.tsx');
const installer=read('scripts/install-runtime-intelligence.mjs');

const CLEAN_R5_PIN='d83c417734e866a3bcd06a9ab8b9a12a7b39cbb6';
const failures=[];
if(!runtime.includes("from 'runtime-intelligence/react'"))failures.push('TrustWeaveRuntime must consume runtime-intelligence/react');
if(runtime.includes("from 'runtime-intelligence/panel'"))failures.push('Temporary lightweight panel must not remain mounted in React dogfood');
if(runtime.includes('mountRuntimeIntelligencePanel'))failures.push('Temporary lightweight panel mount must be removed');
if(runtime.includes('react-runtime-toolkit'))failures.push('TrustWeaveRuntime still imports the copied legacy toolkit');
if(layout.includes('TrustWeaveRuntimePreload'))failures.push('Legacy preload is still active in RootLayout');
if(page.includes('react-runtime-toolkit'))failures.push('Home still imports the copied legacy profiler');
if(!runtime.includes("process.env.NODE_ENV==='development'"))failures.push('Runtime intelligence must remain development-only');
if(!runtime.includes('source={ROOT_SOURCE}'))failures.push('Root profiler source attribution is missing');
if(!page.includes('source="components/NetworkApp.tsx"'))failures.push('NetworkApp profiler source attribution is missing');
if(!installer.includes(CLEAN_R5_PIN))failures.push('Dogfood installer is not pinned to the cleaned R5 runtime commit');

if(failures.length){
  console.error('Runtime Intelligence source gate failed:\n- '+failures.join('\n- '));
  process.exit(1);
}
console.log('Runtime Intelligence source gate passed. TrustWeave keeps canonical React evidence wiring and no longer mounts the discarded lightweight panel.');
