# TrustWeave — Current User & Admin Guide

**Updated:** 2026-09-13

This is the short operational guide. For the complete user-experience behavior, see `docs/product/USER-EXPERIENCE-HANDBOOK.md`.

## Start

1. Sign in.
2. Open **My Networks**.
3. Choose an existing network, join/create another network, or explore an enabled Playground.
4. Existing memberships remain available even if Launch Control hides that vertical from new Create/Playground discovery.

## Create a network

- Choose an enabled network type.
- Complete the lightweight setup.
- With **Auto-approve ON**, successful creation should open the new network immediately.
- With manual approval, the new network remains Pending until a platform owner approves it.

Platform owners manage this under **Launch Control → Networks & Approvals**.

## Family

Use Family for people, relationships, generations, profiles, tree/path exploration, memories, birthdays, history, contribution, invitations/claiming and family administration.

## Community / Cultural Association

Use Community for member families/households, Me & My Family, directory, annual membership/renewal, events, announcements, birthdays, committee roles, community history and photos.

The President-first Home summarizes what needs attention and what is happening next.

## Residential / Housing Society

Use Residential for flats/residents, notices, complaints, amenities/bookings, maintenance, committee/governance, visitors/security, assets and compliance.

The Chairman-first Home summarizes operational attention and links into the existing modules.

### Complaint workflow

A resident can create a complaint with a photo. Complaint category/responsibility routing can notify the assigned resolver. Updates/comments can notify the resident. Notification deep links should open the exact complaint.

## Notifications

The notification bell opens the shared inbox.

- Notifications may be normal/high/urgent.
- Open a notification to enter its network/surface/item.
- Access is rechecked; a notification does not bypass permissions.
- Desktop uses a full-height drawer.
- Mobile uses a tall bottom sheet.

## Web Push

If Web Push is configured and you opt in on a device, notifications can arrive when the app is not open. In-app notifications remain the source of truth.

## Mentions / responsibilities

Where supported, use role mentions such as `@President`, `@Chairman`, `@Treasurer` or named-member mentions. Admins assign responsibility roles within the current network.

## Photos/media

TrustWeave compresses supported images before upload, re-encodes them to WebP, creates thumbnails and serves them through private signed URLs. Complaint photos use stricter authorization than normal event/community media.

## Appearance and language

Appearance options: Light, Warm, Modern, Aurora, Dark.

Language foundation: English, Hindi, Marathi.

## Platform-owner Launch Control

Organized into:

- **Networks & Approvals**
- **Showcase**
- **Feature Rollout**
- **Governance**

Create/Playground visibility controls discovery only; it must not remove valid existing memberships.

## Verification

For E1–E10 validation use `docs/engagement/E1-E10-VERIFICATION-GUIDE.md`.


## Community posts & broadcasts

Community and Residential networks can use the shared Posts & Updates surface for member posts, photos, comments, reactions and mentions. Network admins can additionally mark important/urgent updates, pin posts and notify all eligible members.

## Funds / collections

Community leaders can manage membership-year funds, pooled/community funds and event-specific collections with receipts, transactions and relevant notifications.

## Elections / voting

Formal elections and polls support eligibility snapshots, nominations, voting windows, one-submission enforcement and controlled result publication. Secret ballots separate participation identity from vote choice.

## Media & Storage

Admins can review storage usage, archive/restores and explicitly delete archived media. TrustWeave does not automatically destructively clean old media.

## Engagement Control Center

Open the notification bell and choose the settings icon. Preferences apply to the **current network**.

You can control Posts, Mentions, Complaints, Funds, Elections, Events/Membership and General activity independently for Inbox emphasis and Push delivery. Muted Inbox categories remain persisted and can be opened using **Show muted**. Quiet hours can be configured with timezone and an optional urgent-alert bypass.

The in-app notification record remains authoritative even when Push is disabled or suppressed.
<!-- FINAL-LAUNCH-CLOSURE -->
## Final launch discovery and demo-data workflow

### Before signing in
A visitor can now use the public Discovery front door to understand TrustWeave, explore Housing Society or Family Community journeys, view member/resident value, open Playground, and read the Product Guide. Sign In remains visible but is not required to understand the product.

### Populating a real pilot/demo network
For Residential or Family Community, an admin/platform owner opens the network Admin surface and uses **Final launch data**. Choose the bundled dataset (or upload the matching launch JSON/XLSX), review the dry-run counts, type the exact active network name, confirm synthetic-data intent, authorize the dataset, and then persist it. Re-running the same version is lineage/idempotency aware. See `DATA-SEED-RUNBOOK.md`.

### Safety
The launch loader does not reset a network globally. A production-looking network name requires a separate explicit override. Use this capability only for synthetic launch/pilot datasets.
