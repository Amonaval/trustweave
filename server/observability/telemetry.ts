import {createHash} from "node:crypto";
import {ERROR_BUDGET_POLICY,SLO_MANIFEST,evaluateSloWindow,operationMeta,type SloEvent} from "../../core/observability/contracts";

type ApiObservation={
 kind:"query"|"command";name:string;requestId:string;actorId:string;networkId?:string;
 outcome:"success"|"failure";durationMs:number;errorCode?:string;idempotency?:string;
};
type StoredObservation=SloEvent&{kind:"query"|"command";name:string;capability:string;vertical:string;slow:boolean;timestamp:string};
type TelemetryStore={events:StoredObservation[]};
const root=globalThis as typeof globalThis&{__trustweaveTelemetry?:TelemetryStore};
const store=root.__trustweaveTelemetry||(root.__trustweaveTelemetry={events:[]});
const MAX_EVENTS=2000;

export function telemetryTag(value:string|undefined){return value?createHash("sha256").update(value).digest("hex").slice(0,16):undefined}

export function recordApiObservation(input:ApiObservation){
 const meta=operationMeta(input.kind,input.name);const timestamp=new Date().toISOString();const slow=input.durationMs>meta.slowMs;
 const event:StoredObservation={kind:input.kind,name:input.name,capability:meta.capability,vertical:meta.vertical,journey:meta.journey,outcome:input.outcome,durationMs:input.durationMs,slow,timestamp};
 store.events.push(event);if(store.events.length>MAX_EVENTS)store.events.splice(0,store.events.length-MAX_EVENTS);
 console.info(JSON.stringify({
  type:"network_os_observation",traceId:input.requestId,requestId:input.requestId,
  actorTag:telemetryTag(input.actorId),networkTag:telemetryTag(input.networkId),
  kind:input.kind,operation:input.name,capability:meta.capability,vertical:meta.vertical,journey:meta.journey,
  outcome:input.outcome,durationMs:input.durationMs,slow,errorCode:input.errorCode,
  ...(input.idempotency?{idempotency:input.idempotency}:{}),timestamp
 }));
}

function safeOperationalDetails(details:Record<string,unknown>){
 const out:Record<string,unknown>={};let count=0;
 for(const [key,value] of Object.entries(details)){
  if(count++>=20)break;
  if(/token|email|name|title|body|message|description|url|path|payload|content/i.test(key)){out[key]="[redacted]";continue}
  if(/actorid|userid|networkid/i.test(key)&&typeof value==="string"){out[key.replace(/id$/i,"Tag")]=telemetryTag(value);continue}
  if(["string","number","boolean"].includes(typeof value)||value===null)out[key]=value;
 }
 return out;
}
export function recordOperationalEvent(event:string,details:Record<string,unknown>={}){console.info(JSON.stringify({type:"network_os_operational",event,...safeOperationalDetails(details),timestamp:new Date().toISOString()}))}

export function processTelemetrySnapshot(){
 const events=[...store.events];
 const slow=events.filter(e=>e.slow).length,failures=events.filter(e=>e.outcome==="failure").length;
 const byJourney=Object.entries(events.reduce<Record<string,{total:number;failures:number;slow:number}>>((acc,e)=>{const row=acc[e.journey]||(acc[e.journey]={total:0,failures:0,slow:0});row.total++;if(e.outcome==="failure")row.failures++;if(e.slow)row.slow++;return acc},{})).map(([journey,v])=>({journey,...v}));
 const slos=SLO_MANIFEST.filter(s=>s.measurement==="server-runtime").map(s=>evaluateSloWindow(s,events));
 return {mode:"process-local-bounded",maxEvents:MAX_EVENTS,samples:events.length,failures,slow,byJourney,slos,errorBudgetPolicy:ERROR_BUDGET_POLICY};
}

export function resetProcessTelemetryForTests(){store.events.splice(0,store.events.length)}
