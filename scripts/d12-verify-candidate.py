#!/usr/bin/env python3
"""Recapture and compare a disposable D12 candidate in one guarded command.

Requires D12_CANDIDATE_DATABASE_URL locally. No database URL is accepted on argv.
This wrapper runs d12-capture-candidate.py and then d12-compare-catalogs.py.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import sys


def run(command: list[str], cwd: Path) -> None:
    proc = subprocess.run(command, cwd=cwd)
    if proc.returncode:
        raise SystemExit(proc.returncode)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("golden_primary", type=Path)
    parser.add_argument("--golden-supplement", required=True, type=Path)
    parser.add_argument("--candidate-project-ref", required=True)
    parser.add_argument("--golden-project-ref", required=True)
    parser.add_argument(
        "--project",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
    )
    parser.add_argument(
        "--candidate-root",
        type=Path,
        default=Path(".d12-work") / "candidate",
    )
    parser.add_argument("--psql", default="psql")
    args = parser.parse_args()

    project = args.project.resolve()
    root = (
        (project / args.candidate_root).resolve()
        if not args.candidate_root.is_absolute()
        else args.candidate_root.resolve()
    )
    recapture = root / "recapture"
    parity_report = root / "catalog-parity.json"

    apply_receipt = root / "apply-receipt.json"
    if not apply_receipt.is_file():
        raise SystemExit(
            f"Disposable apply receipt missing: {apply_receipt}. "
            "Run d12-apply-candidate.py successfully first."
        )

    run(
        [
            sys.executable,
            str(project / "scripts" / "d12-capture-candidate.py"),
            "--candidate-project-ref",
            args.candidate_project_ref,
            "--golden-project-ref",
            args.golden_project_ref,
            "--project",
            str(project),
            "--out",
            str(recapture),
            "--psql",
            args.psql,
        ],
        project,
    )

    run(
        [
            sys.executable,
            str(project / "scripts" / "d12-compare-catalogs.py"),
            str(args.golden_primary.resolve()),
            "--golden-supplement",
            str(args.golden_supplement.resolve()),
            "--candidate-primary",
            str(recapture / "candidate-primary.csv"),
            "--candidate-supplement",
            str(recapture / "candidate-supplement.csv"),
            "--out",
            str(parity_report),
        ],
        project,
    )

    print(f"D12 candidate catalog verification: PASS ({parity_report})")
    print("Structural, security and API/contract catalog parity passed.")
    print("Next: behavioral and product/browser parity. Candidate is still not canonical.")


if __name__ == "__main__":
    main()
