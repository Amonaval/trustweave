# TrustWeave — M3-A Architecture Inventory & Boundaries

**Mission:** Mission 3 — Shared Component / CSS Architecture  
**Slice:** M3-A — architecture inventory and boundaries  
**Date:** 2026-09-16  
**Status:** COMPLETE — inventory/decision only; no runtime refactor in this slice

**2026-09-16 continuation:** The autonomous-company program did not supersede this product-architecture direction. M3-B6 completed only the canonical progressive-section selector slice. Workspace shells, async resource/action lifecycle, genuinely shared business/use-case components, incremental CSS ownership, and contract/scenario documentation remain protected backlog. Reliability is being established first for `housing-society` and `family-association` so later convergence can be verified safely.

## 1. Decision summary

TrustWeave already has a meaningful shared Network OS UI layer. Mission 3 should therefore be a **convergence mission**, not a rewrite.

The launch-critical duplication is concentrated in four places:

1. Housing-specific copies of interaction shells that already have shared equivalents.
2. Repeated async `load/run/busy/notify/reload` lifecycle code across both launch verticals and shared use-case panels.
3. Repeated generic layout/CSS rules inside vertical-specific selectors.
4. Vertical business panels that share presentation patterns but **do not share the same domain contract**.

The architectural rule for Mission 3 is:

> Share stable interaction and presentation contracts first. Share business behavior only when the domain semantics are genuinely the same. Keep vertical vocabulary, authorization rules and workflow semantics in vertical adapters/components.

No feature expansion, migration rewrite, plugin lazy-loading work, or broad Mission-2 regression is part of this decision.

---

## 2. Current architecture observed

The source already contains the intended layers, but ownership is inconsistent:

```text
Platform/app shell
  -> TemplateNetworkApp / NetworkApp / registries
  -> shared Network OS components
  -> vertical-specific launch experiences
  -> remotes/capabilities
  -> one large global CSS file
```

Existing shared foundations are substantial and should be preserved:

- `components/shared/NetworkUi.tsx`
  - `NetworkMetric`
  - `NetworkSectionHead`
  - `NetworkEmpty`
  - `InitialsAvatar`
- `components/shared/ResponsiveSectionTabs.tsx`
- `components/shared/NetworkFundsPanel.tsx`
- `components/shared/NetworkVotingPanel.tsx`
- `components/shared/NetworkPostsPanel.tsx`
- `components/shared/NetworkActivityHub.tsx`
- `components/shared/MediaManagementPanel.tsx`
- shared directory/explorer/admin/guide/notification surfaces

This means M3-B should mostly **make launch verticals compose the existing/shared contracts consistently**, then add only the missing primitives.

---

## 3. Quantitative inventory

### 3.1 Launch-critical component concentration

Approximate current source sizes:

| Component | Approx. size | Observation |
|---|---:|---|
| `components/TemplateNetworkApp.tsx` | 88 KB | Central productized composition; many conditional surfaces |
| `components/HousingSocietyHome.tsx` | 20 KB | Vertical-specific flagship dashboard |
| `components/HousingSocietyOperationsPanel.tsx` | 24 KB | Notices, complaints, vendors, amenities |
| `components/HousingSocietyFinancePanel.tsx` | 17 KB | Maintenance billing + society funds |
| `components/HousingSocietyGovernancePanel.tsx` | 17 KB | Committee terms, meetings, actions, resolutions |
| `components/HousingSocietySecurityPanel.tsx` | 17 KB | Visitors, staff, assets, compliance |
| `components/FamilyAssociationAdminPanel.tsx` | 16 KB | Membership year, family membership, roles, finance |
| `components/shared/NetworkFundsPanel.tsx` | 12 KB | Shared Community funds/collections |
| `components/shared/NetworkVotingPanel.tsx` | 14 KB | Shared elections/polls/secret ballots |
| `app/globals.css` | ~469 KB / 1,486 physical lines | Single accumulated global stylesheet |

The physical CSS line count understates density because many rules are compressed onto single lines.

### 3.2 Existing shared primitive adoption

Current consumer counts in `components/`:

- `NetworkSectionHead`: 25 files
- `NetworkEmpty`: 19 files
- `NetworkMetric`: 14 files
- `ResponsiveSectionTabs`: 12 files

This is strong evidence that these are established contracts, not experimental helpers.

### 3.3 CSS duplication evidence

Exact/near-exact generic declarations currently exist under different semantic selectors. Examples:

- Two-column `display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:14px` appears in:
  - `.association-dashboard-grid`
  - `.fca-admin-grid`
  - `.network-funds-admin-grid`
  - `.network-voting-admin-grid`
  - `.progressive-card-grid`
- `display:grid; gap:14px; min-width:0` appears in:
  - `.hs-manage-workspace`
  - `.hs-manage-content`
  - `.section-workspace`
- active tab styling is duplicated between:
  - `.hs-section-tab-buttons button.active`
  - `.responsive-section-tab-buttons button.active`
- mobile section-select label styling is duplicated between:
  - `.hs-section-tab-select span`
  - `.responsive-section-tab-select > span`

These are strong CSS-normalization candidates because the declarations describe layout/control mechanics rather than vertical identity.

---

## 4. High-value duplication inventory

### A. Progressive section navigation — **P0 / first extraction**

**Current state**

- `components/shared/ResponsiveSectionTabs.tsx` is already the generic contract.
- `components/shared/HousingSectionTabs.tsx` implements the same desktop tabs + mobile select pattern with fewer capabilities.
- `HousingSectionTabs` is consumed by Housing Finance, Governance and Security.
- Family Community and shared panels already use `ResponsiveSectionTabs`.

**Stable contract**

```text
options + active id + onChange + accessible label
-> desktop tablist
-> mobile select
-> optional icon / badge / description
```

**Decision**

`ResponsiveSectionTabs` is canonical. `HousingSectionTabs` should be retired in M3-B after its consumers are migrated.

**Why first**

- behavior is already proven in both launch products;
- generic component is a strict superset of the Housing version;
- CSS duplication is obvious;
- visual behavior can remain materially unchanged;
- limited blast radius.

---

### B. Workspace/admin shell — **P0/P1**

**Current state**

Three closely related workspace contracts exist:

1. Generic `section-workspace` + `ResponsiveSectionTabs` + `section-workspace-stage`.
2. `FamilyAssociationAdminPanel`, already using the generic pattern.
3. `HousingSocietyManageWorkspace`, with bespoke `hs-manage-tabs`, `hs-manage-select`, `hs-manage-content`.

Housing adds one meaningful variant: sticky admin navigation.

**Stable contract**

```text
header
+ section navigation
+ active stage
+ optional sticky navigation
+ role/admin context
```

**Decision**

Create one technical `SectionWorkspace` / `AdminWorkspace` contract built on `ResponsiveSectionTabs`. Sticky behavior is a variant, not a separate Housing component architecture.

Do **not** remove Housing-specific labels/icons/content composition.

---

### C. Async panel lifecycle — **P0/P1**

The following repeated pattern occurs across Housing, Family Community and shared panels:

```text
load snapshot
-> catch and notify
run mutation
-> set busy
-> try mutation
-> notify success
-> reload snapshot
-> catch and notify actual error
-> finally clear busy
```

Observed in:

- Housing Core
- Housing Operations
- Housing Finance
- Housing Governance
- Housing Security
- Housing Pilot
- Family Association Admin
- shared Funds
- shared Voting
- shared Media Management

**Stable contract**

The lifecycle is generic; the remote operation and messages are domain-specific.

**Decision**

Introduce a small shared hook/controller in M3-B, likely two contracts rather than one oversized hook:

- resource load state (`idle/loading/ready/error` + reload)
- mutation/action state (`busy` + run + success/error callbacks)

Requirements:

- never swallow runtime/API errors;
- preserve original error messages when available;
- allow demo/read-only short-circuit outside or through an explicit guard;
- support reload after mutation;
- avoid hidden global state.

This is more valuable than creating many decorative wrapper components.

---

### D. Loading / empty / error presentation — **P1**

`NetworkEmpty` exists and is widely adopted, but loading and error presentation remain inconsistent.

Examples include custom Housing dashboard loading, null-snapshot empty handling and notify-only load failures.

**Decision**

Add one small technical state primitive only after the async lifecycle contract is established, e.g. `NetworkAsyncState` / `PanelState`.

It should support:

- loading
- load error with visible retry where appropriate
- empty
- read-only/demo note where needed

Do not force every panel to render the same visual; allow children/slots for domain-specific empty copy.

---

### E. Form scaffolding — **P1/P2**

The CSS contract is already shared:

- `.form-grid`
- `.field`
- `.text-input`
- `.select`
- `.form-actions`
- `.form-help`

But JSX repeats labels/help/error/action structure across Family Community, Housing and shared panels.

**Decision**

Do not componentize every input just to reduce JSX. Extract only accessibility-bearing contracts that add value:

- `FormField` / field label + help + error + required state
- `FormActions` when consistent busy/disabled semantics are useful
- `MediaUploadField` separately because it has real media behavior

Plain layout grids should normally remain CSS primitives.

---

### F. Card/grid/list presentation — **P1/P2**

Repeated mechanics exist for:

- 2-column admin/card grids
- 3-column summary grids
- section headers with right-side actions
- list/detail rows with icon + main text + metadata + trailing state/action
- status pills/badges

**Decision**

Prefer CSS/layout primitives first. Introduce React components only where interaction/accessibility or a stable semantic contract exists.

Recommended technical contracts:

- `SectionCardHeader`
- `StatusListRow` / `ActionListRow`
- `SummaryGrid` only if a real prop contract reduces repeated markup

Avoid a generic `Card` component that merely renders `<section className="card">`.

---

### G. Housing demo fixtures — **P1, vertical-owned**

Housing flagship home and Housing panels contain duplicated demo snapshots for the same concepts:

- notices/complaints/vendors/amenities/bookings
- finance cycles/funds/summary
- committee terms/actions/resolutions
- visitors/assets/compliance

The values are similar but not always identical, which creates drift risk between the home summary and detailed panels.

**Decision**

Centralize these as **Housing-owned fixtures**, not shared Network OS fixtures, for example:

`verticals/housing-society/demo/fixtures.ts`

This is an ownership cleanup, not a cross-vertical abstraction.

Family Community demo/seed contracts should remain independently owned unless the same actual domain contract is used.

---

## 5. Shared business/use-case boundaries

Mission 3 must distinguish “same visual shape” from “same business behavior.”

### 5.1 Funds / transactions

**Already shared:** `NetworkFundsPanel` for Community pooled funds and collections.

**Housing:** maintenance cycles, unit bills, charge heads, payments, arrears and society fund balances.

**Decision:** do not merge these into one business panel.

Potential shared lower-level contracts:

- money/amount formatting
- fund balance summary card
- transaction/ledger row
- finance metric grid
- receipt/status presentation

Business adapters remain separate:

```text
Community funds adapter -> shared presentation primitives
Housing maintenance adapter -> shared presentation primitives
```

### 5.2 Voting / elections / resolutions

**Already shared:** `NetworkVotingPanel` for elections/polls/secret ballots and used by both launch verticals where applicable.

**Housing Governance:** committee resolutions/approval workflow is a separate domain contract.

**Decision:** keep them separate. Reuse only status/result/count/presentation primitives where stable.

Do not force committee resolutions into election semantics.

### 5.3 Posts / broadcasts vs notices / complaints

**Already shared:** `NetworkPostsPanel` + shared activity model for Community posts/broadcasts.

**Housing:** notices and complaints carry dedicated operational semantics, priority, routing, assignment/status and complaint-specific media authorization.

**Decision:** keep workflows separate. Share technical behavior:

- composer shell
- attachment control
- mention extraction/routing helper where contract is identical
- status/list row presentation
- busy/error handling

### 5.4 Media

**Already shared:** `MediaManagementPanel` and `network_media_assets` lifecycle.

**Duplication remaining:** upload input/compression/bind/remove-on-failure flows are repeated in posts, activity and Housing complaint paths.

**Decision:** create a technical `MediaAttachmentField` and/or a small `useMediaAttachment` workflow around existing storage presets. Domain authorization stays in the preset/remote contract.

### 5.5 Activity / timeline

`NetworkActivityHub` is already the shared interaction surface. Association Home and Housing Home have compact read-only summaries.

**Decision:** retain domain-specific flagship summaries. Consider a shared compact timeline/list presentation only if a second consumer proves the same row contract.

### 5.6 Directory / member presentation

Core directory/explorer behavior is already shared by `TemplateNetworkApp`. Association/Housing home summaries are intentionally branded and domain-specific.

**Decision:** do not flatten flagship homes into one generic dashboard. Share avatars/rows/metrics only where it preserves each vertical's identity.

### 5.7 Notification/preferences

Already shared and mature enough. No M3-C priority unless a concrete duplicated consumer contract is discovered while refactoring.

---

## 6. CSS ownership decision

### Current problem

`app/globals.css` combines:

- tokens/base rules
- historical mission rules
- shared technical controls
- shared business/use-case styles
- vertical signature styles
- vertical operational layout rules
- responsive behavior

The problem is not simply file size. The architectural problem is that generic mechanics are sometimes owned by vertical selectors.

### Target ownership

```text
common tokens / primitives
  -> shared technical component CSS
  -> shared business/use-case CSS
  -> vertical-specific additive CSS
```

### What belongs in vertical CSS

Keep:

- brand colors/palette
- vertical hero/signature composition
- domain-specific emphasis
- truly domain-specific information layouts
- additive visual variants

Move/normalize away from vertical CSS:

- generic tabs/selectors
- generic workspace spacing
- common grids
- generic form/control sizing
- generic list/detail row mechanics
- common loading/empty/error presentation
- generic responsive switching rules

### M3-D strategy

Do not split the 469 KB stylesheet in one operation.

1. Remove exact duplicate selector contracts while M3-B components migrate.
2. Establish named shared CSS ownership blocks.
3. Move only touched stable blocks into dedicated files if the build remains stable.
4. Keep vertical overrides additive and import-order explicit.

A physical multi-file split is desirable only after selector ownership is clear; it is not the first step.

---

## 7. Component ownership rules

### Technical shared components own

- accessibility semantics
- responsive interaction mechanics
- base layout contract
- loading/empty/error interaction
- base CSS selectors/tokens
- generic slots/variants

They must not know `housing-society` or `family-association` business vocabulary.

### Shared business/use-case components own

- a stable cross-vertical workflow contract
- normalized data/adapter input
- shared interaction behavior
- business-level presentation that is genuinely common

They may accept vertical vocabulary/configuration, but should not branch repeatedly on vertical kind.

### Vertical components/adapters own

- domain vocabulary
- domain authorization/role rules
- remote/RPC choice
- workflow-specific validation
- domain-specific status transitions
- flagship identity/hero composition
- domain-specific demo fixtures

### Platform/app shell owns

- network/vertical selection
- surface registration/composition
- role-aware routing/navigation
- launch-control exposure
- common active-network context

Mission 3 should not turn this into Mission 4 bundle/plugin work.

---

## 8. Proposed physical boundaries

No mass file move is required in M3-A. As files are touched, converge toward:

```text
components/shared/
  ui/                 # technical primitives
  workspaces/         # section/admin shells
  use-cases/          # truly shared business surfaces

verticals/
  housing-society/
    ui/                # Housing-specific UI/adapters
    demo/              # Housing demo fixtures
  family-association/
    ui/                # FCA-specific UI/adapters

styles/                # introduced incrementally, not by big-bang rewrite
  tokens.css
  ui.css
  use-cases.css
  verticals/
    housing-society.css
    family-association.css
```

Important: existing imports should be moved only when a component is already being refactored. Avoid a repository-wide path churn mission.

---

## 9. M3-B recommended execution slices

### M3-B1 — Progressive selector convergence — **first**

- migrate Housing Finance/Governance/Security from `HousingSectionTabs` to `ResponsiveSectionTabs`;
- preserve labels/current active states;
- remove `HousingSectionTabs` after zero consumers;
- remove duplicate `hs-section-tab-*` CSS;
- targeted source gates + Housing focused checks.

### M3-B2 — Shared workspace shell

- introduce technical `SectionWorkspace` / `AdminWorkspace`;
- migrate `HousingSocietyManageWorkspace` to it using a sticky-navigation variant;
- migrate/confirm Family Association Admin generic usage;
- preserve progressive-disclosure UX.

### M3-B3 — Async resource/action lifecycle

- introduce small load/action hooks/controller;
- migrate one low-risk shared panel first, then one Housing panel and FCA Admin;
- validate real error propagation and reload behavior before broader adoption.

### M3-B4 — Async/empty/loading presentation

- add a shared panel state primitive only after B3 settles the state contract;
- remove ad-hoc loading/empty duplicates where behavior is equivalent.

### M3-B5 — Shared media field/control

- extract common attachment field/preset/error-cleanup behavior;
- migrate Network Posts and Housing complaint attachment paths carefully;
- retain complaint-specific authorization and binding entity type.

### M3-B6 — Generic layout CSS normalization

- consolidate exact duplicate two/three-column grid and workspace rules;
- do not touch flagship branding blocks yet.

---

## 10. M3-C candidate order

After technical primitives stabilize:

1. media attachment/use-case integration;
2. shared finance presentation primitives beneath separate Community/Housing adapters;
3. shared governance/result/status presentation beneath separate elections/resolution workflows;
4. member/role administration presentation where actual contracts converge;
5. compact timeline/list rows only when multiple consumers match.

Do not make “one universal panel” for funds, governance or operations.

---

## 11. Validation/gate design

Mission 3 should add targeted architecture gates over time rather than re-running all historical verticals.

Recommended `validate:mission3` contract eventually checks:

- `HousingSectionTabs` has no consumers / is removed after B1;
- launch-critical progressive sections use the canonical selector/workspace contracts;
- shared UI components contain no Housing/FCA-specific business branching;
- vertical registries remain intact;
- no historical migrations are modified;
- current `validate:ux-progressive` remains green;
- existing Housing + FCA source gates remain green for touched consumers;
- TypeScript/static syntax is green when dependencies permit.

Runtime validation remains targeted to changed Housing + Family Community surfaces.

---

## 12. Explicit non-extractions

The following should remain vertical-specific unless later evidence changes the contract:

- Association flagship hero/emblem/home storytelling.
- Housing Chairman/resident flagship home.
- Housing complaint workflow.
- Housing maintenance billing model.
- Housing committee resolution workflow.
- FCA annual membership/renewal policy model.
- FCA household representative semantics.
- Housing security/visitor/compliance business workflows.
- vertical palettes and branded signature CSS.

These differences are product value, not architecture debt.

---

## 13. Storybook decision

**Deferred.**

The repository already has source gates, targeted Playwright flows and deterministic showcase data. Introducing Storybook during the first convergence slices would add build/tooling surface before the component contracts are stable.

Re-evaluate during M3-E only if isolated scenario development materially improves validation for the newly stabilized shared contracts.

---

## 14. M3-A exit decision

M3-A is complete because:

- duplication has been mapped around the two launch-critical verticals;
- existing shared contracts vs missing technical contracts are separated;
- cross-vertical business boundaries are explicit;
- CSS ownership rules are defined;
- non-extractions are documented;
- the first low-risk M3-B slice is clear.

### Next action

Proceed with **M3-B1 — Progressive selector convergence**. Keep visual output materially unchanged and validate only the affected Housing + Family Community/shared contracts.
