# V1 — Network Activation Autopilot

**Date:** 2026-09-22  
**Execution branch:** `network-activation-autopilot`  
**Product status:** **SOURCE-COMPLETE CANDIDATE / REAL-WORLD VALUE VALIDATION PENDING**  
**Primary proving vertical:** Family Community / Cultural Association  
**Runtime/database effects in this implementation session:** none

## Product hypothesis

A real institution should not need to manually rebuild itself inside TrustWeave.

V1 tests whether TrustWeave can take the structured records an Association already has, reconstruct a governed network with very little administrator work, preserve uncertainty and provenance, and immediately produce useful institutional observations.

The product promise is:

> Bring the organization you already have. TrustWeave reconstructs what it can prove, asks only about what it cannot safely decide, and activates the approved result through existing governed domain contracts.

V1 is intentionally a product/value experiment, not another architecture program.

## Current proving slice

The current V1 slice accepts the existing Family Association activation workbook rather than attempting every possible source format.

The workbook can represent:

- families / households;
- people;
- household membership;
- annual Association membership;
- family representative;
- payment state / amount / reference;
- current and historical leadership roles.

The proving slice deliberately does **not** yet include PDF interpretation, WhatsApp ingestion, Google Drive connectors, generic OCR, a general chatbot or paid model APIs.

Those become candidates only if the structured activation experience proves valuable.

## End-to-end flow

```text
Existing Association workbook
        ↓
Existing deterministic workbook parser
        ↓
Candidate Network Compiler
        ↓
Candidate facts + row-level provenance
        ↓
Ambiguity Inbox
        ↓
Human resolves only unsafe decisions
        ↓
Resolved Activation Plan
        ↓
Activation evidence persisted first
        ↓
Existing TrustWeave governed APIs/contracts
        ↓
People + families + relationships
+ membership + representative + leadership history
        ↓
First Institutional Intelligence report
```

## V1-A — Compile — implemented in source

`core/activation-autopilot/compiler.ts` converts a validated workbook into a candidate network.

It records:

- exact candidate facts;
- source file;
- source sheet;
- source row;
- source column where applicable;
- certainty/confidence vocabulary;
- attention items;
- activation summary.

Current deterministic ambiguity detection includes:

- possible duplicate identity from name/email/phone overlap;
- a person linked to multiple households;
- conflicting membership status for the same family/year;
- conflicting representative for the same family/year;
- conflicting payment records;
- conflicting singular leadership roles such as President/Treasurer for the same term;
- ordinary parser/schema blockers.

No ambiguity is silently upgraded into canonical truth.

## V1-B — Resolve — implemented in source

`core/activation-autopilot/resolution.ts` turns attention items into an explicit activation plan.

Supported decisions:

### Separate identities

The administrator can confirm that overlapping identity records are genuinely different people.

### Merge identities

The administrator can choose one source person as canonical.

The merge:

- keeps the selected stable ID;
- excludes losing person rows from canonical writes;
- carries over values only where the canonical row is blank;
- never overwrites a non-empty canonical field automatically;
- rewrites typed workbook references to the selected stable ID;
- preserves losing source rows as evidence.

### Choose canonical conflicting source row

For household, membership, representative, payment and leadership conflicts, the administrator selects the row that should become canonical.

Linked conflict decisions must agree; contradictory selections remain blocked.

## V1-C — Activate & Prove — implemented in source

Activation reuses the existing TrustWeave contracts rather than adding a parallel persistence model.

The resolved plan goes through:

- existing network entity upsert;
- existing governed relationship creation;
- Family Community annual membership RPCs;
- representative state;
- Family Community leadership-history RPCs.

The current representative from the latest supplied membership cycle is also synchronized into the governed `family → represented_by → person` graph relationship required by existing household-management semantics.

Repeated activation is protected by:

- stable import IDs for entities;
- existing relationship keys;
- annual membership upsert behavior;
- leadership-history rerun detection.

When activating into a non-empty network, V1 fails closed if a new workbook Family/Person appears to collide with an existing manually created entity that lacks the stable import ID. It does not guess that the records are the same.

## Provenance and evidence

V1 reuses the existing G9.1-A governed evidence layer instead of inventing another storage system.

Additive migration:

`supabase/migrations/124_v1_network_activation_evidence.sql`

adds narrow Family Community admin RPCs for:

- recording activation source/evidence;
- reading activation evidence.

Evidence is restricted to network administrators.

Before canonical activation begins, TrustWeave records:

- the activation source;
- every source row retained for provenance;
- rows excluded from canonical writes;
- original raw source values;
- resolved normalized values;
- schema version;
- row status.

This separates:

1. **what the source actually said**, from
2. **what the administrator approved as canonical network state**.

Migration 124 has **not** been applied to any Supabase project by this mission session.

## First Institutional Intelligence

`core/activation-autopilot/intelligence.ts` produces an immediate deterministic report after activation.

Current source-backed observations include:

- people without household links;
- families without linked people;
- families missing from the latest membership cycle;
- active families missing representatives;
- memberships with unpaid/partial source state;
- reconstructed leadership history;
- number and depth of membership cycles.

Current evidence-backed answers include:

- what TrustWeave reconstructed;
- latest supplied membership cycle;
- President history when present.

This is intentionally deterministic. It does not use a generic LLM/chatbot and therefore does not create a model/API cost dependency.

## User experience

Family Community's existing **Data & import** admin surface now routes to `NetworkActivationAutopilot`.

The UX is intentionally:

1. analyze existing records;
2. preview reconstructed network;
3. review only ambiguous items;
4. activate governed network;
5. show immediate institutional intelligence.

The old guided importer remains available to other productized verticals.

## Trust rules

V1 is governed by these rules:

1. AI/inference never writes directly to canonical network state.
2. Deterministic work remains deterministic.
3. Ambiguity stops for explicit human judgment.
4. A human-selected merge may fill blanks but may not overwrite conflicting non-empty values.
5. Source evidence survives canonical conflict resolution.
6. Existing manually governed state is not silently overwritten.
7. Domain writes go through existing TrustWeave contracts.
8. No paid/external AI provider is required for the current V1 slice.

## Source contract

A narrow source gate is registered:

```bash
npm run validate:v1-activation
```

It verifies only the V1 activation invariants and provider/cost independence. It is not a substitute for real product validation.

No broad browser suite, connected QA suite, GitHub Actions workflow or Supabase runtime was executed for V1 in this implementation session.

## Deliberate exclusions

V1 does not authorize work on:

- Residential activation;
- School;
- new generic vertical architecture;
- federation expansion;
- broad Intelligence Fabric;
- generic RAG/chat;
- PDF/WhatsApp/Drive ingestion;
- paid AI APIs;
- exhaustive browser certification;
- D12 reconstruction/perfection work.

## Database/runtime gate

Source implementation is ahead of the currently applied database until migration 124 is explicitly approved and applied.

Do not apply migration 124 automatically.

The Founder must explicitly authorize any database change.

After that authorization, the smallest useful runtime proof is:

1. use one controlled Family Community network;
2. use one representative real-world Association activation pack;
3. analyze it;
4. record number of human decisions required;
5. activate it;
6. inspect the reconstructed governed network;
7. inspect the first institutional intelligence;
8. compare setup effort and usefulness against manual Excel/admin work.

No broad QA program is required for that proof.

## Product success criteria

V1 should be judged primarily by:

- proportion of useful structure reconstructed automatically;
- number of meaningful human decisions required;
- wrong facts avoided because uncertainty was surfaced;
- setup time saved;
- usefulness of the resulting network immediately after activation;
- organizer trust in provenance;
- willingness to activate another chapter/network this way.

The strongest product signal is not a passing test suite.

It is a real organizer saying:

> “You understood most of this for me. Give me the rest of the organization to load.”

## Current decision boundary

V1 source implementation is sufficient to stop feature expansion.

The next value-bearing step is **real artifact-pack validation**, not more platform construction.

Do not begin V2 Governed Institutional Intelligence as a broad mission until V1 produces credible real-user/product evidence.
