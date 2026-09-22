# Root Markdown History

This directory is the single landing zone for Markdown documents removed from the repository root during the autonomous-company cleanup. These files are preserved for traceability and historical evidence; they are **not current authority** unless a current canonical document explicitly points to one.

Current authority starts at `AI-START-HERE.md`.

## History model

- `history/` is the single discovery and taxonomy layer for historical material.
- `history/root-legacy/` contains documents removed from the root and pre-reset snapshots.
- `archive/` is a byte-stable compatibility store, not a second authority surface. Established source gates and old manifests bind to its paths, so moving it would destroy reproducible historical evidence. New historical material must be indexed from `history/` and must not create a new competing archive taxonomy.
- `release-evidence/` contains generated, candidate-bound machine evidence and is not narrative history.

The M3-C preflight inventory is recorded in `history/M3-C-PREFLIGHT-HISTORY-INVENTORY.md`.

## Preserved root documents

- `AIDLC-OPERATING-RULE.md`
- `ARCHIVE-INDEX.md`
- `CODEBASE-UPDATE-RULE.md`
- `CODEBASE.md`
- `DATA-SEED-RUNBOOK.md`
- `DEPLOY.md`
- `FINAL-RELEASE-MANIFEST.md`
- `GENERIC-CAPABILITY-UTILIZATION-RULE.md`
- `LAUNCH-READINESS-REPORT.md`
- `MISSION-1-APPLY-RETEST-RUNBOOK.md`
- `MISSION-1-RUNTIME-SEED-INTEGRITY-CLOSURE.md`
- `MISSION-2-AUTOMATION-RUNBOOK.md`
- `MISSION-2-CLOSURE-HANDOFF.md`
- `MISSION-2-SLOW-USER-REGRESSION-CLOSURE.md`
- `MISSION-DOCUMENTATION-RULE.md`
- `MODEL-SELECTION-RULE.md`
- `PILOT-DEMO-RUNBOOK.md`
- `RUNTIME-VERIFICATION-CHECKLIST.md`
- `STATIC-ANALYSIS-HARDENING.md`
- `SUPABASE-SETUP-GUIDE.md`
- `VALIDATION.md`
- `VERCEL-SETUP-GUIDE.md`


## M3-C0 live-document snapshots

The following snapshots preserve the verbose pre-M3-C0 live root documents before they were rewritten into compact control documents:

- `PRE-M3C0-README.md`
- `PRE-M3C0-CURRENT-STATE.md`
- `PRE-M3C0-MISSION-STATUS.md`
- `PRE-M3C0-ROADMAP.md`
