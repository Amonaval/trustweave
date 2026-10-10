import fs from 'node:fs';
import path from 'node:path';

const root=process.cwd();
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const runtime=read('tools/trustweave_tool/TrustWeaveRuntime.tsx');
const layout=read('app/layout.tsx');
const page=read('app/page.tsx');
const installer=read('scripts/install-runtime-intelligence.mjs');

const R5_2_PIN='3a903eafa55df9697238aed0c1be110c6241a057';
const failures=[];
if(!runtime.includes("from 'runtime-intelligence/react'"))failures.push('TrustWeaveRuntime must consume runtime-intelligence/react');
if(!runtime.includes("from 'runtime-intelligence/panel'"))failures.push('TrustWeaveRuntime must consume the canonical mature panel entry');
if(!runtime.includes('mountRuntimeIntelligencePanel'))failures.push('Canonical mature panel mount is missing');
if(runtime.includes('react-runtime-toolkit'))failures.push('TrustWeaveRuntime still imports the copied legacy toolkit');
if(layout.includes('TrustWeaveRuntimePreload'))failures.push('Legacy preload is still active in RootLayout');
if(page.includes('react-runtime-toolkit'))failures.push('Home still imports the copied legacy profiler');
if(!runtime.includes("process.env.NODE_ENV==='development'"))failures.push('Runtime intelligence must remain development-only');
if(!runtime.includes('source={ROOT_SOURCE}'))failures.push('Root profiler source attribution is missing');
if(!page.includes('source="components/NetworkApp.tsx"'))failures.push('NetworkApp profiler source attribution is missing');
if(!installer.includes(R5_2_PIN))failures.push('Dogfood installer is not pinned to R5.2');

if(failures.length){console.error('Runtime Intelligence source gate failed:\n- '+failures.join('\n- '));process.exit(1);}
console.log('Runtime Intelligence source gate passed. TrustWeave mounts the canonical mature panel over the shared React evidence runtime.');
