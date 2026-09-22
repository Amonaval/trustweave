import {test} from '@playwright/test';
import fs from 'node:fs';import path from 'node:path';
import {login} from '../lib/login';import {activate,seedState} from '../lib/role-client';import {expertCrawl} from '../lib/crawler';import {mission2Watch} from '../lib/mission2-regression';import {expectedCrawlerTestIds,VERTICALS} from '../runtime/catalog.mjs';
import type {QaVerticalKind} from '../runtime/catalog.mjs';

const vertical=(process.env.QA_CRAWL_VERTICAL||'') as QaVerticalKind;
const role=process.env.QA_CRAWL_ROLE as 'owner'|'admin'|'member';
const resultFile=process.env.QA_CRAWL_RESULT_FILE||path.join('qa-results','resilient-crawl','unscoped-result.json');
if(!VERTICALS.some(item=>item.kind===vertical))throw new Error(`Unknown QA_CRAWL_VERTICAL ${JSON.stringify(vertical)}`);
if(!['owner','admin','member'].includes(role))throw new Error(`Unknown QA_CRAWL_ROLE ${JSON.stringify(role)}`);

test.describe('Resilient whole-app crawl shard',()=>{
 test.setTimeout(Number(process.env.QA_CRAWL_SHARD_TIMEOUT_MS||180_000));
 test(`${vertical}/${role}`,async({page},testInfo)=>{
  const startedAt=new Date().toISOString();let stage='fixture';let crawlResult:unknown=null;
  try{
   const state=seedState();const network=state.networks?.[vertical];if(!network?.id)throw new Error(`Seed fixture has no ${vertical} network`);
   stage='activation';await activate(role,network.id);
   stage='login';await login(page,role);
   stage='crawl';const watch=mission2Watch(page,testInfo);
   crawlResult=await expertCrawl(page,testInfo,{maxActions:Number(process.env.QA_CRAWL_ACTIONS||24),role,scope:`resilient-${vertical}`,expectedTestIds:expectedCrawlerTestIds(vertical,role),timeBudgetMs:Number(process.env.QA_CRAWL_BUDGET_MS||120_000),allowDestructive:false});
   stage='runtime';await watch.assertClean(`${vertical}/${role} resilient crawl`);
   fs.mkdirSync(path.dirname(resultFile),{recursive:true});fs.writeFileSync(resultFile,JSON.stringify({status:'PASS',vertical,role,startedAt,finishedAt:new Date().toISOString(),stage,crawl:crawlResult},null,2)+'\n');
  }catch(error){
   const message=error instanceof Error?error.message:String(error);fs.mkdirSync(path.dirname(resultFile),{recursive:true});fs.writeFileSync(resultFile,JSON.stringify({status:'FAIL',vertical,role,startedAt,finishedAt:new Date().toISOString(),stage,message,crawl:crawlResult},null,2)+'\n');throw error;
  }
 });
});
