import {spawn} from 'node:child_process';
import fs from 'node:fs';
import {loadQaEnv,isStaging} from './runtime/env.mjs';

loadQaEnv();
if(!isStaging()){
 console.error('Mission 2 two-vertical resume requires QA_MODE=staging.');
 process.exit(1);
}
if(!fs.existsSync('qa-results/fixtures/seed-state.json')){
 console.error('Missing qa-results/fixtures/seed-state.json. This resume command intentionally does not rebuild/reseed.');
 process.exit(1);
}
const headed=process.argv.includes('--headed');
const args=['playwright','test',
 'qa/e2e/60-accessibility-responsive.spec.ts',
 'qa/e2e/81-resilience-runtime.spec.ts',
 '--project=chromium-desktop','--workers=1',
 ...(headed?['--headed']:[])
];
const env={...process.env,
 QA_M2_SCOPE:'housing-society,family-association',
 QA_M2_RESUME:'true',
 QA_M2_SERVER_WARMUP_MS:process.env.QA_M2_SERVER_WARMUP_MS||'10000'
};
const code=await new Promise(resolve=>{
 const c=spawn('npx',args,{stdio:'inherit',env,shell:process.platform==='win32'});
 c.on('close',x=>resolve(x??1));c.on('error',()=>resolve(127));
});
if(code!==0)process.exit(code);

// Mobile Family Community-only continuation. Grep avoids the Family desktop crawl in this mixed spec.
const mobileArgs=['playwright','test','qa/e2e/30-mission2-family-and-mobile.spec.ts','--project=chromium-mobile','--workers=1','--grep','mobile Family Community',...(headed?['--headed']:[])];
const mobileCode=await new Promise(resolve=>{
 const c=spawn('npx',mobileArgs,{stdio:'inherit',env,shell:process.platform==='win32'});
 c.on('close',x=>resolve(x??1));c.on('error',()=>resolve(127));
});
process.exit(mobileCode);
