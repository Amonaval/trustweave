import {spawnSync} from 'node:child_process';
import {existsSync, readFileSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const PIN='de8d01ead5c75054a613a483c3830917b9bc8ace';
const TARGET=`github:Amonaval/runtime-intelligence#${PIN}`;
const npmCommand=process.platform==='win32'?'npm.cmd':'npm';
const args=['install','--no-save','--package-lock=false',TARGET];
const scriptDir=path.dirname(fileURLToPath(import.meta.url));
const appDir=path.resolve(scriptDir,'..');

function log(label,value=''){
  console.log(`[runtime-intelligence] ${label}${value===''?'':`: ${value}`}`);
}

function resolveProbe(specifier){
  const probe=spawnSync(
    process.execPath,
    ['--input-type=module','-e',`import('${specifier}').then(()=>console.log('RESOLVE_OK')).catch(error=>{console.error(error?.stack||error);process.exit(1)})`],
    {cwd:appDir,encoding:'utf8'}
  );
  log(`resolve ${specifier}`,probe.status===0?'OK':'FAILED');
  if(probe.stdout?.trim()) console.log(probe.stdout.trim());
  if(probe.stderr?.trim()) console.error(probe.stderr.trim());
  return probe.status===0;
}

log('installer started');
log('script',fileURLToPath(import.meta.url));
log('cwd',process.cwd());
log('appDir',appDir);
log('node',process.version);
log('node executable',process.execPath);
log('platform',`${process.platform}/${process.arch}`);
log('npm command',npmCommand);
log('pin',PIN);
log('target',TARGET);
log('command',`${npmCommand} ${args.join(' ')}`);
log('package.json exists',String(existsSync(path.join(appDir,'package.json'))));

try{
  const pkg=JSON.parse(readFileSync(path.join(appDir,'package.json'),'utf8'));
  log('app package',`${pkg.name||'unknown'}@${pkg.version||'unknown'}`);
  log('declared runtime-intelligence dependency',String(Boolean(pkg.dependencies?.['runtime-intelligence']||pkg.devDependencies?.['runtime-intelligence'])));
}catch(error){
  log('package.json read failed',error?.message||String(error));
}

log('starting npm install');
const started=Date.now();
const result=spawnSync(npmCommand,args,{
  cwd:appDir,
  encoding:'utf8',
  env:process.env,
});

log('npm install finished',`${Date.now()-started}ms`);
log('exit status',String(result.status));
log('signal',String(result.signal));
if(result.error) console.error('[runtime-intelligence] spawn error:',result.error);
if(result.stdout?.trim()){
  console.log('[runtime-intelligence] npm stdout:');
  console.log(result.stdout.trim());
}else{
  log('npm stdout','<empty>');
}
if(result.stderr?.trim()){
  console.error('[runtime-intelligence] npm stderr:');
  console.error(result.stderr.trim());
}else{
  log('npm stderr','<empty>');
}

const packageJsonPath=path.join(appDir,'node_modules','runtime-intelligence','package.json');
log('installed package.json exists',String(existsSync(packageJsonPath)));
if(existsSync(packageJsonPath)){
  try{
    const installed=JSON.parse(readFileSync(packageJsonPath,'utf8'));
    log('installed package',`${installed.name||'unknown'}@${installed.version||'unknown'}`);
    log('installed exports',JSON.stringify(installed.exports||{}));
  }catch(error){
    log('installed package.json read failed',error?.message||String(error));
  }
}

if(result.status!==0){
  log('installer failed','npm install did not complete successfully');
  process.exit(result.status??1);
}

const reactOk=resolveProbe('runtime-intelligence/react');
const panelOk=resolveProbe('runtime-intelligence/panel');
if(!reactOk||!panelOk){
  log('installer failed','package installed but one or more subpath imports do not resolve');
  process.exit(2);
}

log('installer completed successfully');
