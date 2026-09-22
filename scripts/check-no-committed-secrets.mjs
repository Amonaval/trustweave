import {execFileSync} from 'node:child_process';
import fs from 'node:fs';

const tracked=execFileSync('git',['ls-files'],{encoding:'utf8'}).split(/\r?\n/).filter(Boolean);
const forbiddenEnv=new Set([
 'generic-family-hierarchy-4/.env',
 'generic-family-hierarchy-4/.env.local',
 'generic-family-hierarchy-4/.env.qa',
 'generic-family-hierarchy-4/.env.qa.release',
 'generic-family-hierarchy-4/.env.d12-candidate',
]);
const findings=[];
for(const path of tracked){
 if(forbiddenEnv.has(path))findings.push(`${path}: tracked runtime env file`);
 if(!fs.existsSync(path)||fs.statSync(path).isDirectory())continue;
 const text=fs.readFileSync(path,'utf8');
 const lines=text.split(/\r?\n/);
 for(let i=0;i<lines.length;i++){
  const line=lines[i];
  if(/sb_secret_[A-Za-z0-9_-]+/.test(line))findings.push(`${path}:${i+1}: Supabase secret key literal`);
  const inspectAssignment=(path.startsWith('.github/workflows/')&&/\.ya?ml$/.test(path))||(/^generic-family-hierarchy-4\/\.env/.test(path)&&!path.endsWith('.example'));
  if(!inspectAssignment)continue;
  const m=line.match(/\b(QA_[A-Z0-9_]*PASSWORD|SUPABASE_SERVICE_ROLE_KEY)\s*[:=]\s*(.+)$/);
  if(!m)continue;
  const rhs=m[2].trim();
  if(!rhs||rhs.includes('secrets.')||rhs.includes('process.env')||rhs.startsWith('${{'))continue;
  findings.push(`${path}:${i+1}: literal value assigned to ${m[1]}`);
 }
}
if(findings.length){
 console.error('Committed secret guard failed:\n'+findings.join('\n'));
 process.exit(1);
}
console.log('Committed secret guard PASS');
