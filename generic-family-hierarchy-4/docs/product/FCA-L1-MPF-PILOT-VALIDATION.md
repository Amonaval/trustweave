# FCA-L1 — MPF Pune East Pilot Validation Contract

**Status:** IMPLEMENTED / SOURCE REVIEWED — TARGETED RUNTIME VALIDATION PENDING  
**Branch:** `fca-l1-mpf-pilot`  
**Candidate:** `ba895c7997087f84f2769c1419616b49d3bd1085`  
**Date:** 2026-09-23

## Mission outcome

Make the existing Family Community product credible enough for a small MPF Pune East pilot without starting another Community feature program.

The source candidate now focuses on three things:

1. preserve the seven observed pilot blockers as explicit source checks;
2. make the anonymous MPF Playground use the same canonical 20-family synthetic data used by the launch loader;
3. make the President/member public-preview journeys genuinely read-only and meaningful instead of falling through to connected RPCs.

This is a pilot-proof slice, not a new vertical implementation.

## FCA-P0 — seven observed blockers

Current source review classifies all seven as **source-resolved**:

| # | Blocker | Source evidence |
|---|---|---|
| 1 | Residential flagship hero usable on small screens | narrow-screen `.hs-chairman-hero` / actions CSS exists |
| 2 | Returning to Family clears stale Housing/Community/Alumni demo state | Family Playground entry explicitly clears other demo modes |
| 3 | Signed-out network/language/theme controls remain legible in dark mode | public Discovery exposes Theme + Language controls and dark styling |
| 4 | Event RSVP exposes Going/Tentative participant identities | shared Community detail uses event RSVP identity contract |
| 5 | Mobile More remains above device safe area | bottom nav uses `safe-area-inset-bottom` and a dedicated More control |
| 6 | Housing statutory committee election is distinct from ordinary member poll | statutory election record cannot cast the official poll in-app; Maharashtra guidance is explicit |
| 7 | Launch seed reruns reuse lineage instead of duplicating rows | runner consumes prior remote IDs and migration 113 keys lineage by network/dataset/section/row |

**Important:** this table is a source audit, not runtime certification.

## FCA-P1 — canonical MPF Playground

Before FCA-L1, the public Family Community runtime described itself as full-fidelity MPF Pune East while still using the older generic 10-family/30-person Association sample.

The candidate now derives the read-only Playground from:

`public/launch-demo/family-community-20-families.json`

That canonical synthetic dataset contains:

- 20 families;
- 67 people;
- 148 family relationships;
- annual membership/payment state;
- 8 committee/leadership assignments;
- 6 events + RSVP evidence;
- 12 posts;
- 4 memories;
- 4 groups + membership;
- 4 funds + transactions;
- 2 member-decision/election records.

`showcase-data/family-community-playground.ts` adapts that data into the existing generic productized contracts. No MPF-specific application or backend was created.

## FCA-P2 — President/member preview journeys

### Anonymous / public Playground

The read-only sample now has an explicit Family Community persona rather than relying on an accidental undefined-owner match.

Expected public journey:

1. Discovery → Family Community → MPF Pune East Playground.
2. Home shows realistic families/people/community activity.
3. Me & My Family shows a deterministic representative + household and cannot edit.
4. Directory supports families / representatives / members plus area/profession filtering.
5. Event detail shows Going/Tentative people using local preview evidence.
6. Group detail shows local preview membership without Supabase calls.
7. Funds & Collections renders a read-only canonical snapshot.
8. Member Decisions renders a read-only canonical snapshot.
9. Community detail Like/edit/join/comment mutations remain unavailable.
10. Playground share stays on the valid public Playground URL; connected networks retain exact object deep links.

Shared Funds/Voting components now accept generic optional preview snapshots, so this is not an MPF-only UI fork. Any Playground without preview data fails to an empty read-only state rather than calling connected RPCs.

### Connected President / committee admin

Existing source supports:

- Community policy;
- April–March membership year, fee and grace period;
- family representative / membership / payment state;
- leadership and designation history;
- finance entries;
- family/member management;
- co-admin household administration;
- shared posts/events/groups lifecycle;
- invitations/claims/import/export/privacy/lifecycle administration through existing generic admin surfaces.

### Connected ordinary member

Existing source supports:

- Me & My Family;
- family/member directory and profiles;
- Community posts/events/groups;
- RSVP and attendee identities;
- family structure/connections;
- contributions;
- Funds visibility;
- Member Decisions;
- contextual Guide.

## Targeted runtime validation — next action

Do not run broad QA.

### A. Anonymous Playground — no database mutation required

Manually validate:

- Discovery opens the exact Family Community Playground;
- Home feels like MPF Pune East rather than a generic Association;
- Me & My Family shows a coherent representative/household;
- directory counts/search/filters feel credible;
- one event detail shows attendee names;
- one group detail shows members;
- Funds shows realistic read-only values;
- Member Decisions shows the sample election/poll without mutation controls;
- share produces a usable public Playground destination;
- mobile More, small-screen layout and dark/signed-out controls remain usable.

### B. Connected President/admin — intentional environment only

Before exercising LIFE2 mutations, confirm the target environment actually contains the required Community Object contracts (including migration 126 or its effective equivalent). Do not auto-apply SQL merely for this validation.

Then validate the smallest President journey:

- annual membership year / fee / grace;
- family membership + representative + payment state;
- leadership/committee history;
- one post/event/group lifecycle;
- one RSVP identity view;
- Funds/collections visibility;
- one Member Decision flow appropriate to an association.

### C. Connected ordinary member

Validate:

- own profile/family linkage;
- Me & My Family;
- directory/profile privacy;
- RSVP + attendee view;
- post/comment/group participation;
- Funds visibility appropriate to policy;
- member decision participation where eligible.

## Evidence status

- **Implementation:** yes.
- **Source review:** yes.
- **Dedicated FCA-L1 source gate authored:** yes — `scripts/fca-l1-pilot-proof-gate.mjs`.
- **Dedicated gate executed:** **no**.
- **Build/typecheck executed for this candidate:** **no**.
- **Browser/runtime validation:** **no**.
- **Supabase mutation:** none by this FCA-L1 work.
- **Deployment / GitHub Actions:** none.
- **Paid/metered resource:** none.

Do not upgrade this status to runtime-verified until the targeted journey actually runs.

## Stop condition

Once the anonymous proof is credible and the minimum President/member connected journey is validated, **stop building** and show it to a small real MPF Pune East group.

The first real-user cycle should classify findings into:

- blocker / trust failure;
- repeated friction;
- Generic + Easy + Impactful improvement;
- useful later;
- noise / one-off customization.

That evidence selects the next mission.
