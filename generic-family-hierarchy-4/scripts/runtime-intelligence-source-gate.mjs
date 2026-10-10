import fs from 'node:fs';
import path from 'node:path';

const root=process.cwd();
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const runtime=read('tools/trustweave_tool/TrustWeaveRuntime.tsx');
const layout=read('app/layout.tsx');
const page=read('app/page.tsx');

const failures=[];
if(!runtime.includes("from 'runtime-intelligence/react'"))failures.push('TrustWeaveRuntime must consume runtime-intelligence/react');
if(!runtime.includes("from 'runtime-intelligence/panel'"))failures.push('TrustWeaveRuntime must consume runtime-intelligence/panel');
if(runtime.includes('react-runtime-toolkit'))failures.push('TrustWeaveRuntime still imports the copied legacy toolkit');
if(layout.includes('TrustWeaveRuntimePreload'))failures.push('Legacy preload is still active in RootLayout');
if(page.includes('react-runtime-toolkit'))failures.push('Home still imports the copied legacy profiler');
if(!runtime.includes("process.env.NODE_ENV==='development'"))failures.push('Runtime intelligence must remain development-only');

if(failures.length){
  console.error('Runtime Intelligence source gate failed:\n- '+failures.join('\n- '));
  process.exit(1);
}
console.log('Runtime Intelligence source gate passed. TrustWeave consumes the canonical react + panel product surfaces.');
