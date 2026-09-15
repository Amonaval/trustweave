# TrustWeave — Final Release Manifest

**Candidate date:** 2026-09-15  
**Baseline input:** `TRUSTWEAVE-E10-STABILITY-ESLINT-CLOSURE-FULL.zip`  
**Release candidate outputs:** `TRUSTWEAVE-LAUNCH-CANDIDATE-FULL.zip` and `TRUSTWEAVE-LAUNCH-CANDIDATE-AFFECTED.zip`

## Release state
**SOURCE-CLOSED / FINAL RUNTIME CERTIFICATION REQUIRED.**

The exact candidate source contains the final pre-launch Discovery/Product Exploration work, guarded persisted launch-data orchestration, FCA annual-membership import closure, launch E2E specifications and synchronized living documentation. Source/regression gates are green. Dependency-backed lint/build/headed/mobile staging proof remains the mandatory final GO/NO-GO gate and is intentionally not represented as passed.

## Source delta from supplied FULL baseline
- Added/relocated release files: **35**
- Modified existing files: **25**
- Removed from root/source path: **2** (superseded Discovery handoffs archived)
- Present files carried by AFFECTED package: **60**
- Total source-path delta including removals: **62**
- Present affected path list: `FINAL-LAUNCH-AFFECTED-FILES.txt`
- Removed-path list for affected-patch consumers: `FINAL-LAUNCH-REMOVED-FILES.txt`

## Candidate tree fingerprint
SHA-256 over sorted `relative/path + file SHA-256` entries for the candidate tree, excluding the self-referential `FINAL-RELEASE-MANIFEST.md`, `FINAL-LAUNCH-AFFECTED-FILES.txt` and `FINAL-LAUNCH-REMOVED-FILES.txt`:

`18fa8bbee502e1ca909e26dadccd9aa5bcece575b9fd795899b26230e9e593fb`

## Final launch datasets
| File | SHA-256 | Bytes |
| --- | --- | ---: |
| `public/launch-demo/residential-25-flats.json` | `7849ca0ca4abda3287f7f77b7c0954b52aa0caff9d90552c597b8518b63ac9ee` | 106,367 |
| `public/launch-demo/residential-25-flats.xlsx` | `7d182ef304a7132e6c2c2990b73aeb7dd9ddf82ddd07ad1aa9c722028e2a1104` | 87,818 |
| `public/launch-demo/family-community-20-families.json` | `a4c06b20fe9d52f0f8e4d83c6bddc14bcb032a0e87bcfe05215d3fd76cb9c1d7` | 114,630 |
| `public/launch-demo/family-community-20-families.xlsx` | `5e704f567e63d9401cfa65a285190ff01430cb078e3d07dceeb8cf80ee69fb55` | 60,355 |


## Major implementation files
- `components/PublicDiscoveryPortal.tsx`
- `components/shared/LaunchDemoDataLoader.tsx`
- `core/launch-seed/contracts.ts`
- `capabilities/launch-seed/*`
- `supabase/migrations/113_final_launch_demo_seed_lineage.sql`
- `capabilities/import/productized-workbook.ts`
- `qa/e2e/25-final-launch-discovery.spec.ts`
- `qa/e2e/26-final-launch-seed-runtime.spec.ts`
- `scripts/final-launch-source-gate.mjs`

## Release closure documents
- `LAUNCH-READINESS-REPORT.md`
- `PILOT-DEMO-RUNBOOK.md`
- `DATA-SEED-RUNBOOK.md`
- `RUNTIME-VERIFICATION-CHECKLIST.md`
- `NEXT-SESSION-FINAL-RUNTIME-CERTIFICATION.md`

## Evidence captured in candidate
- `release-evidence/FINAL-LAUNCH-SOURCE-GATES.txt`
- `release-evidence/STATIC-EXTRA-GATES.txt`
- `release-evidence/NPM-DEPENDENCY-BLOCKER.txt`

## Validation snapshot before packaging
- Final launch source gate: **24/24 PASS**.
- Showcase stabilization: **14/14 PASS**.
- Residential flagship: **12/12 PASS**.
- E10 closure + E1→E10 chain: **PASS**.
- HS0→HS6: **PASS**.
- FCA0: **27/27 PASS**.
- Syntax: **341 TS/TSX files, 0 syntax errors**.
- Migration static audit: **111 SQL files, PASS**.

## Runtime certification state
The supplied baseline did not contain `node_modules`. Dependency restoration was attempted, but this execution environment could not resolve `registry.npmjs.org` (`EAI_AGAIN`), so the following are **not certified here**:
- `npm run lint:trustweave`
- complete `npm run validate:static` / TypeScript gate
- `npm run build`
- headed desktop Playwright launch walkthroughs
- mobile viewport launch walkthroughs
- staging execution of the fresh persisted Residential + Family Community seed/idempotency test

See `release-evidence/NPM-DEPENDENCY-BLOCKER.txt` and `RUNTIME-VERIFICATION-CHECKLIST.md`.

## Mandatory pending certification
Do not mark production launch GO until `RUNTIME-VERIFICATION-CHECKLIST.md` is fully complete: 0-error lint, full static/type check, Next build, migration 113 on the intended staging project, fresh persisted Residential and Family Community seed/idempotency proof, headed desktop, mobile viewport, notification/deep-link, push, private-media, role-permission and cross-network-isolation checks.

## Baseline rule
After the pending runtime checklist passes without a launch blocker, `TRUSTWEAVE-LAUNCH-CANDIDATE-FULL.zip` is the exact source baseline to promote. If runtime certification requires code changes, do **not** silently patch this ZIP; make the fixes from this candidate, rerun the complete closure gates, and issue a new candidate ZIP + manifest.
