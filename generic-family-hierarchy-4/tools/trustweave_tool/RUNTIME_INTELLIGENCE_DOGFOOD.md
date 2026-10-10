# TrustWeave Runtime Intelligence dogfood

Canonical product source: `Amonaval/runtime-intelligence`.

Pinned R5.3 baseline: `d051810f4a29fb932be5a27a99b852e987d76be8`.

## Install

From `generic-family-hierarchy-4`:

```bash
node scripts/install-runtime-intelligence.mjs
node scripts/runtime-intelligence-source-gate.mjs
npm run dev
```

## Current architecture

- One mature panel: `LdsDebugPanel` via `runtime-intelligence/panel`.
- React runtime emits normalized UREP evidence; no parallel React dashboard exists.
- Shared browser collectors now activate Network, Core Web Vitals, Console, window errors/unhandled rejections and privacy-safe interaction observations.
- Existing DOM duplication, virtualization, paint, worker, idle and update-budget advisers remain shared.
- Network observations are also emitted into UREP for later cross-signal intelligence.
- `TrustWeave.Root` is attributed to `app/layout.tsx#RootLayout` and `TrustWeave.NetworkApp` to `components/NetworkApp.tsx`.

Expected visible product surfaces now include the mature Summary, Network, Vitals, Console/Errors, Events, Slow API, profiler/perf and adviser-backed Pinpoint/Intelligence areas. R5.4 deepens React component/effect/resource ownership.
