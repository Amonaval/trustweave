# TrustWeave — AI Start Here

**Current mission:** M3-C — Autonomous Company Runtime / Founder Spectator Mode  
**Active execution record:** `missions/mission-003/m3-c/mission.json`

## Read order

1. `PRODUCT-CONSTITUTION.md` — product priorities and non-negotiables.
2. `ARCHITECTURE-CONSTITUTION.md` — architecture vocabulary, boundaries and ADR triggers.
3. `AGENTIC-COMPANY-OS.md` — agent roles, authority, repair loop and human gates.
4. `MISSION-LIFECYCLE.md` — state machine, risk classes and evidence contract.
5. `governance/autonomy-policy.json` — Founder Spectator Mode, executive council, decision classes and autonomy SLO.
6. `governance/DOCUMENTATION-GOVERNANCE.md` — authority and source-of-truth rules.
7. `CURRENT-STATE.md` + `MISSION-STATUS.md` + `ROADMAP.md` — current descriptive truth and sequencing.
8. Active mission contract from `missions/registry.json`.
9. Only then inspect source, tests, migrations and historical evidence needed for the task.

## Machine-operable governance

- `governance/architecture-policy.json`
- `governance/company-os.json`
- `governance/documentation-policy.json`
- `governance/quality-policy.json`
- `governance/autonomy-policy.json`
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

Closed mission notes, old handoffs, apply notes and session-era bootstrap diaries are evidence, not current authority. Use `history/root-legacy/`, `archive/`, and mission evidence only when current work requires history. Root Markdown is capped at ten files by the documentation gate.
