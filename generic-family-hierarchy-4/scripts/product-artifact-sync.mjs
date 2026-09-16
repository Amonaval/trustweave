import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

export const productArtifacts=[
  'TRUSTWEAVE-PUBLIC-PRODUCT-PROFILE.html',
  'TRUSTWEAVE-PRODUCT-EVOLUTION-JOURNEY.html',
  'TRUSTWEAVE-PRODUCT-FEATURE-HANDBOOK.html',
  'GENERIC-NETWORK-OS-VISION.html',
  'TRUSTWEAVE-FOUNDER-AUTONOMOUS-WORKING-MODEL.html'
];

const root=process.cwd();
const targetRoot=path.join(root,'public','artifacts');
const digest=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const check=process.argv.includes('--check');
fs.mkdirSync(targetRoot,{recursive:true});
const results=[];
for(const name of productArtifacts){
  const source=path.join(root,name),target=path.join(targetRoot,name);
  if(!fs.existsSync(source)){results.push({name,status:'MISSING_SOURCE'});continue}
  const current=fs.existsSync(target)&&digest(source)===digest(target);
  if(!check&&!current)fs.copyFileSync(source,target);
  results.push({name,status:current||!check?'PASS':'STALE'});
}
for(const result of results)console.log(`${result.status==='PASS'?'PASS':'FAIL'} ${result.name} — ${result.status}`);
if(results.some(x=>x.status!=='PASS'&&check))process.exit(1);
