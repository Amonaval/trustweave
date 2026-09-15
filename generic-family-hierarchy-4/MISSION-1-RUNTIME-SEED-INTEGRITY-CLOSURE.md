# TrustWeave — Mission 1 Runtime Defect & Seed Integrity Closure

**Date:** 2026-09-15  
**Status:** IMPLEMENTED IN SOURCE · PERSISTED RUNTIME RETEST REQUIRED

## Closed in this mission
1. The reported English message keys `PendingApprovalsTxt`, `NeedsAttentionTxt`, `ComingUpTxt` and `ImportantTxt` now each have exactly one definition in the English dictionary.
2. Launch seeding now persists a run record and structured row diagnostics with section, row/ref, operation, code, message, details, hint and retryability; the UI can download the run as JSON.
3. Seed lineage supports `partial` and `error` states. A successfully created remote record is checkpointed before a later state transition, allowing a rerun to repair the same record instead of creating another one.
4. Family Community relationship seeding no longer goes through the interactive `/api/v1/graph/relationships` command route with its 40 calls/minute burst limit. The launch adapter remains network-scoped, admin/platform-owner restricted and dataset-authorization restricted, and delegates to the normal secured relationship RPC.
5. Family Community and Housing ballots are created/adopted first, options are created/adopted second, and open/close state is applied last. This closes the dependency failure where voting was opened before two choices existed.
6. Community media upload SQLSTATE `22023` is repaired in migration 115. Storage authorization still derives the network from the object path and requires real membership. Byte-size validation tolerates supported Storage metadata shapes in the BEFORE trigger and is revalidated during media registration with the uploaded object plus client-reported compressed size fallback.

## Why the Cultural seed kept improving by exactly 40 rows
The supplied Family Community dataset has 148 relationship rows. Fifty-four inverse `Child` rows are intentionally skipped because the canonical `Parent` relationship is already stored. The remaining relationship operations were using an interactive HTTP command route with a 40 requests/minute burst limit. That explains the observed progression of approximately 40 newly successful rows per manual retry. Mission 1 removes that bulk-seed bottleneck without weakening normal interactive rate limits.

## Known constraints, not errors
The supplied Family Community dataset intentionally produces 113 constrained first-run warnings when all source intent is considered:
- 54 inverse Child relationship rows;
- 39 RSVP rows for synthetic directory people who are not authentication accounts;
- 20 group-membership rows with the same authenticated-account limitation.

TrustWeave does not create fake auth users merely to make demo counts look complete. These rows remain explicit warnings in the seed report.

## Required persisted retest
Apply migrations through `115_mission1_runtime_seed_integrity.sql` to the **same** Supabase project used for the seeded rehearsal, then:
1. Create a normal Community post with one photo and verify upload, post creation, media binding and display succeed without `22023`.
2. Rerun the Family Community launch dataset once. Download the seed report if any error remains.
3. Rerun it again unchanged and confirm no accidental creates; only terminal rows should skip while recoverable partial/error rows retry.
4. Repeat the same two-run proof for Housing.
5. If any error remains, provide the downloaded JSON report; it now identifies the exact source row and operation rather than only a total count.

## Source certification
- Mission 1 gate: 22/22 PASS
- Final launch source: 24/24 PASS
- Showcase stabilization: 14/14 PASS
- Residential flagship: 12/12 PASS
- E1→E10 + E10 closure: PASS
- HS0→HS6: PASS
- FCA0: 27/27 PASS
- Static syntax: 344 TS/TSX, 0 syntax errors
- Migration static audit: 113 SQL files, PASS

Dependency-backed lint, complete TypeScript/Next build and actual Supabase persisted retest are not marked PASS in this execution environment.
