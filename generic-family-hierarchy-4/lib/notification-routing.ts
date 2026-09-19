import type {Notification} from "./types";
import {networkSurfaceHref} from "./network-routes";

export type NotificationDeepLink={networkId?:string;surface?:string;itemId?:string};

export function buildNotificationDeepLink(input:NotificationDeepLink){
 if(input.networkId){
  try{
   const href=networkSurfaceHref(input.networkId,input.surface||"home");
   // A resource ID needs an owner-specific authorized detail route before it enters a URL.
   return href;
  }catch{/* Historical/non-UUID demo identifiers retain the legacy link. */}
 }
 const params=new URLSearchParams();
 if(input.networkId)params.set("twNetwork",input.networkId);
 if(input.surface)params.set("twSurface",input.surface);
 if(input.itemId)params.set("twItem",input.itemId);
 const query=params.toString();
 return query?`/?${query}`:"/";
}

export function readNotificationDeepLink(search?:string):NotificationDeepLink{
 if(typeof window==="undefined"&&!search)return {};
 const params=new URLSearchParams(search??window.location.search);
 return {networkId:params.get("twNetwork")||undefined,surface:params.get("twSurface")||undefined,itemId:params.get("twItem")||undefined};
}

export function clearNotificationDeepLink(){
 if(typeof window==="undefined")return;
 const url=new URL(window.location.href);
 ["twNetwork","twSurface","twItem"].forEach(k=>url.searchParams.delete(k));
 window.history.replaceState({},"",`${url.pathname}${url.search}${url.hash}`);
}

function metadataText(value: unknown): string | undefined {
 if(typeof value === "string") return value.trim() || undefined;
 if(typeof value === "number" || typeof value === "boolean") return String(value);
 return undefined;
}

function inferNotificationSurface(notification: Pick<Notification,"type"|"entity_type"|"metadata">): string | undefined {
 const explicit=metadataText(notification.metadata?.surface);
 if(explicit)return explicit;
 const type=notification.type||"";
 const entity=notification.entity_type||"";
 if(type.startsWith("complaint")||entity==="complaint")return "complaints";
 if(type.startsWith("fund_")||type==="payment_recorded"||type==="collection_due"||entity==="fund"||entity==="collection")return "funds";
 if(type.startsWith("ballot_")||type.startsWith("election")||type.startsWith("poll")||entity==="election"||entity==="ballot"||entity==="poll")return "elections";
 if(type.startsWith("community_post")||type==="community_broadcast"||type==="post_mention"||type==="post_comment"||entity==="post"||entity==="activity")return "community";
 if(type.startsWith("event")||type.startsWith("membership")||type.startsWith("renewal")||entity==="event")return "community";
 return undefined;
}

/**
 * Builds the best available in-app destination for both new and historical
 * notifications. Older rows sometimes persisted only ?twNetwork=... in href;
 * merge that partial href with notification metadata/type so opening the row
 * lands on the relevant surface instead of the network Home screen.
 */
export function resolveNotificationDeepLink(notification: Pick<Notification,"network_id"|"href"|"type"|"entity_type"|"entity_id"|"metadata">): string {
 const stored=notification.href?.trim();
 let networkId=notification.network_id;
 let surface=inferNotificationSurface(notification);
 let itemId=notification.entity_id;

 if(stored){
  try{
   const base=typeof window!=="undefined"?window.location.origin:"https://trustweave.local";
   const url=new URL(stored,base);
   networkId=url.searchParams.get("twNetwork")||networkId;
   surface=url.searchParams.get("twSurface")||surface;
   itemId=url.searchParams.get("twItem")||itemId;
   const hasTrustWeaveParams=url.searchParams.has("twNetwork")||url.searchParams.has("twSurface")||url.searchParams.has("twItem");
   // Preserve genuine application paths, but enrich partial root/query deep links.
   // Only same-origin application paths can be used as an internal destination.
   if(url.origin===base&&url.pathname!=="/"&&!hasTrustWeaveParams)return `${url.pathname}${url.search}${url.hash}`;
  }catch{
   // Fall through to deterministic in-app routing below.
  }
 }
 return buildNotificationDeepLink({networkId,surface,itemId});
}
