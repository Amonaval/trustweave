import type {NetworkMembershipRole,NetworkMembershipStatus} from "../network/contracts";

export type PolicyTimeWindow=Readonly<{validFrom?:string|null;validUntil?:string|null}>;
export type PolicyMembership=Readonly<{networkId:string;role:NetworkMembershipRole;status:NetworkMembershipStatus}&PolicyTimeWindow>;
export type PolicyResourceRef=Readonly<{networkId:string;kind:string;id:string}>;
export type ScopedRelationship=Readonly<{
  kind:string;
  networkId:string;
  actorUserId:string;
  resource:PolicyResourceRef;
}&PolicyTimeWindow>;
export type ConsentGrant=Readonly<{
  id:string;
  networkId:string;
  subjectUserId:string;
  granteeUserId:string;
  capability:string;
  action:string;
  purpose:string;
  resource?:PolicyResourceRef;
  revokedAt?:string|null;
}&PolicyTimeWindow>;

export type ScopedAuthorizationRequest=Readonly<{
  actorUserId?:string;
  membership:PolicyMembership;
  capability:string;
  action:string;
  purpose:string;
  resource?:PolicyResourceRef;
  actionWindow?:PolicyTimeWindow;
  relationships?:readonly ScopedRelationship[];
  consents?:readonly ConsentGrant[];
  consentSubjectUserId?:string;
  now?:string;
}>;

export type ScopedAuthorizationRequirement=Readonly<{
  roles?:readonly NetworkMembershipRole[];
  relationshipKinds?:readonly string[];
  accessMode?:"role-only"|"relationship-only"|"role-or-relationship"|"role-and-relationship";
  purposes?:readonly string[];
  consent?:"none"|"explicit";
}>;

export type AuthorizationDecisionReason=
  |"allowed"
  |"invalid-context"
  |"inactive-membership"
  |"network-mismatch"
  |"outside-time-window"
  |"purpose-denied"
  |"role-or-relationship-denied"
  |"consent-required";

export type ScopedAuthorizationDecision=Readonly<{
  allowed:boolean;
  reason:AuthorizationDecisionReason;
  matchedBy?:"role"|"relationship"|"role-and-relationship";
}>;

function instant(value:string|undefined):number {
  if(!value)return Date.now();
  const parsed=Date.parse(value);
  return Number.isFinite(parsed)?parsed:Number.NaN;
}
function inWindow(window:PolicyTimeWindow|undefined,now:number):boolean {
  if(!window)return true;
  const from=window.validFrom?Date.parse(window.validFrom):null;
  const until=window.validUntil?Date.parse(window.validUntil):null;
  if(from!==null&&(!Number.isFinite(from)||now<from))return false;
  if(until!==null&&(!Number.isFinite(until)||now>until))return false;
  return true;
}
function sameResource(a:PolicyResourceRef,b:PolicyResourceRef):boolean {
  return a.networkId===b.networkId&&a.kind===b.kind&&a.id===b.id;
}
function deny(reason:Exclude<AuthorizationDecisionReason,"allowed">):ScopedAuthorizationDecision {
  return {allowed:false,reason};
}
function allow(matchedBy:"role"|"relationship"|"role-and-relationship"):ScopedAuthorizationDecision {
  return {allowed:true,reason:"allowed",matchedBy};
}

/**
 * Application-level, fail-closed policy decision contract.
 * This never replaces server/RPC/RLS authorization; callers must still enforce data access there.
 */
export function decideScopedAuthorization(
  request:ScopedAuthorizationRequest,
  requirement:ScopedAuthorizationRequirement,
):ScopedAuthorizationDecision {
  const now=instant(request.now);
  const membership=request.membership;
  if(!Number.isFinite(now)||!membership.networkId||!request.capability.trim()||!request.action.trim()||!request.purpose.trim())return deny("invalid-context");
  if(membership.status!=="active")return deny("inactive-membership");
  if(request.resource&&request.resource.networkId!==membership.networkId)return deny("network-mismatch");
  if(!inWindow(membership,now)||!inWindow(request.actionWindow,now))return deny("outside-time-window");
  if(requirement.purposes?.length&&!requirement.purposes.includes(request.purpose))return deny("purpose-denied");

  const roleMatch=Boolean(requirement.roles?.includes(membership.role));
  const relationMatch=Boolean(
    request.actorUserId&&request.resource&&requirement.relationshipKinds?.length&&
    request.relationships?.some(relation=>
      relation.networkId===membership.networkId&&
      relation.actorUserId===request.actorUserId&&
      requirement.relationshipKinds!.includes(relation.kind)&&
      sameResource(relation.resource,request.resource!)&&
      inWindow(relation,now)
    )
  );
  const mode=requirement.accessMode||
    (requirement.roles?.length&&requirement.relationshipKinds?.length?"role-or-relationship":
      requirement.roles?.length?"role-only":
        requirement.relationshipKinds?.length?"relationship-only":null);
  let matchedBy:"role"|"relationship"|"role-and-relationship"|undefined;
  if(mode==="role-only"&&roleMatch)matchedBy="role";
  if(mode==="relationship-only"&&relationMatch)matchedBy="relationship";
  if(mode==="role-or-relationship"&&(roleMatch||relationMatch))matchedBy=roleMatch?"role":"relationship";
  if(mode==="role-and-relationship"&&roleMatch&&relationMatch)matchedBy="role-and-relationship";
  if(!matchedBy)return deny("role-or-relationship-denied");

  if(requirement.consent==="explicit"){
    if(!request.actorUserId||!request.consentSubjectUserId)return deny("consent-required");
    const grant=request.consents?.find(item=>
      !item.revokedAt&&
      item.networkId===membership.networkId&&
      item.subjectUserId===request.consentSubjectUserId&&
      item.granteeUserId===request.actorUserId&&
      item.capability===request.capability&&
      item.action===request.action&&
      item.purpose===request.purpose&&
      (request.resource?Boolean(item.resource&&sameResource(item.resource,request.resource)):!item.resource)&&
      inWindow(item,now)
    );
    if(!grant)return deny("consent-required");
  }
  return allow(matchedBy);
}
