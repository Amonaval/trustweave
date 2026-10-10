# TrustWeave Runtime Intelligence dogfood

Canonical product source: `Amonaval/runtime-intelligence`.

Pinned R5 baseline: `de8d01ead5c75054a613a483c3830917b9bc8ace`.

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
- `TrustWeave.Root` is profiled at the app boundary and attributed to `app/layout.tsx#RootLayout`.
- `TrustWeave.NetworkApp` is a nested profiled owner and attributed to `components/NetworkApp.tsx`.
- The framework-neutral panel mounts from `runtime-intelligence/panel`.
- R5 adds **Render activity**: profiler-observed commit count, total/average/max recorded render duration, mount/update split, and source attribution by boundary.
- Nested profiler boundaries overlap. Their duration totals are useful within a boundary but must not be summed as exclusive application work.
- Render activity is prioritization evidence only. It does **not** claim why a render happened or that a component is defective.
- Evidence and advisors come from the canonical runtime-intelligence product, not the copied TrustWeave toolkit.

The old `tools/react-runtime-toolkit` tree remains only as historical/transitional code on this branch and is no longer imported by the active app path.

## Validate source wiring

```bash
node scripts/runtime-intelligence-source-gate.mjs
```

## R5 browser dogfood

Start TrustWeave in development mode, keep Runtime Intelligence enabled, and exercise representative flows such as initial network load, navigation between major areas, directory/list views, search/filter changes, and modal/detail flows.

Use the panel to answer:

1. Which profiled boundary accumulated the most recorded render duration within that boundary?
2. Is that concentration repeated across interactions or only initial mount?
3. Can the boundary be located immediately from the displayed source?
4. Are generic advisor opportunities useful and clearly separate from profiler timing evidence?
5. Does React dev/Strict Mode create enough duplicate lifecycle noise to reduce usefulness?

Do not infer state/update cause from timing proximity. If a browser finding shows a real missing signal, that finding should drive the next React hardening work.
