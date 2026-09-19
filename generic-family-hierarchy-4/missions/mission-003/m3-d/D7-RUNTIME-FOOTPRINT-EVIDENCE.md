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

`scripts/d7-bundle-budget.mjs` runs automatically after `next build` and:
- measures root-route JavaScript from the Next app build manifest;
- enforces a configurable root-route budget (default 2 MB raw JS);
- rejects representative Housing/FCA markers in the root-route chunks.

The raw 2 MB value is an initial safety ceiling, not a performance target. Future measurements can ratchet it down once a stable CI baseline is observed.

## Boundaries / non-goals

No School code, new route, schema migration, RLS change, i18n redesign, CSS rewrite, Server Component rewrite or product feature change was introduced. The large generic `TemplateNetworkApp` remains a productized shell; D7 removes vertical-heavy specialty code from its initial chunk rather than attempting a risky full UI decomposition in one mission.

Connected browser/runtime validation remains part of the existing two-vertical staging checkpoint. D7 certification here is source/type/lint/unit/production-build plus generated bundle-budget evidence.
