# React Runtime Toolkit

A framework-independent browser observability core plus an isolated React adapter. Designed to be copied/published as a package and plugged into any React 18+ application without app-specific business logic.

## Quick integration

For browser/runtime signals only:

```tsx
<RuntimeBridge enabled={debugEnabled} config={{brand: 'My App Runtime'}}>
  <App />
</RuntimeBridge>
```

For automatic React commit/fiber analysis, inject the preload script **before React initializes**:

```tsx
<script dangerouslySetInnerHTML={{__html: getReactRuntimePreloadScript()}} />
```

The preload installs/chains the React DevTools global hook. If React DevTools already owns the hook, it preserves it and observes the same commit callbacks. This is intentionally isolated because the hook/fiber shape is not a public React API.

## What it captures

- Web vitals evidence: LCP, FCP, CLS, Event Timing / INP evidence, navigation TTFB
- Long Animation Frames with script / forced-layout attribution when supported
- fetch + XHR with status, latency, initiator stack and pluggable decoding
- Resource Timing: transfer/encoded/decoded size, cache hints, protocol, server timing
- React commit tree summaries without wrapping every component when preload is present
- changed props and best-effort hook/state diffs
- shallow-equal reference churn (unstable object/array/function props)
- interaction → React commit → request correlation
- element inspector: DOM → React fiber → component → live props/state
- runtime/resource errors and an optional React error boundary
- console capture
- DOM node count, max depth, mutation rate and WeakRef detached-node probes
- JS heap sampling where supported and `measureUserAgentSpecificMemory()` when available
- optional timer inventory
- snapshots and regression deltas
- evidence-based Pinpoint findings and JSON export

## Safety / honesty rules

The toolkit intentionally does **not** call an active component a leak, does not label every parent-driven render unnecessary, and does not turn arbitrary weighted deductions into an objective health score. Experimental/private APIs are capability-detected and isolated.

## Plug-ins

```ts
registerNetworkDecoder(sample => {
  if (!sample.url.includes('/graphql')) return;
  return {protocol: 'graphql'};
});

registerFindingRule((snapshot, config) => []);
```

Keep application-specific decoders and rules outside this package.

## Performance modes

The browser observers run only while the bridge is enabled. Deep fiber analysis is debug-only and intentionally bounded (component and history caps). React's official `<Profiler>` also adds overhead and production profiling requires React's profiling build, so use this toolkit as an investigation tool rather than always-on production code.
