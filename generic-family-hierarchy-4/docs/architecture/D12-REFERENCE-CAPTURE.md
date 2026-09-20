# D12 reference capture kit

This is a read-only capture of the existing Supabase PostgreSQL schema. Keep the old project as the golden reference. The kit does not connect to a new project, run migrations, or move customer data. It requires native PostgreSQL client tools (`psql`, `pg_dump`) and Python 3; **Docker is not required**. Install a `pg_dump` major version at least as new as the server's major version.

## Capture on Windows (PowerShell)

Use your existing Supabase dashboard's **Project Settings → Database → Connection string** to configure the database connection on your own computer. Prefer the session pooler if direct IPv6 access is unavailable. Obtain the database password locally; never paste a URL or password into chat or a repository.

```powershell
$env:PGHOST = '<host shown by Supabase>'
$env:PGPORT = '<port shown by Supabase>'
$env:PGUSER = '<database user shown by Supabase>'
$env:PGDATABASE = 'postgres'
$env:PGSSLMODE = 'require'
$env:PGPASSWORD = '<password, only in this local PowerShell session>'
./scripts/d12-capture-reference.ps1
Remove-Item Env:PGPASSWORD
```

Run from `generic-family-hierarchy-4`. These values are placeholders, not defaults. A local `.pgpass` file is also supported by libpq and avoids setting `PGPASSWORD` in shell history. For macOS/Linux, set the corresponding `PG*` environment variables and run `bash scripts/d12-capture-reference.sh`. Alternatively set `TW_D12_DATABASE_URL` locally; it is passed to libpq through the process environment, never a command-line argument. Do not commit the resulting package. The output directory must be empty/new.

The output is `generic-family-hierarchy-4/.d12-reference/` and contains:

| File | Content |
| --- | --- |
| `schema.sql` | Public schema-only `pg_dump`, including constraints, functions, policies and grants; no rows |
| `metadata.json` | Catalog inventory for public/app schemas, roles (names/flags only), extensions, objects, RLS, policies and grants |
| `storage-buckets.json` | Storage bucket configuration; no objects or files |
| `migration-history.json` | Supabase migration version/name inventory; no SQL/data rows |
| `manifest.json` | SHA-256 checksums for capture files |

Run `./scripts/d12-capture-reference.ps1 -ValidateOnly` (or `bash scripts/d12-capture-reference.sh --validate-only`) before sharing. Inspect the package locally for sensitive literals in function bodies, schema comments, bucket names or role names. The scanner rejects likely credentials and data-copy statements, but it cannot prove all content safe. If necessary, redact locally and rerun validation; note any redaction so schema comparison can account for it. Share only these five files with the D12 session.

The scripts use read-only catalog queries and `pg_dump --schema-only`; they do not alter the live database. If the connection lacks catalog permissions, capture fails without producing a complete package. Do not substitute a production data dump or `roles.sql` containing password hashes. A subsequent mission will compare this reference to all 121 historical migration files (`001` through `123`, with reserved gaps `096` and `097`) and application SQL usage before deriving canonical modules.
