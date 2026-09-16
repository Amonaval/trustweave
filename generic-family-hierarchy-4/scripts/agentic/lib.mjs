import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {execFileSync,spawnSync} from 'node:child_process';

export const ROOT=process.cwd();
export const readJson=p=>JSON.parse(fs.readFileSync(path.resolve(ROOT,p),'utf8'));
export const writeJson=(p,v)=>{const f=path.resolve(ROOT,p);fs.mkdirSync(path.dirname(f),{recursive:true});fs.writeFileSync(f,JSON.stringify(v,null,2)+'\n')};
export const exists=p=>fs.existsSync(path.resolve(ROOT,p));
export const read=p=>fs.readFileSync(path.resolve(ROOT,p),'utf8');
export const sha256=s=>crypto.createHash('sha256').update(s).digest('hex');
export function candidateSha(){
  try{return execFileSync('git',['rev-parse','HEAD'],{cwd:ROOT,encoding:'utf8',stdio:['ignore','pipe','ignore']}).trim()}catch{}
  const extensions=['.ts','.tsx','.js','.mjs','.json','.md','.css','.sql','.yml','.yaml','.toml','.cjs'];
  const ignore=['release-evidence','archive','qa-results','node_modules','.next','.agent-worktrees','.git','missions/mission-003/m3-b6-e1/review.json','missions/mission-003/m3-b6-e1/EVIDENCE.md','missions/mission-003/m3-b6-e1/metrics.json'];
  const files=walk('.',{extensions,ignore}).sort();const h=crypto.createHash('sha256');
  for(const file of files){h.update(file);h.update('\0');h.update(fs.readFileSync(path.resolve(ROOT,file)));h.update('\0')}
  return `snapshot-${h.digest('hex').slice(0,24)}`;
}
export function walk(dir,{extensions=null,ignore=[]}={}){
  const out=[];const abs=path.resolve(ROOT,dir);if(!fs.existsSync(abs))return out;
  const visit=d=>{for(const e of fs.readdirSync(d,{withFileTypes:true})){const full=path.join(d,e.name);const rel=path.relative(ROOT,full).replaceAll('\\','/');if(ignore.some(x=>rel===x||rel.startsWith(`${x}/`)))continue;if(e.isDirectory())visit(full);else if(!extensions||extensions.some(ext=>rel.endsWith(ext)))out.push(rel)}};visit(abs);return out;
}
export function treeHash(dir){
  const files=walk(dir).sort();const h=crypto.createHash('sha256');for(const f of files){h.update(f);h.update('\0');h.update(fs.readFileSync(path.resolve(ROOT,f)));h.update('\0')}return h.digest('hex');
}
export function parseArgs(argv=process.argv.slice(2)){
  const args={_:[]};for(let i=0;i<argv.length;i++){const a=argv[i];if(!a.startsWith('--')){args._.push(a);continue}const k=a.slice(2);const n=argv[i+1];if(n&&!n.startsWith('--')){args[k]=n;i++}else args[k]=true}return args;
}
export function runShell(command,{cwd=ROOT,timeout=15*60*1000,env={}}={}){
  const shell=process.platform==='win32'?'cmd.exe':'bash';const shellArgs=process.platform==='win32'?['/d','/s','/c',command]:['-lc',command];
  const startedAt=new Date().toISOString();const r=spawnSync(shell,shellArgs,{cwd,env:{...process.env,...env},encoding:'utf8',timeout,maxBuffer:20*1024*1024});const finishedAt=new Date().toISOString();
  return {startedAt,finishedAt,status:r.status===0?'PASS':'FAIL',exitCode:r.status,stdout:r.stdout||'',stderr:r.stderr||'',error:r.error?String(r.error):null};
}
export function printChecks(title,checks){let failed=0;for(const [name,pass,detail=''] of checks){console.log(`${pass?'PASS':'FAIL'} ${name}${detail?` — ${detail}`:''}`);if(!pass)failed++}console.log(`${title}: ${checks.length-failed}/${checks.length} passed.`);if(failed)process.exitCode=1;return failed===0}
