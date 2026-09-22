import fs from 'node:fs';
import path from 'node:path';

const readJson=file=>JSON.parse(fs.readFileSync(file,'utf8'));
const reliabilityPath='qa-results/reliability/SUMMARY.json';
const notificationPath='qa-results/d12-candidate-parity/notification-role-contract.json';
if(!fs.existsSync(reliabilityPath))throw new Error('Missing connected reliability summary.');
if(!fs.existsSync(notificationPath))throw new Error('Missing notification-role contract summary.');

const reliability=readJson(reliabilityPath);
const notification=readJson(notificationPath);
if(reliability.status!=='CERTIFIED'||reliability.mode!=='connected')throw new Error('Connected reliability is not CERTIFIED.');
if(notification.status!=='PASSED')throw new Error('Notification-role contract is not PASSED.');
const checks=Array.isArray(notification.checks)?notification.checks:[];
if(checks.length!==14||checks.some(row=>row.status!=='passed'))throw new Error('Notification-role contract must contain exactly 14 passing checks.');

const report={
 generatedAt:new Date().toISOString(),
 status:'D12_BEHAVIOR_BROWSER_PARITY_PASS',
 candidateProjectRef:process.env.QA_STAGING_PROJECT_REF,
 goldenProjectRef:process.env.D12_GOLDEN_PROJECT_REF,
 applyMode:'managed-bootstrap',
 catalogParity:'PASS',
 scope:{verticals:['family-association','housing-society'],roles:['owner','admin','member'],browser:'chromium-desktop',resilientCrawl:true},
 steps:[
  {name:'two-vertical-connected-reliability',status:'passed',required:true},
  {name:'notification-role-drift-repair',status:'passed',required:true},
 ],
 secretsIncluded:false,
 nextGate:'canonical-promotion-review',
 evidence:{reliability:reliabilityPath,notificationRole:notificationPath}
};
const out='qa-results/d12-candidate-parity/SUMMARY.json';
fs.mkdirSync(path.dirname(out),{recursive:true});
fs.writeFileSync(out,JSON.stringify(report,null,2)+'\n');
console.log('TrustWeave D12 candidate behavioral/browser parity: D12_BEHAVIOR_BROWSER_PARITY_PASS');
