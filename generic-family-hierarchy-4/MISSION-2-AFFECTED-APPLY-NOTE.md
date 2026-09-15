# Mission 2 AFFECTED Overlay — Apply Note

Apply `TRUSTWEAVE-MISSION-2-SLOW-USER-REGRESSION-AFFECTED.zip` only over the exact Mission-1 FULL baseline:

`TRUSTWEAVE-MISSION-1-RUNTIME-SEED-INTEGRITY-FULL.zip`

1. Overlay all files from the AFFECTED ZIP, preserving paths.
2. Remove every path listed in `MISSION-2-REMOVED-FILES.txt`.
3. Do not copy `node_modules`, `.next`, Playwright results or local environment secrets.
4. Restore dependencies from the committed lockfile.
5. Apply migrations through 115 to approved staging.
6. Run `npm run validate:mission2`, then `npm run qa:mission2`.

The FULL Mission-2 ZIP is the preferred new source of truth. The AFFECTED package exists for review/application convenience and is verified against the FULL tree.
