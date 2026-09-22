#!/usr/bin/env python3
"""Capture D12 catalog evidence from a fresh disposable Supabase candidate via psql.

The connection URL is read only from D12_CANDIDATE_DATABASE_URL. The script uses
exactly the repository's read-only D12 capture SQL and writes SQL-Editor-compatible
one-row CSV files locally for the parity comparator.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
from d12_db_url import project_ref_from_db_url


def capture(psql: str, db_url: str, sql_path: Path) -> str:
    env = os.environ.copy()
    env["PGDATABASE"] = db_url
    env["PGSSLMODE"] = "require"
    env["PGCONNECT_TIMEOUT"] = "20"
    proc = subprocess.run(
        [psql, "-X", "-q", "-A", "-t", "--set", "ON_ERROR_STOP=1", "--file", str(sql_path)],
        env=env,
        text=True,
        capture_output=True,
    )
    if proc.returncode:
        if proc.stderr:
            print(proc.stderr, end="", file=__import__("sys").stderr)
        raise SystemExit(proc.returncode)
    lines = [line for line in proc.stdout.splitlines() if line.strip()]
    if len(lines) != 1:
        raise SystemExit(
            f"{sql_path.name}: expected exactly one JSON output row, got {len(lines)}"
        )
    value = lines[0]
    parsed = json.loads(value)
    if not isinstance(parsed, dict):
        raise SystemExit(f"{sql_path.name}: output is not a JSON object")
    return value


def write_csv(path: Path, json_text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=["doc"])
        writer.writeheader()
        writer.writerow({"doc": json_text})


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate-project-ref", required=True)
    parser.add_argument("--golden-project-ref", required=True)
    parser.add_argument(
        "--project",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=Path(".d12-work") / "candidate" / "recapture",
    )
    parser.add_argument("--psql", default="psql")
    args = parser.parse_args()

    candidate_ref = args.candidate_project_ref.strip().lower()
    golden_ref = args.golden_project_ref.strip().lower()
    if not candidate_ref or not golden_ref or candidate_ref == golden_ref:
        raise SystemExit("Candidate and golden project refs must be non-empty and different.")

    db_url = os.environ.get("D12_CANDIDATE_DATABASE_URL", "").strip()
    if not db_url:
        raise SystemExit(
            "D12_CANDIDATE_DATABASE_URL is not set. Keep it local; never paste it into chat or Git."
        )
    detected_ref = project_ref_from_db_url(db_url)
    if detected_ref != candidate_ref:
        raise SystemExit(
            "REFUSING CAPTURE: candidate DB URL does not match --candidate-project-ref."
        )
    if detected_ref == golden_ref:
        raise SystemExit("REFUSING CAPTURE: candidate DB URL resolves to golden project.")

    psql = shutil.which(args.psql)
    if not psql:
        raise SystemExit(f"psql executable not found: {args.psql}")

    project = args.project.resolve()
    out = (project / args.out).resolve() if not args.out.is_absolute() else args.out.resolve()
    primary_sql = project / "scripts" / "d12-capture-reference.sql"
    supplement_sql = project / "scripts" / "d12-capture-supplement.sql"
    if not primary_sql.is_file() or not supplement_sql.is_file():
        raise SystemExit("D12 capture SQL scripts are missing from the repository.")

    primary_json = capture(psql, db_url, primary_sql)
    supplement_json = capture(psql, db_url, supplement_sql)

    primary_csv = out / "candidate-primary.csv"
    supplement_csv = out / "candidate-supplement.csv"
    write_csv(primary_csv, primary_json)
    write_csv(supplement_csv, supplement_json)

    primary_doc = json.loads(primary_json)
    supplement_doc = json.loads(supplement_json)
    receipt = {
        "format": "trustweave-d12-candidate-recapture-v1",
        "candidate_project_ref": candidate_ref,
        "golden_project_ref": golden_ref,
        "server_version": primary_doc.get("server_version"),
        "primary_csv": str(primary_csv),
        "primary_sha256": sha256(primary_csv),
        "supplement_csv": str(supplement_csv),
        "supplement_sha256": sha256(supplement_csv),
        "counts": {
            "relations": len(primary_doc.get("relations") or []),
            "columns": len(primary_doc.get("columns") or []),
            "constraints": len(primary_doc.get("constraints") or []),
            "indexes": len(primary_doc.get("indexes") or []),
            "functions": len(primary_doc.get("functions") or []),
            "triggers": len(primary_doc.get("triggers") or []),
            "policies": len(primary_doc.get("policies") or []),
            "sequences": len(supplement_doc.get("sequences") or []),
        },
        "secrets_recorded": False,
        "next_gate": "catalog-parity",
    }
    receipt_path = out / "recapture-receipt.json"
    receipt_path.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")

    print(f"D12 candidate recapture: PASS ({receipt_path})")
    print(f"Primary: {primary_csv}")
    print(f"Supplement: {supplement_csv}")
    print("Next: compare candidate captures against the golden captures.")


if __name__ == "__main__":
    main()
