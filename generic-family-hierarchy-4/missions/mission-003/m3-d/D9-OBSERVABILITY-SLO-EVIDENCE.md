# M3-D9 — Reliability / Observability / SLO Evidence

**Baseline:** `llm-push` D8 at `fe7ec0ba5e9d7cf859b52a4de301578d4bf3ef7e`.

## Repository evidence that drove D9

The server runtime already emitted JSON query/command logs with request IDs and durations, but it had four material gaps:

- raw actor IDs and network IDs were written directly to logs;
- query/command logs had no standardized capability, vertical or user-journey dimensions;
- no slow-operation threshold, SLI/SLO definition or error-budget policy existed;
- `/api/health` always returned `healthy` and did not distinguish liveness, runtime readiness or the deliberately-unconfigured background worker.

D9 standardizes the existing runtime seam rather than introducing a monitoring vendor, observability database or fake distributed tracing platform.

## Implemented

### 1. Privacy-safe structured observations

`server/observability/telemetry.ts` is now the common observation runtime for authenticated queries and commands.

Each observation contains:
- request/trace correlation using the existing request ID;
- operation kind/name;
- capability;
- vertical;
- user journey;
- outcome;
- duration;
- slow/not-slow classification;
- normalized error code;
- idempotency state where relevant.

Raw actor/network identifiers are not logged. They are represented by deterministic SHA-256-derived 16-character tags. Operational-event details redact fields whose keys imply names, emails, message/content/payload/URL/path/token data. This keeps tenant correlation possible without turning telemetry into a second private-data store.

### 2. Bounded process-local SLI sample

The server keeps at most 2,000 recent API observations in process memory. It is explicitly described as `process-local-bounded`, not durable or globally complete.

The snapshot provides aggregate samples, failure counts, slow counts, per-journey counts and SLO evaluations. It intentionally does not expose tenant identifiers or raw request payloads.

Durable history should come from the structured JSON log stream / external metrics collector when operational scale justifies one.

### 3. Operation ownership + slow thresholds

`core/observability/contracts.ts` maps current D6/D8 operations to capability/vertical/journey metadata, including Housing operations, Family Community administration, directory/graph/member paging, imports, exports and relationship writes.

Representative slow thresholds:
- directory/graph/member reads: 800 ms;
- Housing snapshot: 1,200 ms;
- Housing/FCA mutations and FCA admin snapshot: 1,500 ms;
- synchronous import/export: 5,000 ms.

Unknown operations remain observable but are marked `unmapped` and fall back to generic read/mutation thresholds.

### 4. SLI / SLO / error-budget contract

Initial SLOs are executable contracts, not claims about current production achievement:

- Core authenticated reads: 99.5% availability, p95 <= 1,200 ms;
- Core authenticated mutations: 99.5%, p95 <= 1,800 ms;
- Housing operations: 99.5%, p95 <= 1,500 ms;
- Family Community admin: 99.5%, p95 <= 1,500 ms;
- authenticated direct-entry: 99.5%, p95 <= 2,000 ms, but explicitly marked `external-browser-required` because server API telemetry cannot truthfully measure end-user navigation by itself.

Minimum sample requirements prevent tiny process-local samples from being represented as certified SLO status.

The error-budget policy marks 75% consumption as warning territory and 100% consumption as the reliability-first release boundary once sufficient measured samples exist.

### 5. Operational health

`/api/health` now separates:
- process liveness;
- runtime readiness based on required Supabase configuration presence;
- Supabase configuration state (count only, no secret/env names);
- background worker state;
- telemetry mode/durability.

The background dispatcher honestly reports `unconfigured / durable=false` and emits a privacy-safe operational event when durable background dispatch is attempted. The application does not claim a queue exists.

This health endpoint does not expose in-process request volume or tenant-level metrics publicly.

### 6. Capability observability status

The capability manifest now distinguishes:
- `not-standardized`;
- `partial-standardized-api-runtime`;
- `standardized-api-runtime`.

Housing operations and Family Community admin are standardized because their migrated D6 boundaries run through the common query/command runtimes. Network membership/construction/affiliation are marked partial because newer API paths are standardized while legacy direct-RPC paths still exist.

## Fitness tests

`qa/unit/observability-slo-contracts.test.ts` verifies:
- raw actor/network IDs and private-looking operational fields do not appear in emitted telemetry;
- known operations receive capability/journey/slow-threshold metadata;
- bounded process telemetry produces failure/slow journey signals;
- SLO evaluation exposes insufficient-sample state and error-budget exhaustion;
- direct-entry remains external-browser measured rather than falsely certified from server logs;
- health remains sanitized;
- background durability is reported honestly;
- query/command log helpers delegate to the standardized observation runtime.

## Explicit limits / next evidence

D9 is not a production observability certification.

There is no external durable metrics/tracing backend in this mission. Process-local SLI samples reset on process/serverless lifecycle and cannot be used as the sole source for monthly SLO reporting.

Actual p50/p95/p99, slow database query visibility, connection-pool saturation and long-window error budgets require a connected production/staging telemetry backend and database/provider metrics. The structured dimensions and SLO contracts created here are designed to feed that system later without changing application semantics.

D10 can now make observability registration part of thin-vertical scaffolding. D11 School readiness can require every School-owned API capability to declare its journey/slow threshold/SLO ownership before implementation.
