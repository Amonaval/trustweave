# Mission 2 final cleanup — apply note

Apply this overlay to the latest tree that already includes the Mission-2 two-vertical resume patch.

Then apply Supabase migrations through **118**. Migration 118 reasserts both the notification preference contract and the Housing complaint-routes RPC, and reloads PostgREST.

Mission 2 regression is intentionally **paused** after this cleanup. Do not continue the broad automated regression now. Preserve current QA evidence for later resumption.

Closed by this patch:
- corrupt Playwright PNG fixture replaced with a valid browser-decodable PNG;
- media compression gets an `<img>` fallback when `createImageBitmap()` rejects a valid image;
- `get_my_notification_preferences()` live schema drift repaired;
- `hs4_get_complaint_routes()` reasserted;
- crawler exits on a time budget instead of reaching the Playwright hard timeout.
