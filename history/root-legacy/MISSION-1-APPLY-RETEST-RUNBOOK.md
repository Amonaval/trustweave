# TrustWeave — Mission 1 Apply & Retest Runbook

Use the Mission 1 FULL baseline or apply the Mission 1 AFFECTED overlay exactly to `TRUSTWEAVE-LAUNCH-RUNTIME-UX-CLOSURE-FULL.zip`.

## 1. Database apply — mandatory
Apply all pending Supabase migrations through:

`115_mission1_runtime_seed_integrity.sql`

Migration 115 assumes the prior runtime repair in migration 114 already exists. Apply migrations in chronological order; do not run only selected function fragments. The migration finishes with a PostgREST schema-cache reload notification.

## 2. Community photo-post retest
As a real member/admin of the active Community network:
1. Open Community.
2. Create a normal post with a small JPG/PNG photo.
3. Verify the compressed upload succeeds without SQLSTATE `22023`.
4. Verify the post persists.
5. Verify the media is bound to the post, renders after refresh and remains private to authorized network members.
6. Delete/archive through normal UI if desired; do not manipulate Storage directly.

If this fails, capture the exact Supabase error code/message and the object path prefix (do not share secrets/tokens).

## 3. Family Community seed retest
Use the same synthetic launch dataset and the same authorized demo network unless you intentionally want a fresh proof.
1. Run the seed once after migration 115.
2. Completion should have **0 unexplained errors**. Known constraints appear as warnings, not errors.
3. Click **Download seed report** and retain the JSON if any error remains.
4. Run the identical dataset again.
5. The unchanged rerun must not create duplicates. `partial`/`error` rows may retry; terminal rows should skip.

### Expected constrained warnings for the supplied full Family Community dataset
- 54 inverse Child relationship rows;
- 39 RSVP rows that cannot become separate authenticated attendees;
- 20 group-membership rows with the same auth-account constraint.

Total: 113 known constraints. Any additional **error** is actionable.

## 4. Housing seed retest
Repeat the same two-run proof for Housing:
- first run completes with 0 unexplained errors;
- second unchanged run creates no accidental duplicates;
- complaints, bookings, billing cycles, governance actions/resolutions, visitors, move/renovation requests, posts, ballots and ballot options retain stable lineage through any recoverable state transition.

Download the seed report if any error remains.

## 5. Prior runtime repair regression
Recheck the five migration-114 paths as part of the same environment:
- Housing operations snapshot loads;
- Funds loads without `a.type` SQL failure;
- explicit **Open Voting** opens immediately;
- mention routing resolves;
- private media authorization works for a network the signed-in user belongs to.

## 6. Source/dependency checks
In a dependency-enabled environment run:
```bash
npm ci
npm run lint:trustweave
npm run validate:static
npm run build
npm run validate:mission1
npm run validate:final-launch
```
Do not waive lint/build failures.

## 7. What to send back if a seed still fails
Send the downloaded `trustweave-seed-report-*.json`. It contains the run id and row-level section/ref/operation/code/message/details/hint needed to fix the actual product contract without guessing from an aggregate count.
