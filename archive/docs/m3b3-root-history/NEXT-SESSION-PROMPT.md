# New Session Prompt — TrustWeave Mission 3

We are starting a fresh session for **TrustWeave / Generic Network OS — Mission 3: Shared Component / CSS Architecture**.

I am attaching the latest **Mission-3 Handoff FULL ZIP**. Treat that ZIP as the source of truth. Do not ask me to reconstruct earlier missions unless a specific artifact is genuinely missing.

## Current decision
Mission 2 dragged for a long time and is now intentionally **paused/concluded for now**. It is not necessary to make the entire historical Playwright suite green before beginning Mission 3. Preserve its evidence, fixes and QA tooling, but do not restart broad regression work unless I explicitly ask.

Current launch/showcase focus is only:
- `housing-society` (Residential / Housing Society)
- `family-association` (Family Community / Cultural Association)

Other verticals remain in the platform/global registries but are not the immediate launch-certification focus.

## Latest important state
- Source tree contains immutable Supabase migrations through **121**.
- Migrations 119–121 consolidate recent Housing complaint-contract drift repairs.
- Latest Housing UX follow-up makes vendor service-desk issues navigable and makes saved committee terms/roles/meetings visible to admins.
- Mission-2 regression scope was narrowed to Housing + Family Community.
- Login/auth QA was deliberately kept simple; do not overengineer it again.
- Do not rewrite historical migrations.
- Documentation is a living release requirement.

## Mission 3 objective
Formalize this architecture:

Platform → vertical plugins → reusable business/use-case components → technical UI components → design tokens/primitives/common CSS.

I want shared behavior implemented once and verticals to compose it instead of copying JSX, CSS and business glue.

Start slowly and thoughtfully. First inspect the codebase and produce **M3-A: duplication/component/CSS architecture inventory + proposed boundaries**. Identify high-value extraction candidates, especially duplicated patterns between Housing Society and Family Community. Do not immediately perform a giant refactor.

Then proceed sequentially:
1. M3-A architecture inventory/boundaries
2. M3-B shared technical primitives
3. M3-C shared business/use-case components
4. M3-D vertical CSS normalization
5. M3-E contract/gate/documentation closure

Permanent UX rule: avoid endless peer-section stacking; preserve progressive disclosure.

Use targeted validation for affected Housing + Family Community consumers after each slice. Do not trigger broad all-vertical regression unless I explicitly request it.

Mission 4 (later) will handle plugin/lazy-load/bundle architecture, so do not mix that into Mission 3.

Before making changes, read:
- `NEXT-SESSION-MISSION-3-SHARED-COMPONENT-ARCHITECTURE.md`
- `MISSION-2-CLOSURE-HANDOFF.md`
- `MISSION-STATUS.md`
- `CURRENT-STATE.md`
- `ROADMAP.md`
- `PRODUCT-CAPABILITY-CATALOG.md`
- `USER-EXPERIENCE-HANDBOOK.md`
- `CTO-PRODUCT-CAPABILITY-BOOK.md`

Then begin M3-A.
