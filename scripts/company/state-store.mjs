import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

export const now=()=>new Date().toISOString();
export const hash=value=>crypto.createHash('sha256').update(typeof value==='string'?value:JSON.stringify(value)).digest('hex');

export class DurableStateStore{
  constructor(root='company-state'){
    this.root=path.resolve(root);this.stateFile=path.join(this.root,'company.json');this.journalFile=path.join(this.root,'journal.ndjson');
    fs.mkdirSync(this.root,{recursive:true});
  }
  initial(){return {version:1,revision:0,updatedAt:now(),activeMissionId:null,missions:{},portfolio:[],interventions:[],metrics:{founderInterventions:0,manualErrorRelays:0}}}
  read(){
    if(!fs.existsSync(this.stateFile))return this.initial();
    const raw=fs.readFileSync(this.stateFile,'utf8');const state=JSON.parse(raw);
    if(!state||state.version!==1||typeof state.revision!=='number'||!state.missions)throw new Error('Company state is invalid or unsupported.');
    return state;
  }
  write(state,event='STATE_UPDATED',detail={}){
    const next={...state,revision:(state.revision||0)+1,updatedAt:now()};const body=JSON.stringify(next,null,2)+'\n';
    const temp=`${this.stateFile}.${process.pid}.${crypto.randomUUID()}.tmp`;const fd=fs.openSync(temp,'wx');
    try{fs.writeFileSync(fd,body);fs.fsyncSync(fd)}finally{fs.closeSync(fd)}
    if(fs.existsSync(this.stateFile))fs.copyFileSync(this.stateFile,`${this.stateFile}.previous`);
    fs.renameSync(temp,this.stateFile);
    const journal={sequence:next.revision,at:next.updatedAt,event,detail,stateHash:hash(body)};const jfd=fs.openSync(this.journalFile,'a');
    try{fs.writeFileSync(jfd,JSON.stringify(journal)+'\n');fs.fsyncSync(jfd)}finally{fs.closeSync(jfd)}
    return next;
  }
  transaction(event,detail,mutator){const current=this.read();const draft=structuredClone(current);const result=mutator(draft);return {state:this.write(draft,event,detail),result}}
  journal(){if(!fs.existsSync(this.journalFile))return [];return fs.readFileSync(this.journalFile,'utf8').split(/\r?\n/).filter(Boolean).map(line=>JSON.parse(line))}
  verify(){const state=this.read(),journal=this.journal();const sequences=journal.map(x=>x.sequence);const monotonic=sequences.every((x,i)=>i===0||x>sequences[i-1]);return {valid:monotonic&&(!journal.length||journal.at(-1).sequence===state.revision),revision:state.revision,events:journal.length}}
}
