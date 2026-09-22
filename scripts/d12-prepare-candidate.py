#!/usr/bin/env python3
"""Prepare and statically gate the TrustWeave D12 fresh-database candidate.

This script never connects to a database. It orchestrates the D12 classifier and
reconstruction generator against the two read-only catalog captures, then fails
closed on unreviewed source/live differences or an invalid generated manifest.

Raw captures stay outside Git. The output remains a disposable candidate until
all five D12 parity layers pass against a fresh Supabase project.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
from typing import Any


KNOWN_MISSING = {
    "public.set_network_notification_role(text,text,uuid,boolean)",
    "public.remove_network_notification_role(text,uuid)",
}
KNOWN_EXTRA_PREFIXES = {
    "public.reconcile_network_media_usage(",
}
KNOWN_DIFFERENT_BY_DESIGN = {
    "supabase_migrations.schema_migrations",
}
EXPECTED_PHASES = [
    "00-foundation",
    "05-sequences",
    "08-bootstrap-functions",
    "10-tables",
    "15-sequence-ownership",
    "20-constraints",
    "30-indexes",
    "40-functions",
    "45-source-drift-repairs",
    "50-triggers",
    "60-security",
    "70-storage",
    "75-schema-grants",
    "80-table-grants",
    "85-sequence-grants",
    "90-function-grants",
]


def load_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: expected JSON object")
    return value


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(command: list[str], cwd: Path) -> None:
    proc = subprocess.run(command, cwd=cwd)
    if proc.returncode:
        raise SystemExit(proc.returncode)


def is_known_extra(obj: str) -> bool:
    return any(obj.startswith(prefix) for prefix in KNOWN_EXTRA_PREFIXES)


def verify_classification(value: dict[str, Any]) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    graph = value.get("module_graph_validation") or {}
    if graph.get("valid") is not True:
        errors.append(
            "Canonical module graph is invalid: "
            f"unknown={graph.get('unknown_dependencies')} cycles={graph.get('cycles')}"
        )

    violations = value.get("schema_dependency_violations") or []
    if violations:
        errors.append(f"Live FK/module dependency violations remain: {len(violations)}")

    app_contracts = value.get("application_rpc_contracts") or {}
    missing_rpc_names = set(app_contracts.get("missing_live_names") or [])
    allowed_rpc_names = {
        "set_network_notification_role",
        "remove_network_notification_role",
    }
    unexpected_rpc = sorted(missing_rpc_names - allowed_rpc_names)
    if unexpected_rpc:
        errors.append(f"Unreviewed application RPCs are missing live: {unexpected_rpc}")
    if missing_rpc_names != allowed_rpc_names:
        warnings.append(
            "Current missing-live RPC names differ from the captured D12 expectation: "
            f"{sorted(missing_rpc_names)}"
        )

    for row in value.get("inventory") or []:
        classification = str(row.get("classification") or "").upper()
        obj = str(row.get("object") or "")
        if classification == "MISSING" and obj not in KNOWN_MISSING:
            errors.append(f"Unreviewed MISSING object: {obj}")
        elif classification == "EXTRA" and not is_known_extra(obj):
            errors.append(f"Unreviewed EXTRA object: {obj}")
        elif classification == "DRIFT":
            errors.append(f"Unreviewed DRIFT object: {obj}")
        elif classification == "DIFFERENT-BY-DESIGN" and obj not in KNOWN_DIFFERENT_BY_DESIGN:
            errors.append(f"Unreviewed DIFFERENT-BY-DESIGN object: {obj}")

    return errors, warnings


def verify_manifest(
    manifest: dict[str, Any],
    classification: dict[str, Any],
    primary: Path,
    supplement: Path,
) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    if manifest.get("status") != "candidate-until-fresh-parity":
        errors.append("Generated baseline is not marked candidate-until-fresh-parity.")

    primary_hash = sha256(primary)
    supplement_hash = sha256(supplement)
    expected_hashes = {
        "primary_capture_sha256": primary_hash,
        "supplement_capture_sha256": supplement_hash,
    }
    for key, expected in expected_hashes.items():
        if manifest.get(key) != expected:
            errors.append(f"Manifest {key} does not match supplied capture.")
    if classification.get("primary_sha256") != primary_hash:
        errors.append("Classification primary hash does not match supplied primary capture.")
    if classification.get("supplement_sha256") != supplement_hash:
        errors.append("Classification supplement hash does not match supplied supplement capture.")

    repairs = set(manifest.get("explicit_source_drift_repairs") or [])
    if repairs != KNOWN_MISSING:
        errors.append(
            "Explicit source-drift repairs differ from reviewed notification contracts: "
            f"{sorted(repairs)}"
        )

    apply_order = manifest.get("apply_order") or []
    phase_rank = {phase: index for index, phase in enumerate(EXPECTED_PHASES)}
    observed_ranks: list[int] = []
    for item in apply_order:
        phase = str(item).split("/", 1)[0]
        if phase not in phase_rank:
            errors.append(f"Unknown generated apply phase: {phase}")
            continue
        observed_ranks.append(phase_rank[phase])
    if observed_ranks != sorted(observed_ranks):
        errors.append("Generated manifest apply_order is not phase-first.")

    bootstrap = [str(x).lower() for x in manifest.get("bootstrap_functions") or []]
    for required in ("current_network_id(", "a4_safe_external_url("):
        if not any(required in item for item in bootstrap):
            errors.append(f"Required pre-table bootstrap function missing from manifest: {required}")

    seq = manifest.get("sequence_reconstruction") or {}
    captured = int(seq.get("captured") or 0)
    identity_owned = list(seq.get("identity_owned") or [])
    if captured and len(identity_owned) > captured:
        errors.append("Identity-owned sequence count exceeds captured sequence count.")

    counts = manifest.get("object_counts") or {}
    if int(counts.get("relations") or 0) <= 0:
        errors.append("Generated manifest contains no relations.")
    if int(counts.get("functions") or 0) <= 0:
        errors.append("Generated manifest contains no functions.")

    files = manifest.get("files") or []
    if len(files) != len(apply_order):
        errors.append("Manifest file checksum list does not match apply_order length.")

    if not errors:
        warnings.append(
            "Static gate passed. This does NOT authorize applying the candidate to the golden database."
        )
    return errors, warnings


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("primary", type=Path)
    parser.add_argument("--supplement", required=True, type=Path)
    parser.add_argument(
        "--project",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
    )
    parser.add_argument(
        "--workdir",
        type=Path,
        default=Path(".d12-work") / "candidate",
    )
    parser.add_argument(
        "--keep-existing",
        action="store_true",
        help="Do not delete an existing candidate work directory before generation.",
    )
    args = parser.parse_args()

    project = args.project.resolve()
    primary = args.primary.resolve()
    supplement = args.supplement.resolve()
    workdir = (project / args.workdir).resolve() if not args.workdir.is_absolute() else args.workdir.resolve()

    if not primary.is_file():
        raise SystemExit(f"Primary capture not found: {primary}")
    if not supplement.is_file():
        raise SystemExit(f"Supplement capture not found: {supplement}")

    migrations = (project / "supabase" / "migrations").resolve()
    try:
        workdir.relative_to(migrations)
    except ValueError:
        pass
    else:
        raise SystemExit("Refusing to generate a D12 candidate inside supabase/migrations.")

    if workdir.exists() and not args.keep_existing:
        shutil.rmtree(workdir)
    workdir.mkdir(parents=True, exist_ok=True)

    classification_path = workdir / "classification.json"
    canonical_dir = workdir / "canonical"

    run(
        [
            sys.executable,
            str(project / "scripts" / "d12-classify-catalog.py"),
            str(primary),
            "--supplement",
            str(supplement),
            "--project",
            str(project),
            "--out",
            str(classification_path),
        ],
        project,
    )
    run(
        [
            sys.executable,
            str(project / "scripts" / "d12-reconstruct-canonical.py"),
            str(primary),
            "--supplement",
            str(supplement),
            "--project",
            str(project),
            "--out",
            str(canonical_dir),
        ],
        project,
    )

    classification = load_json(classification_path)
    manifest_path = canonical_dir / "manifest.json"
    manifest = load_json(manifest_path)

    errors, warnings = verify_classification(classification)
    manifest_errors, manifest_warnings = verify_manifest(
        manifest, classification, primary, supplement
    )
    errors.extend(manifest_errors)
    warnings.extend(manifest_warnings)

    report = {
        "format": "trustweave-d12-static-gate-v1",
        "status": "PASS" if not errors else "FAIL",
        "primary_sha256": sha256(primary),
        "supplement_sha256": sha256(supplement),
        "classification": str(classification_path),
        "candidate_manifest": str(manifest_path),
        "errors": errors,
        "warnings": warnings,
        "next_gate": (
            "fresh-disposable-supabase-apply"
            if not errors
            else "resolve-static-gate-errors"
        ),
    }
    report_path = workdir / "static-gate.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    for warning in warnings:
        print(f"WARN: {warning}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        print(f"D12 static gate: FAIL ({report_path})", file=sys.stderr)
        raise SystemExit(1)

    print(f"D12 static gate: PASS ({report_path})")
    print(f"Candidate manifest: {manifest_path}")
    print("Next: apply only to a fresh disposable Supabase project; never the golden project.")


if __name__ == "__main__":
    main()
