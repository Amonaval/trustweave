# TrustWeave — Product Roadmap

**Updated:** 2026-09-15

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
- apply migrations through 114 to approved staging;
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

