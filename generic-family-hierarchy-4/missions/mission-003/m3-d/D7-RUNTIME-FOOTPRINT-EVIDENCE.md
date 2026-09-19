# M3-D7 — Runtime footprint & lazy vertical loading

**Baseline:** `llm-push` M3-D6 at `bc89b3ca7ae8b3f417e39c9769f0e046e589d099`.

## Implemented

D7 reduces universal startup coupling without changing product behavior.

### Universal shell split

`components/NetworkApp.tsx` no longer statically imports `AlumniNetworkApp` or `TemplateNetworkApp`. Both are loaded with Next dynamic imports only when the selected network requires them.

The universal shell also no longer imports the large `templates/productized/config.ts` showcase/sample dataset. A new lightweight `templates/productized/runtime-meta.ts` carries only startup-safe labels/sample names/descriptions.

### Productized vertical split

`TemplateNetworkApp.tsx` keeps the generic productized experience as the lazy shell, while Housing and Family Community specialty UI is loaded with dynamic boundaries:

- Family Association admin;
- Housing core/home/operations/finance/governance/security/pilot/manage workspace;
- Association home;
- Housing pilot telemetry remote.

Heavy sample entities/activities/groups/relationships remain in `templates/productized/config.ts`, which is now loaded only with the productized shell rather than the Family startup path.

### Runtime metadata

The canonical vertical manifest records `loadingBoundary` for each vertical. Capability metadata now distinguishes current shared runtime, productized lazy shell, and vertical lazy chunks.

This deliberately does not turn the manifest itself into an asynchronous registry: stable route/auth/navigation metadata remains synchronous and small. D10 thin-vertical tooling can later generate this metadata without requiring heavy UI modules to join the startup graph.

## Fitness guards

`qa/unit/runtime-footprint.test.ts` fails if:
- Alumni or productized apps return to static `NetworkApp` imports;
- heavy productized showcase config returns to the universal shell/manifest compositions;
- Housing/FCA specialty panels return to static `TemplateNetworkApp` imports;
- Housing pilot telemetry becomes statically imported.

The production `build` script now runs Next through `scripts/d7-build.mjs`, preserves the complete Next output, parses the authoritative root-route **First Load JS** value, and enforces a configurable ceiling through `scripts/d7-bundle-budget.mjs`.

The measured D7 root value from Next is **644 kB First Load JS** for `/`. The initial CI ceiling is **700 kB** (700,000 bytes), leaving bounded headroom while making startup growth visible. This replaces two rejected raw-manifest heuristics: `app-build-manifest.json` includes async App Router chunks, and `react-loadable-manifest.json` did not register these App Router dynamic chunks in this build. Those files therefore cannot reliably distinguish startup from async loading here.

Vertical leakage is guarded structurally in `qa/unit/runtime-footprint.test.ts`: the universal shell cannot statically import Alumni/productized apps or the heavy showcase config, and the productized shell cannot statically import Housing/FCA specialty panels. Build-script syntax and parsing are also unit-tested.

## Boundaries / non-goals

No School code, new route, schema migration, RLS change, i18n redesign, CSS rewrite, Server Component rewrite or product feature change was introduced. The large generic `TemplateNetworkApp` remains a productized shell; D7 removes vertical-heavy specialty code from its initial chunk rather than attempting a risky full UI decomposition in one mission.

Connected browser/runtime validation remains part of the existing two-vertical staging checkpoint. D7 certification here is source/type/lint/unit/production-build plus generated bundle-budget evidence.
