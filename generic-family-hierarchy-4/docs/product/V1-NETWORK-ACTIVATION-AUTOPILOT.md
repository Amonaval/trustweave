# V1 — Network Activation Autopilot

**Date:** 2026-09-22  
**Execution branch:** `network-activation-autopilot-lean`  
**Product status:** **NAA-L1 SOURCE IMPLEMENTED / MANUAL RUNTIME PROOF DEFERRED**  
**Primary proving vertical:** Family Community / Cultural Association  
**Runtime/database effects in this implementation session:** none

## Product hypothesis

A real institution should not need to manually rebuild itself inside TrustWeave.

V1 tests whether TrustWeave can take the records an organization already has — without first forcing the user to manually migrate them into a TrustWeave-shaped workbook — convert as much as is safely possible with small amounts of human semantic guidance, reconstruct a governed network, preserve uncertainty/provenance, and immediately produce useful institutional observations.

The product promise is:

> Bring the organization you already have. TrustWeave reconstructs what it can prove, asks only about what it cannot safely decide, and activates the approved result through existing governed domain contracts.

V1 is intentionally a product/value experiment, not another architecture program.

## Current proving slice

The first implementation built the **lower half** of the product correctly: a governed compiler and activation path for a known Family Association schema.

That implementation is retained, but it is no longer considered the complete V1 product.

The actual V1 must accept supported arbitrary Excel/CSV structures and help the user adapt them into the canonical activation model.

A user may be asked for small, high-leverage semantic work such as:

- what one row represents;
- which source sheet matters;
- which source column maps to which target field;
- what an ambiguous code/value means;
- whether a proposed bulk transformation rule is correct;
- which columns may be ignored.

A user must **not** be required to manually rebuild thousands of rows into the TrustWeave template before V1 can help.

The proving slice still deliberately excludes PDF interpretation, WhatsApp/Drive connectors, generic OCR, broad RAG/chat and paid model APIs.

Canonical generic-engine contract:

`docs/product/GENERIC-DATA-TRANSFORMATION-ENGINE-THESIS.md`

## End-to-end flow

```text
Arbitrary supported Excel / CSV
        ↓
V1-A0 Structure Discovery
        ↓
Assisted Source → Target Mapping
(user confirms meaning where needed)
        ↓
V1-A1 Transform + Repair
(deterministic normalization + confirmed bulk rules)
        ↓
Safe normalized activation model
+ unresolved exception set
        ↓
V1-B Governed Candidate Network Compiler
        ↓
Domain ambiguity / identity review
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
V1-D First Institutional Intelligence
```

The generic adaptation layer should ultimately live as an independently usable product/component. TrustWeave should consume it through a thin adapter rather than embedding TrustWeave vocabulary into the generic core.

## V1-A0 — Lean Source Mapping Bridge — SOURCE IMPLEMENTED

Before the existing compiler runs, V1 needs a generic source-adaptation layer that can inspect supported arbitrary Excel/CSV input and construct a user-confirmed mapping into a target schema.

This layer must not rely on hard-coded Association synonym dictionaries. It may suggest mappings, but semantic mappings become trusted only through deterministic evidence or human confirmation.

The current `core/activation-autopilot/compiler.ts` remains the downstream governed compiler for an already normalized activation model.

The existing governed compiler records:



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

## V1-A1 — Broader Transform & Repair — PARKED after the lean slice

The long-term engine may perform richer high-volume repair after mapping, but this is **not the current alpha commitment**.

The lean slice implements only enough deterministic transformation and unresolved-item reporting to prove that an arbitrary ordinary workbook can reach the existing governed compiler safely.

Parked capabilities include:

- deterministic normalization;
- confirmed source-to-target mapping;
- value mapping;
- split/merge transforms where explicitly defined;
- validation;
- broken-reference detection;
- grouped exception discovery;
- pattern-based repair proposals;
- bulk application of user-confirmed rules.

The product should prefer asking the user to approve one rule over asking them to edit hundreds of rows.

When safe completion is partial, the engine may produce:

- safe normalized output;
- an approximately completed target workbook with unresolved cells/rows highlighted;
- a companion review report listing missing, invalid, conflicting, unmapped and ignored data.

It is acceptable to process only the safe subset.

**Incomplete data is acceptable. Wrong trusted data is not.**

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

The complete V1 UX should be:

1. upload the organization's existing workbook/CSV;
2. discover sheets/structure and ask only necessary structural questions;
3. propose source → target mappings;
4. let the user confirm/adjust/ignore mappings;
5. process all rows using deterministic and confirmed rules;
6. present bulk repair suggestions and unresolved exceptions;
7. optionally export a partially completed target workbook + review report;
8. pass only the safe normalized model into the governed candidate compiler;
9. resolve remaining domain/identity ambiguity;
10. activate the governed network;
11. show immediate institutional intelligence.

The current implementation begins effectively at step 8.

The old guided importer remains available to other productized verticals.

## Trust rules

V1 is governed by these rules:

1. The user must not be forced to manually migrate large source files into a TrustWeave template before the product can help.
2. The generic adaptation core must not hard-code TrustWeave/Association semantic synonym dictionaries.
3. Humans may be asked for small, high-leverage semantic confirmations; the system should perform the repetitive data work.
4. Semantic uncertainty is never converted into trusted data merely to increase completion percentage.
5. AI/inference never writes directly to canonical network state.
6. Deterministic work remains deterministic.
7. Suggested mappings/rules are previewed and confirmed at the appropriate scope before semantic use.
8. Ambiguity stops for explicit human judgment.
9. Partial safe processing/export is a valid successful outcome.
10. A human-selected merge may fill blanks but may not overwrite conflicting non-empty values.
11. Source evidence survives canonical conflict resolution.
12. Existing manually governed state is not silently overwritten.
13. Domain writes go through existing TrustWeave contracts.
14. No paid/external AI provider is required for V1.

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

The governed compiler/activation foundation is sufficient; do not expand that lower layer further without evidence.

**NAA-L1 source implementation now provides:**

1. accept an ordinary supported XLSX/CSV;
2. select/detect the relevant sheet/header;
3. show source columns beside the TrustWeave target fields;
4. suggest only where cheap/safe, and let the user confirm/change/ignore mappings;
5. transform the safely mapped data into the current activation model;
6. show unresolved/missing items clearly, with no semantic guessing.

Source implementation is complete. Manual/browser proof against the synthetic files remains useful evidence, but it is not a reason to keep expanding this workstream. Pattern repair, recipe persistence, drift detection, standalone commercialization and broader generic X→Y support remain parked until evidence calls for them.

The generic source-to-target engine is a parallel product thesis with a strict separation boundary. Do not create its standalone repository, infrastructure or broad feature set until explicitly authorized.

Do not begin V2 Governed Institutional Intelligence as a broad mission until V1 can demonstrate that genuinely messy source data can be converted into trustworthy governed context with low human effort.

## Canonical discussion synthesis and mission sequence

The product-learning discussion that changed V1 from a known-schema importer into arbitrary-source adaptation is captured in:

- docs/product/NETWORK-ACTIVATION-AUTOPILOT-DISCUSSION-SYNTHESIS-AND-MISSION-QUEUE.md
- docs/product/GENERIC-DATA-TRANSFORMATION-ENGINE-THESIS.md

**NAA-L1 is implemented in source. Network Activation is now parked for portfolio re-selection.**

Implementation reused the existing SheetJS/XLSX dependency and added only the product-specific mapping/trust seam. No additional importer framework was added because the bounded need did not justify another dependency/runtime surface.

Current behavior:

- inspect ordinary XLSX/CSV;
- suggest a header row while keeping it user-controlled;
- map one source sheet to any TrustWeave activation target section;
- suggest only exact header-name matches, never fuzzy semantic meaning;
- allow confirm/change/ignore mapping;
- apply mapped values across all rows with existing target validation;
- reject ambiguous date strings rather than guessing locale;
- preserve original source sheet/row provenance;
- allow partial candidate preview;
- leave missing stable IDs genuinely missing and block activation until mapped.

Do not create the standalone engine repository yet. That remains a future option if real evidence justifies it.
