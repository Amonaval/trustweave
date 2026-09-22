# TrustWeave M3-D — Universal Network Architecture Master Plan

> **Execution correction (2026-09-19):** This strategic plan was drafted against an older snapshot. `EXECUTION-CHARTER.md` and the live `llm-push` implementation take precedence. The addressable application foundation is **D1**. The D1–D10 headings below are original plan labels and execute as **D2–D11**. D0 source measurements and evidence are in `D0-ARCHITECTURE-BASELINE.md`; School remains blocked until D11.

**Status:** PROPOSED MASTER PLAN FOR NEXT SESSION  
**Updated:** 2026-09-19  
**Mode:** Architecture reinforcement before the School vertical  
**Primary objective:** Make every future vertical cheaper, safer, smaller and faster to build while improving scale, performance, privacy and operational simplicity.

## 1. Why this program exists

TrustWeave has reached the point where adding another substantial vertical can either validate the Network OS thesis or expose accumulated architectural debt.

The next vertical, School, must not become another large independent application embedded inside the repository.

Before building School, this program strengthens the platform so that future verticals are **thin compositions over reusable primitives**.

The target design scenario is deliberately ambitious:

- millions of users over time;
- hundreds of thousands of networks;
- many users participating in several networks;
- some networks small and intimate, others institution-scale;
- privacy-sensitive cross-network federation;
- AI-assisted operations across authorized contexts;
- global applicability without a giant client bundle or an unmaintainable database/RPC surface.

This is a **design envelope**, not a claim about current production traffic.

## 2. Current architecture — what is already strong

Repository inspection shows meaningful platform foundations already exist.

### 2.1 Network OS primitives already present

- network identity and active network context;
- neutral account↔network membership;
- network-local identity bindings (`VerticalIdentityRef`);
- generic entities, dimensions, relationships and projections;
- typed vertical definitions and app compositions;
- capability folders and domain adapters;
- import/construction/participation/claiming primitives;
- generic events/groups/activity concepts;
- trusted identity across multiple network memberships;
- peer network trust bridges;
- umbrella/federation affiliation;
- purpose-scoped federated profiles;
- governed introductions and path provenance;
- launch control, Playground, Guide and feature catalogs;
- command runtime with request context, rate limiting and idempotency;
- substantial RLS/security testing and migration discipline;
- autonomous mission/QA/review infrastructure.

This is enough evidence that TrustWeave is not starting from a vertical monolith.

### 2.2 Privacy architecture is directionally correct

The current contracts already encode important principles:

- one authenticated person may belong to many networks;
- each network keeps its own profile/entity context;
- membership in one network does not expose another network;
- federation does not inherit private graphs;
- bridges are explicit rather than inferred;
- cross-network portability is opt-in.

Those are core product assets and must not be weakened for convenience.

### 2.3 Existing engineering governance is unusually strong for the current stage

The repository already has architecture constitutions, deterministic gates, RLS/security audits, Playwright flows, migration checks, idempotent command handling and an AI-company execution harness.

The next task is **simplification and consolidation**, not adding more governance machinery for its own sake.

## 2.4 New P0 finding — application state must become addressable

The current product still relies too heavily on in-app navigation and hidden selected-network/UI state. A serious multi-network platform needs stable, authorization-aware URLs for meaningful states.

This is now the first implementation priority after D0 measurement. The architecture program inserts **D1 — Addressable Application & Deep-Link Routing Foundation** before vertical-manifest consolidation; subsequent missions shift by one and School readiness becomes D11.

The route model must support direct entry, refresh/back/forward, URL-derived network context, login return-to-origin, public/private routes, stable ID/slug semantics, capability ownership, notification/share links, selective public profiles, federation links and future mobile universal links.

Routing is a platform primitive because it also enables deterministic QA, durable links between networks and AI agents that can point users directly to a resource/action instead of recreating navigation steps.

A route is never an authorization boundary by itself. Every direct-entry request must still pass server/RLS/policy authorization. URLs must not leak private data.

## 3. Current architecture — where scale and new verticals will hurt

The architecture has good seams, but several pressure points are visible.

### 3.1 Vertical registration is still too compile-time and repetitive

Adding a vertical currently touches multiple parallel concepts:

- `NetworkVerticalKind` closed union;
- vertical definition registry;
- app composition registry;
- capability runtime registry;
- template definition/catalog;
- productized vertical config;
- feature catalog and backend feature registration;
- guide/playground/launch-control surfaces.

This is safer than ad-hoc conditionals, but still too much repeated registration work.

**Direction:** one canonical vertical manifest should generate or feed all secondary registries. No reflection magic; keep strong typing and fail-closed behavior.

### 3.2 Two overlapping vertical/template models remain

`VerticalDefinition` and `VerticalTemplateDefinition` describe overlapping concerns using different capability vocabularies.

This is useful historical scaffolding but will become confusing with School and future verticals.

**Direction:** separate clearly:

- **Vertical Manifest** — runtime/product identity, availability, owned domain capabilities, navigation entry points;
- **Domain Model Descriptor** — entity kinds, dimensions, relationships, projections;
- **Capability Contracts** — reusable behavior with explicit requirements.

A template should become a composition recipe, not a second competing vertical system.

### 3.3 Shared capability metadata is not rich enough

Capabilities are largely represented as string identifiers. A future system needs machine-readable answers to:

- who owns the capability;
- what data it owns;
- what permissions it requires;
- what commands/queries/events it exposes;
- whether it has UI surfaces;
- which bundle/lazy boundary it belongs to;
- what migration namespace it owns;
- what observability/SLOs apply;
- what vertical adapters are allowed.

**Direction:** introduce a small typed capability manifest, not a framework.

### 3.4 Authorization is too coarse for School and future institutions

Core network roles are currently owner/admin/member. This is insufficient for:

- parent sees only children they guard;
- teacher operates only assigned classes/subjects;
- transport staff sees only relevant route/pickup context;
- committee/event coordinators get narrow delegated authority;
- society staff gets operational access without finance/admin access.

**Direction:** keep network-level RBAC, then add **scoped policy decisions** combining role, relationship, resource, capability and purpose. Do not scatter new boolean checks in UI components.

### 3.5 Consent is not yet a first-class cross-vertical primitive

School makes this unavoidable, but the need already exists in Family, federation, professional introductions and public profiles.

Potential reusable contract:

- subject;
- grantor;
- purpose;
- scope;
- grantee/network;
- valid-from / valid-until;
- revocation state;
- evidence/audit metadata.

The platform should distinguish **authorization** from **consent**.

### 3.6 Cross-network actions need one generic obligation model

Across verticals users repeatedly need to answer: **what requires my attention?**

Examples:

- school consent;
- society payment;
- community renewal;
- family event RSVP;
- trusted introduction review;
- governance vote.

**Direction:** a reusable `ActionItem` / `Obligation` capability should provide source, actor, due date, action type, status and deep-link context without owning domain business rules.

This primitive is key to the future cross-network “My Day / Needs Your Attention” experience.

### 3.7 Client/runtime composition can become too heavy

Current `NetworkApp.tsx` is a large orchestration hotspot and statically imports multiple vertical runtimes. The repository also contains large legacy client/runtime modules and large i18n bundles.

Next.js can code-split effectively, but only when dependency boundaries allow it. A single route that statically imports every vertical risks paying for verticals the current user never opens.

**Direction:** vertical runtime loading must become lazy/bundle-aware, with small shared shell contracts and vertical-specific code loaded only on demand.

### 3.8 Data access is still heavily RPC-oriented and fragmented

Repository evidence currently includes hundreds of Supabase RPC call sites and a large historical `lib/remote.ts` surface. Server command infrastructure is stronger now, but old and new styles coexist.

This is not automatically wrong; PostgreSQL functions can be excellent for secure transactional work. The risk is **unbounded RPC growth and duplicated authorization semantics** as every new vertical adds functions.

**Direction:**

- use server command/query boundaries for high-value mutations and complex reads;
- keep direct RPC usage behind capability/domain ports;
- define RPC ownership and naming conventions;
- consolidate repeated query patterns;
- require pagination/bounded results;
- progressively shrink legacy remote god-modules;
- do not rewrite working persistence merely for aesthetic purity.

### 3.9 Database complexity is becoming a maintenance concern

The current migration history contains roughly:

- 119 SQL migration files (numbered through 121);
- ~15.7k lines of migration SQL;
- ~174 table-creation statements across history;
- ~624 function definitions/redefinitions;
- ~589 `SECURITY DEFINER` occurrences;
- ~109 policy definitions;
- ~148 index definitions.

Most security-definer functions appear to include explicit `search_path` hardening and grant/revoke treatment, which is positive. The problem is future maintainability, dependency ordering and regression risk as the surface continues to grow.

**Direction:** add a current schema inventory and ownership map; do not infer current object count by summing historical DDL. Introduce contract tests around **current objects**, function privileges, indexes, network filters and query plans.

### 3.10 Validation infrastructure is powerful but fragmented

There are more than 200 npm scripts and many one-mission source gates. This provides strong evidence but increases discoverability and maintenance cost.

**Direction:** preserve historical gates, but route future work through a smaller capability/mission gate registry. New architecture work should reduce the number of bespoke scripts needed per vertical.

## 4. Architecture doctrine for the next scale

## 4.1 Modular monolith first

Do **not** split TrustWeave into microservices because millions of hypothetical future users were mentioned.

The near-term architecture should remain a **modular monolith with strong bounded contexts**, because it minimizes deployment/operational complexity while allowing clear capability ownership.

Extract a service only when one or more are proven:

- materially different scaling profile;
- independent availability requirement;
- isolation/compliance requirement;
- very high asynchronous workload;
- different deployment cadence;
- operational ownership warrants separation.

Service extraction should follow existing capability boundaries, not create them after the fact.

## 4.2 Domain-driven boundaries, not horizontal utility layers

Boundaries should follow business capability and semantic ownership.

A capability must be cohesive and change for one primary business reason. Vertical-specific rules stay in vertical/domain adapters. Shared code must not become a dumping ground.

## 4.3 Tenant/network context is first-class everywhere

Every request, command, query, cache key, telemetry event and background job involving tenant data must carry network/tenant context explicitly.

No API should rely on implicit “currently selected network” state when the target network can be passed and authorized explicitly.

## 4.4 Pool now, design for stamps later

The current Supabase/Postgres shared environment is appropriate for the current stage.

Design so future **deployment stamps/cells** can host subsets of networks if scale, geography, compliance or noisy-neighbor behavior eventually requires it.

Do not implement stamps now. Make them possible by keeping:

- network ownership explicit;
- global identity references separable from network-local data;
- no cross-tenant foreign-key assumptions that require one database forever;
- federated/public projections able to cross deployment boundaries through APIs/events later.

## 4.5 Commands, queries and events have different jobs

Use:

- **commands** for state-changing intent with authorization, validation and idempotency;
- **queries** for bounded read models optimized for user journeys;
- **domain events** only when another capability genuinely needs durable asynchronous reaction.

Do not introduce event sourcing.

If durable cross-capability event delivery becomes necessary, use a **transactional outbox** so database change and event publication cannot diverge.

## 4.6 Read models are allowed

The canonical domain model does not need to answer every dashboard efficiently.

For high-frequency views such as “My Day”, school parent dashboard, society chairman dashboard or federation discovery, maintain explicit query/read models when evidence shows repeated expensive joins or fan-out.

Read models must be derivable/rebuildable and must preserve network/privacy rules.

## 4.7 No unbounded operations

At the design envelope of 100k+ networks, the following become permanent rules:

- no unbounded list endpoints;
- cursor/keyset pagination for growing collections;
- no global scans in request paths;
- every hot tenant query starts from network/subject scope;
- batch imports/exports use chunking and resumable jobs;
- bulk notifications are asynchronous;
- large graph traversals have explicit depth/result/time budgets;
- expensive analytics use precomputation or background work;
- every cache key includes appropriate tenant/purpose identity;
- large tenants cannot starve small tenants.

## 4.8 Architecture fitness functions

Architectural rules should be executable where possible:

- core cannot import verticals;
- vertical A cannot import vertical B;
- every released vertical has one manifest;
- no new direct Supabase calls from UI surfaces;
- every capability-owned table/function is registered;
- network-scoped tables have tenant-aware indexes/policies;
- no unrestricted `SECURITY DEFINER` functions;
- vertical bundle size stays within budget;
- public/federated contracts cannot expose private graph fields;
- school-specific code cannot leak into core unless a second domain proves the primitive.

## 5. Target architecture

```text
Human Account / Trusted Identity
            │
            ▼
    Network Membership Layer
            │
            ├── network-local identity binding
            ├── role + scoped policy context
            └── consent grants
            │
            ▼
      Network OS Kernel
            │
    ┌───────┼──────────────────────────────┐
    ▼       ▼                              ▼
Capabilities / Use-case engines       Federation / Bridges
    │                                       │
    ├── directory                           ├── network passports
    ├── relationships                       ├── affiliations
    ├── groups/events                       ├── discovery projections
    ├── actions/obligations                 ├── introductions
    ├── consent                             └── purpose scopes
    ├── workflow
    ├── notifications
    ├── media/documents
    ├── governance
    └── import/export
    │
    ▼
Vertical Manifest + Thin Domain Adapters
    │
    ├── Family
    ├── Family Community / Association
    ├── Housing Society
    ├── School (next proving vertical)
    ├── Professional
    ├── Business
    └── future verticals
    │
    ▼
Lazy Vertical UI + Domain-specific UX
```

The dependency direction remains downward. A vertical composes primitives; the kernel never knows School, Housing or Family vocabulary.

## 6. M3-D mission sequence

Do not execute this as one giant rewrite. Every mission must preserve product behavior and produce measurable simplification.

### M3-D0 — Architecture Baseline & Fitness Map

**Goal:** establish measurable current architecture before restructuring.

Deliver:

- dependency graph and import-boundary report;
- current vertical-addition touchpoint count;
- current schema/RPC ownership inventory;
- bundle/client dependency baseline;
- hot-file/complexity baseline;
- capability reuse matrix for Family Community + Housing + proposed School workflows;
- architecture fitness-function backlog;
- no product behavior change.

Exit: we can quantify whether later missions reduce complexity.

### M3-D1 — Canonical Vertical Manifest

**Goal:** one authoritative description for each vertical.

Converge duplicated registration/configuration where safe:

- vertical identity/status;
- domain model descriptor;
- capability composition;
- feature catalog reference;
- app composition reference;
- guide/playground/launch metadata;
- lazy-loader entry point.

Secondary registries should be generated/derived or mechanically validated against the manifest.

Success measure: adding a skeleton vertical requires dramatically fewer cross-repo edits.

### M3-D2 — Capability Contract & Ownership Model

**Goal:** make reusable primitives first-class, inspectable units.

Introduce minimal typed metadata for:

- capability id/version;
- owner;
- required kernel contracts;
- commands/queries/events;
- data/RPC namespace;
- policy requirements;
- UI entry points;
- observability requirements;
- compatible adapters.

Do not package each capability into a separate npm module yet.

### M3-D3 — Scoped Authorization + Consent Foundation

**Goal:** support institution-grade permissions without owner/admin/member explosion.

Add a reusable policy decision model that can express:

- role-based permissions;
- relationship-derived access;
- resource scope;
- capability/action;
- purpose;
- time window;
- optional explicit consent.

Prove with existing Housing/Community cases before School.

School target examples for later proof:

- guardian sees only authorized students;
- teacher accesses assigned class/subject operations;
- transport staff sees only route/pickup data;
- admin delegation does not grant unrelated finance/private access.

### M3-D4 — Action / Obligation / Consent / Workflow Primitives

**Goal:** extract cross-vertical operational primitives from existing Housing/Community patterns.

Candidate primitives:

- `ActionItem` / obligation;
- acknowledgement;
- approval/request lifecycle;
- consent grant;
- assignee / SLA / due date;
- status transitions;
- audit trail;
- notification hooks.

Do not generalize Housing finance/governance semantics that are genuinely domain-specific.

### M3-D5 — Data & API Boundary Consolidation

**Goal:** make persistence growth sustainable.

Work:

- capability/domain-owned ports;
- route new mutations through standard command runtime;
- reduce direct UI→RPC coupling;
- shrink `lib/remote.ts` incrementally;
- standard query contracts and pagination;
- RPC ownership/privilege inventory;
- current schema object manifest;
- idempotency rules for all sensitive mutations;
- introduce outbox only if a real cross-capability async workflow requires it.

### M3-D6 — Runtime Footprint & Lazy Vertical Loading

**Goal:** adding verticals should not increase every user's startup cost.

Work:

- split large orchestration hotspots;
- lazy-load vertical apps/capability-heavy panels;
- namespace/lazy-load i18n where useful;
- Server Component vs Client Component audit;
- route-level data-fetching/caching review;
- bundle analyzer baseline and budgets;
- CSS ownership/chunking cleanup;
- remove vertical imports from universal startup path where possible.

Success measure: a Family user should not download School/Housing code merely because those verticals exist.

### M3-D7 — Multi-Tenant Scale & Data Performance

**Goal:** prepare the pooled architecture for large tenant count without premature sharding.

Work:

- network-first composite index audit;
- RLS/query-plan benchmarks on representative large datasets;
- keyset pagination;
- graph traversal budgets;
- hot-tenant/noisy-neighbor protections;
- per-network quotas and rate policies;
- job/chunking model for imports, exports, digests and fan-out;
- cache policy and invalidation ownership;
- connection/pooling strategy;
- scale triggers for partitioning and deployment stamps.

Do not implement partitioning or a new database topology until measurements justify it.

### M3-D8 — Reliability, Observability & Operational SLOs

**Goal:** millions of hypothetical users must not depend on founder intuition.

Add:

- tenant-aware structured telemetry;
- traces/metrics/log correlation where valuable;
- user-journey SLIs;
- SLOs for core actions;
- error-budget policy for release decisions;
- slow-query and failed-policy visibility;
- background-job health;
- dependency health;
- capability/vertical dimensions in telemetry without leaking private data.

### M3-D9 — Vertical Developer Experience / Thin-Vertical SDK

**Goal:** make a new vertical boring to add.

Provide:

- `vertical create` scaffolding/generator or equivalent deterministic template;
- manifest validation;
- standard adapter interfaces;
- test harness;
- seed/playground fixtures;
- capability compatibility report;
- vertical-specific bundle and policy checks;
- required documentation generated from the manifest where appropriate.

A new skeleton should fail closed until persistence/authorization are implemented.

### M3-D10 — School Architecture Proof & Readiness Certification

**Goal:** prove the new architecture before implementing the School product.

Take representative School workflows and classify each A/B/C/D:

A — existing generic primitive;  
B — primitive + thin School adapter;  
C — reusable platform primitive created in M3-D;  
D — genuinely School-specific.

Representative workflows:

1. create school/network;
2. academic year;
3. grade/division;
4. student enrollment;
5. guardian linkage;
6. teacher/class/subject assignment;
7. school notice with action semantics;
8. homework/task;
9. attendance/absence;
10. trip consent;
11. PTM follow-up;
12. transport route/pickup authorization;
13. parent concern routing;
14. event/competition workflow;
15. end-of-year progression.

Exit criteria:

- architecture can express the School vertical without core imports of School code;
- School-specific code has clear ownership;
- generic platform additions benefit at least one existing vertical or a strongly justified cross-vertical contract;
- predicted client/runtime footprint is bounded;
- authorization/privacy model passes threat review;
- next session receives a concrete School build charter.

## 7. School build direction after M3-D

The School implementation is a **separate session/program** after D10.

Illustrative playground target:

> **St. Arnold's, Pune — Wadgaon Sheri School Playground**

Use only synthetic seed data unless real data is explicitly authorized.

The School vertical should focus first on operational simplification rather than becoming a full ERP replacement.

Initial high-value capability themes:

- School Today / “what needs attention?”;
- structured parent communication;
- teacher workload reduction;
- action/consent tracking;
- attendance and absence recovery;
- PTM continuity;
- events and permissions;
- authorized pickup/transport workflows;
- parent concern routing;
- child journey/history;
- AI assistant grounded in verified school context.

Where specialist ERP/LMS/accounting already exists, TrustWeave should integrate rather than rebuild commodity functionality unless a pilot proves replacement value.

## 8. Scale architecture trigger table

| Concern | Do now | Trigger for next step |
|---|---|---|
| Vertical code | modular monolith + lazy loading | independent scale/deploy need |
| Database | pooled Postgres/Supabase | measured saturation/noisy-neighbor/compliance |
| Partitioning | network-first indexes + bounded queries | table/query evidence shows need |
| Deployment stamps/cells | design-compatible only | region/compliance/blast-radius/scale requirement |
| Events | synchronous transactions by default | real durable cross-capability async need |
| Outbox | design/contract only | state change + event atomicity required |
| Read models | use for proven hot journeys | repeated expensive fan-out/query joins |
| Cache | explicit bounded cache ownership | measured latency/load benefit |
| Microservices | no | bounded context needs independent scale/availability/deploy |
| AI agents | permissioned tools over contracts | proven user/operator value |

## 9. Architecture quality scorecard

Track only metrics that influence decisions:

- number of files/registries required to add a vertical;
- % of School proof workflows classified A/B/C/D;
- vertical-specific LOC and bundle size;
- universal startup JS attributable to unused verticals;
- forbidden dependency violations;
- direct UI→database/RPC calls;
- capability ownership coverage for tables/RPCs/routes;
- p50/p95/p99 latency of core journeys;
- slow query count and RLS overhead on representative tenant sizes;
- max bounded result sizes/pagination coverage;
- cross-tenant authorization failures caught by automated tests;
- high-risk `SECURITY DEFINER` functions lacking explicit privilege/search-path checks;
- background job retry/idempotency health;
- SLO/error-budget status;
- human interventions required per architecture mission.

## 10. Non-goals

Do not use this program to introduce technology for prestige.

Explicitly avoid unless evidence changes:

- Kubernetes;
- mandatory microservices;
- event sourcing;
- service mesh;
- graph database replacement;
- separate database per network;
- a new state-management framework merely for consistency;
- a generic plugin marketplace;
- rewriting all existing migrations/tables/RPCs;
- converting every domain workflow into one generic workflow engine;
- forcing all verticals into identical UX.

## 11. External architecture principles used

This plan intentionally borrows proven ideas rather than inventing architecture terminology:

- **Tenant isolation and tenant context as first-class architecture** — AWS SaaS Lens.
- **Deployment stamps/cells for future horizontal tenant scaling and blast-radius control** — Azure Architecture Center deployment-stamp pattern.
- **Domain/bounded-context decomposition around business capabilities** — Domain-Driven Design guidance from Microsoft/Azure Architecture Center.
- **Architecture fitness functions / evolutionary architecture** — continuous executable checks rather than architecture-by-review only.
- **Transactional outbox when database state and durable event publication must be atomic** — AWS Prescriptive Guidance.
- **SLIs/SLOs and error budgets for reliability decisions** — Google SRE.
- **Vendor-neutral traces, metrics and logs** — OpenTelemetry.
- **route/server/client boundaries, code splitting, lazy loading and bundle analysis** — Next.js production guidance.
- **database row-security as a separate isolation concern from authentication** — PostgreSQL RLS and SaaS tenant-isolation guidance.

The principle is not to copy a hyperscaler architecture. It is to keep TrustWeave simple now while avoiding choices that make safe growth impossible later.

## 12. Definition of success

M3-D succeeds when:

> **A substantial new vertical can be added mostly by declaring domain semantics, composing reusable capabilities and implementing only the irreducible domain behavior — without expanding universal bundle cost, weakening privacy, multiplying ad-hoc database APIs or forcing the Founder to understand every internal dependency.**

School is the first major proof. Future verticals should become progressively easier, not progressively more expensive.
