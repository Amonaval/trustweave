export type ObservedOperationKind="query"|"command"|"job"|"dependency";
export type ObservedOperationMeta=Readonly<{
 capability:string;
 journey:string;
 vertical:"shared"|"housing-society"|"family-association";
 slowMs:number;
}>;

const op=(capability:string,journey:string,vertical:ObservedOperationMeta["vertical"],slowMs:number):ObservedOperationMeta=>Object.freeze({capability,journey,vertical,slowMs});

export const OBSERVED_OPERATIONS={
 "query:housingOperations.snapshot":op("domain.housing-society","housing.operations","housing-society",1200),
 "query:housingOperations.complaint-routes":op("domain.housing-society","housing.operations","housing-society",800),
 "command:housingOperations":op("domain.housing-society","housing.operations","housing-society",1500),
 "query:familyAssociationAdmin.snapshot":op("domain.family-association","family-community.admin","family-association",1500),
 "command:familyAssociationAdmin":op("domain.family-association","family-community.admin","family-association",1500),
 "query:network.entities.page":op("network.affiliation","network.directory","shared",800),
 "query:network.relationships.page":op("network.affiliation","network.graph","shared",800),
 "query:network.members.page":op("network.membership","network.members","shared",800),
 "query:network.export":op("network.context","network.export","shared",5000),
 "command:bootstrapInstitution":op("network.construction","network.import","shared",5000),
 "command:createGraphRelationship":op("network.affiliation","network.graph","shared",1200),
} as const satisfies Record<string,ObservedOperationMeta>;

export function operationMeta(kind:"query"|"command",name:string):ObservedOperationMeta{
 return OBSERVED_OPERATIONS[`${kind}:${name}` as keyof typeof OBSERVED_OPERATIONS]||
  op("unmapped",kind==="query"?"api.read":"api.mutation","shared",kind==="query"?1000:1500);
}

export type SloDefinition=Readonly<{
 id:string;
 label:string;
 journeys:readonly string[];
 availabilityTarget:number;
 latencyP95Ms:number;
 minimumSamples:number;
 measurement:"server-runtime"|"external-browser-required";
}>;

export const SLO_MANIFEST=[
 {id:"core-read",label:"Core authenticated reads",journeys:["api.read","network.directory","network.graph","network.members"],availabilityTarget:0.995,latencyP95Ms:1200,minimumSamples:100,measurement:"server-runtime"},
 {id:"core-mutation",label:"Core authenticated mutations",journeys:["api.mutation","network.import"],availabilityTarget:0.995,latencyP95Ms:1800,minimumSamples:50,measurement:"server-runtime"},
 {id:"housing-operations",label:"Housing operations",journeys:["housing.operations"],availabilityTarget:0.995,latencyP95Ms:1500,minimumSamples:50,measurement:"server-runtime"},
 {id:"family-community-admin",label:"Family Community administration",journeys:["family-community.admin"],availabilityTarget:0.995,latencyP95Ms:1500,minimumSamples:50,measurement:"server-runtime"},
 {id:"direct-entry",label:"Authenticated network direct entry",journeys:["network.direct-entry"],availabilityTarget:0.995,latencyP95Ms:2000,minimumSamples:50,measurement:"external-browser-required"},
] as const satisfies readonly SloDefinition[];

export type SloEvent={journey:string;outcome:"success"|"failure";durationMs:number};

function percentile95(values:number[]){if(!values.length)return null;const sorted=[...values].sort((a,b)=>a-b);return sorted[Math.min(sorted.length-1,Math.ceil(sorted.length*.95)-1)]}

export function evaluateSloWindow(def:SloDefinition,events:readonly SloEvent[]){
 const matched=events.filter(e=>def.journeys.includes(e.journey));
 const successes=matched.filter(e=>e.outcome==="success").length;
 const availability=matched.length?successes/matched.length:null;
 const latencyP95Ms=percentile95(matched.filter(e=>e.outcome==="success").map(e=>e.durationMs));
 const allowedFailureRate=1-def.availabilityTarget;
 const actualFailureRate=matched.length?(matched.length-successes)/matched.length:0;
 const errorBudgetConsumedPct=allowedFailureRate>0?actualFailureRate/allowedFailureRate*100:0;
 const enough=matched.length>=def.minimumSamples;
 const withinAvailability=availability===null||availability>=def.availabilityTarget;
 const withinLatency=latencyP95Ms===null||latencyP95Ms<=def.latencyP95Ms;
 return {
  id:def.id,samples:matched.length,availability,latencyP95Ms,errorBudgetConsumedPct,
  status:!enough?"insufficient-samples":withinAvailability&&withinLatency?"within-slo":"slo-breached"
 } as const;
}

export const ERROR_BUDGET_POLICY=Object.freeze({
 releaseFreezeAtConsumedPct:100,
 warningAtConsumedPct:75,
 rule:"When a measured SLO has sufficient samples and its availability error budget is exhausted, reliability work takes precedence over non-critical feature release until the window recovers or an explicit incident review accepts the risk.",
});
