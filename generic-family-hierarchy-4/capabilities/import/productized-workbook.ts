import {fetchNetworkAffiliatedEntities} from "../affiliation/remote";
import {createNetworkEntityRelationship,fetchNetworkEntityRelationships,upsertNetworkEntity} from "../template-product/remote";
import {assignFcaRole,fetchFcaAdminSnapshot,recordFcaActivationEvidence,setFcaFamilyMembership,upsertFcaMembershipYear} from "../../verticals/family-association/runtime/admin-remote";
import type {ImportCommitResult,ImportReview,ImportSheetSchema,ParsedImportRow} from "../../core/import/contracts";
import {buildActivationEvidencePayload} from "../../core/activation-autopilot/evidence";

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
function fcaPaymentStatus(input:unknown){const status=String(input||"unpaid").trim().toLowerCase();return ["unpaid","paid","waived","partial","not_required"].includes(status)?status:"unpaid"}
function membershipYearStatus(endDate:string){return endDate<new Date().toISOString().slice(0,10)?"closed":"open"}
function membershipYearRank(label:string){const dates=membershipYearDates(label);return dates?Number(dates.startDate.slice(0,4)):-1}

export async function commitProductizedWorkbook(review:ImportReview):Promise<ImportCommitResult>{
 if(!review.canCommit)throw new Error("Resolve import validation errors before committing.");
 let activationEvidenceCount=0;
 if(review.schema.verticalKind==="family-association"){
  const evidence=buildActivationEvidencePayload(review);
  const recorded=await recordFcaActivationEvidence(evidence.source,evidence.records);
  activationEvidenceCount=recorded.insertedEvidence;
 }
const existing=await fetchNetworkAffiliatedEntities();const stableMap=new Map<string,string>();for(const e of existing){const sid=String(e.entity.metadata?.importStableId||"").trim().toLowerCase();if(sid)stableMap.set(`${e.entity.kind}|${sid}`,e.entity.id)}const refMap=new Map<string,string>();let created=0,updated=0,relationships=0,domainRecords=0,skipped=0;
 for(const sheet of review.sheets.filter(s=>s.schema.recordType==="entity")){for(const row of sheet.rows.filter(r=>r.status!=="rejected")){const item=buildEntity(row,sheet.schema,review.schema.version);if(!item.label){skipped++;continue}const existingId=item.stableId?stableMap.get(`${item.kind}|${item.stableId.toLowerCase()}`):undefined;const id=await upsertNetworkEntity({id:existingId,kind:item.kind,label:item.label,metadata:item.metadata,affiliations:item.affiliations});if(existingId)updated++;else created++;if(item.stableId){refMap.set(item.stableId.toLowerCase(),id);stableMap.set(`${item.kind}|${item.stableId.toLowerCase()}`,id)}}}
 const existingRelationships=await fetchNetworkEntityRelationships();const edgeKeys=new Set(existingRelationships.map(r=>`${r.fromEntityId}|${r.toEntityId}|${r.relationshipType}`));for(const sheet of review.sheets.filter(s=>s.schema.recordType==="relationship")){for(const row of sheet.rows.filter(r=>r.status!=="rejected")){const from=refMap.get(String(row.values.from_id||"").toLowerCase())||refMap.get(String(row.values.fromRef||"").toLowerCase());const to=refMap.get(String(row.values.to_id||"").toLowerCase())||refMap.get(String(row.values.toRef||"").toLowerCase());const rel=String(row.values.relationship||row.values.relationship_type||"").trim();if(!from||!to||!rel){skipped++;continue}const key=`${from}|${to}|${rel}`;if(edgeKeys.has(key)){skipped++;continue}await createNetworkEntityRelationship(from,to,rel,{importSchemaVersion:review.schema.version});edgeKeys.add(key);relationships++}}

 if(review.schema.verticalKind==="family-association"){
  const currentRepresentativeByFamily=new Map<string,{personRef:string;membershipYear:string;rank:number}>();
  for(const sheet of review.sheets.filter(s=>s.schema.recordType==="domain"&&s.schema.key==="association_membership")){
   for(const row of sheet.rows.filter(r=>r.status!=="rejected")){
    const familyRef=String(row.values.family_id||"").trim().toLowerCase();
    const personRef=String(row.values.representative_id||"").trim().toLowerCase();
    const membershipYear=String(row.values.membership_year||"").trim();
    if(!familyRef||!personRef||!membershipYear)continue;
    const rank=membershipYearRank(membershipYear),prior=currentRepresentativeByFamily.get(familyRef);
    if(!prior||rank>prior.rank)currentRepresentativeByFamily.set(familyRef,{personRef,membershipYear,rank});
   }
  }
  for(const [familyRef,current] of currentRepresentativeByFamily){
   const familyEntityId=refMap.get(familyRef)||stableMap.get(`family|${familyRef}`);
   const personEntityId=refMap.get(current.personRef)||stableMap.get(`person|${current.personRef}`);
   if(!familyEntityId||!personEntityId)throw new Error(`Current representative for ${familyRef.toUpperCase()} could not be resolved.`);
   const represented=existingRelationships.filter(r=>r.fromEntityId===familyEntityId&&r.relationshipType==="represented_by");
   const conflicting=represented.find(r=>r.toEntityId!==personEntityId);
   if(conflicting)throw new Error(`${conflicting.fromLabel||familyRef} already has a different current representative. Resolve the existing governed relationship before activation.`);
   const key=`${familyEntityId}|${personEntityId}|represented_by`;
   if(!edgeKeys.has(key)){
    await createNetworkEntityRelationship(familyEntityId,personEntityId,"represented_by",{importSchemaVersion:review.schema.version,source:"network-activation-autopilot",membershipYear:current.membershipYear});
    edgeKeys.add(key);relationships++;
   }
  }
 }

 // Family Association annual membership and leadership are governed domain state,
 // not generic entity metadata. Resolve the activation pack against the existing
 // FCA admin contracts so Autopilot never bypasses domain authorization or history.
 if(review.schema.verticalKind==="family-association"){
  const snapshot=await fetchFcaAdminSnapshot();
  const yearIds=new Map<string,string>((snapshot.years||[]).map((year:any)=>[String(year.label||"").trim().toLowerCase(),String(year.id)]));
  const graceDays=Math.max(0,Math.min(90,Number(snapshot.settings?.grace_period_days??30)||30));
  const roleIds=new Map<string,string>();
  for(const role of snapshot.roles||[]){
   const id=String(role.id||"");if(!id)continue;
   const key=String(role.role_key||"").trim().toLowerCase();
   const label=String(role.label||"").trim().toLowerCase();
   if(key)roleIds.set(key,id);if(label)roleIds.set(label,id);
  }
  const ensureYear=async(label:string)=>{
   const key=label.trim().toLowerCase();const existingId=yearIds.get(key);if(existingId)return existingId;
   const dates=membershipYearDates(label);if(!dates)throw new Error(`Membership year “${label}” must use YYYY-YY or YYYY-YYYY before activation.`);
   const id=await upsertFcaMembershipYear({label,startDate:dates.startDate,endDate:dates.endDate,familyFee:0,gracePeriodDays:graceDays,status:membershipYearStatus(dates.endDate)});
   yearIds.set(key,id);return id;
  };

  for(const sheet of review.sheets.filter(s=>s.schema.recordType==="domain"&&s.schema.key==="association_membership")){
   for(const row of sheet.rows.filter(r=>r.status!=="rejected")){
    const familyRef=String(row.values.family_id||"").trim().toLowerCase();
    const familyEntityId=refMap.get(familyRef)||stableMap.get(`family|${familyRef}`);
    const label=String(row.values.membership_year||"").trim();
    if(!familyEntityId||!label){skipped++;continue}
    const representativeRef=String(row.values.representative_id||"").trim().toLowerCase();
    const representativeEntityId=representativeRef?(refMap.get(representativeRef)||stableMap.get(`person|${representativeRef}`)):undefined;
    if(representativeRef&&!representativeEntityId)throw new Error(`Representative “${row.values.representative_id}” could not be resolved for ${row.values.family_id}.`);
    const yearId=await ensureYear(label);
    await setFcaFamilyMembership({
     yearId,
     familyEntityId,
     representativeEntityId:representativeEntityId||null,
     status:fcaMembershipStatus(row.values.status),
     paymentStatus:fcaPaymentStatus(row.values.payment_status),
     amountPaid:Number(row.values.amount_paid||0),
     paymentReference:String(row.values.payment_reference||"").trim()
    });
    domainRecords++;
   }
  }

  const peopleLabelByStable=new Map<string,string>();
  for(const sheet of review.sheets.filter(s=>s.schema.recordType==="entity"&&s.schema.entityKind==="person")){
   for(const row of sheet.rows.filter(r=>r.status!=="rejected")){
    const stable=String(row.values.stable_id||"").trim().toLowerCase();
    const label=String(row.values.name||"").trim();
    if(stable&&label)peopleLabelByStable.set(stable,label);
   }
  }
  const roleLabelById=new Map<string,string>((snapshot.roles||[]).map((role:any)=>[String(role.id),String(role.label||"").trim()]));
  const existingRoleKeys=new Set<string>((snapshot.role_history||[]).map((history:any)=>[
   String(history.year_label||"").trim().toLowerCase(),
   String(history.person_label||"").trim().toLowerCase(),
   String(history.role_label||"").trim().toLowerCase(),
   String(history.starts_on||"").trim(),
   String(history.ends_on||"").trim()
  ].join("|")));
  const activationRoleKeys=new Set<string>();

  for(const sheet of review.sheets.filter(s=>s.schema.recordType==="domain"&&s.schema.key==="leadership_history")){
   for(const row of sheet.rows.filter(r=>r.status!=="rejected")){
    const personRef=String(row.values.person_id||"").trim().toLowerCase();
    const personEntityId=refMap.get(personRef)||stableMap.get(`person|${personRef}`);
    const roleKey=String(row.values.role_key||"").trim().toLowerCase();
    const roleCatalogId=roleIds.get(roleKey);
    const label=String(row.values.membership_year||"").trim();
    if(!personEntityId)throw new Error(`Leadership person “${row.values.person_id}” could not be resolved.`);
    if(!roleCatalogId)throw new Error(`Association role “${row.values.role_key}” is not available in this network.`);
    const yearId=label?await ensureYear(label):null;
    const personLabel=peopleLabelByStable.get(personRef)||String(row.values.person_id||"").trim();
    const roleLabel=roleLabelById.get(roleCatalogId)||roleKey;
    const startsOn=String(row.values.starts_on||"").trim();
    const endsOn=String(row.values.ends_on||"").trim();
    const exactKey=[label.toLowerCase(),personLabel.toLowerCase(),roleLabel.toLowerCase(),startsOn,endsOn].join("|");
    if(existingRoleKeys.has(exactKey)||activationRoleKeys.has(exactKey)){skipped++;continue}
    await assignFcaRole({
     yearId,
     personEntityId,
     roleCatalogId,
     startsOn:startsOn||null,
     endsOn:endsOn||null,
     notes:String(row.values.notes||"").trim()
    });
    activationRoleKeys.add(exactKey);
    domainRecords++;
   }
  }
 }
 return {created,updated,relationships,skipped,message:`Imported ${created} new, updated ${updated}, created ${relationships} relationships${domainRecords?`, persisted ${domainRecords} governed membership/leadership records`:""}${activationEvidenceCount?`, retained ${activationEvidenceCount} source evidence records`:""}${skipped?` and skipped ${skipped} existing/incomplete rows`:""}.`};
}
