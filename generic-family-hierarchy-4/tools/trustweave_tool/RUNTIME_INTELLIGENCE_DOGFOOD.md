# TrustWeave Runtime Intelligence dogfood

Canonical product source: `Amonaval/runtime-intelligence`.

Pinned R3 baseline: `bf3548c41b23058e99adde58179f9bbf0bef6146`.

## Install for dogfood

From `generic-family-hierarchy-4`:

```bash
node scripts/install-runtime-intelligence.mjs
```

The installer intentionally uses `--no-save --package-lock=false` for this dogfood branch so TrustWeave's large application manifest/lockfile are not churned before the package is publication-ready. R6 will own persistent package distribution.

## Runtime behavior

- Development only. Production returns the application unchanged.
- Enabled by default in development.
- `?twdebug=0` disables it for the browser session.
- `?twdebug=1` re-enables it.
- `TrustWeave.Root` is profiled at the app boundary.
- `TrustWeave.NetworkApp` is a nested profiled owner.
- The framework-neutral panel mounts from `runtime-intelligence/panel`.
- Evidence and advisors come from the canonical runtime-intelligence product, not the copied TrustWeave toolkit.

The old `tools/react-runtime-toolkit` tree remains only as historical/transitional code on this branch and is no longer imported by the active app path.

## Validate source wiring

```bash
node scripts/runtime-intelligence-source-gate.mjs
```
