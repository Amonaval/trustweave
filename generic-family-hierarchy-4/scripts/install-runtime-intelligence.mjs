import {spawnSync} from 'node:child_process';

const PIN='bf3548c41b23058e99adde58179f9bbf0bef6146';
const result=spawnSync(
  process.platform==='win32'?'npm.cmd':'npm',
  ['install','--no-save','--package-lock=false',`github:Amonaval/runtime-intelligence#${PIN}`],
  {stdio:'inherit'}
);
process.exit(result.status??1);
