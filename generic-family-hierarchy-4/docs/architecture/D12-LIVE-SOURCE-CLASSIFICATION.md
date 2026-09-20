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
