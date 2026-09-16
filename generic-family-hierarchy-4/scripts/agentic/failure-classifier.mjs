import fs from 'node:fs';import {parseArgs} from './lib.mjs';
export function classifyFailure(text=''){
 const t=text.toLowerCase();
 const rules=[
  ['review-pending',/(pending_independent_review|independent review.*pending|missing independent reviewer)/],
  ['schema-drift',/(schema cache|relation .* does not exist|column .* does not exist|function .* does not exist|rpc .*404)/],
  ['stale-deployment',/(old build|stale deployment|chunkloaderror|deployment.*sha)/],
  ['environment-defect',/(econnrefused|enotfound|timeout|browser.*not installed|missing.*env|supabase.*url|service role|port .* in use|cannot find module ['"`](?:react|next|@|node:)|eslint:\s*not found|ts2580: cannot find name ['"]process['"]|npm.*network|network.*registry)/],
  ['test-data-defect',/(fixture|seed|test data|no matching row|expected .* record)/],
  ['architecture-violation',/(arch-00|forbidden import|architecture.*violation|scope gate)/],
  ['test-defect',/(locator.*strict mode|test.*syntax|playwright.*config|expect.*received.*undefined)/],
  ['product-defect',/(typeerror|referenceerror|statuscode.? 5\d\d|assertionerror|failed.*acceptance)/]
 ];for(const [name,rx] of rules)if(rx.test(t))return name;return 'unknown';
}
if(import.meta.url===`file://${process.argv[1]}`){const a=parseArgs();const text=a.file?fs.readFileSync(a.file,'utf8'):fs.readFileSync(0,'utf8');console.log(classifyFailure(text))}
