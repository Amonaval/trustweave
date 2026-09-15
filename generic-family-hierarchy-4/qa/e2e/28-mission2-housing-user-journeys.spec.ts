import {test,expect} from '@playwright/test';
import {login} from '../lib/login';import {activate,seedState} from '../lib/role-client';
import {mission2Watch,TINY_PNG,userClick,userFill,userPause,openSurface} from '../lib/mission2-regression';
const stamp=()=>Date.now().toString(36);

test.describe.serial('Mission 2 — Housing Society real-user journeys',()=>{
 test('notice, complaint+photo, finance, governance and visitor flows persist',async({page},testInfo)=>{
  const s=seedState();await activate('owner',s.networks['housing-society'].id);await login(page,'owner');const watch=mission2Watch(page,testInfo);
  const notice=`M2 Notice ${stamp()}`;await openSurface(page,'notices');await userFill(page,page.getByTestId('qa-hs-notice-title'),notice);await userFill(page,page.getByTestId('qa-hs-notice-body'),'Mission 2 normal notice creation');await userClick(page,page.getByTestId('qa-hs-notice-publish'),1.2);await expect(page.getByText(notice,{exact:false})).toBeVisible();
  const complaint=`M2 Complaint ${stamp()}`;await openSurface(page,'complaints');await userFill(page,page.getByTestId('qa-hs-complaint-title'),complaint);await userFill(page,page.getByTestId('qa-hs-complaint-body'),'Photo complaint should persist without storage/RPC errors');await page.getByTestId('qa-hs-complaint-photo').setInputFiles(TINY_PNG);await userClick(page,page.getByTestId('qa-hs-complaint-submit'),1.5);await expect(page.getByTestId('qa-hs-complaint-card').filter({hasText:complaint})).toBeVisible({timeout:25_000});
  await openSurface(page,'maintenance');await userFill(page,page.getByTestId('qa-hs-charge-code'),`M2${stamp().slice(-4)}`);await userFill(page,page.getByTestId('qa-hs-charge-label'),`Mission 2 Charge ${stamp()}`);await userFill(page,page.getByTestId('qa-hs-charge-amount'),'100');await userClick(page,page.getByTestId('qa-hs-charge-save'),1.2);
  await openSurface(page,'governance');const meeting=`M2 Committee ${stamp()}`;await userFill(page,page.getByTestId('qa-hs-meeting-title'),meeting);await userClick(page,page.getByTestId('qa-hs-meeting-create'),1.2);await expect(page.getByText(meeting,{exact:false})).toBeVisible({timeout:20_000});
  await openSurface(page,'security');await page.getByTestId('qa-hs-visitor-unit').selectOption({index:1});const visitor=`M2 Visitor ${stamp()}`;await userFill(page,page.getByTestId('qa-hs-visitor-name'),visitor);await userClick(page,page.getByTestId('qa-hs-visitor-create'),1.2);await expect(page.getByText(visitor,{exact:false})).toBeVisible();
  await page.reload({waitUntil:'domcontentloaded'});await userPause(page,1.2);await openSurface(page,'complaints');await expect(page.getByTestId('qa-hs-complaint-card').filter({hasText:complaint})).toBeVisible({timeout:20_000});
  await watch.assertClean('Housing notice/complaint/finance/governance/security');
 });

 test('member can create complaint but cannot access society admin workspace',async({page},testInfo)=>{
  const s=seedState();await activate('member',s.networks['housing-society'].id);await login(page,'member');const watch=mission2Watch(page,testInfo);
  await expect(page.getByTestId('qa-nav-admin')).toHaveCount(0);await openSurface(page,'complaints');const title=`M2 Member Complaint ${stamp()}`;await userFill(page,page.getByTestId('qa-hs-complaint-title'),title);await userFill(page,page.getByTestId('qa-hs-complaint-body'),'Resident generated complaint');await userClick(page,page.getByTestId('qa-hs-complaint-submit'),1.2);await expect(page.getByTestId('qa-hs-complaint-card').filter({hasText:title})).toBeVisible();await watch.assertClean('Housing member complaint and permissions');
 });
});
