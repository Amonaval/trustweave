# M3-D3 — Capability contract and ownership inventory

**Baseline:** `llm-push` M3-D2 at `279c05f45d002077b3a2692bd6440079de0ad5a0`. Candidate source checkpoint; connected staging remains batched with D1–D3.

## Implemented

The 25 released capability IDs are the typed keys of `core/verticals/capability-manifest.ts`. Each record identifies a bounded owner and existing source anchor; it also records known commands, queries, events, referenced persistence tables, existing policy location, owned API routes, UI route model, observability and loading boundary. `VerticalCapabilityId` derives from these keys. Unknown IDs throw in the getter, and the D2 vertical manifest validates all advertised IDs at startup. The unit gate checks all source files, listed API routes and persistence references against the repository and migrations, denies unknown/prototype keys, and checks unique declared API route ownership.

This is a source inventory, **not an authorization system**. Empty arrays mean the contract has not yet mapped those operations or persistence references; they do not promise absence of behavior. Table references can be shared and do not imply exclusive ownership. The single UI route remains a shared network surface, and the current bundle remains shared. Observability is explicitly unstandardized. Existing RPC/RLS or application policy labels identify where to inspect existing behavior; they do not assert complete enforcement. The institutional bootstrap endpoint is shared and not attributed to Alumni merely because the domain uses it. D4, D6, D7 and D9 own the subsequent authorization, full data/API inventory, lazy loading and telemetry enforcement, respectively.

## Gates

- `npm run qa:unit`: 33/33 passed, including source/route/schema reference coverage and unknown capability denial.
- `npm run check:types`, focused lint, `npm run agentic:architecture` (5/5), `npm run agentic:docs` (28/28), `npm run artifacts:check` (5/5) and `npm run build` passed. Network route First Load JS is 755 kB versus 754 kB at D2. The initial typecheck overlapped Next's generated type directory cleanup; the sequential rerun after build passed.
- No migrations, RLS, UI behavior or School implementation changed. Authenticated cross-network checks remain required at the combined D1–D3 checkpoint.
