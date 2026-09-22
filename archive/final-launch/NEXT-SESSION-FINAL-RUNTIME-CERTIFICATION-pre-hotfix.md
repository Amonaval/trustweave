# NEXT SESSION — TrustWeave Final Runtime Certification & Pilot Go/No-Go

Use `TRUSTWEAVE-LAUNCH-CANDIDATE-FULL.zip` as the **only source of truth**. Do not merge older checkpoints and do not add unrelated features.

## Objective
Convert the source-closed launch candidate into a runtime-certified go/no-go release. The engineering implementation is already present; this session is proof, targeted fixes only if a required gate fails, and final launch decision.

## Execute sequentially
1. Restore exact dependencies from `package-lock.json`.
2. Run `npm run lint:trustweave`, `npm run validate:static`, `npm run build`, `npm run validate:final-launch`, `npm run qa:db-static`. Fix any real blocker before continuing.
3. Apply all pending migrations through `114_final_launch_runtime_contract_repair.sql` to an approved staging QA project.
4. Run `qa/e2e/25-final-launch-discovery.spec.ts` desktop + mobile.
5. With `TW_QA_FINAL_LAUNCH_SEED=1`, run `qa/e2e/26-final-launch-seed-runtime.spec.ts` against fresh temporary Residential and Family Community networks.
6. Manually rehearse the roles in `PILOT-DEMO-RUNBOOK.md`: anonymous visitor, Chairman/admin/resident, Community President/admin/representative/member, platform owner, and older/non-technical mobile user.
7. Complete every mandatory item in `RUNTIME-VERIFICATION-CHECKLIST.md`, including exact notification deep links, Push controls, private media and cross-network isolation.
8. If a gate fails, make the smallest launch-safe fix, rerun impacted regression/source/runtime gates, update docs and repackage FULL/AFFECTED ZIPs.
9. Update `LAUNCH-READINESS-REPORT.md` with evidence and explicitly record **GO** or **NO-GO**.

## Binding rule
Do not call launch-ready until lint has 0 errors, production build passes, both fresh persisted seed journeys pass idempotently, headed/mobile flagship walkthroughs pass, and no known launch-blocking defect remains.
