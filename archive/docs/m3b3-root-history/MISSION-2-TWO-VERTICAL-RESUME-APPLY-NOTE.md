# Mission 2 — Two-Vertical Resume Patch

Current launch QA scope is intentionally limited to:
- `housing-society` (Residential)
- `family-association` (Family Community)

The global product `VERTICALS` registry is unchanged.

## Resume from the already-completed point

This command does not run build/static gates, seed runtime, or the already-run all-vertical smoke/capability suites:

```bash
npm run qa:mission2:resume:2v:headed
```

Headless:

```bash
npm run qa:mission2:resume:2v
```

It requires the existing `qa-results/fixtures/seed-state.json` and starts from the remaining accessibility/resilience/mobile stage.

It intentionally excludes Organization-based lifecycle and 100-row volume suites for the current launch scope.
