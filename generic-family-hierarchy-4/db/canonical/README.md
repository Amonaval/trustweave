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

Run from `generic-family-hierarchy-4`:

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

## Promotion rule

Do not copy generated files into a permanent baseline or change bootstrap behavior until the candidate database passes the D12 parity gates. Historical migrations are not deleted, squashed or rewritten.
