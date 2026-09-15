"use client";

export type HousingSectionTab={id:string;label:string};

export default function HousingSectionTabs({value,onChange,options,label="Section"}:{value:string;onChange:(value:string)=>void;options:HousingSectionTab[];label?:string}){
 return <div className="hs-section-tabs" data-testid="qa-hs-section-tabs">
  <div className="hs-section-tab-buttons" role="tablist" aria-label={label}>
   {options.map(option=><button key={option.id} type="button" role="tab" aria-selected={value===option.id} className={value===option.id?"active":""} onClick={()=>onChange(option.id)}>{option.label}</button>)}
  </div>
  <label className="hs-section-tab-select"><span>{label}</span><select value={value} onChange={e=>onChange(e.target.value)}>{options.map(option=><option key={option.id} value={option.id}>{option.label}</option>)}</select></label>
 </div>;
}
