import fs from 'node:fs';
const read=p=>fs.readFileSync(new URL(`../${p}`,import.meta.url),'utf8');
const responsive=read('components/shared/ResponsiveSectionTabs.tsx');
const css=read('app/globals.css');
const template=read('components/TemplateNetworkApp.tsx');
const fca=read('components/FamilyAssociationAdminPanel.tsx');
const familyAdmin=read('components/FamilyAdminCenter.tsx');
const familyApp=read('components/NetworkApp.tsx');
const familyGuide=read('components/GuidePortal.tsx');
const alumni=read('components/AlumniNetworkApp.tsx');
const funds=read('components/shared/NetworkFundsPanel.tsx');
const voting=read('components/shared/NetworkVotingPanel.tsx');
const activity=read('components/shared/NetworkActivityHub.tsx');
const participation=read('components/ParticipationCenter.tsx');
const media=read('components/shared/MediaManagementPanel.tsx');
const networksHome=read('components/MyNetworksHome.tsx');
const housingManage=read('components/HousingSocietyManageWorkspace.tsx');
const finance=read('components/HousingSocietyFinancePanel.tsx');
const governance=read('components/HousingSocietyGovernancePanel.tsx');
const security=read('components/HousingSocietySecurityPanel.tsx');
const handbook=read('USER-EXPERIENCE-HANDBOOK.md');
const rules=read('DEVELOPMENT-RULES.md');
const checks=[
 ['shared responsive section primitive exists',responsive.includes('data-ui-progressive="tabs"')&&responsive.includes('responsive-section-tab-select')],
 ['mobile section navigation uses select instead of horizontal tab scrolling',css.includes('@media(max-width:760px)')&&css.includes('.responsive-section-tab-buttons{display:none}')&&css.includes('.responsive-section-tab-select{display:grid')],
 ['shared workspace/card-grid layout is available',css.includes('.section-workspace{')&&css.includes('.progressive-card-grid{display:grid')],
 ['productized vertical admin is progressive',template.includes('genericManageSection')&&template.includes('data-testid="qa-product-manage-workspace"')&&template.includes('<ResponsiveSectionTabs')],
 ['productized community life is progressive',template.includes('data-testid="qa-community-workspace"')&&template.includes('communitySection==="posts"')&&template.includes('communitySection==="life"')&&template.includes('communitySection==="knowledge"')],
 ['productized contributions are progressive',template.includes('data-testid="qa-contribution-workspace"')&&template.includes('contributionSection==="new"')&&template.includes('contributionSection==="requests"')],
 ['productized guide is progressive',template.includes('data-testid="qa-product-guide-workspace"')&&template.includes('productGuideSection==="start"')&&template.includes('productGuideSection==="capabilities"')&&template.includes('productGuideSection==="deeper"')],
 ['Family Community admin is progressive',fca.includes('ResponsiveSectionTabs')&&['policy','year','membership','leadership','finance'].every(x=>fca.includes(`section==="${x}"`))],
 ['Family admin center uses responsive sections',familyAdmin.includes('ResponsiveSectionTabs')&&!familyAdmin.includes('admin-center-tabs')],
 ['Family advanced administration renders one category at a time',familyApp.includes('familyAdvancedSection')&&['health','privacy','governance','data'].every(x=>familyApp.includes(`familyAdvancedSection==="${x}"`))],
 ['Family guide overview uses progressive disclosure',familyGuide.includes('data-testid="qa-family-guide-workspace"')&&['discover','people','build','ideas'].every(x=>familyGuide.includes(`overviewSection==="${x}"`))],
 ['Family guide library uses internal mode ids, not translated display text',familyGuide.includes('(mode==="library"||mode==="privacy")')&&!familyGuide.includes('mode===tr("LibraryTxt")')],
 ['Alumni admin is progressive',alumni.includes('data-testid="qa-alumni-admin-workspace"')&&['overview','participation','data','lifecycle'].every(x=>alumni.includes(`adminSection==="${x}"`))],
 ['shared Funds surface is sectioned',funds.includes('ResponsiveSectionTabs')&&['overview','manage','dues','transactions'].every(x=>funds.includes(`section==="${x}"`))],
 ['shared Voting surface is sectioned',voting.includes('ResponsiveSectionTabs')&&['ballots','nominate','manage'].every(x=>voting.includes(`section==="${x}"`))],
 ['shared Activity/Groups surface is sectioned without horizontal tab scrolling',activity.includes('ResponsiveSectionTabs')&&activity.includes('area==="activities"')&&activity.includes('area==="groups"')&&!activity.includes('className="activity-tabs"')],
 ['Family participation center uses responsive section navigation',participation.includes('ResponsiveSectionTabs')&&!participation.includes('className="participation-tabs"')],
 ['shared media management uses responsive filters',media.includes('ResponsiveSectionTabs')&&!media.includes('className="media-filter-tabs"')],
 ['network tool navigation switches to a mobile selector',networksHome.includes('className="nx8-tool-select"')&&css.includes('.nx8-tool-rail{display:none}.nx8-tool-select{display:grid')],
 ['Housing Manage Society is sectioned',housingManage.includes('ResponsiveSectionTabs')||housingManage.includes('HousingSectionTabs')||housingManage.includes('content[active]')],
 ['Housing Finance/Governance/Security remain sectioned',[finance,governance,security].every(x=>x.includes('HousingSectionTabs'))],
 ['UX handbook contains cross-vertical density rule',handbook.includes('Cross-vertical progressive-disclosure rule')&&handbook.includes('Do not append a new peer block to the bottom of an already long operational page')],
 ['development rules make progressive disclosure permanent',rules.includes('Permanent UI density rule')&&rules.includes('tabs / mobile selector')],
];
let failed=0;for(const [name,ok] of checks){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)failed++}
console.log(`Progressive disclosure UX gate: ${checks.length-failed}/${checks.length}`);if(failed)process.exit(1);
