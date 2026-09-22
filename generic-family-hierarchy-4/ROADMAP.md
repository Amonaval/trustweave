# TrustWeave — Roadmap

## Current priority — V1 Network Activation Autopilot (2026-09-22)

TrustWeave is still pre-release. Network Activation should therefore receive **one bounded 20–30% effort / 70–80% impact slice**, not a full transformation-platform program.

### NAA-L1 — Lean Source Mapping Bridge — SOURCE IMPLEMENTED

Prove only this:

> Can a user bring an ordinary supported Excel/CSV, confirm a small source → TrustWeave mapping, and get a safe normalized activation candidate without manually migrating hundreds/thousands of rows?

In scope:

- XLSX/CSV upload using existing spreadsheet plumbing;
- sheet/header selection or cheap detection;
- source-column → target-field mapping UI;
- reuse existing/open-source mapping/validation capability where it actually saves work;
- user confirm/change/ignore;
- deterministic application across all rows;
- explicit unresolved/missing-data summary;
- safe normalized preview/output for the existing governed compiler.

Not required for this alpha slice:

- smart pattern-repair engine;
- persistent recipes;
- drift detection;
- separate standalone-engine repository;
- arbitrary external target Y;
- multi-file orchestration;
- PDF/OCR/connectors;
- AI/LLM semantic inference;
- migration 124 / database activation.

### Stop condition

Source implementation now covers the bounded slice above. Network Activation is **parked for portfolio re-selection**; synthetic/browser proof may be run when we intentionally validate this area, but no follow-on feature mission is implied.

Open items remain visible in `docs/product/PRODUCT-WORKSTREAM-TRACKER.md`; they are not an instruction to continue this category.

Detailed product learning:

- `docs/product/V1-NETWORK-ACTIVATION-AUTOPILOT.md`
- `docs/product/NETWORK-ACTIVATION-AUTOPILOT-DISCUSSION-SYNTHESIS-AND-MISSION-QUEUE.md`
- `docs/product/GENERIC-DATA-TRANSFORMATION-ENGINE-THESIS.md`

## D12 architecture/recoverability — review-closed

D12 successfully demonstrated fresh-project structural/security/API-contract parity. Formal exhaustive browser certification remains deferred by Founder decision, not falsely complete. The historical golden Supabase remains the preferred real environment for existing data/users; the D12 project remains a recovery/reference environment. Restart D12 only for a concrete product/recovery reason.


## Active architecture priority — M3-D (2026-09-19)

D0–D11 are implemented as the architecture reinforcement program. D11's School proof classifies the representative scope as A=1, B=9, C=0, D=2 and certifies the platform architecture for bounded School implementation while keeping School completely unregistered/unimplemented. The next School program must follow `missions/mission-003/m3-d/NEXT-SESSION-SCHOOL-IMPLEMENTATION-CHARTER.md`: scaffold first, then policy/graph, server-owned data boundaries, shared actions/consent, the two School-specific seams (attendance and transport/pickup), and only then synthetic Playground/connected activation gates. `missions/mission-003/m3-d/EXECUTION-CHARTER.md` gives the revised sequence; `NETWORK-OS-ARCHITECTURE-MASTER-PLAN.md` retains the older D1–D10 labels as historical strategy, explicitly shifted by one. The connected Residential/Community reliability and staging migration 122 gate below still require real evidence.

**Updated:** 2026-09-16

## North star — Founder Spectator Mode

TrustWeave is becoming an AI-operated company, not only an AI-assisted codebase. The founder owns vision, values and irreversible boundaries; AI becomes the default operating layer for strategy, product, architecture, engineering, QA, criticism, release, knowledge and continuous improvement.

The success test is simple: give the system one meaningful outcome and watch it move from evidence → decision → mission → code → verification → independent review → release-ready evidence with **zero manual error relay** and no more than one optional founder intervention.

## Active program — M3-C Autonomous Company Runtime

### C0 — Control Surface Reset — VERIFY
- root Markdown 34 → 10;
- legacy root docs preserved under one obvious history landing zone;
- active governance moved under `governance/`;
- mission registry + generic mission CLI;
- mission-specific source validation;
- autonomy policy + Founder Spectator Mode program.

### C1 — Company Brain & Durable Mission Governor
Build crash-safe persistent mission state and generic `create → plan → run → resume → next → close` workflows. A new session/process must resume from repository state without depending on chat memory.

### C2 — AI Executive Council
Introduce structured role-separated decision cycles: CEO, Chief of Staff, CTO/Architect, CPO/User Advocate and Critic/Red Team. Require alternatives, dissent, evidence, decision class and explicit reason for the selected plan.

### C3 — Autonomous Environment & Toolchain Manager
Make dependency restore, app/preview startup, QA preconditions, disposable test resources, browser execution, evidence collection and cleanup part of the mission runtime. This is the direct path to eliminating manual B6 runtime relay.

### C4 — Self-Healing Engineering Swarm
Decompose approved missions into bounded work packages, support parallel builders where safe, classify failures, repair within budget and integrate without silent scope expansion.

### C5 — Autonomous User / Pilot / Product Critic
Use realistic Chairman, President, admin, representative, resident/member and ordinary-user journeys to discover friction before coding. Convert reproducible findings into ranked opportunity missions.

### C6 — Independent Risk & Review Board
Operationally separate final review from building. Activate architecture, security/privacy, data/migration, UX/accessibility and performance lenses by risk.

### C7 — Autonomous Release, Rollback & Incident Loop
Executable preview/release rehearsal, smoke validation, migration/rollback plans, incident classification and repair missions.

### C8 — Company Memory & Learning Engine
Persist decisions, failures, metrics, user findings and outcomes so future missions automatically reuse relevant lessons instead of reloading history manually.

### C9 — Founder Spectator Cockpit
One surface for active missions, executive debate, decisions, evidence, blockers, autonomy score, human interventions, costs and the next proposed move.

### C10 — Zero-Touch Mission Demonstration
Run one substantial TrustWeave product/architecture improvement from founder intent to release-ready candidate with zero manual error relay, independent review and runtime proof.

### C11 — Continuous Autonomous Portfolio Loop
Within delegated authority/budget, AI observes evidence, selects the next highest-value bounded mission, executes it, measures outcome and continues. Founder interaction becomes summary/oversight by default.

Machine-readable program: `missions/mission-003/m3-c/mission-set.json`.

## Protected parallel obligations

M3-C does not erase prior truth. B6 must still complete its dependency/runtime/independent-review certification before formal closure. Mission 1/2 runtime evidence remains pending where previously recorded. No autonomy milestone may weaken tenant isolation, migration immutability, privacy, evidence quality or release gates.

## Active product priority — two-vertical reliability

The autonomous-company proof does not replace product work. The active execution priority is now:

1. Residential / Housing Society and Family Community connected reliability;
2. deterministic critical journeys plus checkpointed crawling;
3. verified product-defect repair with permanent regression assertions;
4. then resume the remaining reusable component/CSS convergence on the stable baseline.

Connected QA scope is controlled from root `qa.config.mjs`; platform-wide contracts continue to protect all registered verticals.

The first connected pass is complete. Repair batch R1-A addresses the verified Housing snapshot regression, missing notification-role RPC, persistence-helper race and two accessibility contrast findings. Exit now requires applying additive migration 122 to dedicated staging, rerunning the impacted journeys/Axe checks, and resolving the still-unclassified `family-association/admin` crawler shard before the full two-vertical closure run.

## Protected product architecture program

The pre-autonomy reusable architecture program remains binding. M3-B6 completed only the first technical-primitives slice; remaining work proceeds incrementally after/alongside reliability:

- workspace-shell convergence;
- async lifecycle/state normalization;
- shared business/use-case components where Housing and Family Community semantics genuinely match;
- incremental CSS ownership normalization;
- component contract documentation and isolated scenarios/Storybook only if it materially helps;
- later plugin/lazy-loading and modular SQL-source architecture after regression protection is strong.

## Legacy certification anchors
These exact historical labels remain only for accepted source-gate compatibility; the active program above is authoritative.
- Mission 2 — Slow Full Product User Regression — IMPLEMENTED IN SOURCE
- Mission 3 — Agentic Company & Engineering OS + architecture convergence

## Autonomous Company progress — 2026-09-16

- **Generation 1 complete (C1–C4):** durable governor, executive council, environment manager, self-healing engineering.
- **Generation 2 next (C5–C7):** autonomous user/pilot critic, independent risk board, release/rollback/incident loop.
- **Generation 3 (C8–C10):** durable learning, Founder cockpit, zero-touch product mission.
- **Later C11:** continuous portfolio selection only after C10 demonstrates bounded end-to-end autonomy.

Generation 2 is now complete. C8 must make the existing decisions, failures, opportunities and incident lessons searchable and automatically relevant to planning. C9 turns that state into one human-facing cockpit. C10 then consumes the highest-value safe opportunity and demonstrates the entire loop on a real TrustWeave change.

Generation 3 is complete pending final candidate closure. The next roadmap decision returns to the Founder/company portfolio: pilot rollout remains gated by explicit production authority, while routine discovery, debate, implementation, browser QA, review and packaging can now proceed autonomously.

## Parallel commercial discovery track — product-thesis, not current execution authority

The active reliability / architecture program above remains engineering authority. In parallel, validate the first paid wedge before authorizing another broad vertical.

1. Interview / observe 3–5 founder-led multi-location operators.
2. Obtain hierarchy, weekly MIS, SOP/audit, issue tracker, compliance calendar and review workflow from at least one design partner.
3. Map the buyer's Monday-morning operating review to existing TrustWeave primitives.
4. Seek a concrete pull signal: data access, design-partner commitment, LOI, paid discovery or paid trial.
5. Only then authorize the smallest TrustWeave Ops slice: location hierarchy, audit/SOP, issue/corrective action, compliance/renewals, exception dashboard, AI COO brief.
6. Measure manual follow-ups removed, closure time, leadership time saved and willingness to renew/pay.
7. Expand toward a Promoter / Business Group Command Center only after connector/data-quality maturity.

This track must not interrupt current Residential / Family Community reliability work or database/bootstrap closure.


## Parallel strategic validation track — AI-native Trusted Network Intelligence

**Product-thesis only; not current execution authority.**

TrustWeave will evaluate whether its strongest long-term differentiation is a shared **Intelligence Fabric for trusted human networks**: member/network agents operating over explicit intent, verified trust paths, institutional memory, consent, permissions and federated network boundaries.

Current working portfolio decision:

- active engineering remains reliability / architecture / D12 closure;
- AI Trusted Network Intelligence Fabric is the highest-upside long-term thesis to validate;
- TrustWeave Ops remains the strongest near-term monetization hypothesis;
- Family + Community become natural proving grounds for trust/intent/consent;
- Residential remains an operational proving ground.

Validation sequence before broad implementation:

1. define intent, consent, trust-path and match-explanation semantics;
2. prototype one synthetic "I need help" flow;
3. test with neutral users against directory/group-broadcast alternatives;
4. run a bounded human-reviewed Community/Association pilot;
5. separately prove a Network Agent job such as meeting preparation or institutional-memory retrieval;
6. test cross-network federation only after two networks independently produce local value;
7. re-score the portfolio using observed outcome, trust and willingness-to-pay evidence.

Canonical strategy:
- docs/product/TRUSTWEAVE-AI-NATIVE-TRUSTED-NETWORK-INTELLIGENCE-THESIS.md
- docs/product/TRUSTWEAVE-PRODUCT-THESIS-EVALUATION-PORTFOLIO.md

## Cross-workstream backlog authority

Use `docs/product/PRODUCT-WORKSTREAM-TRACKER.md` to retain open work across Network Activation, verticals, architecture, reliability and product-thesis areas.

A backlog item is not active merely because it is documented.
