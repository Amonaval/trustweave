# Mission 2 QA Harness Correction — Apply Note

Baseline: `TRUSTWEAVE-MISSION-2-QA-MEDIA-CORRECTION-FULL.zip`.

Overlay all files from this affected package, then remove any paths listed in `REMOVED-FILES.txt` (none in this correction).

No new database migration is introduced. The environment must already include migrations through 116.

After applying, stop any stale dev server unless you intentionally set `QA_REUSE_SERVER=true`, then run `npm run qa:mission2:headed`.
