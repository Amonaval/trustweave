# TrustWeave fresh-database bootstrap

This directory contains **versioned one-time installers** for creating a brand-new TrustWeave Supabase database from zero.

Current release:

`2026-09-20-d12`

See `DEVELOPER_GUIDE.md` for the full operating model.

## Important

- Never apply a bootstrap release to the golden/live database.
- Never apply a bootstrap release to a database that already contains TrustWeave tables.
- Never delete or rewrite `supabase/migrations/` because a bootstrap release exists.
- Bootstrap SQL must contain schema/security/functions/configuration only — never customer rows or Storage object contents.
