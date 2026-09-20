import {getQuery,postCommand} from "../../../lib/api-client";
import type {FamilyAssociationAdminCommand,FamilyAssociationAdminCommandResult} from "../../../core/api/contracts";

export type FcaAdminSnapshot={settings:Record<string,any>;years:any[];memberships:any[];roles:any[];role_history:any[];finance:any[]};
async function command(input:FamilyAssociationAdminCommand){return postCommand<FamilyAssociationAdminCommandResult>("/api/v1/family-association/admin/command",input,{idempotent:true})}
export async function fetchFcaAdminSnapshot(){return getQuery<FcaAdminSnapshot>("/api/v1/family-association/admin")}
export async function updateFcaSettings(input:{dependentAgeLimit:number;gracePeriodDays:number;maxAutoChildren:number;onboardingPolicy:string;financeVisibility:string}){await command({action:"updateSettings",input})}
export async function upsertFcaMembershipYear(input:{id?:string|null;label:string;startDate:string;endDate:string;familyFee:number;gracePeriodDays:number;status:string}){return String((await command({action:"upsertMembershipYear",input})).id||"")}
export async function setFcaFamilyMembership(input:{yearId:string;familyEntityId:string;representativeEntityId?:string|null;status:string;paymentStatus:string;amountPaid:number;paymentReference?:string}){return String((await command({action:"setFamilyMembership",input})).id||"")}
export async function assignFcaRole(input:{yearId?:string|null;personEntityId:string;roleCatalogId:string;startsOn?:string|null;endsOn?:string|null;notes?:string}){return String((await command({action:"assignRole",input})).id||"")}
export async function addFcaFinanceEntry(input:{yearId:string;entryType:string;amount:number;description?:string;visibility:string}){return String((await command({action:"addFinanceEntry",input})).id||"")}
