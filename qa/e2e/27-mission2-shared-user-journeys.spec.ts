import {test,expect} from '@playwright/test';
import {login} from '../lib/login';
import {activate,seedState} from '../lib/role-client';
import {mission2Watch,waitForPersistedOrMessage,TINY_PNG,userClick,userFill,userPause,openSurface} from '../lib/mission2-regression';

const stamp=()=>Date.now().toString(36);

test.describe.serial('Mission 2 — shared real-user journeys',()=>{
 test('Family Community: post + photo + comment persists without 4xx/5xx',async({page},testInfo)=>{
  const s=seedState();await activate('owner',s.networks['family-association'].id);await login(page,'owner');
  const watch=mission2Watch(page,testInfo),title=`M2 community photo post ${stamp()}`;
  await openSurface(page,'community');
  await userClick(page,page.getByTestId('qa-section-posts'));
  await userClick(page,page.getByTestId('qa-post-create'));
  await userFill(page,page.getByTestId('qa-post-title'),title);
  await userFill(page,page.getByTestId('qa-post-body'),'Mission 2 persisted post with a real Storage upload.');
  await page.getByTestId('qa-post-photo').setInputFiles(TINY_PNG);await userPause(page);
  await userClick(page,page.getByTestId('qa-post-publish'),1.5);
  const card=page.getByTestId('qa-post-card').filter({hasText:title});await waitForPersistedOrMessage(page,card,'Family Community photo post');
  await userClick(page,card.getByTestId('qa-post-comments'));
  await userFill(page,card.getByTestId('qa-post-comment-input'),'Mission 2 persisted comment');
  await userClick(page,card.getByTestId('qa-post-comment-submit'));
  await expect(card).toContainText('Mission 2 persisted comment');
  await page.reload({waitUntil:'domcontentloaded'});await userPause(page,1.2);await openSurface(page,'community');await userClick(page,page.getByTestId('qa-section-posts'));
  await expect(page.getByTestId('qa-post-card').filter({hasText:title})).toBeVisible({timeout:20_000});
  await watch.assertClean('Family Community post/photo/comment');
 });

 test('Family Community: fund transaction and voting work through normal UI',async({page},testInfo)=>{
  const s=seedState();await activate('owner',s.networks['family-association'].id);await login(page,'owner');const watch=mission2Watch(page,testInfo);
  const fundName=`M2 Pilot Fund ${stamp()}`;
  await openSurface(page,'funds');await userClick(page,page.getByTestId('qa-section-manage'));
  await userFill(page,page.getByTestId('qa-fund-name'),fundName);await userFill(page,page.getByTestId('qa-fund-target'),'5000');await userClick(page,page.getByTestId('qa-fund-create'),1.3);
  await userClick(page,page.getByTestId('qa-section-overview'));await expect(page.getByText(fundName,{exact:false})).toBeVisible({timeout:20_000});
  await userClick(page,page.getByTestId('qa-section-manage'));await page.getByTestId('qa-fund-tx-fund').selectOption({label:fundName});await userFill(page,page.getByTestId('qa-fund-tx-amount'),'250');await userClick(page,page.getByTestId('qa-fund-tx-record'),1.2);
  await userClick(page,page.getByTestId('qa-section-transactions'));await expect(page.locator('body')).toContainText('250');

  const ballot=`M2 Open Voting ${stamp()}`;await openSurface(page,'elections');await userClick(page,page.getByTestId('qa-section-manage'));
  await userFill(page,page.getByTestId('qa-vote-title'),ballot);await userClick(page,page.getByTestId('qa-vote-create'));
  const ballotSelect=page.getByTestId('qa-vote-option-ballot');await ballotSelect.selectOption({label:ballot});
  for(const label of ['Approve','Reject']){await userFill(page,page.getByTestId('qa-vote-option-label'),label);await userClick(page,page.getByTestId('qa-vote-option-add'))}
  await userClick(page,page.getByTestId('qa-section-ballots'));const card=page.getByTestId('qa-ballot-card').filter({hasText:ballot});await expect(card).toBeVisible();await userClick(page,card.getByTestId('qa-ballot-open'),1.2);await expect(card).toContainText('open');
  await userClick(page,card.getByTestId('qa-ballot-option').first());await userClick(page,card.getByTestId('qa-ballot-cast'),1.2);await expect(card).toContainText(/already recorded|recorded/i);
  await watch.assertClean('Family Community funds/voting');
 });
});
