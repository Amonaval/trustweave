import fs from 'node:fs';
import path from 'node:path';
import {ROOT,readJson,exists,walk,printChecks} from './lib.mjs';
const p=readJson('governance/documentation-policy.json');const checks=[];const ok=(n,v,d='')=>checks.push([n,!!v,d]);
for(const f of [...p.canonicalRoot,...p.rootIndexes])ok(`canonical/index exists: ${f}`,exists(f));
const rootMd=fs.readdirSync(ROOT).filter(f=>f.endsWith('.md'));
for(const rxText of p.forbiddenRootPatterns){const rx=new RegExp(rxText);const bad=rootMd.filter(f=>rx.test(f));ok(`no forbidden root pattern ${rxText}`,bad.length===0,bad.join(', '))}
for(const base of p.singleCopyBasenames){const matches=walk('.',{extensions:['.md'],ignore:['archive','node_modules','.next']}).filter(f=>path.posix.basename(f)===base);ok(`single canonical copy: ${base}`,matches.length===1,matches.join(', '))}
ok('active mission record exists',exists(p.activeMission),p.activeMission);
if(exists(p.activeMission)){try{const m=readJson(p.activeMission);ok('active mission id/state present',Boolean(m.id&&m.state),`${m.id||'?'} ${m.state||'?'}`)}catch(e){ok('active mission JSON parses',false,String(e))}}
const dupGov=walk('.',{extensions:['.md'],ignore:['archive','node_modules','.next']}).filter(f=>path.posix.basename(f)==='DOCUMENTATION-GOVERNANCE.md');ok('documentation governance has one canonical live copy',dupGov.length===1,dupGov.join(', '));
console.log(`INFO root markdown count=${rootMd.length}; legacy compatibility docs=${p.legacyRootCompatibility.filter(exists).length}`);
printChecks('Documentation drift gate',checks);
