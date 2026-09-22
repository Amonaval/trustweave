#!/usr/bin/env node
import fs from 'node:fs';
import {MissionGovernor} from './mission-governor.mjs';
const args=process.argv.slice(2),command=args.shift()||'status';const value=name=>{const i=args.indexOf(`--${name}`);return i>=0?args[i+1]:null};const has=name=>args.includes(`--${name}`);const root=value('state-root')||'company-state';const governor=new MissionGovernor({stateRoot:root});
const output=value=>console.log(JSON.stringify(value,null,2));
try{
 if(command==='create')output(governor.create({id:value('id'),title:value('title'),intent:value('intent'),risk:value('risk')||'R1',decisionClass:value('decision-class')||'D1'}));
 else if(command==='plan'){const file=value('file');if(!file)throw new Error('plan requires --file');output(governor.plan(value('id'),JSON.parse(fs.readFileSync(file,'utf8'))))}
 else if(command==='run'||command==='resume')output(await governor[command](value('id'),{interruptAfter:value('interrupt-after')===null?null:Number(value('interrupt-after'))}));
 else if(command==='next')output(governor.next(value('id')));
 else if(command==='close'){const review=JSON.parse(fs.readFileSync(value('review'),'utf8'));output(governor.close(value('id'),{candidate:value('candidate'),evidence:value('evidence'),review}))}
 else if(command==='verify')output(governor.store.verify());
 else if(command==='status')output(value('id')?governor.require(value('id')):governor.store.read());
 else throw new Error('Usage: company-cli <create|plan|run|resume|next|close|verify|status>');
}catch(error){console.error(error instanceof Error?error.message:String(error));process.exitCode=has('allow-failure')?0:1}
