# School Vertical Architecture Proof

**Mission:** M3-D11 — School Architecture Proof / Readiness Certification  
**Baseline:** `llm-push` after D10 at `c028220a6a8a5634c5db2482e4189584f0ed653d`  
**Decision:** **ARCHITECTURE READY FOR BOUNDED SCHOOL IMPLEMENTATION**  
**Product status:** School is still **not implemented, not registered, not enabled and not release-certified**.

## 1. What D11 proves

The School proving target can be expressed as a thin vertical over the D1–D10 Network OS architecture without requiring a second application architecture, a parallel workflow engine, a parallel authorization model, a new route grammar or universal bundle loading.

The representative scope has:

- **A — 1 workflow:** fully covered by an existing shared primitive;
- **B — 9 workflows:** existing shared primitive plus a thin School adapter;
- **C — 0 workflows:** no new reusable platform primitive required for the representative scope;
- **D — 2 supporting domain seams:** attendance recording and transport/pickup remain genuinely School-specific.

The earlier D0 finding that absence/homework/pickup lacked a proven shared lifecycle has materially changed: D4 introduced resource/purpose/time-aware policy and consent; D5 introduced tasks, acknowledgements, approvals, consent workflow, assignment, due/SLA timing and audit. Those additions remove the need to invent a new generic School workflow engine.

The machine-readable classification is `missions/mission-003/m3-d/D11-SCHOOL-WORKFLOW-MAP.json`.

## 2. Representative workflow classification

| Workflow | Class | Reuse | Thin School ownership |
| --- | --- | --- | --- |
| Student ↔ guardian relationships | **B** | Generic entities/relationships + D4 policy | Guardian/student vocabulary and exact resource policy |
| Class ↔ teacher scoping | **B** | Affiliations/groups + D4 policy | Class/cohort/teacher semantics |
| Notices + required actions | **B** | Activities, notifications, D5 task/acknowledgement | Audience resolution and School labels |
| Field-trip/activity consent | **B** | Event + D4 explicit consent + D5 consent workflow | Guardian/student/trip binding and purpose/expiry |
| Absence recovery | **B** | D5 task/assignment/due/audit | Projection from School attendance source |
| Homework/tasks | **B** | D5 task/assignee/due/audit | Learning content and class/student assignment |
| PTM continuity | **B** | Events + acknowledgement/task/audit | PTM slot/notes/follow-up visibility |
| School events/RSVP | **A** | Existing groups/events/RSVP | Labels/audience filtering only |
| Parent concerns/follow-through | **B** | Task/assignment/SLA/audit | Concern taxonomy and School response semantics |
| Student journey history | **B** | Activities/milestones/projections + D4 policy | Student milestone taxonomy and visibility |
| Attendance recording | **D** | Shared policy/command mechanics | `school.attendance` state/reason/correction semantics |
| Transport/pickup | **D** | Shared policy/consent/approval/notifications | `school.transport` route/stop/pickup/release semantics |

### Why category C is empty

D11 found no representative need that justifies another cross-product platform primitive before School begins.

This is significant. The architecture program was specifically intended to prevent School from forcing premature platform invention. The existing D4/D5 mechanics are now sufficient to compose the generic lifecycle requirements that were missing at D0.

If implementation later discovers a repeated mechanic proven in School **and** Housing/Community, it can be proposed as a new platform primitive with evidence. D11 does not create one speculatively.

## 3. School-owned capability boundary

The first School vertical may own one capability contract, conceptually `domain.school`, with thin internal modules.

The current proof identifies only two truly School-specific operational seams:

1. **Attendance**
   - present/absent/late/excused semantics;
   - correction rules;
   - reason vocabulary;
   - student/class/day scope.

2. **Transport / pickup**
   - route/stop assignment;
   - transport or pickup authorization;
   - release/hand-off state;
   - safety-specific policy.

Homework, notices, PTM, events, consent, concerns and journey history should **not** each become separate platform engines.

Future grading/assessment, timetable, fee/ERP, examination or LMS functionality is outside this proof. It must earn its own product/architecture justification rather than being assumed into the first School build.

## 4. D10 scaffold proof

`qa/fixtures/d11-school-blueprint.json` describes a School skeleton without registering it.

The blueprint declares:

- reused platform capabilities;
- one owned `domain.school` capability;
- route surfaces;
- policy/workflow/data adapter obligations;
- D9 observability journey/threshold;
- a deliberately synthetic Playground seed.

The D10 scaffold can:

- validate the School blueprint;
- produce a deterministic integration plan;
- generate vertical-local files in a temporary directory;
- keep School out of the live runtime tree.

The generated architecture requires the same five bounded central integration edits as any D10 thin vertical with a domain capability:

1. `core/verticals/kinds.ts`
2. `core/verticals/capability-manifest.ts`
3. `templates/productized/runtime-meta.ts`
4. `app-shell/vertical-manifest.ts`
5. `qa/runtime/catalog.mjs` only when connected QA is activated

No auto-discovery or hidden runtime registration is introduced.

## 5. Addressability proof

School uses the existing D1 grammar:

`/network/{networkId}/{surface}`

Initial surfaces proven by the blueprint are:

- `home`
- `students`
- `classes`
- `notices`
- `tasks`
- `ptm`
- `events`
- `attendance`
- `transport`
- `concerns`
- `guide`
- `admin`

The surface route is not an authorization boundary. Direct entry must pass membership + D4 policy + server/RLS authorization.

Resource-detail routes such as a specific student, consent or pickup authorization should only be added when the School capability exposes a stable opaque resource ID and a server-owned authorized lookup. D11 does not create unsafe ID-bearing URLs in advance.

## 6. Privacy proof

The School blueprint inherits the existing privacy rules:

- network membership does not imply access to every student;
- guardian access is resource/relationship scoped;
- teacher access is class/resource scoped;
- consent is purpose/time/resource scoped;
- direct URLs cannot bypass authorization;
- no cross-network profile pooling by default;
- School data stays network-local unless an explicit future bridge/consent contract says otherwise.

The D11 playground contains only synthetic people and relationships. It does not contain real students, guardians, staff or institutional records.

## 7. Runtime and scale proof

School remains absent from:

- `NETWORK_VERTICAL_KINDS`;
- `VERTICAL_MANIFEST`;
- productized runtime metadata;
- QA runtime catalog;
- `verticals/school`.

Therefore D11 itself adds **zero School production runtime import**.

When implementation begins, the D10 integration plan requires `lazy-vertical-ui`; D7's production First Load JS gate remains binding. The current D7 root baseline is 644 kB with a 700 kB ceiling.

School server reads/writes must inherit D6 server-owned boundaries, D8 pagination/work budgets and D9 operation/journey observability.

## 8. Readiness gates for implementation

D11 authorizes **bounded implementation**, not activation.

Before a School skeleton becomes active, implementation must provide and independently test:

- School D4 policy adapter;
- School D5 workflow adapter;
- server-owned D6 query/command boundary;
- additive schema/migrations where School-owned persistence is required;
- D9 operation metadata and journey instrumentation;
- D7 lazy-loading proof;
- representative route/direct-entry tests;
- role/resource authorization tests;
- synthetic Playground;
- connected browser QA before release.

The D10 blueprint intentionally reports these unresolved implementation blockers today:

- policy adapter not implemented;
- server API boundary not implemented;
- workflow adapter not implemented.

That is expected at D11. The architecture is certified because the responsibilities and interfaces are explicit and bounded, not because product code already exists.

## 9. Certification boundary

D11 does **not** certify:

- a School product;
- a production schema;
- real-school workflows;
- legal/compliance readiness for minors;
- connected authenticated browser behavior;
- staging database migrations;
- real performance/SLO achievement;
- the existing open migration-122 / two-vertical reliability staging gate.

Those remain separate execution/release evidence.

## 10. Final architecture conclusion

D0 asked whether School would force another large vertical application.

After D1–D10, the evidence says **no** for the representative School scope.

School can now begin as:

> a lazy-loaded, explicitly registered, policy-scoped vertical that reuses Network OS identity, relationships, groups/events, notifications, consent, workflows, routing, server API boundaries, scale budgets and observability — while keeping attendance and transport/pickup semantics School-owned.

That is sufficient to pass the architecture-readiness gate and proceed to a bounded School implementation mission.
