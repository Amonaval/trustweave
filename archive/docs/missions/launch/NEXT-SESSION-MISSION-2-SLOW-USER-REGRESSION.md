# TrustWeave — Next Mission 2: Slow Full Product User Regression

Use the latest **Mission 1 FULL ZIP** as the only source of truth. Do not revert migration 115 or the progressive-disclosure/runtime repairs.

## Entry gate
Before expanding regression coverage, apply migration 115 and complete Mission 1 persisted retest:
- Community post + photo succeeds;
- Family Community seed has no unexplained runtime/database errors and an unchanged rerun is stable;
- Housing seed has no unexplained runtime/database errors and an unchanged rerun is stable.

## Mission objective
Build/extend a **slow, low-concurrency Playwright user-regression system** that behaves like real users and is safe for Supabase Free Tier. Prefer compact certification networks (about 3–5 families and 3–5 housing units) over repeatedly loading the large showcase datasets.

## Coverage principle
Do not certify merely that a page renders. Execute meaningful use cases across Family, Family Community and Housing plus shared Network OS features: create/edit/delete where supported, posts/comments/photos, notices, complaints, funds/dues, events/RSVP, memberships/renewals, voting, visitors/security, committee/governance, family relationships, invitations, media lifecycle, notifications/deep links, role permissions, mobile navigation and cross-network isolation.

Add pacing/delays between mutating operations, use workers=1 unless a test is proven read-only, reuse sessions, and avoid repeated destructive setup. Every discovered defect must receive a regression test before closure.

## Deferred architecture missions
Mission 3: shared technical/business component architecture + CSS ownership + Storybook/use-case catalogue.  
Mission 4: vertical plugin manifests, lazy-loaded vertical bundles and maintainable domain-organized SQL sources while preserving immutable chronological migrations.
