import {NextResponse} from "next/server";
import type {ApiFailure,ApiSuccess} from "../../core/api/contracts";
import {normalizeCommandError} from "./errors";
import {recordApiObservation,recordOperationalEvent} from "../observability/telemetry";
export function commandSuccess<T>(requestId:string,data:T,status=200){return NextResponse.json<ApiSuccess<T>>({ok:true,data,requestId},{status,headers:{"x-request-id":requestId}})}
export function commandFailure(requestId:string,error:unknown){const x=normalizeCommandError(error);return NextResponse.json<ApiFailure>({ok:false,error:{code:x.code,message:x.message},requestId},{status:x.status,headers:{"x-request-id":requestId}})}
export function logCommand(input:{requestId:string;actorId:string;command:string;networkId?:string;outcome:"success"|"failure";startedAt:number;errorCode?:string;idempotency?:"none"|"stored"|"cached"|"released"}){recordApiObservation({kind:"command",name:input.command,requestId:input.requestId,actorId:input.actorId,networkId:input.networkId,outcome:input.outcome,durationMs:Date.now()-input.startedAt,errorCode:input.errorCode,idempotency:input.idempotency})}
export function logQuery(input:{requestId:string;actorId:string;query:string;networkId?:string;outcome:"success"|"failure";startedAt:number;errorCode?:string}){recordApiObservation({kind:"query",name:input.query,requestId:input.requestId,actorId:input.actorId,networkId:input.networkId,outcome:input.outcome,durationMs:Date.now()-input.startedAt,errorCode:input.errorCode})}
export function logOperationalEvent(event:string,details:Record<string,unknown>={}){recordOperationalEvent(event,details)}
