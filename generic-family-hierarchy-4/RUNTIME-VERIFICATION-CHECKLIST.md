# TrustWeave — Final Runtime Verification Checklist

**This checklist is the binding final go/no-go gate.**

## A. Local dependency/build proof
- [ ] `npm ci` succeeds from the committed lockfile.
- [ ] `npm run lint:trustweave` — **0 errors**. Warnings reviewed.
- [ ] `npm run validate:static` — PASS.
- [ ] `npm run build` — PASS.
- [ ] `npm run validate:final-launch` — PASS.
- [ ] `npm run qa:db-static` — PASS.

## B. Staging database / environment
- [ ] Approved staging/QA Supabase project selected.
- [ ] Migration 113 applied after all prior migrations.
- [ ] Required storage buckets/policies available.
- [ ] VAPID / Push env configured if Push is in launch scope.
- [ ] No production customer network is used for destructive certification.

## C. Fresh Residential persisted proof
- [ ] Create a fresh `housing-society` certification network.
- [ ] Set it active and open as owner/admin.
- [ ] Final launch loader is visible only in persisted Admin.
- [ ] Bundled Residential dataset dry run is valid with 0 reference errors.
- [ ] Exact network-name confirmation required.
- [ ] Commit completes with 0 errors.
- [ ] 25 units / expected resident directory are present.
- [ ] Home counts match underlying seeded data.
- [ ] Notices, complaints/comments/routing, amenities/bookings are meaningful.
- [ ] Maintenance cycles/bills/payments/adjustments/funds/budget/expenses are meaningful.
- [ ] Committee, meetings, actions/resolutions and election/poll are present.
- [ ] Visitors/staff/move/renovation/assets/compliance/emergency are present.
- [ ] Community events/posts/comments and media are present.
- [ ] Complaint media is private and signed.
- [ ] Notification deep link opens the exact complaint/post/fund/election item.
- [ ] Re-run same dataset: no duplicate core/domain records; expected 0-created/idempotent result.
- [ ] Resident role sees own permitted flat/household context and cannot see admin-only data.

## D. Fresh Family Community persisted proof
- [ ] Create a fresh `family-association` certification network.
- [ ] Bundled Family Community dry run valid with 0 reference errors.
- [ ] Commit completes with 0 errors.
- [ ] 20 families and 67 people are represented.
- [ ] Household relationships and Family Structure are present.
- [ ] Annual membership records are persisted through FCA governed membership APIs.
- [ ] Active/grace/pending/payment states display coherently.
- [ ] Committee role catalog/assignments are present.
- [ ] Events, announcements, funds, elections, posts/comments, memories and groups are present.
- [ ] Account-only RSVP/group constraints produce understood warnings, not fabricated auth users.
- [ ] Invitations/contribution prompts and media are present.
- [ ] Re-run same dataset is idempotent.
- [ ] Representative/member roles see the correct family/member-safe view.

## E. Anonymous + desktop/mobile UX
- [ ] Anonymous visitor understands product within first 10 seconds.
- [ ] Housing journey works.
- [ ] Family Community journey works.
- [ ] Member/resident journey works.
- [ ] Playground reachable without sign-in.
- [ ] Product Guide Simple/Detailed/Deep works.
- [ ] Sign in/create flow remains reachable.
- [ ] Desktop topbars and More state correct.
- [ ] Mobile topbars/sheets/close/back correct.
- [ ] Loading, empty and error states acceptable.
- [ ] EN/HI/MR token integrity acceptable for launch surfaces.

## F. Engagement / privacy / isolation
- [ ] Notification inbox discoverable.
- [ ] Push enable/disable works.
- [ ] Engagement Control Center preferences persist.
- [ ] Exact deep links verified for flagship notifications.
- [ ] Private media not publicly readable.
- [ ] Role permissions verified.
- [ ] Launch Control discovery/create/playground behavior verified.
- [ ] Existing memberships remain visible independent of showcase visibility.
- [ ] Cross-network data leakage check passes.

## G. Final decision
- [ ] `LAUNCH-READINESS-REPORT.md` updated with runtime evidence/date/environment.
- [ ] No known launch-blocking defect remains.
- [ ] Final decision recorded: **GO** or **NO-GO**.

## Hotfix 114 targeted retest — mandatory
- [ ] `hs4_get_operations_snapshot()` resolves in PostgREST and Housing operations render.
- [ ] Funds snapshot opens without `column a.type does not exist`.
- [ ] Explicit Open Voting makes a future-scheduled draft ballot votable immediately by an eligible member.
- [ ] `route_network_mentions(...)` resolves and a real mention routes a notification.
- [ ] Creator/admin can upload private media after explicitly selecting the network; another network cannot read it.
- [ ] Manage Society renders one workspace area at a time on desktop and mobile.
- [ ] Finance/Governance/Security subsections prevent extreme all-module vertical scrolling.
- [ ] Appearance is a single Classic/Modern/Dark selector and all three are visibly distinct.

## Mission 1 seed/media retest — mandatory
- [ ] Apply migrations through `115_mission1_runtime_seed_integrity.sql` to the same Supabase project.
- [ ] Community post + photo succeeds without SQLSTATE `22023`; media survives refresh and remains tenant-private.
- [ ] Family Community seed completes with 0 unexplained errors; download report if not.
- [ ] Family Community unchanged rerun produces no accidental duplicate creates.
- [ ] Housing seed completes with 0 unexplained errors; download report if not.
- [ ] Housing unchanged rerun produces no accidental duplicate creates.
- [ ] Migration-114 operations/funds/voting/mentions/media paths remain green.

Known Family Community constraints (113 for the supplied full dataset) must be shown as warnings, not mixed into the error count.


## Mission 2 slow automated user regression — mandatory before Mission 3
- [ ] Migrations through 115 are applied to approved staging/QA.
- [ ] `.env.qa` points only to staging/QA and `QA_ALLOW_MUTATION=true` is explicitly enabled.
- [ ] `npm run qa:mission2` executes with one worker.
- [ ] Mission-1 fresh Residential + Family Community seed/idempotency retest passes first.
- [ ] Community post + real photo + comment persists across reload with no unexpected API 4xx/5xx.
- [ ] Funds + transaction normal UI flow passes.
- [ ] Ballot create → 2 options → Open Voting → cast vote passes.
- [ ] Housing notice + complaint photo + charge head + committee meeting + visitor preapproval pass.
- [ ] Housing normal member complaint succeeds and admin workspace remains inaccessible.
- [ ] Family Community membership year + annual family membership persist.
- [ ] Family, Family Community and Housing owner/admin/member slow crawls have zero unexplained runtime/API failures.
- [ ] Mobile Family Community progressive navigation passes.
- [ ] Cross-tenant negative isolation proof passes.
- [ ] `qa-results/mission2/runtime-issues.ndjson` contains no unexplained issue.
- [ ] `qa-results/BUG-REPORT.md` has no unresolved launch-blocking finding.
- [ ] Runner result is **MISSION2_CERTIFIED**.
