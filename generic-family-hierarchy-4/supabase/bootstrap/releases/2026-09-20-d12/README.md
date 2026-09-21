# TrustWeave Bootstrap Release — 2026-09-20 D12

Status: **materialized canonical current-state baseline; fresh-from-Git replay certification pending**.

This directory is the permanent executable fresh-database package for the first D12 canonical baseline.

The SQL payload was checksum-materialized from the promoted D12 canonical model. Do not manually reconstruct it from historical migrations or edit generated SQL in place.

## Release cut point

Historical migration state covered: through the accepted D12 source state around migrations `001..123`.

Future schema evolution continues through new incremental migrations after that historical cut point.

## Integrity contract

Before any apply, run:

```bash
python scripts/d12-validate-bootstrap.py
```

The validator fails closed unless:

- all 95 SQL files are present;
- every SQL SHA-256 matches `manifest.json`;
- the 94 direct database-context files and one Storage owner-context file exactly partition the release;
- apply order is phase-first;
- reviewed D12 object counts/contracts remain unchanged;
- no credential-like content is embedded.

CI runs this validator on every relevant repository change.

## Fresh disposable apply

The guarded local runner is:

```bash
export D12_BOOTSTRAP_DATABASE_URL='...keep local...'
python scripts/d12-apply-bootstrap.py \
  --candidate-project-ref <fresh-project-ref> \
  --golden-project-ref yyhwcqpzplebittvxzzl \
  --confirm APPLY-D12-BOOTSTRAP-TO-FRESH-DISPOSABLE
```

The runner refuses the golden project, verifies the database URL/project-ref match, validates this release, and refuses a target that already contains public relations/functions/sequences.

It applies only `manifest.json.direct_apply_order` in one transaction. The Storage owner-context file is intentionally separate and must be executed through the hosted Supabase owner/platform context before parity certification.

## Apply model

Use `APPLY_ORDER.txt` and `manifest.json`.

The package must only be applied to a genuinely fresh disposable Supabase project.

A successful SQL apply is **not** enough to certify the release. D12 requires structural, security, API/contract, behavioral and product/browser parity on a clean replay.

See `../../DEVELOPER_GUIDE.md`.
