# TrustWeave Agentic Execution Harness

The harness is intentionally small. It does not pretend that a Node script is an autonomous engineer; it gives an external agent/orchestrator deterministic contracts and evidence boundaries.

Core commands:

- `node scripts/agentic/mission-contract-gate.mjs --mission <mission.json>`
- `node scripts/agentic/architecture-gate.mjs`
- `node scripts/agentic/documentation-gate.mjs`
- `node scripts/agentic/run-mission.mjs --mission <mission.json> --profile source|static|runtime|all`
- `node scripts/agentic/scorecard.mjs`

`run-mission` emits commit/snapshot-bound evidence, gate logs and a classified `next-action.json` on failure. An AI controller can consume that output, make a bounded repair, and rerun without requiring a founder to relay raw logs.

Runtime gates are blocked—not silently skipped as success—when their required environment is absent. Source/static proof can therefore advance a mission to `SOURCE-GATED`, but not to runtime/release certification.
