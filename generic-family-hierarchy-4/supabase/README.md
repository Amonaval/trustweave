# TrustWeave Supabase database layout

TrustWeave keeps **database history**, **current-state architecture**, and **fresh-database bootstrap** separate on purpose.

## Directory contract

```text
supabase/
├─ migrations/                 # Immutable chronological upgrade history
└─ bootstrap/                  # Versioned one-time installers for a NEW database
```

The canonical architectural model lives separately under:

```text
db/canonical/
├─ modules.json                # Ownership/dependency graph
├─ README.md                   # Reconstruction contract
└─ PROMOTION.json              # Provenance for the promoted baseline
```

## Which path should I use?

### Existing TrustWeave database

Use `supabase/migrations/`.

Never re-run a bootstrap package on an existing database.

### Brand-new empty Supabase project

Use the release identified by:

`supabase/bootstrap/CURRENT`

Read `supabase/bootstrap/DEVELOPER_GUIDE.md` before applying anything.

### Architecture/refinement work

Use `db/canonical/` and the D12 reconstruction/verification tools.

Do not hand-edit the generated bootstrap release as a shortcut around the canonical generator.

## Invariant

A bootstrap release is a **current-state installation artifact**, not migration history.

Historical migration files remain immutable even after a newer bootstrap release exists.
