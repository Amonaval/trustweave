# R5.7.4 TrustWeave real-world validation

This is the final React closure checkpoint. Do not inject synthetic faults into TrustWeave.

## Setup

```bash
node scripts/install-runtime-intelligence.mjs
node scripts/runtime-intelligence-source-gate.mjs
npm run dev
```

Expected runtime pin: `0908f7c8d90d81745db788913a17e6292d2147a0`.

## Exercise representative TrustWeave flows

- [ ] Initial hydration/load.
- [ ] Network switch/navigation.
- [ ] Timeline filter changes and timeline-heavy interaction.
- [ ] Analytics open/load.
- [ ] Directory/search/filter.
- [ ] Tree-heavy view.
- [ ] Modal/profile open-close cycles.
- [ ] Representative API-heavy flow.
- [ ] `?twdebug=0` disables diagnostics cleanly.
- [ ] `?twdebug=1` re-enables diagnostics cleanly.

## Mature product surfaces

- [ ] Summary health/environment is plausible.
- [ ] ✨ Intelligence is present and conservative.
- [ ] ⚡ Opportunities is present and shows actionable signals only when evidence exists.
- [ ] Opportunity cards preserve evidence level and drill into detailed tabs.
- [ ] 🔍 Pinpoint/Fix workflow opens findings and credible React source paths.
- [ ] Network + Slow API collect requests.
- [ ] Vitals collect available browser metrics.
- [ ] Console/Errors capture without breaking host console.
- [ ] Events show UREP/interaction activity.
- [ ] Perf shows NetworkApp plus strategic inner boundaries without duplicate root timing.
- [ ] Memory shows owner lifecycle/resource evidence where instrumented.
- [ ] JSON + HTML exports contain normalized findings/opportunities.

## Trust / evidence quality

- [ ] No synthetic Fault Lab evidence appears.
- [ ] No React finding recommends Lit-only APIs such as `updated()` or `disconnectedCallback()`.
- [ ] No fabricated fallback source path is shown when attribution is unavailable.
- [ ] Interaction→render/network links are correlation unless stronger evidence exists.
- [ ] Network→state remains temporal correlation.
- [ ] No React `UPDATE_CAUSE` is claimed from timing proximity.
- [ ] No uninstrumented hook dependency is called causal.
- [ ] Resource lifetime violations appear only for explicitly tracked resources that outlive an owner.
- [ ] A healthy flow is allowed to remain healthy; Runtime Intelligence does not manufacture problems.

## Final artifact

After normal use, export one JSON report and one HTML report. If those reports are credible and low-noise, React validation is closed. Future React changes should be driven by real product defects or missing high-value evidence, not additional synthetic parity missions.
