# Mission 2 Playwright Start Delay — Quick Apply

Apply this overlay after the Mission-2 QA Harness Correction + Login Quick Fix.

Changes:
- Adds a one-time 50 second warm-up after localhost becomes reachable and before the first Mission-2 Playwright test starts.
- Adds Playwright-only rerun commands that skip source/static/build preflight.
- Does not modify `qa/lib/login.ts`.

Commands:

- Full certification (includes preflight/build): `npm run qa:mission2:headed`
- Browser runtime only, headed: `npm run qa:mission2:playwright:headed`
- Browser runtime only, normal: `npm run qa:mission2:playwright`
- Browser runtime only, slower 1s action pace: `npm run qa:mission2:playwright:slow`

`--playwright-only` requires the existing deterministic fixture at `qa-results/fixtures/seed-state.json`; it will not recreate it or run build/preflight.

The first Playwright invocation waits 50 seconds after localhost is reachable. Later Playwright groups in the same Mission-2 run reuse the warm-up marker and do not wait another 50 seconds.
