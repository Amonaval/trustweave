/** Inventory of declared vertical capabilities. Metadata records present ownership and gaps;
 * it does not grant permission or imply that a policy or telemetry hook is enforced. */
export type CapabilityContract = Readonly<{
  owner: string;
  source: string;
  commands: readonly string[];
  queries: readonly string[];
  events: readonly string[];
  /** Known table references; these may be shared across owners and are not an exclusive schema grant. */
  persistenceNamespace: readonly string[];
  policyBoundary: "existing-rpc-rls" | "shared-application" | "unmapped";
  apiRoutes: readonly string[];
  uiRoute: "shared-network-surface" | "none";
  observability: "not-standardized";
  loadingBoundary: "current-shared-bundle";
}>;

function contract(owner:string,source:string,options:Partial<Omit<CapabilityContract,"owner"|"source">>={}):CapabilityContract {
  return Object.freeze({owner,source,commands:[],queries:[],events:[],persistenceNamespace:[],policyBoundary:"unmapped",apiRoutes:[],uiRoute:"shared-network-surface",observability:"not-standardized",loadingBoundary:"current-shared-bundle",...options});
}

/** Capability IDs are derived from these records, not a second maintained union. */
export const CAPABILITY_MANIFEST={
  "network.context":contract("network-context","capabilities/network-context/remote.ts",{commands:["setActiveNetwork"],queries:["fetchMyNetworkMemberships"],persistenceNamespace:["public.networks","public.network_memberships"],policyBoundary:"existing-rpc-rls"}),
  "network.membership":contract("participation","capabilities/participation/remote.ts",{commands:["joinNetwork"],apiRoutes:["app/api/v1/networks/join/route.ts"],persistenceNamespace:["public.network_memberships"],policyBoundary:"existing-rpc-rls"}),
  "network.construction":contract("construction","capabilities/construction/runtime.ts",{commands:["createNetwork"],apiRoutes:["app/api/v1/networks/create/route.ts"],persistenceNamespace:["public.networks"],policyBoundary:"existing-rpc-rls"}),
  "network.affiliation":contract("affiliation","capabilities/affiliation/remote.ts",{queries:["fetchNetworkAffiliatedEntities","fetchNetworkProjections"],persistenceNamespace:["public.network_entities","public.network_projections"],policyBoundary:"existing-rpc-rls"}),
  "network.activity":contract("activity","capabilities/activity/remote.ts",{commands:["createNetworkActivity","respondNetworkEvent"],queries:["fetchNetworkActivities"],persistenceNamespace:["public.network_activities"],policyBoundary:"existing-rpc-rls"}),
  "network.intelligence":contract("intelligence-adapter","capabilities/intelligence-adapter/runtime.ts",{queries:["createKnowledgeIntelligenceRuntime"]}),
  "runtime.launch-control":contract("launch-runtime","capabilities/launch-runtime/remote.ts"),
  "runtime.guide":contract("guide","lib/user-guide-content.ts",{policyBoundary:"shared-application"}),
  "runtime.playground":contract("playground","app-shell/vertical-runtime.ts",{policyBoundary:"shared-application"}),
  "runtime.whats-new":contract("whats-new","app-shell/vertical-runtime.ts",{policyBoundary:"shared-application"}),
  "identity.claiming":contract("identity-claiming","capabilities/identity-claiming/runtime.ts",{commands:["claimIdentity"],apiRoutes:["app/api/v1/identities/claim/route.ts"],policyBoundary:"existing-rpc-rls"}),
  "identity.invitations":contract("participation","capabilities/participation/remote.ts",{apiRoutes:["app/api/v1/networks/[networkId]/invitations/route.ts"],persistenceNamespace:["public.network_memberships"],policyBoundary:"existing-rpc-rls"}),
  "identity.privacy":contract("identity","lib/identity.tsx",{policyBoundary:"shared-application"}),
  "contribution.governed":contract("participation","capabilities/participation/remote.ts",{persistenceNamespace:["public.network_contributions"],policyBoundary:"existing-rpc-rls"}),
  "community.groups-events":contract("activity","capabilities/activity/remote.ts",{commands:["createNetworkGroup","createNetworkActivity"],queries:["fetchNetworkGroups","fetchNetworkActivities"],persistenceNamespace:["public.network_groups","public.network_activities"],policyBoundary:"existing-rpc-rls"}),
  "notifications.digest":contract("notifications","lib/notification-routing.ts",{persistenceNamespace:["public.notifications"],policyBoundary:"shared-application"}),
  "domain.kinship":contract("family","verticals/family/participation/adapter.ts",{policyBoundary:"existing-rpc-rls"}),
  "domain.institutional-membership":contract("alumni","verticals/alumni/runtime/composition.ts",{persistenceNamespace:["public.alumni_profiles"],policyBoundary:"existing-rpc-rls"}),
  "domain.community-association":contract("association","verticals/association/runtime/composition.ts"),
  "domain.family-association":contract("family-association","verticals/family-association/runtime/composition.ts"),
  "domain.housing-society":contract("housing-society","verticals/housing-society/runtime/remote.ts",{persistenceNamespace:["public.hs_complaints"],policyBoundary:"existing-rpc-rls"}),
  "domain.organizational-intelligence":contract("organization","verticals/organization/runtime/composition.ts"),
  "domain.business-trust":contract("business-trust","verticals/business-trust/runtime/composition.ts"),
  "domain.franchise-operations":contract("franchise","verticals/franchise/runtime/composition.ts"),
  "domain.professional-expertise":contract("professional","verticals/professional/runtime/composition.ts"),
} as const satisfies Record<string,CapabilityContract>;

export type VerticalCapabilityId=keyof typeof CAPABILITY_MANIFEST;

export function getCapabilityContract(id:VerticalCapabilityId):CapabilityContract;
export function getCapabilityContract(id:string):CapabilityContract;
export function getCapabilityContract(id:string):CapabilityContract {
  if(!Object.prototype.hasOwnProperty.call(CAPABILITY_MANIFEST,id))throw new Error(`Unknown capability: ${id}`);
  return CAPABILITY_MANIFEST[id as VerticalCapabilityId];
}
