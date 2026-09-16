# Two-Vertical Reliability Defect Ledger

**Run:** 2026-09-16 connected reliability  
**Scope:** `housing-society`, `family-association` × owner/admin/member

| Finding | Classification | Root cause | Repair | Regression evidence | Status |
| --- | --- | --- | --- | --- | --- |
| Family photo post reports success before the card assertion | Harness defect | Persistence helper raced the success banner against the refreshed card and treated any message as failure | Continue waiting through success messages; fail early only for failure-like product messages | `reliability-remediation-contracts.test.mjs`; existing journey 27 | Source repaired; connected rerun pending |
| Housing notice publishes but never appears | Reproducible product/data-contract defect | Migration 121 narrowed `hs4_get_operations_snapshot()` and returned empty notices, amenities and bookings | Additive migration 122 restores the complete snapshot while retaining complaint repair fields | Migration contract test; existing journey 28 | Source repaired; migration apply + connected rerun pending |
| `get_network_notification_roles` returns PostgREST 404 | Stale/missing staging RPC contract | Connected schema lacks the client-called function even though the historical migration defines it | Migration 122 recreates the authorized function and reloads PostgREST schema | Migration contract test; role crawl | Source repaired; migration apply + connected rerun pending |
| Housing owner landing contrast failures | Reproducible accessibility defect | `#6d786f` measured 4.10–4.37:1 on light tinted surfaces | Add `--muted-contrast:#59645d` to the measured small-text surfaces | Contract test; Axe suite 60 | Source repaired; connected Axe rerun pending |
| Family Community owner landing contrast failure | Reproducible accessibility defect | Announcement copy measured 4.30:1 | Use the accessible muted contrast token | Contract test; Axe suite 60 | Source repaired; connected Axe rerun pending |
| Family Community/admin resilient shard fails twice | Unclassified reproducible evidence | Shard log/result was not included in the partial artifacts; missing notification-role RPC is a plausible shared dependency but is not assumed proven | Preserve as open and inspect the next focused rerun evidence | Resilient crawler shard | Open pending rerun |

No RLS, tenant isolation, role boundary, or historical migration was weakened or rewritten.
