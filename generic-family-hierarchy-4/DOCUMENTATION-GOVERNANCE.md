# TrustWeave Documentation Governance

**Status:** PROPOSED AUTHORITY — M3-B strategic reset

## 1. Goal

Documentation must let a human or agent answer:
1. What rules govern this work?
2. What is true in the current source/runtime?
3. What mission is active?
4. What evidence proves a claim?
5. Which document wins when two statements conflict?

The goal is fewer authoritative documents, not more documentation.

## 2. Two authority axes

TrustWeave separates **normative authority** from **descriptive truth**.

### Normative authority — what is allowed / intended
Highest to lowest:
1. Current explicit founder/architect decision.
2. `PRODUCT-CONSTITUTION.md` + `ARCHITECTURE-CONSTITUTION.md`.
3. Human-approved ADRs.
4. Active mission charter/acceptance contract.
5. `MISSION-LIFECYCLE.md` + `AGENTIC-COMPANY-OS.md` + durable development rules.
6. Mission implementation plan.
7. Agent-local decisions/notes.

If the two constitutions conflict materially, agents must not invent precedence; escalate to the founder and record the resolution.

### Descriptive authority — what actually exists / passed
Highest to lowest:
1. Observed runtime/database/environment evidence tied to the target and commit.
2. Current source code + chronological migrations.
3. Generated test/CI/evidence artifacts tied to commit SHA.
4. `CURRENT-STATE.md`.
5. `MISSION-STATUS.md` / `ROADMAP.md`.
6. Capability/UX/guide narrative documents.
7. Historical mission notes, release manifests, old prompts and chat handoffs.

Code can prove that an implementation differs from a plan. Code does **not** silently supersede a constitution; that is an architecture defect until explicitly approved.

## 3. Canonical living set

Keep the root operating set intentionally small:

- `AI-START-HERE.md` — short bootstrap/read order only.
- `PRODUCT-CONSTITUTION.md` — product priorities/invariants.
- `ARCHITECTURE-CONSTITUTION.md` — architecture boundaries/invariants.
- `AGENTIC-COMPANY-OS.md` — agent operating model.
- `MISSION-LIFECYCLE.md` — state machine/mission execution.
- `CURRENT-STATE.md` — concise current operational truth.
- `MISSION-STATUS.md` — active/closed mission status.
- `ROADMAP.md` — active sequence and deliberate deferrals.
- `DOCUMENTATION-GOVERNANCE.md` — this authority model.
- `DEVELOPMENT-RULES.md` — implementation/safety rules that are not constitution-level.

Narrative product docs live once under `docs/product/`. Do not maintain root mirrors and `docs/product` copies that can diverge.

## 4. Mission-local documents

A material active mission may have one folder/record containing:
- charter/acceptance;
- plan/architecture decision if needed;
- status;
- evidence manifest;
- decisions/exceptions.

Do not create separate apply notes, handoffs, manifests and checklists when one mission record plus machine evidence can represent the same truth.

## 5. Historical/evidence documents

Historical mission docs, release manifests, affected-file lists, superseded prompts, apply notes and old runtime checklists are evidence. They belong under `archive/` after closure unless an accepted gate still references the path.

Historical artifacts never override current normative or descriptive authority.

## 6. Generated documents

Machine-generated reports belong in evidence/result directories and must include/derive:
- mission ID;
- candidate commit SHA;
- environment class;
- generation timestamp.

Generated evidence should not be manually edited into becoming product truth.

## 7. Single-copy rule

A living document has one canonical path.

Mirrors are allowed only when generated automatically and byte-identical, with the canonical source named in the generated header. A manually maintained mirror is prohibited.

Current repository drift to remove in M3-B3 includes divergent root/`docs/product` copies and stale "latest mission" diary sections in bootstrap/index documents.

## 8. Mission closure documentation

At closure, update only durable truth that changed:
- current state;
- mission status;
- roadmap when sequencing changed;
- architecture/product constitution or ADR only when a governing decision changed;
- UX/capability narrative only when user/capability behavior changed;
- mission journey/history as historical record.

Do not update nine documents merely to repeat the same status sentence.

## 9. Document drift gate

M3-B4 should add a deterministic check for:
- duplicate canonical basenames;
- divergent mirrors;
- root historical artifacts outside allow-list;
- multiple active mission declarations;
- stale `NEXT-SESSION-*` files in root after mission activation;
- canonical docs pointing to missing files;
- status terms outside approved vocabulary;
- mission closure claiming runtime proof without runtime evidence.

## 10. Current repository cleanup policy

Do not big-bang delete documentation in M3-B0.

M3-B3 will:
1. classify each current root artifact;
2. retain canonical operating docs;
3. move closed mission/apply/handoff evidence to archive;
4. choose one canonical copy for current product narratives;
5. replace stale bootstrap diaries with compact indexes;
6. update gate-referenced paths only with explicit compatibility checks.

## 11. Status vocabulary

Use:
- PLANNED
- ACTIVE
- IMPLEMENTED
- SOURCE-GATED
- RUNTIME-VERIFIED
- PILOT-VALIDATED
- RELEASED
- PAUSED
- SUPERSEDED

Additional qualifiers may describe blockers, but must not blur source vs runtime proof.
