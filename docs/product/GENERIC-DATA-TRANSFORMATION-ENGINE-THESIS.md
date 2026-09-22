# Generic Data Transformation Engine — Product Thesis & Trust Contract

**Date:** 2026-09-22  
**Status:** Product thesis / architecture boundary — PARKED beyond the lean TrustWeave proof  
**Working description:** Human-supervised X → Y spreadsheet/data transformation engine  
**Relationship to TrustWeave:** Separate, independently usable product/core that may power TrustWeave through a thin adapter

## 1. Product thesis

Organizations already possess data. The expensive work is usually not typing it again; it is understanding inconsistent source structure, mapping it to a desired target structure, repairing data at scale, handling exceptions safely, and proving what changed.

The engine should therefore solve:

> Given source data X and desired target schema/output Y, help a human create a trustworthy transformation plan, apply the repetitive work at scale, isolate uncertainty, and produce a usable result without inventing meaning.

The engine is not a TrustWeave-specific importer.

It must eventually be capable of:

- arbitrary supported spreadsheet/CSV source X;
- arbitrary supported target schema or target workbook Y;
- cleaning and deterministic normalization;
- user-assisted source → target mapping;
- reusable transformation/value rules;
- validation and referential checks;
- pattern-based bulk repair proposals;
- exception queues;
- partial safe completion;
- downloadable transformed output;
- machine-readable output for host integrations;
- full transformation provenance.

TrustWeave is one consumer of this engine, not its owner.

## 1A. Reuse-before-build rule

This product follows **adopt → compose → extend → build** in that order.

Before implementing any non-trivial capability:

1. search for mature open-source libraries/products that already solve it;
2. evaluate license, maintenance/activity, security posture, portability, data/privacy behavior and integration cost;
3. prefer composing proven components when they satisfy the trust contract;
4. extend/fork only when the extension surface is stable enough and ownership cost is justified;
5. build from scratch only when no suitable component exists, integration would create greater long-term complexity, or the capability itself is part of the product's differentiation/moat.

Commodity capabilities that should normally be reused rather than reinvented include:

- XLSX/CSV parsing and writing;
- table rendering/virtualization;
- ordinary header matching;
- basic schema/type validation;
- common deterministic transforms;
- similarity/string-distance primitives;
- export formatting;
- generic data profiling where a suitable library exists.

Capabilities we may need to own because they express the product thesis include:

- human-supervised X → Y transformation recipes;
- decision provenance and trust state;
- safe partial-completion semantics;
- pattern-level repair proposals with affected-scope preview;
- reusable confirmed semantic rules;
- source/target drift detection;
- exception orchestration;
- host/target adapter contract.

Open source is the default preference, not a religion. A paid dependency/product may be considered when there is a real paying customer or clear commercial justification and the build-vs-buy economics favor adoption.

**No paid or metered product/service may be activated, trialled with billable usage, provisioned or purchased without explicit Founder approval and a clear cost warning.** Customer willingness to pay changes the economic decision; it does not remove the approval gate.

Dependency adoption must not weaken the core trust invariants. If an external library guesses semantic meaning without adequate control, we wrap/disable that behavior or do not use it.

## 2. Hard architectural boundary

The generic engine must be independently usable and independently testable.

The core must NOT import TrustWeave domain concepts, database clients, Supabase contracts, Family Community vocabulary, network authorization logic, or TrustWeave UI components.

Integration direction:

```text
Generic Transformation Engine
        ↑
   stable adapter contract
        ↑
TrustWeave Activation Adapter
        ↓
TrustWeave target schema / validation contracts
        ↓
TrustWeave governed compiler + activation
```

The engine may expose library, CLI, API or embeddable UI surfaces later, but these are delivery decisions rather than core semantics.

If independent generic-engine implementation is later authorized, it **must live in a separate codebase/repository** and remain independently runnable/testable. TrustWeave should define and consume only a stable adapter contract; it must not absorb a full generic subsystem into the application. Repository creation is parked until the lean TrustWeave source-mapping proof shows enough reusable value to justify it.

## 3. Genericity rule

Do not make the engine "generic" by accumulating domain synonym dictionaries.

Examples of prohibited core behavior:

- hard-coding that `Family Head`, `Main Member` or `Primary Member` means representative;
- hard-coding Association-specific statuses or role semantics;
- guessing that a column called `Group` means household;
- interpreting `Y`, `P`, `A2`, `Current?` or similar values without a rule or user confirmation.

Domain adapters may declare target fields and validation constraints. The human may confirm mappings. The engine may suggest. The core must not silently invent domain meaning.

## 4. Division of labor

### Machine responsibility

The engine should perform high-volume work:

- inspect sheets, dimensions, headers and data distributions;
- detect likely header/data regions;
- infer technical data types;
- normalize deterministic formatting;
- propose source → target mappings;
- discover repeated patterns;
- apply confirmed rules across thousands of rows;
- validate transformed output;
- group similar exceptions;
- produce completion/error reports;
- generate target workbook/data;
- preserve before/after provenance.

### Human responsibility

The human should provide low-volume semantic knowledge:

- what a sheet or row represents when unclear;
- which source field maps to which target field;
- what ambiguous values mean;
- which duplicate identity is canonical;
- whether a proposed rule is valid;
- which data may be ignored;
- missing facts that cannot safely be derived.

The product should optimize the leverage ratio:

> Humans provide meaning once. The engine performs the repetitive work everywhere.

## 5. Trust invariant

**Incomplete data is acceptable. Wrong trusted data is not.**

The engine optimizes for maximum safely usable data, not maximum imported data.

It is always acceptable to:

- leave a column unmapped;
- leave a row unresolved;
- process only part of a file;
- export a partially completed target;
- request human confirmation;
- reject unsupported structure;
- ask the user to supply missing information.

It is never acceptable to silently fabricate meaning to make completion numbers look better.

## 6. Decision classes

Every transformation must belong to one of these classes.

### Deterministic

Meaning is not being inferred.

Examples:

- trim leading/trailing whitespace;
- canonicalize line endings;
- normalize explicitly configured phone punctuation;
- exact type conversion that cannot change semantic meaning;
- apply a user-confirmed mapping/rule.

May be applied automatically when reversible and recorded.

### Suggested

The engine has evidence for a likely mapping or repair, but semantic meaning is involved.

Examples:

- `Mobile No.` likely maps to target `phone`;
- 98% of values match a target enum;
- the same value pattern consistently maps one way in confirmed records.

Must be previewed and confirmed at the appropriate scope before canonical use.

### Unknown / ambiguous

Evidence is insufficient or conflicting.

Do not guess. Ask, leave unresolved, or exclude from the safe output.

## 7. Mapping experience

The basic interaction is not "fix every row."

It is:

> Confirm the transformation plan.

Example:

```text
SOURCE                 TARGET                     DECISION
Member_Name      →     Person Name               suggested
Mob              →     Phone                     suggested
FY               →     Membership Year           suggested
Current?         →     Membership Status         unknown
Legacy Notes     →     —                         unmapped
```

The user may:

- accept a suggested mapping;
- choose another target;
- mark source as intentionally ignored;
- defer;
- define a value mapping;
- define a transformation rule.

One confirmation should apply to all relevant rows unless explicitly scoped otherwise.

## 8. Pattern repair experience

The hero behavior is:

> Detect → explain pattern → propose rule → show affected rows → human confirms → bulk apply → isolate exceptions.

Example:

```text
Observed:
132/132 rows with Fee Paid = Yes also have Status = Active.
17 comparable rows have Fee Paid = Yes and blank Status.

Proposal:
Fill Active in those 17 rows.

[Review 17] [Apply rule] [Do not use]
```

The engine must show why the rule was proposed and exactly which records it will affect.

No pattern-derived semantic rule becomes trusted merely because its statistical confidence is high.

## 9. Transformation recipe

Every completed mapping session should be representable as a reusable, inspectable recipe.

A recipe should be able to contain:

- source sheet/header selection;
- target schema/version;
- column mappings;
- ignored columns;
- type conversions;
- value mappings;
- split/merge rules;
- normalization rules;
- validation rules;
- reference rules;
- duplicate/identity decisions where reusable;
- human confirmations;
- unresolved/exception policy.

When a later source file changes, the system should detect drift rather than blindly reuse the old recipe.

## 10. Output model

The product should support three outcomes.

### A. Safe transformed output

Generate the target workbook/CSV/data payload with only accepted transformations.

### B. Completion workbook

Generate an approximately 80–95% completed target workbook where unresolved required cells/rows are visibly highlighted for the user to complete.

### C. Review report

Generate a companion report such as:

- Summary;
- Unmapped Columns;
- Missing Required Data;
- Invalid Values;
- Possible Duplicates;
- Broken References;
- Conflicting Records;
- Applied Rules;
- Ignored Data.

A user should receive value even if they never connect a destination application.

## 11. Provenance contract

For every changed value, retain enough information to answer:

- what was the original source?
- where was it located?
- what is the transformed value?
- which rule changed it?
- was the rule deterministic, suggested+confirmed, or manually edited?
- who/what confirmed it?
- what recipe/version was used?
- when was it processed?

Raw source and transformed result are different artifacts and must never be conflated.

## 12. Standalone product test

The generic engine deserves independent product investment only if it can prove value outside TrustWeave.

A standalone proof should demonstrate:

1. input workbook/CSV not designed for the engine;
2. independent target workbook/schema;
3. user confirms a small number of structural/mapping questions;
4. engine processes substantially more rows than the user touches;
5. unresolved cases are isolated rather than guessed;
6. user receives a useful transformed file and review report;
7. transformation recipe can be reused on a second similar source;
8. source drift is detected safely.

TrustWeave adoption alone does not prove the standalone product.

## 13. TrustWeave integration rule

TrustWeave should eventually provide:

```text
TrustWeave target schema
        ↓
Generic engine maps/cleans source
        ↓
safe normalized output
        ↓
TrustWeave candidate compiler
        ↓
TrustWeave ambiguity/domain review
        ↓
governed activation
```

The generic engine owns data adaptation.

TrustWeave owns:

- target domain semantics;
- network identity;
- governed relationships;
- authorization;
- domain-level conflicts;
- evidence retention policy;
- canonical activation.

Neither layer should duplicate the other's responsibility.

## 14. Cost and AI rule

The core must work without requiring a paid AI/model API.

AI may later be an optional suggestion provider behind an adapter, but:

- it cannot be required for deterministic transforms;
- it cannot write trusted output without the same decision rules;
- source data must not be sent to an external model without an explicit privacy/product decision;
- any potentially billable external model/API requires explicit Founder approval before use.

The same approval rule applies to paid libraries/products generally: commercial justification may make a paid dependency rational, but it never authorizes spending automatically.

## 14A. Mandatory dependency decision record

Every implementation mission must explicitly state, before custom code:

- which existing/open-source systems were considered;
- license/commercial-use compatibility;
- maintenance/activity and known security posture;
- runtime/stack/privacy implications;
- estimated percentage of the mission they remove;
- adopt / compose / extend / build decision;
- why any owned code is differentiated or otherwise necessary.

“Open source exists” is not enough to adopt it. “We can code it” is not enough to rebuild it.

Canonical discussion synthesis and mission queue:

- docs/product/NETWORK-ACTIVATION-AUTOPILOT-DISCUSSION-SYNTHESIS-AND-MISSION-QUEUE.md

## 15. What is not authorized yet

This thesis does NOT authorize:

- creating a new repository;
- provisioning infrastructure;
- selecting a paid AI provider;
- building a cloud service;
- generic OCR/PDF extraction;
- broad connector development;
- billing/multi-tenant SaaS work;
- replacing the existing TrustWeave candidate compiler;
- applying TrustWeave migration 124.

The immediate work is only the bounded TrustWeave NAA-L1 source-mapping proof. The broader standalone engine remains product inventory until the Founder explicitly re-selects it from the cross-product tracker.

## 16. Product principle

> **The engine does the scale work. Humans provide the meaning. Neither pretends to do the other's job.**

And the non-negotiable trust rule:

> **Never ingest or emit semantic data as trusted merely because guessing would improve completion.**
