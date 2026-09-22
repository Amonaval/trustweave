# D12 Browser / Product Runtime Parity Handoff

## Current continuation — 2026-09-20

The original D12 Candidate `blpdjhmtayjkcczqltqi` is now inactive. The active Clean Replay `yqtrkpyyzxzpthklqygs` predates the final ACL packaging correction and has no seeded Auth users. Use **one new empty disposable project** for the final committed-bootstrap ACL proof and this browser gate. Do not replay the full bootstrap on either earlier populated project.

The QA wrapper now accepts committed bootstrap evidence at `.d12-work/bootstrap-replay` when `D12_PARITY_EVIDENCE_ROOT` points there. Run `d12-verify-candidate.py` with `--candidate-root .d12-work/bootstrap-replay` to generate a fresh catalog parity report and bound recapture receipt. The catalog report includes hashes of all four input CSVs. Keep `.env.d12-candidate` local, set its ref and URL to the same new project, and retain its secrets only on the machine running QA. The wrapper rejects mismatched refs, release manifest bytes, nonempty freshness receipts, and stale capture hashes. It cannot certify the current Clean Replay from old receipts.

The previous candidate's manual browser smoke is historical evidence; it is not an automated PASS on the new project. Formal D12-F closure remains open.

## Purpose

This is the final D12-E gate before canonical-promotion review.

Database/catalog/API behavioral parity has already passed on the fresh disposable candidate. This document scopes only the remaining browser/product runtime proof.

## Candidate / golden boundaries

- Golden project: `OS Network` — `yyhwcqpzplebittvxzzl` — read-only.
- Historical candidate: `TrustWeave D12 Candidate` — `blpdjhmtayjkcczqltqi` — inactive. Current target: the next empty disposable project after final bootstrap apply.
- Never point mutating QA at the golden project.
- Never place service-role keys, DB passwords, or connection URLs in Git or chat.

## Scope

Only the configured reliability scope:

- `housing-society`
- `family-association`

Roles:

- owner
- admin
- member

Browser:

- Chromium desktop for primary certification.
- Existing responsive/mobile checks may run where already configured.

## Required runtime guard

The application runtime must be configured to the disposable candidate project.

Before any mutation:

1. `NEXT_PUBLIC_SUPABASE_URL` must resolve to the same new disposable project ref.
2. `QA_STAGING_PROJECT_REF` must equal that new disposable project ref.
3. `QA_MODE=staging`.
4. `QA_ALLOW_MUTATION=true`.
5. The configured project ref must not equal the golden ref `yyhwcqpzplebittvxzzl`.

The existing QA runtime guards already reject production/golden mismatches.

## Browser certification command

Use the existing D12 wrapper once a candidate-configured application runtime is available:

```bash
npm run qa:d12:candidate
```

The wrapper requires catalog parity PASS first, reuses the connected two-vertical reliability suite, runs Playwright/resilient crawl, and executes the restored notification-role behavior proof.

## Minimum product journeys that must pass

### Housing

- authenticated owner enters/activates Housing;
- Housing landing/property snapshot renders;
- owner/admin critical operations surface loads without runtime/API failures;
- member experience renders without admin-only controls becoming available;
- cross-tenant routes/data remain inaccessible.

### Family Community

- authenticated owner enters/activates Family Community;
- Family Community admin snapshot/home renders;
- owner/admin critical operations surface loads without runtime/API failures;
- member experience renders with correct role boundary;
- notification-role admin control can assign/remove an active network member;
- ordinary member cannot manage notification roles.

### Shared

- login/session establishment;
- network switching;
- route/addressability;
- no fatal console/runtime errors in critical journeys;
- no unexpected 401/403/404/500 responses for allowed journeys;
- expected authorization denials remain denials;
- resilient crawl completes for configured scope.

## Evidence required

A PASS requires:

- `qa-results/reliability/SUMMARY.json` = connected certification pass;
- `qa-results/d12-candidate-parity/notification-role-contract.json` = PASS;
- `qa-results/d12-candidate-parity/SUMMARY.json` = `D12_BEHAVIOR_BROWSER_PARITY_PASS`;
- no unresolved critical/high runtime defect in the D12 candidate scope.

## Promotion boundary

After browser parity passes, run:

```bash
python scripts/d12-promotion-gate.py
```

Expected result:

`READY_FOR_CANONICAL_PROMOTION_REVIEW`

That result is review readiness only. It must not automatically rewrite historical migrations or silently promote generated SQL.
