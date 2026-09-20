# D12 Browser / Product Runtime Parity Handoff

## Current continuation — 2026-09-20

The final fresh replay target is `TrustWeave D12 Final ACL Proof` (`yqwitkoxyrujbzpjwuji`). Its 94 direct SQL files and seven owner-context Storage policies are applied, and the structural/security/API catalog comparator passed. The earlier Clean Replay `yqtrkpyyzxzpthklqygs` and first ACL diagnostic project `leeupnpnyoblfsdasbkp` are paused. Use the **final project** for this browser gate; do not replay the bootstrap on it.

The QA wrapper accepts the reviewed managed-SQL receipt (`trustweave-d12-managed-sql-apply-receipt-v1`) and the historical direct-bootstrap receipt. Extract `D12-FRESH-REPLAY-EVIDENCE-2026-09-20.zip` at the repository root so the receipt, parity report and recapture files land under `.d12-work/bootstrap-replay/`. Set `D12_PARITY_EVIDENCE_ROOT=.d12-work/bootstrap-replay`. The wrapper checks the committed manifest bytes, the exact reviewed project and source commit, empty-project freshness, apply provenance, all catalog layers and the actual candidate CSV bytes. The original golden supplement hash is accepted only with its fixed promoted manifest fingerprint.

Preflight passed locally against the real archived receipt, report, recapture and CSV bytes; 23 focused tests passed. A checkout and dependencies are now available, and the final project is healthy with zero Auth users/networks. **Connected behavior/browser parity has not run:** direct candidate API requests from this workspace time out, its dashboard browser session is at sign-in, and no candidate service key/local QA environment is available. The Supabase plugin can query the disposable database but cannot supply the service key required by the existing deterministic Auth seed. The wrapper now fails before lengthy static/build work if keys are absent or the candidate API is unreachable (8-second timeout). Configure the candidate app runtime in an environment that reaches its API before executing the command below. Never share service-role keys or database passwords in Git or chat. The earlier candidate's manual browser smoke is historical evidence and does not certify this final project. D12-F closure remains open.

## Purpose

This is the final D12-E gate before canonical-promotion review.

Database/catalog/API behavioral parity has already passed on the fresh disposable candidate. This document scopes only the remaining browser/product runtime proof.

## Candidate / golden boundaries

- Golden project: `OS Network` — `yyhwcqpzplebittvxzzl` — read-only.
- Current disposable candidate: `TrustWeave D12 Final ACL Proof` — `yqwitkoxyrujbzpjwuji` — active. Earlier replay projects and historical candidate are not QA targets.
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

1. `NEXT_PUBLIC_SUPABASE_URL` must resolve to the final disposable project ref `yqwitkoxyrujbzpjwuji`.
2. `QA_STAGING_PROJECT_REF` must equal `yqwitkoxyrujbzpjwuji`.
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

The promotion gate recognizes the reviewed managed-SQL replay, validates the committed bootstrap and recapture bytes, and requires both connected reliability and notification-role results. It returns `NOT_READY` while this final project's connected evidence is absent. Four focused promotion guard tests cover a complete isolated fixture, absent browser result, altered manifest receipt and altered capture bytes.

That result is review readiness only. It must not automatically rewrite historical migrations or silently promote generated SQL.
