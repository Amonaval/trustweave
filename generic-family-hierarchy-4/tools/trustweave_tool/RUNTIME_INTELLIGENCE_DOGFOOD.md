# TrustWeave Runtime Intelligence dogfood

Canonical product source: `Amonaval/runtime-intelligence`.

Pinned cleaned R5 baseline: `d83c417734e866a3bcd06a9ab8b9a12a7b39cbb6`.

## Install for dogfood

From `generic-family-hierarchy-4`:

```bash
node scripts/install-runtime-intelligence.mjs
```

The installer intentionally uses `--no-save --package-lock=false` while package/distribution work is deferred.

## Current runtime behavior

- Development only. Production returns the application unchanged.
- Enabled by default in development.
- `?twdebug=0` disables it for the browser session.
- `?twdebug=1` re-enables it.
- `TrustWeave.Root` is profiled at the app boundary and attributed to `app/layout.tsx#RootLayout`.
- `TrustWeave.NetworkApp` is a nested profiled owner and attributed to `components/NetworkApp.tsx`.
- React evidence is emitted through the canonical Runtime Intelligence React adapter/runtime.
- The temporary lightweight React panel has been removed from active dogfood. It was a parallel product direction and is not part of the target architecture.
- The existing mature `LdsDebugPanel` remains the canonical Runtime Intelligence product UI. R5.2 will adapt its delivery/data boundary so React consumes the same mature product rather than a second panel.

The old `tools/react-runtime-toolkit` tree remains only as historical/transitional code on this branch and is not imported by the active app path.

## Validate source wiring

```bash
node scripts/runtime-intelligence-source-gate.mjs
```

## Next direction

R5.2–R5.6 target 80–90% practical parity with the Lit product by reusing the mature panel, shared collectors and shared intelligence core, while adding only the React-specific evidence translation needed for framework semantics.
