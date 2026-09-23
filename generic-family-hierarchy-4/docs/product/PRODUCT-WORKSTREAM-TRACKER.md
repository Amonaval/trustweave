# TrustWeave — Product Workstream Tracker

**Date:** 2026-09-23  
**Purpose:** Keep open work visible without turning every category into a serial mission program.

## Operating rule

TrustWeave is pre-release.

For every product, vertical or architecture area:

1. keep **one highest-leverage next slice** at most;
2. prefer roughly **20–30% effort for 70–80% of learning/value**;
3. finish that bounded slice, then re-select from the whole portfolio;
4. park remaining work with a concrete resume trigger;
5. do not continue a category merely because its backlog is long;
6. release/security/privacy blockers can override this rule.

**OPEN / PARKED does not mean NEXT.**

## Workstream tracker

| Area | Current state | Highest-leverage next slice | Status | Resume / selection trigger |
| --- | --- | --- | --- | --- |
| **Network Activation Autopilot** | Governed lower layer + NAA-L1 source-mapping bridge implemented | None now | **PARKED / manual proof pending** | Resume only for a real/synthetic validation finding, alpha blocker, or evidence that source adaptation remains the dominant onboarding pain |
| Generic X→Y Transformation Engine | Strong parallel thesis; no independent implementation | None now | PARKED | Re-select only if NAA-L1 proves a reusable boundary or a non-TrustWeave buyer/use case appears |
| Pattern Repair / smart bulk fixes | Product idea defined | None now | PARKED | Real files show repetitive repair dominates remaining effort |
| Transformation Recipe / drift detection | Product idea defined | None now | PARKED | Same source format is imported repeatedly and remapping becomes real pain |
| **Family Community / Association** | MPF Visual Life Home source landed; next gap is object depth rather than more decorative breadth | Consume **LIFE2 shared Community Objects** for real event/post/memory/group detail, lifecycle and sharing | **ACTIVE CONSUMER / BOUNDED** | Validate the shared object experience in MPF after migration 126 is intentionally applied; do not fork MPF-specific lifecycle code |
| Residential / Housing Society | Operational vertical with the same Community engine as MPF | Consume **LIFE2 shared Community Objects** for society events/posts/groups; no duplicate Residential implementation | **ACTIVE CONSUMER / SHARED** | Validate through the same shared detail/lifecycle contract; Residential-only work remains limited to domain-specific operations |
| School vertical | Architecture/readiness blueprint exists; implementation intentionally absent | None | PARKED | Explicit product/commercial priority with real user/design partner |
| Other new verticals / org use cases | Ideas/foundation exist | None | PARKED | Evidence-backed buyer/problem outranks current work |
| Governed Institutional Intelligence / V2 | Initial deterministic intelligence shape exists | None | PARKED | Trustworthy real activated context + repeated institutional questions |
| TrustWeave Ops / distributed operations | Strong paid-wedge thesis | Discovery, not build | PARKED / THESIS | Design partner shares real workflow/data or concrete commercial pull |
| Architecture — code split / lazy loading | Meaningful D7 work already completed | Only measured bottlenecks | PENDING | Bundle/performance evidence crosses agreed threshold |
| Architecture — shared components / CSS / cleanup | Open convergence opportunities exist | Opportunistic only | PENDING | Repeated maintenance cost or touched-area refactor creates clear leverage |
| Architecture — database/D12 recovery | Review-closed baseline exists | None | PARKED | Concrete recovery/bootstrap/product reason |
| **Shared Community Objects** | `network_activities` / `network_groups` already power productized verticals, but objects previously ended at create/display/join | **LIFE2:** shared detail drawer, creator/admin edit-delete, comments, RSVP names, group members/details, explicit join/leave, real deep-link sharing | **ACTIVE / BOUNDED** | Stop after MPF + Residential prove the same implementation; extend only through shared contracts, never per vertical |
| Connected reliability / QA | Preserved unresolved gates exist | Run only when required by release/change risk | GATED | Alpha/release candidate or critical path changed |
| Autonomous-company runtime | C1–C10 proof completed | None | PARKED | A concrete company-operating problem justifies more automation |
| PDF/OCR/connectors/generic AI ingestion | Opportunity inventory only | None | PARKED | Real customer input cannot be solved with supported tabular files |

## Selected next slice — FCA-L1: field-feedback closure + MPF East public pilot proof

Founder usage on 2026-09-22 supplied stronger evidence than the original screenshot-only plan. FCA-L1 therefore absorbs a **bounded field-feedback closure** before the external proof:

1. Residential mobile flagship hero must remain usable on a small screen.
2. Switching back to Family Playground must clear stale Housing/Community/Alumni demo state.
3. Network/language/theme controls and the signed-out public surface must remain legible in dark mode, with a way to change appearance after sign-out.
4. Event RSVP must make Going and Tentative participants inspectable, not show only an aggregate.
5. Mobile More/navigation must be visibly reachable above the device safe area.
6. Housing elections must distinguish the Maharashtra statutory committee-election workflow from ordinary in-app member polls and explain unavailable voting.
7. Bundled launch seed reruns must reuse the same network-scoped records through lineage rather than duplicate rows.

These are observed alpha/pilot blockers and are allowed to override the earlier "no feature expansion" rule. They **do not** authorize broader Residential development, a new election-compliance product, performance work, or a generalized seed architecture.

**Lean stop condition:** validate these observed blockers locally on the existing Family Community + Residential journeys, then complete one public MPF East proof pack / real-user feedback cycle. After that, stop and re-select from the portfolio.

## Network Activation alpha finish line

NAA-L1 is successful enough to stop when:

- several structurally different synthetic XLSX/CSV files can be mapped without rewriting them into our template;
- the user mainly confirms column meanings rather than editing rows;
- confirmed mappings are applied across the entire dataset;
- unresolved/missing information is explicit;
- no semantic guess becomes trusted;
- the safe normalized output can enter the existing governed compiler path.

Do **not** require pattern-learning, persistent recipes, drift detection, arbitrary external targets, database activation or standalone commercialization to call this bounded slice complete.

## How to pick the next work after NAA-L1

Choose from the whole table using:

1. alpha/release impact;
2. user pain or product learning;
3. trust/security risk;
4. business/commercial pull;
5. effort versus expected value;
6. whether existing/open-source capability can eliminate most implementation.

Do not choose based on which category already has the longest roadmap.

## Commit/history discipline

A bounded mission should normally produce **1–5 coherent commits**. A larger mission should generally remain within **5–10** unless rollback/security/migration/bisect needs justify more.

Batch by outcome, not by file.

For connector-driven work, use Git blob/tree/commit batching rather than accepting one repository commit per tool write.

If exploratory history becomes noisy, create a clean batched merge-candidate branch and retain the noisy branch only as temporary/historical evidence.


## 2026-09-23 — FCA-VIS1 MPF Visual Life Home

Founder review identified a voluntary-adoption risk: Community was operationally useful but visually flat. This bounded slice changes Family Community Home only, using existing private media/profile/activity data.

Implemented source direction:
- visual hero + editable community cover;
- featured upcoming event/poster;
- member/photo and birthday rails;
- photo/memory/update story strip;
- profession/locality community pulse;
- richer update/history/group/membership composition;
- designed placeholders when media/profile enrichment is missing;
- restrained hover/bar motion with reduced-motion support;
- generic Association retains its existing Home;
- no new backend, image service, external API, paid dependency or Residential redesign.

Stop after live review with representative MPF content. Do not automatically expand the visual redesign across the product.


## 2026-09-23 — LIFE2 shared Community Object depth

Founder direction: do not solve event/post/group depth independently in MPF, Residential, Alumni or future verticals. All productized verticals already reuse the same generic activity/group engine, so lifecycle must live once in the shared layer.

Source work includes migration `126_community_object_depth.sql` plus common UI/routing:
- creator/admin edit + delete for activities and posts;
- group view, description, members, join/leave, admin edit/delete, add/remove members and member/lead role management;
- proper attendee detail for events;
- proper comment surface instead of browser prompts;
- share URLs that deep-link to the exact authorized object, including post-aware notification routing;
- image lightbox and shared detail drawer;
- MPF and Residential Home event entry points route to the same shared detail experience.

Migration 126 is **committed source only and not applied to any Supabase project**. Runtime edit/delete/group-member features require an explicit later environment decision.


## 2026-09-23 — VIS2 Founder Design Studio + Family Community reuse

Founder direction: visual presentation should be controllable without repeated source edits, while vertical capability depth should converge through existing shared engines instead of new Family-specific features.

Source work:
- one **Platform Design Studio** inside Founder Launch Control;
- global managed slots for platform logo/mark, landing background + hero, and Guide banner;
- per-vertical managed Playground slots for banner, discovery thumbnail, featured-event fallback and icon;
- curated platform-wide font, layout density, hero treatment and corner presets;
- existing compressed WebP / EXIF-stripping client pipeline and existing `community-media` bucket are reused; no external image service or paid transformation;
- migration `127_platform_design_studio.sql` is source-only and supplies the platform-owner settings/asset registry plus narrowly scoped storage access for public platform visuals;
- actual network cover editing is generalized across Family, Alumni, Association, Family Community, Residential and the remaining productized verticals through the existing `network_branding/cover` media binding;
- Family Community keeps its existing legacy Family Memories + quiet digest, but now composes the existing shared Posts and Network Activity/Groups experiences for posts, comments, likes, events, RSVP, shared memories/moments and groups;
- Family navigation is relabelled from **Memories** to **Community** so the reused event/post surfaces are discoverable;
- no new Family-only Events implementation or duplicate lifecycle backend was introduced.

Activation boundary:
- existing network cover and shared Community functions use existing media/activity contracts;
- LIFE2 edit/delete/member-depth still depends on migration 126 where those RPCs are needed;
- Platform Design Studio persistence/upload requires migration 127;
- migration 127 was **not applied**, no deployment/workflow was run, and all visual consumers retain existing fallbacks when the contract is absent.


## 2026-09-23 — VIS3 Product Front Door & platform-level exploration

Founder direction: continue visible, transformational experience work and make the accumulated product depth understandable before a user commits to a network.

This bounded slice:
- upgrades the anonymous/signed-in Product Front Door rather than creating a separate marketing site;
- adds a restrained manual Product Story carousel and an all-vertical visual gallery;
- reserves up to four managed story/infographic images per vertical so earlier Family/MPF/Residential share visuals have a durable in-product home;
- keeps carousel motion manual-first with no auto-rotation;
- makes **Explore & Guide** and **Launch Control** platform-level workspaces, independent of whichever network is currently active;
- separates Design Studio into Platform, Vertical defaults, Playground overrides and Network-specific identity;
- makes Playground visuals inherit vertical defaults instead of requiring duplicate images;
- preserves network-specific imagery inside the existing private network media boundary;
- repairs the platform-image storage guard and notification RPC overload in source-only migration `128_vis3_platform_runtime_repairs.sql`;
- compacts the Launch Control vertical selector and shared object detail action;
- records prior share-image/PDF migration targets in `VIS3-SHARE-ASSET-MAP.md`.

Activation boundary:
- migration 128 is committed source only and not applied;
- exact previously-generated Library/Project images are not regenerated or silently substituted;
- upload those originals through Design Studio after migration 128 is intentionally applied;
- no deployment, workflow, test suite or external paid resource was invoked.
