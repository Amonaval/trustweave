#!/usr/bin/env python3
"""Apply a statically-passed D12 candidate to a fresh disposable Supabase database.

SAFETY:
- never accepts a database URL on the command line;
- reads D12_CANDIDATE_DATABASE_URL from the local environment only;
- requires both candidate and golden project refs and refuses if they match;
- verifies the candidate DB host matches the declared candidate project ref;
- requires the static gate to be PASS;
- applies the manifest in one psql transaction with ON_ERROR_STOP.

This script is for a NEW disposable candidate only. Never point it at the golden DB.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from urllib.parse import urlparse


CONFIRM = "APPLY-TO-DISPOSABLE-D12-CANDIDATE"


def load_json(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: expected JSON object")
    return value


def project_ref_from_db_url(value: str) -> str | None:
    try:
        host = (urlparse(value).hostname or "").lower()
    except ValueError:
        return None
    if host.startswith("db.") and host.endswith(".supabase.co"):
        return host[3 : -len(".supabase.co")]
    return None


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--candidate-root",
        type=Path,
        default=Path(".d12-work") / "candidate",
        help="Directory produced by d12-prepare-candidate.py.",
    )
    parser.add_argument("--candidate-project-ref", required=True)
    parser.add_argument("--golden-project-ref", required=True)
    parser.add_argument(
        "--confirm",
        required=True,
        help=f"Must be exactly {CONFIRM!r}.",
    )
    parser.add_argument(
        "--psql",
        default="psql",
        help="psql executable name/path.",
    )
    args = parser.parse_args()

    if args.confirm != CONFIRM:
        raise SystemExit("Disposable-candidate confirmation phrase does not match.")

    candidate_ref = args.candidate_project_ref.strip().lower()
    golden_ref = args.golden_project_ref.strip().lower()
    if not candidate_ref or not golden_ref:
        raise SystemExit("Candidate and golden project refs must be non-empty.")
    if candidate_ref == golden_ref:
        raise SystemExit("REFUSING APPLY: candidate project ref equals golden project ref.")

    db_url = os.environ.get("D12_CANDIDATE_DATABASE_URL", "").strip()
    if not db_url:
        raise SystemExit(
            "D12_CANDIDATE_DATABASE_URL is not set. Keep the URL local; never paste it into chat or Git."
        )

    detected_ref = project_ref_from_db_url(db_url)
    if detected_ref is None:
        raise SystemExit(
            "Candidate DB URL is not a recognized db.<project-ref>.supabase.co URL. "
            "This safety runner intentionally refuses unknown/non-Supabase hosts."
        )
    if detected_ref != candidate_ref:
        raise SystemExit(
            "REFUSING APPLY: database URL project ref does not match --candidate-project-ref."
        )
    if detected_ref == golden_ref:
        raise SystemExit("REFUSING APPLY: database URL resolves to the golden project ref.")

    psql = shutil.which(args.psql)
    if not psql:
        raise SystemExit(f"psql executable not found: {args.psql}")

    root = args.candidate_root.resolve()
    gate_path = root / "static-gate.json"
    canonical = root / "canonical"
    manifest_path = canonical / "manifest.json"

    if not gate_path.is_file():
        raise SystemExit(f"Static gate report missing: {gate_path}")
    if not manifest_path.is_file():
        raise SystemExit(f"Candidate manifest missing: {manifest_path}")

    gate = load_json(gate_path)
    if gate.get("status") != "PASS":
        raise SystemExit("REFUSING APPLY: D12 static gate is not PASS.")

    manifest = load_json(manifest_path)
    if manifest.get("status") != "candidate-until-fresh-parity":
        raise SystemExit("REFUSING APPLY: manifest is not marked as a D12 candidate.")

    apply_order = manifest.get("apply_order") or []
    if not apply_order:
        raise SystemExit("REFUSING APPLY: candidate manifest has no SQL apply_order.")

    sql_files: list[Path] = []
    for rel in apply_order:
        path = (canonical / str(rel)).resolve()
        try:
            path.relative_to(canonical.resolve())
        except ValueError:
            raise SystemExit(f"REFUSING APPLY: manifest path escapes canonical directory: {rel}")
        if not path.is_file():
            raise SystemExit(f"REFUSING APPLY: generated SQL file missing: {path}")
        sql_files.append(path)

    # Keep the connection string out of argv/process listings. libpq accepts a URI in
    # PGDATABASE; the child receives it only through its local environment.
    env = os.environ.copy()
    env["PGDATABASE"] = db_url
    command = [
        psql,
        "-X",
        "--set",
        "ON_ERROR_STOP=1",
        "--single-transaction",
    ]
    for sql_file in sql_files:
        command.extend(["--file", str(sql_file)])

    print(f"D12 disposable apply: candidate={candidate_ref}, files={len(sql_files)}")
    print("Golden project is protected by project-ref mismatch checks.")
    print("Database URL is sourced from the local environment and will not be printed.")

    proc = subprocess.run(command, env=env)
    if proc.returncode:
        print("D12 disposable apply: FAILED; psql transaction should have rolled back.", file=sys.stderr)
        raise SystemExit(proc.returncode)

    receipt = {
        "format": "trustweave-d12-disposable-apply-receipt-v1",
        "status": "APPLIED_TO_DISPOSABLE_CANDIDATE",
        "candidate_project_ref": candidate_ref,
        "golden_project_ref": golden_ref,
        "manifest": str(manifest_path),
        "sql_files": len(sql_files),
        "next_gate": "candidate-recapture-and-parity",
        "secrets_recorded": False,
    }
    receipt_path = root / "apply-receipt.json"
    receipt_path.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(f"D12 disposable apply: PASS ({receipt_path})")
    print("Next: recapture the candidate catalog and compare it with the golden captures.")


if __name__ == "__main__":
    main()
