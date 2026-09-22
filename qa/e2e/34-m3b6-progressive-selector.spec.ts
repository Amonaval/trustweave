import {test,expect} from '@playwright/test';
import type {Page,TestInfo} from '@playwright/test';
import {login} from '../lib/login';
import {activate,seedState} from '../lib/role-client';
import {mission2Watch,openSurface,userPause} from '../lib/mission2-regression';

type SelectorCase={surface:string;panelTestId:string;sections:readonly string[]};
const CASES:readonly SelectorCase[]=[
 {surface:'maintenance',panelTestId:'qa-hs-finance',sections:['billing','funds','arrears']},
 {surface:'governance',panelTestId:'qa-hs-governance',sections:['committee','actions','resolutions']},
 {surface:'security',panelTestId:'qa-hs-security',sections:['visitors','requests','assets']},
];

async function verifyResponsiveSelector(page:Page,testInfo:TestInfo,c:SelectorCase){
 await openSurface(page,c.surface);
 const panel=page.getByTestId(c.panelTestId);
 await expect(panel).toBeVisible({timeout:15_000});
 const selector=panel.getByTestId('qa-section-tabs');
 await expect(selector).toBeVisible();
 const mobile=testInfo.project.name==='chromium-mobile';
 const select=selector.getByTestId('qa-section-select');
 const buttons=selector.locator('.responsive-section-tab-buttons');
 if(mobile){
  await expect(select).toBeVisible();
  await expect(buttons).toBeHidden();
  for(const section of c.sections.slice(1)){
   await select.selectOption(section);await userPause(page,.25);await expect(select).toHaveValue(section);
  }
 }else{
  await expect(buttons).toBeVisible();
  await expect(select).toBeHidden();
  for(const section of c.sections){
   const tab=selector.getByTestId(`qa-section-${section}`);await expect(tab).toBeVisible();await tab.click();await userPause(page,.25);await expect(tab).toHaveAttribute('aria-selected','true');
  }
 }
}

test.describe.serial('M3-B6 — canonical progressive selector convergence',()=>{
 test('Housing Finance, Governance and Security use the same responsive selector on desktop/mobile',async({page},testInfo)=>{
  const seed=seedState();await activate('owner',seed.networks['housing-society'].id);await login(page,'owner');const watch=mission2Watch(page,testInfo);
  for(const c of CASES)await verifyResponsiveSelector(page,testInfo,c);
  await watch.assertClean('M3-B6 progressive selector convergence');
 });
});
