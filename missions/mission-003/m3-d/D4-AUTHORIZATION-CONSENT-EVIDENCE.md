# M3-D4 — Scoped authorization and consent foundation

**Baseline:** `llm-push` M3-D3 at `6fc46e3e89ac160daaa0857fb448a39ec5a57da7`. Candidate source checkpoint; server/RPC/RLS remains the authoritative data-access boundary and connected staging evidence is still batched.

## Implemented

`core/authorization/policy.ts` introduces one fail-closed application policy contract that evaluates an active network membership together with capability/action, resource scope, declared purpose, membership/action time windows, relationship-derived scope and optional explicit consent. Consent grants are exact to network, subject, grantee, capability, action, purpose, resource and validity window; revoked/expired/mismatched grants do not match.

Housing Society and Family Community own thin adapters in their vertical folders rather than moving domain vocabulary into the kernel. Housing proves administrator management plus occupant-scoped unit reads. Family Community proves administrator management plus household-member-scoped reads. Existing direct network-surface authorization now routes owner/admin/member checks through the shared decision engine while preserving the previous behavior and server-backed membership requirement.

D3 capability metadata now records optional policy-adapter source paths. This is inspectable ownership metadata, not a claim that every historical RPC has been converted. Existing RPC/RLS policy continues to decide data access. No consent persistence table, migration, School code, finance/governance flattening or cross-network inherited permission was added.

## Verification contract

- `qa/unit/authorization-policy.test.ts` covers inactive membership, cross-network denial, purpose mismatch, expired membership, Housing relationship/resource scope, Family Community relationship/resource scope, administrator-only management, exact consent, revocation and consent-purpose mismatch.
- The existing `qa/unit/network-routes.test.ts` continues to cover cross-tenant, inactive-member, unknown-surface and private-admin direct-entry denial through the D4 policy adapter.
- `qa/unit/capability-manifest.test.ts` now checks that every declared policy adapter exists.
- The standard `npm run qa:unit` gate includes the D4 suite. CI/build/type evidence must be read from the resulting commit; authenticated staging and disposable-database/RLS certification remain separate gates.

## Boundary

D4 establishes reusable decision semantics. It does **not** replace Postgres RLS, SECURITY DEFINER privilege checks or server command authorization, and it does not persist consent grants yet. D5 may compose these decisions into action/obligation/workflow primitives; D6 owns broader API/data boundary consolidation and current privilege inventory.
