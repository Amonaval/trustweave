import type {RequestContext} from "./request-context";
import {createRequestContext} from "./request-context";
import {commandFailure,commandSuccess,logQuery} from "./response";
import {enforceScopedBurstLimit} from "./rate-limit";
import {SCALE_BUDGETS} from "../../core/scale/contracts";
import {normalizeCommandError} from "./errors";

type QueryRuntimeOptions<TResult>={
 request:Request;
 queryName:string;
 execute:(ctx:RequestContext)=>Promise<TResult>;
 rateLimit?:{limit:number;networkLimit?:number;windowMs?:number};
 networkId?:(result:TResult,ctx:RequestContext)=>string|undefined;
};

export async function executeQuery<TResult>(o:QueryRuntimeOptions<TResult>){
 let requestId=o.request.headers.get("x-request-id")||crypto.randomUUID();
 let ctx:RequestContext|null=null;
 try{
  ctx=await createRequestContext(o.request);
  requestId=ctx.requestId;
  enforceScopedBurstLimit({actorId:ctx.user.id,networkId:ctx.activeNetworkId,operation:o.queryName,actorLimit:o.rateLimit?.limit??SCALE_BUDGETS.queryActorPerMinute,networkLimit:o.rateLimit?.networkLimit??SCALE_BUDGETS.queryNetworkPerMinute,windowMs:o.rateLimit?.windowMs});
  const data=await o.execute(ctx);
  logQuery({requestId,actorId:ctx.user.id,query:o.queryName,networkId:o.networkId?.(data,ctx)||ctx.activeNetworkId,outcome:"success",startedAt:ctx.startedAt});
  return commandSuccess(requestId,data);
 }catch(error){
  const normalized=normalizeCommandError(error);
  if(ctx)logQuery({requestId,actorId:ctx.user.id,query:o.queryName,networkId:ctx.activeNetworkId,outcome:"failure",startedAt:ctx.startedAt,errorCode:normalized.code});
  return commandFailure(requestId,normalized);
 }
}
