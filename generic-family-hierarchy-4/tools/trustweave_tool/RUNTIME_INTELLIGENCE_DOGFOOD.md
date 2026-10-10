# TrustWeave Runtime Intelligence — R5.6 dogfood

Pinned canonical runtime: `ec86b2d944c4144b69f78a9cfc9251dd101d762a`.

```bash
node scripts/install-runtime-intelligence.mjs
node scripts/runtime-intelligence-source-gate.mjs
npm run dev
```

## What to expect

This is now the mature Runtime Intelligence product, not the discarded lightweight React panel. The same panel exposes Summary, ✨ Intelligence, Pinpoint, Vitals, Network, Perf, Errors, Console, Events, Slow API, Memory, History/compare/export and Environment. App-specific Falcor remains relevant only where the app uses Falcor.

TrustWeave intentionally disables timing on the structural `TrustWeave.Root` provider to avoid double-counting the same commits. Meaningful Perf boundaries include `TrustWeave.NetworkApp`, `TrustWeave.AnalyticsPanel`, `TrustWeave.TimelineView` and `TrustWeave.UpcomingWidget` when those surfaces render.

Shared browser collectors provide Network/Vitals/Console/errors/interactions. Shared advisers provide DOM duplication, virtualization, paint, worker, idle, sequential API and update-budget signals. React adds source-attributed profiler ownership plus optional tracked state/effect/resource evidence. The Intelligence engine uses the shared evidence graph/root-cause grouping/incident capsule stack and labels temporal relationships as correlation, never automatic causality.

## Tomorrow's browser checkpoint

Exercise initial load, navigation, Timeline filters, Analytics load, directory/tree-heavy flows, search/filter changes and a few modals. Check:

1. Mature panel appears with the original full tab set plus ✨ Intelligence.
2. Perf shows meaningful component boundaries rather than Root/NetworkApp duplicates.
3. Network/Vitals/Console/Events populate from normal use.
4. Pinpoint shows shared advisor findings only when evidence exists.
5. Intelligence says Possible/Strongest signal for temporal correlation, not Confirmed/Likely cause unless evidence supports it.
6. Source paths point back to TrustWeave files.
7. The application behaves normally with `?twdebug=0` and with diagnostics enabled.

If something fails, share the panel output plus browser console error; the mission chain is now narrow enough that any remaining defect should be a targeted hardening fix, not another architecture rewrite.
