# TrustWeave — NEXT SESSION: Mission 3 Shared Component / CSS Architecture

## Entry decision
Mission 2 is intentionally paused/concluded for now. Do **not** wait for the entire historical regression suite to become green before starting this mission.

Preserve Mission-2 evidence and avoid broad QA reruns during Mission 3. Use targeted validation for changed shared components and their consumers. Current launch focus remains only:
- `housing-society`
- `family-association`

Use the accompanying Mission-3 handoff FULL ZIP as the source of truth.

## Mission objective
Formalize the architecture already emerging in TrustWeave so reusable UI, CSS, interaction patterns and business/use-case behavior are implemented once and verticals compose them instead of copying them.

Target architecture:

```text
Platform
  ↓
Vertical plugins
  ↓
Reusable business / use-case components
  ↓
Technical UI components
  ↓
Design tokens / primitives / common CSS
```

This is an architecture/refactoring mission, not a feature-expansion mission.

## Product priorities that must remain protected
The current showcase product focus is:
1. Residential / Housing Society (`housing-society`)
2. Family Community / Cultural Association (`family-association`)

Protect their current working behavior and polish first. Other verticals remain in the codebase and global registries but are not the immediate launch-certification target.

Permanent UX rule: avoid endless peer-section stacking. Prefer progressive disclosure through tabs, selectors, card grids, accordions, submenus, master/detail or contextual drill-down.

## Core work
### 1. Inventory duplication before refactoring
Create a practical inventory of repeated:
- JSX/layout patterns
- CSS and responsive rules
- forms and async states
- admin/workspace shells
- cards, empty/error/loading states
- directory/member presentation
- posts/media
- funds/transactions
- voting/elections
- activities/timeline
- governance patterns
- notices/complaints/workflows

Prioritize duplication shared by Housing Society and Family Community, then shared Network OS infrastructure. Do not refactor merely because two files look similar; identify stable behavioral contracts first.

### 2. Establish technical UI primitives
Examples:
- responsive section/workspace shell
- card/grid primitives
- progressive section selector
- modal/drawer/sheet
- form field/action rows
- async loading/success/error state
- empty state
- metric/summary card
- media uploader/control
- list/detail row
- admin workspace/header/action pattern

Each primitive should own its base styling contract. Avoid leaking vertical-specific CSS into generic primitives.

### 3. Establish reusable business/use-case components
Candidates include:
- posts / broadcast feed
- shared media lifecycle
- funds and transactions
- elections / voting
- activities / timeline
- directory/member cards
- role/member management
- governance summaries
- admin workspace composition
- notification/preferences surfaces

Prefer configuration/adapters/slots for vertical-specific vocabulary and domain behavior rather than copied components.

### 4. CSS architecture
Move toward:

```text
common tokens / primitives
→ shared technical component CSS
→ shared business component CSS
→ vertical-specific additive overrides
```

Vertical CSS should express actual domain identity, not duplicate generic spacing/layout/control styling.

Do not perform a giant CSS rewrite. Refactor in coherent slices with validation after each slice.

### 5. Component contract documentation
Document:
- purpose
- required props/contracts
- supported variants
- vertical adapter points
- CSS ownership
- accessibility expectations
- consumers
- validation/gates

Evaluate Storybook only if it materially helps isolated component and business-scenario development without destabilizing the build. Do not introduce it by default.

### 6. Validation strategy
Mission 2 stays paused. For every Mission-3 slice:
- run static syntax/type/source gates relevant to the touched area;
- run targeted Housing + Family Community checks for shared components they consume;
- keep global catalogs intact;
- do not silently suppress runtime/API errors;
- do not trigger the full historical all-vertical regression unless explicitly requested.

A generic component change should eventually have a source gate proving its intended consumers still satisfy the contract.

## Recommended execution order
### M3-A — Architecture inventory and boundaries
Map duplicate components/CSS/use cases, identify highest-value extraction candidates, and define ownership rules. Produce a short architecture decision artifact before major moves.

### M3-B — Shared technical primitives
Extract low-risk structural primitives first. Keep visual output materially unchanged.

### M3-C — Shared business components
Start with the most duplicated/high-value patterns between Housing and Family Community.

### M3-D — Vertical CSS normalization
Remove duplicated generic styling from vertical stylesheets and make vertical layers additive.

### M3-E — Contract/gate/documentation closure
Add targeted source/runtime gates, update component/use-case documentation, and record migration guidance for future verticals.

Proceed sequentially. Do not turn Mission 3 into one huge refactor.

## Non-goals
- No vertical lazy-loading / plugin-bundle refactor yet — that is Mission 4.
- No historical SQL migration rewrites.
- No broad new product features.
- No deep intelligence/RAG expansion.
- No re-opening full Mission-2 regression unless explicitly requested.
- No removal of existing verticals from global registries merely because current launch focus is two verticals.

## Documentation governance
Mission 3 is substantial architecture work. Keep living artifacts updated after meaningful slices (or at least every 3–4 slices):
- `MISSION-STATUS.md`
- `CURRENT-STATE.md`
- `ROADMAP.md`
- `TRUSTWEAVE-MISSION-JOURNEY.md`
- `USER-EXPERIENCE-HANDBOOK.md`
- `CTO-PRODUCT-CAPABILITY-BOOK.md`
- `CEO-PRODUCT-BRIEF.md`
- `PRODUCT-CAPABILITY-CATALOG.md`
- relevant apply/verification notes
- public/evolution artifacts where architecture changes materially affect product presentation

Preserve historical evidence in archive/mission docs rather than cluttering root documentation.

## Mission 3 exit condition
Mission 3 is complete when:
- Housing and Family Community materially compose shared technical/business components rather than duplicate them;
- common UI/CSS changes propagate through defined shared contracts;
- vertical CSS is primarily additive/domain-specific;
- component ownership and extension points are documented;
- targeted validation proves current launch verticals remain stable;
- the architecture is ready for Mission 4 plugin/lazy-load work without another duplication cleanup first.
