import type {FamilyAssociationAdminCommand} from "../../../../../../core/api/contracts";
import {executeFamilyAssociationAdminCommand} from "../../../../../../server/family-association/admin-service";
import {executeCommand} from "../../../../../../server/shared/command-runtime";
import {CommandError} from "../../../../../../server/shared/errors";
export const runtime="nodejs";
const actions=new Set(["updateSettings","upsertMembershipYear","setFamilyMembership","assignRole","addFinanceEntry"]);
export async function POST(request:Request){
 return executeCommand({request,commandName:"familyAssociationAdmin",idempotency:"required",rateLimit:{limit:30},parse:body=>{
  const action=typeof body.action==="string"?body.action:"";
  if(!actions.has(action)||!body.input||typeof body.input!=="object"||Array.isArray(body.input))throw new CommandError("INVALID_INPUT","Invalid Family Community admin operation.");
  return {action,input:body.input} as FamilyAssociationAdminCommand;
 },execute:executeFamilyAssociationAdminCommand});
}
