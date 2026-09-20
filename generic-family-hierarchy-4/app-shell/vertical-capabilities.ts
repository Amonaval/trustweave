import type {NetworkVerticalKind} from "../core/verticals/contracts";
import {NETWORK_VERTICAL_KINDS} from "../core/verticals/kinds";
import {createIdentityClaimingRuntime} from "../capabilities/identity-claiming/runtime";
import {createParticipationRuntime} from "../capabilities/participation/runtime";
import {createNetworkConstructionRuntime} from "../capabilities/construction/runtime";
import {ALUMNI_IDENTITY_CLAIM_ADAPTER} from "../verticals/alumni/identity/claiming-adapter";
import {ALUMNI_PARTICIPATION_ADAPTER} from "../verticals/alumni/participation/adapter";
import {ALUMNI_CONSTRUCTION_ADAPTER} from "../verticals/alumni/construction/adapter";
import {FAMILY_IDENTITY_CLAIM_ADAPTER} from "../verticals/family/identity/claiming-adapter";
import {FAMILY_PARTICIPATION_ADAPTER} from "../verticals/family/participation/adapter";
import {FAMILY_CONSTRUCTION_ADAPTER} from "../verticals/family/construction/adapter";
import {VERTICAL_MANIFEST} from "./vertical-manifest";

const familyRuntime={
  identityClaiming:createIdentityClaimingRuntime(FAMILY_IDENTITY_CLAIM_ADAPTER),
  participation:createParticipationRuntime(FAMILY_PARTICIPATION_ADAPTER),
  construction:createNetworkConstructionRuntime(FAMILY_CONSTRUCTION_ADAPTER),
};
const alumniRuntime={
  identityClaiming:createIdentityClaimingRuntime(ALUMNI_IDENTITY_CLAIM_ADAPTER),
  participation:createParticipationRuntime(ALUMNI_PARTICIPATION_ADAPTER),
  construction:createNetworkConstructionRuntime(ALUMNI_CONSTRUCTION_ADAPTER),
};
const productizedRuntime={mode:"productized-template",identityClaiming:null,participation:null,construction:null} as const;

type RuntimeRegistry={
  family:typeof familyRuntime;
  alumni:typeof alumniRuntime;
}&Record<Exclude<NetworkVerticalKind,"family"|"alumni">,typeof productizedRuntime>;

/** Generic productized entries derive from the manifest; only real adapters are specialized. */
const verticalCapabilities=Object.freeze({
  family:familyRuntime,
  alumni:alumniRuntime,
  ...Object.fromEntries(NETWORK_VERTICAL_KINDS.filter(kind=>VERTICAL_MANIFEST[kind].runtimeMode==="productized-template").map(kind=>[kind,productizedRuntime])),
}) as RuntimeRegistry;

export type VerticalCapabilityRuntimeRegistry=RuntimeRegistry;

export function getVerticalCapabilityRuntime<K extends NetworkVerticalKind>(kind:K):RuntimeRegistry[K] {
  if(!Object.prototype.hasOwnProperty.call(VERTICAL_MANIFEST,kind)||!Object.prototype.hasOwnProperty.call(verticalCapabilities,kind))throw new Error(`Unknown network vertical: ${kind}`);
  return verticalCapabilities[kind];
}
