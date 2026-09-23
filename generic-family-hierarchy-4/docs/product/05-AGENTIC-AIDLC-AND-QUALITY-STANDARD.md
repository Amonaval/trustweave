# TrustWeave — Agentic AIDLC & Quality Standard

**Status:** CANONICAL DELIVERY OVERLAY  
**Effective:** 2026-09-23

TrustWeave already has a Mission Lifecycle and Agentic Company OS. Do **not** add a second competing lifecycle.

This document incorporates the strongest useful ideas from modern AI-DLC / spec-driven development / harness engineering / context engineering / agent-evaluation / DevSecOps practice into the existing lifecycle.

It is an **overlay and quality standard**, not a dependency on any vendor framework.

## 1. Existing lifecycle mapping

Use the current mission states, with this mental model:

- **Intent / assess value** → INTAKE + DISCOVERY
- **Specify outcome and constraints** → ARCHITECTURE + PLAN
- **Execute** → IMPLEMENT
- **Evaluate / verify** → VERIFY + REVIEW + HARDEN
- **Publish knowledge / release** → DOCUMENT + RELEASE
- **Measure / learn / compact** → OBSERVE + CLOSE

For bug repair, start from reproducible evidence and cause classification. For idea assessment, stop before implementation when evidence is weak.

## 2. Spec-before-code, but only to the needed depth

Every material mission should establish:
- problem/evidence source;
- user/buyer behavior expected to change;
- why now;
- included/excluded scope;
- architecture/reuse decision;
- acceptance examples;
- risk class;
- required evidence;
- cost/token/Founder budget;
- stop condition.

Small fixes do not need ceremony-heavy specs. Complexity/risk determines depth.

## 3. Repository is the system of record

Chat is working memory. The repo is company memory.

Keep the always-loaded map small. Retrieve detail on demand.

Promote recurring human taste, review comments, user feedback and failure lessons into one of:
- canonical Markdown;
- type/schema contract;
- linter/static rule;
- regression test;
- architecture boundary;
- QA/eval dataset;
- tool/skill.

Prefer mechanical enforcement when a rule is objective.

## 4. Context engineering / token economics

Use a context ladder:

**L0 — always-on map:** current strategy, ROI rules, constitution, current state/status.  
**L1 — mission context:** active charter + only relevant product/architecture/governance docs.  
**L2 — source evidence:** exact files/functions/diffs/schema slices required.  
**L3 — history:** old conversations/handoffs/evidence only when a current question requires them.

Rules:
- map, do not preload encyclopedias;
- search before broad reading;
- return IDs/counts/findings/diffs rather than huge raw outputs;
- summarize long tool results before carrying them forward;
- prefer scripts/tests for deterministic facts;
- periodically compact completed decisions and archive stale plans;
- optimize for **useful context per token**, not maximum context size.

## 5. Agent legibility

Anything important to autonomous work must be inspectable by the agent:
- source and schemas;
- current product intent;
- environment identity;
- logs/metrics/traces when available;
- rendered UI/runtime evidence when relevant;
- tool permissions;
- current branch/candidate;
- cost/spend boundary;
- release state.

If an agent repeatedly fails because information/tooling is inaccessible, fix the environment/harness rather than repeatedly writing a longer prompt.

## 6. Mechanical invariants / taste rules

High-value repeated rules should become checks where practical.

Candidate invariants include:
- forbidden architecture dependency directions;
- tenant/network boundary violations;
- direct-table access where secure RPC is required;
- historical migration mutation;
- unregistered advanced capability exposure;
- missing Launch Control gating where required;
- route/deep-link contract breaks;
- unsafe public/private data projection;
- oversized critical bundles/files;
- duplicated shared capability implementations;
- missing structured failure/error states;
- public docs containing confidential markers;
- known dependency/security policy violations.

Do not encode subjective product taste into hundreds of brittle lints. Mechanize only stable principles.

## 7. Agent/company eval pack

Product tests are not enough; evaluate the **company agent behavior**.

Maintain a small set of golden scenarios that check whether the AI system:
- chooses current Founder strategy over stale handoffs;
- keeps one active priority;
- rejects low-value speculative breadth;
- prefers shared capability to duplicate vertical code when semantics match;
- does not hard-code MPF into generic Community;
- keeps Launch Control separate from authorization;
- protects `main`/production and respects release gates;
- refuses unapproved spend;
- classifies environment/harness failure before product patching;
- never rewrites historical migrations;
- preserves network isolation and consent;
- distinguishes source/runtime/pilot evidence;
- retrieves minimal context rather than loading history indiscriminately;
- stops when the mission stop condition is met.

Run these locally/deterministically where possible. Use model-based graders only when they add clear value and cost is approved.

## 8. Trace / decision evaluation

For important autonomous runs, preserve enough structured trace to answer:
- what evidence was read;
- what tools/actions were used;
- what decision/handoff happened;
- which policy/constraint applied;
- what was changed;
- what verification passed/failed;
- what cost/external effect occurred.

Use this to improve prompts/tools/policies and detect regressions in agent behavior.

## 9. Tool design

Prefer a smaller number of high-signal tools with clear names and bounded outputs.

A tool should:
- expose one coherent action;
- validate inputs;
- return only decision-useful context by default;
- make target/environment identity obvious;
- fail explicitly;
- support dry-run/read-only modes for risky work where possible;
- make consequential mutations auditable.

Do not give agents broad powerful tools merely because they are convenient.

## 10. Security / autonomy

Autonomy requires stronger runtime control, not weaker controls.

Use:
- least-privilege credentials;
- network/tenant-scoped permissions;
- sandboxed execution for untrusted/generated commands where practical;
- tool allow-lists/policy hooks;
- explicit environment identity;
- audit trails;
- secrets kept outside prompts/repos;
- human approval for destructive, externally visible or costly high-impact actions.

Agent control must be enforceable at the action/tool layer, not only written in prompts.

## 11. Risk-based DevSecOps quality

Every mission does **not** run every gate.

Select gates by affected risk:
- product behavior / UX;
- auth/privacy/RLS/storage;
- migration/data;
- accessibility;
- performance/bundle/query;
- dependency/supply-chain;
- runtime/release.

Security, performance and reliability should be continuous **risk lenses**, not late hardening phases.

## 12. Performance and footprint

Measure before optimizing, but make regressions visible.

Prefer:
- lazy/selected-vertical delivery;
- bounded dependencies;
- client/server boundary discipline;
- efficient media;
- query/index evidence for hot paths;
- bundle/runtime budgets on critical routes;
- simple infrastructure until load proves otherwise.

When a performance bug is fixed, keep a reproducible metric/guard where cost-effective.

## 13. Supply-chain / release integrity

As commercial release maturity grows, progressively add:
- dependency/SCA policy;
- SBOM generation;
- release artifact hashes;
- reproducible build definition;
- build/source provenance/attestation appropriate to risk;
- isolated/hardened build environments when commercially justified.

Do not activate paid CI solely to chase a maturity label. Adopt the assurance level justified by real release risk.

## 14. Continuous garbage collection

Agent velocity can create entropy quickly.

Use small recurring cleanup, not giant refactor seasons:
- stale docs;
- duplicate patterns;
- dead feature flags;
- copy-pasted helpers;
- architecture boundary drift;
- unresolved TODOs with no owner/value;
- repeated agent confusion.

When a pattern recurs, fix the system that allowed it.

## 15. Definition of autonomous quality

A mission is not high-quality because AI wrote it quickly.

High-quality autonomy means:
- correct priority;
- minimal necessary change;
- preserved architecture/security;
- complete user outcome;
- targeted runtime proof;
- independent criticism/review when risk warrants;
- no hidden cost;
- compact durable knowledge;
- observable outcome after release/pilot;
- fewer Founder interventions next time.

## External patterns adapted, not adopted wholesale

This standard is intentionally compatible with ideas seen in:
- AI-Driven Development Lifecycle (AI-DLC);
- Spec-Driven Development;
- agent harness/context engineering;
- trace/eval-driven agent development;
- DORA AI-assisted delivery capabilities;
- OWASP agent control/security;
- NIST SSDF / DevSecOps principles;
- SLSA-style provenance.

TrustWeave should borrow proven principles while keeping its own simpler operating model.
