import type {ProductizedVerticalKind} from "../../templates/productized/config";

export type ApiSuccess<T>={ok:true;data:T;requestId:string};
export type ApiFailure={ok:false;error:{code:string;message:string};requestId:string};
export type ApiResponse<T>=ApiSuccess<T>|ApiFailure;

export type CreateNetworkCommand=
 | {kind:"family";name:string;slug?:string;description?:string}
 | {kind:ProductizedVerticalKind;name:string;contextValue:string;description?:string};
export type CreateNetworkResult={networkId:string;approvalStatus?:"pending"|"approved"|"rejected"};

export type JoinNetworkCommand={kind:"family"|"productized";code:string};
export type JoinNetworkResult={networkId:string};

export type CreateGraphRelationshipCommand={fromEntityId:string;toEntityId:string;relationshipType:string;metadata?:Record<string,unknown>};
export type CreateGraphRelationshipResult={relationshipId:string};

export type BootstrapInstitutionRow={kind?:string;label:string;metadata?:Record<string,unknown>;affiliations?:Record<string,string|string[]>};
export type BootstrapInstitutionCommand={rows:BootstrapInstitutionRow[]};
export type BootstrapInstitutionResult={inserted:number;updated:number;skipped:number};

export type ClaimIdentityCommand={kind:"family"|"alumni"|"productized";subjectId:string};
export type ClaimIdentityResult={networkId:string};

export type RequestNetworkBridgeCommand={sourceNetworkId:string;targetCode:string;relationshipType:"affiliation"|"community"|"partner"|"parent_child"|"trusted_peer";contextLabel?:string;capabilities:{discovery:boolean;introductions:boolean;pathTraversal:boolean}};
export type RequestNetworkBridgeResult={bridgeId:string};
export type ReviewNetworkBridgeCommand={bridgeId:string;accept:boolean};
export type ReviewNetworkBridgeResult={bridgeId:string;status:"accepted"|"declined"};
export type RevokeNetworkBridgeCommand={bridgeId:string};
export type RevokeNetworkBridgeResult={bridgeId:string;status:"revoked"};
export type NetworkBridgeCodeCommand={networkId:string;regenerate?:boolean};
export type NetworkBridgeCodeResult={networkId:string;code:string};

export type DiscoverTrustedNetworkCommand={sourceNetworkId:string;query:string;limit?:number};
export type DiscoverTrustedNetworkResult={candidates:Array<{candidateId:string;targetNetworkId:string;targetNetworkName:string;bridgeId:string;relationshipType:string;matchHint:string;pathDepth:1|2;pathSummary:string}>};
export type RequestTrustedIntroductionCommand={candidateId:string;message:string};
export type RequestTrustedIntroductionResult={introductionId:string};
export type ReviewTrustedIntroductionCommand={introductionId:string;accept:boolean};
export type ReviewTrustedIntroductionResult={introductionId:string;status:"accepted"|"declined"};


export type HousingOperationsCommand=
 | {action:"createNotice";input:{title:string;body?:string;noticeType?:string;pinned?:boolean;expiresAt?:string|null}}
 | {action:"createComplaint";input:{unitEntityId?:string|null;category:string;title:string;description?:string;priority?:string;photoPath?:string}}
 | {action:"updateComplaint";input:{id:string;status?:string;assignedTo?:string|null;assignedVendorId?:string|null;slaDueAt?:string|null;resolutionNote?:string|null}}
 | {action:"addComplaintComment";input:{id:string;body:string}}
 | {action:"upsertVendor";input:{id?:string;name:string;category:string;contactName?:string;phone?:string;email?:string;status?:string}}
 | {action:"createVendorContract";input:{vendorId:string;title:string;startsOn?:string|null;endsOn?:string|null;sla?:string|null;amount?:number|null}}
 | {action:"upsertAmenity";input:{id?:string;name:string;description?:string;location?:string;capacity?:number|null;bookingMode?:string;status?:string}}
 | {action:"createAmenityBooking";input:{amenityId:string;unitEntityId?:string|null;startsAt:string;endsAt:string;purpose?:string}}
 | {action:"reviewAmenityBooking";input:{id:string;status:"approved"|"rejected"|"cancelled"}}
 | {action:"setComplaintRoute";input:{category:string;roleKey:string}};
export type HousingOperationsCommandResult={id?:string;notificationIds?:string[]};

export type FamilyAssociationAdminCommand=
 | {action:"updateSettings";input:{dependentAgeLimit:number;gracePeriodDays:number;maxAutoChildren:number;onboardingPolicy:string;financeVisibility:string}}
 | {action:"upsertMembershipYear";input:{id?:string|null;label:string;startDate:string;endDate:string;familyFee:number;gracePeriodDays:number;status:string}}
 | {action:"setFamilyMembership";input:{yearId:string;familyEntityId:string;representativeEntityId?:string|null;status:string;paymentStatus:string;amountPaid:number;paymentReference?:string}}
 | {action:"assignRole";input:{yearId?:string|null;personEntityId:string;roleCatalogId:string;startsOn?:string|null;endsOn?:string|null;notes?:string}}
 | {action:"addFinanceEntry";input:{yearId:string;entryType:string;amount:number;description?:string;visibility:string}};
export type FamilyAssociationAdminCommandResult={id?:string};
