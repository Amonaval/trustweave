# TrustWeave — Architecture Constitution

**Status:** BINDING — M3-B1/B2 accepted for execution  
**Effective scope:** TrustWeave / Generic Network OS  
**Predecessor evidence:** `missions/mission-003/M3-A-ARCHITECTURE-INVENTORY-AND-BOUNDARIES.md`  
**Change rule:** Material changes to this constitution require an ADR and founder/architect approval.

## 1. Purpose

This document governs architectural decisions. It does not describe every implementation detail.

The goal is a lean Network OS with strong reusable primitives, protected tenant/privacy boundaries, and vertical products that retain real domain semantics. Architecture exists to make product evolution safer and more autonomous, not to maximize abstraction.

## 2. Architectural vocabulary

### Platform kernel
The smallest domain-neutral foundation needed by every TrustWeave product:
- network identity and active-network context;
- account/network membership boundaries;
- vertical and capability registration/composition;
- common authorization and tenant-isolation contracts;
- shared app-shell/navigation contracts;
- durable API/command/query boundaries required across products;
- common lifecycle, observability and compatibility contracts.

The kernel must not contain Housing, Family, Association, Alumni or other vertical-specific business vocabulary.

### Capability
A reusable behavior with a stable contract that can be adopted by multiple verticals without changing its business meaning. A capability can include contracts, runtime/remote code, data ownership and optional shared UI.

Examples already present include participation, affiliation, launch activation, federation primitives and shared engagement capabilities.

### Vertical
A product/domain composition that owns:
- vocabulary and branded experience;
- domain-specific workflows and validation;
- domain-specific feature catalog/composition;
- domain adapters and vertical RPC/remote selection;
- vertical demo fixtures;
- domain-specific authorization requirements in addition to platform invariants.

A vertical may depend on the kernel and approved capabilities. One vertical must not depend directly on another vertical.

### Shared use-case
A user/business workflow reused across verticals only when the underlying semantics are genuinely the same, not merely because the screens look similar.

Examples: shared Network Voting can be common when election/poll semantics are the same. Housing committee resolutions remain a separate workflow.

### Technical shared component
A reusable interaction/presentation contract that owns accessibility, responsive mechanics, generic state and base layout. It may accept labels/configuration but must not decide domain business rules.

`ResponsiveSectionTabs` is the canonical example from M3-A.

### Domain adapter
A translation boundary between a vertical's domain model and a shared capability/use-case. It owns mapping, vocabulary, domain validation and remote selection. It must not weaken platform authorization or tenant isolation.

### Plugin
A runtime-loadable/installable extension with an explicit registration and compatibility contract. Current verticals are not automatically called plugins merely because they are modular. Plugin/lazy-loading architecture remains Mission 4 work until a demonstrated need justifies it.

## 3. Dependency direction

Permitted direction:

```text
app shell
  -> vertical composition
      -> domain adapters
          -> shared capabilities / shared use-cases
              -> platform kernel
                  -> infrastructure adapters
```

Technical UI may be consumed by all upper layers.

Forbidden:
- kernel/core importing a vertical;
- shared technical UI branching on a vertical kind for business behavior;
- vertical A importing vertical B business code;
- generic capabilities depending on a vertical-specific schema or vocabulary without an adapter;
- UI authorization used as the only enforcement boundary;
- browser code using service-role credentials;
- a new shared abstraction created only because markup looks similar.

## 4. Ownership rules

### Data ownership
Every table, RPC and durable storage namespace must have one owning domain: kernel, capability or vertical.

Shared data structures must represent a truly shared contract. Vertical-specific status machines, billing semantics, committee rules, complaint rules and membership policies remain vertical-owned.

Cross-owner reads/writes occur only through explicit contracts or reviewed database relationships.

### Authorization ownership
Authorization is enforced at server/RLS/RPC/storage access boundaries. UI visibility is explanatory UX, never the sole security boundary.

Shared capabilities define common permission contracts. Verticals may add stricter rules but may not weaken tenant isolation, privacy or security invariants.

### Migration ownership
- Deployment migrations remain chronological and append-only.
- Historical migrations are immutable after acceptance.
- A migration must declare/clearly imply its owning domain and dependencies.
- New migration logic must be replayable on a disposable database before production promotion when schema/security behavior changes.
- Reserved historical gaps remain reserved; agents must not renumber or reuse them merely for cosmetic continuity.
- Destructive or privilege-widening changes require explicit human approval.

### UI ownership
- shared technical UI: interaction/accessibility/responsiveness;
- shared use-case UI: genuinely common business workflow;
- vertical UI: domain vocabulary, flagship identity, domain workflow composition;
- vertical CSS: additive branding/domain information layouts;
- generic mechanical CSS: shared ownership.

`app/globals.css` is current technical debt, not a reason for a big-bang rewrite.

## 5. Command, query and event boundaries

TrustWeave does not adopt event sourcing or formal CQRS by default.

Use:
- **command** for governed state mutation;
- **query** for reads/projections;
- **event** only when a durable fact has multiple consumers, audit value, asynchronous propagation value, or a proven product requirement.

Do not introduce a queue, broker, event store or distributed service merely to satisfy this vocabulary.

## 6. Configuration vs code

Configuration may control:
- labels and localized copy;
- icons/themes;
- feature exposure/Launch Control;
- navigation composition;
- safe product settings.

Code/database policy owns:
- authorization;
- tenant isolation;
- business invariants;
- workflow state transitions;
- validation that protects correctness;
- destructive-operation safeguards.

A rule does not become configuration merely because several verticals have different values.

## 7. Architecture invariants

1. One account may participate in multiple governed networks without collapsing their private graphs.
2. Network data remains tenant/network scoped unless an explicit federated/public contract permits disclosure.
3. Federation/bridge/application scope never implies automatic child-graph disclosure.
4. Verticals preserve domain semantics; reuse must not flatten meaningful differences.
5. Shared technical contracts contain no vertical business rules.
6. Historical migrations are immutable.
7. Authorization is enforced server-side/RLS/RPC/storage-side.
8. A released capability is cumulative unless explicit removal/replacement is approved.
9. Source-green is not runtime-certified.
10. Launch-critical validation remains focused on Housing Society and Family Community unless scope is explicitly changed.
11. No microservices, Kubernetes, queue/broker, event sourcing, new graph database, or plugin framework without measured need and an ADR.
12. Errors must be surfaced/classified; no agent may suppress a real API/runtime failure to make a gate pass.

## 8. ADR policy

An ADR is required before:
- changing dependency direction or kernel boundaries;
- merging/splitting domain ownership across vertical/capability boundaries;
- introducing a new infrastructure/runtime class;
- changing tenant/privacy/authorization semantics;
- adding a destructive or difficult-to-reverse data model change;
- breaking a public/shared contract;
- adopting a new plugin/event/queue/cache/database architecture;
- changing constitution-level compatibility rules.

An ADR is not required for a local refactor that stays within an accepted boundary and passes the mission's acceptance contract.

## 9. Compatibility policy

Default: additive/backward-compatible evolution.

Breaking changes require:
1. explicit rationale;
2. affected-consumer inventory;
3. migration/compatibility plan;
4. rollback plan;
5. independent review;
6. human approval when user data, permissions, public contracts or irreversible behavior are affected.

## 10. M3-A binding decisions

Until superseded by evidence/ADR:
- `ResponsiveSectionTabs` is the canonical progressive section navigation contract.
- Workspace-shell duplication should converge through a technical shared contract.
- Repeated async load/mutate/busy/error/reload behavior is a shared technical concern.
- Housing maintenance finance is not Community pooled funds.
- Housing committee resolutions are not shared elections/secret ballots.
- Housing complaints/notices remain domain workflows beneath shared technical primitives.
- CSS normalization is incremental; vertical signature styling remains additive/domain-owned.
- Storybook remains deferred until stabilized component contracts demonstrate a real need.

## 11. Enforcement path

Architecture moves from prose to enforcement in this order:
1. constitution and mission contracts;
2. targeted source/static gates for forbidden dependencies and required contracts;
3. TypeScript/module boundaries where practical;
4. mission-scoped CI;
5. independent review evidence;
6. runtime verification where source inspection cannot prove behavior.

The goal is not zero architectural discussion. The goal is that routine decisions become cheap, consistent and machine-checkable.


## 12. Machine policy

`governance/architecture-policy.json` is the machine-readable projection of this constitution. The Markdown constitution remains normative; the JSON may only make deterministic subsets stricter/easier to evaluate, never silently broaden permissions. If they disagree, this constitution wins and the projection must be repaired.
