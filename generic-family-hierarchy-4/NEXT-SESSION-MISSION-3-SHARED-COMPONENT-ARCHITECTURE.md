# TrustWeave — NEXT SESSION: Mission 3 Shared Component / CSS Architecture

## Entry gate
Do not begin the architectural refactor until Mission 2 has been executed against approved staging and the user-regression suite is green or every remaining failure is explicitly understood and accepted.

Use the latest Mission-2 FULL ZIP as the only source of truth.

## Objective
Formalize the architecture already emerging in the product so reusable UI/technical/business behavior is implemented once and verticals compose it rather than copying UI/CSS/logic.

Target layers:

```text
Platform
  ↓
Vertical plugins
  ↓
Reusable business/use-case components
  ↓
Technical UI components
  ↓
Design tokens / primitives / common CSS
```

## Core work
1. Inventory duplicated JSX/CSS/use-case logic across Family, Family Community, Housing and shared Network OS.
2. Define technical primitives (responsive sections, workspace/card grid, modal/drawer, forms, async state, empty/error state, media control, etc.) with self-owned CSS contracts.
3. Define reusable business components (posts, funds, voting, activities, media, directory/member cards, admin workspaces, etc.) with vertical configuration/adapters.
4. Make vertical CSS additive: shared primitive/business CSS first, vertical overrides only for true domain identity.
5. Keep the permanent progressive-disclosure rule: no endless peer-section stacking; use tabs/selectors, card grids, accordions, submenus or master/detail patterns.
6. Add component/use-case documentation. Evaluate Storybook for isolated components and reusable business scenarios; integrate it only if it improves maintainability without destabilizing production build.
7. Strengthen source/regression gates so a change to a generic component is automatically certified across consuming verticals.

## Non-goals
- Do not begin vertical lazy-loading/plugin bundle refactor yet; that is Mission 4.
- Do not rewrite historical SQL migrations.
- Do not add unrelated product features.

## Exit condition
Verticals compose shared components with materially less duplicated JSX/CSS/business glue, common visual behavior changes propagate through shared contracts, and the full Mission-2 regression suite remains green.
