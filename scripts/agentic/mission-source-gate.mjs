import {parseArgs,resolveMissionPath,readJson,runShell,printChecks} from './lib.mjs';
const a=parseArgs();const missionPath=resolveMissionPath(a.mission);const m=readJson(missionPath);const checks=[];const commands=m.sourceValidation?.commands||[];
if(!commands.length){checks.push(['mission declares source validation commands',false,missionPath]);printChecks('Mission source gate',checks);process.exit(1)}
for(const entry of commands){const command=typeof entry==='string'?entry:entry.command;const name=typeof entry==='string'?entry:(entry.name||entry.command);const r=runShell(command);process.stdout.write(r.stdout);process.stderr.write(r.stderr);checks.push([name,r.status==='PASS',r.status==='PASS'?'PASS':`exit ${r.exitCode}`])}
printChecks(`Mission source gate (${m.id})`,checks);
