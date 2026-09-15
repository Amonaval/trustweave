# TrustWeave — Mission 2 Slow User Regression Closure

**Date:** 2026-09-15  
**State:** IMPLEMENTED IN SOURCE — STAGING EXECUTION REQUIRED

## Why this mission exists
The first launch rehearsal proved that source gates alone do not catch ordinary user failures. Supabase/PostgREST and Storage defects frequently return HTTP 400/409/422 while the React page remains mounted, so a crawler that only checks navigation or HTTP 500 can report a false green state.

Mission 2 therefore treats an unexpected API 4xx/5xx during an ordinary user action as a test failure and captures the response body as evidence.

## Runtime order
`npm run qa:mission2` is deliberately serial and low-concurrency:

1. Mission 2 source contract.
2. Existing QA preflight (unit/contracts, types/build/migration/source checks in a dependency-enabled environment).
3. Reuse the deterministic QA fixture when available; create it only when missing.
4. **Mission 1 persisted seed retest first** using the full Residential 25-flat and Family Community 20-family launch datasets. This proves fresh persistence and unchanged rerun idempotency before broader crawling.
5. Slow deterministic user journeys on desktop.
6. Owner/admin/member crawl across Family, Family Community and Housing Society.
7. Explicit cross-network isolation proof.
8. Mobile progressive-navigation regression.
9. Evidence summary + bug report.

The runner uses **one worker** and defaults to **700 ms pacing** for user actions and crawler actions. These can be increased via `QA_USER_PACE_MS` and `QA_CRAWL_PACE_MS`.

## Deterministic journeys added
### Family Community / shared capabilities
- Create Community post with a real tiny image through Storage.
- Add a comment and verify the post survives reload.
- Create a fund and record a transaction.
- Create a ballot, add two choices, explicitly Open Voting, cast a vote, verify receipt/state.
- Create a membership year and persist annual family membership through FCA controls.

### Housing Society
- Create notice.
- Create complaint with image and verify persisted reload.
- Create maintenance charge head.
- Create committee meeting.
- Pre-approve visitor against a real seeded unit.
- Verify normal member can create a complaint but cannot access Manage Society.

### Family / shared shell
- Slow owner crawl with runtime/API failure observation.
- Owner/admin/member crawls across Family, Family Community and Housing.
- Mobile Family Community navigation through responsive selectors/More sheet.
- Direct tenant-B negative isolation proof.

## Runtime failure capture
Mission 2 now observes:
- `/rest/v1/`
- `/storage/v1/`
- `/functions/v1/`
- `/api/v1/`

Unexpected HTTP >=400 responses, request failures, page errors and console errors fail the user journey. Strict Mission-2 issues are persisted to:

`qa-results/mission2/runtime-issues.ndjson`

Playwright also produces traces/screenshots/video on failures plus `qa-results/test-failures.json`, `qa-results/BUG-REPORT.md`, and `qa-results/mission2/SUMMARY.md`.

## Additional defect found during Mission 2 source audit
The shared Activity composer filtered normal-member activity types by comparing internal keys (`memory`, `milestone`) with translated display strings. That could hide valid non-admin activity types depending on locale. It now filters using stable internal IDs. A permanent Mission-2 source assertion protects this behavior.

The mobile surface opener was also corrected to use the actual bottom-navigation / mobile More-sheet test hooks instead of assuming the desktop sidebar is visible.

## Source evidence
- Mission 2 source gate: **38/38 PASS**.
- Mission 1 runtime/seed gate: **22/22 PASS**.
- Progressive-disclosure UX gate: **23/23 PASS**.
- Runtime hotfix gate: **18/18 PASS**.
- Final-launch source gate: **24/24 PASS**.
- Showcase stabilization: **14/14 PASS**.
- Residential flagship: **12/12 PASS**.
- FCA0: **27/27 PASS**.
- HS0→HS6: **PASS**.
- E1→E10: **PASS**.
- Static syntax scan: **344 TS/TSX, 0 syntax errors**.
- Migration static audit: **113 SQL files PASS**.

## What is not claimed
This environment does not contain `.env.qa`, and dependency restoration cannot complete offline because the npm cache is missing `zustand-4.5.7.tgz` (and the environment cannot reliably reach the registry). Therefore the new Playwright suite has **not** been represented as runtime-certified here.

Mission 2 becomes runtime-certified only when `npm run qa:mission2` executes against an approved staging/QA Supabase project with migrations through 115 applied and returns `MISSION2_CERTIFIED`.

## Closure rule
Every defect discovered by the Mission-2 run must be fixed at root cause and receive a deterministic regression assertion before the suite is allowed to return green. Do not suppress unexpected 4xx/5xx merely to make the run pass.
