"use client";
import type {ReactNode} from "react";
import {BadgeIndianRupee,Building2,Database,LayoutDashboard,Settings2,ShieldCheck,UsersRound,Wrench} from "lucide-react";
import {useLanguage,type MessageToken} from "../lib/i18n";
import {NetworkSectionHead} from "./shared/NetworkUi";

export type HousingManageSection="overview"|"people"|"operations"|"finance"|"governance"|"security"|"data";
type SectionDef={id:HousingManageSection;label:MessageToken;icon:typeof LayoutDashboard};
const SECTIONS:SectionDef[]=[
 {id:"overview",label:"HsManageOverviewTxt",icon:LayoutDashboard},
 {id:"people",label:"HsManagePeopleTxt",icon:UsersRound},
 {id:"operations",label:"HsManageOperationsTxt",icon:Wrench},
 {id:"finance",label:"HsManageFinanceTxt",icon:BadgeIndianRupee},
 {id:"governance",label:"HsManageGovernanceTxt",icon:Building2},
 {id:"security",label:"HsManageSecurityTxt",icon:ShieldCheck},
 {id:"data",label:"HsManageDataSettingsTxt",icon:Database},
];

export default function HousingSocietyManageWorkspace({active,onChange,content}:{active:HousingManageSection;onChange:(section:HousingManageSection)=>void;content:Record<HousingManageSection,ReactNode>}){
 const {t}=useLanguage();
 return <div className="hs-manage-workspace" data-testid="qa-hs-manage-workspace">
  <NetworkSectionHead kicker={<><Settings2 size={13}/> {t("HsManageWorkspaceTxt")}</>} title={t("HsManageWorkspaceTxt")} description={t("HsManageWorkspaceDescTxt")}/>
  <div className="hs-manage-tabs" role="tablist" aria-label={t("HsManageWorkspaceTxt")}>
   {SECTIONS.map(({id,label,icon:Icon})=><button key={id} role="tab" aria-selected={active===id} className={active===id?"active":""} onClick={()=>onChange(id)}><Icon size={15}/><span>{t(label)}</span></button>)}
  </div>
  <label className="hs-manage-select"><span>{t("HsManageWorkspaceTxt")}</span><select value={active} onChange={e=>onChange(e.target.value as HousingManageSection)}>{SECTIONS.map(({id,label})=><option key={id} value={id}>{t(label)}</option>)}</select></label>
  <section className="hs-manage-content" role="tabpanel" data-manage-section={active}>{content[active]}</section>
 </div>;
}
