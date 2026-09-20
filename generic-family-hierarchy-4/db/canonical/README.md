# D12 canonical database reconstruction

This directory is the **candidate current-state database source**, not a replacement for `supabase/migrations/001..123` yet.

## Contract

- `supabase/migrations/` stays immutable upgrade history.
- `modules.json` owns the current modular dependency graph.
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

The generator writes ordered SQL modules plus a manifest/checksums. Keep raw captures outside Git. Review generated SQL before applying it to a **new disposable Supabase project**.

## Promotion rule

Do not copy generated files into a permanent baseline or change bootstrap behavior until the candidate database passes the D12 parity gates. Historical migrations are not deleted, squashed or rewritten.
