import {fetchNetworkAffiliatedEntities} from "../affiliation/remote";
import {createNetworkEntityRelationship,fetchFcaAdminSnapshot,fetchNetworkEntityRelationships,setFcaFamilyMembership,upsertFcaMembershipYear,upsertNetworkEntity} from "../template-product/remote";
import type {ImportCommitResult,ImportReview,ImportSheetSchema,ParsedImportRow} from "../../core/import/contracts";

function value(row:ParsedImportRow,key:string){return row.values[key]}
function buildEntity(row:ParsedImportRow,sheet:ImportSheetSchema,schemaVersion:string){const metadata:Record<string,unknown>={},affiliations:Record<string,string|string[]>={};let label="",stableId="";for(const col of sheet.columns){const v=value(row,col.key);if(v===""||v==null)continue;if(col.target==="label")label=String(v);else if(col.target==="stableId")stableId=String(v);else if(col.target.startsWith("metadata."))metadata[col.target.slice(9)]=v;else if(col.target.startsWith("affiliation."))affiliations[col.target.slice(12)]=String(v)}if(stableId)metadata.importStableId=stableId;metadata.importSchemaVersion=schemaVersion;return {kind:sheet.entityKind||"custom",label,stableId,metadata,affiliations}}

function membershipYearDates(label:string){
 const clean=label.trim();
 const match=clean.match(/^(\d{4})\s*[-/]\s*(\d{2}|\d{4})$/);
 if(!match)return null;
 const startYear=Number(match[1]);
 let endYear=Number(match[2]);
 if(endYear<100)endYear=Math.floor(startYear/100)*100+endYear;
 if(endYear<startYear)endYear+=100;
 if(endYear!==startYear+1)return null;
 return {startDate:`${startYear}-04-01`,endDate:`${endYear}-03-31`};
}
function fcaMembershipStatus(input:unknown){const status=String(input||"active").trim().toLowerCase();if(status==="grace")return "grace";if(status==="inactive"||status==="expired")return "inactive";return "active"}
function membershipYearStatus(endDate:string){return endDate<new Date().toISOString().slice(0,10)?"closed":"open"}

export async function commitProductizedWorkbook(review:ImportReview):Promise<ImportCommitResult>{
 if(!review.canCommit)throw new Error("Resolve import validation errors before committing.");const existing=await fetchNetworkAffiliatedEntities();const stableMap=new Map<string,string>();for(const e of existing){const sid=String(e.entity.metadata?.importStableId||"").trim().toLowerCase();if(sid)stableMap.set(`${e.entity.kind}|${sid}`,e.entity.id)}const refMap=new Map<string,string>();let created=0,updated=0,relationships=0,domainRecords=0,skipped=0;
 for(const sheet of review.sheets.filter(s=>s.schema.recordType==="entity")){for(const row of sheet.rows.filter(r=>r.status!=="rejected")){const item=buildEntity(row,sheet.schema,review.schema.version);if(!item.label){skipped++;continue}const existingId=item.stableId?stableMap.get(`${item.kind}|${item.stableId.toLowerCase()}`):undefined;const id=await upsertNetworkEntity({id:existingId,kind:item.kind,label:item.label,metadata:item.metadata,affiliations:item.affiliations});if(existingId)updated++;else created++;if(item.stableId){refMap.set(item.stableId.toLowerCase(),id);stableMap.set(`${item.kind}|${item.stableId.toLowerCase()}`,id)}}}
 const existingRelationships=await fetchNetworkEntityRelationships();const edgeKeys=new Set(existingRelationships.map(r=>`${r.fromEntityId}|${r.toEntityId}|${r.relationshipType}`));for(const sheet of review.sheets.filter(s=>s.schema.recordType==="relationship")){for(const row of sheet.rows.filter(r=>r.status!=="rejected")){const from=refMap.get(String(row.values.from_id||"").toLowerCase())||refMap.get(String(row.values.fromRef||"").toLowerCase());const to=refMap.get(String(row.values.to_id||"").toLowerCase())||refMap.get(String(row.values.toRef||"").toLowerCase());const rel=String(row.values.relationship||row.values.relationship_type||"").trim();if(!from||!to||!rel){skipped++;continue}const key=`${from}|${to}|${rel}`;if(edgeKeys.has(key)){skipped++;continue}await createNetworkEntityRelationship(from,to,rel,{importSchemaVersion:review.schema.version});edgeKeys.add(key);relationships++}}

 // Family Association annual membership is governed domain state, not entity metadata.
 // Commit it through the existing FCA membership RPCs after families are resolved so
 // the guided workbook is genuinely persisted and rerun-safe instead of silently ignored.
 if(review.schema.verticalKind==="family-association"){
  const domainSheets=review.sheets.filter(s=>s.schema.recordType==="domain"&&s.schema.key==="association_membership");
  if(domainSheets.length){
   const snapshot=await fetchFcaAdminSnapshot();
   const yearIds=new Map<string,string>((snapshot.years||[]).map((year:any)=>[String(year.label||"").trim().toLowerCase(),String(year.id)]));
   const graceDays=Math.max(0,Math.min(90,Number(snapshot.settings?.grace_period_days??30)||30));
   for(const sheet of domainSheets){for(const row of sheet.rows.filter(r=>r.status!=="rejected")){
    const familyRef=String(row.values.family_id||"").trim().toLowerCase();
    const familyEntityId=refMap.get(familyRef)||stableMap.get(`family|${familyRef}`);
    const label=String(row.values.membership_year||"").trim();
    const dates=membershipYearDates(label);
    if(!familyEntityId||!label||!dates){skipped++;continue}
    const yearKey=label.toLowerCase();let yearId=yearIds.get(yearKey);
    if(!yearId){yearId=await upsertFcaMembershipYear({label,startDate:dates.startDate,endDate:dates.endDate,familyFee:0,gracePeriodDays:graceDays,status:membershipYearStatus(dates.endDate)});yearIds.set(yearKey,yearId)}
    await setFcaFamilyMembership({yearId,familyEntityId,status:fcaMembershipStatus(row.values.status),paymentStatus:"unpaid",amountPaid:0});
    domainRecords++;
   }}
  }
 }
 return {created,updated,relationships,skipped,message:`Imported ${created} new, updated ${updated}, created ${relationships} relationships${domainRecords?`, persisted ${domainRecords} governed membership records`:""}${skipped?` and skipped ${skipped} existing/incomplete rows`:""}.`};
}
