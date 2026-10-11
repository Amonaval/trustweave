# Runtime Intelligence P0.4 — TrustWeave Source Pinpoint Validation

Runtime Intelligence is pinned to the P0.4 browser-accepted source-attribution baseline for real-world React dogfood.

## Runtime pin

`db9a3ee4e805118076e27c37d1a82e84888ad50f`

This validation is intentionally performed against normal TrustWeave behavior. **Do not add synthetic faults to TrustWeave.**

## Setup

From `generic-family-hierarchy-4`:

```bash
node scripts/install-runtime-intelligence.mjs
node scripts/runtime-intelligence-source-gate.mjs
```

Restart the Next development server after installing a new runtime pin. If Next still serves a stale package, remove `.next`, remove stale `node_modules/runtime-intelligence` if necessary, rerun the installer, and restart before evaluating provenance.

Enable Runtime Intelligence using the existing `?twdebug=1` flow.

## Required real-world checks

Exercise normal TrustWeave flows that create browser/runtime evidence, especially API-backed actions and strategically instrumented React components.

For an unfamiliar finding, verify the canonical panel shows:

1. an application source path rather than Runtime Intelligence / React / Next / webpack / `node_modules`;
2. line and column when the runtime or registration stack exposes them;
3. an explicit provenance meaning instead of presenting every location as root cause;
4. an application-only stack when available;
5. the same source/provenance in Opportunities or normalized reporting when that finding is surfaced;
6. a location useful enough that the developer can open the file and reach relevant code without repository search.

## P0.2 React expectations

### Component boundary

For a component wrapped with `withRuntimeIntelligence(...)`, the runtime may show:

```text
components/NetworkApp.tsx:...
provenance: Component boundary
```

This is the boundary registration location. It is useful source context, **not a claim that this line caused an expensive render**.

### Tracked state update

When `useRuntimeTrackedState` records an update request, prefer the actual application setter invocation location:

```text
components/...tsx:188:7
provenance: invocation
```

That answers where the tracked update was requested. It does not automatically establish business/root causality.

### Effect / resource registration

For runtime-tracked effects and resources, the source should identify the hook/registration location. If a tracked resource survives owner teardown, the lifetime-violation finding should point to the **resource registration** source rather than the later teardown line.

### Derived performance diagnostics

If an update-budget diagnostic is derived from a source-bearing React update, it should retain that provenance while remaining correlation-level evidence. It must not gain confirmed causality merely because a file/line is known.

## Network / browser expectations

P0.1 behavior must remain intact:

- fetch/XHR findings retain the application invocation stack where available;
- browser errors/rejections retain application error-origin source where provable;
- sequential API findings retain a common originating call site when supported by evidence.

A useful network example should look conceptually like:

```text
src/.../service-or-hook.ts:87:14
provenance: invocation
```

not merely `(network)` or a frame inside Runtime Intelligence, React, Next, webpack, or `node_modules`.

## Evidence honesty

A source location answers **where a proven observation, invocation, registration, or boundary occurred**. It is not automatically a root cause.

React Profiler render timing remains observation/framework-reported evidence. P0.2 may attach a known Component boundary to that observation, but it does not invent update cause or confirmed causality.

If exact original source cannot be proven, generated/related/unknown is preferable to false precision.

## Remaining hard case

Completely uninstrumented React components may still lack an exact original component-definition line. That requires a separate evidence-honest dev/fiber/source-map/build-metadata path if real dogfood proves it is necessary.

Do not treat the existence of a bundled/generated frame as proof of the original TSX definition.

## Closure bar

P0 source pinpoint is not mature merely because unit tests or Fault Labs show a source.

The closure bar is real TrustWeave use:

> From an unfamiliar real finding, a developer should be able to use the displayed application file/line/provenance and immediately reach the relevant TrustWeave code without manually searching the repository.

Record any case that still requires repository search; that is input for the remaining P0.3 work.

## P0.4 console/export acceptance

The pinned package captures warning/error invocation stacks into UREP and releases subscribers on teardown. Verify any naturally occurring console messages have application source where supported. Do not inject a warning/error to make this real-consumer gate pass.

Raw collector `callStack` values are omitted from JSON/HTML exports. UREP retains bounded application provenance. Generated module coordinates are not original TSX coordinates; Pinpoint must label them.

Current mission evidence and pending connected checks are recorded in `RUNTIME_INTELLIGENCE_P0_4_NORMAL_FLOW_ACCEPTANCE.md`.
