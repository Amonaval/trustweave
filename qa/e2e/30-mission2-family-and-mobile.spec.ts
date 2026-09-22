import {test,expect} from '@playwright/test';import {login} from '../lib/login';import {activate,seedState} from '../lib/role-client';import {expertCrawl} from '../lib/crawler';import {mission2Watch,userClick,userPause,openSurface} from '../lib/mission2-regression';

test('Mission 2 — Family owner slow regression crawl catches API/runtime failures',async({page},testInfo)=>{
 test.skip(testInfo.project.name==='chromium-mobile','desktop crawl is covered by chromium-desktop');
 const s=seedState();await activate('owner',s.networks.family.id);await login(page,'owner');const watch=mission2Watch(page,testInfo);await expertCrawl(page,testInfo,{maxActions:Number(process.env.QA_M2_FAMILY_ACTIONS||45),role:'owner',scope:'mission2-family',expectedTestIds:['qa-nav-admin']});await watch.assertClean('Family owner slow crawl');
});

test('Mission 2 — mobile Family Community navigation uses progressive selectors without horizontal workflow',async({page},testInfo)=>{
 test.skip(testInfo.project.name!=='chromium-mobile','mobile certification project only');const s=seedState();await activate('owner',s.networks['family-association'].id);await login(page,'owner');const watch=mission2Watch(page,testInfo);await openSurface(page,'community');await expect(page.getByTestId('qa-section-select').first()).toBeVisible();await page.getByTestId('qa-section-select').first().selectOption('posts');await userPause(page);await expect(page.getByTestId('qa-network-posts-panel')).toBeVisible();await watch.assertClean('Family Community mobile progressive navigation');
});
