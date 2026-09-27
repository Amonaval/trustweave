# TrustWeave Runtime Observability

Independent, browser-local runtime diagnostics adapted from the Lit/RUF debugging-tool concept.

## Why this exists

TrustWeave is React/Next, while the original toolkit uses Lit/RUF as its component instrumentation seam. This folder keeps the diagnostic core independent and adds a React adapter rather than coupling the tool to TrustWeave product code.

## Activate

Open any TrustWeave URL with `?twdebug=1`. The setting persists for the current browser tab/session. Use `?twdebug=0` to disable it again.

When disabled, no fetch patch, PerformanceObserver, error listener, React Profiler or panel is installed.

## What is observed in this first integration

- named React Profiler boundaries: commit duration and mount/update phase
- component boundary mount/unmount churn (rate-based, not cumulative-count "storm" guesses)
- fetch/Supabase request duration, status and repeated-request bursts
- browser errors and unhandled promise rejections (observation only; never swallowed)
- browser long tasks
- DOM size
- evidence-based Pinpoint findings
- local JSON report copied from the panel

## Safety / architecture choices

- no external endpoint and no auto-post
- no error recovery behavior
- all global patches/listeners have explicit disposers and are restored on detach
- no "memory leak" claim from active component counts; true retained-object leak detection needs stronger evidence and remains intentionally out of scope
- performance values are called React commit durations, not generic "render time"
- no arbitrary single health score; findings are evidence based

## Adding a named React boundary

```tsx
import RuntimeProfiler from "../tools/runtime-observability/react/RuntimeProfiler";

<RuntimeProfiler name="MemberDirectory">
  <MemberDirectory />
</RuntimeProfiler>
```

That is the intended integration contract: one wrapper, no change inside the observed component.
