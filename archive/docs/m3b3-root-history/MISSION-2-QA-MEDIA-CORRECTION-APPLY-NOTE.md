# Mission 2 — QA + Media Runtime Correction Apply Note

Baseline: `TRUSTWEAVE-MISSION-2-SLOW-USER-REGRESSION-FULL.zip`.

## Apply

1. Overlay every file from `TRUSTWEAVE-MISSION-2-QA-MEDIA-CORRECTION-AFFECTED.zip` onto that baseline.
2. Delete every path listed in `MISSION-2-QA-MEDIA-CORRECTION-REMOVED-FILES.txt`.
3. Apply Supabase migration `116_mission2_media_membership_runtime_repair.sql` after migrations through 115.
4. Restore dependencies from `package-lock.json` and run the normal lint/type/build gates.
5. Run `npm run qa:mission2:headed` on Windows/macOS/Linux, or `npm run qa:mission2:slow` for the slower 1-second pace.

## What this correction closes

- responsive navigation in the fresh-seed runtime tests instead of clicking a hidden desktop Admin control;
- malformed Playwright callback signatures and type-only imports across QA;
- accidental root duplicate of `16-phase2-representative-capabilities.spec.ts`;
- optional `notes` TypeScript errors in Phase 4D business-rule tests;
- stricter media preflight/storage authorization using explicit path actor + active membership, including safe creator-membership repair;
- Mission 2 crawl coverage across all released verticals, every instrumented owner navigation surface, and the existing broad regression pack;
- Windows-safe Mission 2 headed/slow commands.
