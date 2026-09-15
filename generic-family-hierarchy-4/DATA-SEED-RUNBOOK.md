# TrustWeave — Final Launch Data Seed Runbook

> **Hotfix prerequisite:** before using this runbook after the first seeded rehearsal, apply migrations through **114_final_launch_runtime_contract_repair.sql** and use the runtime-hotfix FULL baseline.
Use this only for the supplied synthetic final-launch datasets. The workflow persists through real product APIs and is intentionally guarded.

## Prerequisites
1. Deploy the exact launch-candidate FULL ZIP.
2. Restore dependencies from `package-lock.json` and pass lint/static/build.
3. Apply all migrations through `114_final_launch_runtime_contract_repair.sql` to the approved staging/pilot Supabase project.
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
11. Completion must report **0 errors**. Review constrained warnings before any presentation.
12. Refresh/open the populated network and inspect flagship surfaces.

## Idempotency proof
Run the same dataset again without changing it. Expected result: unchanged rows skip and the second run reports **0 created** (or equivalent no-duplicate outcome). Verify `get_launch_demo_seed_lineage` contains stable source row mappings.

## Residential verification anchors
Verify coherent data in Home, My Home, Residents, Notices, Complaints, Amenities, Maintenance & Dues, Committee & Meetings, Elections & Voting, Visitors & Security, Media & Storage, Society Structure, Community, Neighbours, Guide & Help and Manage Society.

Look specifically for mixed dues states, open/in-progress/resolved complaints, current notices, bookings, committee actions, compliance, visitors, one active governance/voting story, community posts/events and private media.

## Family Community verification anchors
Verify Home, Me & My Family, Families, Community Life, Guide & Help, Funds & Collections, Elections & Voting, Media & Storage, Family Structure, Family & Community Links, Build Together and Manage Community.

Look specifically for annual membership/renewal states, 20 family records, household/kinship structure, committee roles, event/RSVP behavior, funds, election/poll, posts/comments, memories and invitations/contribution prompts.

## Warnings that are not silent failures
The product stores RSVP and group membership against authenticated accounts. Synthetic directory people are not converted into fake auth users. The seeder records these source rows as constrained warnings where they cannot be represented faithfully by current safe APIs.

## Cleanup
For certification networks, use the normal permanent network deletion flow after evidence is captured. There is deliberately no launch-data global reset RPC.
