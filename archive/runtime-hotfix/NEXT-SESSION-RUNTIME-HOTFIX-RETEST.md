# NEXT SESSION — TrustWeave Runtime Hotfix Retest & Pilot GO/NO-GO

Use `TRUSTWEAVE-LAUNCH-RUNTIME-UX-CLOSURE-FULL.zip` as the **only source of truth**. This supersedes the earlier launch candidate. Do not merge older checkpoints.

## Why this session exists
The first persisted seed rehearsal succeeded, then exposed real runtime issues: missing PostgREST RPC contracts, an invalid funds column reference, explicit Open Voting preserving a future timestamp, network-media authorization friction, and overly long/uncategorized operational surfaces that were first obvious in Housing Society. The UX closure has now been applied cross-vertical. Those are addressed in this hotfix; this session must prove them against the same real Supabase environment.

## Execute sequentially
1. Restore dependencies from the included lockfile and run `npm run lint:trustweave`, `npm run validate:static`, `npm run build`.
2. Apply every pending migration through **114_final_launch_runtime_contract_repair.sql** to the seeded/staging Supabase project.
3. Run `npm run validate:launch-runtime-hotfix`, `npm run validate:ux-progressive`, `npm run validate:final-launch`, `npm run validate:showcase-stabilization`, `npm run validate:showcase-residential`, `npm run validate:e10-closure`, `npm run validate:hs6`, `npm run validate:fca0`, and `npm run qa:db-static`.
4. Follow `RUNTIME-HOTFIX-APPLY-RUNBOOK.md` and explicitly retest all five reported runtime failures: HS operations snapshot, funds, Open Voting, mentions, private media.
5. Rehearse the progressive-disclosure rule across seeded Residential and Family Community plus Family/Alumni/productized shells: Admin/Manage, Funds, Voting, Community/Activity, Guide, Contributions, Media and mobile navigation. Reject any return to giant all-modules-at-once continuation scrolling or horizontally scrolling navigation rails.
6. Verify the Appearance control exposes only **Classic / Modern / Dark** in one dropdown, with old Warm/Aurora local preferences migrating safely.
7. Run the final launch desktop/mobile Playwright and persisted seed/idempotency checks; verify notification exact deep links, Push, private media, role boundaries and cross-network isolation.
8. Update `LAUNCH-READINESS-REPORT.md` with real runtime evidence and make an explicit **GO / NO-GO** decision.

## Binding rule
Do not add another broad feature mission during this retest. Fix only defects that block a flagship launch journey. The next product/UX mission should be driven by this real rehearsal evidence after the hotfix is proven.
