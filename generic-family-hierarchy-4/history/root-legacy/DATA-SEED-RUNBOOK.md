# TrustWeave — Final Launch Data Seed Runbook

> **Mission 1 prerequisite:** apply migrations through **115_mission1_runtime_seed_integrity.sql** to the same Supabase project before rerunning launch seeding. Migration 115 builds on the runtime repair in migration 114 and adds recoverable lineage, structured seed diagnostics, bulk-safe relationship seeding, ballot ordering recovery and the Community photo-upload 22023 repair.
Use this only for the supplied synthetic final-launch datasets. The workflow persists through real product APIs and is intentionally guarded.

## Prerequisites
1. Deploy the exact launch-candidate FULL ZIP.
2. Restore dependencies from `package-lock.json` and pass lint/static/build.
3. Apply all migrations through `115_mission1_runtime_seed_integrity.sql` to the approved staging/pilot Supabase project. Do not skip migration 114.
4. Sign in as network admin/owner or platform owner.
5. Create/select a **fresh** `housing-society` or `family-association` network. Prefer names containing `Demo`, `Pilot`, `Sample`, `Sandbox` or `Test`.

## Bundled sources
### Residential
- `public/launch-demo/residential-25-flats.json`
- `public/launch-demo/residential-25-flats.xlsx`
- version: `trustweave-launch-residential.v1`

### Family Community
- `public/launch-demo/family-community-20-families.json`
- `public/launch-demo/family-community-20-families.xlsx`
- version: `trustweave-launch-family-community.v1`

## Safe UI workflow
1. Open the active real network.
2. Go to **Manage Society / Manage Community → Admin**.
3. Find **Final launch data**.
4. Keep the bundled dataset or upload the matching final `.json` / `.xlsx`.
5. Review the dry-run row/create/update/skip/error summary. **Do not commit if reference errors are non-zero.**
6. Type the exact active network name.
7. Confirm that the source is synthetic showcase data.
8. If the network name does not look like a demo/pilot, the UI requires a second explicit override. Avoid that override for certification; use a fresh clearly named QA network.
9. Click **Authorize this dataset**. Authorization is tied to the active network + dataset version.
10. Click **Persist launch dataset** and monitor progress.
11. Completion must report **0 runtime/database errors**. Constrained warnings are shown separately and do not count as successful persistence.
12. Download the **seed report JSON** from the completion panel. Keep it whenever a run has an error; it records seed run id, section, source row reference, operation, error code, message, details, hint and retryability.
13. Refresh/open the populated network and inspect flagship surfaces.

## Idempotency proof
Run the same dataset again without changing it. Expected result: unchanged terminal rows skip and the second run reports **0 accidental creates**. Rows previously marked `partial` or `error` are intentionally retried. Verify `get_launch_demo_seed_lineage` contains stable source row mappings and that a create followed by a failed state transition keeps its remote id for recovery rather than creating a duplicate on the next run.

## Residential verification anchors
Verify coherent data in Home, My Home, Residents, Notices, Complaints, Amenities, Maintenance & Dues, Committee & Meetings, Elections & Voting, Visitors & Security, Media & Storage, Society Structure, Community, Neighbours, Guide & Help and Manage Society.

Look specifically for mixed dues states, open/in-progress/resolved complaints, current notices, bookings, committee actions, compliance, visitors, one active governance/voting story, community posts/events and private media.

## Family Community verification anchors
Verify Home, Me & My Family, Families, Community Life, Guide & Help, Funds & Collections, Elections & Voting, Media & Storage, Family Structure, Family & Community Links, Build Together and Manage Community.

Look specifically for annual membership/renewal states, 20 family records, household/kinship structure, committee roles, event/RSVP behavior, funds, election/poll, posts/comments, memories and invitations/contribution prompts.

## Warnings that are not silent failures
Warnings are persisted and exported separately from runtime/database errors.

For the supplied Family Community dataset, **113 first-run constrained skips are currently intentional and explainable**:
- 54 inverse `Child` relationship rows are skipped because the canonical `Parent` edge already represents the same family relationship;
- 39 RSVP source rows cannot be represented as separate attendees because synthetic directory people are deliberately not fabricated as authentication accounts;
- 20 group-membership source rows have the same authenticated-account constraint.

Those 113 constraints must not be confused with seed errors. Any additional error row is actionable and should be investigated from the downloaded report.

The Family relationship seed path now calls the secured relationship RPC directly under explicit launch-dataset authorization rather than the interactive HTTP command endpoint. This avoids the 40-calls/minute browser-command burst limit that previously produced the characteristic `40 created` on each retry.

Ballots are now persisted in draft, their options are seeded/adopted, and only then is the requested open/closed state applied. Recoverable remote ids are checkpointed before state transitions so a later failure does not create duplicate ballots/posts/operational rows on rerun.

## Cleanup
For certification networks, use the normal permanent network deletion flow after evidence is captured. There is deliberately no launch-data global reset RPC.
