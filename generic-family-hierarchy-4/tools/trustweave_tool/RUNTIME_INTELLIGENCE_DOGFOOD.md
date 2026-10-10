# TrustWeave Runtime Intelligence dogfood

Canonical product source: `Amonaval/runtime-intelligence`.

Pinned R5.4 baseline: `9b707e0b5eaf5a527e868011784c3aa93f1a11cc`.

## Install

```bash
node scripts/install-runtime-intelligence.mjs
node scripts/runtime-intelligence-source-gate.mjs
npm run dev
```

## Current product path

- One mature `LdsDebugPanel`; no React-specific dashboard.
- Shared browser surfaces populate Network, Vitals, Console/Errors, Events and Slow API.
- React profiler boundaries populate mature Perf and Memory.
- React Runtime Intelligence now has nearest-owner hierarchy plus opt-in tracked state/effect/resource hooks.
- Tracked state changes feed the existing Perf render-reason drill-down and property-thrash Pinpoint path.
- Unreleased tracked resources become lifecycle violations in the existing Pinpoint workflow.
- Evidence remains explicit: uninstrumented hook causality is not guessed.

R5.5 adds cross-signal correlation and investigation intelligence; R5.6 hardens the TrustWeave dogfood and closes practical parity gaps.
