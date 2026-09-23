# TrustWeave fresh-database bootstrap

This directory contains **versioned one-time installers** for creating a brand-new TrustWeave Supabase database from zero.

Current immutable base release:

`2026-09-20-d12`

Current post-release tail:

`2026-09-23-post-d12`

For a brand-new project, apply the release named by `CURRENT` and then the consolidated tail named by `POST_CURRENT`. The tail currently brings the fresh-database contract through migration 130 without rewriting the certified D12 release.

See `DEVELOPER_GUIDE.md` for the full operating model.

## Important

- Never apply a bootstrap release to the golden/live database.
- Never apply a bootstrap release to a database that already contains TrustWeave tables.
- Never delete or rewrite `supabase/migrations/` because a bootstrap release exists.
- Bootstrap SQL must contain schema/security/functions/configuration only — never customer rows or Storage object contents.
- Do not add unproven SQL to `POST_CURRENT`; runtime-prove the final contract first, then synchronize the consolidated tail.
