"use client";

import type {ReactNode} from "react";

export type ResponsiveSectionOption<T extends string=string>={
 id:T;
 label:string;
 description?:string;
 icon?:ReactNode;
 badge?:string|number;
};

export default function ResponsiveSectionTabs<T extends string>({
 options,active,onChange,label="Sections",className="",
}:{
 options:readonly ResponsiveSectionOption<T>[];
 active:T;
 onChange:(id:T)=>void;
 label?:string;
 className?:string;
}){
 if(options.length<=1)return null;
 return <nav className={`responsive-section-tabs ${className}`.trim()} aria-label={label} data-ui-progressive="tabs">
  <div className="responsive-section-tab-buttons" role="tablist" aria-label={label}>
   {options.map(option=><button key={option.id} type="button" role="tab" aria-selected={active===option.id} className={active===option.id?"active":""} onClick={()=>onChange(option.id)}>
    {option.icon}<span>{option.label}</span>{option.badge!==undefined&&<em>{option.badge}</em>}
   </button>)}
  </div>
  <label className="responsive-section-tab-select"><span>{label}</span><select value={active} onChange={event=>onChange(event.target.value as T)}>{options.map(option=><option value={option.id} key={option.id}>{option.label}{option.badge!==undefined?` (${option.badge})`:""}</option>)}</select>{options.find(option=>option.id===active)?.description&&<small>{options.find(option=>option.id===active)?.description}</small>}</label>
 </nav>;
}
