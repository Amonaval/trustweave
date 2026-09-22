import {decideScopedAuthorization,type ScopedAuthorizationRequest} from "../../../core/authorization/policy";

export const FAMILY_ASSOCIATION_HOUSEHOLD_RELATION="family-association.household-member";
export type FamilyAssociationPolicyAction="household.read"|"community.manage";
type CommunityRequest=Omit<ScopedAuthorizationRequest,"capability"|"action">&Readonly<{action:FamilyAssociationPolicyAction}>;

/** Thin Family Community rules over the shared policy engine. Persistence/RLS remains authoritative. */
export function decideFamilyAssociationAuthorization(request:CommunityRequest){
  const {action,...context}=request;
  if(action==="community.manage"){
    return decideScopedAuthorization(
      {...context,capability:"domain.family-association",action},
      {roles:["owner","admin"],accessMode:"role-only",purposes:["community-administration"]},
    );
  }
  return decideScopedAuthorization(
    {...context,capability:"domain.family-association",action},
    {
      roles:["owner","admin"],
      relationshipKinds:[FAMILY_ASSOCIATION_HOUSEHOLD_RELATION],
      accessMode:"role-or-relationship",
      purposes:["community-directory","member-self-service"],
    },
  );
}
