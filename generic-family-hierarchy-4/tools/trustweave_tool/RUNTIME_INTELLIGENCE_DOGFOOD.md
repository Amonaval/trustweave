# TrustWeave Runtime Intelligence dogfood

Canonical product source: `Amonaval/runtime-intelligence`.

Pinned R5.2 baseline: `3a903eafa55df9697238aed0c1be110c6241a057`.

## Install

From `generic-family-hierarchy-4`:

```bash
node scripts/install-runtime-intelligence.mjs
node scripts/runtime-intelligence-source-gate.mjs
npm run dev
```

## R5.2 architecture

- Development only; production returns the app unchanged.
- `?twdebug=0` disables and `?twdebug=1` enables for the browser session.
- React profiler/runtime emits normalized UREP evidence.
- TrustWeave mounts the existing mature `LdsDebugPanel` through `runtime-intelligence/panel`.
- A thin compatibility bridge translates UREP evidence into the panel's established report structures. There is no second React dashboard.
- `TrustWeave.Root` is attributed to `app/layout.tsx#RootLayout`.
- `TrustWeave.NetworkApp` is attributed to `components/NetworkApp.tsx`.

R5.3+ will progressively activate shared browser/runtime collectors and deeper React ownership/correlation while preserving the same mature panel UI.
