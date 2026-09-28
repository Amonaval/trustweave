# TrustWeave Runtime Intelligence

Framework-neutral browser observability core with a React/Next adapter. It is the TrustWeave port of the Lit/RUF debugging panel rather than a separate product implementation.

## Activate

Add `?twdebug=1` to any TrustWeave URL. The flag persists for the current browser session. Use `?twdebug=0` to disable it.

When disabled the toolkit installs no React profiler, fetch patch, console patch, PerformanceObserver, interaction listener or panel.

## Current panel parity

- Summary and evidence-based Pinpoint
- Vitals: LCP, CLS, INP approximation via Event Timing, long tasks
- Network: status, latency, content type/declared size, failed/slow/duplicate request detection
- Perf: named React Profiler boundaries with mount/update commit counts, average and worst duration
- Errors: uncaught errors and unhandled rejections, observation only
- Console: local log/info/warn/error/debug capture
- Actions: click/input/change/submit/keydown timeline (generic equivalent of an application action timeline)
- Memory: mount/unmount/GC probe evidence without unsupported leak verdicts
- History: up to 20 manually saved browser-session snapshots
- Environment: route, browser/device/connection basics
- Inspect: pick a rendered element and map it back to React fiber; show owning component, current memoized props, component chain and best-effort hook state
- Copy report: structured JSON suitable for AI/source-code correlation

## Adapter contract

The core under `tools/runtime-observability` contains no TrustWeave business logic. React integration is deliberately thin:

```tsx
<RuntimeProfiler name="MemberDirectory">
  <MemberDirectory />
</RuntimeProfiler>
```

The root already profiles `TrustWeaveRoot` and `NetworkApp`. Add named boundaries only around surfaces where component-level attribution adds value; do not wrap every component blindly.

## Correctness choices carried forward from the Lit review

- global monkey patches always restore on detach
- errors are never swallowed or replaced by fallback UI
- repeated-request detection only classifies GET/HEAD bursts
- component count alone is never called a render storm
- mounted-minus-unmounted alone is never called a memory leak
- React Profiler values are labeled commit duration, not generic browser render time
- no arbitrary 0–100 score is presented as objective health
- the panel is outside the profiled root to prevent a self-observation feedback loop

## React inspector caveat

The DOM-to-component inspector reads React's private fiber pointer as a best-effort developer-tool technique. React does not expose this as a public API, so it is isolated inside the adapter and must never become application logic.
