"use client";
import {createContext,useContext,useEffect,useMemo,useState,type ReactNode} from "react";

export type AppTheme="light"|"modern"|"dark";
type ThemeContextValue={theme:AppTheme;setTheme:(theme:AppTheme)=>void};
const ThemeContext=createContext<ThemeContextValue|undefined>(undefined);
const STORAGE_KEY="network-os-theme";
const THEMES:AppTheme[]=["light","modern","dark"];

function normalizeTheme(value:string|null):AppTheme{
 if(value==="warm")return "light";
 if(value==="aurora")return "modern";
 return value&&THEMES.includes(value as AppTheme)?value as AppTheme:"light";
}
function applyTheme(theme:AppTheme){
 if(typeof document==="undefined")return;
 document.documentElement.dataset.theme=theme;
 document.documentElement.style.colorScheme=theme==="dark"?"dark":"light";
}

export function ThemeProvider({children}:{children:ReactNode}){
 const [theme,setThemeState]=useState<AppTheme>("light");
 useEffect(()=>{
  const stored=typeof window!=="undefined"?window.localStorage.getItem(STORAGE_KEY):null;
  const initial=normalizeTheme(stored);
  setThemeState(initial);applyTheme(initial);
  if(stored!==initial){try{window.localStorage.setItem(STORAGE_KEY,initial)}catch{}}
 },[]);
 const setTheme=(next:AppTheme)=>{setThemeState(next);applyTheme(next);try{if(typeof window!=="undefined")window.localStorage.setItem(STORAGE_KEY,next)}catch{}};
 const value=useMemo(()=>({theme,setTheme}),[theme]);
 return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme(){
 const ctx=useContext(ThemeContext);
 if(!ctx)throw new Error("useTheme must be used within ThemeProvider");
 return ctx;
}
