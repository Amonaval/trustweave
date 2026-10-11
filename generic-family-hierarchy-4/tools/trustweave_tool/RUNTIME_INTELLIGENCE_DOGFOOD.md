# TrustWeave Runtime Intelligence — R5.7.4 real-world closure

Pinned canonical runtime: `0908f7c8d90d81745db788913a17e6292d2147a0`.

```bash
node scripts/install-runtime-intelligence.mjs
node scripts/runtime-intelligence-source-gate.mjs
npm run dev
```

## What to expect

This is the mature Runtime Intelligence product with the validated React adapter and first-class Opportunities surface. The canonical panel exposes Summary, ✨ Intelligence, ⚡ Opportunities, 🔍 Pinpoint, Vitals, Network, Perf, Errors, Console, Events, Slow API, Memory, History/compare/export and Environment. App-specific Falcor remains relevant only where the app uses Falcor.

TrustWeave intentionally disables timing on the structural `TrustWeave.Root` provider to avoid double-counting the same commits. Meaningful Perf boundaries include `TrustWeave.NetworkApp`, `TrustWeave.AnalyticsPanel`, `TrustWeave.TimelineView` and `TrustWeave.UpcomingWidget` when those surfaces render.

Shared browser collectors provide Network/Vitals/Console/errors/interactions. Shared advisers provide DOM duplication, virtualization, paint, worker, idle, sequential API and update-budget signals. React adds source-attributed profiler ownership plus optional tracked state/effect/resource evidence. The Intelligence engine uses the shared evidence graph/root-cause grouping/incident capsule stack and labels temporal relationships as correlation, never automatic causality.

The Opportunities tab is the canonical actionable view over the same normalized opportunity model exported in JSON/HTML. It groups Performance, Network, Rendering, Scheduling and Memory opportunities, preserves evidence strength and observed/synthetic origin, and drills back into Pinpoint/Network/Perf for detailed evidence.

## Final real-world browser checkpoint

Use TrustWeave normally rather than injecting faults. Exercise:

1. Initial hydration/load and one network switch/navigation.
2. Timeline filters and timeline-heavy interaction.
3. Analytics open/load.
4. Directory/search/filter and tree-heavy views.
5. A few modal/profile open-close cycles.
6. Any representative normal flow that causes API traffic and React updates.
7. Verify `?twdebug=0` cleanly disables diagnostics and `?twdebug=1` re-enables them.

Then inspect the mature panel once and export JSON + HTML.

### Closure criteria

- Summary/health remains plausible for normal use; the tool does not manufacture failures merely because the app is busy.
- ✨ Intelligence stays conservative when no strong incident exists.
- ⚡ Opportunities shows only actionable optimization/reliability signals and gives meaningful drill-down.
- Perf attributes useful work to strategic React boundaries rather than duplicate root timing.
- Network/Vitals/Console/Events populate without changing host behavior.
- Pinpoint source paths and recommendations are credible for React.
- Temporal relationships are described as correlation unless stronger evidence exists.
- No synthetic Fault Lab evidence appears in TrustWeave.
- JSON/HTML exports contain normalized findings/opportunities and are sufficient for offline review.

If this checkpoint is clean, React validation is considered closed. Further React changes should be driven by real TrustWeave/product defects, not additional synthetic parity missions.
