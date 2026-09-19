import type {FamilyAssociationAdminCommand,FamilyAssociationAdminCommandResult} from "../../core/api/contracts";
import type {RequestContext} from "../shared/request-context";

export async function fetchFamilyAssociationAdmin(ctx:RequestContext):Promise<unknown>{
 const {data,error}=await ctx.supabase.rpc("get_fca_admin_snapshot");
 if(error)throw error;
 return data||{settings:{},years:[],memberships:[],roles:[],role_history:[],finance:[]};
}

export async function executeFamilyAssociationAdminCommand(ctx:RequestContext,c:FamilyAssociationAdminCommand):Promise<FamilyAssociationAdminCommandResult>{
 switch(c.action){
  case "updateSettings":{
   const {error}=await ctx.supabase.rpc("update_fca_settings",{p_dependent_age_limit:c.input.dependentAgeLimit,p_grace_period_days:c.input.gracePeriodDays,p_max_auto_children:c.input.maxAutoChildren,p_onboarding_policy:c.input.onboardingPolicy,p_finance_visibility:c.input.financeVisibility});
   if(error)throw error;return {};
  }
  case "upsertMembershipYear":{
   const {data,error}=await ctx.supabase.rpc("upsert_fca_membership_year",{p_id:c.input.id||null,p_label:c.input.label,p_start_date:c.input.startDate,p_end_date:c.input.endDate,p_family_fee:c.input.familyFee,p_grace_period_days:c.input.gracePeriodDays,p_status:c.input.status});
   if(error)throw error;return {id:String(data)};
  }
  case "setFamilyMembership":{
   const {data,error}=await ctx.supabase.rpc("set_fca_family_membership",{p_year_id:c.input.yearId,p_family_entity_id:c.input.familyEntityId,p_representative_entity_id:c.input.representativeEntityId||null,p_status:c.input.status,p_payment_status:c.input.paymentStatus,p_amount_paid:c.input.amountPaid,p_payment_reference:c.input.paymentReference||null});
   if(error)throw error;return {id:String(data)};
  }
  case "assignRole":{
   const {data,error}=await ctx.supabase.rpc("assign_fca_role",{p_year_id:c.input.yearId||null,p_person_entity_id:c.input.personEntityId,p_role_catalog_id:c.input.roleCatalogId,p_starts_on:c.input.startsOn||null,p_ends_on:c.input.endsOn||null,p_notes:c.input.notes||null});
   if(error)throw error;return {id:String(data)};
  }
  case "addFinanceEntry":{
   const {data,error}=await ctx.supabase.rpc("add_fca_finance_entry",{p_year_id:c.input.yearId,p_entry_type:c.input.entryType,p_amount:c.input.amount,p_description:c.input.description||null,p_visibility:c.input.visibility});
   if(error)throw error;return {id:String(data)};
  }
 }
}
