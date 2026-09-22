# M3-B5 — Execution Harness

**Status:** IMPLEMENTED

## Control plane

TrustWeave uses the repository and CI as durable mission memory:

`mission.json -> worktree/branch -> bounded diff -> deterministic gates -> classified failure -> bounded repair -> rerun -> independent review -> evidence -> release gate`

The harness intentionally avoids a new multi-agent framework. An AI controller can drive the loop using the commands under `scripts/agentic/`, while Git and evidence files preserve state when the model/session changes.

## Durable controls

- `governance/execution-policy.json` — branch/environment/retry/release policy.
- `mission-worktree.mjs` — one isolated worktree/branch per active mission.
- `scope-gate.mjs` — changed-path enforcement in Git; protected-tree hash enforcement when Git metadata is unavailable.
- `run-mission.mjs` — gate orchestration and SHA/snapshot-bound evidence.
- `failure-classifier.mjs` — first-pass defect classification before repair.
- `runtime-preflight.mjs` — explicit environment readiness.
- `review-gate.mjs` — final-review separation contract.
- `evidence-gate.mjs` + `mission-close.mjs` — release/closure cannot outrun evidence.

## What is autonomous today

Deterministic planning contracts, source/static gate execution, evidence capture, failure classification, scoped rerun instructions, documentation drift detection and packaging can run without founder participation.

A persistent external AI runner (for example a Work/cloud-computer execution context or CI-connected coding agent) is still required to read a failure, edit code, commit the repair and resume the loop after asynchronous CI completes. This repository supplies the protocol; it does not falsely claim that a local Node process can reason and edit code by itself.

## Environment boundary

R3/destructive database certification belongs only in a disposable QA/release-candidate environment. Staging/production remain protected and human-gated at the current maturity.
