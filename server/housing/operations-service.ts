import type {HousingOperationsCommand,HousingOperationsCommandResult} from "../../core/api/contracts";
import type {RequestContext} from "../shared/request-context";

export type HousingOperationsQueryView="snapshot"|"complaint-routes";

export async function fetchHousingOperations(ctx:RequestContext,view:HousingOperationsQueryView):Promise<unknown>{
 const rpc=view==="snapshot"?"hs4_get_operations_snapshot":"hs4_get_complaint_routes";
 const {data,error}=await ctx.supabase.rpc(rpc);
 if(error)throw error;
 if(view==="snapshot")return data||{notices:[],complaints:[],vendors:[],amenities:[],bookings:[]};
 return data||[];
}

export async function executeHousingOperationsCommand(ctx:RequestContext,c:HousingOperationsCommand):Promise<HousingOperationsCommandResult>{
 switch(c.action){
  case "createNotice":{
   const {data,error}=await ctx.supabase.rpc("hs2_create_notice",{p_title:c.input.title,p_body:c.input.body||null,p_notice_type:c.input.noticeType||"general",p_pinned:!!c.input.pinned,p_expires_at:c.input.expiresAt||null});
   if(error)throw error;return {id:String(data)};
  }
  case "createComplaint":{
   const {data,error}=await ctx.supabase.rpc("hs4_create_complaint",{p_unit_entity_id:c.input.unitEntityId||null,p_category:c.input.category,p_title:c.input.title,p_description:c.input.description||null,p_priority:c.input.priority||"normal",p_photo_path:c.input.photoPath||null});
   if(error)throw error;const result=(data||{}) as {complaint_id?:string;notification_ids?:string[]};return {id:String(result.complaint_id||""),notificationIds:result.notification_ids||[]};
  }
  case "updateComplaint":{
   const {data,error}=await ctx.supabase.rpc("hs4_update_complaint",{p_complaint_id:c.input.id,p_status:c.input.status||null,p_assigned_to:c.input.assignedTo||null,p_assigned_vendor_id:c.input.assignedVendorId||null,p_sla_due_at:c.input.slaDueAt||null,p_resolution_note:c.input.resolutionNote||null});
   if(error)throw error;return {notificationIds:(data||[]) as string[]};
  }
  case "addComplaintComment":{
   const {data,error}=await ctx.supabase.rpc("hs4_add_complaint_comment",{p_complaint_id:c.input.id,p_body:c.input.body});
   if(error)throw error;const result=(data||{}) as {comment_id?:string;notification_ids?:string[]};return {id:String(result.comment_id||""),notificationIds:result.notification_ids||[]};
  }
  case "upsertVendor":{
   const {data,error}=await ctx.supabase.rpc("hs2_upsert_vendor",{p_id:c.input.id||null,p_name:c.input.name,p_category:c.input.category,p_contact_name:c.input.contactName||null,p_phone:c.input.phone||null,p_email:c.input.email||null,p_status:c.input.status||"active"});
   if(error)throw error;return {id:String(data)};
  }
  case "createVendorContract":{
   const {data,error}=await ctx.supabase.rpc("hs2_create_vendor_contract",{p_vendor_id:c.input.vendorId,p_title:c.input.title,p_starts_on:c.input.startsOn||null,p_ends_on:c.input.endsOn||null,p_sla:c.input.sla||null,p_amount:c.input.amount??null});
   if(error)throw error;return {id:String(data)};
  }
  case "upsertAmenity":{
   const {data,error}=await ctx.supabase.rpc("hs2_upsert_amenity",{p_id:c.input.id||null,p_name:c.input.name,p_description:c.input.description||null,p_location:c.input.location||null,p_capacity:c.input.capacity??null,p_booking_mode:c.input.bookingMode||"approval",p_status:c.input.status||"active"});
   if(error)throw error;return {id:String(data)};
  }
  case "createAmenityBooking":{
   const {data,error}=await ctx.supabase.rpc("hs2_create_amenity_booking",{p_amenity_id:c.input.amenityId,p_unit_entity_id:c.input.unitEntityId||null,p_starts_at:c.input.startsAt,p_ends_at:c.input.endsAt,p_purpose:c.input.purpose||null});
   if(error)throw error;return {id:String(data)};
  }
  case "reviewAmenityBooking":{
   const {error}=await ctx.supabase.rpc("hs2_review_amenity_booking",{p_booking_id:c.input.id,p_status:c.input.status});
   if(error)throw error;return {};
  }
  case "setComplaintRoute":{
   const {error}=await ctx.supabase.rpc("hs4_set_complaint_route",{p_category:c.input.category,p_role_key:c.input.roleKey});
   if(error)throw error;return {};
  }
 }
}
