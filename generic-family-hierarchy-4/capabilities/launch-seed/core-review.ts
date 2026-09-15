import {getImportSchema} from "../../core/import/registry";
import type {ImportReview,ParsedImportRow,ParsedImportSheet} from "../../core/import/contracts";
import type {LaunchDataset,LaunchSeedKind} from "../../core/launch-seed/contracts";
import {sectionRows} from "./dataset";

const PATHS:Record<LaunchSeedKind,Record<string,string>>={
 "housing-society":{units:"core_import.units",residents:"core_import.residents",occupancy:"core_import.occupancy",vehicles:"core_import.vehicles",parking:"core_import.parking"},
 "family-association":{families:"core_import.families",people:"core_import.people",household_membership:"core_import.household_membership",association_membership:"core_import.association_membership"},
};
function normalizedValue(raw:Record<string,any>,label:string,key:string){const value=raw[label]!==undefined?raw[label]:raw[key];if(typeof value==="string"){const t=value.trim();if(t.toLowerCase()==="yes")return true;if(t.toLowerCase()==="no")return false;return t}return value??""}
export function buildLaunchCoreReview(data:LaunchDataset,kind:LaunchSeedKind,fileName=`${data.version}.json`):ImportReview{
 const schema=getImportSchema(kind);const sheets:ParsedImportSheet[]=[];
 for(const ss of schema.sheets){const path=PATHS[kind][ss.key];if(!path)continue;const rows:ParsedImportRow[]=sectionRows(data,path).map((raw,index)=>({sheetKey:ss.key,sheetName:ss.name,rowNumber:index+2,values:Object.fromEntries(ss.columns.map(col=>[col.key,normalizedValue(raw,col.label,col.key)])),raw,status:"valid",issues:[]}));sheets.push({schema:ss,rows,validRows:rows.length,warningRows:0,rejectedRows:0})}
 const validRows=sheets.reduce((n,s)=>n+s.validRows,0);return {schema,fileName,issues:[],sheets,validRows,warningRows:0,rejectedRows:0,canCommit:validRows>0};
}
