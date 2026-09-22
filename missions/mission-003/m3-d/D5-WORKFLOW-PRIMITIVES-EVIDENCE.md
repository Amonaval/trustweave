# M3-D5 — Action / obligation / workflow primitives

**Baseline:** `llm-push` M3-D4 at `12d11ad6315a502e1d90526933eeed36390315d4`.

## Implemented

`core/workflow/contracts.ts` and `core/workflow/runtime.ts` introduce an in-process workflow contract for tasks, acknowledgements, approvals and consent obligations. The common mechanics are deliberately narrow: stable source identity, assignment, due date, SLA deadline, kind-aware state transitions, outcome, and append-only application audit entries.

The primitive does not create a generic workflow database and does not replace D4 authorization/consent. `WorkflowConsentRequirement` directly reuses D4's `PolicyResourceRef`; actual consent authorization still belongs to the D4 decision boundary. Existing historical records are projected with empty audit arrays rather than fabricating history.

Housing proves three independent existing patterns through `verticals/housing-society/runtime/workflow.ts`: complaint assignment/SLA, amenity approval, and governance action obligations. Family Community proves event RSVP as an acknowledgement obligation through its own adapter. Domain status strings remain translated inside the owning vertical; the kernel does not learn Housing or Community vocabulary.

D3 capability metadata now exposes optional `workflowAdapter` ownership for Housing and Family Community. This is discovery metadata only and does not imply that every existing workflow RPC has been migrated.

## QA

- `qa/unit/workflow-primitives.test.ts` covers guarded transitions, audit append, terminal-state denial, assignment, due/SLA timing, Housing projections, Community RSVP projection and D4 consent vocabulary reuse.
- `npm run qa:unit` includes the D5 contracts.
- `npm run qa:resilient` is added as the expected alias for the already-existing configured resilient crawler (`qa/run-resilient-crawl.mjs --scope=configured`).

## Boundaries

No migrations, RLS changes, RPC rewrites, UI workflow redesign or School code were added. Existing Housing/Community persistence remains authoritative. D6 owns command/query/API boundary consolidation.
