import {test,expect} from '@playwright/test';
import {login} from '../lib/login';
import {activate,seedState} from '../lib/role-client';
import {mission2Watch,openSurface,userPause} from '../lib/mission2-regression';
import {VERTICALS} from '../runtime/catalog.mjs';

const selector='a:visible,button:visible,input:visible,select:visible,textarea:visible,summary:visible,[role=tab]:visible,[role=menuitem]:visible,[role=button]:visible,[data-testid]:visible';

test.describe.serial('Mission 2 — every released vertical surface is reachable and inventoried',()=>{
 for(const vertical of VERTICALS)test(`${vertical.kind} owner traverses every instrumented navigation surface`,async({page},testInfo)=>{
  const s=seedState();await activate('owner',s.networks[vertical.kind].id);await login(page,'owner');const watch=mission2Watch(page,testInfo);
  await expect(page.getByTestId(`qa-vertical-shell-${vertical.kind}`)).toBeVisible({timeout:20_000});
  await page.locator('details:visible').evaluateAll((els:any[])=>els.forEach((el:any)=>{el.open=true})).catch(()=>{});
  const navIds=await page.locator('[data-testid^="qa-nav-"]').evaluateAll((els:any[])=>[...new Set(els.map(el=>el.getAttribute('data-testid')).filter(Boolean))]);
  expect(navIds.length,`${vertical.kind} should expose instrumented navigation`).toBeGreaterThan(0);
  const coverage:any[]=[];
  for(const testId of navIds as string[]){
   const id=testId.replace(/^qa-nav-/,'');await openSurface(page,id);await userPause(page,.65);
   const controls=await page.locator(selector).evaluateAll((els:any[])=>els.slice(0,600).map((el:any)=>({tag:el.tagName.toLowerCase(),testId:el.getAttribute('data-testid'),role:el.getAttribute('role'),name:(el.getAttribute('aria-label')||el.getAttribute('title')||el.innerText||el.getAttribute('name')||'').trim().slice(0,180),type:el.getAttribute('type')})));
   coverage.push({surface:id,url:page.url(),controls});
   await expect(page.locator('body')).not.toContainText(/Unhandled Runtime Error|Application error|TypeError:|ReferenceError:|SQLSTATE/i);
  }
  await testInfo.attach(`${vertical.kind}-interactive-inventory`,{body:Buffer.from(JSON.stringify({vertical:vertical.kind,navIds,coverage},null,2)),contentType:'application/json'});
  await watch.assertClean(`${vertical.kind} complete surface inventory`);
 });
});
