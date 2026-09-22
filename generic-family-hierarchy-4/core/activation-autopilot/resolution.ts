import type {ImportReview,ParsedImportRow,ParsedImportSheet} from "../import/contracts";
import type {ActivationAttentionItem,NetworkActivationCompilation} from "./compiler";

export type ActivationResolutionDecision =
 | {attentionId:string;action:"keep_separate"}
 | {attentionId:string;action:"merge_person";sheetKey:string;rowNumber:number}
 | {attentionId:string;action:"keep_source_row";sheetKey:string;rowNumber:number};

export type ActivationResolutionState={
 review:ImportReview;
 resolvedAttentionIds:string[];
 unresolvedAttentionIds:string[];
 conflictingDecisionIds:string[];
 canActivate:boolean;
 skippedSourceRows:{sheetKey:string;rowNumber:number}[];
 identityAliases:Record<string,string>;
};

const clean=(value:unknown)=>String(value??"").trim();
const rowKey=(sheetKey:string,rowNumber:number)=>`${sheetKey}|${rowNumber}`;
const sourceGroupKey=(item:ActivationAttentionItem)=>item.sourceRefs
 .map(ref=>rowKey(ref.sheetKey,ref.rowNumber))
 .sort()
 .join(",");

function cloneRow(row:ParsedImportRow):ParsedImportRow{
 return {...row,values:{...row.values},raw:{...row.raw},issues:[...row.issues]};
}

function stableId(sheet:ParsedImportSheet,row:ParsedImportRow){
 const column=sheet.schema.columns.find(item=>item.target==="stableId");
 return column?clean(row.values[column.key]):"";
}

function isBlank(value:unknown){return value===""||value==null}

export function applyActivationResolutions(
 review:ImportReview,
 compilation:NetworkActivationCompilation,
 decisions:readonly ActivationResolutionDecision[],
):ActivationResolutionState{
 const decisionById=new Map(decisions.map(decision=>[decision.attentionId,decision] as const));
 const unresolved=new Set<string>();
 const resolved=new Set<string>();
 const conflicting=new Set<string>();
 const skipRows=new Set<string>();
 const identityAliases=new Map<string,string>();
 const canonicalPersonMerges=new Map<string,{sheetKey:string;rowNumber:number;losingRows:{sheetKey:string;rowNumber:number}[]}>();

 // Conflicts that offer row choices may appear more than once for the same source rows
 // (for example status + representative + payment disagreement). They must resolve
 // to one source row so the activation plan cannot combine contradictory facts.
 const rowChoiceByGroup=new Map<string,{choice:string;attentionIds:string[]}>();

 for(const item of compilation.attention){
  if(item.severity==="info")continue;
  const decision=decisionById.get(item.id);
  if(item.severity==="blocking"||!decision){unresolved.add(item.id);continue}

  if(item.code==="POSSIBLE_DUPLICATE_IDENTITY"){
   if(decision.action==="keep_separate"){
    resolved.add(item.id);
    continue;
   }
   if(decision.action!=="merge_person"){
    unresolved.add(item.id);
    continue;
   }

   const selectedRef=item.sourceRefs.find(ref=>ref.sheetKey===decision.sheetKey&&ref.rowNumber===decision.rowNumber);
   const selectedSheet=review.sheets.find(sheet=>sheet.schema.key===decision.sheetKey);
   const selectedRow=selectedSheet?.rows.find(row=>row.rowNumber===decision.rowNumber);
   const canonicalId=selectedSheet&&selectedRow?stableId(selectedSheet,selectedRow):"";
   if(!selectedRef||!selectedSheet||selectedSheet.schema.entityKind!=="person"||!selectedRow||!canonicalId){
    unresolved.add(item.id);
    continue;
   }

   const losingRows:{sheetKey:string;rowNumber:number}[]=[];
   let invalid=false;
   for(const ref of item.sourceRefs){
    if(ref.sheetKey===decision.sheetKey&&ref.rowNumber===decision.rowNumber)continue;
    const sourceSheet=review.sheets.find(sheet=>sheet.schema.key===ref.sheetKey);
    const sourceRow=sourceSheet?.rows.find(row=>row.rowNumber===ref.rowNumber);
    const losingId=sourceSheet&&sourceRow?stableId(sourceSheet,sourceRow):"";
    if(!sourceSheet||sourceSheet.schema.entityKind!=="person"||!sourceRow||!losingId){
     invalid=true;break;
    }
    identityAliases.set(losingId.toLowerCase(),canonicalId);
    losingRows.push({sheetKey:ref.sheetKey,rowNumber:ref.rowNumber});
    skipRows.add(rowKey(ref.sheetKey,ref.rowNumber));
   }
   if(invalid){
    losingRows.forEach(ref=>skipRows.delete(rowKey(ref.sheetKey,ref.rowNumber)));
    unresolved.add(item.id);
    continue;
   }

   canonicalPersonMerges.set(item.id,{
    sheetKey:decision.sheetKey,
    rowNumber:decision.rowNumber,
    losingRows
   });
   resolved.add(item.id);
   continue;
  }

  if(decision.action!=="keep_source_row"){
   unresolved.add(item.id);
   continue;
  }

  const validChoice=item.sourceRefs.some(ref=>ref.sheetKey===decision.sheetKey&&ref.rowNumber===decision.rowNumber);
  if(!validChoice){unresolved.add(item.id);continue}
  const group=sourceGroupKey(item);
  const choice=rowKey(decision.sheetKey,decision.rowNumber);
  const prior=rowChoiceByGroup.get(group);
  if(prior&&prior.choice!==choice){
   conflicting.add(item.id);
   prior.attentionIds.forEach(id=>conflicting.add(id));
   unresolved.add(item.id);
   prior.attentionIds.forEach(id=>unresolved.add(id));
   continue;
  }
  rowChoiceByGroup.set(group,{choice,attentionIds:[...(prior?.attentionIds||[]),item.id]});
  resolved.add(item.id);
 }

 for(const [group,selection] of rowChoiceByGroup){
  if(selection.attentionIds.some(id=>conflicting.has(id)))continue;
  for(const candidate of group.split(",").filter(Boolean)){
   if(candidate!==selection.choice)skipRows.add(candidate);
  }
 }

 // Start from every source row, including rows that will be excluded from canonical
 // writes. Excluded rows remain present as rejected rows so the evidence layer can
 // preserve what the source actually contained.
 const clonedSheets=review.sheets.map(sheet=>({
  ...sheet,
  rows:sheet.rows.map(cloneRow),
  validRows:0,
  warningRows:0,
  rejectedRows:0,
 })) as ParsedImportSheet[];

 // A human-selected person merge may safely fill blank canonical fields from the
 // losing source person. It never overwrites a non-empty canonical field.
 for(const merge of canonicalPersonMerges.values()){
  const targetSheet=clonedSheets.find(sheet=>sheet.schema.key===merge.sheetKey);
  const targetRow=targetSheet?.rows.find(row=>row.rowNumber===merge.rowNumber);
  if(!targetSheet||!targetRow)continue;
  for(const losingRef of merge.losingRows){
   const losingSheet=review.sheets.find(sheet=>sheet.schema.key===losingRef.sheetKey);
   const losingRow=losingSheet?.rows.find(row=>row.rowNumber===losingRef.rowNumber);
   if(!losingSheet||!losingRow)continue;
   for(const column of targetSheet.schema.columns){
    if(column.target==="stableId")continue;
    if(isBlank(targetRow.values[column.key])&&!isBlank(losingRow.values[column.key])){
     targetRow.values[column.key]=losingRow.values[column.key];
    }
   }
  }
 }

 // Rewrite typed references only after a human chooses the canonical person.
 // Raw source cells remain untouched for provenance.
 for(const sheet of clonedSheets){
  for(const row of sheet.rows){
   for(const column of sheet.schema.columns.filter(column=>column.type==="reference")){
    const current=clean(row.values[column.key]);
    const replacement=current?identityAliases.get(current.toLowerCase()):undefined;
    if(replacement)row.values[column.key]=replacement;
   }
   if(skipRows.has(rowKey(sheet.schema.key,row.rowNumber)))row.status="rejected";
  }
  sheet.validRows=sheet.rows.filter(row=>row.status==="valid").length;
  sheet.warningRows=sheet.rows.filter(row=>row.status==="warning").length;
  sheet.rejectedRows=sheet.rows.filter(row=>row.status==="rejected").length;
 }

 const validRows=clonedSheets.reduce((sum,sheet)=>sum+sheet.validRows,0);
 const warningRows=clonedSheets.reduce((sum,sheet)=>sum+sheet.warningRows,0);
 const rejectedRows=clonedSheets.reduce((sum,sheet)=>sum+sheet.rejectedRows,0);
 const hasImportErrors=review.issues.some(issue=>issue.severity==="error");
 const allReviewResolved=compilation.attention
  .filter(item=>item.severity==="review")
  .every(item=>resolved.has(item.id)&&!conflicting.has(item.id));

 const resolvedReview:ImportReview={
  ...review,
  sheets:clonedSheets,
  validRows,
  warningRows,
  rejectedRows,
  canCommit:review.canCommit&&!hasImportErrors&&allReviewResolved&&validRows+warningRows>0,
 };

 return {
  review:resolvedReview,
  resolvedAttentionIds:[...resolved].filter(id=>!conflicting.has(id)),
  unresolvedAttentionIds:[...unresolved],
  conflictingDecisionIds:[...conflicting],
  canActivate:resolvedReview.canCommit,
  skippedSourceRows:[...skipRows].map(key=>{
   const [sheetKey,row]=key.split("|");return {sheetKey,rowNumber:Number(row)};
  }),
  identityAliases:Object.fromEntries(identityAliases),
 };
}
