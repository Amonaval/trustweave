import fs from 'node:fs';
const read=p=>fs.readFileSync(new URL(`../${p}`,import.meta.url),'utf8');
const migration=read('supabase/migrations/114_final_launch_runtime_contract_repair.sql');
const storage=read('lib/storage.ts');
const template=read('components/TemplateNetworkApp.tsx');
const manage=read('components/HousingSocietyManageWorkspace.tsx');
const sectionTabs=read('components/shared/HousingSectionTabs.tsx');
const finance=read('components/HousingSocietyFinancePanel.tsx');
const governance=read('components/HousingSocietyGovernancePanel.tsx');
const security=read('components/HousingSocietySecurityPanel.tsx');
const themeProvider=read('components/ThemeProvider.tsx');
const themeSwitcher=read('components/ThemeSwitcher.tsx');
const css=read('app/globals.css');
const messages=['en','hi','mr'].map(l=>read(`lib/i18n/messages/${l}.ts`));
const checks=[
 ['repair migration restores hs4 zero-argument snapshot RPC',/create or replace function public\.hs4_get_operations_snapshot\(\)/i.test(migration)],
 ['repair migration restores route_network_mentions typed RPC',migration.includes('public.route_network_mentions(')&&migration.includes('text[],text,text,text,text,uuid,text')],
 ['funds snapshot uses network_activities.activity_type',migration.includes("a.activity_type='event'")&&!migration.includes("a.type='event'")],
 ['explicit Open Voting opens immediately',migration.includes("set status='open',opens_at=now(),updated_at=now()")],
 ['media storage is authorized from path network membership',migration.includes('storage_path_network_id')&&migration.includes('public.is_network_member(public.storage_path_network_id(name))')],
 ['media guard no longer requires current_network_id equality',migration.includes('Media can only be uploaded to a network you belong to.')&&!/nid\s*<>\s*public\.current_network_id\(\)/i.test(migration)],
 ['PostgREST schema cache reload is requested after RPC repair',/notify\s+pgrst\s*,\s*'reload schema'/i.test(migration)],
 ['client storage refuses ambiguous first-membership fallback',storage.includes('.find((x:any)=>x.is_active)')&&!storage.includes('|| (data||[])[0]')&&storage.includes('Select the network you are working in before uploading media.')],
 ['Manage Society renders one categorized workspace',template.includes('<HousingSocietyManageWorkspace')&&manage.includes('content[active]')&&manage.includes('HsManageDataSettingsTxt')],
 ['Housing admin modules route into workspace sections',template.includes('members:"people"')&&template.includes('import:"data"')&&template.includes('lifecycle:"data"')],
 ['Housing More navigation is grouped on desktop/mobile',template.includes('desktopMoreGroups.map')&&template.includes('mobileMoreGroups.map')&&template.includes('HsNavRunSocietyTxt')],
 ['Finance dense admin surface has focused subsections',finance.includes('<HousingSectionTabs')&&finance.includes('financeView==="billing"')&&finance.includes('financeView==="funds"')&&finance.includes('financeView==="arrears"')],
 ['Governance dense admin surface has focused subsections',governance.includes('<HousingSectionTabs')&&governance.includes('governanceView==="committee"')&&governance.includes('governanceView==="actions"')&&governance.includes('governanceView==="resolutions"')],
 ['Security dense surface has focused subsections',security.includes('<HousingSectionTabs')&&security.includes('securityView==="visitors"')&&security.includes('securityView==="requests"')&&security.includes('securityView==="assets"')],
 ['subsection tabs collapse to a mobile select',sectionTabs.includes('hs-section-tab-select')&&css.includes('@media(max-width:620px)')],
 ['theme choices are exactly Classic / Modern / Dark',themeProvider.includes('type AppTheme="light"|"modern"|"dark"')&&themeProvider.includes('const THEMES:AppTheme[]=["light","modern","dark"]')&&themeSwitcher.includes('qa-theme-select')&&!themeSwitcher.includes('value:"warm"')&&!themeSwitcher.includes('value:"aurora"')],
 ['old Warm/Aurora preferences migrate safely',themeProvider.includes('if(value==="warm")return "light"')&&themeProvider.includes('if(value==="aurora")return "modern"')],
 ['new Housing/theme navigation copy exists in all locales',messages.every(m=>['HsManageWorkspaceTxt','HsNavRunSocietyTxt','HsNavCommunityRecordsTxt','HsNavHelpManageTxt','ThemeClassicTxt','ThemeModernTxt','ThemeDarkTxt'].every(k=>m.includes(k)))],
];
let failed=0;for(const [name,ok] of checks){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)failed++}
console.log(`Final launch runtime hotfix gate: ${checks.length-failed}/${checks.length}`);if(failed)process.exit(1);
