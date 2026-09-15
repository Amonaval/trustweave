import type {LaunchDataset,LaunchSeedCommitResult,LaunchSeedKind,LaunchSeedLineageRow,LaunchSeedOptions} from "../../core/launch-seed/contracts";
import {recordLaunchSeedLineage} from "./remote";
import {seedPayloadHash} from "./dataset";

type MutationResult=string|void|{id?:string|null;message?:string};
export class LaunchSeedRunner{
 readonly prior=new Map<string,LaunchSeedLineageRow>();created=0;updated=0;skipped=0;errors=0;warnings:string[]=[];completedSections:string[]=[];current=0;
 constructor(readonly data:LaunchDataset,readonly kind:LaunchSeedKind,lineage:LaunchSeedLineageRow[],readonly total:number,readonly options:LaunchSeedOptions={}){for(const row of lineage)this.prior.set(`${row.sectionKey}|${row.rowRef}`,row)}
 private progress(section:string,message:string){this.current++;this.options.onProgress?.({phase:"commit",section,current:this.current,total:this.total,message})}
 priorRow(section:string,rowRef:string){return this.prior.get(`${section}|${rowRef}`)}
 async remember(section:string,rowRef:string,payload:unknown,remoteId?:string|null,status:"committed"|"skipped"|"warning"="committed",message?:string){const payloadHash=seedPayloadHash(payload);await recordLaunchSeedLineage({datasetVersion:this.data.version,sectionKey:section,rowRef,payloadHash,remoteId,status,message});this.prior.set(`${section}|${rowRef}`,{sectionKey:section,rowRef,payloadHash,remoteId,status,lastMessage:message})}
 async warningRow(section:string,rowRef:string,payload:unknown,message:string,remoteId?:string|null){const hash=seedPayloadHash(payload),prior=this.priorRow(section,rowRef);if(prior?.payloadHash===hash){this.skipped++;this.progress(section,`Skipped ${rowRef} — unchanged warning.`);return}this.skipped++;this.warnings.push(message);await this.remember(section,rowRef,payload,remoteId||prior?.remoteId||null,"warning",message);this.progress(section,`Recorded constrained seed row ${rowRef}.`)}
 async row(section:string,rowRef:string,payload:unknown,mutate:(existingId?:string|null)=>Promise<MutationResult>,opts:{immutableAfterCreate?:boolean}={}){
  const hash=seedPayloadHash(payload),prior=this.priorRow(section,rowRef);
  if(prior?.payloadHash===hash){this.skipped++;this.progress(section,`Skipped ${rowRef} — unchanged.`);return prior.remoteId||undefined}
  if(prior&&opts.immutableAfterCreate){const msg=`${section}/${rowRef} already exists and the product API treats it as historical/immutable; changed source was not duplicated.`;this.skipped++;this.warnings.push(msg);await this.remember(section,rowRef,payload,prior.remoteId,"warning",msg);this.progress(section,`Skipped changed historical row ${rowRef}.`);return prior.remoteId||undefined}
  try{const result=await mutate(prior?.remoteId||null);const id=typeof result==="string"?result:result&&typeof result==="object"?result.id||undefined:prior?.remoteId||undefined;const message=result&&typeof result==="object"?result.message:undefined;await this.remember(section,rowRef,payload,id,"committed",message);if(prior)this.updated++;else this.created++;this.progress(section,`${prior?"Updated":"Created"} ${rowRef}.`);return id||undefined}catch(error:any){this.errors++;const msg=`${section}/${rowRef}: ${error?.message||String(error)}`;this.warnings.push(msg);this.progress(section,`Error on ${rowRef}.`);return undefined}
 }
 sectionDone(section:string){if(!this.completedSections.includes(section))this.completedSections.push(section)}
 result():LaunchSeedCommitResult{return {datasetVersion:this.data.version,kind:this.kind,created:this.created,updated:this.updated,skipped:this.skipped,errors:this.errors,warnings:this.warnings,completedSections:this.completedSections,message:`Launch seed completed: ${this.created} created, ${this.updated} updated, ${this.skipped} skipped, ${this.errors} errors.`}}
}
