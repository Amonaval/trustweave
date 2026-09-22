import {test,expect} from '@playwright/test';import {login} from '../lib/login';import {activate,seedState} from '../lib/role-client';import {mission2Watch,userClick,userFill,openSurface} from '../lib/mission2-regression';
const stamp=()=>Date.now().toString(36);
test('Mission 2 — Family Community annual membership controls persist',async({page},testInfo)=>{
 const s=seedState();await activate('owner',s.networks['family-association'].id);await login(page,'owner');const watch=mission2Watch(page,testInfo);
 await openSurface(page,'admin');await userClick(page,page.getByTestId('qa-section-vertical'));await expect(page.getByTestId('qa-fca-admin-panel')).toBeVisible();
 await userClick(page,page.getByTestId('qa-section-year'));const label=`M2-${stamp()}`;await userFill(page,page.getByTestId('qa-fca-year-label'),label);await userFill(page,page.getByTestId('qa-fca-year-fee'),'1100');await userClick(page,page.getByTestId('qa-fca-year-save'),1.2);await expect(page.getByText(label,{exact:false})).toBeVisible();
 await userClick(page,page.getByTestId('qa-section-membership'));await page.getByTestId('qa-fca-membership-year').selectOption({label});await page.getByTestId('qa-fca-membership-family').selectOption({index:1});await userClick(page,page.getByTestId('qa-fca-membership-save'),1.2);
 await expect(page.locator('body')).not.toContainText(/Could not save|schema cache|does not exist|column .* does not exist/i);await watch.assertClean('Family Community annual membership');
});
