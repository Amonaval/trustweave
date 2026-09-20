import {spawnSync} from "node:child_process";
import {assertRootFirstLoadBudget} from "./d7-bundle-budget.mjs";

const nextBin="node_modules/next/dist/bin/next";
const result=spawnSync(process.execPath,[nextBin,"build"],{encoding:"utf8",env:process.env,maxBuffer:64*1024*1024});
if(result.stdout)process.stdout.write(result.stdout);
if(result.stderr)process.stderr.write(result.stderr);
if(result.error)throw result.error;
if(result.status!==0)process.exit(result.status??1);
assertRootFirstLoadBudget(result.stdout);
