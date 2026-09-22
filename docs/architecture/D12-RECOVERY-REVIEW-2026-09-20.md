# D12 recovery review — 2026-09-20

**Status:** recovery review complete; bounded automated browser parity **BLOCKED_BY_ENVIRONMENT**. No database mutation or bootstrap replay was performed in this review.

## Authority and protected boundary

Reviewed `llm-push` at `3dff4a87c90c9bfaa2b22092af4bf0f14ceb2c47`, the D12 freeze handover, committed bootstrap release, clean replay certification, browser parity handoff, QA wrapper, and latest successful CI run. The golden `OS Network` project (`yyhwcqpzplebittvxzzl`) remained untouched.

## Current projects and read-only checks

- `TrustWeave D12 Candidate` (`blpdjhmtayjkcczqltqi`): **INACTIVE**. Its earlier database behavioral PASS and founder browser smoke remain historical evidence, not a fresh browser run.
- `TrustWeave D12 Clean Replay` (`yqtrkpyyzxzpthklqygs`): **ACTIVE_HEALTHY**. Read-only catalog checks found 167 public tables, 167 with RLS, 981 constraints, 401 indexes, 465 public functions, 97 public/Storage policies, both expected Storage buckets, and both notification-role RPC signatures. It currently has zero Auth users, zero networks, and zero Storage objects.
- `TrustWeave QA DB Replay` (`gbdqujqohhdxqnemlpbc`): **INACTIVE**.

The Clean Replay certification states that this project was populated **before** the final function ACL packaging correction. Its structural/API evidence remains useful, but it is not proof of a final fresh install from the corrected committed bytes. The latest `llm-push` GitHub Actions validation succeeded, including bootstrap integrity, tooling syntax, TypeScript, lint, unit contracts, and production build. CI did not run connected browser parity.

## Browser gate preflight

The required scope remains `housing-society` and `family-association`, with owner/admin/member roles. `qa/run-d12-candidate-parity.mjs` requires a local catalog PASS, a local disposable apply receipt, matching `QA_STAGING_PROJECT_REF`, a candidate-configured app runtime, and seeded test identities before its connected reliability suite and notification-role contract can run.

No candidate-configured application runtime or QA credentials are available in this workspace, and the browser session has no TrustWeave app tab or verified candidate URL. The active Clean Replay has no Auth users or networks for role journeys. The committed `.env.d12-candidate.example` points to Clean Replay, but the QA wrapper still requires `.d12-work/candidate/apply-receipt.json` with status `APPLIED_TO_DISPOSABLE_CANDIDATE`; the committed bootstrap apply runner writes a different `.d12-work/bootstrap-replay/apply-receipt.json` format. Do not bypass this identity guard or relabel an old receipt.

**Result:** no browser journeys were executed; product/browser parity is **NOT VERIFIED** in this review. This is a preflight/environment block, not a failed Housing or Family Community journey.

## Coherent resume path

1. Preserve the inactive earlier candidate and the golden project. Do not replay a full bootstrap over either existing populated candidate.
2. For the final ACL packaging proof, use one genuinely empty disposable project and apply the finalized committed release through its guarded bootstrap path. Verify the resulting catalog/ACLs and record the new project ref in evidence.
3. Align the D12 browser wrapper/promotion evidence contract with the committed bootstrap receipt, while retaining exact candidate/golden ref checks and fail-closed mutation guards.
4. In a local checkout, configure the app and `.env.d12-candidate` for that **same** disposable project, keeping keys and passwords local. Seed only deterministic QA accounts/data there.
5. Run bounded owner/admin/member journeys for the two configured verticals and the notification-role contract; retain the generated reliability and D12 summary files. Classify the already known Family Guide routing defect separately.
6. Reconcile static, catalog, database behavior, browser and bootstrap provenance before the D12-F promotion/closure decision. Do not infer a fresh browser PASS from the earlier manual smoke.

No user secret is requested or recorded in this checkpoint.

## Follow-up checkpoint — QA preflight repair

Commit `2a86bd3b8366bf26912f854af4cc7a343b100d68` added support for the committed-bootstrap receipt alongside the original candidate receipt. It binds the final manifest checksum, fresh-project preflight, recapture project refs and hashes, catalog CSV input hashes, all three PASS layers, and QA project ref before any connected mutation. Eleven focused tests passed locally, including rejection of stale/mismatched evidence; full TrustWeave CI passed. `.env.d12-candidate.example` now uses a placeholder future disposable ref and the bootstrap-replay evidence root, rather than pointing at the older Clean Replay. This fixes the receipt-format blocker identified above; it does not create an app runtime or produce a browser parity PASS.

The release's `CURRENT` pointer and `CANONICAL_CURRENT_STATE` manifest label predate formal D12-F closure. Reconcile that state in the promotion review after fresh ACL and browser proof; do not infer closure from those labels alone.

## Follow-up checkpoint — fresh ACL replay PASS

The connected Supabase SQL path removed the need for a local psql binary or database URL in chat. An initial empty disposable project exposed table ACL drift; commit `ce5eddfbedd2a1ab3a92bbd58ac24ca78e57bfe1` corrected the generator, ten grant files and manifest. The second genuinely empty project `yqwitkoxyrujbzpjwuji` received all 94 direct files and seven Storage owner-context policies. Full structural/security/API golden catalog parity passed with zero differences and warnings; browser and behavioral gates remain open. See `D12-FRESH-REPLAY-2026-09-20.md` for evidence hashes and next steps.
