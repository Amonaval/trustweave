# TrustWeave — FINAL PRE-LAUNCH SESSION
## Discovery / Product Exploration + Complete Demo Data + Launch Certification

Use the supplied **latest FULL E10 Stability + ESLint Closure ZIP** as the only source of truth. Do not merge from older E8/E9 checkpoints.

This is intended to be the **last substantial engineering session before controlled launch / real-world showcase**. The objective is not to add more unrelated features. The objective is to make the existing product understandable, populated, stable, demonstrable and certifiable.

---

# 0. Binding operating rules

1. Preserve all existing Family, Family Community / Cultural Association, Residential / Housing Society and shared Network OS capabilities.
2. Do not remove or silently replace E1–E10 engagement functionality.
3. Launch Control controls discovery/creation/playground visibility; it must not delete vertical functionality or hide existing memberships.
4. Use the current E10 baseline only. No stale full-file overlays from older checkpoints.
5. Every change must preserve mobile + desktop behavior.
6. Prefer existing RPCs/services/components. Do not create parallel social, voting, finance, notification or media subsystems.
7. Keep Supabase Free Tier in mind: small datasets, low concurrency, no wasteful repeated destructive tests.
8. Warnings may remain for this launch session if they are understood legacy debt. **ESLint errors, build errors, runtime blockers and broken flagship journeys may not remain.**
9. Do not expose founder-private strategy, patent/IP material, anti-abuse internals or unreleased sensitive architecture in the public Product Guide / Discovery experience.
10. After completion, create a new FULL launch-candidate ZIP and AFFECTED ZIP. That exact FULL ZIP becomes the launch baseline.

---

# 1. FIRST GATE — prove the incoming baseline before feature work

Run and record:

```bash
npm run lint:trustweave
npm run validate:static
npm run build
npm run validate:e10-closure
```

Also run the existing relevant E1→E10 / showcase / Residential source gates.

Expected:
- ESLint: **0 errors** (warnings allowed)
- static/type gate: no live-app blocker
- `npm run build`: PASS
- E10 closure: PASS

If anything fails, fix it before Discovery work.

---

# 2. MAJOR MISSION A — Discovery / Product Exploration Transformation

## Product problem

TrustWeave already has broad capability, but a new visitor cannot easily understand its power before signing in. The first experience must explain value before asking for commitment.

## Desired top-level journey

```text
Landing / Product Front Door
   ↓
What is TrustWeave?
   ↓
Choose my situation / role
   ↓
See the problems TrustWeave solves
   ↓
Explore capabilities / realistic Playground
   ↓
Open Product Guide / Knowledge Center
   ↓
Sign in / Create network / Start pilot
```

### First 10 seconds

A Society Chairman / Committee Member should understand:

> Residents, complaints, notices, maintenance, visitors, amenities, committee work, elections, finances and community communication — together in one private society system.

A Community President / Director should understand:

> Families, annual membership, renewals, events, funds, committees, elections, professional connections, community posts, memories and history — together instead of fragmented Excel + WhatsApp workflows.

A normal user should also understand that TrustWeave is a private multi-network operating system, not only a Housing Society or MPF app.

### Required landing actions

Keep Sign In visible, but not as the emotional center.

Prominent actions should include concepts equivalent to:
- Explore Housing Society
- Explore Family Community
- Try Playground
- See what TrustWeave can do
- Product Guide
- Sign in

Do not require login merely to understand the product.

---

# 3. Role-oriented exploration

Create understandable paths such as:

### I manage a Housing Society
Show the connected operational story:

```text
Resident / Unit
→ Notice
→ Complaint + photo
→ Assign resolver/vendor
→ Notify
→ Resolve
→ Maintenance dues
→ Payment
→ Committee meeting
→ Resolution / election
→ Visitor / security
→ Asset / compliance
```

### I lead a Community / Association

```text
Family
→ Representative / spouse / children
→ Annual membership
→ Renewal / payment
→ Event + RSVP
→ Fund / collection
→ Committee role
→ Election / poll
→ Community post / mention
→ Professional/community discovery
→ Memories / history
```

### I am a member / resident
Explain daily value without admin terminology.

Use progressive disclosure. Do not dump 50 module names in one screen.

---

# 4. Product Guide / Knowledge Center

Build a real in-product documentation center, not a raw directory listing.

Suggested information architecture:

```text
Product Guide
├── Start Here
├── Housing Society
├── Family Community / Association
├── Family
├── What TrustWeave Can Do
├── How People Use It
├── Privacy & Trust
├── Getting Started
├── Product Evolution
└── Go Deeper
    ├── Feature Handbook
    ├── UX Handbook
    ├── Capability Catalog
    ├── Product Journey
    └── Technical / CTO view
```

### Disclosure levels

**Simple:** normal users, older/non-technical users, residents, members.

**Detailed:** Chairmen, Presidents, Directors, committee/admin users and product evaluators.

**Deep:** technical/product stakeholders.

Never publicly expose merely because a Markdown file exists:
- founder strategy;
- patent/IP candidate details;
- private acquisition strategy;
- anti-abuse/ranking internals;
- unreleased confidential roadmap;
- secrets/environment/config data.

---

# 5. MAJOR MISSION B — Launch Demo Data Loader

The final demo must not rely on tiny hard-coded UI samples. Create a reusable, network-scoped **Launch Demo Data Loader / Pilot Seeder**.

## Supplied datasets

### Residential
- `TRUSTWEAVE-LAUNCH-DEMO-RESIDENTIAL-25-FLATS.xlsx`
- `TRUSTWEAVE-LAUNCH-DEMO-RESIDENTIAL-25-FLATS.json`

### Family Community
- `TRUSTWEAVE-LAUNCH-DEMO-FAMILY-COMMUNITY-20-FAMILIES.xlsx`
- `TRUSTWEAVE-LAUNCH-DEMO-FAMILY-COMMUNITY-20-FAMILIES.json`

All records are synthetic.

## Existing importer facts

### Housing Society importer already supports
- Buildings / Units
- Residents
- Occupancy / Ownership / Tenancy
- Vehicles
- Parking

Keep that path working.

### Family Community importer currently supports commit of
- Families
- People
- Household Membership

**Important gap:** `Association Membership` exists in the guided schema but the current generic `commitProductizedWorkbook` ignores `recordType: "domain"` sheets. Fix this properly or explicitly map Family Association annual membership through a vertical-specific commit adapter.

Do not silently pretend annual membership imported when it did not.

---

# 6. Extended seed loader architecture

Implement an explicit admin/platform-owner launch seeding workflow for the operational sheets.

Required properties:

### Safety
- network-scoped;
- admin/platform-owner only;
- explicit confirmation;
- synthetic/demo marker;
- never cross network boundaries;
- refuse to seed arbitrary real production networks unless explicitly allowed;
- no global destructive reset.

### Idempotency
Every spreadsheet row has stable references such as:
- `U001`
- `CMP101`
- `VEN001`
- `EV004`
- `F001`
- `P001`

Persist/import lineage so re-running the same data updates/skips rather than duplicates.

### Experience

```text
Upload workbook / choose bundled launch dataset
→ Parse
→ Validate references
→ Dry-run summary
→ Show create/update/skip/error counts
→ Commit
→ Progress
→ Completion report
→ Open populated network
```

### Technical rule
Use existing product RPCs/services wherever possible instead of raw direct inserts.

Examples:
- Housing notices → `createHsNotice`
- Complaints → `createHsComplaint`
- Complaint comments → `addHsComplaintComment`
- Amenities → `upsertHsAmenity`
- Bookings → `createHsAmenityBooking`
- Charge heads / cycles / payments / funds / budget / expenses → existing HS finance RPCs
- Committee / meetings / resolutions → existing governance RPCs
- Visitors / staff / assets / compliance → HS5 RPCs
- Shared funds → E6 APIs
- Elections / polls → E7 APIs
- Posts → E9 activity/posts APIs
- Media → E5 media pipeline

If a historical/demo state cannot be represented through current safe APIs, add the smallest network-scoped, platform-owner/demo-only seed capability. Do not create a broad insecure bypass.

### Notifications
Do **not** insert notification rows merely to make the inbox look busy.
Create real domain actions that naturally generate notifications and deep links. Verify those links.

### Media
Use small bundled synthetic fixture images through the normal E5 upload/compression/private-storage path so Media & Storage and complaint/event/post thumbnails are real. Keep files tiny and Free-Tier-safe.

---

# 7. Residential launch dataset — must populate every meaningful surface

Use the supplied 25-flat dataset.

Expected surfaces with meaningful data:

- Home
- My Home
- Residents
- Notices
- Complaints
- Amenities
- Maintenance & Dues
- Committee & Meetings
- Elections & Voting
- Visitors & Security
- Media & Storage
- Society Structure
- Community
- Neighbours
- Guide & Help
- Manage Society

And every currently reachable Residential submodule that is not listed above.

The workbook contains synthetic data for:
- 25 units;
- ~50 residents/occupants;
- ownership/tenancy;
- vehicles + parking;
- notices;
- complaints + comments + SLA/assignment;
- vendors + contracts;
- amenities + bookings;
- charge heads + billing cycles;
- bill expectations + payments + adjustments;
- funds + budget + expenses;
- committee terms + assignments;
- meetings + agenda + minutes + actions + resolutions + documents;
- elections/polls;
- visitors;
- staff + unit authorization;
- move/renovation requests;
- assets + maintenance;
- compliance;
- emergency contacts;
- community events;
- posts + comments;
- media manifest.

## Residential demo quality bar

The Home must look alive and coherent, not randomly populated. Examples:
- some paid dues, some partial, some overdue;
- open + in-progress + resolved complaints;
- upcoming visitors;
- current amenity bookings;
- committee actions due;
- compliance due soon;
- current notices;
- one open poll/election;
- community posts/events;
- real counts linked to underlying data.

---

# 8. Family Community launch dataset — populate every meaningful surface

Use the supplied 20-family dataset.

Expected surfaces:

- Home
- Me & My Family
- Families
- Community Life
- Guide & Help
- Funds & Collections
- Elections & Voting
- Media & Storage
- Family Structure
- Family & Community Links
- Build Together
- Manage Community

And all currently reachable Community submodules.

Dataset includes:
- 20 families;
- representatives, spouses and children;
- profile metadata;
- household membership;
- spouse/parent/child structure;
- annual membership years;
- active/grace/pending states;
- payment states;
- committee role catalog + assignments;
- events + RSVP;
- announcements;
- funds + transactions;
- elections/polls;
- posts + comments;
- memories;
- community groups;
- invitations;
- contribution prompts;
- media manifest.

## Community quality bar

Home should show meaningful current life:
- renewals due;
- families in grace/pending;
- upcoming event;
- birthdays/profile context where available;
- active funds/collections;
- committee context;
- current post/broadcast;
- an election/poll;
- memories/history.

---

# 9. Playground vs real imported network

Both must be compelling.

### Playground
Fast, curated, deterministic and no-save.

### Real sample network
Must be populated through the real import/seed pathway and exercise real persisted RPC/database behavior.

Do not confuse the two.

The real imported Residential and Family Community sample networks are the final proof that the product works beyond deterministic Playground fixtures.

---

# 10. FINAL UX / SHOWCASE HARDENING

Rehearse the product as:

- anonymous skeptical visitor;
- new user with no network;
- Society Chairman;
- committee/admin;
- normal resident;
- Community President;
- family representative;
- ordinary family member;
- platform owner;
- older/non-technical mobile user.

Check:
- first 10 seconds comprehension;
- no overlapping topbars;
- More menus retain expected desktop state;
- mobile More sheets close appropriately;
- loading states;
- back/close behavior;
- empty states;
- errors;
- i18n token integrity;
- notification inbox discoverability;
- push enable/disable;
- notification exact deep links;
- role permissions;
- private media;
- launch controls;
- no cross-network data leakage.

---

# 11. FINAL AUTOMATED / RUNTIME CERTIFICATION

Required minimum:

```text
1. lint:trustweave — 0 errors
2. validate:static — PASS
3. npm run build — PASS
4. E1→E10 source gates — PASS
5. E10 closure — PASS
6. showcase flow/stabilization gates — PASS
7. Residential gates — PASS
8. Family Community gates — PASS
9. fresh Residential workbook import/seed — PASS
10. fresh Family Community workbook import/seed — PASS
11. headed Playwright flagship walkthroughs — PASS
12. mobile viewport flagship walkthroughs — PASS
```

Create launch-specific E2E tests that verify meaningful data, not merely that a page renders.

Examples:
- Residential Home displays counts that match imported seed data.
- Complaint deep link opens exact complaint.
- Fund/election/post notification opens exact surface/item.
- A resident sees their flat and household.
- Committee data appears for admin.
- Association representative sees family + annual membership.
- Family Structure displays seeded kinship.
- Funds have balances/transactions.
- Poll/election is visible.
- Posts/comments exist.

---

# 12. FINAL DOCUMENTATION / RELEASE CLOSURE

Synchronize the living product docs after the launch-candidate state is proven:

- CURRENT-STATE.md
- MISSION-STATUS.md
- ROADMAP.md
- USER-GUIDE.md
- USER-EXPERIENCE-HANDBOOK.md
- PRODUCT-CAPABILITY-CATALOG.md
- CTO-PRODUCT-CAPABILITY-BOOK.md
- CEO-PRODUCT-BRIEF.md
- TRUSTWEAVE-MISSION-JOURNEY.md
- TRUSTWEAVE-PRODUCT-FEATURE-HANDBOOK.html
- TRUSTWEAVE-PUBLIC-PRODUCT-PROFILE.html
- TRUSTWEAVE-PRODUCT-EVOLUTION-JOURNEY.html
- DOCUMENTATION.md

Add a concise:
- LAUNCH-READINESS-REPORT.md
- PILOT-DEMO-RUNBOOK.md
- DATA-SEED-RUNBOOK.md
- FINAL-RELEASE-MANIFEST.md

Do not clutter root with old mission docs; archive superseded evidence.

---

# 13. FINAL DELIVERABLES

Produce:

1. **TRUSTWEAVE-LAUNCH-CANDIDATE-FULL.zip** — exact final source of truth.
2. **TRUSTWEAVE-LAUNCH-CANDIDATE-AFFECTED.zip**.
3. The final Residential 25-flat workbook + JSON.
4. The final Family Community 20-family workbook + JSON.
5. Launch Readiness Report.
6. Pilot Demo Runbook.
7. Data Seed Runbook.
8. Runtime verification checklist.
9. Final release manifest.
10. One concise launch handover prompt for any post-launch session.

---

# 14. Definition of DONE

Do not call this launch-ready simply because source gates pass.

DONE means:

> A brand-new Residential network can be created, seeded/imported with the supplied 25-flat dataset, opened as Chairman/admin/resident and every flagship surface contains coherent real persisted data.

AND

> A brand-new Family Community network can be created, seeded/imported with the supplied 20-family dataset, opened as President/admin/family representative/member and every flagship surface contains coherent persisted data.

AND

> An anonymous visitor can understand what TrustWeave is, explore the appropriate role journey and Playground, reach the Product Guide, and then sign in/create a network without confusion.

AND

> lint has 0 errors, build passes, flagship headed/mobile flows pass, notification deep links work, private media stays private, and no known launch-blocking defect remains.

This is the final pre-launch mission. Prefer closure and proof over adding more features.
