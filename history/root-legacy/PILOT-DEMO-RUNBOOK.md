# TrustWeave — Pilot / Showcase Demo Runbook

> **Mission 1 prerequisite:** before using this runbook, apply migrations through **115_mission1_runtime_seed_integrity.sql** and use the Mission 1 FULL baseline. Complete the Community photo-post and two-run seed idempotency proof in `MISSION-1-APPLY-RETEST-RUNBOOK.md`.
## Goal
Demonstrate a coherent story, not a module checklist. Use Playground for fast read-only discovery and seeded real networks for persisted proof.

## 1. Anonymous visitor — 2 to 4 minutes
1. Open the landing page signed out.
2. State the thesis: **a private operating system for the networks people already belong to**.
3. Open **Housing Society** and show the resident/unit → notice/complaint → resolution → dues/payment → committee/voting → visitor/security story.
4. Return and open **Family Community** to show family → annual membership → event/fund → committee/voting → post/history.
5. Open **Product Guide**. Toggle Simple / Detailed / Deep to demonstrate progressive disclosure.
6. Open Playground briefly. Explain that Playground is deterministic/no-save, while the seeded pilot networks use real persisted product behavior.
7. Sign in only after the evaluator understands the product.

## 2. Residential — Chairman/admin story
Open the final seeded Residential pilot. Use this order:
- Home: live counts and current work.
- Residents / My Home: unit-centered model.
- Notices and Complaints: exact service loop, assignment, status and photo.
- Amenities: availability/booking.
- Maintenance & Dues: mixed paid/partial/overdue states, adjustments, receipts, funds/budget/expenses.
- Committee & Meetings: term, roles, agenda/minutes/actions/resolutions.
- Elections & Voting.
- Visitors & Security: visitors, staff access, move/renovation, assets/compliance/emergency.
- Community + posts/events.
- Media & Storage: prove signed/private media behavior.

Then switch to a normal resident account and prove scope: own flat/household, member-safe finance, resident complaint/visitor flows and no admin-only data leakage.

## 3. Family Community — President/admin story
Open the final seeded Family Community pilot. Use this order:
- Home: current community life.
- Families: 20-family directory, representative/spouse/children.
- Me & My Family / Family Structure: household and kinship.
- Annual membership: active/grace/pending/payment history.
- Community Life: events, announcements, posts/comments, memories.
- Funds & Collections.
- Committee roles + Elections & Voting.
- Build Together: invitations/contribution.
- Media & Storage.

Then switch to a representative/member account and show the member-safe view and preserved annual/community history.

## 4. Notification proof
Trigger real domain actions instead of fake notification rows. Verify the inbox shows the event and the deep link opens the exact complaint/post/fund/election surface/item where applicable. Verify Push enable/disable/preferences in the approved browser environment.

## 5. Mobile proof
Repeat the anonymous first-impression path and one flagship path at a mobile viewport. Check topbar overlap, More-sheet close behavior, loading, back/close, long labels, notification drawer and primary CTAs.

## 6. What not to show
Do not expose founder-private strategy, unreleased confidential roadmap/IP, anti-abuse internals, environment secrets or raw internal docs simply because they exist in the repository.
