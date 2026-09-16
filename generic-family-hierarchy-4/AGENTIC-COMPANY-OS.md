# TrustWeave — Agentic Company & Engineering OS

**Status:** BINDING — M3-B1/B2 accepted for execution  
**Objective:** Let the founder/architect provide intent and exceptional decisions while the engineering system plans, builds, verifies, reviews, documents and prepares release evidence with minimal human participation.

## 1. Operating principle

TrustWeave should not simulate a large company with many chat personas.

Start with the smallest organization that creates real separation of duties:

1. **Mission Lead** — intent decomposition + product planning.
2. **Architecture Governor** — architectural/data/security boundary authority.
3. **Builder** — implementation.
4. **Independent Reviewer** — independent code/architecture review using specialist lenses.
5. **Verification Agent** — QA, failure classification, repair-loop evidence.
6. **Release & Knowledge Agent** — documentation synchronization, evidence packaging and release readiness.

Security, Data/Migration, UX, Performance and Accessibility are **specialist review lenses**, not permanent agents. A dedicated specialist agent is activated only when mission risk/scope triggers it.

The Verification Agent owns ordinary failure triage. A separate Incident Agent is created only for production incidents or repeated unexplained failures.

## 2. Role contracts

### Mission Lead
**Responsibility:** Convert founder intent into one bounded mission with outcome, included/excluded scope, acceptance evidence, risk class and required reviewers.  
**Inputs:** founder intent, Product Constitution, Current State, Roadmap, active evidence.  
**Outputs:** mission charter/manifest, acceptance contract, scope/risk classification.  
**Authority:** may reject/split/reshape work that is ambiguous, oversized or weakly tied to product outcome.  
**Prohibited:** implementation, silent scope expansion, changing constitutions.  
**Evidence:** explicit acceptance criteria and dependency/surface inventory.  
**Handoff:** accepted mission charter to Architecture Governor.  
**Escalate:** conflicting product priorities, unclear irreversible decision, constitution conflict.  
**Human gate:** new strategic direction, constitution change, or material scope/value choice.

### Architecture Governor
**Responsibility:** Decide boundaries, ownership, reuse, data/auth/migration implications and ADR need.  
**Inputs:** mission charter, Architecture Constitution, M3-A/current architecture, source dependency map.  
**Outputs:** architecture decision section/ADR, forbidden-change list, required gates/review lenses.  
**Authority:** veto architecture-violating plans; require a narrower adapter/shared contract.  
**Prohibited:** approving its own constitution change; weakening security/privacy for convenience.  
**Evidence:** affected layers, ownership, dependency direction, compatibility/rollback.  
**Handoff:** architecture-approved plan to Builder.  
**Escalate:** new infrastructure, destructive migration, cross-vertical semantic merge, privacy/security change.  
**Human gate:** constitution/ADR cases marked high-risk.

### Builder
**Responsibility:** Implement the approved plan in a mission branch/worktree.  
**Inputs:** mission charter, architecture decision, source tree, local conventions.  
**Outputs:** commits, tests/gates, migration files when authorized, change summary.  
**Authority:** make bounded implementation choices inside accepted contracts.  
**Prohibited:** changing mission scope, editing historical migrations, suppressing errors/tests, self-merging, rewriting architecture contracts to justify code.  
**Evidence:** diff, targeted tests, new regression assertion for fixed defects.  
**Handoff:** candidate commit/PR + evidence to Verification and Reviewer.  
**Escalate:** unexpected boundary/data/security implication, repeated gate failure, acceptance ambiguity.  
**Human gate:** none for ordinary low-risk implementation.

### Independent Reviewer
**Responsibility:** Review the candidate independently from the Builder. Apply architecture, security, data, UX/accessibility and performance lenses according to risk.  
**Inputs:** charter, constitutions, diff, test evidence.  
**Outputs:** approve / changes-required findings with severity and evidence.  
**Authority:** block promotion for contract violations or insufficient evidence.  
**Prohibited:** silently fixing its own findings and then declaring the work independently reviewed; lowering mandatory gates.  
**Evidence:** finding list tied to files/contracts.  
**Handoff:** approval or findings to Verification/Builder.  
**Escalate:** disputed architecture/security finding or necessary scope change.  
**Human gate:** only unresolved high-impact disagreement.

### Verification Agent
**Responsibility:** Run the required mission-scoped gates, classify failures, drive bounded repair loops and preserve evidence.  
**Inputs:** candidate commit, acceptance contract, gate matrix, target environments.  
**Outputs:** verification manifest, failure classification, rerun history, runtime evidence.  
**Authority:** retry deterministic checks, request/route bounded repair, reject unsupported “pass” claims.  
**Prohibited:** hiding flaky/runtime/API failures, mutating protected environments outside guards, waiving P0/P1.  
**Evidence:** command, environment identity, commit SHA, exit status, artifacts, screenshots/traces where relevant.  
**Handoff:** green evidence to Release & Knowledge; failures to Builder with classified root cause.  
**Escalate:** >3 repair loops, environment ambiguity, schema drift, non-deterministic failure, production-like target uncertainty.  
**Human gate:** protected/disposable environment authorization when credentials or irreversible actions require it.

Failure classes:
- product defect;
- architecture/contract defect;
- QA harness defect;
- environment/dependency defect;
- schema/migration drift;
- test-data/fixture defect;
- flaky/non-deterministic defect;
- documentation/evidence defect.

### Release & Knowledge Agent
**Responsibility:** Ensure current truth and evidence match the candidate, package release artifacts, and enforce document authority/closure rules.  
**Inputs:** approved candidate, verification evidence, mission decisions.  
**Outputs:** synchronized current-state/status/roadmap where needed, evidence manifest, release recommendation, archive moves.  
**Authority:** block closure for documentation drift or missing mandatory evidence.  
**Prohibited:** changing product/architecture decisions during documentation; declaring runtime proof from source-only evidence.  
**Evidence:** document-drift check, evidence manifest, candidate SHA.  
**Handoff:** release-ready candidate to the human or authorized release gate.  
**Escalate:** conflicting canonical documents, missing runtime evidence, release-risk exception.  
**Human gate:** production release under current maturity.

## 3. Specialist activation matrix

Activate a dedicated specialist review when any trigger matches:

| Lens | Trigger |
|---|---|
| Security/privacy | auth/RLS/storage/service-role/tenant/federation/public exposure |
| Data/migration | schema/RPC/signature/data ownership/migration/seed/destructive lifecycle |
| UX/accessibility | user-visible navigation/forms/mobile/translated behavior |
| Performance | measured regression risk, bundle/runtime/query hot path, volume work |
| Release/operations | environment, deploy, secret, rollback or production behavior |

Low-risk presentational refactors do not need five separate agents.

## 4. Human approval matrix

### Human approval always required
- Product or Architecture Constitution change.
- New strategic product direction/vertical scope.
- Privacy/security risk acceptance or permission widening.
- Destructive/irreversible production data action.
- Production release at current maturity.
- New external infrastructure class or recurring paid platform commitment.
- Breaking public/shared contract without an already-approved compatibility plan.

### Human approval conditionally required
- Additive migration: not for authoring/testing; required before protected production application until maturity advances.
- ADR: only when it changes constitution-level behavior or creates material lock-in.
- Mission scope change: only if outcome/cost/risk materially changes.
- Dependency upgrade: only for major runtime/security/compatibility risk.

### No routine human approval
- bounded code refactors within accepted architecture;
- test maintenance caused by intentional UI contract changes;
- documentation synchronization;
- low-risk bug fixes with regression proof;
- source/static gate repair;
- local disposable QA setup inside already-approved safety rules.

## 5. Autonomous repair loop

```text
candidate
-> required validation
-> classify failure
-> identify root cause + affected dependency graph
-> repair within mission boundary
-> rerun targeted gate
-> rerun required regression set
-> independent review
-> evidence
```

Rules:
- maximum default autonomous repair loops: 3;
- a loop that requires scope expansion returns to PLAN/ARCHITECTURE;
- a repeated identical failure after two materially different repairs escalates;
- an environment failure must not be patched as a product defect;
- a QA-harness bug may be repaired only with an explicit proof that product behavior was not weakened.

## 6. Execution harness

### What exists now
TrustWeave already has:
- GitHub Actions CI;
- many source gates;
- TypeScript/lint/build checks;
- Playwright runtime suites;
- staging mutation guards;
- strict RPC/security audits;
- fresh migration replay against explicitly disposable databases;
- release evidence/report generation.

### Missing persistent orchestration
Current chat sessions cannot continuously own a mission, monitor CI, push repair commits, or retain durable execution state by themselves.

To reach agent-executed delivery, M3-B5 requires:
1. a Git repository as the durable source workspace;
2. one branch/worktree per mission;
3. programmatic GitHub PR/status/check access;
4. persistent agent/orchestrator execution that can resume after CI results;
5. dependency-enabled CI runners;
6. protected secrets for QA/staging only;
7. a disposable database/release-candidate environment for migration/destructive certification;
8. preview deployment/runtime URL for browser tests;
9. branch protection requiring mission-defined checks;
10. immutable CI artifacts/evidence tied to commit SHA.

Do not adopt Kubernetes, queues or a multi-agent framework merely to satisfy this list.

## 7. Autonomy maturity model

### L0 — Manual
Human plans, edits, tests and releases.

### L1 — AI-assisted
AI proposes/implements bounded work; human orchestrates patches, testing, failures, documents and session handoffs.

**TrustWeave today:** L1 overall, with strong automated QA/gate assets that are prerequisites for L2.

### L2 — Agent-executed
A mission controller can take an accepted charter to a review-ready PR, run required gates, repair bounded failures and produce evidence. Human does not apply patches or paste routine failures.

Requirements:
- canonical mission contract;
- branch/worktree automation;
- CI status feedback;
- persistent mission state;
- environment access;
- bounded repair loop.

### L3 — Multi-agent reviewed
Author and final reviewer are operationally independent; specialist reviews are risk-triggered; merge requires machine evidence and independent approval.

### L4 — Self-repairing mission execution
The system diagnoses and repairs common product/test/environment failures across multiple cycles, can create/refresh disposable runtime environments and closes documentation without human intervention. Humans handle exceptions.

### L5 — Governed autonomous delivery
Low-risk mission classes can merge/release within pre-approved policy; production observability can create bounded incident/remediation missions; humans remain the authority for constitutions, strategic direction, security/privacy risk acceptance and irreversible decisions.

Progress one level at a time. Do not claim L2+ merely because several scripts can be run automatically.

## 8. Engineering/company scorecard

Use a compact scorecard. Mandatory mission metrics:

1. **Human interventions per mission** — target falls as autonomy matures.
2. **Mission lead time** — accepted charter to review-ready evidence.
3. **Autonomous repair success** — failures repaired without human patch/error relay.
4. **Architecture violations** — target 0 at merge.
5. **Blocking security/data findings** — target 0 at release.
6. **Runtime escape rate** — defects found in real runtime after source-green.
7. **Gate reliability** — flaky/non-deterministic mandatory gate rate.
8. **Documentation drift** — conflicting/stale canonical documents, target 0.

Mission-specific metrics are added only when relevant (bundle size, API latency, query count, accessibility findings, migration replay duration, duplicated contracts). They are not universal vanity KPIs.

## 9. Cost and autonomy policy

Prefer deterministic scripts/compilers/tests over LLM review for facts they can prove.

Use agent reasoning for:
- ambiguity resolution;
- architecture/product trade-offs;
- failure diagnosis;
- code review;
- mission planning;
- evidence synthesis.

The goal is fewer human interventions and fewer expensive reasoning passes, not maximum agent count.

## 10. Product-level agents later

AI inside TrustWeave is a separate track. Any future network-admin/member agent must have:
- network-scoped permissions;
- explicit tool/action allow-list;
- tenant-safe context;
- auditable proposed/action records;
- human approval for externally visible or destructive actions by default;
- reversible operations where possible;
- no silent mutation from generated knowledge.

Mission 3 designs this policy but does not implement broad in-product agents.


## 11. Machine operating contract

`governance/company-os.json` is the executable projection for role separation, specialist activation, repair budgets and approval triggers. Mission manifests may narrow authority further but may not expand it beyond this contract.
