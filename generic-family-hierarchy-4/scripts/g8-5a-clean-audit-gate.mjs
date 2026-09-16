import fs from 'node:fs';
import path from 'node:path';

const root=process.cwd();
const legacyAliases={
 'NEXT-SESSION-PROMPT.md':'archive/docs/m3b3-root-history/NEXT-SESSION-PROMPT.md',
 'PROJECT-VISION.md':'docs/product/PROJECT-VISION.md',
 'FOUNDER-COMPASS.md':'docs/product/FOUNDER-COMPASS.md',
 'USER-GUIDE.md':'docs/product/USER-GUIDE.md',
 'USER-EXPERIENCE-HANDBOOK.md':'docs/product/USER-EXPERIENCE-HANDBOOK.md',
 'TRUSTWEAVE-MISSION-JOURNEY.md':'docs/product/TRUSTWEAVE-MISSION-JOURNEY.md'
};
const resolve=p=>fs.existsSync(path.join(root,p))?p:legacyAliases[p]&&fs.existsSync(path.join(root,legacyAliases[p]))?legacyAliases[p]:p;
const exists=p=>fs.existsSync(path.join(root,resolve(p)));
const read=p=>fs.readFileSync(path.join(root,resolve(p)),'utf8');
const failures=[]; const fail=m=>failures.push(m);

const required=[
 'history/root-legacy/ARCHIVE-INDEX.md','history/root-legacy/GENERIC-CAPABILITY-UTILIZATION-RULE.md','archive/docs/g8.5/G8.5-A-CAPABILITY-APPLICABILITY-MATRIX.md','archive/docs/g8.5/G8.5-A-BASELINE-CLEANUP-AUDIT.md','archive/docs/g8.5/G8.5-A-RUNTIME-VERIFICATION-CHECKLIST.md','archive/docs/g8.5/G8.5-A-RELEASE-MANIFEST.md',
 'archive/docs/archive-map.json','archive/docs/g0-g6/G5-CERTIFICATION-HOTFIX-AFFECTED-FILES.txt','archive/docs/g0-g6/G5-CERTIFICATION-HOTFIX-VERTICAL-FEATURE-DISPATCH.md'
];
for(const f of required) if(!exists(f)) fail(`missing G8.5-A artifact: ${f}`);

const rootMd=fs.readdirSync(root).filter(f=>f.endsWith('.md'));
if(rootMd.length>40) fail(`root documentation still too noisy: ${rootMd.length} Markdown files (expected <=40 during M3-B3 compatibility window)`);
if(!exists('governance/documentation-policy.json')) fail('M3-B3 documentation policy missing');
for(const dir of ['archive/docs/family-foundation','archive/docs/g0-g6','archive/docs/g7','archive/docs/g8','archive/docs/g8.5']){
 if(!exists(dir)||fs.readdirSync(path.join(root,dir)).length===0) fail(`historical archive group missing/empty: ${dir}`);
}

const rule=read('history/root-legacy/GENERIC-CAPABILITY-UTILIZATION-RULE.md');
for(const marker of ['reuse it by default','Productized Vertical Gate','Showcase rule','explicit','Genericize once']) if(!rule.includes(marker)) fail(`capability utilization rule missing: ${marker}`);
const matrix=read('archive/docs/g8.5/G8.5-A-CAPABILITY-APPLICABILITY-MATRIX.md');
for(const marker of ['Maps / geography','Connection paths','Stories / memories / history','Contributions','Launch Control','Notifications / digest','Organization','Business Trust','Franchise','G8.5-B']) if(!matrix.includes(marker)) fail(`capability matrix missing: ${marker}`);

// Accepted baseline manifests must continue to resolve every file after archival.
for(const manifest of fs.readdirSync(path.join(root,'scripts')).filter(f=>f.includes('accepted')&&f.endsWith('baseline.txt'))){
 const missing=read(`scripts/${manifest}`).split(/\r?\n/).filter(Boolean).filter(f=>!exists(f));
 if(missing.length) fail(`${manifest} has missing accepted artifacts: ${missing.join(', ')}`);
}

const roadmap=read('ROADMAP.md'),status=read('MISSION-STATUS.md'),codebase=read('history/root-legacy/CODEBASE.md'),validation=read('history/root-legacy/VALIDATION.md'),handoff=read('NEXT-SESSION-PROMPT.md');
for(const [name,text] of [['ROADMAP',roadmap],['MISSION-STATUS',status],['CODEBASE',codebase],['VALIDATION',validation],['NEXT-SESSION-PROMPT',handoff]]){
 if(!text.includes('G8.5-A')) fail(`${name} not updated for G8.5-A`);
}
if(!roadmap.includes('G8.5-B')) fail('ROADMAP lost G8.5-B history');
if(!/(G8\.5-B|G8\.5-C|G9)/.test(handoff)) fail('NEXT-SESSION-PROMPT lost valid G8.5/G9 continuation');

if(failures.length){console.error(`G8.5-A clean/audit gate: FAIL — ${failures.join(' | ')}`);process.exit(1);}
console.log(`G8.5-A clean/audit gate: PASS — ${rootMd.length} root Markdown docs, historical archive preserved, accepted baselines resolve, reuse/product-depth rules locked.`);
