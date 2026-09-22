# MPF East Playground Screenshot Capture

Local-only showcase helper. It does not modify product data and uses the read-only **Family Community / Cultural Association Playground**.

## Status

Best-effort local showcase helper only. It is **not** a release/certification gate and should not block product work if UI selectors evolve. The primary product requirement is that anonymous Discovery can enter the read-only Family Community Playground; this helper only records that experience for sharing.

## 1. Start TrustWeave locally

From `generic-family-hierarchy-4`:

```bash
npm run dev
```

Keep it running.

## 2. Capture desktop screenshots

Open a second terminal in the same folder:

```bash
node qa/showcase/capture-mpf-east.mjs --base-url=http://127.0.0.1:3000
```

The script captures:

- public landing/discovery;
- Family Community public explanation;
- MPF Pune East Playground home;
- every visible Playground navigation surface;
- progressive sub-sections exposed through section selectors;
- directory modes: All / Families / Representatives / Members;
- one member/family profile detail;
- both Family Structure modes where available.

Output is created under:

```text
artifact/mpf-east-showcase/<timestamp>/desktop/
```

Each run also creates an `INDEX.md` with the ordered screenshots.

## Optional modes

### Desktop + mobile

```bash
node qa/showcase/capture-mpf-east.mjs --base-url=http://127.0.0.1:3000 --mode=both
```

### Mobile only

```bash
node qa/showcase/capture-mpf-east.mjs --base-url=http://127.0.0.1:3000 --mode=mobile
```

### Watch the browser while it captures

```bash
node qa/showcase/capture-mpf-east.mjs --base-url=http://127.0.0.1:3000 --headed --slow-mo=250
```

### Capture deployed Vercel instead of localhost

```bash
node qa/showcase/capture-mpf-east.mjs --base-url=https://YOUR-VERCEL-APP.vercel.app
```

## Notes

- No login is required for the public Playground.
- No database writes are intentionally performed.
- The utility does not need any new npm dependency; it uses the Playwright package already present in TrustWeave.
- If Chromium is not installed locally, install it only when you intentionally want to run this helper; the helper itself adds no application dependency.
- Use `--max-screens=120` if future Playground expansion exceeds the default safety cap of 80 screenshots.


## Compatibility note (v2)

The Playground entry no longer requires only
`qa-vertical-shell-family-association`. The capture waits for any of the
current stable product-shell/navigation markers and writes a screenshot plus
HTML under `_diagnostics/` if Playground entry still cannot be recognized.

This makes the utility tolerant of QA-id changes without changing application
code.


## Community Playground entry (v4)

The script now actually changes the MJS flow itself:

1. Open **Explore Family Community**
2. Wait for the community context page
3. Find the visible Playground CTA (`Try Playground` or `Explore realistic community Playground`)
4. Click it
5. Wait for the Family Association product shell

If no Playground CTA is found, a diagnostic HTML + screenshot is written.