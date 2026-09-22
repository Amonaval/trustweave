# M3-D8 — Multi-Tenant Scale & Performance Evidence

**Baseline:** `llm-push` D7 at `80b1337da4097ab93005393a5f9b5956d627c63f`.

## Repository evidence that drove D8

D8 did not introduce partitioning, sharding, Redis, queues or deployment cells speculatively. The current pooled Postgres/Supabase architecture already has many network-first indexes, but several scale pressure points were concrete:

- shared query/command burst limiting was keyed only by actor + operation, so one tenant had no process-local noisy-neighbor ceiling across multiple actors;
- generic directory, relationship and productized membership reads had full-list RPC contracts;
- graph helpers had no maximum traversal depth/node/edge envelope;
- logical export recursively enumerated network storage with page size 100 but no maximum object/directory envelope;
- institutional bootstrap already had a 500-row cap, but it was a route-local magic number rather than a shared scale contract;
- the background dispatcher intentionally has no durable runtime, so large synchronous work must fail closed rather than pretending serverless post-response work is reliable.

## Implemented

### 1. Executable scale budgets and escalation triggers

`core/scale/contracts.ts` defines shared budgets for page size, graph traversal, imports, synchronous export, per-actor/per-network burst limits and background chunking.

`evaluateScaleEscalation()` makes future topology decisions evidence-driven:
- partitioning review requires both a tenant-scoped relation at or above 25M rows and representative indexed tenant query p95 at or above 250 ms after tuning;
- deployment-stamp review is triggered by explicit regional isolation, or by sustained pool pressure combined with a noisy tenant workload share;
- more than one application instance marks the in-process limiter as insufficient for globally enforceable quotas and requires a shared/distributed limiter before relying on it as a hard platform quota.

These are architecture-review triggers, not automatic infrastructure actions.

### 2. Tenant-aware noisy-neighbor burst guard

The existing in-process burst guard remains deliberately simple, but query and command runtimes now enforce two scopes:
- actor + operation;
- network + operation.

Default ceilings are 60 actor / 1,200 network queries per minute and 30 actor / 600 network commands per minute, with route-specific overrides supported.

This is defense-in-depth only. It is not represented as globally durable across horizontally scaled/serverless instances.

### 3. Network-first indexes and additive keyset contracts

Additive migration `123_m3d8_multi_tenant_scale_performance.sql` adds targeted network-first indexes for:
- entity directory ordering;
- activity ordering;
- relationship paging;
- membership administration;
- activity comments;
- Family Community finance and role history.

It also adds bounded keyset RPCs, each clamped to at most 200 rows:
- `get_network_affiliated_entities_page`;
- `get_productized_network_relationships_page`;
- `get_productized_network_memberships_page`.

Existing eager RPCs remain unchanged for compatibility. This avoids silently truncating current UI while giving large surfaces a migration path.

### 4. Server-owned page APIs

The new page RPCs are not called directly from UI adapters. `server/network/scale-service.ts` owns them behind authenticated `/api/v1/network/*` query routes using the D6 query runtime and tenant-aware burst limits.

Client adapters expose optional page methods without changing existing eager methods.

### 5. Bounded graph work

`core/graph/scale.ts` introduces a bounded graph walk with a default maximum:
- depth 4;
- 5,000 visited nodes;
- 20,000 examined edges.

The limit is deterministic by operation count rather than fragile wall-clock CI timing.

### 6. Bounded import/export/background work

Institutional bootstrap now derives its existing 500-row synchronous cap from the shared scale budget and has an explicit tenant-level burst ceiling.

Network export now fails closed with `EXPORT_REQUIRES_BACKGROUND` if synchronous storage enumeration exceeds 10,000 objects or 2,000 directories. The current background dispatcher remains unconfigured; D8 does not falsely claim large exports are durably queued.

`server/jobs/planner.ts` classifies work above 500 items as `external-required` and provides 250-item chunk planning for the future durable worker runtime.

## Fitness tests

`qa/unit/scale-performance-contracts.test.ts` verifies:
- page limits clamp to 200;
- a 50,000-edge synthetic graph is stopped at the graph budget;
- tenant burst limiting applies across different actors in the same network;
- scale escalation triggers are deterministic;
- migration 123 contains the required network-first indexes and bounded keyset RPCs;
- no partitioning is introduced;
- paged reads stay behind server API boundaries;
- import/export budgets are enforced through shared contracts.

## Explicit non-goals / remaining evidence

D8 does **not** claim production-scale certification. Query-plan/RLS benchmarks require a representative connected database with generated high-volume tenant data and must be gathered before lowering/raising topology triggers.

No partitioning, sharding, database-per-tenant model, Kubernetes, Redis limiter, durable queue or deployment stamp was introduced. Those remain conditional on measured evidence.

Existing full-list UI paths are preserved for behavior compatibility; large-screen conversion can migrate incrementally to the new keyset APIs. D9 will add the tenant-aware telemetry needed to observe latency, slow queries, budget pressure and noisy-neighbor signals in operation.
