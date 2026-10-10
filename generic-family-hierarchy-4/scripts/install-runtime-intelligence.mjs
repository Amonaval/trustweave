import {spawnSync} from 'node:child_process';

const PIN='de8d01ead5c75054a613a483c3830917b9bc8ace';
const result=spawnSync(
  process.platform==='win32'?'npm.cmd':'npm',
  ['install','--no-save','--package-lock=false',`github:Amonaval/runtime-intelligence#${PIN}`],
  {stdio:'inherit'}
);
process.exit(result.status??1);
