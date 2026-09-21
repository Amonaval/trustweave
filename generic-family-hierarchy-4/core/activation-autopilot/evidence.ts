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
  for(const row of sheet.rows.filter(item=>item.status!=="rejected")){
   const values=sheet.schema.columns
    .map(column=>({column,value:row.values[column.key]}))
    .filter(item=>item.value!==""&&item.value!=null);

   const excerpt=values
    .map(({column,value})=>`${column.label}: ${clean(value)}`)
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
     schemaVersion:review.schema.version,
     sourceKind:"guided-workbook"
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
