# TrustWeave — Launch Rehearsal Runtime Hotfix Apply / Retest

**Updated:** 2026-09-15

This hotfix exists because the first real seeded-network rehearsal exposed live database-contract drift and a broader information-density pattern that was first obvious in Housing Society. The UX correction is intentionally cross-vertical so the same exercise is not repeated later. Apply it to the same environment that produced the reported errors before repeating certification.

## What this hotfix repairs

### Runtime contracts — migration 114
`supabase/migrations/114_final_launch_runtime_contract_repair.sql` is additive and intended to be applied after migration 113.

It:
- restores `public.hs4_get_operations_snapshot()` and requests a PostgREST schema-cache reload;
- restores the typed `public.route_network_mentions(text[], text, text, text, text, uuid, text)` RPC;
- fixes the funds snapshot to use `network_activities.activity_type` instead of the invalid `a.type` column;
- makes an explicit **Open Voting** action set `opens_at = now()` so a future schedule cannot leave an apparently-open ballot unvotable;
- authorizes private Storage uploads from the network encoded in the object path plus real active membership, rather than coupling the upload to a profile's current-network field;
- preserves tenant-prefixed/user-owned media paths and network-admin delete authority.

### Client media selection
`lib/storage.ts` no longer silently chooses the first membership when no network is active. Media upload now requires an explicitly active network, preventing a multi-network account from writing a path for the wrong network.

### Cross-vertical progressive-disclosure UX
The product-wide rule is: do not keep adding substantial peer blocks to the bottom of a long operational page. Prefer one focused task area at a time. Desktop uses tabs/workspaces where appropriate; mobile uses compact selectors instead of horizontal navigation scrolling; optional/advanced detail uses accordions; overview choices use card grids; data-heavy collections stay bounded/filterable.

Implemented across:
- Housing Manage Society plus Finance / Governance / Security;
- Family Admin Center, advanced administration, Guide and Participation;
- Family Community annual policy / membership / leadership / finance;
- Alumni administration;
- generic/productized vertical Admin (therefore Association, Organization, Professional, Franchise, Business Trust and future compatible verticals);
- shared Community, Contributions and Product Guide;
- shared Funds, Voting, Activity/Groups and Media Management;
- multi-network tool navigation on mobile.

Appearance is also reduced to one dropdown with three deliberately distinct choices: **Classic / Modern / Dark**. Old Warm and Aurora preferences migrate automatically.

## Apply sequence

1. Deploy `TRUSTWEAVE-LAUNCH-RUNTIME-UX-CLOSURE-FULL.zip` (or apply `TRUSTWEAVE-LAUNCH-RUNTIME-UX-CLOSURE-AFFECTED.zip` exactly to the previous launch-candidate baseline).
2. Apply **all pending migrations through 114** to the same Supabase project used for the seeded demo. Do not apply only frontend changes.
3. Confirm migration 114 completes without an SQL error. Its final `notify pgrst, 'reload schema'` refreshes PostgREST RPC discovery.
4. Reload the application and explicitly select the seeded Housing Society network before media tests.
5. Run the targeted retest below before broader demo rehearsal.

## Targeted retest

### A. Housing operations RPC
- Open Residential Home / Notices / Complaints / Amenities.
- Expected: no `hs4_get_operations_snapshot` schema-cache error; operations data renders.

### B. Funds snapshot
- Open Maintenance & Dues → Society Funds and Family Community Funds & Collections.
- Expected: no `column a.type does not exist` error.

### C. Open Voting
- Create or use a draft ballot whose scheduled `opens_at` is in the future.
- Click **Open Voting**.
- Expected: eligible voters are snapshotted/notified and the ballot becomes votable immediately; the explicit action overrides the future schedule by setting `opens_at` to the current server time.
- Verify from an eligible member account that the ballot opens and a vote can be submitted.

### D. Mentions
- Create a post/activity containing a supported mention such as an owner/admin alias or named member.
- Expected: no `route_network_mentions(...) does not exist` error and notification routing completes.

### E. Private media
- Explicitly select the seeded network.
- Upload a complaint/profile/community image through the normal UI.
- Expected: the upload succeeds for an active member/creator of that network and remains private/signed.
- Switch to another network and repeat only after explicitly selecting it; no cross-network media should become readable.

### F. Cross-vertical UX
- Housing: verify Manage Society, Maintenance & Dues, Committee & Meetings and Visitors & Security replace peer content rather than append it.
- Family: verify Admin Center, Advanced Administration, Guide and Participation use focused sections.
- Family Community: verify annual policy, membership, leadership and finance are navigable as separate work areas.
- Alumni and another productized vertical: verify Admin is a focused workspace rather than an all-modules stack.
- Shared surfaces: verify Funds, Voting, Community Life / Activity, Contributions, Product Guide and Media Management show one peer area/filter context at a time.
- Mobile: verify section navigation becomes selectors/submenus and does not require a horizontally scrolling tab rail.
- Change Appearance using the single dropdown and verify Classic / Modern / Dark are visibly distinct.

## Automated evidence available in this source
- `npm run validate:launch-runtime-hotfix` — 18 runtime-contract checks.
- `npm run validate:ux-progressive` — 23 cross-vertical progressive-disclosure checks.
- `npm run validate:final-launch` — launch source closure.
- `npm run validate:showcase-stabilization` — updated to certify the three-theme selector.
- HS0→HS6 source chain remains mandatory.

## Still requires the real runtime environment
This repository still has no installed dependency tree in the packaging environment, so `eslint`, Next build and Playwright cannot be falsely certified here. After applying migration 114 in your normal/staging environment, complete `RUNTIME-VERIFICATION-CHECKLIST.md` and record actual pass/fail evidence.
