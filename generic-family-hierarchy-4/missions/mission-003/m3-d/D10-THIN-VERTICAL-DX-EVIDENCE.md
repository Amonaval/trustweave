# M3-D10 — Thin-Vertical Developer Experience Evidence

**Baseline:** `llm-push` D9 at `bbf14167c7948adddd452357ecb2eb598d66678a`.

## Repository evidence that drove D10

D2–D9 made the platform rules stronger, but adding a vertical still required an architect to remember several separate concerns:

- compile-time kind registration;
- canonical manifest registration;
- feature/route composition;
- reused versus owned capabilities;
- policy/API/workflow adapter obligations;
- lightweight runtime metadata;
- playground seed;
- QA catalog inclusion;
- D7 lazy-loading rules;
- D9 observability ownership.

D10 reduces that memory burden without replacing the explicit fail-closed registration model with filesystem reflection or magic auto-discovery.

## Implemented

### 1. Thin-vertical blueprint SDK

`core/verticals/thin-sdk.ts` defines one pre-registration blueprint for a future vertical.

It validates:

- route-safe kind and surface IDs;
- known reused capabilities;
- owned capability naming (`domain.<kind>`);
- unique/localized route surfaces;
- declared capability use per surface;
- home + playground start surface;
- explicitly synthetic bounded playground data (<=50 entities);
- relationship seed integrity;
- adapter obligations;
- primary observability journey and slow threshold;
- active-vs-skeleton release safety.

Structural validation and release readiness are intentionally separate. A skeleton may exist with unresolved domain adapters; an active vertical may not.

### 2. Typed adapter interfaces

`core/verticals/thin-adapters.ts` defines typed seams for:

- D4 scoped authorization policy adapters;
- D5 workflow projections;
- D6 server-owned query adapters;
- D6 server-owned command adapters.

The interfaces make the intended translation boundary explicit without creating a second policy/workflow/data engine.

### 3. Deterministic scaffold CLI

`scripts/vertical-scaffold.ts` supports:

- `--check` / `--dry-run`: validate and print the deterministic plan without writing files;
- `--write --out <dir>`: emit vertical-local scaffold files plus `INTEGRATION-PLAN.json`.

Generated local files are:

- `definition.ts`;
- feature catalog;
- runtime composition;
- adapter contract;
- synthetic playground seed;
- local QA contract.

The CLI intentionally does **not** silently edit the product's central registries. Instead it emits the exact small explicit integration plan.

### 4. Explicit central integration plan

For a vertical with one owned domain capability, the plan requires only:

1. `core/verticals/kinds.ts`;
2. `core/verticals/capability-manifest.ts`;
3. `templates/productized/runtime-meta.ts`;
4. `app-shell/vertical-manifest.ts`;
5. `qa/runtime/catalog.mjs` when released.

A vertical using only shared capabilities omits the capability-manifest edit.

This preserves strong compile-time/fail-closed registration while making the work deterministic.

### 5. Route registration contract

The blueprint owns a list of route surfaces. They use the existing D1 grammar:

`/network/{networkId}/{surface}`

The scaffold cannot introduce a competing vertical route grammar. Surface IDs are validated with the same route-safe shape and are emitted into the app composition/playground contract.

### 6. Seed / playground harness

`thinVerticalPlaygroundSeed()` produces a deterministic synthetic network seed from the same blueprint. The SDK validates entity count and relationship endpoints before generation.

No database writes or production data are involved.

### 7. Synthetic non-product proof

`qa/fixtures/d10-thin-vertical.json` defines **civic-circle**, a deliberately synthetic non-product fixture.

It proves:

- an unregistered future kind can be designed/scaffolded without entering runtime;
- owned policy/API obligations remain visible release blockers;
- shared capabilities can be declared explicitly;
- route and playground output is deterministic;
- School remains unregistered and no School code is generated.

### 8. Vertical-specific safety tests

`qa/unit/thin-vertical-dx.test.ts` verifies:

- deterministic structural validation;
- exact central touchpoint plan;
- fail-closed activation when policy/API obligations remain unresolved;
- invalid capability and route references are rejected;
- synthetic seed determinism;
- CLI dry-run writes nothing;
- CLI write emits only expected vertical-local files + integration plan;
- generated source does not contain direct RPC calls;
- generated source does not contain School implementation.

D7 bundle protections and D4/D6 policy/API boundaries remain inherited release gates rather than duplicated in the scaffold.

## Commands

Validate the reference fixture:

`npm run vertical:scaffold:check`

Validate a future blueprint:

`npm run vertical:scaffold -- --spec path/to/vertical.json --check`

Generate into a working directory:

`npm run vertical:scaffold -- --spec path/to/vertical.json --write --out /tmp/trustweave-new-vertical`

## Explicit non-goals

D10 does not:

- add School;
- add a new production vertical;
- auto-register folders at runtime;
- mutate central registries implicitly;
- generate permissive authorization code;
- generate direct UI-to-database calls;
- create database migrations;
- replace connected/browser QA.

D11 can now use this contract to test whether School truly fits as a thin vertical and to identify the small set of reusable platform primitives or genuinely School-specific capabilities still required.
