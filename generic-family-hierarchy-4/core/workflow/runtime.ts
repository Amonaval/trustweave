import type {
  WorkflowActionKind,
  WorkflowAssignee,
  WorkflowAuditEntry,
  WorkflowItem,
  WorkflowState,
  WorkflowTiming,
  WorkflowTransition,
} from "./contracts";

const allowedTransitions:Record<WorkflowActionKind,readonly WorkflowTransition[]>={
  task:["start","complete","cancel","reopen"],
  acknowledgement:["acknowledge","cancel","reopen"],
  approval:["start","approve","reject","cancel","reopen"],
  consent:["start","complete","cancel","reopen"],
};

function instant(value:string|undefined,label:string):number|null{
  if(!value)return null;
  const parsed=Date.parse(value);
  if(!Number.isFinite(parsed))throw new Error(`Invalid ${label} timestamp.`);
  return parsed;
}
function iso(value:string|undefined):string{
  const parsed=instant(value,"workflow audit");
  return parsed===null?new Date().toISOString():new Date(parsed).toISOString();
}
function validate(item:WorkflowItem):void{
  if(!item.id.trim()||!item.networkId.trim()||!item.title.trim()||!item.source.capability.trim()||!item.source.kind.trim()||!item.source.id.trim())throw new Error("Incomplete workflow item.");
  if(item.consent&&item.kind!=="consent")throw new Error("Consent requirements belong to consent workflow items.");
  instant(item.dueAt,"workflow due");
  instant(item.slaDueAt,"workflow SLA");
}
function append(item:WorkflowItem,entry:WorkflowAuditEntry):WorkflowItem{
  return {...item,audit:[...item.audit,entry]};
}
function targetState(event:WorkflowTransition):WorkflowState{
  if(event==="start")return "in_progress";
  if(event==="cancel")return "cancelled";
  if(event==="reopen")return "open";
  return "completed";
}

export function createWorkflowItem(item:Omit<WorkflowItem,"audit">,options:{actorUserId?:string;at?:string}={}):WorkflowItem{
  const created:WorkflowItem={...item,audit:[]};
  validate(created);
  return append(created,{event:"created",at:iso(options.at||item.createdAt),actorUserId:options.actorUserId,toState:item.state});
}

export function assignWorkflowItem(item:WorkflowItem,assignee:WorkflowAssignee,options:{actorUserId?:string;at?:string;note?:string}={}):WorkflowItem{
  validate(item);
  if(item.state==="completed"||item.state==="cancelled")throw new Error("Terminal workflow items cannot be reassigned.");
  if(!assignee.id.trim())throw new Error("Workflow assignee id is required.");
  return append({...item,assignee},{event:"assigned",at:iso(options.at),actorUserId:options.actorUserId,fromState:item.state,toState:item.state,note:options.note});
}

export function transitionWorkflowItem(item:WorkflowItem,event:WorkflowTransition,options:{actorUserId?:string;at?:string;note?:string;outcome?:string}={}):WorkflowItem{
  validate(item);
  if(!allowedTransitions[item.kind].includes(event))throw new Error(`Transition ${event} is not valid for ${item.kind}.`);
  const terminal=item.state==="completed"||item.state==="cancelled";
  if(event==="reopen"){
    if(!terminal)throw new Error("Only terminal workflow items can be reopened.");
  }else if(terminal){
    throw new Error("Terminal workflow items must be reopened before another transition.");
  }
  if(event==="start"&&item.state!=="open")throw new Error("Only open workflow items can be started.");
  const next=targetState(event),at=iso(options.at);
  const outcome=options.outcome??(event==="approve"?"approved":event==="reject"?"rejected":event==="acknowledge"?"acknowledged":event==="cancel"?"cancelled":item.outcome);
  const updated:WorkflowItem={
    ...item,
    state:next,
    outcome:event==="reopen"?undefined:outcome,
    completedAt:next==="completed"?at:undefined,
  };
  return append(updated,{event,at,actorUserId:options.actorUserId,fromState:item.state,toState:next,note:options.note});
}

export function workflowTiming(item:WorkflowItem,nowValue?:string):WorkflowTiming{
  validate(item);
  if(item.state==="completed"||item.state==="cancelled")return {due:"closed",sla:"closed"};
  const now=instant(nowValue,"workflow now")??Date.now(),due=instant(item.dueAt,"workflow due"),sla=instant(item.slaDueAt,"workflow SLA");
  return {
    due:due===null?"none":now>due?"overdue":"pending",
    sla:sla===null?"none":now>sla?"breached":"within",
  };
}
