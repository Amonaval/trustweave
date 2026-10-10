# R5.6 TrustWeave validation checklist

## Architecture gates

- [ ] `node scripts/install-runtime-intelligence.mjs` resolves both `/react` and `/panel`.
- [ ] `node scripts/runtime-intelligence-source-gate.mjs` passes.
- [ ] No active import from `tools/react-runtime-toolkit`.
- [ ] Production behavior unchanged; diagnostics remain development-only.

## Mature product surfaces

- [ ] Summary health/environment renders.
- [ ] ✨ Intelligence tab is present.
- [ ] Pinpoint/Fix workflow opens findings and source paths.
- [ ] Network + Slow API collect requests.
- [ ] Vitals collect available browser metrics.
- [ ] Console/Errors capture without breaking host console.
- [ ] Events show UREP/interaction activity.
- [ ] Perf shows NetworkApp plus strategic inner boundaries.
- [ ] Memory shows owner lifecycle without duplicate root timing.
- [ ] History/export/compare remain functional.

## Evidence honesty

- [ ] Interaction→render/network links are presented as correlation.
- [ ] Network→state remains temporal correlation.
- [ ] No React `UPDATE_CAUSE` is claimed from timing proximity.
- [ ] No uninstrumented hook dependency is called causal.
- [ ] Resource lifetime violation appears only for explicitly tracked resources that outlive an owner.

## TrustWeave flows

- [ ] Initial hydration/load.
- [ ] Network switch/navigation.
- [ ] Timeline filter changes.
- [ ] Analytics open/load.
- [ ] Directory/search/filter.
- [ ] Tree-heavy view.
- [ ] Modal/profile open-close.
- [ ] `?twdebug=0` clean disable / `?twdebug=1` re-enable.
