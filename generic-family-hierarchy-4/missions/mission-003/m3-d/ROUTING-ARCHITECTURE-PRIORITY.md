# M3-D Routing Architecture Priority

**Priority:** P0 after D0 baseline measurement  
**Mission:** D1 — Addressable Application & Deep-Link Routing Foundation

## Why this exists

TrustWeave cannot become a serious Network OS if meaningful product state exists only behind sequences of UI clicks.

Users must be able to:

- open a shared link directly;
- bookmark important resources;
- refresh without losing context;
- use browser history correctly;
- open links from notifications/email/WhatsApp;
- return to the original resource after login;
- selectively expose public profiles/resources where policy allows;
- let future AI agents navigate by durable resource links.

## Architectural rule

> Every meaningful shareable or resumable product state should have a stable, authorization-aware URL unless there is a documented reason it is intentionally ephemeral.

Temporary UI state such as an open tooltip, transient form input or local sort interaction does not automatically require its own route.

## Required design decisions

1. Canonical route grammar across platform, vertical and capability surfaces.
2. Stable resource IDs versus optional human-readable slugs.
3. Network context resolution from route parameters.
4. Route ownership by capability/vertical manifest.
5. Public/private/authenticated route taxonomy.
6. Login redirect/return-to-origin contract.
7. Forbidden, not-found and deleted-resource behavior.
8. Query-string policy for filters/views versus resource identity.
9. Link stability across renames.
10. Notification/share/federation/public-profile deep-link contracts.
11. Future mobile universal-link compatibility.
12. Route telemetry and deterministic route tests.
13. Privacy rules preventing sensitive information in URLs.
14. Explicit guarantee that routing never bypasses server/RLS/policy authorization.

## Representative certification flows

Before D1 closes, direct navigation should be proven for representative existing surfaces across:

- Family;
- Family Community / Association;
- Housing / Residential.

Certification should include anonymous/public where applicable, authenticated direct entry, authorization denial, login return-to-origin, refresh, browser back/forward and stale/deleted resources.

## Migration posture

Do not attempt to convert every historical screen in one rewrite.

D1 establishes the contract, platform router/context primitives and representative high-value migrations. Subsequent capability/vertical work must adopt the contract, and an addressability fitness gate should prevent new meaningful hidden-state screens from being introduced.
