import type {RequestContext} from "./request-context";
import {createRequestContext} from "./request-context";
import {commandFailure,commandSuccess,logQuery} from "./response";
import {enforceBurstLimit} from "./rate-limit";
import {normalizeCommandError} from "./errors";

type QueryRuntimeOptions<TResult>={
 request:Request;
 queryName:string;
 execute:(ctx:RequestContext)=>Promise<TResult>;
 rateLimit?:{limit:number;windowMs?:number};
 networkId?:(result:TResult,ctx:RequestContext)=>string|undefined;
};

export async function executeQuery<TResult>(o:QueryRuntimeOptions<TResult>){
 let requestId=o.request.headers.get("x-request-id")||crypto.randomUUID();
 let ctx:RequestContext|null=null;
 try{
  ctx=await createRequestContext(o.request);
  requestId=ctx.requestId;
  enforceBurstLimit(`${ctx.user.id}:${o.queryName}`,o.rateLimit?.limit??60,o.rateLimit?.windowMs??60_000);
  const data=await o.execute(ctx);
  logQuery({requestId,actorId:ctx.user.id,query:o.queryName,networkId:o.networkId?.(data,ctx)||ctx.activeNetworkId,outcome:"success",startedAt:ctx.startedAt});
  return commandSuccess(requestId,data);
 }catch(error){
  const normalized=normalizeCommandError(error);
  if(ctx)logQuery({requestId,actorId:ctx.user.id,query:o.queryName,networkId:ctx.activeNetworkId,outcome:"failure",startedAt:ctx.startedAt,errorCode:normalized.code});
  return commandFailure(requestId,normalized);
 }
}
