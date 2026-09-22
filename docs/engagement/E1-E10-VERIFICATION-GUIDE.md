# Engagement E1–E10 — Verification Guide

**Baseline:** Engagement program closed through E10 at source-gate level.

## Migration order
Apply sequentially after the existing baseline:

`103 → 104 → 105 → 106 → 107 → 108 → 109 → 110 → 111 → 112`

Do not skip or reorder these migrations.

## Source validation

```bash
npm run validate:engage-e10
```

This executes the E10 gate followed by the complete dependency chain E9 → E1.

## Runtime smoke sequence
1. Sign in with a normal member and an admin account.
2. Verify the bell opens the shared persisted inbox.
3. Open an exact-item deep link from a notification.
4. Enable browser Push on one device when VAPID is configured.
5. Open **Engagement Control Center** from the notification drawer.
6. Turn Push off for Posts while leaving Inbox on; publish a test post and confirm it stays in the inbox but is not pushed.
7. Turn Inbox off for Posts; publish another post and confirm it is hidden in the default list but appears under **Show muted**.
8. Set a quiet-hours window covering the current local time; confirm normal Push is suppressed.
9. With **urgent bypass** enabled, send an urgent admin broadcast and confirm it may still push.
10. Disable urgent bypass and confirm an urgent item stays persisted but does not push during quiet hours.
11. Verify mentions, complaint updates, funds, elections and membership/event notifications honor their category Push settings.
12. Verify E9 posts/comments/reactions and E8 media lifecycle still work after E10.

## Flagship pilot checks
### Community / MPF
- President Home
- household/member directory
- membership/renewals
- events/RSVP
- funds/collections
- elections/voting
- posts/broadcasts/mentions
- notification preferences

### Residential
- Chairman Home
- units/residents
- complaints + routing + photo
- notices/amenities/maintenance/visitors/governance
- elections/voting
- posts/broadcasts
- notification preferences

## Known compile note
Repository-wide `tsc --noEmit` remains blocked by the pre-existing syntax errors in `qa/e2e/19-phase4b-data-integrity-recovery.spec.ts`. E10 changed-source syntax transpile passes independently.
