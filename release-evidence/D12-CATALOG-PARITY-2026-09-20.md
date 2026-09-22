# D12 Clean Replay — Catalog Parity Evidence

Date: 2026-09-20
Branch: `llm-push`

## Safety boundary

- Golden/live project: `OS Network` (`yyhwcqpzplebittvxzzl`) — read-only throughout this verification.
- Candidate-of-record: `TrustWeave D12 Clean Replay` (`yqtrkpyyzxzpthklqygs`), region `ap-south-1`.
- Candidate contains zero application rows at the catalog verification checkpoint.
- No production/customer data, Storage object contents, passwords, service-role keys, or other secrets were copied.
- Historical migrations remain immutable.

## Candidate replay state

Direct Supabase catalog verification found:

- 167 public application tables.
- 1,743 columns.
- 981 constraints.
- 401 indexes.
- 10 triggers.
- 90 public RLS policies plus 7 Storage policies.
- 6 public sequences.
- 5 installed extensions matching golden by name/schema.
- 2 expected private Storage buckets with matching configuration.
- 463 common public functions matching golden definitions.
- 2 candidate-only reviewed drift repairs:
  - `set_network_notification_role(text,text,uuid,boolean)`
  - `remove_network_notification_role(text,uuid)`
- `reconcile_network_media_usage(uuid)` remains present in both golden and candidate.

## Structural parity

Exact fingerprints matched for relations, columns, indexes, triggers, sequences, extensions, public policies, Storage policies, Storage bucket configuration, and Storage RLS state.

All 981 constraint names/types are present on both sides. PostgreSQL deparsed 173 CHECK expressions differently after replay, exclusively changing equivalent array/cast rendering. A targeted normalization proved:

- raw CHECK representation differences: 173
- non-CHECK differences: 0
- semantic differences after cast/deparser normalization: 0

This is representation drift, not behavioral constraint drift.

## Security / ACL parity

The first replay exposed a D12 generator issue: replaying a non-grantable owner ACL to `postgres` via `GRANT` materialized explicit grant-option bits. The candidate was repaired by removing only those grant-option bits while preserving privileges.

After repair:

- normalized relation privilege rows: golden 3,817 / candidate 3,817
- relation ACL fingerprint: exact match
- normalized common-function privilege rows: golden 1,874 / candidate 1,874
- common-function ACL fingerprint: exact match
- public schema ACL: semantic exact match
- public/storage RLS policy fingerprints: exact match

The two candidate-only notification mutators intentionally grant EXECUTE to `authenticated` and `service_role`, with PUBLIC/anon revoked.

Supabase security-advisor categories match golden for application-schema parity. The candidate reports 446 authenticated-executable SECURITY DEFINER functions versus golden 444, explained exactly by the two reviewed candidate-only repairs. The fresh candidate does not inherit the golden project's Auth leaked-password setting warning; that is project configuration, not application schema.

## Tooling corrections committed

- `scripts/d12-compare-catalogs.py`: restored missing `re` import required by the already-reviewed CHECK-expression normalizer.
- `scripts/d12-reconstruct-canonical.py`: normalize explicit owner grant-option state after relation/sequence ACL replay so a future fresh replay reproduces `pg_class.relacl` instead of requiring manual cleanup.

Generator ACL fix commit: `b4a01f5b34871307a210704ea9c4e8c6b79e0dfe`.

## Gate status

D12 structural/security/API catalog parity is verified on the disposable Clean Replay candidate, with the two intentional repaired RPCs as the only API additions.

The next required gate is behavioral/browser parity for exactly:

- verticals: `housing-society`, `family-association`
- roles: `owner`, `admin`, `member`
- targeted proof: notification-role assign/read/deny/remove contract
- configured Playwright reliability + resilient crawl

The existing seed runner requires `SUPABASE_SERVICE_ROLE_KEY` to create disposable Supabase Auth users. That secret must remain local/user-managed and must not be pasted into chat or committed to Git.

Canonical promotion remains blocked until behavioral/browser parity passes.
