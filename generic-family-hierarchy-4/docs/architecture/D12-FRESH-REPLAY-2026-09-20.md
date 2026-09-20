# D12 final fresh replay — 2026-09-20

**Status:** fresh bootstrap and structural/security/API catalog parity **PASS**. Behavioral and connected browser parity remain open; D12-F is not closed.

## Provenance and protected boundary

- Golden `OS Network` (`yyhwcqpzplebittvxzzl`) remained read-only and untouched.
- New empty Personal project `TrustWeave D12 Final ACL Proof` (`yqwitkoxyrujbzpjwuji`, `ap-south-1`) had zero public relations, sequences and functions before apply.
- Corrected release commit: `ce5eddfbedd2a1ab3a92bbd58ac24ca78e57bfe1`; [CI PASS](https://github.com/Amonaval/trustweave/actions/runs/35525493654), including checksum validation of all 95 SQL files. Manifest SHA-256: `771e45c7443a324a9390101a9de04395001e7a4dcd0ceb661439e0ed0ed3f42a`.
- Supabase managed SQL execution applied 94 direct files in manifest order across **eight ordered transactions**. The separate seven-policy Storage owner-context file was applied through migration `d12_final_storage_owner_context`. This was not a psql or GitHub Actions run. No database URL or password was provided in chat or committed.
- The first disposable ACL diagnostic project (`leeupnpnyoblfsdasbkp`) and earlier Clean Replay (`yqtrkpyyzxzpthklqygs`) are paused. Do not replay the full bootstrap on these populated projects.

## Catalog result

| Gate | Result |
|---|---:|
| Public relations / functions / sequences | 167 / 465 / 6 |
| Public tables with RLS / public and Storage policies / buckets | 167 / 97 / 2 |
| Structural differences | 0 — PASS |
| Security differences | 0 — PASS |
| API contract differences | 0 — PASS |
| Comparator warnings | 0 |

The repo's `scripts/d12-compare-catalogs.py` compared new read-only candidate captures to the founder's golden CSVs. SHA-256: golden primary `074f89728fce44712b81627ef5f0dbcae76b6627ba321bd11720f285e9c0acc1`; original corrected golden supplement `0ce6507dc57ae79d96820800f76b5b38ba91e1be82004b3f51591295aaed4743`; final candidate primary `51fdb38f089177d94565d62838938603a12c7be5b3d3526cd60523354967f69e`; final candidate supplement `2af0382c87fd35e50750014599f6c70ad975dd36b71853b343480d769cd22510`. Comparator JSON SHA-256: `c6eb3c8c7a6ab9ce62177df1642e5c2acd5d80e18c6fa56d71f08e40328a6551`. Complete candidate captures, report and honest managed-SQL receipt are archived outside Git as `D12-FRESH-REPLAY-EVIDENCE-2026-09-20.zip`. The promoted manifest carries a separate supplement provenance fingerprint; the original golden input hash used for this comparison is stated above.

## Recovery finding

The first fresh project exposed ACL drift on all 167 tables: the packaged grants omitted PostgreSQL 17 `MAINTAIN` and retained owner grant-option bits. The diagnostic project established the exact correction against every captured table ACL. Commit `ce5eddf` updated the generator, ten table-grant files and manifest hashes. The final project was created *after* that commit and replayed empty. Its full comparator passes all three layers.

Supabase security advisors still report [RLS tables without policies](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy) (103 INFO), [mutable function search paths](https://supabase.com/docs/guides/database/database-linter?lint=0011_function_search_path_mutable) (10 WARN), and [anon](https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable) / [authenticated](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable) SECURITY DEFINER execution (444 / 446 WARN). Review these separately; catalog parity did not widen privileges to suppress them.

## Next gate

Use **the same final project** for deterministic QA accounts, the two verticals `housing-society` and `family-association`, owner/admin/member behavior, the notification-role contract and bounded connected browser journeys. The QA preflight now recognizes the reviewed managed-SQL receipt and original golden supplement hash with fixed manifest/project-ref/capture checksum guards; it does not mislabel this as the psql runner's output. The actual evidence archive and 23 focused tests passed the preflight. The connected run awaits a candidate-configured app checkout, local QA environment and server. Reconcile five-layer evidence before D12-F promotion. No browser or behavioral PASS is claimed here.
