import {test} from "node:test";
import {strict as assert} from "node:assert";
import {assignWorkflowItem,createWorkflowItem,transitionWorkflowItem,workflowTiming} from "../../core/workflow/runtime";
import {projectHsAmenityApprovalWorkflow,projectHsComplaintWorkflow,projectHsGovernanceActionWorkflow} from "../../verticals/housing-society/runtime/workflow";
import {projectCommunityEventAcknowledgement} from "../../verticals/family-association/runtime/workflow";

const networkId="12345678-1234-4123-8123-123456789abc";

test("shared workflow transitions are kind-aware, append audit and fail closed after terminal state",()=>{
 const item=createWorkflowItem({
  id:"task-1",networkId,kind:"task",title:"Inspect lift",
  state:"open",source:{capability:"domain.housing-society",kind:"housing.complaint",id:"c1"},
 },{actorUserId:"admin-1",at:"2026-09-19T10:00:00Z"});
 const assigned=assignWorkflowItem(item,{kind:"role",id:"maintenance",label:"Maintenance"},{actorUserId:"admin-1",at:"2026-09-19T10:01:00Z"});
 const started=transitionWorkflowItem(assigned,"start",{actorUserId:"worker-1",at:"2026-09-19T10:02:00Z"});
 const done=transitionWorkflowItem(started,"complete",{actorUserId:"worker-1",at:"2026-09-19T11:00:00Z",outcome:"Inspected and fixed"});
 assert.equal(done.state,"completed");
 assert.equal(done.outcome,"Inspected and fixed");
 assert.deepEqual(done.audit.map(x=>x.event),["created","assigned","start","complete"]);
 assert.throws(()=>transitionWorkflowItem(done,"complete"),/reopened/);
 assert.throws(()=>transitionWorkflowItem(item,"approve"),/not valid for task/);
});

test("assignment, due date and SLA are independent reusable mechanics",()=>{
 const item=createWorkflowItem({
  id:"task-2",networkId,kind:"task",title:"Repair pump",state:"open",
  source:{capability:"domain.housing-society",kind:"housing.complaint",id:"c2"},
  dueAt:"2026-09-20T12:00:00Z",slaDueAt:"2026-09-19T12:00:00Z",
 },{at:"2026-09-19T09:00:00Z"});
 assert.deepEqual(workflowTiming(item,"2026-09-19T13:00:00Z"),{due:"pending",sla:"breached"});
 assert.equal(assignWorkflowItem(item,{kind:"entity",id:"vendor-1"}).assignee?.id,"vendor-1");
});

test("Housing complaint, amenity approval and governance action keep domain semantics in thin projections",()=>{
 const complaint=projectHsComplaintWorkflow(networkId,{
  id:"c1",category:"Lift",title:"Lift vibration",priority:"high",status:"in_progress",
  slaDueAt:"2026-09-19T12:00:00Z",assignedVendorId:"vendor-1",assignedToLabel:"Kone",
  createdAt:"2026-09-19T09:00:00Z",updatedAt:"2026-09-19T10:00:00Z",
 });
 assert.equal(complaint.kind,"task");
 assert.equal(complaint.state,"in_progress");
 assert.equal(complaint.assignee?.id,"vendor-1");
 assert.equal(complaint.slaDueAt,"2026-09-19T12:00:00Z");
 assert.equal(complaint.audit.length,0);

 const booking=projectHsAmenityApprovalWorkflow(networkId,{
  id:"b1",amenityId:"a1",amenityName:"Clubhouse",startsAt:"2026-09-21T18:00:00Z",endsAt:"2026-09-21T22:00:00Z",status:"pending",
 });
 assert.equal(booking.kind,"approval");
 assert.equal(booking.state,"open");

 const action=projectHsGovernanceActionWorkflow(networkId,{id:"g1",title:"Publish minutes",ownerLabel:"Secretary",dueOn:"2026-09-25",status:"open"});
 assert.equal(action.assignee?.label,"Secretary");
 assert.equal(action.dueAt,"2026-09-25");
});

test("Family Community RSVP is an acknowledgement obligation, not a Housing workflow clone",()=>{
 const open=projectCommunityEventAcknowledgement(networkId,{id:"e1",networkId,type:"event",title:"Community dinner",startsAt:"2026-09-25T18:00:00Z",myRsvp:null},"member-1");
 assert.equal(open.kind,"acknowledgement");
 assert.equal(open.state,"open");
 assert.equal(open.source.capability,"community.groups-events");
 const responded=projectCommunityEventAcknowledgement(networkId,{id:"e1",networkId,type:"event",title:"Community dinner",startsAt:"2026-09-25T18:00:00Z",myRsvp:"going"},"member-1");
 assert.equal(responded.state,"completed");
 assert.equal(responded.outcome,"rsvp:going");
});

test("consent obligations reuse D4 consent vocabulary without inventing a second authorization engine",()=>{
 const consent=createWorkflowItem({
  id:"consent-1",networkId,kind:"consent",title:"Share emergency contact for trip",state:"open",
  source:{capability:"identity.privacy",kind:"consent.request",id:"consent-1"},
  consent:{subjectUserId:"student-1",granteeUserId:"teacher-1",capability:"identity.privacy",action:"contact.read",purpose:"trip-safety",resource:{networkId,kind:"student",id:"student-1"}},
 },{at:"2026-09-19T10:00:00Z"});
 assert.equal(consent.consent?.purpose,"trip-safety");
 assert.equal(transitionWorkflowItem(consent,"complete",{at:"2026-09-19T10:05:00Z",outcome:"consent-recorded"}).outcome,"consent-recorded");
});
