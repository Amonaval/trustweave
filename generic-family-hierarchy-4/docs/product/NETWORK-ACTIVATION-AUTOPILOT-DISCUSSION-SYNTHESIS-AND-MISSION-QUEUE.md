# Network Activation Autopilot — Discussion Synthesis, Lean Scope & Backlog

**Date:** 2026-09-22  
**Status:** Canonical product-learning record  
**Applies to:** TrustWeave Network Activation Autopilot + Generic Data Transformation Engine  
**Execution authority:** Founder Compass + V1 contract + Roadmap remain binding; this document explains the reasoning and mission sequence.

## 1. Why this record exists

The first Network Activation Autopilot implementation proved the governed lower half: a known-schema workbook can be compiled into candidate facts, ambiguity can be reviewed, provenance can be retained, and an approved plan can flow into existing TrustWeave contracts.

The discussion after that implementation exposed a more important product truth:

> A product does not remove onboarding work if it first asks the customer to manually rebuild their existing Excel into our preferred Excel.

The real problem is source adaptation, semantic mapping, high-volume cleaning/repair, exception isolation and trustworthy conversion into a desired target.

This discovery creates two connected products:

1. **TrustWeave Network Activation Autopilot** — turns an institution's existing records into trustworthy governed context and then activates them.
2. **Generic Data Transformation Engine** — a separate, independently usable X → Y spreadsheet/data transformation product that performs the source-adaptation work and can power TrustWeave through an adapter.

## 2. Locked product decisions

### Existing data first

Users should bring the files they already have. Supported arbitrary Excel/CSV is the starting point.

A user may perform small semantic tasks. A user should not perform large migration work that the machine can safely execute.

### Generic X → Y, not domain synonym accumulation

The generic engine must not become a dictionary of rules such as “Family Head means Representative.”

The engine receives a source and a target. It can suggest mappings, profile values and detect patterns. The human confirms meaning when meaning is not safely knowable.

The same engine should eventually be capable of mapping one arbitrary supported spreadsheet structure X to another target workbook/schema Y after cleaning.

### Separate codebase

When implementation of the generic engine begins, it must live in a **separate codebase/repository** from TrustWeave.

It must be independently runnable/testable and must not import TrustWeave domain code.

TrustWeave integrates through a thin target adapter or other stable contract.

The separate repository is not created merely for architecture cleanliness. Creation begins only after the open-source capability spike establishes what we actually need to own.

### Humans provide meaning; machines provide scale

Good questions are allowed.

Examples:

- Which row contains the header?
- What does one row represent?
- Match these source fields to these target fields.
- What does value P mean?
- Should this column be ignored?
- Is this proposed bulk rule correct?
- Are these two records the same person?

The product should ask a small number of high-leverage questions and then perform the repetitive work across hundreds or thousands of rows.

### Trust outranks completion

**Incomplete data is acceptable. Wrong trusted data is not.**

It is valid to:

- leave fields unmapped;
- exclude unresolved rows;
- process only a safe subset;
- return an 80% completed workbook;
- highlight missing information;
- ask the customer to fill genuinely missing facts;
- refuse unsupported structure.

It is not valid to invent semantic meaning so that the progress indicator reaches 100%.

### Smart repair is a hero capability

An Ambiguity Inbox that only lists errors is not enough.

The desired behavior is:

> detect → understand repeated pattern → explain → propose rule → show affected scope → user confirms → apply in bulk → isolate exceptions.

The user should approve rules, not repair the same problem hundreds of times.

### The transformed file itself is a product outcome

The user should be able to receive value without activating TrustWeave.

Important outputs:

- safe transformed target file;
- partially completed target workbook with unresolved areas highlighted;
- review/error workbook or report;
- transformation recipe;
- machine-readable output for an integrating product.

### Transformation Recipe is a durable product object

A successful session should create an inspectable reusable recipe containing source structure, target schema, mappings, value rules, transforms, validation, ignored fields, exception policy and confirmations.

On the next file, reuse the recipe and surface **drift**, rather than restarting mapping from zero.

## 3. User and buyer lenses

### TrustWeave primary operator

Likely personas include an Association Secretary, Membership Coordinator, committee volunteer or operational administrator.

They often understand the organization and Excel but do not know schemas, databases or data modeling.

Their ideal statement is:

> “Here are the files we actually use. Tell me the few things you need from me, do the repetitive work, and show me what still needs judgment.”

A President/Chairman may authorize or sponsor activation, but is not necessarily the person doing the data work.

### Standalone transformation-engine user

Likely early personas include implementation/data-operations specialists, customer-success/onboarding teams, internal operations teams, consultants and administrators repeatedly converting customer/vendor/legacy exports into required formats.

The paying buyer may care about migration time, onboarding throughput, error reduction, auditability or repeated monthly/quarterly conversion.

### Anti-persona

The initial product should not be optimized for a developer who is happy to write custom ETL scripts. That user already has powerful tools.

## 4. Questions a skeptical buyer will ask

### “Can I give you the file I already have?”

That must be the default within the supported-format boundary. If structure is unclear, ask the user to identify the table/header/range rather than forcing template migration.

### “How do I tell you what I need?”

Target Y should be representable through one or more of:

- a target schema contract;
- an empty/template target workbook;
- a representative expected-output file;
- a host-product adapter such as TrustWeave.

### “Will you silently change my data?”

No semantic change becomes trusted merely because an algorithm is confident. Deterministic changes are recorded; semantic suggestions require confirmation at the right scope.

### “Will I approve 2,000 warnings?”

The product should group recurring issues and propose reusable rules. Human work should grow with the number of meanings/exceptions, not linearly with row count.

### “What happens if only 82% can be solved safely?”

Return the 82% plus an explicit completion/review artifact for the rest.

### “Do I repeat this every month?”

No. Reuse the Transformation Recipe and identify source/target drift.

### “How do I audit what happened?”

Retain original value/location, transformed value, rule, decision class, confirmation, recipe version and processing context.

### “Why not Excel, Power Query, OpenRefine or a generic importer?”

We should reuse those capabilities where appropriate. Our reason to own a product is not spreadsheet parsing. It is the trusted human-supervised transformation workflow: reusable semantic recipes, pattern-level repair, safe partial completion, provenance, drift handling, exception orchestration and target adapters.

## 5. Reuse-before-build — binding execution policy

The default sequence is:

> **adopt → compose → extend → build**

Before implementing a non-trivial capability, the mission must record:

- existing open-source candidates;
- license/commercial-use compatibility;
- maintenance/activity signal;
- known security/privacy implications;
- stack/runtime cost;
- integration complexity;
- what percentage of the job it can plausibly remove;
- why we are reusing, wrapping, forking or rejecting it;
- why any custom code is part of differentiation rather than commodity reimplementation.

Open source is not automatically “free engineering.” A dependency that creates more runtime, security or maintenance complexity than it removes should be rejected.

Paid products/libraries are allowed later when customer economics justify them, but no billable trial, provisioning or purchase is allowed without explicit Founder approval and a cost warning.

## 6. Current open-source leverage map

### SheetJS Community Edition — USE / already present

TrustWeave already depends on xlsx/SheetJS for workbook parsing/writing.

Keep using it for spreadsheet I/O rather than inventing an Excel engine.

Before commercial distribution, preserve required license notices/attribution and review the exact version/license obligations.

### react-spreadsheet-import / maintained forks — SPIKE

Useful capabilities include upload flow, header selection, automatic field matching, validation and transformation hooks.

Use it as a capability spike, not an unquestioned permanent architecture choice.

Evaluate current maintenance, security, UI-stack compatibility and whether we should consume, fork or reproduce only a narrow interface around it.

### OpenRefine — BENCHMARK / optional tool, not default embedded core

OpenRefine is a strong maturity reference for cleaning, clustering, reconciliation and reusable operations/history.

Do not make its HTTP API the embedded product boundary without stronger evidence because that API is explicitly unversioned/subject to change and OpenRefine brings a Java local-server runtime.

Borrow concepts and algorithms where appropriate; consider interoperability later.

### Frictionless Framework — CONDITIONAL

Potentially valuable for schema description and tabular validation.

It introduces a Python runtime, so adopt only if it removes enough custom work to justify a second stack.

### DuckDB — SCALE OPTION, not current requirement

Useful later for larger data profiling/transforms and XLSX/CSV processing.

Do not add it until file size/performance evidence warrants another execution layer.

## 7. What we should probably own

Even if open source supplies most plumbing, the differentiated layer is expected to include:

- Transformation Recipe contract;
- trust/decision state;
- human confirmation semantics;
- pattern-repair orchestration;
- safe partial-completion model;
- exception grouping/work queue;
- before/after provenance;
- recipe reuse and source/target drift detection;
- generic target-adapter interface;
- TrustWeave adapter;
- product UX that minimizes human decisions without hiding uncertainty.

This list is a hypothesis. The lean alpha slice must try to shrink it using open source before custom implementation; it is not a commitment to build the whole list.

## 8. One active Network Activation slice

### NAA-L1 — Lean Source Mapping Bridge — NEXT

This is the **only** Network Activation follow-up selected for the alpha.

Goal:

> Let a user bring an ordinary supported Excel/CSV, provide a small amount of mapping help, and get a safe normalized TrustWeave activation candidate without manually rebuilding the whole file.

In scope:

1. upload XLSX/CSV using existing spreadsheet plumbing;
2. select/detect the relevant sheet and header row;
3. present source columns against the current TrustWeave activation target fields;
4. optionally suggest simple mappings using reused/open-source capability, but require confirmation when meaning is uncertain;
5. apply confirmed mappings/deterministic transforms to all rows;
6. show a clear unresolved/missing-data summary and normalized preview/output;
7. pass only the safe normalized subset toward the existing governed compiler.

Exit criteria:

- a handful of structurally different synthetic workbooks can reach the target model without manual row-by-row migration;
- human effort is mainly mapping/meaning confirmation, not bulk data editing;
- unresolved data remains explicit;
- no semantic guess silently becomes trusted;
- no Supabase/database change is required for this proof.

### Stop rule

When NAA-L1 works credibly, **close/park Network Activation and re-select the next highest-value TrustWeave workstream**.

Do not automatically continue into pattern repair, recipe reuse, standalone engine work, unrelated X→Y support or controlled DB activation merely because those ideas are already documented.

The backlog below preserves those options for later evidence-driven selection.

## 9. Parked Network Activation / transformation backlog

| Capability | Status | Resume only when... |
| --- | --- | --- |
| Pattern Repair / bulk smart fixes | PARKED | real files show repetitive cleanup is the dominant remaining user effort |
| Completion workbook + detailed review workbook | PARKED | users prefer/offline-fix unresolved data or UI fixing becomes cumbersome |
| Persistent Transformation Recipe | PARKED | the same source format is imported repeatedly |
| Source/target drift detection | PARKED | recipes are reused and formats actually drift |
| Separate generic-engine repository | PARKED | NAA-L1 demonstrates a reusable boundary worth owning |
| Arbitrary non-TrustWeave target Y | PARKED | standalone-product evidence becomes a portfolio priority |
| Real Association read-only proof | PENDING | NAA-L1 synthetic proof is credible and a representative file is available |
| Controlled TrustWeave activation / migration 124 | FOUNDER GATED | read-only proof is good enough to justify DB mutation |
| Multi-file / multi-table transformations | PARKED | a real source requires them |
| Very-large-file engine / DuckDB | PARKED | measured file-size/performance pain justifies it |
| PDF/OCR/connectors | PARKED | a validated customer workflow requires non-tabular ingestion |
| AI/LLM semantic suggestions | PARKED | deterministic/user-assisted flow proves value and AI has a clear incremental job |

These are backlog pointers, not a serial mission queue.

## 10. Explicit non-goals for the immediate missions

Do not:

- rebuild XLSX/CSV parsing;
- build a spreadsheet/grid library;
- write our own similarity algorithms when mature primitives suffice;
- hard-code TrustWeave/Association field-name dictionaries into the generic engine;
- silently infer semantic codes;
- require a customer to rewrite thousands of rows into our template;
- force 100% completion;
- activate migration 124 merely to test the mapping product;
- broaden into PDF/OCR/connectors;
- build generic RAG/chat;
- start Residential/School implementations;
- create paid cloud/model dependencies without approval.

## 11. Scorecard for the product

Track:

- time from upload to first useful preview;
- number of user semantic questions;
- user decisions per 1,000 source rows;
- rows/cells changed by machine per human decision;
- safe completion percentage;
- unresolved percentage;
- incorrect semantic assumptions that reached trusted output — target **zero**;
- percentage of issues resolved by bulk rules;
- output correctness on reviewed samples;
- recipe reuse percentage on the next file;
- drift correctly detected;
- manual setup time saved;
- willingness to use the engine for another transformation;
- for standalone proof: willingness to pay or commit operational usage.

Automation percentage is secondary to correctness and leverage.

## 12. Kill / rethink criteria

Reconsider the standalone product if:

- ordinary OSS + a thin integration already solves nearly all of the job with no differentiated layer;
- users still perform row-by-row work proportional to dataset size;
- semantic mistakes regularly escape into trusted output;
- Transformation Recipes do not meaningfully reduce repeat work;
- arbitrary target Y cannot be represented without extensive custom development;
- the output/review artifacts are not useful without TrustWeave;
- non-TrustWeave users do not care enough to reuse or pay.

Even if the standalone thesis fails, the generic adapter may remain valuable as TrustWeave infrastructure.

## 13. Immediate handoff

**Next mission: NAA-L1 — Lean Source Mapping Bridge.**

Do not start by writing a new transformation engine.

Start with the smallest useful OSS-assisted mapping flow against the ugly synthetic files. Build only the gaps required to reach a safe normalized TrustWeave candidate.

After that proof, stop this workstream and choose the next priority from the cross-product tracker.
