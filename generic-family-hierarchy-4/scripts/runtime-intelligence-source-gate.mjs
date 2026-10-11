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
const pinpointGuide=read('tools/trustweave_tool/RUNTIME_INTELLIGENCE_P0_1_PINPOINT_VALIDATION.md');

const P0_4_PIN='db9a3ee4e805118076e27c37d1a82e84888ad50f';
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
if(!installer.includes(P0_4_PIN))failures.push('Installer not pinned to P0.4 exact React source-attribution runtime');
if(!installer.includes('source-provenance.js'))failures.push('Installer does not verify universal source provenance implementation');
if(!installer.includes('pinpoint-source-enrichment.js'))failures.push('Installer does not verify Pinpoint source enrichment implementation');
if(!installer.includes('react-source-provenance.js'))failures.push('Installer does not verify P0.4 React provenance implementation');
if(!installer.includes('captureReactRegistrationSource'))failures.push('Installer does not verify React boundary registration attribution');
if(!installer.includes('captureReactInvocationSource'))failures.push('Installer does not verify React invocation attribution');
if(!installer.includes('COMPONENT_REGISTRATION'))failures.push('Installer does not verify component-registration provenance');
if(!installer.includes("'withRuntimeIntelligence'"))failures.push('Installer does not verify the React HOC export');
if(!installer.includes("'mountRuntimeIntelligencePanel'"))failures.push('Installer does not verify the canonical panel mount export');
if(!installer.includes("'createRuntimeReport'"))failures.push('Installer does not verify normalized report export');
if(!installer.includes("'downloadRuntimeReports'"))failures.push('Installer does not verify paired JSON/HTML report export');
if(!pinpointGuide.includes(P0_4_PIN))failures.push('TrustWeave pinpoint validation guide does not match the P0.4 runtime pin');
if(!pinpointGuide.includes('Do not add synthetic faults to TrustWeave'))failures.push('TrustWeave pinpoint validation must remain real-world only');
if(!pinpointGuide.includes('Component boundary'))failures.push('TrustWeave validation guide does not cover component-boundary provenance semantics');

if(failures.length){
  console.error('Runtime Intelligence source gate failed:\n- '+failures.join('\n- '));
  process.exit(1);
}
console.log('Runtime Intelligence source gate passed. TrustWeave consumes the pinned P0.4 exact React source-attribution runtime with canonical panel + Opportunities and a real-world pinpoint validation contract.');
