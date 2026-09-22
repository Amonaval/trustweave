import fs from 'node:fs';import path from 'node:path';import {execFileSync} from 'node:child_process';import {parseArgs,readJson,ROOT,resolveMissionPath} from './lib.mjs';
const a=parseArgs();const missionPath=resolveMissionPath(a.mission);const m=readJson(missionPath);const branch=m.execution?.branch||`agent/${m.id.toLowerCase()}`;const rel=m.execution?.worktree||`.agent-worktrees/${m.id.toLowerCase()}`;const target=path.resolve(ROOT,rel);const base=m.execution?.baseRef||'main';
try{execFileSync('git',['rev-parse','--is-inside-work-tree'],{cwd:ROOT,stdio:'ignore'})}catch{console.error('Git metadata is required to create a durable mission worktree.');process.exit(2)}
if(fs.existsSync(target)){console.log(`Worktree already exists: ${target}`);process.exit(0)}
fs.mkdirSync(path.dirname(target),{recursive:true});execFileSync('git',['worktree','add','-b',branch,target,base],{cwd:ROOT,stdio:'inherit'});console.log(JSON.stringify({mission:m.id,branch,worktree:target,base},null,2));
