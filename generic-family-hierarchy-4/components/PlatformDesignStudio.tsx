"use client";
import {useEffect,useMemo,useState} from "react";
import {Building2,Image as ImageIcon,Images,Layers3,LoaderCircle,Palette,RefreshCw,Trash2,Upload} from "lucide-react";
import type {NetworkVerticalKind} from "../core/verticals/contracts";
import {getVerticalDefinition} from "../app-shell/vertical-registry";
import {DEFAULT_PLATFORM_DESIGN,PLATFORM_GLOBAL_SLOTS,fetchPlatformDesign,platformAssetUrl,platformPlaygroundSlots,platformVerticalDefaultSlots,removePlatformVisual,savePlatformDesignSettings,uploadPlatformVisual,type PlatformDesignSettings,type PlatformDesignSnapshot,type PlatformVisualSlot} from "../lib/platform-design";

type DesignScope="platform"|"vertical"|"playground"|"network";
const ACTIVE_VERTICALS:NetworkVerticalKind[]=["family","housing-society","family-association","association","alumni","organization","business-trust","franchise","professional"];

export default function PlatformDesignStudio({verticalKind,onVerticalChange,onNotify}:{verticalKind:NetworkVerticalKind;onVerticalChange?:(kind:NetworkVerticalKind)=>void;onNotify:(message:string)=>void}){
 const [scope,setScope]=useState<DesignScope>("platform");
 const [snapshot,setSnapshot]=useState<PlatformDesignSnapshot>({settings:DEFAULT_PLATFORM_DESIGN,assets:[]}),[busy,setBusy]=useState(""),[contractMissing,setContractMissing]=useState(false),[recentSlot,setRecentSlot]=useState("");
 const slots=useMemo(()=>scope==="platform"?PLATFORM_GLOBAL_SLOTS:scope==="vertical"?platformVerticalDefaultSlots(verticalKind):scope==="playground"?platformPlaygroundSlots(verticalKind):[],[scope,verticalKind]);
 const load=async()=>{try{setSnapshot(await fetchPlatformDesign());setContractMissing(false)}catch(e:any){setContractMissing(true);onNotify(e?.message||"Platform design controls need the database contract.")}};
 useEffect(()=>{void load()},[verticalKind]);
 const refreshEverywhere=()=>window.dispatchEvent(new Event("trustweave:platform-design"));
 const saveSettings=async(next:PlatformDesignSettings)=>{setBusy("settings");try{const settings=await savePlatformDesignSettings(next);setSnapshot(x=>({...x,settings}));refreshEverywhere();onNotify("Platform visual style updated.")}catch(e:any){onNotify(e.message||"Could not update platform style.")}finally{setBusy("")}};
 const upload=async(slot:PlatformVisualSlot,file:File)=>{setBusy(slot.key);try{await uploadPlatformVisual(slot.key,file);await load();setRecentSlot(slot.key);refreshEverywhere();onNotify(slot.label+" uploaded. It is listed below under Uploaded assets.")}catch(e:any){onNotify(e.message||"Could not update this visual.")}finally{setBusy("")}};
 const remove=async(slot:PlatformVisualSlot)=>{if(!confirm("Remove "+slot.label+"? The inherited or built-in visual will be used."))return;setBusy(slot.key);try{await removePlatformVisual(slot.key);await load();refreshEverywhere();onNotify(slot.label+" removed.")}catch(e:any){onNotify(e.message||"Could not remove this visual.")}finally{setBusy("")}};
 const setting=<K extends keyof PlatformDesignSettings>(key:K,value:PlatformDesignSettings[K])=>void saveSettings({...snapshot.settings,[key]:value});
 const inherited=(slot:PlatformVisualSlot)=>scope==="playground"?platformAssetUrl(snapshot,slot.key.replace(`playground.${verticalKind}.`,`vertical.${verticalKind}.`)):undefined;
 const managedAssets=useMemo(()=>snapshot.assets.filter(item=>{
  if(scope==="platform")return PLATFORM_GLOBAL_SLOTS.some(slot=>slot.key===item.slot_key);
  if(scope==="vertical")return item.slot_key.startsWith(`vertical.${verticalKind}.`);
  if(scope==="playground")return item.slot_key.startsWith(`playground.${verticalKind}.`);
  return false;
 }),[snapshot.assets,scope,verticalKind]);
 const title=scope==="platform"?"Platform identity":scope==="vertical"?getVerticalDefinition(verticalKind).displayName+" defaults":scope==="playground"?getVerticalDefinition(verticalKind).displayName+" Playground":"Network-specific identity";
 return <div className="platform-design-studio" data-testid="qa-platform-design-studio">
  <section className="card platform-design-intro"><div><span className="warm-kicker"><Palette size={13}/> Founder visual control</span><h2>Platform Design Studio</h2><p>Four deliberate layers: TrustWeave platform identity → vertical defaults → optional Playground overrides → private network-specific identity.</p></div><button className="btn small" disabled={!!busy} onClick={()=>void load()}><RefreshCw size={14}/> Refresh</button></section>
  {contractMissing&&<div className="notice"><b>Design database contract is not active in this environment.</b> Existing product visuals continue to work. Apply the committed Design Studio migrations only when you intentionally enable these controls.</div>}
  <nav className="platform-design-scope-tabs card" aria-label="Design scope">
   <button className={scope==="platform"?"active":""} onClick={()=>setScope("platform")}><Layers3/><span><b>Platform</b><small>TrustWeave brand & global UI</small></span></button>
   <button className={scope==="vertical"?"active":""} onClick={()=>setScope("vertical")}><Palette/><span><b>Vertical defaults</b><small>Default look per product type</small></span></button>
   <button className={scope==="playground"?"active":""} onClick={()=>setScope("playground")}><Images/><span><b>Playground</b><small>Showcase-only overrides</small></span></button>
   <button className={scope==="network"?"active":""} onClick={()=>setScope("network")}><Building2/><span><b>Network</b><small>Family / society / community identity</small></span></button>
  </nav>

  {scope==="platform"&&<section className="card platform-style-controls"><div className="section-title"><div><span className="warm-kicker">Platform-wide system</span><h3>Typography & layout</h3><p className="page-subtitle">These presets affect TrustWeave globally. They are not owned by whichever network or vertical happens to be open.</p></div>{busy==="settings"&&<LoaderCircle className="spin" size={18}/>}</div><div className="platform-style-grid">
   <label><span>Font character</span><select className="select" value={snapshot.settings.font_key} disabled={!!busy||contractMissing} onChange={e=>setting("font_key",e.target.value as PlatformDesignSettings["font_key"])}><option value="humanist">Humanist</option><option value="editorial">Editorial</option><option value="modern">Modern</option><option value="system">System</option></select></label>
   <label><span>Layout density</span><select className="select" value={snapshot.settings.layout_key} disabled={!!busy||contractMissing} onChange={e=>setting("layout_key",e.target.value as PlatformDesignSettings["layout_key"])}><option value="compact">Compact</option><option value="balanced">Balanced</option><option value="spacious">Spacious</option></select></label>
   <label><span>Hero treatment</span><select className="select" value={snapshot.settings.hero_key} disabled={!!busy||contractMissing} onChange={e=>setting("hero_key",e.target.value as PlatformDesignSettings["hero_key"])}><option value="immersive">Immersive</option><option value="split">Split</option><option value="clean">Clean</option></select></label>
   <label><span>Corner style</span><select className="select" value={snapshot.settings.corner_key} disabled={!!busy||contractMissing} onChange={e=>setting("corner_key",e.target.value as PlatformDesignSettings["corner_key"])}><option value="soft">Soft</option><option value="rounded">Rounded</option><option value="square">Square</option></select></label>
  </div></section>}

  {(scope==="vertical"||scope==="playground")&&<section className="card platform-design-vertical-picker"><div><span className="warm-kicker">{scope==="vertical"?"Default product identity":"Showcase override"}</span><h3>{title}</h3><p>{scope==="vertical"?"These images become the default for every network of this type unless that network supplies its own identity.":"Playground only. Empty slots automatically inherit the vertical default, so you do not need to maintain two copies."}</p></div><select className="select" value={verticalKind} onChange={e=>onVerticalChange?.(e.target.value as NetworkVerticalKind)}>{ACTIVE_VERTICALS.map(kind=><option value={kind} key={kind}>{getVerticalDefinition(kind).displayName}</option>)}</select></section>}

  {(scope==="platform"||scope==="vertical"||scope==="playground")&&<section className="platform-visual-groups">
   <div className="platform-visual-heading"><div><span className="warm-kicker">Managed media</span><h3>{title}</h3><p>{scope==="platform"?"Global product-level images.":scope==="vertical"?"Default images plus up to four product-story / infographic visuals.":"Optional overrides used only when demonstrating this vertical in Playground."}</p></div></div>
   <div className="platform-visual-grid">{slots.map(slot=>{const direct=platformAssetUrl(snapshot,slot.key),fallback=inherited(slot),url=direct||fallback,isBusy=busy===slot.key;return <article className="card platform-visual-card" key={slot.key}><div className="platform-visual-preview">{url?<img src={url} alt=""/>:<span><ImageIcon/><small>{slot.aspect}</small></span>}{!direct&&fallback&&<em>Inherited default</em>}</div><div className="platform-visual-copy"><b>{slot.label}</b><small>{slot.description}</small><code>{slot.key}</code></div><div className="card-actions"><label className="btn small"><Upload size={13}/>{isBusy?"Updating…":direct?"Replace":fallback?"Override":"Upload"}<input type="file" accept="image/jpeg,image/png,image/webp" disabled={!!busy||contractMissing} onChange={e=>{const file=e.target.files?.[0];if(file)void upload(slot,file);e.currentTarget.value=""}}/></label>{direct&&<button className="btn small danger-text" disabled={!!busy||contractMissing} onClick={()=>void remove(slot)}><Trash2 size={13}/> Remove</button>}</div></article>})}</div>
  </section>}
  {(scope==="platform"||scope==="vertical"||scope==="playground")&&<section className="card platform-uploaded-assets">
   <div className="platform-visual-heading"><div><span className="warm-kicker">Uploaded assets</span><h3>What is stored in this scope</h3><p>Every direct upload is listed here by its managed slot. Replacing a slot replaces the old object; inherited defaults are not duplicated.</p></div><span className="entity-kind-pill">{managedAssets.length} stored</span></div>
   {managedAssets.length===0?<p className="page-subtitle">No direct uploads in this scope yet.</p>:<div className="platform-visual-grid">{managedAssets.map(item=><article className={`platform-visual-card ${recentSlot===item.slot_key?"recent":""}`} key={item.slot_key}><div className="platform-visual-preview">{item.url?<img src={item.url} alt=""/>:<span><ImageIcon/></span>}</div><div className="platform-visual-copy"><b>{item.slot_key}</b><small>{item.updated_at?`Updated ${new Date(item.updated_at).toLocaleString()}`:"Managed platform asset"}</small><code>{item.object_path}</code></div></article>)}</div>}
  </section>}

  {scope==="network"&&<section className="card platform-network-design-boundary"><div><span className="warm-kicker"><Building2 size={13}/> Private network layer</span><h3>Every real network can be visually its own</h3><p>A Family, MPF chapter, housing society or alumni network can override the vertical default with its own cover and media. Those assets stay in the existing network-scoped private media pipeline rather than the public platform asset registry. After a network cover upload, TrustWeave opens that network’s Media & Storage library so the admin can see exactly what was stored.</p></div><div className="design-precedence"><b>Visual precedence</b><span>Network cover / network media</span><i>→</i><span>Vertical default</span><i>→</i><span>Built-in fallback</span></div><div className="notice"><b>Why this is separate:</b> founder-controlled platform imagery is intentionally public-safe; network imagery can contain tenant-specific identity and remains governed by that network's owner/admin and membership rules.</div></section>}
 </div>
}
