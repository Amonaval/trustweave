import type {WorkflowAssignee,WorkflowItem,WorkflowState} from "../../../core/workflow/contracts";
import type {HsBooking,HsComplaint} from "./operations-remote";
import type {HsGovernanceAction} from "./governance-remote";

function state(value:string):WorkflowState{
  const normalized=value.trim().toLowerCase();
  if(["resolved","closed","done","completed","confirmed","approved"].includes(normalized))return "completed";
  if(["cancelled","canceled","rejected","withdrawn"].includes(normalized))return "cancelled";
  if(["in_progress","in-progress","assigned","working"].includes(normalized))return "in_progress";
  return "open";
}
function assigneeForComplaint(item:HsComplaint):WorkflowAssignee|undefined{
  if(item.assignedVendorId)return {kind:"entity",id:item.assignedVendorId,label:item.assignedToLabel||undefined};
  if(item.assignedTo)return {kind:"user",id:item.assignedTo,label:item.assignedToLabel||undefined};
  return undefined;
}

export function projectHsComplaintWorkflow(networkId:string,item:HsComplaint):WorkflowItem{
  return {
    id:`housing-complaint:${item.id}`,networkId,kind:"task",title:item.title,state:state(item.status),
    source:{capability:"domain.housing-society",kind:"housing.complaint",id:item.id},
    assignee:assigneeForComplaint(item),slaDueAt:item.slaDueAt||undefined,outcome:item.resolutionNote||undefined,
    createdAt:item.createdAt,audit:[],
  };
}

export function projectHsAmenityApprovalWorkflow(networkId:string,item:HsBooking):WorkflowItem{
  return {
    id:`housing-amenity-booking:${item.id}`,networkId,kind:"approval",title:`Approve ${item.amenityName} booking`,
    state:state(item.status),source:{capability:"domain.housing-society",kind:"housing.amenity-booking",id:item.id},
    dueAt:item.startsAt,outcome:["approved","confirmed","rejected","cancelled","canceled"].includes(item.status.toLowerCase())?item.status:undefined,audit:[],
  };
}

export function projectHsGovernanceActionWorkflow(networkId:string,item:HsGovernanceAction):WorkflowItem{
  return {
    id:`housing-governance-action:${item.id}`,networkId,kind:"task",title:item.title,state:state(item.status),
    source:{capability:"domain.housing-society",kind:"housing.governance-action",id:item.id},
    assignee:item.ownerLabel?{kind:"external",id:item.ownerLabel,label:item.ownerLabel}:undefined,
    dueAt:item.dueOn||undefined,outcome:item.completionNote||undefined,audit:[],
  };
}
