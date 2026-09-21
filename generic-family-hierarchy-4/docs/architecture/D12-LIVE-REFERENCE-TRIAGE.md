# D12 live reference triage — SQL Editor export

**Capture:** Founder-provided `d12-capture-reference.sql` one-row CSV; SHA-256 `074f89728fce44712b81627ef5f0dbcae76b6627ba321bd11720f285e9c0acc1`. Raw export remains outside the repository. This document contains only aggregate metadata and named code contracts. No database mutation was performed.

## Validated contents

The `doc` column parses as a single JSON object. The live server reports PostgreSQL 17.6. Captured: 167 public relations (all ordinary tables), 1,743 columns, 981 constraints, 401 indexes, 463 function signatures, 97 policies (90 public and 7 Storage), 3,377 table grant rows, and 5 installed extensions. All 167 captured public tables have RLS enabled. Of 463 functions, 444 are marked `SECURITY DEFINER` and all 444 report a function-level `search_path`. These counts describe the catalog; they do not prove that policies and function bodies are correct.

The source contains 121 SQL migration files numbered through `123`; versions `096` and `097` are reserved gaps. Every one of the 167 live public table names occurs in the historical migration text. This is name presence only, not proof that table definitions, constraints, grants or policies match.

## Concrete drift candidates

| Observation | Evidence | Investigation |
| --- | --- | --- |
| Two application RPC names are absent from the live function inventory | `lib/remote.ts` calls `set_network_notification_role` and `remove_network_notification_role`; migration `105_engagement_mentions_role_routing.sql` defines both, and no later repository migration mentions a drop of either | Treat assignment/removal in `components/shared/NetworkNotificationRoleAdmin.tsx` as potentially broken against this working database. Confirm with a read-only live signature query and a synthetic admin flow before authoring any forward repair. Do not apply migration `105` wholesale to the old project. |
| One live function has no literal `CREATE FUNCTION` match in historical migrations | `reconcile_network_media_usage(uuid)` exists in live public schema; source text lacks its definition; a security review references the name | Determine how it was introduced and whether current canonical SQL should include its live definition. Preserve its authorization and Storage behavior during reconstruction. |
| The expected Supabase CLI migration catalog was not visible | `to_regclass('supabase_migrations.schema_migrations')` returned null in this capture | Do not infer applied migration versions from filenames. Obtain migration/application history separately if available, or classify source-to-live differences by object definition and controlled replay. |

The name checks come from `scripts/d12-inspect-sql-editor-csv.py`. They ignore dynamic SQL, overloads, signatures and policy generation. Neither the table-name coverage nor these three function findings constitutes a full drift audit.

## Supplement capture — stabilized

A corrected run of `scripts/d12-capture-supplement.sql` was received as a one-row CSV with SHA-256 `0ce6507dc57ae79d96820800f76b5b38ba91e1be82004b3f51591295aaed4743`. The raw export remains outside the repository.

The supplement confirms:

- PostgreSQL server version: **17.6**.
- Public enums: **0**.
- Public domains: **0**.
- Public sequences: **6**.
- Public schema ACL captured successfully.
- Relation ACL entries captured: **173**.
- Function ACL entries captured: **463**.
- Storage buckets: **2** — `community-media` and `profile-photos`; both private with a 1 MiB file-size limit.
- `storage.buckets` and `storage.objects` both have RLS enabled; `FORCE ROW LEVEL SECURITY` is false.
- `reconcile_network_media_usage(uuid)` is present by exact signature.
- `set_network_notification_role(text,text,uuid,boolean)` is absent by exact signature.
- `remove_network_notification_role(text,uuid)` is absent by exact signature.
- `supabase_migrations.schema_migrations` is still not visible through `to_regclass`.

This moves the two notification-role RPCs from a name-inventory suspicion to a **confirmed live contract drift candidate**. Do not patch the golden database yet. D12 should first compare repository call sites and migration intent, then reproduce the failure/absence against the candidate fresh database and decide whether the canonical source should contain those RPCs.

The original supplement failed because its `app_ns` CTE projected only `oid,nspname` and later referenced `nspacl`. Commit `23418c290b90c9bcf6b15487f30e6871692e5d8a` fixed the capture query by projecting `nspacl`; this was a capture-script defect, not a live database defect.

## Remaining capture limitation

The SQL Editor captures now provide enough catalog evidence to begin object ownership, dependency analysis and live-vs-source drift classification. They still do **not** provide a complete executable logical dump equivalent to `pg_dump --schema-only`.

That is no longer a blocker for the next D12 design step. Canonical reconstruction can proceed from:

1. 121 accepted historical migration files through version 123;
2. the two live catalog captures;
3. current application/RPC usage.

Fresh bootstrap and final five-layer equivalence still require reconstruction into a new isolated Supabase project and product-level comparison against the untouched golden project. No user data or Storage objects need copying.
