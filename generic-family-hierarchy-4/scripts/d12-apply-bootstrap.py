#!/usr/bin/env python3
"""Apply the committed D12 bootstrap to a fresh disposable Supabase database.

SAFETY CONTRACT:
- never accepts a database URL on argv;
- reads D12_BOOTSTRAP_DATABASE_URL from the local environment only;
- requires explicit candidate and golden project refs;
- refuses when candidate == golden;
- requires the golden ref to match the committed release manifest;
- accepts only candidate-bound direct or Supabase session-pooler URLs;
- validates every committed bootstrap checksum before connecting;
- refuses any database with existing public relations/functions/sequences;
- applies only manifest direct_apply_order in one psql transaction;
- leaves Storage owner-context SQL for Supabase platform/dashboard execution.

This is a destructive schema bootstrap and is intentionally restricted to a
fresh disposable project. Never point it at the golden/live TrustWeave DB.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from d12_db_url import project_ref_from_db_url


CONFIRM = "APPLY-D12-BOOTSTRAP-TO-FRESH-DISPOSABLE"


def load_json(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: expected JSON object")
    return value


def run_capture(command: list[str], env: dict[str, str]) -> str:
    proc = subprocess.run(
        command,
        env=env,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if proc.returncode:
        if proc.stderr:
            print(proc.stderr, file=sys.stderr)
        raise SystemExit(proc.returncode)
    return proc.stdout.strip()


def main() -> None:
    project = Path(__file__).resolve().parent.parent
    default_release = (
        project
        / "supabase"
        / "bootstrap"
        / "releases"
        / "2026-09-20-d12"
    )

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release-root", type=Path, default=default_release)
    parser.add_argument("--candidate-project-ref", required=True)
    parser.add_argument("--golden-project-ref", required=True)
    parser.add_argument(
        "--confirm",
        required=True,
        help=f"Must be exactly {CONFIRM!r}.",
    )
    parser.add_argument("--psql", default="psql")
    parser.add_argument(
        "--receipt",
        type=Path,
        default=Path(".d12-work") / "bootstrap-replay" / "apply-receipt.json",
    )
    args = parser.parse_args()

    if args.confirm != CONFIRM:
        raise SystemExit("Fresh-disposable confirmation phrase does not match.")

    candidate_ref = args.candidate_project_ref.strip().lower()
    golden_ref = args.golden_project_ref.strip().lower()
    if not candidate_ref or not golden_ref:
        raise SystemExit("Candidate and golden project refs must be non-empty.")
    if candidate_ref == golden_ref:
        raise SystemExit(
            "REFUSING APPLY: candidate project ref equals golden project ref."
        )

    release = args.release_root.resolve()
    manifest_path = release / "manifest.json"
    if not manifest_path.is_file():
        raise SystemExit(f"Committed bootstrap manifest missing: {manifest_path}")
    manifest = load_json(manifest_path)

    committed_golden = str(manifest.get("golden_project_ref") or "").strip().lower()
    if not committed_golden:
        raise SystemExit("REFUSING APPLY: committed manifest has no golden project ref.")
    if committed_golden != golden_ref:
        raise SystemExit(
            "REFUSING APPLY: supplied golden project ref differs from the committed "
            "D12 protected golden ref."
        )

    validator = Path(__file__).resolve().with_name("d12-validate-bootstrap.py")
    if not validator.is_file():
        raise SystemExit(f"Bootstrap validator missing: {validator}")
    validation = subprocess.run(
        [
            sys.executable,
            str(validator),
            "--release-root",
            str(release),
        ],
        check=False,
    )
    if validation.returncode:
        raise SystemExit(
            "REFUSING APPLY: committed D12 bootstrap validation did not PASS."
        )

    db_url = os.environ.get("D12_BOOTSTRAP_DATABASE_URL", "").strip()
    if not db_url:
        raise SystemExit(
            "D12_BOOTSTRAP_DATABASE_URL is not set. Keep the URL local; "
            "never paste it into chat or Git."
        )

    detected_ref = project_ref_from_db_url(db_url)
    if detected_ref is None:
        raise SystemExit(
            "REFUSING APPLY: database URL is not a recognized "
            "candidate-bound Supabase direct or session-pooler URL."
        )
    if detected_ref != candidate_ref:
        raise SystemExit(
            "REFUSING APPLY: database URL project ref does not match "
            "--candidate-project-ref."
        )
    if detected_ref == golden_ref:
        raise SystemExit(
            "REFUSING APPLY: database URL resolves to the golden project ref."
        )

    psql = shutil.which(args.psql)
    if not psql:
        raise SystemExit(f"psql executable not found: {args.psql}")

    env = os.environ.copy()
    # libpq accepts a URI in PGDATABASE. This keeps credentials out of argv and
    # therefore out of normal process listings and receipts.
    env["PGDATABASE"] = db_url
    env["PGSSLMODE"] = "require"
    env["PGCONNECT_TIMEOUT"] = "20"

    # Freshness is non-negotiable: the permanent baseline is never an upgrade
    # mechanism. Existing public application objects mean the target is wrong.
    freshness_sql = r"""
select json_build_object(
  'relations', (
    select count(*)
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind in ('r','p','v','m','f')
  ),
  'functions', (
    select count(*)
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
  ),
  'sequences', (
    select count(*)
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind = 'S'
  )
)::text;
"""
    freshness_raw = run_capture(
        [
            psql,
            "-X",
            "--set",
            "ON_ERROR_STOP=1",
            "--tuples-only",
            "--no-align",
            "--command",
            freshness_sql,
        ],
        env,
    )
    try:
        freshness = json.loads(freshness_raw)
    except json.JSONDecodeError as exc:
        raise SystemExit(
            f"REFUSING APPLY: could not parse fresh-database preflight: {freshness_raw!r}"
        ) from exc

    nonempty = {
        key: int(freshness.get(key) or 0)
        for key in ("relations", "functions", "sequences")
    }
    if any(nonempty.values()):
        raise SystemExit(
            "REFUSING APPLY: target is not a fresh public schema: "
            f"{nonempty}. Create/use a new disposable Supabase project."
        )

    direct_order = [str(x) for x in (manifest.get("direct_apply_order") or [])]
    if not direct_order:
        raise SystemExit("REFUSING APPLY: committed manifest has no direct apply order.")

    sql_files: list[Path] = []
    for rel in direct_order:
        path = (release / rel).resolve()
        try:
            path.relative_to(release)
        except ValueError as exc:
            raise SystemExit(
                f"REFUSING APPLY: manifest path escapes release root: {rel}"
            ) from exc
        if not path.is_file():
            raise SystemExit(f"REFUSING APPLY: bootstrap SQL missing: {path}")
        sql_files.append(path)

    command = [
        psql,
        "-X",
        "--set",
        "ON_ERROR_STOP=1",
        "--single-transaction",
    ]
    for path in sql_files:
        command.extend(["--file", str(path)])

    print(
        "D12 committed bootstrap apply: "
        f"candidate={candidate_ref}, direct_files={len(sql_files)}"
    )
    print("Fresh public schema preflight: PASS.")
    print("Golden project is protected by manifest + project-ref mismatch checks.")
    print("Database URL is read from local environment and will not be printed.")

    proc = subprocess.run(command, env=env)
    if proc.returncode:
        print(
            "D12 committed bootstrap apply: FAILED; the psql transaction should "
            "have rolled back.",
            file=sys.stderr,
        )
        raise SystemExit(proc.returncode)

    owner_context = list(manifest.get("storage_owner_context_files") or [])
    receipt_path = args.receipt
    if not receipt_path.is_absolute():
        receipt_path = (project / receipt_path).resolve()
    receipt_path.parent.mkdir(parents=True, exist_ok=True)

    receipt = {
        "format": "trustweave-d12-bootstrap-replay-apply-receipt-v1",
        "status": "DIRECT_BOOTSTRAP_APPLIED_TO_FRESH_DISPOSABLE",
        "candidate_project_ref": candidate_ref,
        "golden_project_ref": golden_ref,
        "release_root": str(release),
        "manifest_sha256": hashlib.sha256(manifest_path.read_bytes()).hexdigest(),
        "direct_sql_files": len(sql_files),
        "owner_context_files": owner_context,
        "owner_context_required": bool(owner_context),
        "freshness_preflight": nonempty,
        "secrets_recorded": False,
        "next_gate": (
            "apply-storage-owner-context-then-catalog-parity"
            if owner_context
            else "catalog-parity"
        ),
    }
    receipt_path.write_text(
        json.dumps(receipt, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"D12 committed bootstrap apply: PASS ({receipt_path})")
    if owner_context:
        print(
            "Next: apply Storage owner-context SQL with Supabase platform/dashboard "
            "tooling, then run catalog parity."
        )


if __name__ == "__main__":
    main()
