# D12 Clean Replay Certification

Date: 2026-09-20

## Projects

- Golden/live: `yyhwcqpzplebittvxzzl` — **OS Network** — read-only reference.
- Clean replay: `yqtrkpyyzxzpthklqygs` — **TrustWeave D12 Clean Replay** — disposable verification target.
- Previous candidate: `blpdjhmtayjkcczqltqi` — **TrustWeave D12 Candidate** — paused.
- Legacy QA replay: `gbdqujqohhdxqnemlpbc` — **TrustWeave QA DB Replay** — paused.

No credentials, connection strings, customer rows, Auth users, or Storage object contents are recorded here.

## Clean replay state

The clean replay project is active and contains the D12 reconstructed schema with zero rows in all 167 public tables.

Supabase migration history is empty, which is expected because the D12 current-state bootstrap is not historical migration replay.

## Structural/API counts

Verified directly against the clean replay catalog:

- public relations: **167**
- public columns: **1,743**
- public constraints: **981**
- public indexes: **401**
- public functions: **465**
- public triggers: **10**
- public sequences: **6**
- public RLS-enabled tables: **167**
- public policies: **90**
- Storage policies: **7**
- total TrustWeave public + Storage policies: **97**

The function total is intentionally two higher than golden because the canonical baseline restores the two reviewed source contracts missing from the live catalog:

- `set_network_notification_role(text,text,uuid,boolean)`
- `remove_network_notification_role(text,uuid)`

The golden-only/live-extra `reconcile_network_media_usage(uuid)` contract is also present in the clean replay baseline.

## Storage parity

Verified buckets:

- `community-media` — private, 1 MiB file-size limit
- `profile-photos` — private, 1 MiB file-size limit

Verified seven Storage object policies:

- authenticated can delete community media
- authenticated can delete own profile photos
- authenticated can update own profile photos
- authenticated can upload community media
- authenticated can upload profile photos
- visibility-aware community media reads
- visibility-aware profile photo reads

## Golden vs clean replay deterministic catalog fingerprints

Exact match:

- relations
- columns
- indexes
- public + Storage policies
- triggers
- sequences
- application table grants
- all golden public function definitions/signatures/config/security properties after excluding only the two intentional notification-role repairs

The aggregate constraint fingerprint initially differed because the whole-catalog aggregation order was not globally unique. This was isolated by table. **All 167 public tables have identical per-table constraint counts and deterministic constraint fingerprints between golden and clean replay.** Therefore no constraint schema difference remains.

## Repository/bootstrap evidence

The permanent release is:

`supabase/bootstrap/releases/2026-09-20-d12/`

It contains:

- 95 checksum-pinned SQL files
- 94 ordinary database-context files
- 1 separate hosted-Supabase Storage owner-context file
- `manifest.json`
- generated `APPLY_ORDER.txt`

Repository integrity is enforced by:

- `scripts/d12-validate-bootstrap.py`
- `scripts/d12-apply-bootstrap.py`
- TrustWeave CI

The clean-replay verification confirms the materialized Git baseline corresponds to the D12 current-state architecture.

## Advisor note

Supabase advisors report many expected zero-traffic warnings such as unused indexes and tables with RLS enabled but no direct policies. These are not classified as D12 replay defects merely because they appear on a fresh database. They should be evaluated against golden/product access architecture separately; D12 parity evidence is based on deterministic catalog comparison and behavioral/product verification, not on eliminating every advisor informational/performance warning.

## Known non-database issue

The Family Explore/Guide route issue at paths such as:

`network/<network-id>/guide`

was observed before D12 migration work and remains intentionally deferred until SQL/bootstrap refinement is closed. It is not attributed to D12 database reconstruction.
