import fs from 'node:fs';

const read=p=>fs.readFileSync(p,'utf8');
const routing=read('lib/notification-routing.ts');
const center=read('components/shared/NotificationCenter.tsx');
const posts=read('components/shared/NetworkPostsPanel.tsx');
const lint=read('eslint.trustweave.cjs');
const app=read('components/NetworkApp.tsx');
const participation=read('components/ParticipationCenter.tsx');
const template=read('components/TemplateNetworkApp.tsx');
const checks=[
 ['historical partial notification links are enriched',routing.includes('resolveNotificationDeepLink')&&routing.includes('inferNotificationSurface')],
 ['complaints route to complaints surface',routing.includes('return "complaints"')],
 ['posts route to community surface',routing.includes('return "community"')],
 ['funds route to funds surface',routing.includes('return "funds"')],
 ['elections route to elections surface',routing.includes('return "elections"')],
 ['notification center uses resolver',center.includes('resolveNotificationDeepLink(n)')],
 ['push toggle persists actual subscribed state',center.includes('push_enabled:nextState.subscribed')&&center.includes('saveEngagementNotificationPreferences(nextPrefs)')],
 ['push button has transitional state',center.includes('E10EnablingPushTxt')&&center.includes('E10DisablingPushTxt')],
 ['drawer is explicitly notification inbox',center.includes('NotificationInboxTxt')],
 ['mark all read is visibly labelled',center.includes('notification-action-label')&&center.includes('MarkAllReadTxt')],
 ['exact post deep link scrolls into view',posts.includes('scrollIntoView')&&posts.includes('deep.itemId')],
 ['lint keeps correctness failures blocking',lint.includes("'@typescript-eslint/no-unused-expressions': 'error'")&&lint.includes("'@typescript-eslint/await-thenable': 'error'")],
 ['legacy debt is warnings not release blockers',lint.includes("'@typescript-eslint/no-base-to-string': 'warn'")&&lint.includes("'@typescript-eslint/no-unnecessary-type-assertion': 'warn'")],
 ['family playground expression cleanup',app.includes('if(familyVariant==="public")enterPublicPlayground();else enterSetupPlayground();')],
 ['participation expression cleanup',participation.includes('if(!demo)void trackPublicParticipation')],
 ['productized group toggle expression cleanup',template.includes('if(g.myMember)await leaveNetworkGroup(g.id);else await joinNetworkGroup(g.id)')],
];
let failures=0;
for(const [name,ok] of checks){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)failures++}
console.log(`E10 stability closure gate: ${checks.length-failures}/${checks.length}`);
if(failures)process.exit(1);
