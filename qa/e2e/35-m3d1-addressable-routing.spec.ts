import {test,expect} from '@playwright/test';
import {login} from '../lib/login';
import {activate,authenticatedClient,seedState} from '../lib/role-client';

test.describe.serial('M3-D1 — addressable private networks',()=>{
 test('owner opens Family Community and Housing links directly, refreshes and uses history',async({page})=>{
  const networks=seedState().networks as Record<string,{id:string}>;
  const community=networks['family-association'].id,housing=networks['housing-society'].id;
  await activate('owner',community);
  await login(page,'owner');
  for(const [id,surface] of [[community,'community'],[housing,'complaints']] as const){
   const href=`/network/${id}/${surface}`;
   await page.goto(href,{waitUntil:'domcontentloaded'});
   await expect(page.locator('[data-testid^="qa-vertical-shell-"]').first()).toBeVisible({timeout:30_000});
   await expect(page).toHaveURL(new RegExp(`/network/${id}/${surface}$`));
   await page.reload({waitUntil:'domcontentloaded'});
   await expect(page.locator('[data-testid^="qa-vertical-shell-"]').first()).toBeVisible({timeout:30_000});
   await expect(page).toHaveURL(new RegExp(`/network/${id}/${surface}$`));
  }
  await page.goBack({waitUntil:'domcontentloaded'});
  await expect(page).toHaveURL(new RegExp(`/network/${community}/community$`));
  await page.goForward({waitUntil:'domcontentloaded'});
  await expect(page).toHaveURL(new RegExp(`/network/${housing}/complaints$`));
 });

 test('a private deep link survives sign in and unauthorized tenant entry reveals no network shell',async({page})=>{
  const state=seedState();
  const community=(state.networks as Record<string,{id:string}>)['family-association'].id;
  await activate('owner',community);
  await page.goto(`/network/${community}/community`,{waitUntil:'domcontentloaded'});
  await expect(page.getByText('Sign in to open your private network link.')).toBeVisible({timeout:30_000});
  await page.getByTestId('qa-open-auth').click();
  await page.getByTestId('qa-auth-email').fill(process.env.QA_OWNER_EMAIL||'');
  await page.getByTestId('qa-auth-password').fill(process.env.QA_OWNER_PASSWORD||'');
  await page.getByTestId('qa-auth-submit').click();
  await expect(page.locator('[data-testid^="qa-vertical-shell-"]').first()).toBeVisible({timeout:30_000});
  await expect(page).toHaveURL(new RegExp(`/network/${community}/community$`));

  await authenticatedClient('tenantB'); // loads generated QA credentials without modifying data
  await page.context().clearCookies();
  await page.evaluate(()=>localStorage.clear());
  await page.goto(`/network/${community}/community`,{waitUntil:'domcontentloaded'});
  await page.getByTestId('qa-open-auth').click();
  await page.getByTestId('qa-auth-email').fill(process.env.QA_TENANT_B_OWNER_EMAIL||'');
  await page.getByTestId('qa-auth-password').fill(process.env.QA_TENANT_B_OWNER_PASSWORD||'');
  await page.getByTestId('qa-auth-submit').click();
  await expect(page.getByRole('heading',{name:'Page unavailable'})).toBeVisible({timeout:30_000});
  await page.goto(`/network/${state.tenantB.id}/tree`,{waitUntil:'domcontentloaded'});
  await expect(page.getByTestId('qa-vertical-shell-family')).toBeVisible({timeout:30_000});
  await page.reload({waitUntil:'domcontentloaded'});
  await expect(page.getByTestId('qa-vertical-shell-family')).toBeVisible({timeout:30_000});
  await page.goto(`/network/${community}/community`,{waitUntil:'domcontentloaded'});
  await expect(page.getByRole('heading',{name:'Page unavailable'})).toBeVisible({timeout:30_000});
  await expect(page.locator('[data-testid^="qa-vertical-shell-"]')).toHaveCount(0);
 });
});
