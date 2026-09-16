# TrustWeave — Product Roadmap

**Updated:** 2026-09-16

The roadmap has moved from capability construction to **proof, pilot and adoption**. Broad feature expansion is intentionally paused until the final launch candidate passes runtime certification.

## Closed in source — final pre-launch engineering
1. Anonymous Discovery / product front door.
2. Role-oriented Housing Society, Family Community and member/resident exploration.
3. Public-safe Product Guide with progressive disclosure.
4. Guarded, network-scoped Launch Demo Data Loader.
5. Residential 25-flat final synthetic dataset bundled as JSON + XLSX.
6. Family Community 20-family final synthetic dataset bundled as JSON + XLSX.
7. Annual FCA Association Membership guided-import persistence.
8. Seed authorization + lineage/idempotency migration.
9. Launch-specific source gate and persisted runtime E2E specifications.
10. Release documentation, runbooks, manifest and runtime checklist.

## Now — Final Runtime Certification & Pilot Go/No-Go
No unrelated engineering work should start before these pass:
- restore packages from the lockfile in a network-enabled environment;
- `lint:trustweave` — 0 errors;
- `validate:static` — PASS;
- `npm run build` — PASS;
- apply migrations through 115 to approved staging;
- seed one fresh Residential network and rerun idempotently;
- seed one fresh Family Community network and rerun idempotently;
- headed desktop walkthroughs for Chairman/admin/resident and President/admin/representative/member;
- mobile viewport walkthroughs;
- verify exact notification deep links, Push controls, private media and cross-network isolation;
- record go/no-go evidence in `LAUNCH-READINESS-REPORT.md`.

## After runtime certification — controlled pilots
### Residential / Housing Society
Use one real pilot society to measure onboarding completion, notice readership, complaint resolution, maintenance visibility, governance/security usefulness and administrator willingness to continue.

### Family Community / Cultural Association
Use the MPF-style pilot to measure family onboarding, annual membership/renewal, events, funds/collections, committee operations, voting, posts/notifications and representative/member return loops.

## Explicitly deferred
- unrelated new verticals;
- broad intelligence expansion;
- speculative federation UX expansion;
- new finance/social/voting/media subsystems parallel to existing shared capabilities.

The next product decision should come from **real pilot evidence**, not another broad feature mission.

## 2026-09-15 — Seeded-network rehearsal hotfix
The first real seeded Residential rehearsal exposed live contract/UX defects that source-only certification had not proven. Migration **114** now restores the missing `hs4_get_operations_snapshot()` and `route_network_mentions(...)` RPCs, fixes the invalid funds `a.type` reference, makes explicit **Open Voting** open immediately, and decouples Storage authorization from profile active-network drift while preserving network membership isolation.

Housing Society UX was also restructured after real laptop use showed unacceptable information density: Manage Society now renders one categorized workspace at a time; Finance, Governance and Security have focused subsections; Housing More is grouped; and Appearance is reduced to a single **Classic / Modern / Dark** selector. These are launch-hardening changes, not new product scope.

**Runtime status:** source gates are green, but this hotfix is not considered proven until migration 114 is applied to the real/staging database and the reported operations/funds/voting/mentions/media paths are retested.

## Launch closure missions — recorded 2026-09-15
The remaining pre-launch work is intentionally split rather than attempted as one refactor.

### Mission 1 — Runtime Defect & Seed Integrity Closure — IMPLEMENTED IN SOURCE
- remove duplicate English message definitions reported during rehearsal;
- repair Community post-with-photo SQLSTATE `22023`;
- persist row-level launch seed diagnostics and downloadable run reports;
- make partial/error lineage recoverable and reruns idempotent;
- remove the interactive 40/min relationship API bottleneck from authorized synthetic seeding;
- seed/adopt ballot options before opening/closing voting;
- preserve known authenticated-account modeling constraints as warnings rather than fake data.

Runtime proof remains required after migration **115** is applied to the same Supabase project: post a Community photo, rerun Family Community seeding to stable completion, and rerun Housing seeding to stable completion.

### Mission 2 — Slow Full Product User Regression — IMPLEMENTED IN SOURCE / STAGING RUN REQUIRED
The one-worker Playwright regression layer is implemented. It runs the Mission-1 full persisted seed/idempotency proof first, then slow deterministic user journeys and owner/admin/member crawls across Family, Family Community and Housing, plus mobile navigation and direct cross-network isolation. Unexpected REST/Storage/Functions/app API 4xx/5xx responses are now release failures with structured evidence. Default user/crawler pacing is 700 ms and deterministic QA fixtures are reused to minimize Auth/API writes.

Source contract: **38/38 PASS**. Runtime certification requires `npm run qa:mission2` against staging with migrations through 115 applied.

### Mission 3 — Shared UI / Business / Technical Component Architecture — SUPERSEDED BY M3-B STRATEGIC RESET
The architecture-convergence objective remains valid, but the prior sequencing assumption that Mission 2 runtime must be green before Mission 3 is superseded by the 2026-09-16 handoff decision. M3-A inventory is complete; implementation work is parked behind the M3-B Agentic Company & Engineering OS sequence below.

### Mission 4 — Plugin Architecture, Vertical Lazy Loading & SQL Modularization
Move toward loading core/common code first and vertical bundles only when selected. Define injectable vertical manifests for routes, navigation, capabilities, permissions, seed adapters and tests. Keep historical Supabase migrations immutable; organize future maintainable SQL by domain (`common`, `family`, `family-community`, `housing`, `engagement`, etc.) while continuing to emit chronological deployment migrations. Do this only after Mission 2 provides strong regression protection.

## Mission 3 — Agentic Company & Engineering OS + architecture convergence

Mission 3 is strategically reframed. M3-A remains the evidence base; the old component-refactor sequence becomes the first workload of the new operating system rather than the immediate mission.

### M3-A — COMPLETE: Architecture Inventory & Boundaries
Preserve `missions/mission-003/M3-A-ARCHITECTURE-INVENTORY-AND-BOUNDARIES.md`.

### M3-B0 — COMPLETE: Strategic reset / evidence ingestion
No production code. Diagnose current architecture/process/orchestration/documentation/tooling gaps.

### M3-B1 — COMPLETE: Product & Architecture Constitutions
Finalize product vocabulary, kernel/capability/vertical/shared-use-case/domain-adapter boundaries, invariants, ADR policy and human approval boundaries.

### M3-B2 — COMPLETE: Agentic Company OS + Mission Lifecycle
Finalize minimal agent roles, independent review, failure/repair loop, lifecycle, approval matrix, maturity model and scorecard.

### M3-B3 — COMPLETE: Repository Knowledge OS
Remove canonical ambiguity and divergent mirrors; compact session bootstrap; archive stale handoffs/evidence; add document-drift checks.

### M3-B4 — COMPLETE / OPERATING: Evaluation / Quality OS
Compose existing source/QA/security/migration/runtime assets into mission-scoped gate manifests and evidence contracts rather than creating another unrelated validation chain.

### M3-B5 — COMPLETE / OPERATING: Execution Harness
Design/wire Git branch/worktree + PR/check feedback + persistent orchestration + preview runtime + disposable database + evidence artifacts. Use existing GitHub Actions/QA foundations. Add no speculative infrastructure.

### M3-B6 — VERIFY: First agent-governed engineering experiment
Progressive selector convergence is implemented under the new operating model: Housing Finance/Governance/Security use `ResponsiveSectionTabs`; duplicate selector code/CSS is removed; source, architecture, documentation and protected-migration gates are green. Dependency-backed type/lint, desktop/mobile runtime and an independent reviewer remain blocking evidence before CLOSE.

### After B6
If the operating model proves useful, continue the parked M3-A backlog: workspace convergence → async lifecycle → async state/media primitives → incremental CSS ownership normalization. Mission 4 remains reserved for plugin/lazy-load/bundle/SQL modularization and is not pulled forward merely because Mission 3 is agentic.
