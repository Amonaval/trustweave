# TrustWeave Database Bootstrap Developer Guide

## 1. Why this exists

Historically, TrustWeave evolved through many incremental SQL migrations.

That history is valuable for understanding how the product evolved, but replaying every historical migration is not the best installation path for a brand-new database.

The bootstrap system provides a **validated current-state database installer**.

Its purpose is:

> Create the current TrustWeave database directly from an empty Supabase project using a deterministic, modular, one-time SQL package.

The bootstrap package was introduced after D12 reconstructed the live database, applied it to a fresh Supabase project, and validated structural, security, API, behavioral, tenant-isolation and product-smoke parity.

---

## 2. Three database concepts

### A. Historical migrations

Location:

```text
supabase/migrations/
```

Purpose:

- chronological history;
- upgrades for databases that already exist;
- forensic/audit context;
- incremental production evolution.

Rules:

- immutable after accepted deployment;
- never renumber;
- never squash merely because a bootstrap exists;
- never use historical edits to repair a fresh-bootstrap problem.

### B. Canonical architecture

Location:

```text
db/canonical/
```

Purpose:

- module ownership;
- dependency graph;
- reconstruction rules;
- parity evidence;
- promotion provenance;
- generator contract.

This is the architectural source for producing bootstrap releases.

### C. Fresh-database bootstrap

Location:

```text
supabase/bootstrap/
```

Purpose:

- install TrustWeave into an empty Supabase project;
- provide deterministic apply order;
- avoid replaying historical migration chronology;
- become the preferred starting point for future dev/test/QA databases.

---

## 3. Versioned release structure

```text
supabase/bootstrap/
├─ CURRENT
├─ README.md
├─ DEVELOPER_GUIDE.md
└─ releases/
   └─ 2026-09-20-d12/
      ├─ manifest.json
      ├─ APPLY_ORDER.txt
      ├─ 00-foundation/
      ├─ 05-sequences/
      ├─ 08-bootstrap-functions/
      ├─ 10-tables/
      ├─ 15-sequence-ownership/
      ├─ 20-constraints/
      │  ├─ 00-keys/
      │  └─ 10-other/
      ├─ 30-indexes/
      ├─ 40-functions/
      ├─ 45-source-drift-repairs/
      ├─ 50-triggers/
      ├─ 60-security/
      ├─ 70-storage/
      ├─ 71-storage-owner-context/
      ├─ 75-schema-grants/
      ├─ 80-table-grants/
      ├─ 85-sequence-grants/
      └─ 90-function-grants/
```

`CURRENT` contains the release directory that should be used for a new project.

---

## 4. Why the SQL is split into phases

Database objects have dependencies. A single giant SQL file hides those relationships and makes failures difficult to isolate.

TrustWeave therefore uses phase-first installation.

### 00-foundation

Creates required extensions and database prerequisites.

### 05-sequences

Creates standalone/serial-style sequences.

Identity-column sequences are **not** created here because PostgreSQL creates them with the table.

### 08-bootstrap-functions

Creates the very small set of functions needed by table defaults, CHECK expressions or index expressions before tables exist.

### 10-tables

Creates all table shells.

Cross-table foreign keys are intentionally not created yet.

### 15-sequence-ownership

Restores exact sequence properties and ownership after identity/table creation.

### 20-constraints/00-keys

Creates all primary keys and UNIQUE constraints globally.

This phase must finish before foreign keys are added.

### 20-constraints/10-other

Creates foreign keys and remaining CHECK/other constraints.

The global key-before-FK split is intentional and was proven necessary during the D12 fresh replay.

### 30-indexes

Creates non-constraint indexes.

### 40-functions

Creates the complete captured function catalog.

Function-body validation may be deferred while the complete function dependency graph is recreated.

### 45-source-drift-repairs

Contains explicitly reviewed application contracts that were required by current source but missing from the golden live catalog.

For the D12 release these include:

- `set_network_notification_role(text,text,uuid,boolean)`
- `remove_network_notification_role(text,uuid)`

These are not accidental differences; they are documented D12 repairs.

### 50-triggers

Creates triggers after their functions exist.

### 60-security

Enables/reconstructs public-table RLS and user policies.

### 70-storage

Creates TrustWeave Storage bucket configuration that can be applied in the ordinary database context.

No Storage object/file rows are copied.

### 71-storage-owner-context

Contains hosted-Supabase Storage policy operations that require the platform-owned Storage context.

This phase is separate because `storage.buckets` and `storage.objects` are owned by `supabase_storage_admin`.

### 75-schema-grants

Reconstructs application schema ACL.

### 80-table-grants

Reconstructs table grants.

### 85-sequence-grants

Reconstructs sequence privileges.

### 90-function-grants

Reconstructs explicit function EXECUTE ACL.

---

## 5. Fresh project installation

Only use bootstrap on a genuinely empty project.

Before applying:

1. confirm the target is not the golden/live project;
2. confirm TrustWeave public tables do not already exist;
3. confirm the selected release matches `CURRENT`;
4. review `manifest.json`;
5. follow `APPLY_ORDER.txt`;
6. keep all passwords/connection strings local;
7. never commit secrets.

The automated installer should perform the same safety checks before executing SQL.

---

## 6. Storage is intentionally special

Hosted Supabase owns core Storage relations.

Therefore:

- built-in Storage table ownership is not reconstructed;
- Storage object/file data is never copied;
- TrustWeave bucket definitions are bootstrap configuration;
- TrustWeave Storage policies may require the separate owner-context phase;
- post-install parity must verify Storage RLS/policies instead of trying to replace Supabase internals.

---

## 7. What bootstrap must NOT contain

A bootstrap release must not contain:

- real customer/member rows;
- production IDs merely because they existed in golden data;
- Storage file/object records;
- passwords;
- database URLs;
- service-role keys;
- auth session tokens;
- environment-specific secrets.

Configuration rows may only be included when they are part of the product/database contract and are explicitly classified as bootstrap configuration rather than customer data.

---

## 8. Validation after bootstrap

A fresh bootstrap is not considered healthy merely because all SQL statements executed.

Validation layers are:

1. **structural** — relations, columns, constraints, indexes, sequences;
2. **security** — RLS, policies, grants, Storage boundary;
3. **API/contract** — functions/RPC signatures and ACL;
4. **behavioral** — representative role/tenant/database behavior;
5. **product/browser** — application smoke/regression against the fresh database.

D12 established these layers as the promotion standard.

---

## 9. How future migrations work

After release `2026-09-20-d12` becomes the current bootstrap:

- existing databases continue forward through new migrations;
- new databases install the current bootstrap first;
- only migrations **after the bootstrap cut point** need to be applied on top when creating a database from an older bootstrap release.

Example:

```text
bootstrap release includes state through historical migration 123

new migrations:
124_new_feature.sql
125_security_fix.sql
126_new_rpc.sql
```

A database created from the D12 bootstrap would then run migrations 124+.

A future bootstrap release may roll those changes into a new current-state package, but migrations 124–126 still remain in history.

---

## 10. Creating the next bootstrap release

Do not hand-copy random migrations into a new release.

The process is:

1. identify the current golden/reference database;
2. capture catalog state read-only;
3. run the canonical classifier/reconstructor;
4. generate a candidate bootstrap release;
5. apply it to a completely fresh disposable Supabase project;
6. run all parity layers;
7. review intentional differences;
8. promote the generated package;
9. update `CURRENT`;
10. keep the previous release for reproducibility/history.

---

## 11. When to create a new bootstrap release

Do not regenerate bootstrap after every migration.

Create a new bootstrap when one or more are true:

- migration history becomes materially cumbersome;
- major architecture/module boundaries change;
- a release milestone needs a clean install artifact;
- fresh-environment creation becomes slow or fragile;
- a major database refactor has been fully certified.

Normal product work should continue to create incremental migrations.

---

## 12. Developer decision table

| Situation | Use |
| --- | --- |
| Upgrade an existing TrustWeave DB | `supabase/migrations/` |
| Create a new empty TrustWeave DB | `supabase/bootstrap/CURRENT` release |
| Investigate architecture ownership | `db/canonical/modules.json` |
| Reconstruct/compare live state | D12 canonical tooling |
| Fix an already-deployed schema | new migration |
| Change an old historical migration | **Do not** |
| Store production rows in bootstrap | **Do not** |
| Test bootstrap correctness | fresh disposable Supabase project |

---

## 13. D12 release provenance

The first bootstrap release is based on the D12 reconstruction.

Evidence lives under:

```text
docs/architecture/D12-*
db/canonical/PROMOTION.json
```

The known Family Explore/Guide URL navigation defect is a pre-existing application-routing issue and is intentionally outside bootstrap/database scope.
