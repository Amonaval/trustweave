# TrustWeave — Strategic Leverage Opportunity Register

**Status:** CANONICAL FUTURE-LEVERAGE REGISTER — NOT AN EXECUTION BACKLOG  
**Effective:** 2026-09-23  
**Review cadence:** strategic/stage-gate reviews, or after roughly 3–4 substantial missions when company/system learning has materially changed.

This document preserves high-leverage ideas that are valuable enough **not to forget**, but not automatically valuable enough to build now.

The current active mission remains whatever `MISSION-STATUS.md` says. An item in this register becomes executable only after current evidence satisfies its activation trigger and normal priority rules select it.

## How to use this register

At a strategic review:

1. inspect current Founder strategy and company stage;
2. inspect real user/commercial/reliability evidence;
3. scan this register for newly satisfied activation triggers;
4. promote at most the few items that now have exceptional leverage;
5. keep the rest parked without guilt.

Do **not** read this entire file for ordinary bug fixes or bounded product missions.

## Opportunity states

- **FOUNDATION PRESENT** — substantial pieces already exist; improve opportunistically.
- **WATCH** — preserve idea and observe trigger.
- **READY WHEN TRIGGERED** — high leverage once stated evidence appears.
- **LATER MATURITY** — deliberately defer until commercial/scale stage.
- **ANTI-GOAL** — useful warning; do not pursue as an objective.

---

## 1. Agent / Company Eval Pack

**State:** READY WHEN TRIGGERED  
**Leverage:** Very high  
**Likely cost:** Low if kept local/deterministic

### Idea

Test not only the product, but the behavior of the AI company itself.

Maintain a compact set of golden scenarios that verify the system continues to:
- choose current Founder strategy over stale handoffs;
- keep one active priority;
- stop at mission stop conditions;
- choose shared capability over duplicated vertical work when semantics match;
- keep MPF/Marbella customer configuration out of generic business logic;
- protect `main`, production and irreversible environments;
- refuse unapproved spend;
- preserve migration immutability;
- distinguish Launch Control from authorization;
- preserve tenant/network privacy and consent;
- distinguish source/runtime/pilot evidence;
- classify environment/harness failures before changing product code;
- retrieve minimal relevant context rather than indiscriminately loading history.

### Why it matters

Models, prompts, tools and sessions will change. Product tests cannot prove that the **company reasoning system** still follows the Founder operating model.

### Activation trigger

Promote when any of these occurs:
- the Company OS autonomously executes several real missions;
- a model/tool change causes inconsistent decisions;
- a repeated strategic/operating mistake appears;
- higher-autonomy external actions are being considered.

### Do not overbuild

Start with roughly 10–25 high-value scenarios. Prefer deterministic assertions. Model-based graders require a clear benefit and approved cost.

---

## 2. Mechanical Invariants / Policy-as-Code

**State:** FOUNDATION PRESENT / GROW OPPORTUNISTICALLY  
**Leverage:** Very high

### Idea

Convert stable repeated rules from prose into cheap mechanical checks where practical.

Candidate invariants:
- historical migrations cannot change;
- forbidden dependency directions;
- tenant/network boundary violations;
- insecure direct access where governed RPC/server boundary is required;
- advanced/releasable capability missing required Launch Control registration;
- frontend rollout flag used as authorization;
- unreleased vertical exposed publicly;
- unsafe public/private projection;
- critical route/deep-link contract regressions;
- duplicated shared-capability implementations;
- hard-coded pilot/customer semantics inside generic modules;
- critical bundle/asset thresholds;
- public artifacts containing confidential/internal-only markers;
- dependency/security policy violations.

### Activation trigger

Add a mechanical rule when:
- the same failure happened more than once;
- the rule is objective enough to test reliably;
- the expected prevention value exceeds maintenance/noise.

### Anti-trigger

Do not mechanize subjective product taste or create brittle lint bureaucracy.

---

## 3. Context Compiler / Token-Economics Layer

**State:** FOUNDATION PRESENT / CONTINUOUS  
**Leverage:** Very high

### Idea

Treat context as a finite engineering/company resource.

Existing context ladder:
- **L0:** tiny always-on strategic/control map;
- **L1:** active mission context;
- **L2:** exact source/evidence;
- **L3:** historical conversations/handoffs only when required.

Future improvement could become a small deterministic context compiler that resolves a mission into the minimum relevant files, source owners, invariants, recent decisions and evidence references.

### Measure

Useful metrics may eventually include:
- tokens/context per mission;
- tool-output volume;
- number of irrelevant docs loaded;
- repeated rediscovery;
- Founder restatement required;
- outcome quality per reasoning/tool pass.

### Activation trigger

Build additional machinery only if:
- repeated sessions reload large amounts of history;
- token/tool cost becomes material;
- important rules are frequently missed despite the read map;
- mission setup consumes meaningful Founder time.

### Anti-trigger

Do not build a vector/RAG knowledge platform simply because the repo has many documents.

---

## 4. Agent Legibility & High-Signal Tool Contracts

**State:** FOUNDATION PRESENT / CONTINUOUS  
**Leverage:** High

### Idea

Agents should be able to directly inspect what matters:
- source/schema;
- current intent and branch/candidate;
- exact environment identity;
- rendered UI when relevant;
- logs/metrics/traces;
- rollout/release state;
- tool permissions;
- cost boundary.

Tools should return bounded, decision-useful outputs instead of massive logs.

### Activation trigger

Improve tooling whenever the Founder repeatedly:
- pastes raw errors/logs;
- explains environment state;
- manually identifies files/routes;
- relays output between agents;
- waits through huge tool responses that contain little decision value.

### Target

**Founder is never the observability API.**

---

## 5. Trace / Decision Observability for Autonomous Work

**State:** WATCH → READY BEFORE HIGHER AUTONOMY  
**Leverage:** High

### Idea

For consequential autonomous runs, preserve structured evidence of:
- input evidence/context;
- decisions;
- tool/action calls;
- policy applied;
- changed artifacts;
- verification;
- cost/external effects;
- escalation/approval.

This enables debugging the **agent/company process**, not only application code.

### Activation trigger

Before allowing:
- autonomous external writes;
- higher-risk database/release actions;
- automated customer communications;
- multiple long-running company functions;
- materially paid AI/tool usage.

### Anti-trigger

Do not persist every hidden thought or produce huge verbose traces. Store actionable decision/action/evidence records.

---

## 6. Enforceable Agent Runtime Security

**State:** READY WHEN AUTONOMY EXPANDS  
**Leverage:** Critical

### Idea

Prompt instructions are not enough for consequential autonomy.

Layer:
1. written policy;
2. least-privilege tool credentials;
3. environment isolation/sandbox;
4. action allow/deny rules;
5. explicit target identity;
6. approval gates;
7. auditable action record.

Special attention when agents consume untrusted external/user text: prompt-injection/data-poisoning resistance, safe tool invocation and explicit trust/provenance boundaries.

### Activation trigger

Required before AI receives broader ability to:
- write production/customer data;
- send external communications;
- spend money;
- alter infrastructure;
- operate across customer tenants;
- execute third-party integrations.

### Permanent rule

More autonomy requires **stronger enforceable controls**, not merely better prompts.

---

## 7. Risk-Based Quality / DevSecOps Matrix

**State:** FOUNDATION PRESENT / CONTINUOUS  
**Leverage:** High

### Idea

Quality gates are selected by changed risk rather than running everything.

Lenses:
- user/UX/accessibility;
- authorization/privacy/tenant/storage;
- migration/data;
- dependency/supply chain;
- performance/query/bundle/media;
- runtime/release/rollback;
- AI permission/evaluation where applicable.

### Activation behavior

Already the default philosophy. Continue improving the mapping from changed owners/contracts to the smallest sufficient gate set.

### Anti-goal

Do not turn “quality” into permanent full-suite execution.

---

## 8. Continuous AI Garbage Collection / Codebase Fitness

**State:** READY WHEN TRIGGERED  
**Leverage:** High over time

### Idea

AI increases implementation speed and therefore can increase entropy speed.

Run small hygiene passes rather than large refactor seasons:
- stale docs;
- dead feature flags;
- unused dependencies;
- duplicate helpers/components;
- CSS ownership drift;
- obsolete compatibility code;
- unresolved TODOs with no value;
- repeated agent-confusion hotspots;
- oversized files/modules;
- architecture invariant drift.

### Trigger

After roughly 3–4 substantial missions, or when repeated maintenance friction appears.

### Budget

Prefer approximately 5–10% cleanup effort, usually in touched/high-friction areas.

### Anti-trigger

Do not create “cleanup” programs without evidence of actual friction.

---

## 9. Product & Company Observability

**State:** READY AS REAL PILOTS BEGIN  
**Leverage:** Very high

### Idea

Move from subjective “looks used” to privacy-respecting evidence.

Product questions:
- activation;
- returning users;
- meaningful actions;
- journey completion;
- notification/deep-link return;
- feature discovery;
- admin support effort;
- recurring network workflows.

Company questions:
- mission lead time;
- Founder interventions;
- autonomous repair rate;
- regression escape;
- context/tool cost;
- per-network onboarding effort.

### Trigger

Real MPF/Marbella pilot usage.

### Rule

Instrument only metrics that can change a decision. Avoid surveillance or vanity dashboards.

---

## 10. Requirements → Verified Release Automation

**State:** WATCH / HIGH LONG-TERM LEVERAGE  
**Leverage:** Potentially transformative

### Idea

Long-term company flow:

> requirement/evidence → strategic classification → capability/vertical impact → bounded spec → implementation → targeted verification → independent criticism → preview → Founder gate where required → publish/release → observe → learn.

Eventually, a new network/vertical trends toward:

> describe → configure → adapt only genuine domain seams → seed/import → validate → Playground/preview → launch.

### Trigger

When several real networks show repeated implementation/onboarding patterns and the automation would remove repeated Founder/developer work.

### Anti-trigger

Do not automate a process that is not yet understood/repeated.

---

## 11. Founder Decision Inbox / Company Control Plane

**State:** FOUNDATION PRESENT / EVOLVE FROM NEED  
**Leverage:** Very high for one-person company

### Idea

One compact Founder surface containing only consequential questions:
- decision;
- why now;
- evidence;
- recommendation;
- strongest alternative;
- risk/downside;
- expected impact;
- cost;
- what AI does after approval.

Routine work continues automatically within policy.

### Trigger

When multiple parallel digital company functions produce decisions, or Founder attention begins becoming the bottleneck.

### Anti-goal

Do not build a pretty dashboard before there is enough real company activity to summarize.

---

## 12. Business-Function AI Automation

**State:** WATCH / GRADUAL  
**Leverage:** Very high after product proof

Potential functions:
- customer support triage/drafting;
- pilot/user feedback synthesis;
- prospect research;
- personalized demo preparation;
- CRM hygiene;
- public-safe product content;
- help center/docs;
- competitive/market intelligence;
- finance/admin evidence organization;
- compliance/legal research and drafting.

### Trigger

A real recurring digital business task consumes Founder time.

### Rule

Automate **repeated work**, not theoretical departments.

External commitment, payment, legal agreement, hiring/equity and material public promises remain Founder/high-consequence gates.

---

## 13. AI Model Portability / Cost-Quality Routing

**State:** LATER / TRIGGERED BY REAL AI USAGE  
**Leverage:** Medium–high

### Idea

Do not permanently couple TrustWeave product intelligence or Company OS to one model/vendor.

Potential future layer:
- model-agnostic task interface;
- deterministic-first decisions;
- cheap/fast model for low-risk work;
- stronger model only where reasoning benefit is measurable;
- caching/reuse where safe;
- cost/latency/quality telemetry;
- fallback strategy.

### Trigger

Multiple material AI workloads, meaningful recurring inference cost, vendor limitations or reliability needs.

### Anti-trigger

Do not build a model router before there is significant AI workload.

---

## 14. AI Trust / Data Provenance / Prompt-Injection Defenses

**State:** READY BEFORE DATA-POWERED AGENTS  
**Leverage:** Critical

### Idea

AI features operating on network/company data need:
- clear provenance;
- trusted vs untrusted source distinction;
- permission-scoped retrieval;
- prompt-injection-aware handling of external/user content;
- explicit action confirmation policy;
- auditability;
- deterministic validation for high-consequence outputs;
- generated suggestions separated from canonical truth.

### Trigger

Before AI can retrieve arbitrary external content, act from user-generated text, or mutate trusted network/company state.

---

## 15. Supply-Chain / Release Integrity Maturity Ladder

**State:** LATER MATURITY  
**Leverage:** High once commercial risk rises

Possible progression:

1. dependency/SCA policy;
2. SBOM;
3. release artifact hashes;
4. reproducible build definition;
5. build/source provenance/attestations;
6. more isolated/hardened build environment;
7. stronger signing/release controls if customer/compliance risk justifies them.

Use principles from NIST SSDF / SLSA / modern software-supply-chain practice as checklists when the stage demands them.

### Trigger

Paid customers, stronger contractual security expectations, enterprise procurement, meaningful release/supply-chain risk.

### Anti-trigger

Do not pay for CI/security infrastructure simply to claim a maturity framework.

---

## 16. Security / Privacy Governance Maturity

**State:** FOUNDATION PRESENT / DEEPEN WITH COMMERCIALIZATION  
**Leverage:** Critical

Future questions:
- formal retention/deletion policy;
- account/network data portability;
- consent history;
- incident response;
- access review;
- customer/admin audit evidence;
- school/child-data obligations;
- regional privacy/compliance needs;
- AI data-use policy.

### Trigger

Real customers/data, School/children use, commercial agreements or expansion into regulated/sensitive contexts.

### Rule

Do not wait for enterprise scale to fix real privacy/security risks, but avoid speculative compliance theater.

---

## 17. Lightweight Experiment / Feature-Exposure Discipline

**State:** FOUNDATION PRESENT VIA LAUNCH CONTROL  
**Leverage:** High

### Idea

Launch Control can evolve into evidence-driven staged exposure:
- internal;
- Playground;
- pilot;
- selected networks;
- broad release.

Where useful, compare behavior/outcomes before broad release.

### Trigger

Enough real users/network diversity exists for staged exposure to generate meaningful evidence.

### Rule

Feature exposure is not authorization. Avoid experimentation that manipulates sensitive/critical user experiences.

---

## 18. Add-on / Integration / Capability-Pack Ecosystem

**State:** LATER  
**Leverage:** Potentially very high

Potential future shape:
- core platform;
- vertical composition;
- optional capability packs;
- integrations/connectors;
- eventually third-party/internal extensions.

### Trigger

Repeated requests for optional integrations/capabilities across multiple customers, with stable contracts.

### Anti-trigger

No marketplace/plugin platform before repeated extension demand.

---

## 19. Formal External Framework Review

**State:** WATCH  
**Leverage:** Medium as a periodic check

At major maturity transitions, compare TrustWeave against selected external practice—not to copy frameworks, but to detect blind spots.

Useful lenses may include:
- AI-DLC / spec-driven development;
- DORA delivery/AI research;
- OWASP agent/application guidance;
- NIST SSDF;
- SLSA;
- accessibility standards;
- relevant privacy/security standards.

### Trigger

Commercial/stage transition or material new autonomy/security model.

### Rule

Borrow principles; do not optimize for badges/framework compliance unless customer/legal value justifies it.

---

## 20. Multi-Agent / Framework Proliferation

**State:** ANTI-GOAL

Do not measure maturity by:
- number of agents;
- number of personas;
- adopting CrewAI/LangGraph/etc.;
- number of orchestration layers;
- number of dashboards;
- length of prompts.

Introduce a framework only when it solves a demonstrated orchestration/state/tooling problem better than the existing Company OS.

> **Maximum autonomy with minimum machinery.**

---

# Strategic review promotion checklist

An opportunity may move toward execution only when most relevant answers are strong:

1. What repeated real problem does it solve?
2. What evidence shows the trigger is now satisfied?
3. Does it improve user value, Founder leverage, quality/trust, speed, cost or commercial proof?
4. Can an existing capability/process solve most of it?
5. What is the smallest useful slice?
6. What measurable improvement would prove success?
7. What ongoing maintenance/complexity does it add?
8. Does it introduce paid services/infrastructure?
9. Is it reversible?
10. What happens if we defer another 3 months?

If deferral has little cost, keep it parked.

# Review cadence

Review this register:
- at major company stage gates;
- during explicit strategic reviews;
- after roughly 3–4 substantial missions if meaningful new patterns emerged;
- when a new external AI/engineering practice looks genuinely relevant;
- when Founder time, cost, security risk or product scale changes materially.

Do **not** review it before every mission.

# Graduation / archival rule

When an item becomes a permanent adopted rule/capability:
- promote the durable contract into its canonical constitution/standard/code/check;
- update this item to ADOPTED or archive it;
- do not keep both this register and another document as competing authorities.

When evidence disproves an idea, mark it REJECTED with the reason. Preserving rejected reasoning can prevent future rediscovery.
