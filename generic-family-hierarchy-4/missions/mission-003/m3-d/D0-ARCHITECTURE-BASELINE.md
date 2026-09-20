# M3-D0 — Architecture baseline and fitness map

**Measured:** 2026-09-19, `llm-push` at `613a200e8237777459835a126896c7fa1049bb9b`. This is a source inventory, not runtime or production certification.

## Observable baseline

| Dimension | Evidence | Consequence / next fitness check |
| --- | --- | --- |
| Vertical addition | Nine vertical definitions in `verticals/*/definition.ts`; parallel `app-shell/vertical-registry.ts`, `app-shell/vertical-runtime.ts`, `app-shell/vertical-capabilities.ts`, `app-shell/template-registry.ts`, `templates/productized/config.ts`, `core/verticals/contracts.ts`, plus navigation and feature catalogs | D2 must reduce authoritative registration touchpoints; count again after one skeleton vertical. |
| Dependency direction | `app-shell/vertical-runtime.ts` eagerly imports all nine compositions plus definition and capability registries; `components/NetworkApp.tsx` eagerly imports `TemplateNetworkApp` and `AlumniNetworkApp` | D7 must measure production JS before/after lazy entry; source imports alone do not prove bundle size. |
| Navigation | `app/page.tsx` mounts `NetworkApp`; `NetworkApp` holds `view`, `TemplateNetworkApp` holds `tab`; current notification href uses `/?twNetwork=...&twSurface=...`; few dedicated public/invitation routes | D1 establishes canonical URL grammar and browser/history contract before more verticals. |
| Hotspots | `NetworkApp.tsx` 2,146 lines, `TemplateNetworkApp.tsx` 259 lines with dense inline rendering, `lib/remote.ts` 777 lines, `app/globals.css` 1,482 lines | Split only when a bounded route/capability extraction preserves behavior. |
| Data access | 158 source lines containing `supabase.rpc(` in `app/`, `components/`, `capabilities/`, `verticals/`, `lib/`; calls coexist with `app/api/v1` command routes | D6 inventories ownership per capability and prevents new UI-local RPC expansion. |
| DB history | 120 migration files; 109 lines containing `create policy`, 136 containing `create index`, 591 containing `security definer`, 585 containing `create or replace function` (case-insensitive searches) | These are lexical counts, not unique objects or a security audit. D6/D8 require catalog/query-plan and privilege review in disposable DB. No historical migration edits. |
| Browser QA | 37 files under `qa/e2e`; 180 under `scripts` | D1 adds deterministic route contracts; source gates cannot substitute for logged-in browser tests. |

Reproduce source counts with `wc -l components/NetworkApp.tsx components/TemplateNetworkApp.tsx lib/remote.ts app/globals.css`, `rg -n 'supabase\.rpc\(' app components capabilities verticals lib | wc -l`, and `rg --files supabase/migrations | wc -l`. The migration keyword counts use `rg -ni` over that directory.

## Current access path and risk

`getAuthUser()` resolves the profile's active network and membership role. `repository.fetchNetworkSettings()` then resolves the active network. `setActiveNetwork()` calls the existing `set_active_network` RPC; membership listing uses `get_my_networks`. The URL does not currently select the network. A stored notification link can activate a network through `NotificationCenter`, but a copied URL alone has no durable network-context contract. Server RPC/RLS remains the data authorization boundary; route selection must never grant access.

The representative Family, Family Community and Housing surfaces use Family `View` and productized `Tab` unions. A route foundation should derive allowed surfaces from the existing app compositions where possible, validate the requested network against the caller's active memberships before activating it, and fail closed for unknown/inactive networks. There is no generic resource-by-ID read authorization contract yet; detailed member/complaint/event routes must wait for the corresponding capability-owned lookup and policy checks.

## Reuse assessment for the School proving target

| Proposed School need | Existing reusable foundation | Remaining ownership |
| --- | --- | --- |
| Student/guardian identity and private network | Network memberships, entities, relationships, identity refs | School-specific guardian/student relationship and scoped access. |
| Notices/events/actions | Community activities, engagement, notifications; Housing notices | School-specific audience, acknowledgement and consent adapter; do not relabel Housing complaints. |
| Absence, homework, pickup | No proven shared lifecycle covering these semantics | D5 action/obligation proof first, then School-owned policies/workflows where distinct. |
| Private deep links | Legacy notification query protocol only | D1 canonical network/surface route and later policy-owned resource routes. |

## Fitness backlog and gates

1. D1: valid and invalid route grammar, direct entry, login return, network switch, history, refresh, cross-tenant denial, legacy notification compatibility. Browser proof requires configured staging/test users; record absence rather than asserting success.
2. D2/D3: one source of truth for vertical/capability registration; fail closed for unknown IDs; count touched files for an added skeleton vertical.
3. D4/D5: explicit policy/consent and action contracts with resource-level tests on existing Housing/Community cases.
4. D6: inventory `SECURITY DEFINER` privileges and network-scoped indexes in a disposable Postgres/Supabase instance; use query plans, not lexical counts, for optimization.
5. D7/D8/D9: compare Next production per-route chunks, startup JS, memory, bounded query performance and tenant-aware telemetry before making scale claims.

## Certification boundary

D0 is an evidence-only inventory. No connected database, authenticated browser or production bundle measurement is claimed. The connected two-vertical reliability work and migration 122 staging gate remain open as recorded in `CURRENT-STATE.md`.
