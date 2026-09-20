# D12 — Live vs source classification checkpoint

**Branch:** `llm-push`  
**Golden database:** read-only reference  
**Status:** classification/reconstruction started; no golden DB mutation

## Evidence used

- primary SQL Editor catalog capture, PostgreSQL 17.6;
- stabilized supplement capture;
- 121 historical migration files through version 123, with 096/097 reserved;
- current application call sites;
- migration 105 notification-role implementation;
- migration 122 notification-role read-contract repair.

The raw captures remain outside Git.

## Classification rules

D12 uses the requested final taxonomy only when the evidence is strong enough:

- **MATCH** — live and source contract are demonstrably equivalent at the compared level;
- **DRIFT** — both sides intentionally describe the same contract but differ;
- **MISSING** — required canonical/source object is absent live;
- **EXTRA** — live object has no accepted canonical/source owner yet;
- **DIFFERENT-BY-DESIGN** — difference is expected and should not be repaired.

Name-only hits are recorded as match candidates, not promoted to MATCH until definition/security equivalence is established.

## Confirmed classification

| Object / contract | Classification | Evidence / action |
| --- | --- | --- |
| 167 live public tables | MATCH candidate | Every live table name occurs in historical migration text. Definition, constraints, grants and policy parity still require reconstruction/fresh replay. |
| `public.set_network_notification_role(text,text,uuid,boolean)` | **DRIFT / MISSING live contract** | Migration 105 defines it; current UI transport calls it; exact live signature is absent. Do not patch golden DB. Candidate baseline should include it unless caller removal is deliberately chosen and proven. |
| `public.remove_network_notification_role(text,uuid)` | **DRIFT / MISSING live contract** | Migration 105 defines it; current UI transport calls it; exact live signature is absent. Same decision boundary as setter. |
| `public.get_network_notification_roles()` | MATCH candidate | Migration 105 defines it and migration 122 explicitly repairs/reasserts it; live inventory contains the function. Definition hash parity remains to be checked by the classifier/replay. |
| `public.reconcile_network_media_usage(uuid)` | **EXTRA pending ownership** | Exact live signature exists, but no literal historical migration definition was found in the earlier source scan. Preserve the live definition in the candidate reconstruction and assign ownership to activity/media until provenance is resolved. |
| `supabase_migrations.schema_migrations` visibility | **DIFFERENT-BY-DESIGN / environment evidence gap** | Not visible through `to_regclass` in both captures. Do not fabricate applied-version history from filenames. |
| public enums/domains | **MATCH** at inventory level | Live supplement reports zero enums and zero domains. Candidate reconstruction must not invent any. |
| six public sequences | MATCH candidate | Live supplement captured six sequences; reconstruction generator emits them before tables. |
| two Storage buckets | MATCH candidate | `community-media` and `profile-photos`, private, 1 MiB limit. Bucket config is part of candidate reconstruction; no Storage files are copied. |

## Notification-role decision

The missing mutators are not safe to dismiss as dead migration history. Current source still exposes assignment/removal behavior, and migration 105 contains authorization checks requiring network-admin access and active membership.

D12 therefore treats the canonical choice as:

1. **default candidate:** restore the two migration-105 mutator definitions in the new candidate baseline;
2. prove the admin assignment/removal flow against the candidate project;
3. only remove them from canonical SQL if the application caller is intentionally removed/replaced in the same change and product behavior is proven equivalent.

No change is authorized against the golden project.

## Reconstruction direction

The canonical graph is now encoded in `db/canonical/modules.json`:

`platform-core → identity → activity/workflow/notifications → federation/family → family-community/housing → future boundaries`.

`scripts/d12-reconstruct-canonical.py` reconstructs current-state SQL from the live catalog in dependency-safe phases:

1. extensions and sequences;
2. table shells/columns;
3. constraints;
4. indexes;
5. functions;
6. triggers;
7. RLS and policies;
8. grants;
9. Storage bucket configuration.

The output is a **candidate** until five-layer fresh-project parity passes.

## Next proof steps

- run classifier output against both supplied captures and review all non-match candidates;
- generate candidate modular SQL;
- inspect cross-module references and tighten the dependency graph;
- create a disposable Supabase project and apply candidate baseline;
- compare candidate capture to golden capture;
- run API/behavior/browser parity;
- only then promote the generated baseline as current canonical source.

School/education schema remains out of scope until D12 parity is complete.


## Reconstruction hardening checkpoint — 2026-09-20

The attached primary catalog capture was used as live structural truth for this pass. The reconstruction tooling was dry-run against that real primary capture. The supplement's already-recorded catalog facts were sufficient to harden sequence/ACL/Storage handling; a final run with the raw supplement remains a parity gate before any candidate database is created.

### Active notification-role defect confirmed

The missing notification mutators are not historical noise:

- `lib/remote.ts` still calls `set_network_notification_role` and `remove_network_notification_role`;
- `components/shared/NetworkNotificationRoleAdmin.tsx` calls them when an administrator assigns, changes or removes a responsibility role;
- migration 105 contains the intended admin/member authorization contract;
- the live capture proves both exact signatures are absent.

Therefore D12 keeps both functions as explicit **source-drift repairs in the candidate baseline**. This does not authorize changing the golden database.

### Schema ownership corrected from the live FK graph

The first ownership graph looked acyclic on paper but contradicted live foreign keys. The classifier now derives cross-module FK edges from the captured constraints and checks them against `modules.json`.

Ownership was corrected so shared infrastructure does not depend backwards on a late specialization:

- `family_members` is owned by **identity** rather than the Family specialization;
- `community_*` and `participation_events` are owned by **activity**;
- `contribution_suggestions` and `guide_feedback` are owned by **workflow**;
- `network_effect_events` is owned by **federation**;
- exact-name ownership overrides beat generic prefixes globally.

With these rules the captured public FK graph has **zero undeclared schema dependency violations**. `depends_on` now means only an acyclic schema/FK dependency. Runtime function/application calls are tracked as integration edges and may cross modules in either direction.

### Fresh-bootstrap hazards found and corrected

Static reconstruction testing found issues that would not be visible from object counts alone:

1. **Identity sequence collision:** four of the six captured sequences belong to identity columns and must be created implicitly with their table, not pre-created.
2. **Pre-table function dependency:** captured table expressions require `current_network_id()` and `a4_safe_external_url(...)` before table/constraint creation. The generator derives and emits only required bootstrap functions in phase 08.
3. **Function forward references:** at least 40 SQL-function references point to functions that sort later alphabetically. Full function creation now temporarily disables body validation, then restores it.
4. **ACL parity:** schema ACLs, table grants, sequence grants and explicit function ACLs now have dedicated replay phases. Application-facing principals are normalized before captured grants are reapplied.
5. **Storage boundary:** bucket configuration, Storage RLS state and captured user policies are reconstructed, but Storage object/file rows are never copied and built-in Storage relation ACLs remain Supabase-managed.
6. **Migration-105 extraction:** drift-repair extraction now uses function block boundaries rather than the earlier newline-sensitive regular expression.

The candidate phase order is documented in `db/canonical/README.md`.

### Dry reconstruction evidence

Using the real primary live capture, the hardened generator reproduced the expected structural inventory:

- 167 table definitions;
- 981 constraints;
- 401 captured indexes available for reconstruction, with constraint-backed indexes excluded from duplicate creation;
- 463 live function definitions, plus two early bootstrap re-creations and two explicit notification drift repairs;
- 10 triggers;
- 97 policies;
- six captured sequences, of which four are identity-owned and two are standalone/nextval sequences.

This is **static reconstruction evidence only**. It is not fresh-Supabase parity and does not promote the candidate baseline.

### Classifier strengthening

`scripts/d12-classify-catalog.py` now also:

- validates the declared canonical module graph for unknown dependencies/cycles;
- derives live public FK module edges and reports any undeclared dependency;
- scans current TypeScript/JavaScript source for static Supabase `.rpc("name")` calls;
- reports any application RPC name that is absent from the live public function catalog.

This turns the two known notification defects into a general contract check instead of a one-off exception.

### Next proof boundary

The next database-changing activity is still **only a fresh disposable Supabase candidate**, never the golden project. Before that apply:

1. run classifier + generator with both raw captures in a full repository checkout;
2. require zero module-graph/FK violations and review all `MISSING`, `DRIFT` and `EXTRA` entries;
3. inspect the generated manifest/apply order and ACL reconstruction;
4. apply to the disposable Supabase project;
5. recapture candidate catalog and compare structural/security/API contracts to golden;
6. then run behavioral and product/browser parity.

No School/education schema work starts before those gates pass.
