# D12 canonical database reconstruction

This directory is the **candidate current-state database source**, not a replacement for `supabase/migrations/001..123` yet.

## Contract

- `supabase/migrations/` stays immutable upgrade history.
- `modules.json` owns the current modular ownership graph. Its `depends_on` edges are **schema/FK dependencies only** and must remain acyclic; cross-module runtime calls are integration edges, not DDL ordering edges.
- Generated SQL must come from the captured golden catalog and must not contain application rows or Storage objects.
- A generated baseline is promoted to canonical only after fresh-project five-layer parity: structural, security, API/contract, behavioral and product/browser.
- The existing Supabase project remains untouched and available as the golden fallback.
- `future-education` is a reserved boundary only; D12 must not implement School schema.

## Generation

For the guarded path, run from `generic-family-hierarchy-4`:

```bash
python scripts/d12-prepare-candidate.py "<primary.csv>" --supplement "<supplement.csv>"
```

This runs classification + reconstruction together and writes `.d12-work/candidate/static-gate.json`. It fails closed on:

- invalid/cyclic canonical module dependencies;
- captured FK edges not declared in `modules.json`;
- current application RPC names missing live beyond the two reviewed notification mutators;
- unreviewed `MISSING`, `DRIFT`, `EXTRA`, or `DIFFERENT-BY-DESIGN` objects;
- capture-hash mismatch;
- unexpected source-drift repairs;
- invalid phase ordering or incomplete generated manifest.

The lower-level commands remain available for investigation:

```bash
python scripts/d12-classify-catalog.py "<primary.csv>" --supplement "<supplement.csv>" --out .d12-work/classification.json
python scripts/d12-reconstruct-canonical.py "<primary.csv>" --supplement "<supplement.csv>" --out .d12-work/canonical
```

The generator writes a **phase-first** candidate baseline plus a manifest/checksums. Keep raw captures outside Git. Review generated SQL before applying it to a **new disposable Supabase project**.

Current phase order:

1. `00-foundation` — extensions;
2. `05-sequences` — standalone/serial-style sequences only;
3. `08-bootstrap-functions` — only functions required by table defaults/checks/index expressions;
4. `10-tables` — all table shells, including identity columns;
5. `15-sequence-ownership` — exact sequence options and standalone ownership;
6. `20-constraints`;
7. `30-indexes`;
8. `40-functions` — exact live function catalog with deferred body validation during creation;
9. `45-source-drift-repairs` — explicit source/application contracts proved missing live;
10. `50-triggers`;
11. `60-security` — public-table RLS and policies;
12. `70-storage` — Storage RLS state, buckets and policies, never Storage object/file rows;
13. `75-schema-grants`;
14. `80-table-grants`;
15. `85-sequence-grants`;
16. `90-function-grants`.

The split is intentional. Identity sequences must not be pre-created; expression dependencies such as `current_network_id()` must exist before table creation; all tables must exist before foreign keys; and function-body validation is deferred while the complete live function graph is recreated.

The generator normalizes application-facing ACLs before replaying captured grants. Built-in Storage relation ACLs remain Supabase-managed; their RLS state and user-defined policies are reconstructed.


### Storage owner context

Hosted Supabase owns `storage.buckets` and `storage.objects` with `supabase_storage_admin`. Direct `postgres` / `psql` sessions cannot mutate their RLS state or create policies on them.

D12 therefore treats built-in Storage relation RLS/force-RLS as **verify-only**. Bucket rows are reconstructed in `70-storage`. User-defined Storage policies are emitted separately under `71-storage-owner-context` and are excluded from the direct `apply_order`. Apply those files through Supabase Dashboard/platform migration tooling, then run catalog parity.

## Disposable candidate workflow

After the guarded static gate passes, D12 still does **not** touch the golden project.

Apply only to a newly created disposable Supabase project:

```bash
# Keep the connection URL local. Do not paste it into chat or Git.
export D12_CANDIDATE_DATABASE_URL='postgresql://...'

python scripts/d12-apply-candidate.py \
  --candidate-project-ref "<new-project-ref>" \
  --golden-project-ref "<existing-golden-project-ref>" \
  --confirm APPLY-TO-DISPOSABLE-D12-CANDIDATE
```

The apply runner requires a PASS `.d12-work/candidate/static-gate.json`, validates that the connection hostname belongs to the declared candidate project, refuses the golden project ref, and applies the manifest in a single `psql` transaction.

Then recapture and compare the disposable database in one command:

```bash
python scripts/d12-verify-candidate.py "<golden-primary.csv>" \
  --golden-supplement "<golden-supplement.csv>" \
  --candidate-project-ref "<new-project-ref>" \
  --golden-project-ref "<existing-golden-project-ref>"
```

That command creates fresh candidate captures and runs the structural/security/API catalog parity gate. A PASS is still **not canonical promotion**; behavioral and product/browser parity remain required.

## Promotion rule

Do not copy generated files into a permanent baseline or change bootstrap behavior until the candidate database passes the D12 parity gates. Historical migrations are not deleted, squashed or rewritten.


## D12 parity status — fresh disposable candidate

The reconstructed baseline has now been applied to a fresh Supabase project and passed:

- structural catalog parity;
- security/ACL parity, with documented Supabase-managed Storage boundaries;
- API/function contract parity;
- representative database behavioral parity for Housing + Family Community;
- restored notification-role mutator authorization behavior;
- cross-tenant read/activation denial.

Supabase advisor parity matches the golden database for all security categories except the expected +2 authenticated SECURITY DEFINER warnings introduced by the two intentionally restored notification mutators. Those functions contain explicit network-admin checks and ordinary-member denial has been proven behaviorally.

Browser/product smoke has now been completed against the disposable candidate and is recorded in `docs/architecture/D12-MANUAL-BROWSER-SMOKE-EVIDENCE.json`.

D12 is **READY FOR CANONICAL BASELINE MATERIALIZATION**. The known Family Explore/Guide route defect (`D12-DEFERRED-ROUTING-001`) is explicitly pre-existing, non-database and non-blocking.

Promotion provenance is recorded in `db/canonical/PROMOTION.json`. The remaining step is mechanical/reproducible: regenerate the proven modular baseline with the committed D12 generator, verify its manifest/checksums, then check those SQL files into `db/canonical/baseline/`. Historical migrations remain immutable.
