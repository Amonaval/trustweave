# M3-D6 — Data & API boundary consolidation

**Baseline:** `llm-push` M3-D5 at `5c65ebf1ca6a4e640b6e5a15221b85837053fdbe`.

## Implemented slice

D6 consolidates two proven high-value vertical boundaries instead of attempting a risky repository-wide RPC rewrite.

### Shared API runtime

- Added an authenticated GET/query runtime beside the existing command runtime.
- Query execution now shares request IDs, authenticated request context, burst limits, normalized errors and structured query logging.
- The existing command runtime remains the mutation boundary and requires idempotency for the migrated vertical commands.

### Housing operations

Housing operations snapshot, complaint routing and the existing operations mutations now flow through typed `/api/v1/housing/operations` query/command routes and `server/housing/operations-service.ts`.

The client adapter keeps only browser-side concerns such as signed complaint-media enrichment and push-delivery requests. Existing RPC/RLS enforcement remains authoritative.

### Family Community administration

The FCA admin snapshot and annual settings/membership/leadership/finance mutations moved out of the generic `capabilities/template-product/remote.ts` hotspot into the Family Association-owned adapter `verticals/family-association/runtime/admin-remote.ts`, backed by typed API routes and `server/family-association/admin-service.ts`.

### Boundary inventory

`core/api/data-boundary-manifest.ts` records the migrated owner, client adapter, server service, routes, RPCs, persistence namespaces, idempotency and privacy posture. It also explicitly lists remaining legacy hotspots so D6 does not falsely claim complete repo migration.

## Guards

`qa/unit/data-boundary-contracts.test.ts` verifies:

- routes/services/adapters exist;
- persistence/RPC references exist in historical migrations;
- migrated RPC names do not leak back into client adapters;
- server services own those RPCs;
- mutation routes require idempotency;
- query routes use the shared authenticated query runtime;
- FCA admin RPCs remain removed from the generic template-product remote.

## Boundaries / non-goals

No SQL migration, schema rewrite, RLS relaxation, new data replication, School code or big-bang legacy remote rewrite was introduced. Housing governance/finance/security/pilot and other generic productized RPC hotspots remain explicitly inventoried for later incremental consolidation.
