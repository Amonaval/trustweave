#!/usr/bin/env python3
"""Validate the committed TrustWeave D12 canonical bootstrap release.

This command is intentionally database-free. It verifies that the permanent
Git release is internally consistent and still byte-identical to its manifest.

It fails closed on:
- unexpected release status/format;
- path traversal or duplicate manifest paths;
- missing/extra SQL files;
- checksum drift;
- invalid direct/owner-context apply partitions;
- unexpected object counts or reviewed source-drift repairs;
- credential-like content in SQL;
- apply-order drift.

A PASS here proves repository integrity only. Fresh Supabase replay/parity is a
separate D12 certification layer.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
from typing import Any


FORMAT = "trustweave-d12-canonical-baseline-v1"
STATUS = "CANONICAL_CURRENT_STATE"
EXPECTED_SQL_FILES = 95
EXPECTED_DIRECT_FILES = 94
EXPECTED_OWNER_CONTEXT = ["71-storage-owner-context/000-storage-policies.sql"]
EXPECTED_OBJECT_COUNTS = {
    "relations": 167,
    "columns": 1743,
    "constraints": 981,
    "indexes": 401,
    "captured_functions": 463,
    "canonical_functions": 465,
    "triggers": 10,
    "policies": 97,
    "sequences": 6,
}
EXPECTED_REPAIRS = {
    "public.set_network_notification_role(text,text,uuid,boolean)",
    "public.remove_network_notification_role(text,uuid)",
}
EXPECTED_BOOTSTRAP_FUNCTIONS = {
    "public.a4_safe_external_url(p_url text, p_kind text)",
    "public.current_network_id()",
}
FORBIDDEN = (
    re.compile(r"postgres(?:ql)?://", re.I),
    re.compile(r"sb_secret_[A-Za-z0-9_-]+"),
    re.compile(r"eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}"),
)
PHASE_ORDER = [
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
    "71-storage-owner-context",
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


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_git_text(path: Path) -> str:
    """Hash LF-normalized text; used for pure-text cross-platform checks."""
    return sha256_bytes(path.read_bytes().replace(b"\r\n", b"\n"))


def matches_reviewed_content(local: bytes, blob: bytes, expected: str) -> bool:
    return (
        sha256_bytes(blob) == expected
        and local.replace(b"\r\n", b"\n") == blob.replace(b"\r\n", b"\n")
    )


def matches_reviewed_git_bytes(path: Path, expected: str, project: Path) -> bool:
    """Accept an EOL-transformed checkout only when its Git blob is reviewed."""
    local = path.read_bytes()
    if sha256_bytes(local) == expected:
        return True
    try:
        relative = path.resolve().relative_to(project.resolve()).as_posix()
    except ValueError:
        return False
    result = subprocess.run(
        ["git", "show", f"HEAD:{relative}"],
        cwd=project,
        capture_output=True,
        check=False,
    )
    blob = result.stdout
    return result.returncode == 0 and matches_reviewed_content(local, blob, expected)


def safe_relative(root: Path, rel: str) -> Path:
    if not rel or rel.startswith("/") or "\\" in rel:
        raise ValueError(f"unsafe manifest path: {rel!r}")
    path = (root / rel).resolve()
    try:
        path.relative_to(root.resolve())
    except ValueError as exc:
        raise ValueError(f"manifest path escapes release root: {rel}") from exc
    return path


def validate(root: Path) -> dict[str, Any]:
    project = Path(__file__).resolve().parent.parent
    errors: list[str] = []
    warnings: list[str] = []
    manifest_path = root / "manifest.json"
    apply_order_path = root / "APPLY_ORDER.txt"

    if not manifest_path.is_file():
        return {"status": "FAIL", "errors": [f"manifest missing: {manifest_path}"]}
    if not apply_order_path.is_file():
        errors.append(f"APPLY_ORDER.txt missing: {apply_order_path}")

    manifest = load_json(manifest_path)
    if manifest.get("format") != FORMAT:
        errors.append(f"unexpected manifest format: {manifest.get('format')!r}")
    if manifest.get("status") != STATUS:
        errors.append(f"unexpected manifest status: {manifest.get('status')!r}")

    golden_ref = str(manifest.get("golden_project_ref") or "").strip()
    candidate_ref = str(manifest.get("candidate_project_ref") or "").strip()
    if not golden_ref or not candidate_ref:
        errors.append("manifest golden/candidate project refs must be present")
    if golden_ref and golden_ref == candidate_ref:
        errors.append("manifest candidate project ref equals golden project ref")

    counts = manifest.get("object_counts") or {}
    for key, expected in EXPECTED_OBJECT_COUNTS.items():
        if int(counts.get(key) or 0) != expected:
            errors.append(
                f"object_counts.{key}: expected {expected}, got {counts.get(key)!r}"
            )

    repairs = set(manifest.get("explicit_source_drift_repairs") or [])
    if repairs != EXPECTED_REPAIRS:
        errors.append(
            "explicit source-drift repairs changed: "
            f"expected={sorted(EXPECTED_REPAIRS)} actual={sorted(repairs)}"
        )

    bootstrap_functions = set(manifest.get("bootstrap_functions") or [])
    if bootstrap_functions != EXPECTED_BOOTSTRAP_FUNCTIONS:
        errors.append(
            "bootstrap function set changed: "
            f"expected={sorted(EXPECTED_BOOTSTRAP_FUNCTIONS)} "
            f"actual={sorted(bootstrap_functions)}"
        )

    all_records = manifest.get("all_files") or []
    direct = [str(x) for x in (manifest.get("direct_apply_order") or [])]
    owner = [str(x) for x in (manifest.get("storage_owner_context_files") or [])]

    if len(all_records) != EXPECTED_SQL_FILES:
        errors.append(
            f"expected {EXPECTED_SQL_FILES} manifest SQL records, found {len(all_records)}"
        )
    if len(direct) != EXPECTED_DIRECT_FILES:
        errors.append(
            f"expected {EXPECTED_DIRECT_FILES} direct-apply files, found {len(direct)}"
        )
    if owner != EXPECTED_OWNER_CONTEXT:
        errors.append(
            f"owner-context files changed: expected={EXPECTED_OWNER_CONTEXT} actual={owner}"
        )

    records: dict[str, dict[str, Any]] = {}
    for row in all_records:
        if not isinstance(row, dict):
            errors.append("manifest all_files contains a non-object record")
            continue
        rel = str(row.get("path") or "")
        if rel in records:
            errors.append(f"duplicate manifest file path: {rel}")
            continue
        records[rel] = row

    manifest_paths = set(records)
    direct_set = set(direct)
    owner_set = set(owner)
    if direct_set & owner_set:
        errors.append(f"direct and owner-context sets overlap: {sorted(direct_set & owner_set)}")
    if direct_set | owner_set != manifest_paths:
        errors.append(
            "direct + owner-context apply sets do not exactly cover manifest SQL files"
        )

    rank = {phase: i for i, phase in enumerate(PHASE_ORDER)}
    # direct_apply_order is the transactional database-context sequence.
    # Storage owner-context is deliberately applied later through hosted
    # Supabase platform/owner context and must not be inserted into that order.
    observed_direct: list[int] = []
    for rel in direct:
        phase = rel.split("/", 1)[0]
        if phase not in rank:
            errors.append(f"unknown bootstrap phase: {phase} ({rel})")
        else:
            observed_direct.append(rank[phase])
    if observed_direct != sorted(observed_direct):
        errors.append("manifest direct_apply_order is not phase-first")

    for rel in owner:
        phase = rel.split("/", 1)[0]
        if phase != "71-storage-owner-context":
            errors.append(f"unexpected owner-context phase: {phase} ({rel})")

    actual_sql: set[str] = set()
    for p in root.rglob("*.sql"):
        actual_sql.add(str(p.relative_to(root)).replace("\\", "/"))
    if actual_sql != manifest_paths:
        errors.append(
            "SQL tree differs from manifest: "
            f"missing={sorted(manifest_paths - actual_sql)} "
            f"extra={sorted(actual_sql - manifest_paths)}"
        )

    checked = 0
    total_bytes = 0
    for rel, row in sorted(records.items()):
        try:
            path = safe_relative(root, rel)
        except ValueError as exc:
            errors.append(str(exc))
            continue
        if path.suffix.lower() != ".sql":
            errors.append(f"manifest payload is not SQL: {rel}")
            continue
        if not path.is_file():
            errors.append(f"manifest SQL missing: {rel}")
            continue

        expected_hash = str(row.get("sha256") or "")
        actual_hash = sha256_bytes(path.read_bytes())
        if not matches_reviewed_git_bytes(path, expected_hash, project):
            errors.append(
                f"checksum mismatch: {rel}: expected {expected_hash}, got {actual_hash}"
            )

        try:
            sql = path.read_text(encoding="utf-8", errors="strict")
        except UnicodeDecodeError:
            errors.append(f"SQL is not valid UTF-8: {rel}")
            continue
        for pattern in FORBIDDEN:
            if pattern.search(sql):
                errors.append(
                    f"credential-like content detected in {rel}: {pattern.pattern}"
                )

        checked += 1
        total_bytes += path.stat().st_size

    if apply_order_path.is_file():
        order_text = apply_order_path.read_text(encoding="utf-8")
        positions: list[int] = []
        for rel in direct + owner:
            pos = order_text.find(rel)
            if pos < 0:
                errors.append(f"APPLY_ORDER.txt missing manifest path: {rel}")
            else:
                positions.append(pos)
        if positions and positions != sorted(positions):
            errors.append("APPLY_ORDER.txt order differs from manifest order")

    if manifest.get("primary_capture_sha256") != (
        "074f89728fce44712b81627ef5f0dbcae76b6627ba321bd11720f285e9c0acc1"
    ):
        errors.append("primary capture SHA changed from the reviewed D12 evidence")
    # The canonical release was rebuilt from the reconstructed supplement capture
    # used for final certification, not the earlier failed SQL-editor export.
    if manifest.get("supplement_capture_sha256") != (
        "5a2a2c5f301ef9606a90f254b98fafae5a8477ab13ccb5ce68052dd66d639c47"
    ):
        errors.append("supplement capture SHA changed from the promoted D12 evidence")

    if not errors:
        warnings.append(
            "Repository integrity PASS does not replace fresh-project structural/security/API/"
            "behavior/browser parity."
        )

    return {
        "format": "trustweave-d12-bootstrap-validation-v1",
        "status": "PASS" if not errors else "FAIL",
        "release_root": str(root),
        "checked_sql_files": checked,
        "sql_bytes": total_bytes,
        "direct_apply_files": len(direct),
        "owner_context_files": owner,
        "golden_project_ref": golden_ref,
        "candidate_project_ref": candidate_ref,
        "errors": errors,
        "warnings": warnings,
    }


def main() -> None:
    project = Path(__file__).resolve().parent.parent
    default_root = (
        project
        / "supabase"
        / "bootstrap"
        / "releases"
        / "2026-09-20-d12"
    )
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release-root", type=Path, default=default_root)
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print the validation report as JSON.",
    )
    args = parser.parse_args()

    root = args.release_root.resolve()
    report = validate(root)
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print(
            "D12 bootstrap validation: "
            f"{report['status']} "
            f"(sql={report['checked_sql_files']}, bytes={report['sql_bytes']})"
        )
        for warning in report["warnings"]:
            print(f"warning: {warning}")
        for error in report["errors"]:
            print(f"error: {error}")

    if report["status"] != "PASS":
        raise SystemExit(1)


if __name__ == "__main__":
    main()
