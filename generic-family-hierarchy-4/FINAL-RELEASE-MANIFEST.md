# TrustWeave — Runtime Contract + Cross-Vertical UX Closure Manifest

**Candidate date:** 2026-09-15  
**Release state:** **SOURCE-CLOSED / LIVE RUNTIME RETEST REQUIRED**

This baseline supersedes `TRUSTWEAVE-LAUNCH-CANDIDATE-FULL.zip`. It combines the real seeded-network runtime repairs with the product-wide progressive-disclosure UX closure requested after rehearsal. It is not production GO until migration 114 and the dependency-backed/live runtime checklist pass in the real/staging environment.

## Runtime defects repaired in source
- restores `public.hs4_get_operations_snapshot()` and PostgREST schema reload;
- fixes funds snapshot `a.type` → `a.activity_type`;
- explicit **Open Voting** opens immediately instead of preserving a future `opens_at`;
- restores typed `public.route_network_mentions(...)`;
- repairs private media network authorization and removes ambiguous first-membership client fallback.

Database repair is additive migration `supabase/migrations/114_final_launch_runtime_contract_repair.sql`. **Frontend deployment alone is insufficient.**

## Cross-vertical UX closure
The permanent rule is no longer Housing-specific: substantial peer operational areas must not be appended indefinitely down one page. Prefer focused workspaces, desktop tabs/mobile selectors, card-grid entry points and accordions for advanced detail.

Implemented across Housing, Family, Family Community / Association, Alumni and shared productized Network OS surfaces, including Admin/Manage, Community, Contributions, Product Guide, Funds, Voting, Activity/Groups, Media Management, Family Participation and multi-network tool navigation. Appearance is reduced to **Classic / Modern / Dark**.

Permanent guard: `npm run validate:ux-progressive` — **23/23 PASS**.

## Delta from previous launch candidate
- Added / relocated paths: **14**
- Modified paths: **51**
- Removed / archived paths: **1**
- Present files in affected overlay: **65**
- Total path delta: **66**
- Present path list: `RUNTIME-UX-CLOSURE-AFFECTED-FILES.txt`
- Removal list: `RUNTIME-UX-CLOSURE-REMOVED-FILES.txt`

## Source validation evidence
- Progressive-disclosure UX gate: **23/23 PASS**
- Runtime hotfix gate: **18/18 PASS**
- Final launch source gate: **24/24 PASS**
- Showcase stabilization: **14/14 PASS**
- Residential flagship: **12/12 PASS**
- FCA0: **27/27 PASS**
- HS0→HS6: **PASS**
- E10 closure + E1→E10: **PASS**
- Static syntax: **344 TS/TSX / 0 syntax errors**
- Migration static audit: **112 SQL / PASS**
- Evidence: `release-evidence/RUNTIME-UX-CLOSURE-SOURCE-GATES.txt`

## Candidate tree fingerprint
SHA-256 over sorted `relative/path + file SHA-256` entries, excluding this manifest and the two self-referential runtime-UX path-list files:

`9b997e26868def59d7bd01b1583278225f8aa08701b7403158eece2f7fd9ea18`

## Mandatory live/dependency proof still pending
The packaging environment has no installed dependency tree and npm restoration previously failed against `registry.npmjs.org` with `EAI_AGAIN`. Therefore this manifest does **not** claim PASS for `lint:trustweave`, complete TypeScript/static validation, Next production build, headed/mobile Playwright, or the live migration-114 retest.

Apply migration 114 to the same Supabase project used for the seeded rehearsal and follow `RUNTIME-HOTFIX-APPLY-RUNBOOK.md` plus `RUNTIME-VERIFICATION-CHECKLIST.md`.

## Baseline rule
`TRUSTWEAVE-LAUNCH-RUNTIME-UX-CLOSURE-FULL.zip` becomes the only source of truth for the next runtime retest. Do not merge older launch/E-mission ZIPs into it.
