# TrustWeave — Mission Lifecycle

**Status:** BINDING — M3-B1/B2 accepted for execution  
**Applies to:** material product, architecture, data, security, UX and engineering missions.

## 1. Canonical state machine

```text
INTAKE
-> DISCOVERY
-> ARCHITECTURE
-> PLAN
-> IMPLEMENT
-> VERIFY
-> REVIEW
-> HARDEN
-> DOCUMENT
-> RELEASE
-> OBSERVE
-> CLOSE
```

A low-risk mission may combine DISCOVERY+ARCHITECTURE or REVIEW+HARDEN, but it may not skip required evidence.

## 2. State contracts

| State | Entry | Permitted lead | Required output | Exit / automated gate | Human gate |
|---|---|---|---|---|---|
| INTAKE | founder intent/backlog item | Mission Lead | outcome, scope hypothesis, risk | mission is bounded and testable | strategic ambiguity only |
| DISCOVERY | bounded intake | Mission Lead + Architecture | baseline/source inventory | affected surfaces/dependencies known | none |
| ARCHITECTURE | discovered scope | Architecture Governor | boundary decision/ADR if needed | constitution compliance | constitution/high-risk ADR |
| PLAN | architecture accepted | Mission Lead | implementation steps, acceptance, gate matrix, rollback | plan covers all affected owners | material scope/cost change |
| IMPLEMENT | accepted plan | Builder | commits/tests | local/targeted prechecks pass | none |
| VERIFY | candidate commit | Verification | evidence + failure classification | all mandatory mission gates green | protected environment authorization if needed |
| REVIEW | verified candidate | Independent Reviewer | approve/findings | no blocking findings | unresolved high-risk disagreement |
| HARDEN | findings/edge cases | Builder + Verification | repairs/regression proof | regression/security/data gates green | only if scope changes |
| DOCUMENT | candidate stable | Release & Knowledge | synchronized canonical truth + evidence manifest | doc drift gate green | none |
| RELEASE | evidence complete | Release Agent / human | deploy/release record | release policy satisfied | production release at current maturity |
| OBSERVE | release deployed | Verification/Incident | telemetry/runtime observation | agreed observation window/outcome | serious incident/risk acceptance |
| CLOSE | observation complete | Release & Knowledge | close record, archive evidence, next decision | no open mandatory evidence | none |

## 3. Mission contract

Every material mission must have one canonical mission record containing:
- ID and title;
- desired product/engineering outcome;
- included scope;
- excluded/deferred scope;
- affected owners/layers;
- invariants;
- risk class;
- architecture/ADR requirement;
- acceptance criteria;
- mandatory gates;
- runtime environment requirement;
- rollback strategy;
- human approval gates;
- human-intervention budget;
- status;
- candidate commit SHA when execution starts.

Markdown is the human-readable source. A small generated JSON evidence manifest may be used for machine checks.

## 4. Risk classes

### R0 — Documentation/analysis only
No production source/runtime/data change.

### R1 — Low-risk refactor
No business behavior, data model, authorization or public contract change.

### R2 — Product behavior change
User-visible behavior or shared contract change without sensitive data/permission change.

### R3 — Sensitive
Auth, privacy, RLS, storage, migration, destructive lifecycle, cross-tenant/federation or high-impact release behavior.

Risk determines mandatory reviewers and environments.

## 5. Evidence contract

A gate result is valid only when evidence records:
- mission ID;
- commit SHA;
- command/check name;
- environment/target identity class;
- timestamp;
- result;
- relevant artifact paths;
- blocker/finding severity;
- whether the result is source/static or runtime.

No document may convert source evidence into runtime certification.

## 6. Release rule

A mission may be code-complete while not release-complete.

Release requires:
- all mandatory gates green;
- no unaccepted P0/P1;
- independent review;
- required runtime evidence;
- documentation synchronized;
- rollback known;
- explicit approval gate satisfied.

## 7. First agent-governed experiment

### Mission
**M3-B6-E1 — Progressive Selector Convergence**

Purpose: test the Company OS with a low-risk M3-A refactor, not merely remove a duplicate component.

### Scope
Included:
- migrate Housing Finance, Governance and Security from `HousingSectionTabs` to canonical `ResponsiveSectionTabs`;
- preserve existing labels, active states and responsive behavior;
- remove `HousingSectionTabs` after zero consumers;
- remove only duplicate `hs-section-tab-*` mechanics made obsolete by the migration;
- add/adjust targeted architecture regression checks.

Excluded:
- business logic changes;
- SQL/migrations;
- wording/product-scope change;
- workspace-shell extraction;
- broad CSS reorganization;
- new vertical work.

### Risk
R1 — low-risk refactor.

### Participating roles
- Mission Lead;
- Architecture Governor;
- Builder;
- Independent Reviewer;
- Verification Agent;
- Release & Knowledge Agent.

No dedicated Security/Data agent is required unless the diff unexpectedly touches those boundaries.

### Mandatory evidence
- zero remaining `HousingSectionTabs` consumers;
- canonical responsive selector contract used by the three Housing panels;
- targeted source/architecture gate;
- `validate:ux-progressive`;
- TypeScript/static check for touched application;
- relevant Housing source gate(s);
- Family Community/shared selector regression check where shared CSS is touched;
- desktop + mobile rendered check of the three affected Housing surfaces in a dependency-enabled runtime;
- no SQL/migration diff;
- independent review finding count: zero blocking.

### Rollback
Single mission branch/PR. Revert the PR/commit; no data rollback is required.

### Human-intervention budget
Target: **2 or fewer**
1. initial mission/OS experiment approval;
2. final merge/release observation.

Routine patching, test execution, error relay and documentation synchronization do not count as acceptable human work.

### Success criteria
- acceptance evidence green;
- no visual/behavioral regression;
- no business/data/security change;
- independent reviewer approves;
- ≤2 human interventions;
- any failures are classified and repaired without the founder relaying raw logs between agents.

## 8. Revised Mission 3 execution plan

### M3-B0 — Strategic reset / evidence ingestion
Status: current slice. No production code. Define the operating model and authoritative contracts.

### M3-B1 — Product + Architecture Constitutions
Finalize product/architecture vocabulary, invariants, approval/ADR rules.

### M3-B2 — Agentic Company OS + Lifecycle
Finalize role contracts, repair loop, state machine, maturity model and scorecard.

### M3-B3 — Repository Knowledge OS
Eliminate canonical ambiguity:
- one authoritative copy per living document;
- archive stale handoffs/apply notes;
- compact `AI-START-HERE`;
- make `CODEBASE.md` an index/current map rather than a historical diary;
- add document-drift checks.

### M3-B4 — Evaluation / Quality OS
Create one mission gate manifest model that composes existing tests instead of adding another unrelated validation chain. Define architecture/document/evidence gates.

### M3-B5 — Execution Harness
Wire mission branch/worktree, PR/check feedback, persistent orchestrator, preview/runtime environment, disposable DB and evidence artifacts. No new infrastructure class without demonstrated need.

### M3-B6 — First agent-governed engineering mission
Run the Progressive Selector Convergence experiment above. Use results to adjust the OS before larger M3-A refactors.

The old M3-B selector/workspace/hooks/CSS plan is therefore **parked as implementation backlog inside M3-B6+**, not cancelled.


## 9. Machine mission contract

Every executable mission is represented by one `mission.json` validated against `governance/schemas/mission.schema.json`. Gate evidence is emitted as JSON compatible with `governance/schemas/evidence.schema.json`. The mission JSON is operational metadata; it does not override the human-readable charter or constitutions.
