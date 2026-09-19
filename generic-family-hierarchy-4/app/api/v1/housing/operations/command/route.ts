import type {HousingOperationsCommand} from "../../../../../../core/api/contracts";
import {executeHousingOperationsCommand} from "../../../../../../server/housing/operations-service";
import {executeCommand} from "../../../../../../server/shared/command-runtime";
import {CommandError} from "../../../../../../server/shared/errors";
export const runtime="nodejs";
const actions=new Set(["createNotice","createComplaint","updateComplaint","addComplaintComment","upsertVendor","createVendorContract","upsertAmenity","createAmenityBooking","reviewAmenityBooking","setComplaintRoute"]);
export async function POST(request:Request){
 return executeCommand({request,commandName:"housingOperations",idempotency:"required",rateLimit:{limit:40},parse:body=>{
  const action=typeof body.action==="string"?body.action:"";
  if(!actions.has(action)||!body.input||typeof body.input!=="object"||Array.isArray(body.input))throw new CommandError("INVALID_INPUT","Invalid Housing operation.");
  return {action,input:body.input} as HousingOperationsCommand;
 },execute:executeHousingOperationsCommand});
}
