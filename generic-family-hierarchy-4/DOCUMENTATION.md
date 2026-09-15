# TrustWeave Documentation — Start Here

Use this page for current launch truth. Historical mission evidence remains under `archive/`.

## Final launch closure
- `CURRENT-STATE.md` — exact current product/release state.
- `MISSION-STATUS.md` — final pre-launch mission status.
- `LAUNCH-READINESS-REPORT.md` — green gates, blocked gates and launch decision.
- `PILOT-DEMO-RUNBOOK.md` — showcase sequence for anonymous visitor, Residential and Family Community.
- `DATA-SEED-RUNBOOK.md` — safe persisted launch-data workflow.
- `RUNTIME-VERIFICATION-CHECKLIST.md` — binding final go/no-go checklist.
- `RUNTIME-HOTFIX-APPLY-RUNBOOK.md` — apply migration 114 and retest the real rehearsal failures.
- `FINAL-RELEASE-MANIFEST.md` — candidate contents and affected-file scope.
- `NEXT-SESSION-RUNTIME-HOTFIX-RETEST.md` — next-session handoff; certification only.

## Executive / product views
- `CEO-PRODUCT-BRIEF.md`
- `CTO-PRODUCT-CAPABILITY-BOOK.md`
- `TRUSTWEAVE-MISSION-JOURNEY.md`
- `USER-EXPERIENCE-HANDBOOK.md`
- `PRODUCT-CAPABILITY-CATALOG.md`
- `TRUSTWEAVE-PRODUCT-FEATURE-HANDBOOK.html`
- `TRUSTWEAVE-PUBLIC-PRODUCT-PROFILE.html`
- `TRUSTWEAVE-PRODUCT-EVOLUTION-JOURNEY.html`

Canonical mirrored Markdown copies also live under `docs/product/` where applicable.

## Operational truth
- `ROADMAP.md`
- `USER-GUIDE.md`
- `VALIDATION.md`
- `CODEBASE.md`
- `PROJECT-VISION.md`

## Engagement closure
- `docs/engagement/E1-E10-VERIFICATION-GUIDE.md`
- `docs/engagement/E10-ENGAGEMENT-CONTROL-CENTER.md`

## Historical evidence
- `ARCHIVE-INDEX.md`
- `archive/docs/archive-map.json`
- `archive/docs/missions/`

Do not infer launch readiness from source gates alone. The runtime checklist is the final authority for go/no-go.

## 2026-09-15 — Seeded-network rehearsal hotfix
The first real seeded Residential rehearsal exposed live contract/UX defects that source-only certification had not proven. Migration **114** now restores the missing `hs4_get_operations_snapshot()` and `route_network_mentions(...)` RPCs, fixes the invalid funds `a.type` reference, makes explicit **Open Voting** open immediately, and decouples Storage authorization from profile active-network drift while preserving network membership isolation.

Housing Society UX was also restructured after real laptop use showed unacceptable information density: Manage Society now renders one categorized workspace at a time; Finance, Governance and Security have focused subsections; Housing More is grouped; and Appearance is reduced to a single **Classic / Modern / Dark** selector. These are launch-hardening changes, not new product scope.

**Runtime status:** source gates are green, but this hotfix is not considered proven until migration 114 is applied to the real/staging database and the reported operations/funds/voting/mentions/media paths are retested.

