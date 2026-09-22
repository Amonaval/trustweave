import type {BackgroundJob,BackgroundJobReceipt} from "./contracts";
import {CommandError} from "../shared/errors";
import {recordOperationalEvent} from "../observability/telemetry";

// M5 establishes the seam only. Do not pretend post-response work is durable on serverless.
export function backgroundRuntimeHealth(){return {status:"unconfigured" as const,durable:false,mode:"none" as const}}
export async function dispatchBackgroundJob(job:BackgroundJob):Promise<BackgroundJobReceipt>{
 recordOperationalEvent("background_job_rejected",{jobName:job.name,networkId:job.networkId,requestId:job.requestId,reason:"runtime-not-configured"});
 throw new CommandError("BACKGROUND_RUNTIME_NOT_CONFIGURED","Background processing is not configured for this deployment.",503);
}
export async function runBoundedInlineJob<T>(work:()=>Promise<T>):Promise<T>{return work()}
