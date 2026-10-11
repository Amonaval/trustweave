import fs from 'node:fs';
import path from 'node:path';

const root=process.cwd();
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const runtime=read('tools/trustweave_tool/TrustWeaveRuntime.tsx');
const layout=read('app/layout.tsx');
const page=read('app/page.tsx');
const analytics=read('components/AnalyticsPanel.tsx');
const timeline=read('components/TimelineView.tsx');
const upcoming=read('components/UpcomingWidget.tsx');
const installer=read('scripts/install-runtime-intelligence.mjs');

const R5_7_4_PIN='0908f7c8d90d81745db788913a17e6292d2147a0';
const failures=[];
if(!runtime.includes("from 'runtime-intelligence/react'"))failures.push('Runtime React entry missing');
if(!runtime.includes("from 'runtime-intelligence/panel'"))failures.push('Canonical mature panel entry missing');
if(!runtime.includes('mountRuntimeIntelligencePanel'))failures.push('Canonical panel mount missing');
if(!runtime.includes('profileRoot={false}'))failures.push('Root profiler de-duplication mode missing');
if(runtime.includes('react-runtime-toolkit')||page.includes('react-runtime-toolkit'))failures.push('Legacy copied toolkit still active');
if(layout.includes('TrustWeaveRuntimePreload'))failures.push('Legacy preload active');
if(!page.includes('source="components/NetworkApp.tsx"'))failures.push('NetworkApp boundary/source missing');
for(const [name,text] of [['AnalyticsPanel',analytics],['TimelineView',timeline],['UpcomingWidget',upcoming]]){
  if(!text.includes('withRuntimeIntelligence'))failures.push(`${name} strategic boundary missing`);
}
if(!installer.includes(R5_7_4_PIN))failures.push('Installer not pinned to validated R5.7.4 runtime');
if(!installer.includes("'withRuntimeIntelligence'"))failures.push('Installer does not verify the React HOC export');
if(!installer.includes("'mountRuntimeIntelligencePanel'"))failures.push('Installer does not verify the canonical panel mount export');
if(!installer.includes("'createRuntimeReport'"))failures.push('Installer does not verify normalized report export');
if(!installer.includes("'downloadRuntimeReports'"))failures.push('Installer does not verify paired JSON/HTML report export');

if(failures.length){
  console.error('Runtime Intelligence source gate failed:\n- '+failures.join('\n- '));
  process.exit(1);
}
console.log('Runtime Intelligence source gate passed. TrustWeave consumes validated R5.7.4 canonical panel + Opportunities + shared intelligence with strategic React boundaries and strict installed-API verification.');
