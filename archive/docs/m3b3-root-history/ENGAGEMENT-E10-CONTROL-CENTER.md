# E10 — Engagement Control Center

## Outcome
E10 closes the E1→E10 engagement stack with per-user, per-network delivery controls. The persisted TrustWeave inbox remains the source of truth; push is only a delivery channel.

## Implemented
- Settings entry inside the shared notification drawer.
- Per-category Inbox + Push preferences for Posts, Mentions, Complaints, Funds, Elections, Events/Membership and General activity.
- Muted inbox categories are not deleted; **Show muted** reveals them. Urgent notifications remain visible.
- Device Push enable/disable remains available.
- Quiet hours start/end, timezone and urgent-bypass preference.
- Push delivery API evaluates global push state, category preference, quiet hours and urgency before sending.
- Preference row is created safely when a user first enables Push.

## Migration
Apply after 111:

`112_engagement_notification_control_center.sql`

## Privacy / reliability invariants
- Preferences are per user + network.
- Notification rows are still persisted before Push delivery.
- Muting a category does not delete history.
- Push suppression never marks a notification as delivered or read.
- Urgent bypass affects only Push quiet-hours suppression; it does not grant authorization.

## Validation
`npm run validate:engage-e10`

The E10 gate then executes the E9→E1 dependency chain.
