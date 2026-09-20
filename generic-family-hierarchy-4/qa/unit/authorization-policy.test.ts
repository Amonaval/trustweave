import {test} from "node:test";
import {strict as assert} from "node:assert";
import {decideScopedAuthorization,type ConsentGrant,type PolicyMembership,type PolicyResourceRef,type ScopedRelationship} from "../../core/authorization/policy";
import {decideHousingUnitAuthorization,HOUSING_UNIT_OCCUPANCY_RELATION} from "../../verticals/housing-society/runtime/policy";
import {decideFamilyAssociationAuthorization,FAMILY_ASSOCIATION_HOUSEHOLD_RELATION} from "../../verticals/family-association/runtime/policy";

const now="2026-09-19T12:00:00.000Z";
const networkId="12345678-1234-4123-8123-123456789abc";
const otherNetworkId="aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const member=(role:"owner"|"admin"|"member"="member",overrides:Partial<PolicyMembership>={}):PolicyMembership=>({networkId,role,status:"active",...overrides});
const resource=(kind:string,id:string,net=networkId):PolicyResourceRef=>({networkId:net,kind,id});

test("scoped authorization fails closed for inactive, cross-network, wrong-purpose and expired contexts",()=>{
 const base={membership:member(),capability:"domain.housing-society",action:"unit.read",purpose:"resident-self-service",resource:resource("housing.unit","A-101"),now};
 const requirement={roles:["member"] as const,accessMode:"role-only" as const,purposes:["resident-self-service"] as const};
 assert.equal(decideScopedAuthorization(base,requirement).allowed,true);
 assert.equal(decideScopedAuthorization({...base,membership:member("member",{status:"suspended"})},requirement).reason,"inactive-membership");
 assert.equal(decideScopedAuthorization({...base,resource:resource("housing.unit","A-101",otherNetworkId)},requirement).reason,"network-mismatch");
 assert.equal(decideScopedAuthorization({...base,purpose:"finance-review"},requirement).reason,"purpose-denied");
 assert.equal(decideScopedAuthorization({...base,membership:member("member",{validUntil:"2026-09-18T12:00:00.000Z"})},requirement).reason,"outside-time-window");
});

test("Housing policy allows administrators or a current unit relationship, never unrelated member management",()=>{
 const unit=resource("housing.unit","A-101");
 const relation:ScopedRelationship={kind:HOUSING_UNIT_OCCUPANCY_RELATION,networkId,actorUserId:"resident-1",resource:unit,validFrom:"2026-01-01T00:00:00.000Z"};
 assert.equal(decideHousingUnitAuthorization({action:"unit.read",actorUserId:"resident-1",membership:member(),purpose:"resident-self-service",resource:unit,relationships:[relation],now}).matchedBy,"relationship");
 assert.equal(decideHousingUnitAuthorization({action:"unit.read",actorUserId:"admin-1",membership:member("admin"),purpose:"housing-operations",resource:unit,now}).matchedBy,"role");
 assert.equal(decideHousingUnitAuthorization({action:"unit.manage",actorUserId:"resident-1",membership:member(),purpose:"housing-administration",resource:unit,relationships:[relation],now}).allowed,false);
 assert.equal(decideHousingUnitAuthorization({action:"unit.read",actorUserId:"resident-1",membership:member(),purpose:"resident-self-service",resource:resource("housing.unit","B-202"),relationships:[relation],now}).allowed,false);
});

test("Family Community policy keeps administration role-scoped while household reads can be relationship-scoped",()=>{
 const household=resource("family-association.household","HH-1");
 const relation:ScopedRelationship={kind:FAMILY_ASSOCIATION_HOUSEHOLD_RELATION,networkId,actorUserId:"member-1",resource:household};
 assert.equal(decideFamilyAssociationAuthorization({action:"household.read",actorUserId:"member-1",membership:member(),purpose:"member-self-service",resource:household,relationships:[relation],now}).matchedBy,"relationship");
 assert.equal(decideFamilyAssociationAuthorization({action:"community.manage",actorUserId:"admin-1",membership:member("admin"),purpose:"community-administration",resource:household,now}).matchedBy,"role");
 assert.equal(decideFamilyAssociationAuthorization({action:"community.manage",actorUserId:"member-1",membership:member(),purpose:"community-administration",resource:household,relationships:[relation],now}).allowed,false);
});

test("explicit consent is exact to subject, grantee, capability, action, resource, purpose and time",()=>{
 const profile=resource("identity.profile","person-2");
 const request={actorUserId:"member-1",membership:member(),capability:"identity.privacy",action:"contact.read",purpose:"community-introduction",resource:profile,consentSubjectUserId:"person-2",now};
 const requirement={roles:["owner","admin","member"] as const,accessMode:"role-only" as const,purposes:["community-introduction"] as const,consent:"explicit" as const};
 assert.equal(decideScopedAuthorization(request,requirement).reason,"consent-required");
 const grant:ConsentGrant={id:"consent-1",networkId,subjectUserId:"person-2",granteeUserId:"member-1",capability:"identity.privacy",action:"contact.read",purpose:"community-introduction",resource:profile,validUntil:"2026-10-01T00:00:00.000Z"};
 assert.equal(decideScopedAuthorization({...request,consents:[grant]},requirement).allowed,true);
 assert.equal(decideScopedAuthorization({...request,consents:[{...grant,revokedAt:"2026-09-19T11:00:00.000Z"}]},requirement).reason,"consent-required");
 assert.equal(decideScopedAuthorization({...request,consents:[{...grant,purpose:"directory-export"}]},requirement).reason,"consent-required");
});
