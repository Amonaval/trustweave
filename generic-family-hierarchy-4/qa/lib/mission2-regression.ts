import {expect} from '@playwright/test';
import type {Page,TestInfo,Locator} from '@playwright/test';
import fs from 'node:fs';import path from 'node:path';

export type Mission2Issue={kind:'console'|'pageerror'|'requestfailed'|'http';message:string;url?:string;status?:number;body?:string;at:string};
const apiLike=/\/rest\/v1\/|\/storage\/v1\/|\/functions\/v1\/|\/api\/v1\//i;
const ignoredNoise=[/favicon/i,/ResizeObserver loop/i,/Failed to load resource: net::ERR_ABORTED/i];

export const USER_PACE_MS=Math.max(150,Number(process.env.QA_USER_PACE_MS||700));
export async function userPause(page:Page,factor=1){await page.waitForTimeout(Math.max(80,Math.round(USER_PACE_MS*factor)))}
export async function userClick(page:Page,locator:Locator,factor=1){await locator.click();await userPause(page,factor)}
export async function userFill(page:Page,locator:Locator,value:string,factor=.5){await locator.fill(value);await userPause(page,factor)}

export function mission2Watch(page:Page,testInfo:TestInfo){
 const issues:Mission2Issue[]=[];const allowed:{pattern:RegExp;statuses:Set<number>;remaining:number}[]=[];
 const push=(issue:Omit<Mission2Issue,'at'>)=>{if(ignoredNoise.some(r=>r.test(issue.message)))return;issues.push({...issue,at:new Date().toISOString()})};
 const allow=(pattern:RegExp,statuses:number[]=[400,401,403,404,409,422],count=1)=>allowed.push({pattern,statuses:new Set(statuses),remaining:count});
 const consumed=(url:string,status:number)=>{const hit=allowed.find(x=>x.remaining>0&&x.statuses.has(status)&&x.pattern.test(url));if(!hit)return false;hit.remaining--;return true};
 page.on('console',m=>{if(m.type()==='error')push({kind:'console',message:m.text()})});
 page.on('pageerror',e=>push({kind:'pageerror',message:e.message}));
 page.on('requestfailed',r=>{if(apiLike.test(r.url()))push({kind:'requestfailed',message:r.failure()?.errorText||'request failed',url:r.url()})});
 page.on('response',async r=>{const status=r.status(),url=r.url();if(status<400||!apiLike.test(url)||consumed(url,status))return;let body='';try{body=(await r.text()).slice(0,2500)}catch{}push({kind:'http',message:`HTTP ${status} ${r.request().method()}`,status,url,body})});
 return {
  issues,allow,
  async assertClean(label='Mission 2 user journey'){
   await userPause(page,.25);
   if(issues.length){
    const dir='qa-results/mission2';fs.mkdirSync(dir,{recursive:true});
    fs.appendFileSync(path.join(dir,'runtime-issues.ndjson'),issues.map(issue=>JSON.stringify({...issue,test:testInfo.titlePath.join(' > '),label})).join('\n')+'\n');
    await testInfo.attach('mission2-runtime-issues',{body:Buffer.from(JSON.stringify({label,issues},null,2)),contentType:'application/json'});
   }
   expect(issues,`${label} produced unexpected browser/API/database failures`).toEqual([]);
  }
 };
}


export async function openSurface(page:Page,id:string){
 const visible=async(testId:string)=>page.locator(`[data-testid="${testId}"]:visible`).first();
 let target=await visible(`qa-nav-${id}`);
 if(await target.count()){await userClick(page,target);return}
 target=await visible(`qa-mobile-nav-${id}`);
 if(await target.count()){await userClick(page,target);return}
 const desktopMore=page.locator('.product-nav-more:visible summary, .family-nav-more:visible summary').first();
 if(await desktopMore.count()){
  await desktopMore.click();await userPause(page,.4);
  target=await visible(`qa-nav-${id}`);
  if(await target.count()){await userClick(page,target);return}
 }
 const mobileMore=await visible('qa-mobile-nav-more');
 if(await mobileMore.count()){
  await userClick(page,mobileMore,.35);
  target=await visible(`qa-mobile-more-${id}`);
  await expect(target,`mobile surface ${id} should be reachable`).toBeVisible({timeout:10_000});
  await userClick(page,target);return;
 }
 await expect(page.locator(`[data-testid="qa-nav-${id}"]:visible`).first(),`surface ${id} should be reachable`).toBeVisible({timeout:10_000});
}

export async function expectAdminWorkspace(page:Page){
 const workspace=page.locator('[data-qa-workspace="admin"]:visible').first();
 await expect(workspace,'active vertical should expose its admin workspace').toBeVisible({timeout:15_000});
 return workspace;
}

export async function expectPersistedText(page:Page,text:string){
 await expect(page.getByText(text,{exact:false}).first()).toBeVisible({timeout:20_000});
 await page.reload({waitUntil:'domcontentloaded'});await userPause(page,1.2);
 await expect(page.getByText(text,{exact:false}).first()).toBeVisible({timeout:20_000});
}

export const TINY_PNG={name:'mission2-photo.png',mimeType:'image/png',buffer:Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9ZQWQAAAAASUVORK5CYII=','base64')};
