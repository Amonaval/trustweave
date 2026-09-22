import {test,expect} from '@playwright/test';
import {attachRuntimeWatch} from '../lib/runtime-watch';

test('Final launch: anonymous Discovery explains Housing, Family Community and the public-safe Product Guide',async({page},testInfo)=>{
 const watch=attachRuntimeWatch(page,testInfo);await page.goto('/');
 await expect(page.getByTestId('qa-public-discovery')).toBeVisible({timeout:15_000});
 await expect(page.getByTestId('qa-open-auth')).toBeVisible();
 await page.getByTestId('qa-explore-housing').click();await expect(page.getByTestId('qa-public-housing')).toBeVisible();
 await page.getByText('← TrustWeave').click();await page.getByTestId('qa-explore-community').click();await expect(page.getByTestId('qa-public-community')).toBeVisible();
 await page.getByText('← TrustWeave').click();await page.getByTestId('qa-product-guide').click();await expect(page.getByTestId('qa-public-product-guide')).toBeVisible();
 await expect(page.getByText(/founder-private strategy, confidential architecture/i)).toBeVisible();
 watch.flush();
});

test('Final launch: mobile Discovery keeps primary routes and sign-in reachable',async({page},testInfo)=>{
 const watch=attachRuntimeWatch(page,testInfo);await page.setViewportSize({width:390,height:844});await page.goto('/');
 await expect(page.getByTestId('qa-explore-housing')).toBeVisible();await expect(page.getByTestId('qa-explore-community')).toBeVisible();await expect(page.getByTestId('qa-public-playground')).toBeVisible();await expect(page.getByTestId('qa-product-guide')).toBeVisible();await expect(page.getByTestId('qa-open-auth')).toBeVisible();watch.flush();
});
