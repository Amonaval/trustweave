import type {ImportReview} from "../import/contracts";

export type ActivationEvidenceSourceInput={
 externalId:string;
 title:string;
 schemaVersion:string;
 metadata:Record<string,unknown>;
};

export type ActivationEvidenceRecordInput={
 chunkId:string;
 title:string;
 section:string;
 excerpt:string;
 extractionVersion:string;
 metadata:Record<string,unknown>;
};

export type ActivationEvidencePayload={
 source:ActivationEvidenceSourceInput;
 records:ActivationEvidenceRecordInput[];
};

const clean=(value:unknown)=>String(value??"").trim();
const safeFileKey=(value:string)=>value.toLowerCase().replace(/[^a-z0-9._-]+/g,"-").replace(/^-+|-+$/g,"").slice(0,120)||"activation-pack";

export function buildActivationEvidencePayload(review:ImportReview):ActivationEvidencePayload{
 const sourceKey=safeFileKey(review.fileName);
 const records:ActivationEvidenceRecordInput[]=[];

 for(const sheet of review.sheets){
  for(const row of sheet.rows){
   const rawValues=Object.entries(row.raw||{})
    .filter(([,value])=>value!==""&&value!=null)
    .map(([label,value])=>({label,value}));
   const normalizedValues=sheet.schema.columns
    .map(column=>({label:column.label,value:row.values[column.key]}))
    .filter(item=>item.value!==""&&item.value!=null);
   const sourceValues=rawValues.length?rawValues:normalizedValues;

   const excerpt=sourceValues
    .map(({label,value})=>`${label}: ${clean(value)}`)
    .join(" · ");

   records.push({
    chunkId:`${sheet.schema.key}:row:${row.rowNumber}`,
    title:`${sheet.schema.name} row ${row.rowNumber}`,
    section:sheet.schema.name,
    excerpt,
    extractionVersion:"network-activation-candidate.v1",
    metadata:{
     sheetKey:sheet.schema.key,
     rowNumber:row.rowNumber,
     recordType:sheet.schema.recordType,
     entityKind:sheet.schema.entityKind||null,
     rowStatus:row.status,
     activationExcluded:row.status==="rejected",
     schemaVersion:review.schema.version,
     sourceKind:"guided-workbook",
     resolvedValues:{...row.values},
     sourceRaw:{...row.raw}
    }
   });
  }
 }

 return {
  source:{
   externalId:`network-activation:${review.schema.version}:${sourceKey}`,
   title:review.fileName,
   schemaVersion:review.schema.version,
   metadata:{
    verticalKind:review.schema.verticalKind,
    sourceKind:"guided-workbook",
    sourceFileName:review.fileName,
    sourceRows:records.length
   }
  },
  records
 };
}
