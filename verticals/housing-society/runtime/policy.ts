import {decideScopedAuthorization,type ScopedAuthorizationRequest} from "../../../core/authorization/policy";

export const HOUSING_UNIT_OCCUPANCY_RELATION="housing.unit.occupancy";
export type HousingUnitPolicyAction="unit.read"|"unit.manage";
type HousingRequest=Omit<ScopedAuthorizationRequest,"capability"|"action">&Readonly<{action:HousingUnitPolicyAction}>;

/** Thin Housing-owned rules over the shared policy engine. Persistence/RLS remains authoritative. */
export function decideHousingUnitAuthorization(request:HousingRequest){
  const {action,...context}=request;
  if(action==="unit.manage"){
    return decideScopedAuthorization(
      {...context,capability:"domain.housing-society",action},
      {roles:["owner","admin"],accessMode:"role-only",purposes:["housing-administration"]},
    );
  }
  return decideScopedAuthorization(
    {...context,capability:"domain.housing-society",action},
    {
      roles:["owner","admin"],
      relationshipKinds:[HOUSING_UNIT_OCCUPANCY_RELATION],
      accessMode:"role-or-relationship",
      purposes:["housing-operations","resident-self-service"],
    },
  );
}
