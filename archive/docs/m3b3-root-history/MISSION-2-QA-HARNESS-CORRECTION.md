# Mission 2 — QA Harness Correction

## Trigger
A staging Mission-2 run produced 58 P1 findings in `BUG-REPORT.md`. The failures collapsed into two repeated QA-contract problems rather than 58 independent product defects:

1. cross-vertical suites asserted the Family-only `qa-admin-center` marker after opening Admin;
2. older login flows could fail at `qa-open-auth`, while Playwright was also allowed to silently reuse an already-running server from a different source revision.

## Corrections
- Every released vertical Admin/Manage workspace now exposes the shared `data-qa-workspace="admin"` contract while retaining its vertical-specific test id.
- `expectAdminWorkspace(page)` is the canonical cross-vertical assertion.
- Historical QA specs no longer click `qa-nav-admin` directly; they use the responsive `openSurface(page,'admin')` helper.
- `login()` now waits for the current Discovery/auth state, retries once after reload, and emits URL/body diagnostics when auth entry is unreachable.
- Playwright no longer reuses an existing server by default. Set `QA_REUSE_SERVER=true` only when intentionally testing an externally verified server built from the same source.
- Mission-2 source gate now prevents reintroduction of the stale patterns.

## Runtime interpretation
The 58 findings from the triggering report must not be counted as 58 product defects. Re-run Mission 2 after this correction. Only failures that remain after the QA harness reaches the intended product surface should be triaged as application/runtime defects.

## Database
No migration is added by this correction. The current runtime baseline still requires migrations through `116_mission2_media_membership_runtime_repair.sql`.
