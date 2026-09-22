import type {PolicyResourceRef} from "../authorization/policy";

export type WorkflowActionKind="task"|"acknowledgement"|"approval"|"consent";
export type WorkflowState="open"|"in_progress"|"completed"|"cancelled";
export type WorkflowTransition="start"|"acknowledge"|"approve"|"reject"|"complete"|"cancel"|"reopen";

export type WorkflowSourceRef=Readonly<{
  capability:string;
  kind:string;
  id:string;
}>;

export type WorkflowAssignee=Readonly<{
  kind:"user"|"role"|"entity"|"external";
  id:string;
  label?:string;
}>;

export type WorkflowConsentRequirement=Readonly<{
  subjectUserId:string;
  granteeUserId:string;
  capability:string;
  action:string;
  purpose:string;
  resource?:PolicyResourceRef;
}>;

export type WorkflowAuditEntry=Readonly<{
  event:"created"|"assigned"|WorkflowTransition;
  at:string;
  actorUserId?:string;
  fromState?:WorkflowState;
  toState?:WorkflowState;
  note?:string;
}>;

export type WorkflowItem=Readonly<{
  id:string;
  networkId:string;
  kind:WorkflowActionKind;
  title:string;
  state:WorkflowState;
  source:WorkflowSourceRef;
  assignee?:WorkflowAssignee;
  dueAt?:string;
  slaDueAt?:string;
  consent?:WorkflowConsentRequirement;
  outcome?:string;
  createdAt?:string;
  completedAt?:string;
  audit:readonly WorkflowAuditEntry[];
}>;

export type WorkflowTiming=Readonly<{
  due:"none"|"pending"|"overdue"|"closed";
  sla:"none"|"within"|"breached"|"closed";
}>;
