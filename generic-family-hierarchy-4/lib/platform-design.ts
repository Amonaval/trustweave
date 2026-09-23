import {supabase} from "./supabase";
import {prepareFamilyImage} from "./storage";
import type {NetworkVerticalKind} from "../core/verticals/contracts";

export type PlatformFontKey="humanist"|"editorial"|"modern"|"system";
export type PlatformLayoutKey="compact"|"balanced"|"spacious";
export type PlatformHeroKey="immersive"|"split"|"clean";
export type PlatformCornerKey="soft"|"rounded"|"square";
export type PlatformDesignSettings={font_key:PlatformFontKey;layout_key:PlatformLayoutKey;hero_key:PlatformHeroKey;corner_key:PlatformCornerKey};
export type PlatformVisualAsset={slot_key:string;object_path:string;thumbnail_path?:string|null;url?:string|null;updated_at?:string|null};
export type PlatformDesignSnapshot={settings:PlatformDesignSettings;assets:PlatformVisualAsset[]};
export type PlatformVisualSlot={key:string;label:string;description:string;aspect:string};

export const DEFAULT_PLATFORM_DESIGN:PlatformDesignSettings={font_key:"humanist",layout_key:"balanced",hero_key:"immersive",corner_key:"rounded"};
export const PLATFORM_GLOBAL_SLOTS:PlatformVisualSlot[]=[
 {key:"brand.logo",label:"Platform logo",description:"Wide logo used in the landing header when available.",aspect:"3:1"},
 {key:"brand.mark",label:"Platform mark / icon",description:"Square brand mark used in compact identity surfaces.",aspect:"1:1"},
 {key:"landing.background",label:"Landing background",description:"Full-page entry background behind network selection and Playground discovery.",aspect:"16:9"},
 {key:"landing.hero",label:"Landing hero",description:"High-level platform visual for prominent discovery surfaces.",aspect:"16:9"},
 {key:"platform.guide.banner",label:"Guide banner",description:"Reusable high-level visual for product exploration and guide surfaces.",aspect:"16:9"},
];
export function platformVerticalSlots(kind:NetworkVerticalKind):PlatformVisualSlot[]{return[
 {key:`playground.${kind}.banner`,label:"Playground banner",description:"Hero/background image inside this vertical's Playground.",aspect:"16:9"},
 {key:`playground.${kind}.thumbnail`,label:"Playground thumbnail",description:"Discovery-card image shown before a visitor opens this Playground.",aspect:"4:3"},
 {key:`playground.${kind}.event`,label:"Playground event image",description:"Fallback visual for the featured/sample event when sample data has no photo.",aspect:"16:9"},
 {key:`playground.${kind}.icon`,label:"Playground icon",description:"Optional square visual mark for this vertical.",aspect:"1:1"},
]}

function required(){if(!supabase)throw new Error("Shared Supabase mode is required for platform design.");return supabase}
function normalizeSettings(value:any):PlatformDesignSettings{return{
 font_key:["humanist","editorial","modern","system"].includes(value?.font_key)?value.font_key:DEFAULT_PLATFORM_DESIGN.font_key,
 layout_key:["compact","balanced","spacious"].includes(value?.layout_key)?value.layout_key:DEFAULT_PLATFORM_DESIGN.layout_key,
 hero_key:["immersive","split","clean"].includes(value?.hero_key)?value.hero_key:DEFAULT_PLATFORM_DESIGN.hero_key,
 corner_key:["soft","rounded","square"].includes(value?.corner_key)?value.corner_key:DEFAULT_PLATFORM_DESIGN.corner_key,
}}
export async function fetchPlatformDesign():Promise<PlatformDesignSnapshot>{
 const s=required();const {data,error}=await s.rpc("get_platform_design");if(error)throw error;
 const d=(data||{}) as any,rows=(d.assets||[]) as any[];
 const paths=rows.map(r=>String(r.object_path||"")).filter(Boolean);
 let urls:(string|null)[]=[];
 if(paths.length){const signed=await s.storage.from("community-media").createSignedUrls(paths,86400);urls=(signed.data||[]).map(x=>x?.signedUrl||null)}
 let cursor=0;
 const assets=rows.map(r=>{const has=!!r.object_path;const url=has?(urls[cursor++]||null):null;return{slot_key:String(r.slot_key),object_path:String(r.object_path||""),thumbnail_path:r.thumbnail_path||null,url,updated_at:r.updated_at||null}});
 return {settings:normalizeSettings(d.settings),assets};
}
export async function savePlatformDesignSettings(settings:PlatformDesignSettings){
 const s=required();const {data,error}=await s.rpc("set_platform_design_settings",{p_settings:settings});if(error)throw error;return normalizeSettings(data);
}
export async function uploadPlatformVisual(slotKey:string,file:File){
 const s=required();const {data:{user}}=await s.auth.getUser();if(!user)throw new Error("Sign in as a platform owner before changing platform visuals.");
 const prepared=await prepareFamilyImage(file,320*1024);
 const safe=slotKey.replace(/[^a-z0-9._-]+/gi,"-").toLowerCase(),path=`platform/${user.id}/${safe}/${crypto.randomUUID()}.webp`;
 const bucket=s.storage.from("community-media");const uploaded=await bucket.upload(path,prepared,{cacheControl:"86400",upsert:false,contentType:"image/webp"});if(uploaded.error)throw uploaded.error;
 try{
  const {data,error}=await s.rpc("set_platform_visual_asset",{p_slot_key:slotKey,p_object_path:path,p_thumbnail_path:null,p_mime_type:"image/webp",p_bytes:prepared.size,p_thumbnail_bytes:0,p_width:null,p_height:null});
  if(error)throw error;const previous=data as any;const old=[previous?.previous_object_path,previous?.previous_thumbnail_path].filter((x:any)=>x&&x!==path);if(old.length)void bucket.remove(old).catch(()=>{});
 }catch(error){void bucket.remove([path]).catch(()=>{});throw error}
}
export async function removePlatformVisual(slotKey:string){
 const s=required();const {data,error}=await s.rpc("remove_platform_visual_asset",{p_slot_key:slotKey});if(error)throw error;const d=data as any,paths=[d?.object_path,d?.thumbnail_path].filter(Boolean);if(paths.length){const removed=await s.storage.from("community-media").remove(paths);if(removed.error)throw removed.error}
}
export function platformAssetUrl(snapshot:PlatformDesignSnapshot|undefined|null,slot:string){return snapshot?.assets.find(a=>a.slot_key===slot)?.url||undefined}
