import test from 'node:test';import assert from 'node:assert/strict';import fs from 'node:fs';
const runner=fs.readFileSync('qa/run-resilient-crawl.mjs','utf8'),crawler=fs.readFileSync('qa/lib/crawler.ts','utf8'),config=fs.readFileSync('playwright.config.ts','utf8');

test('resilient crawl shards all catalog verticals across owner admin and member',()=>{
 assert.match(runner,/scope==='all'\?VERTICALS\.map/);assert.match(runner,/roles=\['owner','admin','member'\]/);assert.match(runner,/for\(const vertical of selected\)for\(const role of roles\)/);
});

test('resilient crawl checkpoints each shard and retries only from a clean process',()=>{
 assert.match(runner,/attempt<=2/);assert.match(runner,/spawn\('npx'/);assert.match(runner,/persist\(\);console\.log/);assert.match(runner,/checkpoint\.shards\[key\]\?\.status==='PASS'/);
});

test('exploratory crawler blocks destructive controls unless explicitly enabled',()=>{
 assert.match(crawler,/allowDestructive=false/);assert.match(crawler,/!allowDestructive\|\|!mutationAllowed\(\)/);assert.match(crawler,/external\.test\(href\|\|''\)/);
});

test('each crawl attempt receives isolated browser and runtime evidence paths',()=>{
 assert.match(runner,/QA_PLAYWRIGHT_RESULTS_DIR/);assert.match(runner,/QA_CRAWL_EVIDENCE_DIR/);assert.match(runner,/QA_MISSION2_EVIDENCE_DIR/);assert.match(config,/QA_PLAYWRIGHT_RESULTS_DIR/);
});
