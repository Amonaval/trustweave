import fs from 'node:fs';
import path from 'node:path';
import {readJson,treeHash,walk} from './agentic/lib.mjs';

const read=p=>fs.readFileSync(p,'utf8');
const checks=[];const ok=(name,pass,detail='')=>checks.push([name,Boolean(pass),detail]);
const panels={
 finance:read('components/HousingSocietyFinancePanel.tsx'),
 governance:read('components/HousingSocietyGovernancePanel.tsx'),
 security:read('components/HousingSocietySecurityPanel.tsx'),
};
const responsive=read('components/shared/ResponsiveSectionTabs.tsx');
const css=read('app/globals.css');
const mission=readJson('missions/mission-003/m3-b6-e1/mission.json');
const liveComponentFiles=walk('components',{extensions:['.ts','.tsx']});
const liveHousingSelectorRefs=liveComponentFiles.filter(file=>read(file).includes('HousingSectionTabs'));

ok('legacy HousingSectionTabs component is removed',!fs.existsSync('components/shared/HousingSectionTabs.tsx'));
ok('zero live component references to HousingSectionTabs',liveHousingSelectorRefs.length===0,liveHousingSelectorRefs.join(', '));
for(const [name,content] of Object.entries(panels)){
 ok(`${name} imports canonical ResponsiveSectionTabs`,content.includes('import ResponsiveSectionTabs from "./shared/ResponsiveSectionTabs"'));
 ok(`${name} renders canonical ResponsiveSectionTabs`,content.includes('<ResponsiveSectionTabs'));
 ok(`${name} uses active/onChange selector contract`,/active=\{(?:financeView|governanceView|securityView)\}/.test(content)&&content.includes('onChange='));
}
ok('finance preserves billing/funds/arrears branches',['billing','funds','arrears'].every(x=>panels.finance.includes(`financeView==="${x}"`)));
ok('governance preserves committee/actions/resolutions branches',['committee','actions','resolutions'].every(x=>panels.governance.includes(`governanceView==="${x}"`)));
ok('security preserves visitors/requests/assets branches',['visitors','requests','assets'].every(x=>panels.security.includes(`securityView==="${x}"`)));
ok('canonical selector exposes deterministic QA ids',responsive.includes('data-testid="qa-section-tabs"')&&responsive.includes('data-testid={`qa-section-${option.id}`}')&&responsive.includes('data-testid="qa-section-select"'));
ok('canonical selector keeps tab semantics',responsive.includes('role="tablist"')&&responsive.includes('role="tab"')&&responsive.includes('aria-selected={active===option.id}'));
ok('canonical selector keeps mobile select path',responsive.includes('responsive-section-tab-select')&&responsive.includes('onChange={event=>onChange(event.target.value as T)}'));
ok('obsolete Housing selector CSS is gone',!css.includes('.hs-section-tabs')&&!css.includes('.hs-section-tab-buttons')&&!css.includes('.hs-section-tab-select'));
ok('canonical responsive selector CSS remains',css.includes('.responsive-section-tabs')&&css.includes('.responsive-section-tab-buttons')&&css.includes('.responsive-section-tab-select')&&css.includes('@media(max-width:760px)'));
ok('mission remains R1 and runtime-evidence bound',mission.risk==='R1'&&mission.runtimeEvidenceRequired===true);
ok('mission forbids migration writes',(mission.scope?.forbiddenWrites||[]).includes('supabase/migrations/**'));
const expected=mission.baseline?.protectedTreeHashes?.['supabase/migrations'];
const actual=treeHash('supabase/migrations');
ok('Supabase migration tree is byte-stable',Boolean(expected)&&expected===actual,`${actual}${expected&&expected!==actual?` expected ${expected}`:''}`);

let failed=0;for(const [name,pass,detail] of checks){console.log(`${pass?'PASS':'FAIL'} ${name}${detail?` — ${detail}`:''}`);if(!pass)failed++}
console.log(`M3-B6 progressive selector gate: ${checks.length-failed}/${checks.length}`);if(failed)process.exit(1);
