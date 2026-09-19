import type {ProductizedVerticalKind} from "../../core/verticals/kinds";

export type ProductizedRuntimeMeta=Readonly<{
 kind:ProductizedVerticalKind;
 label:string;
 shortLabel:string;
 sampleName:string;
 sampleDescription:string;
}>;

/** Lightweight startup metadata only. Heavy sample entities/activities stay in config.ts. */
export const PRODUCTIZED_RUNTIME_META={
 association:{kind:"association",label:"Community / Association",shortLabel:"Association",sampleName:"MPF East Community",sampleDescription:"10-family association pilot with events, RSVP, memories, committees and renewal"},
 "family-association":{kind:"family-association",label:"Family Community / Cultural Association",shortLabel:"Family Association",sampleName:"MPF Pune East",sampleDescription:"Full-fidelity cultural/professional family-community showcase with households, membership states, professions, committees, events, renewals, birthdays, memories and annual history"},
 "housing-society":{kind:"housing-society",label:"Residential Community / Housing Society",shortLabel:"Housing Society",sampleName:"Emerald Heights Co-operative Housing Society",sampleDescription:"72-home Kharadi society showcase represented by a lightweight 24-unit sample with residents, operations, finance, governance, security and community life"},
 organization:{kind:"organization",label:"Organizational Intelligence",shortLabel:"Organization",sampleName:"Northstar Organizational Intelligence",sampleDescription:"36-person, multi-region matrix organization showcase"},
 "business-trust":{kind:"business-trust",label:"Business Trust Network",shortLabel:"Business Trust",sampleName:"Western India Business Trust Network",sampleDescription:"36-business sourcing and warm-introduction showcase"},
 professional:{kind:"professional",label:"Trusted Expertise & Professional Network",shortLabel:"Expert Network",sampleName:"Global Trusted Expertise Network",sampleDescription:"36-professional global expertise, referral and collaboration showcase"},
 franchise:{kind:"franchise",label:"Franchise Network",shortLabel:"Franchise",sampleName:"Northstar India Franchise Network",sampleDescription:"36-location, nine-city operations showcase"},
} as const satisfies Record<ProductizedVerticalKind,ProductizedRuntimeMeta>;
