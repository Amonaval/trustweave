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
 {key:"brand.logo",label:"Platform logo",description:"Wide TrustWeave logo for platform-level entry and exploration surfaces.",aspect:"3:1"},
 {key:"brand.mark",label:"Platform mark / icon",description:"Square TrustWeave mark for compact platform identity surfaces.",aspect:"1:1"},
 {key:"landing.background",label:"Landing background",description:"Full-page background behind the public product front door.",aspect:"16:9"},
 {key:"landing.hero",label:"Landing hero",description:"High-level platform visual used by product discovery.",aspect:"16:9"},
 {key:"platform.guide.banner",label:"Explore & Guide banner",description:"Platform-level visual for the public Product / Guide experience.",aspect:"16:9"},
];

export function platformVerticalDefaultSlots(kind:NetworkVerticalKind):PlatformVisualSlot[]{return[
 {key:`vertical.${kind}.banner`,label:"Default banner",description:"Default hero/banner for this vertical. Real networks can override it with their own cover.",aspect:"16:9"},
 {key:`vertical.${kind}.thumbnail`,label:"Default product thumbnail",description:"Default discovery image for this vertical across the product gallery.",aspect:"4:3"},
 {key:`vertical.${kind}.event`,label:"Default event visual",description:"Fallback event image when a showcase or network event has no image.",aspect:"16:9"},
 {key:`vertical.${kind}.icon`,label:"Vertical logo / mark",description:"Default square visual identity for this vertical.",aspect:"1:1"},
 {key:`vertical.${kind}.story.1`,label:"Story image 1",description:"Primary visual story / infographic for explaining this vertical.",aspect:"16:9"},
 {key:`vertical.${kind}.story.2`,label:"Story image 2",description:"Second product story image. Useful for deeper Family or vertical explanation.",aspect:"16:9"},
 {key:`vertical.${kind}.story.3`,label:"Story image 3",description:"Third product story image.",aspect:"16:9"},
 {key:`vertical.${kind}.story.4`,label:"Story image 4",description:"Fourth product story image.",aspect:"16:9"},
]}

export function platformPlaygroundSlots(kind:NetworkVerticalKind):PlatformVisualSlot[]{return[
 {key:`playground.${kind}.banner`,label:"Playground banner override",description:"Optional showcase-only hero. If empty, the vertical default banner is used.",aspect:"16:9"},
 {key:`playground.${kind}.thumbnail`,label:"Playground thumbnail override",description:"Optional showcase-only discovery image. If empty, the vertical default thumbnail is used.",aspect:"4:3"},
 {key:`playground.${kind}.event`,label:"Playground event override",description:"Optional showcase event visual. If empty, the vertical default event image is used.",aspect:"16:9"},
 {key:`playground.${kind}.icon`,label:"Playground mark override",description:"Optional showcase mark. If empty, the vertical default mark is used.",aspect:"1:1"},
]}

/** Compatibility alias for older callers. */
export const platformVerticalSlots=platformPlaygroundSlots;

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
export function platformAssetUrlAny(snapshot:PlatformDesignSnapshot|undefined|null,slots:readonly string[]){for(const slot of slots){const url=platformAssetUrl(snapshot,slot);if(url)return url}return undefined}
export function verticalDefaultAssetKey(kind:NetworkVerticalKind,part:"banner"|"thumbnail"|"event"|"icon"){return `vertical.${kind}.${part}`}
export function playgroundAssetKey(kind:NetworkVerticalKind,part:"banner"|"thumbnail"|"event"|"icon"){return `playground.${kind}.${part}`}
