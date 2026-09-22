"use client";
import {Moon,Palette,Sun} from "lucide-react";
import {useLanguage,type MessageToken} from "../lib/i18n";
import {useTheme,type AppTheme} from "./ThemeProvider";

const OPTIONS:{value:AppTheme;label:MessageToken;icon:typeof Sun}[]=[
 {value:"light",label:"ThemeClassicTxt",icon:Sun},
 {value:"modern",label:"ThemeModernTxt",icon:Palette},
 {value:"dark",label:"ThemeDarkTxt",icon:Moon},
];

export default function ThemeSwitcher({compact=false}:{compact?:boolean}){
 const {t:tr}=useLanguage();
 const {theme,setTheme}=useTheme();
 const current=OPTIONS.find(x=>x.value===theme)||OPTIONS[0];
 const Icon=current.icon;
 return <label className={`theme-select ${compact?"compact":""}`} title={tr("AppearanceTxt")}>
  <Icon size={14}/>
  {!compact&&<span>{tr("AppearanceTxt")}</span>}
  <select data-testid="qa-theme-select" aria-label={tr("AppearanceTxt")} value={theme} onChange={e=>setTheme(e.target.value as AppTheme)}>
   {OPTIONS.map(o=><option key={o.value} value={o.value}>{tr(o.label)}</option>)}
  </select>
 </label>;
}
