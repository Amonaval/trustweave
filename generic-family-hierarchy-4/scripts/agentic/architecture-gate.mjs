import path from 'node:path';
import {readJson,read,walk,printChecks,exists} from './lib.mjs';

const policy=readJson('governance/architecture-policy.json');
const checks=[];const ok=(n,v,d='')=>checks.push([n,!!v,d]);
const srcFiles=[...walk('core',{extensions:['.ts','.tsx','.js','.mjs']}),...walk('components/shared',{extensions:['.ts','.tsx','.js','.mjs']}),...walk('verticals',{extensions:['.ts','.tsx','.js','.mjs']})];
const importRx=/(?:from\s+|import\s*\()\s*["']([^"']+)["']/g;
const violations=[];
for(const file of srcFiles){
  const source=read(file);let m;while((m=importRx.exec(source))){const spec=m[1];if(!spec.startsWith('.'))continue;const resolved=path.posix.normalize(path.posix.join(path.posix.dirname(file),spec));
    if(file.startsWith('core/')&&!file.startsWith('core/verticals/')&&resolved.startsWith('verticals/')) violations.push(`ARCH-001 ${file} -> ${spec}`);
    if(file.startsWith('components/shared/')&&resolved.startsWith('verticals/')) violations.push(`ARCH-002 ${file} -> ${spec}`);
    if(file.startsWith('verticals/')&&resolved.startsWith('verticals/')){const a=file.split('/')[1],b=resolved.split('/')[1];if(a&&b&&a!==b)violations.push(`ARCH-003 ${file} -> ${spec}`)}
  }
}
ok('architecture policy is binding',policy.status==='BINDING');
ok('architecture constitution exists',exists(policy.constitution));
ok('kernel/shared UI/vertical dependency invariants have no deterministic violations',violations.length===0,violations.slice(0,8).join(' | '));
ok('canonical progressive section contract exists',exists(policy.sharedContracts.progressiveSectionNavigation));
ok('historical migration directory remains present',exists('supabase/migrations'));
printChecks('Agentic architecture gate',checks);
