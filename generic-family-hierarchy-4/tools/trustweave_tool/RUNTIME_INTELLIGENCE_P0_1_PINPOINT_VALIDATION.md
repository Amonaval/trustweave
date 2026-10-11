# Runtime Intelligence P0.1 — TrustWeave Source Pinpoint Validation

Runtime Intelligence is pinned to the P0.1 universal source provenance baseline for real-world React dogfood.

## Runtime pin

`a465a67bc7378bba9b605f39bb41c1efb3b8b3bc`

This validation is intentionally performed against normal TrustWeave behavior. Do not add synthetic faults to TrustWeave.

## Setup

From `generic-family-hierarchy-4`:

```bash
node scripts/install-runtime-intelligence.mjs
node scripts/runtime-intelligence-source-gate.mjs
```

Restart the Next development server after installing a new runtime pin. If Next still serves a stale package, remove `.next` and restart before evaluating provenance.

Enable Runtime Intelligence using the existing `?twdebug=1` flow.

## Required real-world checks

Exercise normal TrustWeave flows that create browser/runtime evidence, especially API-backed actions.

For a finding with deterministic runtime provenance, verify the canonical panel shows:

1. an application source path rather than a Runtime Intelligence / React / Next / `node_modules` frame;
2. line and column when the browser stack exposes them;
3. the provenance meaning (`invocation`, `error`, `registration`, or other explicit kind) rather than presenting every location as a root cause;
4. an application-only stack when available;
5. the same source in the normalized report / Opportunities model where that finding is surfaced.

A useful network example should look conceptually like:

```text
src/.../service-or-hook.ts:87:14
provenance: invocation
```

not merely:

```text
(network)
```

or a frame inside `runtime-intelligence`, React, Next, webpack, or `node_modules`.

## Evidence honesty

A source location answers **where the observed operation originated**. It must not automatically be described as the business/root cause.

If only framework/vendor frames exist, showing `source unavailable` is preferred over inventing a file.

React render timing remains a separate limitation: a Profiler observation does not automatically reveal the component-definition line unless trustworthy source metadata exists.

## Closure bar

P0 source pinpoint is not considered mature merely because the Fault Lab or unit tests show a source.

The closure bar is real TrustWeave use: from an unfamiliar finding, a developer should be able to open the displayed application file/line and immediately land at the relevant invocation or observed source without manually searching the repository.
