# TrustWeave Bootstrap Release — 2026-09-20 D12

Status: **approved for materialization from the D12-proven canonical baseline**.

This directory is the permanent executable fresh-database package for the first D12 canonical baseline.

The SQL payload is generated from the promoted canonical model. Do not manually reconstruct it from historical migrations.

## Release cut point

Historical migration state covered: through the accepted D12 source state around migrations `001..123`.

Future schema evolution continues through new incremental migrations after that historical cut point.

## Apply model

Use `APPLY_ORDER.txt` and `manifest.json`.

The package must only be applied to a fresh empty Supabase project.

See ../../DEVELOPER_GUIDE.md.
