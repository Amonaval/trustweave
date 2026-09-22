import * as XLSX from "xlsx";
import type {
  ImportIssue,
  ImportReview,
  ImportSchema,
  ImportSheetSchema,
  ParsedImportRow,
  ParsedImportSheet,
} from "../import/contracts";
import {convertImportValue} from "../import/parser";

const clean=(value:unknown)=>String(value??"").trim();
const norm=(value:unknown)=>clean(value).toLowerCase().replace(/[^a-z0-9]+/g,"_").replace(/^_|_$/g,"");
const isBlank=(value:unknown)=>clean(value)==="";

export type LeanSourceSheet={
  name:string;
  rows:unknown[][];
  rowCount:number;
  suggestedHeaderRow:number;
};

export type LeanSourceWorkbook={
  fileName:string;
  sheets:LeanSourceSheet[];
};

export type LeanSourceColumn={
  index:number;
  label:string;
  sample:string;
};

export type LeanSheetMapping={
  targetSheetKey:string;
  sourceSheetName:string;
  headerRow:number;
  columns:Record<string,number|null>;
};

function headerScore(row:unknown[]){
  const values=row.map(clean).filter(Boolean);
  if(!values.length)return -1;
  const unique=new Set(values.map(norm)).size;
  const textLike=values.filter(value=>Number.isNaN(Number(value))).length;
  return values.length*4+unique*2+textLike;
}

function suggestedHeaderRow(rows:unknown[][]){
  let best=0,bestScore=-1;
  rows.slice(0,20).forEach((row,index)=>{
    const score=headerScore(row);
    if(score>bestScore){best=index;bestScore=score}
  });
  return best+1;
}

function trimRow(row:unknown[]){
  let end=row.length;
  while(end>0&&isBlank(row[end-1]))end--;
  return row.slice(0,end);
}

export function inspectLeanSourceWorkbook(input:ArrayBuffer,fileName:string):LeanSourceWorkbook{
  const workbook=XLSX.read(input,{type:"array",cellDates:true});
  const sheets=workbook.SheetNames.map(name=>{
    const rows=XLSX.utils.sheet_to_json<unknown[]>(workbook.Sheets[name],{
      header:1,
      defval:"",
      raw:true,
      blankrows:false,
    }).map(trimRow);
    return {name,rows,rowCount:rows.length,suggestedHeaderRow:suggestedHeaderRow(rows)};
  });
  return {fileName,sheets};
}

function excelColumn(index:number){
  let value=index+1,label="";
  while(value>0){const r=(value-1)%26;label=String.fromCharCode(65+r)+label;value=Math.floor((value-1)/26)}
  return label;
}

export function sourceColumnsFor(workbook:LeanSourceWorkbook,sheetName:string,headerRow:number):LeanSourceColumn[]{
  const sheet=workbook.sheets.find(item=>item.name===sheetName);
  if(!sheet)return [];
  const header=sheet.rows[Math.max(0,headerRow-1)]||[];
  const width=Math.max(header.length,...sheet.rows.slice(headerRow,headerRow+5).map(row=>row.length),0);
  return Array.from({length:width},(_,index)=>{
    const raw=clean(header[index]);
    const label=raw||`Column ${excelColumn(index)}`;
    const sample=sheet.rows
      .slice(headerRow,headerRow+4)
      .map(row=>clean(row[index]))
      .filter(Boolean)
      .slice(0,2)
      .join(" · ");
    return {index,label,sample};
  });
}

function exactColumnSuggestion(columns:LeanSourceColumn[],target:ImportSheetSchema["columns"][number]){
  const accepted=new Set([target.key,target.label,...(target.aliases||[])].map(norm).filter(Boolean));
  const match=columns.find(column=>accepted.has(norm(column.label)));
  return match?.index??null;
}

export function suggestLeanSheetMapping(
  workbook:LeanSourceWorkbook,
  target:ImportSheetSchema,
  sourceSheetName:string,
  headerRow?:number,
):LeanSheetMapping{
  const source=workbook.sheets.find(item=>item.name===sourceSheetName);
  const row=headerRow||source?.suggestedHeaderRow||1;
  const columns=sourceColumnsFor(workbook,sourceSheetName,row);
  return {
    targetSheetKey:target.key,
    sourceSheetName,
    headerRow:row,
    columns:Object.fromEntries(target.columns.map(column=>[column.key,exactColumnSuggestion(columns,column)])),
  };
}

export function createInitialLeanMappings(workbook:LeanSourceWorkbook,schema:ImportSchema):LeanSheetMapping[]{
  return schema.sheets.map(target=>{
    const source=workbook.sheets.find(sheet=>norm(sheet.name)===norm(target.name)||norm(sheet.name)===norm(target.key));
    return source
      ? suggestLeanSheetMapping(workbook,target,source.name,source.suggestedHeaderRow)
      : {targetSheetKey:target.key,sourceSheetName:"",headerRow:1,columns:Object.fromEntries(target.columns.map(column=>[column.key,null]))};
  });
}

function rawRecord(columns:LeanSourceColumn[],row:unknown[]){
  return Object.fromEntries(columns.map(column=>[`${column.label} [${excelColumn(column.index)}]`,row[column.index]??""]));
}

export function buildLeanMappedImportReview(
  workbook:LeanSourceWorkbook,
  schema:ImportSchema,
  mappings:LeanSheetMapping[],
):ImportReview{
  const issues:ImportIssue[]=[];
  const parsedSheets:ParsedImportSheet[]=[];
  const stableBySheet=new Map<string,Set<string>>();
  const globalStable=new Map<string,{sheet:string,row:number}>();
  const refs:{row:ParsedImportRow;target:ImportSheetSchema["columns"][number];value:string}[]=[];
  const byTarget=new Map(mappings.map(mapping=>[mapping.targetSheetKey,mapping] as const));

  for(const target of schema.sheets){
    const mapping=byTarget.get(target.key);
    const source=mapping?.sourceSheetName?workbook.sheets.find(sheet=>sheet.name===mapping.sourceSheetName):undefined;

    if(!mapping||!source){
      if(target.required)issues.push({
        severity:"error",
        code:"UNMAPPED_TARGET_SHEET",
        sheet:target.name,
        message:`Map a source sheet to required target “${target.name}”.`,
      });
      continue;
    }

    const headerRow=Math.max(1,Math.min(mapping.headerRow||1,Math.max(source.rowCount,1)));
    const columns=sourceColumnsFor(workbook,source.name,headerRow);
    const mappedIndex=(key:string)=>{
      const value=mapping.columns[key];
      return typeof value==="number"&&value>=0?value:null;
    };

    for(const column of target.columns.filter(column=>column.required&&mappedIndex(column.key)==null)){
      if(column.target==="stableId"&&target.recordType==="entity"){
        issues.push({
          severity:"error",
          code:"UNMAPPED_STABLE_ID",
          sheet:target.name,
          column:column.label,
          message:`${target.name}: “${column.label}” is not mapped. Preview uses source-row identity only; activation stays blocked until a stable source identifier is mapped.`,
        });
      }else{
        issues.push({
          severity:"error",
          code:"UNMAPPED_REQUIRED_COLUMN",
          sheet:target.name,
          column:column.label,
          message:`${target.name}: map required field “${column.label}”.`,
        });
      }
    }

    const rows:ParsedImportRow[]=[];
    const stableSet=new Set<string>();
    stableBySheet.set(target.name,stableSet);
    const dataRows=source.rows.slice(headerRow);

    dataRows.forEach((sourceRow,dataIndex)=>{
      if(sourceRow.every(isBlank))return;
      const rowNumber=headerRow+dataIndex+1;
      const rowIssues:ImportIssue[]=[];
      const values:Record<string,unknown>={};

      for(const column of target.columns){
        const sourceIndex=mappedIndex(column.key);
        const rawValue=sourceIndex!=null?sourceRow[sourceIndex]:"";

        try{
          const converted=convertImportValue(rawValue,column);
          values[column.key]=converted;

          if(column.required&&sourceIndex!=null&&!clean(converted)){
            rowIssues.push({
              severity:"error",
              code:"REQUIRED_VALUE",
              sheet:target.name,
              row:rowNumber,
              column:column.label,
              message:`${column.label} is required.`,
            });
          }

          if(column.target==="stableId"&&clean(converted)){
            const id=clean(converted).toLowerCase();
            if(stableSet.has(id))rowIssues.push({
              severity:"error",
              code:"DUPLICATE_STABLE_ID",
              sheet:target.name,
              row:rowNumber,
              column:column.label,
              message:`Stable ID “${converted}” is duplicated in ${target.name}.`,
            });
            const prior=globalStable.get(id);
            if(prior&&prior.sheet!==target.name)rowIssues.push({
              severity:"error",
              code:"AMBIGUOUS_STABLE_ID",
              sheet:target.name,
              row:rowNumber,
              column:column.label,
              message:`Stable ID “${converted}” is also used in ${prior.sheet} row ${prior.row}.`,
            });
            stableSet.add(id);
            if(!prior)globalStable.set(id,{sheet:target.name,row:rowNumber});
          }

        }catch(error:any){
          values[column.key]="";
          rowIssues.push({
            severity:"error",
            code:"INVALID_VALUE",
            sheet:target.name,
            row:rowNumber,
            column:column.label,
            message:`${column.label}: ${error?.message||"Invalid value."}`,
          });
        }
      }

      const parsed:ParsedImportRow={
        sheetKey:target.key,
        sheetName:source.name,
        rowNumber,
        values,
        raw:rawRecord(columns,sourceRow),
        status:rowIssues.some(issue=>issue.severity==="error")?"rejected":rowIssues.length?"warning":"valid",
        issues:rowIssues,
      };
      rows.push(parsed);
      issues.push(...rowIssues);

      for(const column of target.columns.filter(column=>column.type==="reference")){
        const value=clean(values[column.key]);
        if(value)refs.push({row:parsed,target:column,value});
      }
    });

    parsedSheets.push({
      schema:target,
      rows,
      validRows:rows.filter(row=>row.status==="valid").length,
      warningRows:rows.filter(row=>row.status==="warning").length,
      rejectedRows:rows.filter(row=>row.status==="rejected").length,
    });
  }

  for(const item of refs){
    const targets=item.target.referenceSheets?.length
      ? [...item.target.referenceSheets]
      : item.target.referenceSheet?[item.target.referenceSheet]:[];
    if(!targets.length)continue;
    const found=targets.some(target=>stableBySheet.get(target)?.has(item.value.toLowerCase()));
    if(found)continue;
    const issue:ImportIssue={
      severity:"error",
      code:"UNRESOLVED_REFERENCE",
      sheet:item.row.sheetKey,
      row:item.row.rowNumber,
      column:item.target.label,
      message:`Reference “${item.value}” was not found in ${targets.join(" / ")}.`,
    };
    item.row.issues.push(issue);
    item.row.status="rejected";
    issues.push(issue);
  }

  for(const sheet of parsedSheets){
    sheet.validRows=sheet.rows.filter(row=>row.status==="valid").length;
    sheet.warningRows=sheet.rows.filter(row=>row.status==="warning").length;
    sheet.rejectedRows=sheet.rows.filter(row=>row.status==="rejected").length;
  }

  const validRows=parsedSheets.reduce((sum,sheet)=>sum+sheet.validRows,0);
  const warningRows=parsedSheets.reduce((sum,sheet)=>sum+sheet.warningRows,0);
  const rejectedRows=parsedSheets.reduce((sum,sheet)=>sum+sheet.rejectedRows,0);

  return {
    schema,
    fileName:workbook.fileName,
    issues,
    sheets:parsedSheets,
    validRows,
    warningRows,
    rejectedRows,
    canCommit:!issues.some(issue=>issue.severity==="error")&&validRows+warningRows>0,
  };
}
