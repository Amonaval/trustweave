# TrustWeave — Product Workstream Tracker

**Date:** 2026-09-22  
**Purpose:** Keep open work visible without turning every category into a serial mission program.

## Operating rule

TrustWeave is pre-release.

For every product, vertical or architecture area:

1. keep **one highest-leverage next slice** at most;
2. prefer roughly **20–30% effort for 70–80% of learning/value**;
3. finish that bounded slice, then re-select from the whole portfolio;
4. park remaining work with a concrete resume trigger;
5. do not continue a category merely because its backlog is long;
6. release/security/privacy blockers can override this rule.

**OPEN / PARKED does not mean NEXT.**

## Workstream tracker

| Area | Current state | Highest-leverage next slice | Status | Resume / selection trigger |
| --- | --- | --- | --- | --- |
| **Network Activation Autopilot** | Governed lower layer + NAA-L1 source-mapping bridge implemented | None now | **PARKED / manual proof pending** | Resume only for a real/synthetic validation finding, alpha blocker, or evidence that source adaptation remains the dominant onboarding pain |
| Generic X→Y Transformation Engine | Strong parallel thesis; no independent implementation | None now | PARKED | Re-select only if NAA-L1 proves a reusable boundary or a non-TrustWeave buyer/use case appears |
| Pattern Repair / smart bulk fixes | Product idea defined | None now | PARKED | Real files show repetitive repair dominates remaining effort |
| Transformation Recipe / drift detection | Product idea defined | None now | PARKED | Same source format is imported repeatedly and remapping becomes real pain |
| **Family Community / Association** | Strongest near-term activation proving vertical; anonymous Productized Playground handoff repaired in source | **FCA-L1 — MPF East public pilot proof:** verify the public Community → realistic Playground journey and collect a small shareable proof pack; no feature expansion | **ACTIVE / BOUNDED** | Stop after one local proof + pilot-facing screenshots/feedback; resume build work only for a concrete pilot/release blocker |
| Residential / Housing Society | Existing operational vertical with preserved reliability work | No broad expansion | PENDING | Release/pilot blocker or repeated user need |
| School vertical | Architecture/readiness blueprint exists; implementation intentionally absent | None | PARKED | Explicit product/commercial priority with real user/design partner |
| Other new verticals / org use cases | Ideas/foundation exist | None | PARKED | Evidence-backed buyer/problem outranks current work |
| Governed Institutional Intelligence / V2 | Initial deterministic intelligence shape exists | None | PARKED | Trustworthy real activated context + repeated institutional questions |
| TrustWeave Ops / distributed operations | Strong paid-wedge thesis | Discovery, not build | PARKED / THESIS | Design partner shares real workflow/data or concrete commercial pull |
| Architecture — code split / lazy loading | Meaningful D7 work already completed | Only measured bottlenecks | PENDING | Bundle/performance evidence crosses agreed threshold |
| Architecture — shared components / CSS / cleanup | Open convergence opportunities exist | Opportunistic only | PENDING | Repeated maintenance cost or touched-area refactor creates clear leverage |
| Architecture — database/D12 recovery | Review-closed baseline exists | None | PARKED | Concrete recovery/bootstrap/product reason |
| Connected reliability / QA | Preserved unresolved gates exist | Run only when required by release/change risk | GATED | Alpha/release candidate or critical path changed |
| Autonomous-company runtime | C1–C10 proof completed | None | PARKED | A concrete company-operating problem justifies more automation |
| PDF/OCR/connectors/generic AI ingestion | Opportunity inventory only | None | PARKED | Real customer input cannot be solved with supported tabular files |

## Selected next slice — FCA-L1: MPF East public pilot proof

Why this outranks other open work now:

- NAA-L1 is source-implemented and Network Activation is parked;
- Community / Association is the fastest accessible real-network proving ground in the portfolio;
- a concrete anonymous-routing defect blocked the realistic Family Community Playground from public Discovery;
- the fix requires no migration, paid service, new dependency or feature expansion;
- the next meaningful evidence is a real person reacting to the product, not another architecture layer.

**Lean stop condition:** one local anonymous journey from Discovery → Family Community → realistic MPF East Playground works, a small 8–12 screenshot proof pack can be produced if useful, and the result is shown to pilot/design-partner users. Then re-select from the whole portfolio based on evidence.

The screenshot helper under `qa/showcase/` is best-effort tooling only. It must not become a new QA program or block higher-value work.

## Network Activation alpha finish line

NAA-L1 is successful enough to stop when:

- several structurally different synthetic XLSX/CSV files can be mapped without rewriting them into our template;
- the user mainly confirms column meanings rather than editing rows;
- confirmed mappings are applied across the entire dataset;
- unresolved/missing information is explicit;
- no semantic guess becomes trusted;
- the safe normalized output can enter the existing governed compiler path.

Do **not** require pattern-learning, persistent recipes, drift detection, arbitrary external targets, database activation or standalone commercialization to call this bounded slice complete.

## How to pick the next work after NAA-L1

Choose from the whole table using:

1. alpha/release impact;
2. user pain or product learning;
3. trust/security risk;
4. business/commercial pull;
5. effort versus expected value;
6. whether existing/open-source capability can eliminate most implementation.

Do not choose based on which category already has the longest roadmap.

## Commit/history discipline

A bounded mission should normally produce **1–5 coherent commits**. A larger mission should generally remain within **5–10** unless rollback/security/migration/bisect needs justify more.

Batch by outcome, not by file.

For connector-driven work, use Git blob/tree/commit batching rather than accepting one repository commit per tool write.

If exploratory history becomes noisy, create a clean batched merge-candidate branch and retain the noisy branch only as temporary/historical evidence.
