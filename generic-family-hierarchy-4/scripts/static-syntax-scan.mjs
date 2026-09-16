import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
import {execFileSync} from 'node:child_process';
const require=createRequire(import.meta.url);
let ts;
try { ts=require('typescript'); } catch {
  const globalRoot=execFileSync('npm',['root','-g'],{encoding:'utf8'}).trim();
  ts=require(path.join(globalRoot,'typescript'));
}

const roots=['app','app-shell','capabilities','components','core','lib','templates','verticals','qa'];
const files=[];
function walk(dir){
  for(const entry of fs.readdirSync(dir,{withFileTypes:true})){
    const full=path.join(dir,entry.name);
    if(entry.isDirectory()) walk(full);
    else if(/\.(ts|tsx)$/.test(entry.name)) files.push(full);
  }
}
for(const root of roots) if(fs.existsSync(root)) walk(root);
if(fs.existsSync('TemplateNetworkApp.tsx')) files.push('TemplateNetworkApp.tsx');

let failures=0;
for(const file of files){
  const source=fs.readFileSync(file,'utf8');
  const result=ts.transpileModule(source,{
    fileName:file,
    reportDiagnostics:true,
    compilerOptions:{target:ts.ScriptTarget.ES2022,module:ts.ModuleKind.ESNext,jsx:ts.JsxEmit.Preserve}
  });
  const errors=(result.diagnostics||[]).filter(d=>d.category===ts.DiagnosticCategory.Error);
  if(!errors.length) continue;
  failures++;
  console.error(`\n${file}`);
  for(const d of errors) console.error(ts.flattenDiagnosticMessageText(d.messageText,' '));
}
console.log(`Static syntax scan: ${files.length} TS/TSX files, ${failures} file(s) with syntax errors.`);
if(failures) process.exit(1);
