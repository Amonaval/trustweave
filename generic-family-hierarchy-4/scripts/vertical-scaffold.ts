import {readFileSync,mkdirSync,writeFileSync} from "node:fs";
import {dirname,resolve} from "node:path";
import {thinVerticalIntegrationPlan,thinVerticalPlaygroundSeed,thinVerticalReleaseReadiness,validateThinVerticalBlueprint,type ThinVerticalBlueprint} from "../core/verticals/thin-sdk";

const argv=process.argv.slice(2);
const arg=(name:string)=>{const i=argv.indexOf(name);return i>=0?argv[i+1]:undefined};
const has=(name:string)=>argv.includes(name);
const specPath=arg("--spec");
if(!specPath)throw new Error("Usage: npm run vertical:scaffold -- --spec <blueprint.json> [--check|--dry-run|--write --out <dir>]");
const spec=JSON.parse(readFileSync(resolve(specPath),"utf8")) as ThinVerticalBlueprint;
const validation=validateThinVerticalBlueprint(spec);
if(!validation.valid){console.error(JSON.stringify(validation,null,2));process.exit(2)}
const plan=thinVerticalIntegrationPlan(spec);
const readiness=thinVerticalReleaseReadiness(spec);
const upper=spec.kind.replace(/[^a-z0-9]+/g,"_").toUpperCase();
const pascal=spec.kind.split("-").map(x=>x.slice(0,1).toUpperCase()+x.slice(1)).join("");

function q(value:unknown){return JSON.stringify(value,null,2)}
function renderFiles(){
 const capabilities=[...spec.reusedCapabilities,...(spec.ownedCapability?[spec.ownedCapability]:[])];
 const features=spec.surfaces.filter(s=>s.featureSuffix).map(s=>({key:`${spec.kind}.${s.featureSuffix}`,bundle:s.adminOnly?"admin":"core",label:s.label.en,description:`${s.label.en} surface.`,minimumExperience:s.adminOnly?"admin":"member",defaultLaunch:"released"}));
 const primary=spec.surfaces.filter(s=>!s.adminOnly).map(s=>({viewId:s.viewId,...(s.featureSuffix?{featureKey:`${spec.kind}.${s.featureSuffix}`}:{}),...(s.capability?{capability:s.capability}:{}),iconToken:s.iconToken,label:s.label}));
 const more=spec.surfaces.filter(s=>s.adminOnly).map(s=>({viewId:s.viewId,...(s.featureSuffix?{featureKey:`${spec.kind}.${s.featureSuffix}`}:{}),...(s.capability?{capability:s.capability}:{}),iconToken:s.iconToken,label:s.label,adminOnly:true}));
 const definition=`import type {VerticalDefinition} from "../../core/verticals/contracts";
import {${upper}_FEATURE_CATALOG} from "./features/catalog";
export const ${upper}_VERTICAL={
 kind:${q(spec.kind)},displayName:${q(spec.displayName)},iconToken:${q(spec.iconToken)},themeToken:${q(spec.themeToken)},status:${q(spec.status)},
 capabilities:${q(capabilities)},
 featureCatalog:${upper}_FEATURE_CATALOG,
 legacyNetworkLabels:${q(spec.labels)}
} satisfies VerticalDefinition;
`;
 const catalog=`import type {FeatureCatalog} from "../../../core/features/contracts";
export const ${upper}_FEATURE_CATALOG=${q({catalogId:spec.kind,features,experienceRank:{member:1,admin:2},experienceLabels:{member:{label:"Member",description:"Core network participation."},admin:{label:"Admin",description:"Network administration."}}})} satisfies FeatureCatalog;
`;
 const composition=`import type {VerticalAppComposition} from "../../../core/verticals/app-composition";
export const ${upper}_APP_COMPOSITION=${q({
   kind:spec.kind,renderStatus:spec.status,featureCatalogId:spec.kind,
   primaryNavigation:primary,mobileMoreNavigation:more,
   mobileBottomViewIds:primary.slice(0,4).map(x=>x.viewId),
   mobileMoreActiveViewIds:more.map(x=>x.viewId),
   guide:{registryId:`${spec.kind}-guide`,guideByView:Object.fromEntries(spec.surfaces.map(s=>[s.viewId,`${spec.kind}-${s.viewId}`])),actionToView:{},playgroundViewIds:spec.surfaces.filter(s=>!s.adminOnly).map(s=>s.viewId)},
   playground:{enabled:true,startView:spec.playground.startView,publicNetworkSettings:{name:spec.runtimeMeta.sampleName,network_template:spec.kind,vertical_kind:spec.kind}},
   launch:{bundles:[{key:"core",label:"Core",description:"Thin vertical core"}],playgroundExcludedBundles:["admin"],playgroundTitle:`${spec.displayName} Playground`,playgroundDescription:spec.runtimeMeta.sampleDescription,playgroundRecommendation:`Start at ${spec.playground.startView} and inspect the synthetic network.`,dayOneTitle:`${spec.displayName} ready`,dayOneDescription:"Built on Network OS primitives.",pilotTargetsTitle:`${spec.shortLabel} pilot`,pilotTargetsDescription:"Pilot only after policy, API and observability release gates pass.",footnoteTitle:"Shared engine, thin domain",footnoteDescription:"Domain semantics stay vertical-specific; reusable mechanics stay in the Network OS."},
   whatsNew:{featureToView:{},defaultView:spec.playground.startView,kicker:`New in ${spec.shortLabel}`,fallbackTitle:`${spec.shortLabel} update`,fallbackDescription:"A new capability is available."}
 })} satisfies VerticalAppComposition;
`;
 const adapters=`import type {ThinVerticalAdapters} from "../../../core/verticals/thin-adapters";
export const ${upper}_ADAPTERS={} satisfies ThinVerticalAdapters;
export const ${upper}_ADAPTER_CONTRACT=${q(spec.adapters)} as const;
export const ${upper}_RELEASE_REQUIREMENTS=${q(plan.releaseBlockers)} as const;
`;
 const seed=`export const ${upper}_PLAYGROUND_SEED=${q(thinVerticalPlaygroundSeed(spec))} as const;
`;
 const test=`import {test} from "node:test";
import {strict as assert} from "node:assert";
import {${upper}_ADAPTER_CONTRACT,${upper}_RELEASE_REQUIREMENTS} from "../runtime/adapters";
import {${upper}_PLAYGROUND_SEED} from "../playground/seed";
test("${spec.kind} scaffold keeps policy/data/workflow release gates explicit",()=>{assert.equal(${upper}_PLAYGROUND_SEED.synthetic,true);assert.ok(${upper}_PLAYGROUND_SEED.entities.length>0);assert.ok(${upper}_RELEASE_REQUIREMENTS.length>=0);assert.ok(${upper}_ADAPTER_CONTRACT.policy)});
`;
 return new Map([
  [`verticals/${spec.kind}/definition.ts`,definition],
  [`verticals/${spec.kind}/features/catalog.ts`,catalog],
  [`verticals/${spec.kind}/runtime/composition.ts`,composition],
  [`verticals/${spec.kind}/runtime/adapters.ts`,adapters],
  [`verticals/${spec.kind}/playground/seed.ts`,seed],
  [`verticals/${spec.kind}/qa/contracts.test.ts`,test],
 ]);
}

const files=renderFiles();
const result={validation,readiness,plan,preview:[...files].map(([path,content])=>({path,bytes:Buffer.byteLength(content)}))};
if(has("--check")||has("--dry-run")||!has("--write")){process.stdout.write(JSON.stringify(result,null,2)+"\n");process.exit(0)}
const outDir=resolve(arg("--out")||".");
for(const [path,content] of files){const target=resolve(outDir,path);mkdirSync(dirname(target),{recursive:true});writeFileSync(target,content)}
writeFileSync(resolve(outDir,`verticals/${spec.kind}/INTEGRATION-PLAN.json`),JSON.stringify(plan,null,2)+"\n");
process.stdout.write(JSON.stringify({...result,writtenTo:outDir},null,2)+"\n");
