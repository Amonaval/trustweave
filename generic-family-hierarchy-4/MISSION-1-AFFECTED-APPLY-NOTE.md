# TrustWeave Mission 1 — Affected Overlay Apply Note

Baseline: `TRUSTWEAVE-LAUNCH-RUNTIME-UX-CLOSURE-FULL.zip`

## Apply

1. Overlay the contents of `TRUSTWEAVE-MISSION-1-RUNTIME-SEED-INTEGRITY-AFFECTED.zip` on the baseline project root, preserving paths.
2. Remove the root files listed in `MISSION-1-REMOVED-FILES.txt` (their historical copies are retained under `archive/runtime-hotfix/`).
3. Apply Supabase migrations in chronological order. For an environment already at migration 114, apply `supabase/migrations/115_mission1_runtime_seed_integrity.sql`.
4. Follow `MISSION-1-APPLY-RETEST-RUNBOOK.md` for persisted-runtime verification.

Do not copy only the migration: Mission 1 includes seed-runner/idempotency, diagnostics, i18n and documentation changes as well.
