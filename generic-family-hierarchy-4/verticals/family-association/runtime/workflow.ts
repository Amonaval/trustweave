import type {NetworkActivity} from "../../../core/network-os/contracts";
import type {WorkflowItem} from "../../../core/workflow/contracts";

export function projectCommunityEventAcknowledgement(networkId:string,item:NetworkActivity,actorUserId?:string):WorkflowItem{
  if(item.type!=="event")throw new Error("Only community events can become RSVP acknowledgements.");
  if(item.networkId&&item.networkId!==networkId)throw new Error("Community event belongs to another network.");
  return {
    id:`community-event-rsvp:${item.id}`,networkId,kind:"acknowledgement",title:item.title,
    state:item.myRsvp?"completed":"open",
    source:{capability:"community.groups-events",kind:"community.event",id:item.id},
    assignee:actorUserId?{kind:"user",id:actorUserId}:undefined,dueAt:item.startsAt||undefined,
    outcome:item.myRsvp?`rsvp:${item.myRsvp}`:undefined,createdAt:item.createdAt||undefined,audit:[],
  };
}
