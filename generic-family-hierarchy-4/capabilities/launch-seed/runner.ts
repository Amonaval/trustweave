import type {LaunchDataset,LaunchSeedCommitResult,LaunchSeedDiagnostic,LaunchSeedKind,LaunchSeedLineageRow,LaunchSeedLineageStatus,LaunchSeedOptions} from "../../core/launch-seed/contracts";
import {recordLaunchSeedLineage,recordLaunchSeedRunIssue} from "./remote";
import {seedPayloadHash} from "./dataset";

type MutationResult=string|void|{id?:string|null;message?:string};
type RowOptions={immutableAfterCreate?:boolean;operation?:string};
const completeStatus=(status:string|undefined)=>status==="committed"||status==="skipped"||status==="warning";
const sleep=(ms:number)=>ms>0?new Promise<void>(resolve=>setTimeout(resolve,ms)):Promise.resolve();
function asDiagnostic(error:any,section:string,rowRef:string,operation:string):LaunchSeedDiagnostic{
 const code=error?.code!=null?String(error.code):error?.status!=null?String(error.status):null;
 const message=String(error?.message||error?.error_description||error||"Unknown seed error");
 const details=error?.details!=null?String(error.details):null,hint=error?.hint!=null?String(error.hint):null;
 const retryable=code==="429"||code==="57014"||code==="53300"||code==="08000"||code==="08003"||code==="08006"||String(code||"").startsWith("PGRST");
 return {severity:"error",section,rowRef,operation,code,message,details,hint,retryable,occurredAt:new Date().toISOString()};
}
export class LaunchSeedRunner{
 readonly prior=new Map<string,LaunchSeedLineageRow>();created=0;updated=0;skipped=0;errors=0;warnings:string[]=[];diagnostics:LaunchSeedDiagnostic[]=[];completedSections:string[]=[];current=0;
 constructor(readonly data:LaunchDataset,readonly kind:LaunchSeedKind,lineage:LaunchSeedLineageRow[],readonly total:number,readonly options:LaunchSeedOptions={}){for(const row of lineage)this.prior.set(`${row.sectionKey}|${row.rowRef}`,row)}
 private async progress(section:string,message:string){this.current++;this.options.onProgress?.({phase:"commit",section,current:this.current,total:this.total,message});await sleep(this.options.paceMs??20)}
 priorRow(section:string,rowRef:string){return this.prior.get(`${section}|${rowRef}`)}
 private async diagnostic(diagnostic:LaunchSeedDiagnostic){this.diagnostics.push(diagnostic);this.options.onDiagnostic?.(diagnostic);if(this.options.runId)try{await recordLaunchSeedRunIssue(this.options.runId,diagnostic)}catch{/* diagnostics must never break the seed itself */}}
 async remember(section:string,rowRef:string,payload:unknown,remoteId?:string|null,status:LaunchSeedLineageStatus="committed",message?:string){const payloadHash=seedPayloadHash(payload);await recordLaunchSeedLineage({datasetVersion:this.data.version,sectionKey:section,rowRef,payloadHash,remoteId,status,message});this.prior.set(`${section}|${rowRef}`,{sectionKey:section,rowRef,payloadHash,remoteId,status,lastMessage:message})}
 async checkpoint(section:string,rowRef:string,payload:unknown,remoteId:string,message="Created; remaining state transition will be retried if needed."){await this.remember(section,rowRef,payload,remoteId,"partial",message);return remoteId}
 async warningRow(section:string,rowRef:string,payload:unknown,message:string,remoteId?:string|null){const hash=seedPayloadHash(payload),prior=this.priorRow(section,rowRef);if(prior?.payloadHash===hash&&completeStatus(prior.status)){this.skipped++;this.warnings.push(message);await this.diagnostic({severity:"warning",section,rowRef,operation:"known-constraint",message,occurredAt:new Date().toISOString()});await this.progress(section,`Skipped ${rowRef} — unchanged known constraint.`);return}this.skipped++;this.warnings.push(message);await this.remember(section,rowRef,payload,remoteId||prior?.remoteId||null,"warning",message);await this.diagnostic({severity:"warning",section,rowRef,operation:"constraint",message,occurredAt:new Date().toISOString()});await this.progress(section,`Recorded constrained seed row ${rowRef}.`)}
 async row(section:string,rowRef:string,payload:unknown,mutate:(existingId?:string|null)=>Promise<MutationResult>,opts:RowOptions={}){
  const hash=seedPayloadHash(payload),prior=this.priorRow(section,rowRef);
  if(prior?.payloadHash===hash&&completeStatus(prior.status)){this.skipped++;await this.progress(section,`Skipped ${rowRef} — unchanged.`);return prior.remoteId||undefined}
  if(prior&&opts.immutableAfterCreate&&completeStatus(prior.status)){const msg=`${section}/${rowRef} already exists and the product API treats it as historical/immutable; changed source was not duplicated.`;this.skipped++;this.warnings.push(msg);await this.remember(section,rowRef,payload,prior.remoteId,"warning",msg);await this.diagnostic({severity:"warning",section,rowRef,operation:opts.operation||"immutable-row",message:msg,occurredAt:new Date().toISOString()});await this.progress(section,`Skipped changed historical row ${rowRef}.`);return prior.remoteId||undefined}
  try{const result=await mutate(prior?.remoteId||null);const latest=this.priorRow(section,rowRef);const id=typeof result==="string"?result:result&&typeof result==="object"?result.id||undefined:latest?.remoteId||prior?.remoteId||undefined;const message=result&&typeof result==="object"?result.message:undefined;await this.remember(section,rowRef,payload,id,"committed",message);if(prior?.remoteId||prior?.status==="partial"||prior?.status==="error")this.updated++;else this.created++;await this.progress(section,`${prior?"Updated":"Created"} ${rowRef}.`);return id||undefined}catch(error:any){this.errors++;const diagnostic=asDiagnostic(error,section,rowRef,opts.operation||"seed-row");const msg=`${section}/${rowRef}${diagnostic.code?` [${diagnostic.code}]`:""}: ${diagnostic.message}`;this.warnings.push(msg);const latest=this.priorRow(section,rowRef);try{await this.remember(section,rowRef,payload,latest?.remoteId||prior?.remoteId||null,"error",msg)}catch{/* preserve original failure */}await this.diagnostic(diagnostic);await this.progress(section,`Error on ${rowRef}${diagnostic.code?` · ${diagnostic.code}`:""}.`);return latest?.remoteId||prior?.remoteId||undefined}
 }
 async action(section:string,rowRef:string,operation:string,mutate:()=>Promise<void>){
  try{await mutate();return true}catch(error:any){this.errors++;const diagnostic=asDiagnostic(error,section,rowRef,operation);const msg=`${section}/${rowRef}${diagnostic.code?` [${diagnostic.code}]`:""}: ${diagnostic.message}`;this.warnings.push(msg);await this.diagnostic(diagnostic);return false}
 }

 sectionDone(section:string){if(!this.completedSections.includes(section))this.completedSections.push(section)}
 result():LaunchSeedCommitResult{return {runId:this.options.runId,datasetVersion:this.data.version,kind:this.kind,created:this.created,updated:this.updated,skipped:this.skipped,errors:this.errors,warnings:this.warnings,diagnostics:this.diagnostics,completedSections:this.completedSections,message:`Launch seed completed: ${this.created} created, ${this.updated} updated, ${this.skipped} skipped, ${this.errors} errors.`}}
}
