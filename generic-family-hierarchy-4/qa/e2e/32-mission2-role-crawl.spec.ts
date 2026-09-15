import {test} from '@playwright/test';
import {login} from '../lib/login';import {activate,seedState} from '../lib/role-client';import {expertCrawl} from '../lib/crawler';import {mission2Watch} from '../lib/mission2-regression';import {expectedCrawlerTestIds,VERTICALS} from '../runtime/catalog.mjs';
const verticals=VERTICALS.map(v=>v.kind);const roles=['owner','admin','member'] as const;

test.describe.serial('Mission 2 — slow role regression crawl',()=>{
 for(const kind of verticals)for(const role of roles)test(`${kind}/${role} common user journeys stay free of unexpected API/database failures`,async({page},testInfo)=>{
  const s=seedState();await activate(role,s.networks[kind].id);await login(page,role);const watch=mission2Watch(page,testInfo);
  await expertCrawl(page,testInfo,{maxActions:Number(process.env.QA_M2_CRAWL_ACTIONS||22),role,scope:`mission2-${kind}`,expectedTestIds:expectedCrawlerTestIds(kind,role)});
  await watch.assertClean(`${kind}/${role} slow regression crawl`);
 });
});
