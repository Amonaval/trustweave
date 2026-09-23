# TrustWeave — Decision, ROI & Execution Rules

**Status:** CANONICAL OPERATING RULES  
**Effective:** 2026-09-23

Purpose: prevent drift, over-engineering, token waste, Founder-time waste and high-effort/low-value missions.

## 1. 30/70 lean-delivery rule

For alpha/pilot work, default to approximately **20–30% of theoretical perfect effort to capture 70–80% of impact or learning**.

Solve the dominant problem first, validate the path, stop when the next unit of effort has sharply lower value, and park remaining improvements visibly rather than silently expanding scope.

Security, privacy, tenant isolation, irreversible data integrity and legal/compliance obligations are exceptions where higher assurance may be required.

## 2. 20/80 product-leverage rule

Seek the small set of generic capabilities and user needs that create most repeated product value.

Prefer one shared lifecycle over per-vertical copies; shared identity/membership/role/notification/media/action primitives; and thin adapters when semantics match.

Do not force reuse when domain meanings differ merely because UI looks similar. The ratio is a heuristic for leverage, not an architecture KPI.

## 3. Generic + Easy + Impactful

A requirement rises sharply in priority when it is:

- **Generic:** useful across several networks without corrupting domain meaning;
- **Easy:** bounded enough to ship/verify without starting a new architecture program;
- **Impactful:** materially improves adoption, trust, task completion, return usage or commercial value.

When all three are true, treat it as a default high-priority candidate.

## 4. One active priority

OPEN, PLANNED, PARKED, INTERESTING and DOCUMENTED do not mean NEXT.

At each checkpoint:

1. select the highest-value bounded mission;
2. keep other ideas visible in roadmap/workstream;
3. do not execute them merely because they are documented;
4. re-select only after the stop condition or materially new evidence.

## 5. Thinking order

Always reason in this order:

> **Company trajectory → real user/buyer problem → adoption/trust → product outcome → reusable platform opportunity → vertical semantics → architecture → implementation → code.**

Never optimize code before confirming the mission is worth doing.

## 6. Priority formula

Use as a reasoning aid:

> **Priority ≈ (User Impact × Reuse × Adoption Probability × Learning × Strategic/Commercial Value) / (Complexity × Maintenance Cost × Founder Cost × Risk)**

Do not fabricate precise scores when evidence is weak. High/Medium/Low is enough.

## 7. Founder time is a first-class cost

Prefer self-explaining journeys, repeatable onboarding, durable docs, deterministic tooling, bounded missions and automation that removes routine relay.

Founder outreach is valuable when conversations produce evidence rather than require long product explanation.

## 8. Adopt → Compose → Extend → Build

Before creating something new:

1. **Adopt** an existing trusted capability.
2. **Compose** existing TrustWeave capabilities.
3. **Extend** a shared capability when the need is genuinely reusable.
4. **Build** a new capability only when the above cannot preserve the required semantics/outcome.

Rewrites require stronger justification than incremental evolution.

## 9. Humans provide meaning; machines scale

Do not ask automation to invent trusted semantics from ambiguity.

A person confirms what a source column means; the machine applies it to thousands of rows. An operator defines policy; automation handles repetitive execution. Sensitive AI actions remain governed.

**Partial correct output beats fabricated completion.**

## 10. Evidence ladder

Never blur:

1. Designed / planned.
2. Implemented.
3. Source-gated.
4. Runtime-verified.
5. Pilot-validated.
6. Released / adopted.

Source-green is not runtime proof. A screenshot is not retention proof. A Founder demo is not product-led comprehension proof.

## 11. Stop-condition rule

Every substantial mission declares:

- the outcome that must work;
- evidence sufficient for this stage;
- deliberate exclusions;
- what would justify reopening.

Without a stop condition, work drifts toward perfection rather than value.

## 12. Architecture trigger

Architecture work is justified when it removes repeated implementation, fixes a real security/data/reliability boundary, materially reduces time to launch networks, enables a validated product outcome, or removes meaningful long-term operational burden.

A cleaner abstraction being imaginable is not enough.

## 13. Performance/scale trigger

Measure before scaling.

Do not add Kafka, Jenkins, queues, caches, paid tiers or distributed systems because they are industry-standard or on a future roadmap.

Escalate infrastructure only when measured load, reliability, operations or commercial requirements demand it.

## 14. AI investment rule

Prioritize AI when TrustWeave's structured, permissioned context makes it meaningfully more useful than a generic AI tool.

Park AI that is generic chat, expensive text generation without a real job, non-auditable where trust matters, weaker than deterministic logic, unsafe to permission, or disconnected from an observable outcome.

## 15. Zero-additional-cost rule

Do not initiate, enable, provision or consume anything that could create additional cost without explicit Founder warning and consent.

This includes paid APIs/models, metered cloud resources, paid Supabase/Vercel tiers, GitHub Actions when billing risk exists, new infrastructure/services and chargeable automation.

Free/local/source-only work is preferred while sufficient.

## 16. Commit discipline

Default for a bounded mission:

- **1–5 coherent commits**;
- approximately **5–10 maximum** for substantial work;
- avoid tool-generated micro-commits;
- batch related source/tests/docs/evidence when safe;
- split only when rollback, bisect, security or migration sequencing materially benefits.

## 17. QA discipline

Use the smallest evidence set that proves the mission outcome.

Prefer targeted deterministic checks, focused source review and the affected runtime journey. Do not reopen broad suites/reconstruction programs unless a current product/release risk requires them.

## 18. Database discipline

- historical migrations are immutable;
- existing databases upgrade through migrations;
- bootstrap represents accepted state, not experiments;
- runtime-prove difficult DB/storage behavior when practical;
- add final repair migrations instead of rewriting deployed history;
- synchronize final effective contracts into the current bootstrap tail;
- never put speculative SQL into bootstrap.

## 19. Knowledge / documentation discipline

Conversation history is temporary. Durable decisions belong in canonical Markdown.

The knowledge base must become **smaller, smarter and more valuable**, not larger by ceremony.

Always-load context for material work:

1. AI-START-HERE.md;
2. 00-FOUNDER-DIRECTION-AND-12-MONTH-STRATEGY.md;
3. this file;
4. PRODUCT-CONSTITUTION.md;
5. CURRENT-STATE.md and MISSION-STATUS.md.

Then load only the product/architecture/history needed for the task.

At the end of meaningful work ask whether strategy, current priority, architecture, user learning, commercial evidence or a permanent failure pattern changed. Update only the canonical owner of that truth.

A NEXT-SESSION file is temporary navigation/evidence, never higher authority than current source + canonical strategy/current-state docs.

## 20. Final pre-implementation questions

Before coding, answer:

1. What real user/buyer problem changes?
2. Why is this the highest-value work now?
3. Is the need repeated or merely interesting?
4. Can an existing/shared capability solve it?
5. What is the smallest version yielding most value/learning?
6. What proves success?
7. What is the stop condition?
8. What does it cost in Founder time, maintenance and complexity?
9. Does it risk security/privacy/data integrity?
10. If we do nothing, what meaningful outcome is lost?

If these answers are weak, do not start coding.
