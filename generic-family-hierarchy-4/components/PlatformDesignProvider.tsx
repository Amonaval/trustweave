"use client";
import {createContext,useContext,useEffect,useMemo,useState,type ReactNode} from "react";
import {DEFAULT_PLATFORM_DESIGN,fetchPlatformDesign,platformAssetUrl,type PlatformDesignSnapshot} from "../lib/platform-design";

type PlatformDesignContextValue={snapshot:PlatformDesignSnapshot;asset:(slot:string)=>string|undefined;refresh:()=>Promise<void>};
const fallback:PlatformDesignSnapshot={settings:DEFAULT_PLATFORM_DESIGN,assets:[]};
const PlatformDesignContext=createContext<PlatformDesignContextValue>({snapshot:fallback,asset:()=>undefined,refresh:async()=>{}});

export default function PlatformDesignProvider({children}:{children:ReactNode}){
 const [snapshot,setSnapshot]=useState<PlatformDesignSnapshot>(fallback);
 const refresh=async()=>{try{setSnapshot(await fetchPlatformDesign())}catch{setSnapshot(current=>current||fallback)}};
 useEffect(()=>{void refresh();const onRefresh=()=>void refresh();window.addEventListener("trustweave:platform-design",onRefresh);return()=>window.removeEventListener("trustweave:platform-design",onRefresh)},[]);
 useEffect(()=>{const root=document.documentElement,s=snapshot.settings;root.dataset.platformFont=s.font_key;root.dataset.platformLayout=s.layout_key;root.dataset.platformHero=s.hero_key;root.dataset.platformCorner=s.corner_key},[snapshot.settings]);
 const value=useMemo<PlatformDesignContextValue>(()=>({snapshot,asset:(slot:string)=>platformAssetUrl(snapshot,slot),refresh}),[snapshot]);
 return <PlatformDesignContext.Provider value={value}>{children}</PlatformDesignContext.Provider>
}
export function usePlatformDesign(){return useContext(PlatformDesignContext)}
