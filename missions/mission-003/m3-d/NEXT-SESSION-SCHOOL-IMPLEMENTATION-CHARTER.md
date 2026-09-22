# Next Session — School Vertical Implementation Charter

## Entry condition

M3-D11 architecture readiness has passed. This authorizes a **bounded School implementation program**; it does not authorize production release or use of real student data.

## Non-negotiable baseline

Start from the latest `llm-push` branch. Use:

- `docs/architecture/SCHOOL-VERTICAL-ARCHITECTURE-PROOF.md`;
- `missions/mission-003/m3-d/D11-SCHOOL-WORKFLOW-MAP.json`;
- `qa/fixtures/d11-school-blueprint.json`;
- D10 Thin-Vertical Developer Contract.

Do not create a second School application architecture.

## First implementation sequence

### S0 — Scaffold + compile-time registration

Use the D10 School blueprint to create the vertical skeleton. Add only the explicit central registrations produced by the D10 integration plan. Keep the runtime lazy.

Exit:
- School appears as a skeleton only;
- no real data;
- no direct UI RPC;
- D7 root budget stays green.

### S1 — School identity / graph / policy

Implement synthetic student, guardian, teacher and class relationships over generic entities/affiliations. Add the School D4 policy adapter for guardian/student and teacher/class resource scoping.

Exit:
- cross-student and cross-class denial tests;
- owner/admin override rules explicit;
- route direct entry cannot widen access.

### S2 — Server-owned School data boundary

Add the minimal additive School schema and D6 server query/command APIs needed by the first flows. No historical migration edits.

Start with only data proven necessary for:
- attendance source records;
- School tasks/notices projection;
- concerns if required by the first pilot slice.

Exit:
- no new UI `.rpc(...)`;
- idempotent mutations;
- RLS/security tests;
- migration static/replay evidence.

### S3 — Shared actions + consent

Use D5 workflow primitives for homework/tasks, notices requiring acknowledgement, field-trip consent, absence recovery and PTM follow-up.

Do not create separate School task/approval/consent engines.

### S4 — School-only seams

Implement only the D11 category-D modules:

- `school.attendance`;
- `school.transport`.

Keep their mechanics thin and reuse D4/D5/D6/D9 infrastructure.

### S5 — Playground + QA + activation gate

Use only synthetic records for the initial Playground. The illustrative school context must not claim to represent a real institution.

Run:
- unit/architecture gates;
- route/direct-entry tests;
- policy matrix;
- resilient crawl;
- production build/bundle budget;
- connected browser QA when credentials/environment are available.

Only then change School from skeleton to active.

## Explicitly out of scope for the first School program

Do not add by default:

- grading/examination ERP;
- fee/accounting ERP;
- timetable engine;
- full LMS/content platform;
- payroll/HR;
- biometric attendance;
- live vehicle tracking;
- AI access to cross-student data without explicit resource authorization.

Any of these needs a separate product-value and architecture decision.

## Founder checkpoint

Escalate only if implementation discovers a genuine D3 decision: minors/privacy/compliance commitment, recurring infrastructure spend, destructive production action, or a trade-off that changes the Network OS thesis. Routine design/test/repair remains autonomous.
