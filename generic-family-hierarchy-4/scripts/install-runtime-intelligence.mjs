import {spawnSync} from 'node:child_process';
import {existsSync, readFileSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const PIN='0908f7c8d90d81745db788913a17e6292d2147a0';
const TARGET=`github:Amonaval/runtime-intelligence#${PIN}`;
const npmArgs=['install','--no-save','--package-lock=false',TARGET];
const scriptDir=path.dirname(fileURLToPath(import.meta.url));
const appDir=path.resolve(scriptDir,'..');

function log(label,value=''){
  console.log(`[runtime-intelligence] ${label}${value===''?'':`: ${value}`}`);
}

function run(command,args,label){
  log(`${label} command`,`${command} ${args.join(' ')}`);
  const started=Date.now();
  const result=spawnSync(command,args,{
    cwd:appDir,
    encoding:'utf8',
    env:process.env,
    windowsHide:true,
  });
  log(`${label} finished`,`${Date.now()-started}ms`);
  log(`${label} exit status`,String(result.status));
  log(`${label} signal`,String(result.signal));
  if(result.error) console.error(`[runtime-intelligence] ${label} spawn error:`,result.error);
  if(result.stdout?.trim()){
    console.log(`[runtime-intelligence] ${label} stdout:`);
    console.log(result.stdout.trim());
  }else{
    log(`${label} stdout`,'<empty>');
  }
  if(result.stderr?.trim()){
    console.error(`[runtime-intelligence] ${label} stderr:`);
    console.error(result.stderr.trim());
  }else{
    log(`${label} stderr`,'<empty>');
  }
  return result;
}

function apiProbe(specifier,requiredExports){
  const script=`import(${JSON.stringify(specifier)}).then(mod=>{const required=${JSON.stringify(requiredExports)};const missing=required.filter(name=>typeof mod[name]!=='function');if(missing.length){console.error('MISSING_EXPORTS:'+missing.join(','));process.exit(2)}console.log('API_OK:'+required.join(','))}).catch(error=>{console.error(error?.stack||error);process.exit(1)})`;
  const probe=spawnSync(
    process.execPath,
    ['--input-type=module','-e',script],
    {cwd:appDir,encoding:'utf8',env:process.env,windowsHide:true}
  );
  log(`API ${specifier}`,probe.status===0?'OK':'FAILED');
  if(probe.stdout?.trim()) console.log(probe.stdout.trim());
  if(probe.stderr?.trim()) console.error(probe.stderr.trim());
  return probe.status===0;
}

function installRuntimeIntelligence(){
  const npmExecPath=process.env.npm_execpath;
  if(npmExecPath&&existsSync(npmExecPath)){
    log('npm execution strategy','node + npm_execpath');
    log('npm_execpath',npmExecPath);
    const result=run(process.execPath,[npmExecPath,...npmArgs],'npm install');
    if(!result.error&&result.status===0) return result;
    log('primary npm execution failed','falling back to shell invocation');
  }else{
    log('npm_execpath','<missing or unavailable>');
  }

  if(process.platform==='win32'){
    const comspec=process.env.ComSpec||process.env.COMSPEC||'cmd.exe';
    log('npm execution strategy','Windows cmd.exe fallback');
    log('ComSpec',comspec);
    return run(comspec,['/d','/s','/c','npm',...npmArgs],'npm install fallback');
  }

  log('npm execution strategy','direct npm fallback');
  return run('npm',npmArgs,'npm install fallback');
}

log('installer started');
log('script',fileURLToPath(import.meta.url));
log('cwd',process.cwd());
log('appDir',appDir);
log('node',process.version);
log('node executable',process.execPath);
log('platform',`${process.platform}/${process.arch}`);
log('pin',PIN);
log('target',TARGET);
log('package.json exists',String(existsSync(path.join(appDir,'package.json'))));

try{
  const pkg=JSON.parse(readFileSync(path.join(appDir,'package.json'),'utf8'));
  log('app package',`${pkg.name||'unknown'}@${pkg.version||'unknown'}`);
  log('declared runtime-intelligence dependency',String(Boolean(pkg.dependencies?.['runtime-intelligence']||pkg.devDependencies?.['runtime-intelligence'])));
}catch(error){
  log('package.json read failed',error?.message||String(error));
}

log('starting npm install');
const result=installRuntimeIntelligence();

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

if(result.status!==0||result.error){
  log('installer failed','npm install did not complete successfully');
  process.exit(result.status??1);
}

const reactOk=apiProbe('runtime-intelligence/react',[
  'RuntimeIntelligenceProvider',
  'RuntimeIntelligenceProfiler',
  'withRuntimeIntelligence',
]);
const panelOk=apiProbe('runtime-intelligence/panel',[
  'mountRuntimeIntelligencePanel',
  'createRuntimeReport',
  'downloadRuntimeReports',
]);
if(!reactOk||!panelOk){
  log('installer failed','Installed package does not expose the pinned R5.7.4 React/panel/report API. Stop Next, remove stale node_modules/runtime-intelligence and .next, then rerun this installer.');
  process.exit(2);
}

log('installer completed successfully');
