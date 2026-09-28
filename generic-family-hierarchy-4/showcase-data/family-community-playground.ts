import type {NetworkAffiliatedEntity,NetworkActivity} from "../core/network-os/contracts";
import type {NetworkGroup} from "../capabilities/activity/remote";
import type {NetworkFundsSnapshot} from "../capabilities/template-product/remote";
import type {BallotsSnapshot} from "../capabilities/participation/voting-remote";
import launchData from "../public/launch-demo/family-community-20-families.json";

type Row=Record<string,string|number|boolean|null>;
type Relationship={id:string;fromEntityId:string;toEntityId:string;relationshipType:string;label:string};

const data=launchData as unknown as {
 version:string;
 core_import:{families:Row[];people:Row[];household_membership:Row[];association_membership:Row[]};
 family_detail:{people_extended:Row[];family_relationships:Row[]};
 membership:{family_membership:Row[];role_catalog:Row[];role_assignments:Row[]};
 community:{events:Row[];rsvps:Row[];announcements:Row[];posts:Row[];post_comments:Row[];memories:Row[];groups:Row[];group_membership:Row[]};
 finance:{funds:Row[];transactions:Row[]};
 governance:{ballots:Row[];ballot_options:Row[]};
};

const value=(row:Row,key:string)=>String(row[key]??"").trim();
const num=(row:Row,key:string)=>Number(row[key]||0);
const split=(raw:string)=>raw.split(";").map(x=>x.trim()).filter(Boolean);
const familyEntityId=(id:string)=>`fca-family-${id}`;
const personEntityId=(id:string)=>`fca-person-${id}`;
const relationshipLabel=(kind:string)=>kind==="spouse_of"?"Spouse":kind==="parent_of"?"Parent of":kind==="represented_by"?"Represented by":"Member of family";

const people=data.core_import.people;
const families=data.core_import.families;
const peopleById=new Map(people.map(row=>[value(row,"Person ID"),row] as const));
const familyById=new Map(families.map(row=>[value(row,"Family ID"),row] as const));
const extendedByPerson=new Map(data.family_detail.people_extended.map(row=>[value(row,"Person ID"),row] as const));
const householdByPerson=new Map(data.core_import.household_membership.map(row=>[value(row,"Person ID"),value(row,"Family ID")] as const));
const annualMembershipByFamily=new Map(data.membership.family_membership.map(row=>[value(row,"Family ID"),row] as const));
const associationMembershipByFamily=new Map(data.core_import.association_membership.map(row=>[value(row,"Family ID"),row] as const));
const roleByRef=new Map(data.membership.role_catalog.map(row=>[value(row,"Role Ref"),row] as const));
const roleAssignmentByPerson=new Map(data.membership.role_assignments.map(row=>[value(row,"Person ID"),row] as const));
const familyMembers=new Map<string,string[]>();
for(const row of data.core_import.household_membership){
 const familyId=value(row,"Family ID"),personId=value(row,"Person ID"),list=familyMembers.get(familyId)||[];
 list.push(personId);familyMembers.set(familyId,list);
}

const currentMembershipStatus=(familyId:string)=>{
 const membership=annualMembershipByFamily.get(familyId);
 return value(membership||{},"Status")||value(familyById.get(familyId)||{},"Membership Status")||"pending";
};

const familyEntities:NetworkAffiliatedEntity[]=families.map(row=>{
 const familyId=value(row,"Family ID"),membership=annualMembershipByFamily.get(familyId)||{},representativeId=value(membership,"Representative Person ID");
 const representative=peopleById.get(representativeId)||{},representativeExtended=extendedByPerson.get(representativeId)||{};
 const membershipYear=value(associationMembershipByFamily.get(familyId)||{},"Membership Year")||"2026-27";
 const membershipStatus=currentMembershipStatus(familyId),area=value(row,"Area")||"Pune";
 return {
  entity:{
   id:familyEntityId(familyId),networkId:"sample",kind:"family",label:value(row,"Family / Household Name")||familyId,
   metadata:{
    role:"Registered family",representative:value(representative,"Full Name"),memberCount:(familyMembers.get(familyId)||[]).length,
    contact:value(representativeExtended,"Phone"),email:value(representative,"Email"),city:"Pune",area,
    membership_status:membershipStatus,payment_status:value(membership,"Payment Status"),
    amount_due:num(membership,"Amount Due"),amount_paid:num(membership,"Amount Paid"),payment_reference:value(membership,"Payment Reference")
   }
  },
  affiliations:{membership_year:[membershipYear],membership_status:[membershipStatus],chapter:["MPF Pune East"],city:["Pune"],area:[area],committee:[],interest:[]}
 };
});

const personEntities:NetworkAffiliatedEntity[]=people.map(row=>{
 const personId=value(row,"Person ID"),familyId=householdByPerson.get(personId)||"",family=familyById.get(familyId)||{},extended=extendedByPerson.get(personId)||{};
 const membership=associationMembershipByFamily.get(familyId)||{},assignment=roleAssignmentByPerson.get(personId),roleDef=assignment?roleByRef.get(value(assignment,"Role Ref")):undefined;
 const familyRole=value(extended,"Family Role"),roleLabel=roleDef?value(roleDef,"Label"):(familyRole==="representative"?"Family Representative":"Family Member");
 const area=value(family,"Area")||"Pune",profession=value(row,"Profession"),interests=split(value(extended,"Interests")),committee=roleDef?[roleLabel]:[];
 return {
  entity:{
   id:personEntityId(personId),networkId:"sample",kind:"person",label:value(row,"Full Name")||personId,
   metadata:{
    role:roleLabel,relation:familyRole,dob:value(extended,"Date of Birth"),phone:value(extended,"Phone"),email:value(row,"Email"),
    profession,city:value(row,"City")||"Pune",area,portfolio:roleDef?value(roleDef,"Portfolio"):"",
    profile_visibility:value(extended,"Profile Visibility")||"members",contact_visibility:value(extended,"Contact Visibility")||"members",
    discoverable:"true",interests:interests.join(", ")
   }
  },
  affiliations:{
   membership_year:[value(membership,"Membership Year")||"2026-27"],membership_status:[currentMembershipStatus(familyId)],
   chapter:["MPF Pune East"],city:[value(row,"City")||"Pune"],area:[area],committee,interest:interests,profession:profession?[profession]:[]
  }
 };
});

const representedBy:Relationship[]=data.membership.family_membership.map((row,index)=>({
 id:`fca-represented-${index+1}`,fromEntityId:familyEntityId(value(row,"Family ID")),toEntityId:personEntityId(value(row,"Representative Person ID")),
 relationshipType:"represented_by",label:relationshipLabel("represented_by")
}));

const memberOfFamily:Relationship[]=data.core_import.household_membership.map((row,index)=>({
 id:`fca-member-${index+1}`,fromEntityId:personEntityId(value(row,"Person ID")),toEntityId:familyEntityId(value(row,"Family ID")),
 relationshipType:"member_of_family",label:relationshipLabel("member_of_family")
}));

const seenSpouses=new Set<string>();
const familyRelationships:Relationship[]=[];
for(const row of data.family_detail.family_relationships){
 const raw=value(row,"Relationship").toLowerCase(),from=value(row,"From Person ID"),to=value(row,"To Person ID");
 if(!from||!to||raw==="child")continue;
 if(raw==="spouse"){
  const pair=[from,to].sort().join("|");if(seenSpouses.has(pair))continue;seenSpouses.add(pair);
  familyRelationships.push({id:`fca-${value(row,"Relationship Ref")}`,fromEntityId:personEntityId(from),toEntityId:personEntityId(to),relationshipType:"spouse_of",label:"Spouse"});
 }else if(raw==="parent"){
  familyRelationships.push({id:`fca-${value(row,"Relationship Ref")}`,fromEntityId:personEntityId(from),toEntityId:personEntityId(to),relationshipType:"parent_of",label:"Parent of"});
 }
}

const yesRsvpByEvent=new Map<string,number>();
const previewRsvpsByEvent=new Map<string,{userId:string;memberLabel:string;response:"going"|"maybe"|"declined";updatedAt:string}[]>();
for(const row of data.community.rsvps){
 const eventRef=value(row,"Event Ref"),personId=value(row,"Person ID"),rawResponse=value(row,"Response").toLowerCase();
 const response:("going"|"maybe"|"declined")=rawResponse==="yes"?"going":rawResponse==="maybe"?"maybe":"declined";
 if(response==="going")yesRsvpByEvent.set(eventRef,(yesRsvpByEvent.get(eventRef)||0)+1);
 const list=previewRsvpsByEvent.get(eventRef)||[],person=peopleById.get(personId)||{};
 list.push({userId:personEntityId(personId),memberLabel:value(person,"Full Name")||"Member",response,updatedAt:""});
 previewRsvpsByEvent.set(eventRef,list);
}
const commentsByPost=new Map<string,number>();
for(const row of data.community.post_comments){
 const postRef=value(row,"Post Ref");commentsByPost.set(postRef,(commentsByPost.get(postRef)||0)+1);
}

const eventActivities:NetworkActivity[]=data.community.events.map(row=>{
 const id=value(row,"Event Ref");
 return {id:`fca-${id}`,networkId:"sample",type:"event",title:value(row,"Title"),body:value(row,"Description"),
  startsAt:`${value(row,"Date")}T18:30:00+05:30`,place:value(row,"Venue"),visibility:"members",goingCount:yesRsvpByEvent.get(id)||0,
  metadata:{source_ref:id,status:value(row,"Status"),dataset_version:data.version,preview_rsvps:previewRsvpsByEvent.get(id)||[]}};
});

const announcementActivities:NetworkActivity[]=data.community.announcements.map(row=>({
 id:`fca-${value(row,"Announcement Ref")}`,networkId:"sample",type:"announcement",title:value(row,"Title"),body:value(row,"Body"),visibility:"members",
 metadata:{source_ref:value(row,"Announcement Ref"),audience:value(row,"Audience"),importance:value(row,"Priority"),dataset_version:data.version}
}));

const postActivities:NetworkActivity[]=data.community.posts.map(row=>{
 const person=peopleById.get(value(row,"Author Person ID"));
 return {id:`fca-${value(row,"Post Ref")}`,networkId:"sample",type:"announcement",title:value(row,"Title"),body:value(row,"Body"),visibility:"members",
  authorLabel:person?value(person,"Full Name"):"Community member",commentCount:commentsByPost.get(value(row,"Post Ref"))||0,
  metadata:{content_kind:"post",category:value(row,"Category"),importance:value(row,"Importance"),notify_all:Boolean(row["Notify All"]),pinned:Boolean(row["Pinned"]),source_ref:value(row,"Post Ref"),dataset_version:data.version}};
});

const memoryActivities:NetworkActivity[]=data.community.memories.map(row=>({
 id:`fca-${value(row,"Memory Ref")}`,networkId:"sample",type:"memory",title:value(row,"Title"),body:value(row,"Caption"),
 startsAt:`${value(row,"Date")}T12:00:00+05:30`,visibility:"members",
 metadata:{source_ref:value(row,"Memory Ref"),memory_type:value(row,"Type"),photo_count:num(row,"Photo Count"),dataset_version:data.version}
}));

const groupCounts=new Map<string,number>();
for(const row of data.community.group_membership){
 const groupRef=value(row,"Group Ref");groupCounts.set(groupRef,(groupCounts.get(groupRef)||0)+1);
}
const previewGroupMembers=new Map<string,{userId:string;memberLabel:string;role:"member"|"lead";joinedAt:string}[]>();
for(const row of data.community.group_membership){
 const groupRef=value(row,"Group Ref"),personId=value(row,"Person ID"),person=peopleById.get(personId)||{},list=previewGroupMembers.get(groupRef)||[];
 list.push({userId:personEntityId(personId),memberLabel:value(person,"Full Name")||"Member",role:value(row,"Role").toLowerCase()==="coordinator"?"lead":"member",joinedAt:""});
 previewGroupMembers.set(groupRef,list);
}
const groups:NetworkGroup[]=data.community.groups.map(row=>({
 id:`fca-${value(row,"Group Ref")}`,name:value(row,"Name"),groupType:value(row,"Type")||"group",description:value(row,"Description"),
 memberCount:groupCounts.get(value(row,"Group Ref"))||0,previewMembers:previewGroupMembers.get(value(row,"Group Ref"))||[]
}));

export const familyCommunityPlaygroundEntities:NetworkAffiliatedEntity[]=[...familyEntities,...personEntities];
export const familyCommunityPlaygroundRelationships:Relationship[]=[...representedBy,...memberOfFamily,...familyRelationships];
export const familyCommunityPlaygroundActivities:NetworkActivity[]=[...eventActivities,...announcementActivities,...postActivities,...memoryActivities];
export const familyCommunityPlaygroundGroups:NetworkGroup[]=groups;

const fundByRef=new Map(data.finance.funds.map(row=>[value(row,"Fund Ref"),row] as const));
const familyLabel=(familyId:string)=>value(familyById.get(familyId)||{},"Family / Household Name")||familyId;
const representativeLabel=(familyId:string)=>{
 const membership=annualMembershipByFamily.get(familyId)||{},person=peopleById.get(value(membership,"Representative Person ID"))||{};
 return value(person,"Full Name");
};
const signedTransaction=(row:Row)=>["expense","refund"].includes(value(row,"Transaction Kind").toLowerCase())?-num(row,"Amount"):num(row,"Amount");
const fundTotals=new Map<string,{collected:number;spent:number;signed:number}>();
for(const row of data.finance.transactions){
 const ref=value(row,"Fund Ref"),signed=signedTransaction(row),totals=fundTotals.get(ref)||{collected:0,spent:0,signed:0};
 totals.signed+=signed;if(signed>=0)totals.collected+=signed;else totals.spent+=Math.abs(signed);fundTotals.set(ref,totals);
}
export const familyCommunityPlaygroundFunds:NetworkFundsSnapshot={
 is_admin:false,visibility_mode:"members",
 funds:data.finance.funds.filter(row=>value(row,"Visibility")!=="admins").map(row=>{
  const ref=value(row,"Fund Ref"),totals=fundTotals.get(ref)||{collected:0,spent:0,signed:0},opening=num(row,"Opening Balance");
  return {id:`fca-${ref}`,name:value(row,"Name"),fund_kind:value(row,"Fund Kind"),purpose:value(row,"Purpose"),target_amount:value(row,"Target Amount")?num(row,"Target Amount"):null,opening_balance:opening,visibility:value(row,"Visibility"),status:"active",membership_year_id:value(row,"Year Ref")||null,activity_id:value(row,"Event Ref")||null,activity_title:value(row,"Event Ref")?value(data.community.events.find(e=>value(e,"Event Ref")===value(row,"Event Ref"))||{},"Title"):null,year_label:"2026–27",collected:totals.collected,spent:totals.spent,balance:opening+totals.signed};
 }),
 transactions:data.finance.transactions.filter(row=>value(fundByRef.get(value(row,"Fund Ref"))||{},"Visibility")!=="admins").map(row=>{
  const familyId=value(row,"Source Family ID"),fund=fundByRef.get(value(row,"Fund Ref"))||{},signed=signedTransaction(row);
  return {id:`fca-${value(row,"Transaction Ref")}`,fund_id:`fca-${value(row,"Fund Ref")}`,fund_name:value(fund,"Name"),transaction_kind:value(row,"Transaction Kind"),amount:num(row,"Amount"),signed_amount:signed,source_entity_id:familyId?familyEntityId(familyId):null,source_label:familyId?familyLabel(familyId):null,receipt_no:value(row,"Reference")||null,payment_method:value(row,"Payment Method")||null,reference:value(row,"Reference")||null,note:value(row,"Note")||null,visibility:value(row,"Visibility")||"members",occurred_on:"2026–27 sample",created_at:""};
 }),
 membership_dues:data.membership.family_membership.map(row=>{
  const familyId=value(row,"Family ID"),due=num(row,"Amount Due"),paid=num(row,"Amount Paid");
  return {membership_id:`fca-membership-${familyId}`,membership_year_id:value(row,"Year Ref")||"MY2026",year_label:"2026–27",family_entity_id:familyEntityId(familyId),family_label:familyLabel(familyId),representative_label:representativeLabel(familyId),amount_due:due,amount_paid:paid,outstanding:Math.max(0,due-paid),payment_status:value(row,"Payment Status"),status:value(row,"Status")};
 }),
 events:data.community.events.map(row=>({id:`fca-${value(row,"Event Ref")}`,title:value(row,"Title"),starts_at:value(row,"Date")||null}))
};

const ballotOptionsByRef=new Map<string,Row[]>();
for(const row of data.governance.ballot_options){const ref=value(row,"Ballot Ref"),list=ballotOptionsByRef.get(ref)||[];list.push(row);ballotOptionsByRef.set(ref,list)}
export const familyCommunityPlaygroundBallots:BallotsSnapshot={
 is_admin:false,
 people:data.membership.family_membership.map(row=>{const id=value(row,"Representative Person ID"),person=peopleById.get(id)||{};return {id:personEntityId(id),label:value(person,"Full Name")||id}}),
 ballots:data.governance.ballots.map(row=>{
  const ref=value(row,"Ballot Ref");
  return {id:`fca-${ref}`,ballot_type:(value(row,"Ballot Type")==="poll"?"poll":"election") as "poll"|"election",title:value(row,"Title"),description:value(row,"Description")||null,status:value(row,"Desired Status")||"draft",eligibility_mode:value(row,"Eligibility Mode")||"family_representatives",max_choices:num(row,"Max Choices")||1,secret_ballot:Boolean(row["Secret Ballot"]),allow_nominations:Boolean(row["Allow Nominations"]),opens_at:value(row,"Opens At")||null,closes_at:value(row,"Closes At")||null,eligible_count:data.membership.family_membership.length,participation_count:0,has_voted:false,can_vote:false,options:(ballotOptionsByRef.get(ref)||[]).map(opt=>({id:`fca-${value(opt,"Option Ref")}`,label:value(opt,"Label"),description:value(opt,"Description")||null,candidate_entity_id:value(opt,"Candidate Person ID")?personEntityId(value(opt,"Candidate Person ID")):null,votes:0})),nominations:[]};
 })
};

export const familyCommunityPlaygroundProof={
 datasetVersion:data.version,
 families:familyEntities.length,
 people:personEntities.length,
 relationships:familyCommunityPlaygroundRelationships.length,
 activities:familyCommunityPlaygroundActivities.length,
 groups:groups.length,
 currentCommitteeRoles:data.membership.role_assignments.length
} as const;
