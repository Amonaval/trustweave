# TrustWeave — AI Start Here

**Current mission:** Mission 003 — Agentic Company & Engineering OS  
**Active execution record:** `missions/mission-003/mission.json`

## Read order

1. `PRODUCT-CONSTITUTION.md` — product priorities and non-negotiables.
2. `ARCHITECTURE-CONSTITUTION.md` — architecture vocabulary, boundaries and ADR triggers.
3. `AGENTIC-COMPANY-OS.md` — agent roles, authority, repair loop and human gates.
4. `MISSION-LIFECYCLE.md` — state machine, risk classes and evidence contract.
5. `DOCUMENTATION-GOVERNANCE.md` — authority and source-of-truth rules.
6. `CURRENT-STATE.md` + `MISSION-STATUS.md` + `ROADMAP.md` — current descriptive truth and sequencing.
7. Active mission folder under `missions/`.
8. Only then inspect source, tests, migrations and historical evidence needed for the task.

## Machine-operable governance

- `governance/architecture-policy.json`
- `governance/company-os.json`
- `governance/documentation-policy.json`
- `governance/quality-policy.json`
- `governance/schemas/`

These JSON files are executable projections. They never override the constitutions that authorize them.

## Working doctrine

- Determine authority before editing.
- Bound a mission before implementation.
- Reuse existing product/kernel/capability contracts before creating new abstractions.
- Preserve vertical semantics and tenant/privacy boundaries.
- Run deterministic gates first; use reasoning for ambiguity, review and diagnosis.
- Classify failures before repair; do not patch blindly through dependency chains.
- Never represent source/static proof as runtime proof.
- Historical migrations are immutable.
- Keep founder involvement to explicit approval gates and exceptional decisions.
- Close a mission with commit-bound evidence and synchronized canonical truth.

## Historical context

Closed mission notes, old handoffs, apply notes and session-era bootstrap diaries are evidence, not current authority. Use `ARCHIVE-INDEX.md`, `archive/`, and `missions/mission-003/evidence/` only when current work requires their history.
