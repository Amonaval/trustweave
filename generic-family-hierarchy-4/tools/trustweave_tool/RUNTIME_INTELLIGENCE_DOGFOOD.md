# TrustWeave Runtime Intelligence dogfood

Pinned R5.5 runtime: `3e094b1bd5109f69991cb9fb285836018e1f711f`.

```bash
node scripts/install-runtime-intelligence.mjs
node scripts/runtime-intelligence-source-gate.mjs
npm run dev
```

## What should now work

The React app uses the same mature Runtime Intelligence product UI and core as Lit. Shared browser collectors populate Summary, Network, Vitals, Console/Errors, Events and Slow API. React profiler owners populate Perf/Memory/source attribution. Shared advisors feed Pinpoint and the existing Intelligence presentation.

R5.5 additionally provides bounded interaction context: click/change/submit can be correlated with subsequent React renders, tracked state and network completion inside a short window. EvidenceGraph labels those links correlation/temporal-inference; they are not claimed as causes. The shared intelligence pipeline uses EvidenceGraph, RootCauseGrouper, incident recording and evidence capsules and publishes the existing `__LDS_INTELLIGENCE__` contract.

R5.6 is the final parity-hardening pass: source/package checks, noise reduction, capability audit, TrustWeave-targeted profiler coverage and closure documentation.
