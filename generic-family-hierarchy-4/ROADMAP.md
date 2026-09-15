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
- apply migration 113 to approved staging;
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
