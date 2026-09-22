import {NextResponse} from "next/server";
import {createClient} from "@supabase/supabase-js";
import webpush from "web-push";
import {createRequestContext} from "../../../../server/shared/request-context";
export const runtime="nodejs";export const dynamic="force-dynamic";

type Category="posts"|"mentions"|"complaints"|"funds"|"elections"|"events_membership"|"general";
function categoryFor(type:string,metadata?:any):Category{const meta=String(metadata?.category||"") as Category;if(["posts","mentions","complaints","funds","elections","events_membership","general"].includes(meta))return meta;if(type==="mention"||type==="role_mention")return"mentions";if(type.startsWith("complaint"))return"complaints";if(type.startsWith("fund_")||type==="payment_recorded"||type==="collection_due")return"funds";if(type.startsWith("ballot_")||type.startsWith("election")||type.startsWith("poll"))return"elections";if(type.startsWith("community_post")||type==="community_broadcast"||type==="post_mention"||type==="post_comment")return"posts";if(type.startsWith("event")||type.startsWith("membership")||type.startsWith("renewal"))return"events_membership";return"general"}
function localMinutes(timeZone:string){try{const parts=new Intl.DateTimeFormat("en-GB",{timeZone,hour:"2-digit",minute:"2-digit",hourCycle:"h23"}).formatToParts(new Date());return Number(parts.find(p=>p.type==="hour")?.value||0)*60+Number(parts.find(p=>p.type==="minute")?.value||0)}catch{return null}}
function parseMinutes(value:string|null|undefined){if(!value)return null;const [h,m]=String(value).split(":").map(Number);return Number.isFinite(h)&&Number.isFinite(m)?h*60+m:null}
function inQuietHours(start:string|null|undefined,end:string|null|undefined,timeZone:string){const now=localMinutes(timeZone),s=parseMinutes(start),e=parseMinutes(end);if(now===null||s===null||e===null||s===e)return false;return s<e?now>=s&&now<e:now>=s||now<e}

export async function POST(request:Request){
 try{
  const ctx=await createRequestContext(request);const body=await request.json() as {notificationId?:string};if(!body.notificationId)return NextResponse.json({ok:false,error:"notificationId required"},{status:400});
  const url=process.env.NEXT_PUBLIC_SUPABASE_URL?.trim(),service=process.env.SUPABASE_SERVICE_ROLE_KEY?.trim();if(!url||!service)return NextResponse.json({ok:false,error:"Push server is not configured."},{status:503});
  const admin=createClient(url,service,{auth:{persistSession:false,autoRefreshToken:false}});
  const {data:n,error}=await admin.from("notifications").select("id,user_id,network_id,actor_id,type,title,body,href,priority,metadata").eq("id",body.notificationId).maybeSingle();if(error||!n)return NextResponse.json({ok:false,error:"Notification not found."},{status:404});
  const {data:owner}=await admin.from("platform_owners").select("user_id").eq("user_id",ctx.user.id).maybeSingle();if(n.actor_id!==ctx.user.id&&!owner)return NextResponse.json({ok:false,error:"Not authorized."},{status:403});
  const category=categoryFor(String(n.type||""),n.metadata);let pref:any=null;if(n.network_id){const result=await admin.from("notification_preferences").select("push_enabled,quiet_start,quiet_end,timezone,urgent_bypass_quiet,engagement_categories").eq("network_id",n.network_id).eq("user_id",n.user_id).maybeSingle();pref=result.data}
  if(pref&&pref.push_enabled===false)return NextResponse.json({ok:true,delivered:0,expired:0,suppressed:"push_disabled"});
  if(pref?.engagement_categories?.[category]?.push===false&&n.priority!=="urgent")return NextResponse.json({ok:true,delivered:0,expired:0,suppressed:"category_muted"});
  const urgent=n.priority==="urgent";if(pref&&inQuietHours(pref.quiet_start,pref.quiet_end,pref.timezone||"Asia/Kolkata")&&!(urgent&&pref.urgent_bypass_quiet!==false))return NextResponse.json({ok:true,delivered:0,expired:0,suppressed:"quiet_hours"});
  const publicKey=process.env.NEXT_PUBLIC_WEB_PUSH_VAPID_PUBLIC_KEY?.trim(),privateKey=process.env.WEB_PUSH_VAPID_PRIVATE_KEY?.trim(),subject=process.env.WEB_PUSH_VAPID_SUBJECT?.trim()||"mailto:admin@example.com";if(!publicKey||!privateKey)return NextResponse.json({ok:false,error:"VAPID keys are not configured."},{status:503});
  webpush.setVapidDetails(subject,publicKey,privateKey);const {data:subs}=await admin.from("push_subscriptions").select("id,endpoint,p256dh,auth_key").eq("user_id",n.user_id).eq("active",true);let delivered=0,expired=0;
  for(const sub of subs||[]){try{await webpush.sendNotification({endpoint:sub.endpoint,keys:{p256dh:sub.p256dh,auth:sub.auth_key}},JSON.stringify({notificationId:n.id,title:n.title,body:n.body||"",url:n.href||"/",renotify:urgent}));delivered++}catch(e:any){if(e?.statusCode===404||e?.statusCode===410){expired++;await admin.from("push_subscriptions").update({active:false,updated_at:new Date().toISOString()}).eq("id",sub.id)}}}
  return NextResponse.json({ok:true,delivered,expired,category});
 }catch(e:any){return NextResponse.json({ok:false,error:e?.message||"Push delivery failed."},{status:500})}
}
