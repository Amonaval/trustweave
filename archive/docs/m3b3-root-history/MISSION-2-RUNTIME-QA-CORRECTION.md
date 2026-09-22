# Mission 2 — Runtime QA Correction

## Defects confirmed from the first external run
- Final-launch seed runtime clicked a hidden `qa-nav-admin` after Admin moved behind progressive navigation.
- `30-mission2-family-and-mobile.spec.ts` had a malformed `testInfo})` callback.
- A stray root copy of `16-phase2-representative-capabilities.spec.ts` caused `../lib/*` module resolution errors during project-wide TypeScript checks.
- Phase-4D tests dereferenced optional template `notes` without null-safe handling.
- Windows CMD cannot execute Bash-style `QA_M2_HEADED=true ...`.
- Media upload still reported membership denial in a network created by the user.

## Corrections
- Responsive `openSurface()` now selects visible desktop/mobile/More-menu controls.
- Project-wide QA scan removes malformed `testInfo})` signatures.
- QA Playwright runtime/type imports are separated (`import` + `import type`).
- Stray root Phase-2 spec removed; canonical spec remains under `qa/e2e/`.
- Phase-4D optional notes assertions are null-safe.
- Cross-platform `qa:mission2:headed` and `qa:mission2:slow` npm scripts added.
- Owner/admin/member crawler expanded to all released verticals.
- Every instrumented owner surface now produces an interactive control inventory.
- Historical broad regression pack is part of Mission 2.
- Migration 116 introduces explicit Storage path actor + active membership authorization and a pre-upload media access contract.

## Database apply order
Apply migrations through **116**, reload the app, then run `npm run qa:mission2`.
