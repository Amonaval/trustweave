# TrustWeave Git Delivery Workflow

**Status:** Active  
**Canonical repository:** `Amonaval/trustweave`  
**Agent working branch:** `llm-push`  
**Founder-controlled release branch:** `main`

## Why this exists

TrustWeave now uses GitHub as the durable handoff point between the Founder and the autonomous engineering workflow. Work no longer depends on exchanging disconnected ZIP snapshots for every iteration. Each accepted engineering increment can be recorded, reviewed, tested, and recovered from Git history.

Vercel integration is intentionally deferred because of the current account restriction. Deployment remains a manual or periodic Founder-controlled action until that restriction changes.

## Operating model

1. The Founder provides product intent, priorities, constraints, and true D3 decisions.
2. The engineering agent inspects the repository, implements the bounded change, and verifies it locally.
3. The agent commits and pushes only to `llm-push`.
4. GitHub Actions validates TrustWeave when relevant files change.
5. The agent reports the commit, evidence, failures, residual risks, and any genuine Founder decision.
6. The Founder controls promotion to `main` and production deployment.

## Branch boundaries

| Branch | Purpose | Who controls promotion |
|---|---|---|
| `llm-push` | Autonomous implementation, repair, documentation, and verification | Engineering workflow |
| `main` | Founder-approved release state | Founder |

The agent must not merge into `main`, change production configuration, or deploy production without explicit Founder authorization.

## Automated validation

The repository-level workflow at `.github/workflows/trustweave-ci.yml` runs from the TrustWeave project directory, `generic-family-hierarchy-4/`, and checks:

- company architecture contracts;
- living-documentation contracts;
- deployed product artifact integrity;
- TypeScript correctness;
- the TrustWeave lint baseline;
- unit and resilient-crawl contracts;
- the production build.

The workflow is scoped to TrustWeave changes and runs for pushes to `llm-push` and `main`, plus pull requests targeting `main`.

## Deployment while Vercel integration is unavailable

Git delivery and deployment are deliberately separate:

- GitHub remains the source of truth.
- Tested work accumulates safely on `llm-push`.
- The Founder can review a specific commit or diff.
- Releases can be promoted and deployed manually or periodically.
- A failed deployment does not erase the tested Git history.
- Vercel automation can be added later without changing the branch discipline.

## Evidence required for each delivery

Every engineering delivery should identify:

- the branch and commit SHA;
- the checks that passed;
- any checks that could not run and why;
- discovered defects fixed or recorded;
- residual risk;
- whether a Founder/D3 decision is required.

## Next engineering direction

The next workstream is repository-wide product reliability:

1. inventory all applications, routes, tests, fixtures, and external dependencies;
2. separate deterministic local coverage from credential-dependent integration coverage;
3. stabilize the test harness before expanding it;
4. build a resilient authenticated and unauthenticated crawl;
5. generate actionable HTML, JSON, screenshots, traces, and failure summaries;
6. repair product defects in bounded batches on `llm-push`;
7. preserve Supabase-dependent flows behind explicit environment checks and local test setup.

Supabase production credentials should not be committed or shared in chat. Local testing should use documented environment variables, safe development credentials, fixtures, mocks, or a local Supabase stack as appropriate.
