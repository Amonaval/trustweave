# NEXT SESSION — M3-D Universal Network Architecture Reinforcement + Addressable Routing Foundation

## Authoritative implementation baseline

Use the **latest `llm-push` branch** as the authoritative source of implementation truth.

Important:

- the earlier M3-D strategic work was prepared from a slightly older `main` snapshot;
- `llm-push` is now known to contain 3–4 newer commits;
- **never overwrite newer `llm-push` implementation with an older M3-D/main version simply because a file differs**;
- reconcile strategic/documentation changes deliberately;
- preserve all newer `llm-push` behavior unless a deliberate architecture migration replaces it with evidence and tests.

If a fresh ZIP of `llm-push` is attached, treat it as the code baseline. If the connected repository/branch is available directly in ChatGPT Work, prefer the live `llm-push` checkout as the execution baseline.

## Founder intent

Do **not** build the School vertical yet.

First make the Network OS architecture strong enough that School — and every future vertical — can be added with minimal new code, minimal memory/runtime footprint, strong isolation, stable routing, strong privacy and clear domain ownership.

The target is a product that can plausibly grow toward millions of users and hundreds of thousands of networks without becoming an operational or maintenance nightmare. This is a design envelope, not a claim about current usage.

The Founder is moving out of developer/QA mode. Routine implementation, testing, repair, documentation and sequencing belong to the AI company runtime.

## Company/product north star

TrustWeave is building:

> **A private, federated operating system for the trusted networks of human life.**

Not one giant database containing a person's life, but:

> **One trusted identity participating in many separately governed private networks.**

Platform strategy:

> **Build the universal Network OS primitives extremely well, and make verticals thin compositions of those primitives.**

Product promise:

> **One trusted identity across the private networks that make up your life. Each network stays independent. TrustWeave connects them only where you choose — and AI helps operate the complexity.**

## Required reading

1. `AI-START-HERE.md`
2. `docs/product/TRUSTWEAVE-COMPANY-NORTH-STAR.md`
3. `PRODUCT-CONSTITUTION.md`
4. `ARCHITECTURE-CONSTITUTION.md`
5. `CURRENT-STATE.md`
6. `ROADMAP.md`
7. `missions/mission-003/m3-d/NETWORK-OS-ARCHITECTURE-MASTER-PLAN.md`
8. M3-A architecture inventory
9. current vertical/template/capability registries
10. current routing/navigation implementation
11. current Supabase/server/API boundaries

## Working mode

Operate as principal platform architect + distributed-systems engineer + SaaS architect + database/security engineer + web architecture/routing engineer + performance engineer + product-platform engineer.

Challenge the master plan whenever repository evidence suggests a better path.

Do not perform a big-bang rewrite.
Do not optimize for architectural elegance at the expense of compatibility.
Preserve all working vertical behavior and historical migrations.
Commit certified slices to the already-connected **`llm-push` branch** with clear mission-scoped commits.

---

# P0 prerequisite — Addressable application architecture

The current product requires too much in-app navigation and does not consistently expose meaningful product state through stable URLs. This is now a **fundamental platform concern**, not a UI convenience.

Every meaningful shareable/viewable state should eventually have a stable, authorization-aware URL.

Conceptual examples only — derive the final schema from repository evidence:

```text
/network/{networkId}
/network/{networkId}/directory
/network/{networkId}/events
/network/{networkId}/event/{eventId}

/family/{networkId}/tree
/family/{networkId}/member/{personId}

/residential/{networkId}/complaints
/residential/{networkId}/complaint/{complaintId}

/community/{networkId}/members
/community/{networkId}/events/{eventId}

/school/{networkId}/student/{studentId}
/school/{networkId}/class/{classId}
```

Do not copy these routes mechanically. Design one coherent route grammar first.

The routing architecture must solve:

- stable URLs for meaningful application states;
- direct navigation from browser/address bar;
- refresh correctness;
- browser back/forward correctness;
- network-context resolution from the URL rather than hidden selected-network state;
- authorization on direct navigation;
- public vs authenticated/private route taxonomy;
- unauthenticated deep link -> login -> return to intended destination;
- forbidden vs not-found vs removed-resource behavior;
- stable identifiers versus human-readable slugs;
- link stability if names/slugs change;
- capability/vertical ownership of routes;
- route parameters versus temporary UI state/query parameters;
- notification/email/WhatsApp deep links;
- shareable selective public profiles;
- federation/bridge links;
- canonical URLs;
- future mobile universal/app links;
- routing analytics/telemetry;
- deterministic Playwright route contracts;
- no privacy leakage through URLs;
- no route that bypasses server/RLS authorization.

A future TrustWeave AI agent must be able to say “open the field-trip consent”, “open this complaint”, or “view this profile” and produce a durable deep link instead of simulating many navigation clicks.

---

# Mission sequence

Execute missions **sequentially**, validating each before the next. Founder visibility may be batched, but architecture dependencies must not be.

## D0 — Architecture Baseline & Fitness Map

Measure current reality before changing architecture:

- vertical-addition touchpoints;
- duplicate/parallel registries;
- dependency graph;
- current routing/navigation model and addressability gaps;
- client bundle/startup dependencies;
- large orchestration hotspots;
- database/RPC ownership;
- RLS/function privilege posture;
- tenant-scoped index/query patterns;
- capability reuse across Family Community + Housing + proposed School;
- current architecture fitness tests.

Produce evidence, not guesses.

## D1 — Addressable Application & Deep-Link Routing Foundation — P0

Design and implement the canonical routing/addressability model before adding another vertical.

Must include:

- route grammar and versioning/stability rules;
- URL-derived network/capability context;
- direct-entry authorization behavior;
- auth return-to-origin flow;
- public/private route contracts;
- stable IDs/slugs strategy;
- deep links for notifications and shared links;
- not-found/forbidden/deleted handling;
- route ownership by capability/vertical;
- navigation adapters so existing UI uses the same route contracts;
- refresh/back/forward tests;
- representative deep-link tests for Family, Family Community and Housing;
- architecture guard preventing new meaningful screens from becoming unaddressable hidden state.

Do not attempt to route every historical micro-state in one mission. Establish the platform contract, convert representative/high-value flows, and create a migration path.

## D2 — Canonical Vertical Manifest

Collapse repeated vertical registration/configuration into one authoritative typed manifest with fail-closed runtime behavior.

## D3 — Capability Contract & Ownership Model

Make capabilities inspectable units with ownership, commands/queries/events, persistence namespace, policy/authorization, route ownership, observability and lazy-loading metadata.

## D4 — Scoped Authorization + Consent

Extend owner/admin/member with relationship/resource/purpose/time-aware policy decisions. Introduce reusable consent semantics.

## D5 — Action / Obligation / Workflow Primitives

Extract shared action, acknowledgement, approval, assignment, SLA, consent and audit mechanics from proven Residential/Community patterns without flattening domain semantics.

## D6 — Data & API Boundary Consolidation

Standardize server commands/queries, reduce direct UI→RPC coupling, shrink legacy remote hotspots, inventory current schema/RPC ownership and keep idempotency/privacy consistent.

## D7 — Runtime Footprint & Lazy Vertical Loading

Ensure adding School or another vertical does not increase all users' startup JS/memory cost. Split orchestration hotspots, lazy-load vertical runtime/UI and establish bundle budgets.

## D8 — Multi-Tenant Scale & Performance

Network-first indexes, pagination, bounded graph/query budgets, background work, quotas, noisy-neighbor protection and explicit triggers for future partitioning/deployment stamps.

## D9 — Reliability / Observability / SLOs

Tenant-aware telemetry, traces/metrics/logs, route/user-journey SLIs, SLO/error-budget policy, slow-query visibility and job/dependency health.

## D10 — Thin-Vertical Developer Experience

Create deterministic vertical scaffolding/SDK, manifest validation, adapter interfaces, route registration, seed/playground harness and vertical-specific bundle/policy tests.

## D11 — School Architecture Proof / Readiness Certification

Classify representative School workflows into:

- **A** existing generic primitive;
- **B** primitive + thin School adapter;
- **C** reusable new platform primitive;
- **D** genuinely School-specific capability.

School implementation remains blocked until this proof is credible.

---

# School is the proving target, not the implementation target yet

Use representative School workflows as architecture tests throughout D0→D10.

Future School playground:

- illustrative network modeled around **St. Arnold's, Pune / Wadgaon Sheri**;
- synthetic students, guardians, staff and operational records unless real data is explicitly authorized;
- no claim that synthetic data represents the real institution;
- focus on operational simplification rather than cloning commodity ERP functionality.

Representative workflows should include student/guardian relationships, class/teacher scoping, notices/actions, consent, absence recovery, homework/tasks, PTM continuity, events, transport/pickup, parent concerns and student journey history.

---

# Strong constraints

- Keep a modular monolith unless evidence justifies service extraction.
- No Kubernetes/service mesh/event sourcing merely for future-scale theatre.
- No premature database sharding/partitioning.
- Tenant/network context stays first-class.
- No cross-network data pooling by default.
- No new UI direct-to-database/RPC expansion.
- Historical migrations remain immutable.
- Federation/privacy invariants remain binding.
- New verticals must not increase every user's startup bundle by default.
- Meaningful product states should become addressable through stable routes.
- A direct URL must never bypass authorization.
- Independent review and runtime evidence remain real gates.
- Extract proven reusable primitives from Housing/Community before inventing School-specific duplicates.

---

# Founder role / autonomy boundary

The Founder is not developer or QA.

Do not interrupt for routine:

- implementation choices;
- lint/type/build/test failures;
- Playwright repairs;
- dependency restoration;
- route migration details;
- safe refactors;
- documentation synchronization;
- packaging;
- ordinary architecture decisions already covered by the constitution.

Escalate only genuine D3 decisions such as:

- irreversible privacy/security changes;
- destructive production actions;
- new recurring infrastructure spend;
- legal/compliance commitments;
- major product/company-constitution change;
- a trade-off that materially changes the Network OS thesis.

---

# Required execution behavior in ChatGPT Work

1. Inspect latest `llm-push` first.
2. Reconcile the attached M3-D strategic affected files **selectively**; never blindly overlay older implementation.
3. Update canonical docs when repository evidence changes the architecture plan.
4. Execute D0, then D1, then continue sequentially.
5. Validate and repair each mission before advancing.
6. Commit each certified mission/slice to `llm-push` with clear commit messages.
7. Keep mission evidence and affected-file manifests.
8. Do not wait for Founder confirmation between routine missions.
9. At meaningful checkpoints, summarize outcomes in Founder language, not developer logs.

---

# Expected final handoff from the architecture program

Provide:

- final architecture assessment;
- before/after architecture scorecard;
- routing/addressability architecture and route inventory;
- affected-files package/evidence per D mission;
- one full final repository package;
- `SCHOOL-VERTICAL-ARCHITECTURE-PROOF.md`;
- next-session School implementation charter;
- explicit list of School-only capabilities versus reusable platform capabilities;
- proof that School can be added without universally loading its code/data/runtime.

Success is not “architecture looks cleaner.”

Success is:

> **TrustWeave has a stable, addressable, privacy-safe Network OS foundation where School can be implemented as a thin vertical — and the next vertical after School becomes easier, smaller and safer again.**
