# D12 Canonical Promotion Review

Date: 2026-09-20

## Decision

**READY FOR CANONICAL BASELINE MATERIALIZATION**

D12 has satisfied the required evidence layers against a fresh disposable Supabase project.

This review authorizes materializing the reconstructed current-state SQL baseline under `db/canonical/`. It does **not** authorize deleting, squashing, renumbering or rewriting historical files under `supabase/migrations/`.

## Environments

- Golden/live reference: `OS Network`
  - project ref: `yyhwcqpzplebittvxzzl`
  - role during D12: read-only reference / fallback
- Fresh disposable candidate: `TrustWeave D12 Candidate`
  - project ref: `blpdjhmtayjkcczqltqi`
  - region: `ap-south-1`
  - created from an empty public schema specifically for D12

The earlier `TrustWeave QA DB Replay` project was paused to free a Free-tier project slot. It was not used as the D12 proof database because it already contained older TrustWeave replay state.

## Evidence layers

### 1. Static reconstruction

PASS.

- 167 public relations
- 1,743 columns
- 981 constraints
- 401 indexes
- 463 captured function signatures
- 10 triggers
- 97 policies
- 6 sequences
- 167/167 public tables with RLS enabled
- module/FK ownership graph validated and acyclic
- application RPC scan found 327 current static RPC names
- only two live omissions: the reviewed notification-role mutators

### 2. Fresh structural parity

PASS.

The reconstructed baseline was replayed into a fresh Supabase project and compared with the golden database. PostgreSQL CHECK-expression re-rendering differences were normalized semantically; no semantic CHECK difference remained.

### 3. Security / ACL / Storage parity

PASS with documented platform-managed boundary.

- public/schema/table/sequence/function ACL reconstruction validated
- hosted Storage relation ownership remains Supabase-managed
- user Storage policies use the owner-context application path
- Storage object/file rows are never copied

Security advisor category counts match golden except the intentional +2 authenticated SECURITY DEFINER findings for the two restored notification mutators. Those functions contain explicit network-admin authorization checks.

### 4. API / contract parity

PASS.

- golden function catalog reproduced
- `reconcile_network_media_usage(uuid)` preserved
- source-required `set_network_notification_role(text,text,uuid,boolean)` restored
- source-required `remove_network_notification_role(text,uuid)` restored
- no other current static application RPC name is missing

### 5. Database behavioral parity

PASS.

Persisted evidence: `D12-DATABASE-BEHAVIOR-EVIDENCE.json`.

Representative checks passed for Housing and Family Community:

- active-network selection
- Housing property snapshot
- Family Community admin snapshot
- notification-role owner assign/read/remove
- ordinary-member denial for notification-role management
- cross-tenant read denial
- cross-tenant activation denial

### 6. Product/browser smoke

PASS WITH DEFERRED PRE-EXISTING DEFECT.

Persisted evidence: `D12-MANUAL-BROWSER-SMOKE-EVIDENCE.json`.

The founder switched the application to the new candidate project and performed an approximately 5–10 minute eagle-eye regression. The application loaded correctly and high-level flows looked healthy.

Known deferred issue:

`D12-DEFERRED-ROUTING-001` — Family Explore/Guide route `/network/:networkId/guide` can fail to open.

This defect existed before D12/database migration and is classified as a non-database routing defect. It does not block D12 baseline promotion and should be fixed only after SQL refinement is closed.

## Refinements discovered by fresh replay

The fresh candidate replay exposed and corrected D12 tooling issues that would not have been visible from static catalog analysis alone:

1. PK/UNIQUE constraints must be created before dependent foreign keys.
2. Hosted Supabase Storage policies require a separate owner-context apply boundary.
3. Built-in Storage RLS state is verify-only under hosted ownership.
4. PostgreSQL CHECK definitions require semantic normalization before parity classification.
5. Notification-role drift-repair ACLs must be deterministic.

These refinements are part of the D12 tooling and are not changes to historical migration history.

## Promotion invariants

Canonical materialization must preserve all of the following:

- historical migrations `001..123` remain immutable;
- no production/customer data enters the canonical baseline;
- no Storage object/file contents enter Git;
- no credentials, passwords, service-role keys or connection strings enter Git;
- canonical SQL represents current schema/function/security state, not migration chronology;
- the two notification mutators remain explicit reviewed source-drift repairs;
- the golden database remains available as fallback until the canonical bootstrap path has been used successfully beyond D12.

## Remaining non-D12 work

After SQL/canonical refinement is closed:

- fix `D12-DEFERRED-ROUTING-001` (Family Explore/Guide URL navigation);
- rerun the relevant focused product regression;
- do not reopen D12 database reconstruction unless that fix reveals an actual database contract defect.

