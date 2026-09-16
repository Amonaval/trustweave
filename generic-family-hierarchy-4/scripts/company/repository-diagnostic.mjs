import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';

const root=process.cwd();
const out=path.join(root,'qa-results','repository-diagnostic');
fs.mkdirSync(out,{recursive:true});
const sensitiveValues=Object.entries(process.env).filter(([key,value])=>value&&value.length>=8&&/(secret|password|token|key|database_url|service_role)/i.test(key)).map(([,value])=>value).sort((a,b)=>b.length-a.length);
function redact(value=''){let clean=String(value);for(const secret of sensitiveValues)clean=clean.split(secret).join('[REDACTED]');return clean.replace(/eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}/g,'[REDACTED_JWT]').replace(/(password|token|secret|apikey|api_key)=([^\s&]+)/gi,'$1=[REDACTED]')}
const steps=[
  ['artifact-sync','node',['scripts/product-artifact-sync.mjs','--check']],
  ['control-plane','node',['scripts/agentic/control-plane-gate.mjs']],
  ['architecture','node',['scripts/agentic/architecture-gate.mjs']],
  ['documentation','node',['scripts/agentic/documentation-gate.mjs']],
  ['syntax','node',['scripts/static-syntax-scan.mjs']],
  ['types-full','npm',['run','check:types']],
  ['types-app','npm',['run','check:types:app']],
  ['lint','npm',['run','lint:trustweave']],
  ['unit-contracts','npm',['run','qa:unit']],
  ['qa-structure','node',['qa/static-suite-audit.mjs']],
  ['migration-static','node',['qa/db/migration-static-audit.mjs']],
  ['final-launch-source','npm',['run','validate:final-launch-source']],
  ['progressive-ux','npm',['run','validate:ux-progressive']],
  ['mission2-source','npm',['run','validate:mission2']],
  ['production-build','npm',['run','build']],
  ['public-browser-runtime','npm',['run','validate:m3c10']]
];
const results=[];
for(const [name,command,args] of steps){const started=Date.now();const run=spawnSync(command,args,{cwd:root,env:process.env,encoding:'utf8',timeout:20*60*1000,shell:process.platform==='win32'});const stdout=redact(run.stdout||''),stderr=redact(run.stderr||'');fs.writeFileSync(path.join(out,`${name}.log`),`${stdout}\n--- STDERR ---\n${stderr}`);const status=run.error?.code==='ETIMEDOUT'?'BLOCKED':run.status===0?'PASS':'FAIL';results.push({name,command:[command,...args].join(' '),status,exitCode:run.status,durationMs:Date.now()-started,log:`qa-results/repository-diagnostic/${name}.log`,error:run.error?redact(run.error.message):null});console.log(`${status} ${name} — ${results.at(-1).durationMs}ms`)}
const findings=results.filter(x=>x.status!=='PASS').map((x,index)=>({id:`REPO-${String(index+1).padStart(3,'0')}`,severity:x.name.includes('build')||x.name.includes('type')?'P1':'P2',title:`${x.name} ${x.status.toLowerCase()}`,command:x.command,evidence:x.log,error:x.error}));const summary={generatedAt:new Date().toISOString(),profile:'credential-free-complete-repository',status:findings.length?'FAILED':'PASS',secretsIncluded:false,credentialsRequired:false,results,findings,nextConnectedCommand:'npm run company:diagnose:connected',connectedEvidenceDirectory:'qa-results/'};fs.writeFileSync(path.join(out,'SUMMARY.json'),JSON.stringify(summary,null,2)+'\n');const report=['# TrustWeave Credential-Free Repository Diagnostic','',`Generated: ${summary.generatedAt}`,`Status: **${summary.status}**`,'','This scan does not read, print or require Supabase credentials. Connected database/RPC/RLS/role certification remains a separate guarded local run.','','## Results','','| Check | Status | Duration | Evidence |','| --- | --- | ---: | --- |',...results.map(x=>`| ${x.name} | **${x.status}** | ${Math.round(x.durationMs/1000)}s | \`${x.log}\` |`),'','## Findings','',...(findings.length?findings.map(x=>`- **${x.id} [${x.severity}] ${x.title}** — \`${x.evidence}\``):['No deterministic repository or public-runtime findings were detected.']),'','## Connected runtime next step','','Keep credentials only in ignored `.env.qa`, run `npm run company:diagnose:connected` against dedicated staging, then share a ZIP of `qa-results/`. Never include `.env.qa`.'];fs.writeFileSync(path.join(out,'REPORT.md'),report.join('\n')+'\n');fs.writeFileSync(path.join(out,'ISSUES.json'),JSON.stringify(findings,null,2)+'\n');console.log(`Repository diagnostic ${summary.status}; findings=${findings.length}; report=qa-results/repository-diagnostic/REPORT.md`);if(findings.length)process.exit(1);
