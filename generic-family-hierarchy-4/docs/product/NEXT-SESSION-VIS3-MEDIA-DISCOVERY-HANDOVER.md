# Next session handover — VIS3 / Media / Discovery closure

Use latest `main` as the only source of truth. Do not reconstruct work from old chat descriptions before reading the current code and this file.

## State at handover

The visible VIS3 repair is substantially closed:

- Public Product Discovery shows only verticals whose existing Showcase / Launch Control setting has `playground_enabled=true`.
- Public Playground CTAs preserve the exact vertical; Family Community and Housing Society no longer fall into the Family Playground.
- Pre-sign-in exploration has URL state through `?explore=` and `?playground=`.
- Public hero duplicate Housing/Community CTAs were removed; outcome-specific journeys remain lower on the page.
- The `.public-hero-visual > *` regression no longer changes `.public-orbit` positioning from absolute to relative.
- Shared **Media & Storage** is now a core admin capability across Family, Alumni and productized verticals.
- Network cover uploads return a usable signed URL and then open the network Media & Storage inventory so admins can see where the asset went.
- Design Studio shows the directly uploaded assets for Platform / Vertical / Playground scope.
- Family Community governance uses neutral Indian-association terms such as Member Decisions, Committee selection and Member poll; Housing Society keeps its separate Maharashtra-specific guidance.
- Residential Playground/sample identity is now **Majestique Marbella** in:
  - `showcase-data/residential-showcase-data.v1.json`
  - `templates/productized/config.ts`
  - `templates/productized/runtime-meta.ts`

## Platform image upload — important closure

The repeated Design Studio upload failure was finally isolated to duplicated authorization in the Storage trigger plus Storage BEFORE-trigger metadata differences.

Founder manually applied the focused runtime patch and confirmed image upload now works.

Source-of-truth repair:
- `supabase/migrations/130_vis3_platform_media_storage_final.sql`

Final contract:
1. `platform/<user-id>/...` authorization is enforced by explicit Storage RLS and `public.is_platform_owner()`.
2. `a5_storage_guard()` treats platform media as non-network media and only validates MIME/known-size limits there.
3. Normal network media keeps explicit network-id, uploader-id, active-membership, MIME and quota enforcement.
4. Migrations 128/129 remain historical but their platform-storage guard implementations are superseded by 130.

Do not create another speculative media migration unless a new concrete runtime failure proves it is needed.

## Bootstrap state

The immutable D12 bootstrap is intentionally **not rewritten**:
- `supabase/bootstrap/CURRENT` = `2026-09-20-d12`
- covers accepted state through roughly migration 123.

New synchronized current tail:
- `supabase/bootstrap/POST_CURRENT` = `2026-09-23-post-d12`
- files under `supabase/bootstrap/post-current/2026-09-23-post-d12/`

The tail is a consolidated current-state delta through migration 130:
- 124 retained;
- 125 not replayed separately because 126 contains the final RSVP contract;
- 126 retained;
- 127 retained;
- 128 contributes only the notification-overload cleanup;
- 129 storage guard is not replayed;
- 130 is the final validated platform/network media contract.

Fresh project rule: immutable D12 base first, then POST_CURRENT database SQL, then POST_CURRENT Storage owner-context SQL.

Existing DB rule: use migrations, not bootstrap.

New permanent discipline: **runtime-prove DB changes first, then synchronize the final effective contract into POST_CURRENT before mission closure. Never put experimental patches into bootstrap.**

## Important pending validation

Do not automatically run broad QA/workflows. User prefers bounded source review and targeted manual checks.

Useful next checks, only as needed:
1. local build after latest main;
2. one Platform Design Studio upload and verify it appears under Uploaded assets;
3. one real network cover upload and verify redirect to Media & Storage inventory;
4. quick visual pass of Public Discovery and Majestique Marbella Playground.

After these are satisfactory, stop polishing VIS3. The next product-value checkpoint should return to the representative **MPF Pune East public/pilot proof and real-user feedback**, not D12 recovery or another broad architecture mission unless new evidence changes priority.

## Operating constraints

- GitHub Actions are disabled; do not run workflows.
- Zero-additional-cost rule: do not provision, deploy, call paid APIs, consume metered services or do anything that could create a charge without explicit warning and consent.
- Do not automatically apply Supabase SQL/migrations.
- Keep commits coherent and minimal.
- Do not duplicate vertical functionality when a shared engine already exists.
