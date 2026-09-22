import {getQuery,postCommand} from "../../../lib/api-client";
import type {HousingOperationsCommand,HousingOperationsCommandResult} from "../../../core/api/contracts";
import {fetchEntityMediaAssets,getSignedPhotoUrl} from "../../../lib/storage";
import {requestPushDelivery} from "../../../lib/push";

export type HsNotice={id:string;title:string;body?:string|null;noticeType:string;pinned:boolean;expiresAt?:string|null;createdAt:string;createdBy?:string|null};
export type HsComplaint={id:string;unitEntityId?:string|null;unitLabel?:string|null;category:string;title:string;description?:string|null;attachments?:Array<{kind?:string;path?:string;url?:string}>;photoUrls?:string[];priority:string;status:string;slaDueAt?:string|null;assignedTo?:string|null;assignedToLabel?:string|null;assignedVendorId?:string|null;resolutionNote?:string|null;createdAt:string;updatedAt:string;createdBy?:string|null;comments?:Array<{id:string;body:string;createdAt:string;authorLabel:string}>};
export type HsVendor={id:string;name:string;category:string;contactName?:string|null;phone?:string|null;email?:string|null;status:string;contractCount?:number};
export type HsAmenity={id:string;name:string;description?:string|null;location?:string|null;capacity?:number|null;bookingMode:string;status:string};
export type HsBooking={id:string;amenityId:string;amenityName:string;unitEntityId?:string|null;unitLabel?:string|null;startsAt:string;endsAt:string;status:string;purpose?:string|null;createdBy?:string|null};
export type HsOpsSnapshot={notices:HsNotice[];complaints:HsComplaint[];vendors:HsVendor[];amenities:HsAmenity[];bookings:HsBooking[]};
export type HsComplaintRoute={category_key:string;role_key:string;role_label:string;assignee_count:number};

async function command(input:HousingOperationsCommand){return postCommand<HousingOperationsCommandResult>("/api/v1/housing/operations/command",input,{idempotent:true})}

export async function fetchHsOpsSnapshot(){
 const snap=await getQuery<HsOpsSnapshot>("/api/v1/housing/operations?view=snapshot");
 const media=await fetchEntityMediaAssets("hs_complaint",(snap.complaints||[]).map(c=>c.id)).catch(()=>[]);
 const by=new Map(media.map(x=>[x.entityId,x] as const));
 for(const complaint of snap.complaints||[]){
  const registered=by.get(complaint.id);
  if(registered?.thumbnailUrl||registered?.url){complaint.photoUrls=[registered.thumbnailUrl||registered.url!];continue;}
  const paths=(complaint.attachments||[]).map(a=>a.path||a.url).filter(Boolean) as string[];
  complaint.photoUrls=(await Promise.all(paths.map(p=>getSignedPhotoUrl(p,"community-media")))).filter(Boolean) as string[];
 }
 return snap;
}
export async function createHsNotice(input:{title:string;body?:string;noticeType?:string;pinned?:boolean;expiresAt?:string|null}){return String((await command({action:"createNotice",input})).id||"")}
export async function createHsComplaint(input:{unitEntityId?:string|null;category:string;title:string;description?:string;priority?:string;photoPath?:string}){const result=await command({action:"createComplaint",input});await Promise.all((result.notificationIds||[]).map(id=>requestPushDelivery(id)));return String(result.id||"")}
export async function updateHsComplaint(input:{id:string;status?:string;assignedTo?:string|null;assignedVendorId?:string|null;slaDueAt?:string|null;resolutionNote?:string|null}){const result=await command({action:"updateComplaint",input});await Promise.all((result.notificationIds||[]).map(id=>requestPushDelivery(id)))}
export async function addHsComplaintComment(id:string,body:string){const result=await command({action:"addComplaintComment",input:{id,body}});await Promise.all((result.notificationIds||[]).map(nid=>requestPushDelivery(nid)));return String(result.id||"")}
export async function upsertHsVendor(input:{id?:string;name:string;category:string;contactName?:string;phone?:string;email?:string;status?:string}){return String((await command({action:"upsertVendor",input})).id||"")}
export async function createHsVendorContract(input:{vendorId:string;title:string;startsOn?:string|null;endsOn?:string|null;sla?:string|null;amount?:number|null}){return String((await command({action:"createVendorContract",input})).id||"")}
export async function upsertHsAmenity(input:{id?:string;name:string;description?:string;location?:string;capacity?:number|null;bookingMode?:string;status?:string}){return String((await command({action:"upsertAmenity",input})).id||"")}
export async function createHsAmenityBooking(input:{amenityId:string;unitEntityId?:string|null;startsAt:string;endsAt:string;purpose?:string}){return String((await command({action:"createAmenityBooking",input})).id||"")}
export async function reviewHsAmenityBooking(id:string,status:"approved"|"rejected"|"cancelled"){await command({action:"reviewAmenityBooking",input:{id,status}})}
export async function fetchHsComplaintRoutes(){return getQuery<HsComplaintRoute[]>("/api/v1/housing/operations?view=complaint-routes")}
export async function setHsComplaintRoute(category:string,roleKey:string){await command({action:"setComplaintRoute",input:{category,roleKey}})}
