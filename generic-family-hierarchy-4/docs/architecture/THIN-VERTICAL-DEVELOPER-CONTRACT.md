# TrustWeave Thin-Vertical Developer Contract

D10 turns the D2–D9 architecture rules into one repeatable vertical-onboarding contract. It does **not** remove the explicit compile-time registration boundary.

## Workflow

1. Create one JSON blueprint that declares domain identity, reused capabilities, optional owned capability, route surfaces, adapter obligations, observability journey/threshold and a small synthetic playground seed.
2. Run `npm run vertical:scaffold -- --spec <blueprint.json> --check`.
3. Resolve every validation error and review release blockers.
4. Generate vertical-local files with `--write --out <working-directory>`.
5. Perform the small explicit central integration plan:
   - add the vertical kind;
   - add an owned capability contract only when the vertical truly owns one;
   - add lightweight runtime metadata;
   - add one canonical manifest entry;
   - add the QA catalog entry when the vertical is ready for connected testing.
6. Implement any required policy/API/workflow adapters.
7. Run unit, bundle, policy, routing and connected vertical QA before changing the vertical from skeleton to active.

## Why registration stays explicit

TrustWeave deliberately does not scan folders and auto-register runtime verticals. A misspelled folder or half-generated module must never silently become a user-visible network kind. The closed `NetworkVerticalKind` and canonical manifest remain fail-closed architecture boundaries.

The scaffold therefore automates deterministic boilerplate and emits the exact remaining integration edits instead of bypassing those boundaries.

## Blueprint requirements

A blueprint must have:

- a lowercase route-safe kind;
- localized English/Hindi/Marathi labels for every route surface;
- at least one already-owned reusable capability;
- an owned capability only when domain semantics genuinely need one, named `domain.<kind>`;
- a `home` surface and a valid playground start surface;
- a small explicitly synthetic playground seed (maximum 50 entities);
- declared policy, workflow and data-boundary modes;
- one primary observability journey `<kind>.primary` and a slow-operation threshold.

The generic route grammar remains:

`/network/{networkId}/{surface}`

A thin vertical registers surfaces; it does not invent a competing route grammar.

## Adapter boundary

`core/verticals/thin-adapters.ts` exposes typed policy, workflow, query and command adapter interfaces. Vertical adapters translate domain semantics into existing D4/D5/D6 platform contracts.

They must not:

- bypass server/RPC/RLS authorization;
- create a second persistence owner;
- call Supabase RPC directly from UI code;
- duplicate shared workflow or policy engines.

## Release gates

The scaffold is allowed to be a skeleton with unresolved obligations. Activation is not.

Examples of release blockers:

- vertical policy adapter required but not implemented;
- server-owned API boundary required but not implemented;
- vertical workflow adapter required but not implemented.

The scaffold reports these separately from structural validation so early design work is possible without allowing an unsafe active vertical.

## Runtime/bundle rule

Every generated thin vertical assumes `lazy-vertical-ui`. New vertical code must not become part of the universal shell. D7's First Load JS gate and source import guards remain authoritative.

## QA rule

The generated QA contract is only the local starting point. A released vertical must also enter the normal TrustWeave QA catalog and inherit the shared role/routing/security/resilient-crawl suites.

The D10 synthetic `civic-circle` fixture exists only under QA and is not a product vertical.
