# TrustWeave Founder Autonomous Working Model

## The direction in one sentence

TrustWeave is no longer only a product repository. It now contains a governed company operating layer so the Founder can state the outcome while routine planning, implementation, validation, repair, independent review, documentation and packaging happen without acting as developer or QA coordinator.

## What changed

| Earlier | New operating model |
| --- | --- |
| The Founder described technical steps and carried failures between sessions. | The Founder supplies the outcome, target user and business boundaries. |
| A new session depended on a long conversational handoff. | Mission state, evidence, reviews and next actions are durable repository records. |
| The same builder could be tempted to treat its work as complete. | Candidate-bound independent review covers eleven risk dimensions. |
| Browser, dependency and preview failures required manual coordination. | The environment manager restores dependencies, starts Next and runs Chromium. |
| Product opinions were difficult to reproduce. | Real role/device journeys create measurable, ranked opportunities. |
| Release confidence ended at source checks. | Preview, smoke, rollback, incident and postmortem are executable rehearsals. |
| Prior lessons had to be restated. | Searchable company memory is consulted automatically during planning. |
| The Founder inspected logs and Markdown. | `/company` provides a concise spectator cockpit with drill-down. |

## The autonomous delivery loop

1. **Founder intent** — describe the desired outcome, target user, constraints and prohibited effects.
2. **Memory retrieval** — recover relevant user evidence, past failures, architectural lessons and decisions.
3. **Executive debate** — CEO, Chief of Staff, CTO/Architect, Product Advocate and Critic propose alternatives and preserve dissent.
4. **Authority classification** — D0–D2 reversible work can proceed within policy; D3 remains Founder-controlled.
5. **Mission planning** — create bounded steps, allowed writes, required gates, rollback and intervention budget.
6. **Implementation and bounded repair** — make the smallest safe change, classify failures and retry within limits.
7. **Real verification** — exercise the actual application, roles, devices and database boundaries required by the mission.
8. **Independent review** — bind findings to the committed candidate SHA; the builder cannot self-approve.
9. **Release readiness** — rehearse preview, smoke and rollback without implying production deployment.
10. **Living closure** — synchronize product documentation, evidence, affected-files package and full handoff state.

## What the Founder should provide

A future request normally needs only:

- the business or product outcome;
- the people who must benefit;
- important constraints or non-negotiables;
- anything explicitly forbidden;
- whether production deployment is authorized.

Example:

> Make Housing Society complaint management presentation-ready for residents and committee members. Preserve Family Community and shared architecture. Do not deploy or modify production data. Continue autonomously and ask only for a genuine D3 decision.

The Founder should not need to choose test commands, diagnose TypeScript or Playwright failures, relay console errors, remember documentation updates or manually sequence routine engineering work.

## What remains Founder-controlled

- destructive or irreversible production actions;
- material privacy or security risk acceptance;
- recurring spend, contracts or external commitments;
- inaccessible credentials or infrastructure;
- fundamental product/constitutional changes;
- any decision explicitly classified D3.

Release-ready means validated, independently reviewed and packaged. It does not mean automatically deployed.

## Product and company surfaces

- `/` — public Discovery and role journeys.
- `/artifacts` — deployed product narrative, evolution and capability artifacts.
- `/company` — Founder Spectator Cockpit.
- `qa-results/` — local/staging runtime evidence and prioritized defects.

## Credential-safe local certification

The repository already supports a complete local/staging certification without giving credentials to ChatGPT. Secrets remain in ignored `.env.qa`. The runner generates sanitized evidence under `qa-results/`, including:

- `CERTIFICATION-SUMMARY.json`;
- `BUG-REPORT.md`;
- `REMEDIATION-PLAN.md`;
- `COVERAGE-MATRIX.md`;
- `findings.json`;
- Playwright results, traces, screenshots and videos;
- database, RPC, RLS and crawler evidence.

Run `npm run company:diagnose` for the credential-free repository/browser scan. Run `npm run company:diagnose:connected` only against a dedicated staging Supabase configured in `.env.qa`. Send the resulting `qa-results/` ZIP back for autonomous remediation; do not send `.env.qa`.

The previously halted broad crawler is not treated as trustworthy evidence merely because it runs. `npm run qa:crawl:robust:all` now divides the entire 9-vertical × 3-role surface into isolated, checkpointed shards; retries a failed shard once in a clean context; blocks destructive exploration; and distinguishes a flaky clean-retry pass from a reproducible failure. This prevents one browser crash, stale session or server race from losing hours of progress or flooding the backlog with false product defects.

## Next company mission

The next direction is **M3-C11 — Repository Health & Local Runtime Feedback Loop**:

1. scan the complete repository without credentials;
2. repair deterministic source, type, build and public-runtime failures;
3. run guarded connected certification locally against dedicated staging;
4. ingest the generated issue bundle;
5. fix P0/P1 findings first with permanent regression assertions;
6. repeat until every mandatory layer is PASS or a genuine D3/environment blocker remains.

This is how the autonomous-company work becomes a continuous engineering loop rather than a one-time demonstration.

### Current M3-C11 position

The credential-free phase has now run across artifact integrity, company control-plane gates, architecture, documentation, syntax, full and app TypeScript, lint, unit contracts, QA structure, migration source, launch source, progressive UX, Mission 2 source, production build and a real public Chromium journey. All 16 layers pass.

That scan also repaired three test-system defects before they could be mistaken for product defects: a missing Mission 2 TypeScript declaration, an IPC-incompatible test command, and unpinned lint tooling. The next action is the private connected phase: the Founder runs `npm run qa:seed` once and then `npm run qa:crawl:robust:all` with the dedicated staging values in `.env.qa`, sends `qa-results/`, and the autonomous remediation loop fixes the reproducible findings in priority order.
