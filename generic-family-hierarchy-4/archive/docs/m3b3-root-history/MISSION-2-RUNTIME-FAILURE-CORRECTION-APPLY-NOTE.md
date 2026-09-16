# Mission 2 Runtime Failure Correction — Apply Note

Apply this overlay on top of the latest Mission-2 QA Harness + Login Quick Fix + Playwright Warm-up state.

## Required database step
Apply `supabase/migrations/117_mission2_complaint_routes_contract_repair.sql` to the same Supabase project used by QA. It restores `public.hs4_get_complaint_routes()` and requests a PostgREST schema-cache reload.

## QA corrections
- `qa/mission2-global-setup.ts` is included so Playwright warm-up cannot be missing from the overlay.
- `playwright.config.ts` resolves the global setup defensively.
- Mission-2 role crawls default to 180 seconds instead of 90 seconds.
- Community post-photo and Housing complaint-photo tests now surface `qa-product-message` immediately when persistence fails, instead of timing out with only "card not found".

## Rerun
After migration 117:

`npm run qa:mission2:playwright:headed`

If either photo workflow still fails, send the new failure output. It should now include the actual UI/product error message that caused the persistence failure.
