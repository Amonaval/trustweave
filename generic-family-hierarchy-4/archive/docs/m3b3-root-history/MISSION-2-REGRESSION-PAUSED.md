# Mission 2 — Regression Paused

Mission 2 automated regression is intentionally paused after the current defect-cleanup pass.

## Closed in this pass
- Replaced the corrupt Playwright PNG fixture with a browser-decodable PNG.
- Reasserted `get_my_notification_preferences()` and its expected preference columns in migration 118.
- Reasserted `hs4_get_complaint_routes()` in migration 118 so one final DB apply repairs both observed live-schema drifts.
- Added a crawl time budget so exploratory crawling exits cleanly instead of reaching the Playwright hard timeout and closing the browser mid-read.

## Required apply step
Apply migrations through **118** to the QA/staging Supabase project, then reload the app.

## Deferred
Do not continue broad Mission 2 regression now. Preserve current evidence and resume later from the two-vertical Housing + Family Community scope when desired.
