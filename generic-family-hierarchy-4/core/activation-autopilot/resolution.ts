import type {ImportReview,ParsedImportRow,ParsedImportSheet} from "../import/contracts";
import type {ActivationAttentionItem,NetworkActivationCompilation} from "./compiler";

export type ActivationResolutionDecision =
 | {attentionId:string;action:"keep_separate"}
 | {attentionId:string;action:"keep_source_row";sheetKey:string;rowNumber:number};

export type ActivationResolutionState={
 review:ImportReview;
 resolvedAttentionIds:string[];
 unresolvedAttentionIds:string[];
 conflictingDecisionIds:string[];
 canActivate:boolean;
 skippedSourceRows:{sheetKey:string;rowNumber:number}[];
};

const rowKey=(sheetKey:string,rowNumber:number)=>`${sheetKey}|${rowNumber}`;
const sourceGroupKey=(item:ActivationAttentionItem)=>item.sourceRefs
 .map(ref=>rowKey(ref.sheetKey,ref.rowNumber))
 .sort()
 .join(",");

function cloneRow(row:ParsedImportRow):ParsedImportRow{
 return {...row,values:{...row.values},raw:{...row.raw},issues:[...row.issues]};
}
function cloneSheet(sheet:ParsedImportSheet,rows:ParsedImportRow[]):ParsedImportSheet{
 const cloned=rows.map(cloneRow);
 return {
  ...sheet,
  rows:cloned,
  validRows:cloned.filter(row=>row.status==="valid").length,
  warningRows:cloned.filter(row=>row.status==="warning").length,
  rejectedRows:cloned.filter(row=>row.status==="rejected").length,
 };
}

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

 // Conflicts that offer row choices may appear more than once for the same source rows
 // (for example status + representative disagreement). They must resolve to one row.
 const rowChoiceByGroup=new Map<string,{choice:string;attentionIds:string[]}>();
 for(const item of compilation.attention){
  if(item.severity==="info")continue;
  const decision=decisionById.get(item.id);
  if(item.severity==="blocking"||!decision){unresolved.add(item.id);continue}

  if(decision.action==="keep_separate"){
   if(item.code!=="POSSIBLE_DUPLICATE_EMAIL"&&item.code!=="POSSIBLE_DUPLICATE_NAME"){
    unresolved.add(item.id);continue;
   }
   resolved.add(item.id);continue;
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

 const sheets=review.sheets.map(sheet=>cloneSheet(
  sheet,
  sheet.rows.filter(row=>!skipRows.has(rowKey(sheet.schema.key,row.rowNumber))),
 ));
 const validRows=sheets.reduce((sum,sheet)=>sum+sheet.validRows,0);
 const warningRows=sheets.reduce((sum,sheet)=>sum+sheet.warningRows,0);
 const rejectedRows=sheets.reduce((sum,sheet)=>sum+sheet.rejectedRows,0);
 const hasImportErrors=review.issues.some(issue=>issue.severity==="error");
 const allReviewResolved=compilation.attention
  .filter(item=>item.severity==="review")
  .every(item=>resolved.has(item.id)&&!conflicting.has(item.id));

 const resolvedReview:ImportReview={
  ...review,
  sheets,
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
 };
}
