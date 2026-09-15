# TrustWeave Static Analysis Hardening — E9/E10 Stability

## Why this exists
Recent E9/E10 integration exposed issues that source gates did not catch early enough: stale duplicate files with broken relative imports, an impossible narrowed union comparison, illegal async usage inside a synchronous callback, and metadata values used as truthy values without explicit boolean coercion.

This change adds a dedicated, independent ESLint/static-typecheck path for application code. It does not replace the existing mission source gates or Playwright/database certification.

## Current fixes
- Root `TemplateNetworkApp.tsx` is now a compatibility re-export of `components/TemplateNetworkApp.tsx`; there is no second implementation to drift.
- Removed a redundant `kind !== "housing-society"` check from a branch where TypeScript had already narrowed Housing Society out.
- Preserved explicit `Boolean(post.metadata?.notify_all)` in `NetworkPostsPanel.tsx`.

## Independent ESLint
One-time setup:

```bash
npm run lint:trustweave:setup
```

Run the app-source lint:

```bash
npm run lint:trustweave
```

Run application-only TypeScript (excludes historical QA/archive artifacts):

```bash
npm run check:types:app
```

Run the complete static gate:

```bash
npm run validate:static
```

Optional zero-warning cleanup mode:

```bash
npm run lint:trustweave:strict
```

## Scope
The static profile scans the live application source directories:

- `app/`
- `app-shell/`
- `capabilities/`
- `components/`
- `core/`
- `lib/`
- `templates/`
- `verticals/`
- root compatibility `TemplateNetworkApp.tsx`

It intentionally excludes `qa/`, `archive/`, generated `.next/`, scripts, and the historical root Phase-2 spec so an unrelated certified/archived test problem cannot hide current application defects.

## High-signal failures
The lint profile treats these as errors:

- parser/syntax failures;
- unreachable code / duplicate keys / import assignment;
- awaiting non-Promise values;
- Promise misuse in synchronous callbacks;
- confusing void expressions;
- unnecessary type assertions;
- React hook rule violations;
- Next.js recommended correctness rules.

It initially reports these as warnings rather than blocking adoption:

- impossible/unnecessary conditions;
- floating promises;
- unnecessary `async` functions;
- unused variables;
- hook dependency gaps.

Once the existing warning backlog is understood, selected warnings can be promoted to errors without making the first lint rollout unusably noisy.

## Validation performed in this packaging environment
- Whole live app syntax scan: **331 TS/TSX files, 0 syntax failures**
- `TemplateNetworkApp.tsx` compatibility entry: PASS
- `components/TemplateNetworkApp.tsx` syntax-transpile: PASS
- `components/shared/NetworkPostsPanel.tsx` syntax-transpile: PASS
- E10 source gate: 17/17 PASS
- E9 source gate: 16/16 PASS
- E1→E8 dependency gates: PASS

The ESLint runtime itself is not preinstalled in the extracted packaging environment. The one-time package install could not complete in this sandbox, so no claim is made that the ESLint runtime pass was executed here. In the normal project workspace run `npm run lint:trustweave:setup` once, then `npm run validate:static`.
