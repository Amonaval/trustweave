import type {ImportReview,ParsedImportRow,ParsedImportSheet} from "../import/contracts";
import type {ActivationSourceRef} from "./compiler";

export type ActivationInsightSeverity="positive"|"attention"|"context";
export type ActivationInstitutionalInsight={
 id:string;
 severity:ActivationInsightSeverity;
 title:string;
 summary:string;
 evidence:ActivationSourceRef[];
};

export type ActivationInstitutionalAnswer={
 question:string;
 answer:string;
 evidence:ActivationSourceRef[];
};

export type ActivationInstitutionalReport={
 version:"network-activation-intelligence.v1";
 headline:string;
 summary:{
  families:number;
  people:number;
  householdLinks:number;
  membershipYears:number;
  membershipRecords:number;
  leadershipAssignments:number;
  latestMembershipYear:string|null;
 };
 insights:ActivationInstitutionalInsight[];
 answers:ActivationInstitutionalAnswer[];
};

const clean=(value:unknown)=>String(value??"").trim();
const norm=(value:unknown)=>clean(value).toLowerCase();

function source(review:ImportReview,sheet:ParsedImportSheet,row:ParsedImportRow):ActivationSourceRef{
 return {
  fileName:review.fileName,
  schemaVersion:review.schema.version,
  sheetKey:sheet.schema.key,
  sheetName:sheet.schema.name,
  rowNumber:row.rowNumber
 };
}

function sheet(review:ImportReview,key:string){
 return review.sheets.find(item=>item.schema.key===key);
}

function usableRows(target?:ParsedImportSheet){
 return target?.rows.filter(row=>row.status!=="rejected")||[];
}

function yearStart(label:string){
 const match=label.trim().match(/^(\d{4})\s*[-/–—]\s*(\d{2}|\d{4})$/);
 return match?Number(match[1]):Number.NEGATIVE_INFINITY;
}

function latestYear(rows:ParsedImportRow[]){
 const labels=[...new Set(rows.map(row=>clean(row.values.membership_year)).filter(Boolean))];
 return labels.sort((a,b)=>yearStart(b)-yearStart(a)||b.localeCompare(a))[0]||null;
}

function stableIds(target?:ParsedImportSheet){
 const ids=new Set<string>();
 for(const row of usableRows(target)){
  const value=clean(row.values.stable_id).toLowerCase();
  if(value)ids.add(value);
 }
 return ids;
}

export function buildActivationInstitutionalReport(review:ImportReview):ActivationInstitutionalReport{
 const familiesSheet=sheet(review,"families");
 const peopleSheet=sheet(review,"people");
 const householdSheet=sheet(review,"household_membership");
 const membershipSheet=sheet(review,"association_membership");
 const leadershipSheet=sheet(review,"leadership_history");

 const families=usableRows(familiesSheet);
 const people=usableRows(peopleSheet);
 const household=usableRows(householdSheet);
 const memberships=usableRows(membershipSheet);
 const leadership=usableRows(leadershipSheet);
 const latestMembershipYear=latestYear([...memberships,...leadership]);

 const familyIds=stableIds(familiesSheet);
 const personIds=stableIds(peopleSheet);
 const linkedPeople=new Set(household.map(row=>norm(row.values.from_id||row.values.fromRef)).filter(Boolean));
 const linkedFamilies=new Set(household.map(row=>norm(row.values.to_id||row.values.toRef)).filter(Boolean));
 const latestMemberships=latestMembershipYear
  ? memberships.filter(row=>clean(row.values.membership_year)===latestMembershipYear)
  : [];
 const latestMembershipFamilies=new Set(latestMemberships.map(row=>norm(row.values.family_id)).filter(Boolean));
 const latestRepresentativeFamilies=new Set(
  latestMemberships
   .filter(row=>clean(row.values.representative_id))
   .map(row=>norm(row.values.family_id))
   .filter(Boolean)
 );

 const membershipYears=[...new Set(memberships.map(row=>clean(row.values.membership_year)).filter(Boolean))];
 const insights:ActivationInstitutionalInsight[]=[];

 const unlinkedPeople=[...personIds].filter(id=>!linkedPeople.has(id));
 if(unlinkedPeople.length){
  const evidence=people
   .filter(row=>unlinkedPeople.includes(norm(row.values.stable_id)))
   .slice(0,8)
   .map(row=>source(review,peopleSheet!,row));
  insights.push({
   id:"people-without-household",
   severity:"attention",
   title:`${unlinkedPeople.length} ${unlinkedPeople.length===1?"person is":"people are"} not linked to a household`,
   summary:"These people exist in the source pack but have no household membership row, so their family context would otherwise remain incomplete.",
   evidence
  });
 }

 const unlinkedFamilies=[...familyIds].filter(id=>!linkedFamilies.has(id));
 if(unlinkedFamilies.length){
  const evidence=families
   .filter(row=>unlinkedFamilies.includes(norm(row.values.stable_id)))
   .slice(0,8)
   .map(row=>source(review,familiesSheet!,row));
  insights.push({
   id:"families-without-people",
   severity:"attention",
   title:`${unlinkedFamilies.length} ${unlinkedFamilies.length===1?"family has":"families have"} no linked people`,
   summary:"The household records exist, but the activation pack does not connect any person to them yet.",
   evidence
  });
 }

 if(latestMembershipYear){
  const missingMembership=[...familyIds].filter(id=>!latestMembershipFamilies.has(id));
  if(missingMembership.length){
   insights.push({
    id:"latest-year-membership-gaps",
    severity:"attention",
    title:`${missingMembership.length} ${missingMembership.length===1?"family is":"families are"} missing from ${latestMembershipYear} membership`,
    summary:"TrustWeave can distinguish a directory record from an active annual membership instead of assuming every listed family is current.",
    evidence:families
     .filter(row=>missingMembership.includes(norm(row.values.stable_id)))
     .slice(0,8)
     .map(row=>source(review,familiesSheet!,row))
   });
  }

  const missingRepresentative=[...latestMembershipFamilies].filter(id=>!latestRepresentativeFamilies.has(id));
  if(missingRepresentative.length){
   insights.push({
    id:"latest-year-representative-gaps",
    severity:"attention",
    title:`${missingRepresentative.length} ${missingRepresentative.length===1?"active family has":"active families have"} no representative in ${latestMembershipYear}`,
    summary:"Representative identity is important for governed family-count, renewal, voting and household administration flows.",
    evidence:latestMemberships
     .filter(row=>missingRepresentative.includes(norm(row.values.family_id)))
     .slice(0,8)
     .map(row=>source(review,membershipSheet!,row))
   });
  }

  const paymentAttention=latestMemberships.filter(row=>{
   const state=norm(row.values.payment_status);
   return state==="unpaid"||state==="partial";
  });
  if(paymentAttention.length){
   insights.push({
    id:"latest-year-payment-attention",
    severity:"context",
    title:`${paymentAttention.length} ${paymentAttention.length===1?"membership needs":"memberships need"} payment attention in ${latestMembershipYear}`,
    summary:"This is a source-backed administrative observation, not a payment demand or inferred financial conclusion.",
    evidence:paymentAttention.slice(0,8).map(row=>source(review,membershipSheet!,row))
   });
  }
 }

 if(leadership.length){
  const roles=[...new Set(leadership.map(row=>norm(row.values.role_key)).filter(Boolean))];
  insights.push({
   id:"leadership-history-reconstructed",
   severity:"positive",
   title:`${leadership.length} leadership assignment${leadership.length===1?"":"s"} reconstructed`,
   summary:`${roles.length} distinct role${roles.length===1?"":"s"} are represented across the supplied institutional history.`,
   evidence:leadership.slice(0,8).map(row=>source(review,leadershipSheet!,row))
  });
 }

 if(membershipYears.length>1){
  insights.push({
   id:"membership-history-depth",
   severity:"positive",
   title:`${membershipYears.length} membership cycles are represented`,
   summary:`The activation pack contains institutional history across ${membershipYears.sort((a,b)=>yearStart(a)-yearStart(b)).join(", ")} rather than only a current member list.`,
   evidence:memberships.slice(0,Math.min(8,memberships.length)).map(row=>source(review,membershipSheet!,row))
  });
 }

 const presidentRows=leadership
  .filter(row=>norm(row.values.role_key)==="president")
  .sort((a,b)=>yearStart(clean(a.values.membership_year))-yearStart(clean(b.values.membership_year)));
 const peopleById=new Map(people.map(row=>[norm(row.values.stable_id),clean(row.values.name)]));
 const presidentHistory=presidentRows.map(row=>({
  year:clean(row.values.membership_year),
  person:peopleById.get(norm(row.values.person_id))||clean(row.values.person_id),
  ref:source(review,leadershipSheet!,row)
 }));

 const answers:ActivationInstitutionalAnswer[]=[
  {
   question:"What did TrustWeave reconstruct?",
   answer:`${families.length} families, ${people.length} people, ${household.length} household links, ${membershipYears.length} membership cycles and ${leadership.length} leadership assignments.`,
   evidence:[
    ...families.slice(0,2).map(row=>source(review,familiesSheet!,row)),
    ...people.slice(0,2).map(row=>source(review,peopleSheet!,row)),
    ...memberships.slice(0,2).map(row=>source(review,membershipSheet!,row))
   ]
  }
 ];

 if(latestMembershipYear){
  answers.push({
   question:"What is the latest membership cycle in the supplied records?",
   answer:`${latestMembershipYear}, containing ${latestMemberships.length} family membership record${latestMemberships.length===1?"":"s"}.`,
   evidence:latestMemberships.slice(0,5).map(row=>source(review,membershipSheet!,row))
  });
 }
 if(presidentHistory.length){
  answers.push({
   question:"Who served as President in the supplied history?",
   answer:presidentHistory.map(item=>`${item.year}: ${item.person}`).join("; "),
   evidence:presidentHistory.map(item=>item.ref)
  });
 }

 return {
  version:"network-activation-intelligence.v1",
  headline:`TrustWeave reconstructed ${families.length} families and ${people.length} people from existing institutional records.`,
  summary:{
   families:families.length,
   people:people.length,
   householdLinks:household.length,
   membershipYears:membershipYears.length,
   membershipRecords:memberships.length,
   leadershipAssignments:leadership.length,
   latestMembershipYear
  },
  insights,
  answers
 };
}
