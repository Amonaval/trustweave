import {CAPABILITY_MANIFEST} from "./capability-manifest";

export type ThinVerticalStatus="skeleton"|"active";
export type ThinVerticalPolicyMode="shared-membership"|"vertical-required";
export type ThinVerticalWorkflowMode="none"|"shared-primitives"|"vertical-adapter";
export type ThinVerticalDataMode="shared-api-only"|"vertical-api";
export type ThinVerticalLabel=Readonly<{en:string;hi:string;mr:string}>;

export type ThinVerticalSurface=Readonly<{
 viewId:string;
 iconToken:string;
 label:ThinVerticalLabel;
 featureSuffix?:string;
 capability?:string;
 adminOnly?:boolean;
}>;

export type ThinVerticalBlueprint=Readonly<{
 kind:string;
 displayName:string;
 shortLabel:string;
 iconToken:string;
 themeToken:string;
 status:ThinVerticalStatus;
 ownedCapability?:string|null;
 reusedCapabilities:readonly string[];
 labels:Readonly<{
  entityLabel:string;entityLabelPlural:string;levelLabel:string;levelLabelPlural:string;
  parentLabel:string;childLabel:string;peerLabel:string;
 }>;
 runtimeMeta:Readonly<{sampleName:string;sampleDescription:string}>;
 surfaces:readonly ThinVerticalSurface[];
 playground:Readonly<{
  startView:string;
  synthetic:true;
  entities:readonly Readonly<{id:string;kind:string;label:string}>[];
  relationships:readonly Readonly<{id:string;fromEntityId:string;toEntityId:string;relationshipType:string;label:string}>[];
 }>;
 adapters:Readonly<{policy:ThinVerticalPolicyMode;workflow:ThinVerticalWorkflowMode;data:ThinVerticalDataMode}>;
 observability:Readonly<{journey:string;slowMs:number}>;
}>;

export type ThinVerticalValidation=Readonly<{valid:boolean;errors:readonly string[];releaseBlockers:readonly string[]}>;
const token=/^[a-z][a-z0-9-]{1,39}$/;
const capabilityToken=/^[a-z][a-z0-9-]*(?:\.[a-z][a-z0-9-]*)+$/;

export function validateThinVerticalBlueprint(spec:ThinVerticalBlueprint):ThinVerticalValidation{
 const errors:string[]=[];const releaseBlockers:string[]=[];
 if(!token.test(spec.kind))errors.push("kind must be a lowercase route-safe token");
 if(!spec.displayName.trim()||!spec.shortLabel.trim())errors.push("displayName and shortLabel are required");
 if(!spec.iconToken.trim()||!spec.themeToken.trim())errors.push("iconToken and themeToken are required");
 if(!spec.reusedCapabilities.length)errors.push("at least one reused capability is required");
 for(const capability of spec.reusedCapabilities){
  if(!Object.prototype.hasOwnProperty.call(CAPABILITY_MANIFEST,capability))errors.push(`unknown reused capability: ${capability}`);
 }
 if(spec.ownedCapability){
  if(!capabilityToken.test(spec.ownedCapability))errors.push("ownedCapability must be a dotted capability token");
  if(spec.ownedCapability!==`domain.${spec.kind}`)errors.push(`ownedCapability must be domain.${spec.kind}`);
  if(spec.adapters.policy==="vertical-required")releaseBlockers.push("implement and independently test the vertical policy adapter");
 }
 if(spec.adapters.data==="vertical-api")releaseBlockers.push("implement server-owned query/command API boundary before activation");
 if(spec.adapters.workflow==="vertical-adapter")releaseBlockers.push("implement thin workflow adapter over shared primitives before activation");
 if(spec.observability.journey!==`${spec.kind}.primary`)errors.push(`observability journey must be ${spec.kind}.primary`);
 if(!Number.isFinite(spec.observability.slowMs)||spec.observability.slowMs<100||spec.observability.slowMs>10_000)errors.push("observability slowMs must be between 100 and 10000");
 if(!spec.surfaces.length)errors.push("at least one surface is required");
 const views=new Set<string>();
 for(const surface of spec.surfaces){
  if(!token.test(surface.viewId))errors.push(`invalid surface viewId: ${surface.viewId}`);
  if(views.has(surface.viewId))errors.push(`duplicate surface viewId: ${surface.viewId}`);
  views.add(surface.viewId);
  if(!surface.label.en.trim()||!surface.label.hi.trim()||!surface.label.mr.trim())errors.push(`surface ${surface.viewId} requires en/hi/mr labels`);
  if(surface.capability&&![...spec.reusedCapabilities,spec.ownedCapability].filter(Boolean).includes(surface.capability))errors.push(`surface ${surface.viewId} references undeclared capability ${surface.capability}`);
 }
 if(!views.has("home"))errors.push("home surface is required");
 if(!views.has(spec.playground.startView))errors.push("playground startView must reference a declared surface");
 if(spec.playground.synthetic!==true)errors.push("playground seed must be explicitly synthetic");
 if(!spec.playground.entities.length)errors.push("playground requires at least one synthetic entity");
 if(spec.playground.entities.length>50)errors.push("thin-vertical playground seed must stay at or below 50 entities");
 const entityIds=new Set(spec.playground.entities.map(x=>x.id));
 for(const rel of spec.playground.relationships){
  if(!entityIds.has(rel.fromEntityId)||!entityIds.has(rel.toEntityId))errors.push(`relationship ${rel.id} references unknown entity`);
 }
 if(spec.status==="active"&&releaseBlockers.length)errors.push("active vertical cannot have unresolved release blockers");
 return {valid:errors.length===0,errors,releaseBlockers};
}

export type ThinVerticalIntegrationPlan=Readonly<{
 kind:string;
 loadingBoundary:"lazy-vertical-ui";
 routePattern:"/network/{networkId}/{surface}";
 routeSurfaces:readonly string[];
 requiredCentralEdits:readonly Readonly<{file:string;purpose:string}>[];
 generatedFiles:readonly string[];
 releaseBlockers:readonly string[];
}>;

export function thinVerticalIntegrationPlan(spec:ThinVerticalBlueprint):ThinVerticalIntegrationPlan{
 const validation=validateThinVerticalBlueprint(spec);
 if(!validation.valid)throw new Error(`Invalid thin vertical blueprint: ${validation.errors.join("; ")}`);
 const generatedFiles=[
  `verticals/${spec.kind}/definition.ts`,
  `verticals/${spec.kind}/features/catalog.ts`,
  `verticals/${spec.kind}/runtime/composition.ts`,
  `verticals/${spec.kind}/runtime/adapters.ts`,
  `verticals/${spec.kind}/playground/seed.ts`,
  `verticals/${spec.kind}/qa/contracts.test.ts`,
 ];
 return {
  kind:spec.kind,loadingBoundary:"lazy-vertical-ui",routePattern:"/network/{networkId}/{surface}",
  routeSurfaces:spec.surfaces.map(x=>x.viewId),
  requiredCentralEdits:[
   {file:"core/verticals/kinds.ts",purpose:"add the compile-time vertical kind"},
   ...(spec.ownedCapability?[{file:"core/verticals/capability-manifest.ts",purpose:"declare owned capability, policy/API/observability ownership"}]:[]),
   {file:"templates/productized/runtime-meta.ts",purpose:"register lightweight runtime metadata only"},
   {file:"app-shell/vertical-manifest.ts",purpose:"add one explicit lazy manifest entry"},
   {file:"qa/runtime/catalog.mjs",purpose:"activate the vertical in the deterministic QA catalog when released"},
  ],
  generatedFiles,releaseBlockers:validation.releaseBlockers,
 };
}

export function thinVerticalPlaygroundSeed(spec:ThinVerticalBlueprint){
 const validation=validateThinVerticalBlueprint(spec);if(!validation.valid)throw new Error(validation.errors.join("; "));
 return {
  synthetic:true as const,
  network:{name:spec.runtimeMeta.sampleName,verticalKind:spec.kind,startView:spec.playground.startView},
  entities:spec.playground.entities,
  relationships:spec.playground.relationships,
 };
}

export function thinVerticalReleaseReadiness(spec:ThinVerticalBlueprint,input:{policyImplemented?:boolean;apiBoundaryImplemented?:boolean;workflowAdapterImplemented?:boolean}={}){
 const validation=validateThinVerticalBlueprint({...spec,status:"skeleton"});
 const blockers=[...validation.errors];
 if(spec.ownedCapability&&spec.adapters.policy==="vertical-required"&&!input.policyImplemented)blockers.push("policy adapter not implemented");
 if(spec.adapters.data==="vertical-api"&&!input.apiBoundaryImplemented)blockers.push("server API boundary not implemented");
 if(spec.adapters.workflow==="vertical-adapter"&&!input.workflowAdapterImplemented)blockers.push("workflow adapter not implemented");
 return {ready:blockers.length===0,blockers};
}
