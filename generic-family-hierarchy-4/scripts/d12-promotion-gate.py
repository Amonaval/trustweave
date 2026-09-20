#!/usr/bin/env python3
"""Evaluate whether D12 evidence is ready for canonical-promotion review.

This gate is read-only. It never copies generated SQL into permanent canonical
source and never changes bootstrap/migrations. Passing means the founder may review
promotion; it does not silently promote anything.

The final managed-SQL replay requires automated connected behavior/browser evidence.
The earlier candidate still accepts either the full automated summary or a strict
pair of database-behavior and founder manual browser evidence with zero blockers.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
from typing import Any

MANAGED_FORMAT = "trustweave-d12-managed-sql-apply-receipt-v1"
MANAGED_STATUS = "MANAGED_SQL_BOOTSTRAP_APPLIED_TO_FRESH_DISPOSABLE"
MANAGED_PROJECT = "yqwitkoxyrujbzpjwuji"
MANAGED_COMMIT = "ce5eddfbedd2a1ab3a92bbd58ac24ca78e57bfe1"
PROMOTED_SUPPLEMENT = "5a2a2c5f301ef9606a90f254b98fafae5a8477ab13ccb5ce68052dd66d639c47"
ORIGINAL_SUPPLEMENT = "0ce6507dc57ae79d96820800f76b5b38ba91e1be82004b3f51591295aaed4743"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate_managed_replay(root: Path, apply: dict[str, Any], catalog: dict[str, Any]) -> list[str]:
    """Bind the promotion decision to the same reviewed fresh replay as QA."""
    errors: list[str] = []
    release = (Path("supabase/bootstrap/CURRENT").read_text(encoding="utf-8")).strip()
    if not release or any(c not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-" for c in release):
        return ["Invalid committed bootstrap release name."]
    release_root = Path("supabase/bootstrap/releases") / release
    validated = subprocess.run(
        [sys.executable, "scripts/d12-validate-bootstrap.py", "--release-root", str(release_root)],
        capture_output=True, text=True, check=False,
    )
    if validated.returncode:
        errors.append("Committed bootstrap integrity validation failed.")
    manifest_path = release_root / "manifest.json"
    if not manifest_path.is_file():
        return errors + ["Committed bootstrap manifest is missing."]
    manifest = load(manifest_path)
    if apply.get("status") != MANAGED_STATUS or apply.get("candidate_project_ref") != MANAGED_PROJECT or apply.get("source_commit") != MANAGED_COMMIT:
        errors.append("Managed-SQL receipt does not identify the reviewed final replay.")
    if apply.get("psql_receipt") is not False or apply.get("direct_apply_transactions") != 8 or apply.get("owner_context_migration") != "d12_final_storage_owner_context":
        errors.append("Managed-SQL execution provenance differs from the reviewed replay.")
    if apply.get("secrets_recorded") is not False or apply.get("manifest_sha256") != sha256(manifest_path):
        errors.append("Managed-SQL receipt fails secret or manifest checksum guard.")
    if apply.get("golden_project_ref") != manifest.get("golden_project_ref") or apply.get("direct_sql_files") != len(manifest.get("direct_apply_order") or []) or apply.get("owner_context_files") != manifest.get("storage_owner_context_files"):
        errors.append("Managed-SQL receipt disagrees with the committed manifest.")
    if any((apply.get("freshness_preflight") or {}).get(k) != 0 for k in ("relations", "functions", "sequences")):
        errors.append("Managed-SQL receipt does not prove an empty project.")
    recapture_path = root / "recapture/recapture-receipt.json"
    if not recapture_path.is_file():
        return errors + ["Managed-SQL candidate recapture receipt is missing."]
    recapture = load(recapture_path)
    if recapture.get("format") != "trustweave-d12-candidate-recapture-v1" or recapture.get("candidate_project_ref") != MANAGED_PROJECT or recapture.get("golden_project_ref") != apply.get("golden_project_ref") or recapture.get("secrets_recorded") is not False:
        errors.append("Managed-SQL recapture project refs or provenance differ.")
    inputs = catalog.get("inputs") or {}
    for label in ("primary", "supplement"):
        capture = root / "recapture" / f"candidate-{label}.csv"
        expected = recapture.get(f"{label}_sha256")
        if not capture.is_file() or not expected or sha256(capture) != expected or inputs.get(f"candidate_{label}_sha256") != expected:
            errors.append(f"Managed-SQL candidate {label} capture checksum differs.")
    if inputs.get("golden_primary_sha256") != manifest.get("primary_capture_sha256") or manifest.get("supplement_capture_sha256") != PROMOTED_SUPPLEMENT or inputs.get("golden_supplement_sha256") != ORIGINAL_SUPPLEMENT:
        errors.append("Managed-SQL golden capture provenance differs from reviewed inputs.")
    return errors


def load(path: Path) -> dict[str, Any]:
    if not path.is_file():
        raise SystemExit(f"Required D12 evidence missing: {path}")
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise SystemExit(f"Invalid D12 evidence JSON: {path}")
    return value


def maybe_load(path: Path) -> dict[str, Any] | None:
    return load(path) if path.is_file() else None


def ref(value: Any, *keys: str) -> str:
    for key in keys:
        candidate = str((value or {}).get(key) or "").strip().lower()
        if candidate:
            return candidate
    return ""


def validate_manual_path(
    database_behavior: dict[str, Any],
    manual_browser: dict[str, Any],
    candidate_ref: str,
    golden_ref: str,
) -> list[str]:
    errors: list[str] = []

    if database_behavior.get("status") != "PASS":
        errors.append("Persisted database behavioral parity is not PASS.")
    if int(database_behavior.get("blocker_count") or 0) != 0:
        errors.append("Database behavioral evidence contains blockers.")

    manual_status = str(manual_browser.get("status") or "")
    if manual_status not in {"PASS", "PASS_WITH_DEFERRED_PREEXISTING_DEFECT"}:
        errors.append(f"Manual browser smoke is not an accepted PASS status: {manual_status!r}.")
    if int(manual_browser.get("blocker_count") or 0) != 0:
        errors.append("Manual browser smoke contains D12 blockers.")

    db_candidate = ref(database_behavior, "candidate_project_ref", "candidateProjectRef")
    db_golden = ref(database_behavior, "golden_project_ref", "goldenProjectRef")
    browser_candidate = ref(manual_browser, "candidate_project_ref", "candidateProjectRef")
    browser_golden = ref(manual_browser, "golden_project_ref", "goldenProjectRef")

    if db_candidate != candidate_ref:
        errors.append("Database behavior candidate ref does not match apply receipt.")
    if db_golden != golden_ref:
        errors.append("Database behavior golden ref does not match apply receipt.")
    if browser_candidate != candidate_ref:
        errors.append("Manual browser candidate ref does not match apply receipt.")
    if browser_golden != golden_ref:
        errors.append("Manual browser golden ref does not match apply receipt.")

    failed_checks = [
        row.get("id")
        for row in database_behavior.get("checks") or []
        if str(row.get("status") or "").upper() != "PASS"
    ]
    if failed_checks:
        errors.append(f"Database behavioral evidence contains failed checks: {failed_checks}")

    for defect in manual_browser.get("deferred_defects") or []:
        if defect.get("blocks_d12_database_promotion") is not False:
            errors.append(
                f"Deferred browser defect is not explicitly non-blocking: {defect.get('id')}"
            )
        if defect.get("existed_before_d12_migration") is not True:
            errors.append(
                f"Deferred browser defect is not proven pre-existing: {defect.get('id')}"
            )
        if defect.get("classification") != "PRE_EXISTING_NON_DATABASE_ROUTING_DEFECT":
            errors.append(
                f"Deferred browser defect has unsupported classification: {defect.get('id')}"
            )

    return errors


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--candidate-root",
        type=Path,
        default=Path(os.environ.get("D12_PARITY_EVIDENCE_ROOT") or (
            ".d12-work/bootstrap-replay" if Path(".d12-work/bootstrap-replay/apply-receipt.json").is_file()
            else ".d12-work/candidate"
        )),
    )
    parser.add_argument(
        "--behavior-report",
        type=Path,
        default=Path("qa-results") / "d12-candidate-parity" / "SUMMARY.json",
    )
    parser.add_argument(
        "--database-behavior-evidence",
        type=Path,
        default=Path("docs") / "architecture" / "D12-DATABASE-BEHAVIOR-EVIDENCE.json",
    )
    parser.add_argument(
        "--manual-browser-evidence",
        type=Path,
        default=Path("docs") / "architecture" / "D12-MANUAL-BROWSER-SMOKE-EVIDENCE.json",
    )
    args = parser.parse_args()

    root = args.candidate_root.resolve()
    apply_receipt = load(root / "apply-receipt.json")
    catalog = load(root / "catalog-parity.json")
    managed = apply_receipt.get("format") == MANAGED_FORMAT
    static_gate = None if managed else load(root / "static-gate.json")

    behavior_path = args.behavior_report.resolve()
    automated_behavior = maybe_load(behavior_path)

    database_behavior_path = args.database_behavior_evidence.resolve()
    manual_browser_path = args.manual_browser_evidence.resolve()
    database_behavior = maybe_load(database_behavior_path)
    manual_browser = maybe_load(manual_browser_path)

    errors: list[str] = []
    review_warnings: list[Any] = list(catalog.get("warnings") or [])

    if managed:
        errors.extend(validate_managed_replay(root, apply_receipt, catalog))
    else:
        if static_gate.get("status") != "PASS":
            errors.append("Static candidate gate is not PASS.")
        if apply_receipt.get("status") != "APPLIED_TO_DISPOSABLE_CANDIDATE":
            errors.append("Disposable candidate apply receipt is not PASS.")
    if managed and catalog.get("format") != "trustweave-d12-catalog-parity-v1":
        errors.append("Managed-SQL catalog parity report has unexpected format.")
    if catalog.get("status") != "PASS":
        errors.append("Structural/security/API catalog parity is not PASS.")

    candidate_ref = ref(apply_receipt, "candidate_project_ref", "candidateProjectRef")
    golden_ref = ref(apply_receipt, "golden_project_ref", "goldenProjectRef")
    if not candidate_ref or not golden_ref or candidate_ref == golden_ref:
        errors.append("Apply receipt does not prove distinct candidate/golden project refs.")

    behavior_mode = ""
    behavior_evidence: dict[str, str] = {}

    if automated_behavior and automated_behavior.get("status") == "D12_BEHAVIOR_BROWSER_PARITY_PASS":
        behavior_mode = "automated"
        behavior_candidate = ref(automated_behavior, "candidateProjectRef", "candidate_project_ref")
        behavior_golden = ref(automated_behavior, "goldenProjectRef", "golden_project_ref")
        if behavior_candidate != candidate_ref:
            errors.append("Automated behavior report candidate ref does not match apply receipt.")
        if behavior_golden != golden_ref:
            errors.append("Automated behavior report golden ref does not match apply receipt.")
        if managed:
            reliability = maybe_load(Path("qa-results/reliability/SUMMARY.json"))
            notification = maybe_load(Path("qa-results/d12-candidate-parity/notification-role-contract.json"))
            steps = automated_behavior.get("steps") or []
            if automated_behavior.get("applyMode") != "managed-bootstrap" or automated_behavior.get("catalogParity") != "PASS" or [
                (step.get("name"), step.get("status")) for step in steps
            ] != [
                ("two-vertical-connected-reliability", "passed"),
                ("notification-role-drift-repair", "passed"),
            ]:
                errors.append("Managed-SQL automated parity summary lacks both completed connected steps.")
            if reliability is None or reliability.get("status") != "CERTIFIED" or reliability.get("mode") != "connected":
                errors.append("Connected reliability summary is absent or not certified.")
            if notification is None or notification.get("status") != "PASSED" or any(
                check.get("status") != "passed" for check in notification.get("checks") or []
            ) or len(notification.get("checks") or []) != 14:
                errors.append("Notification-role contract is absent or incomplete.")
        behavior_evidence["automated_behavior_browser_parity"] = str(behavior_path)
    else:
        if managed:
            behavior_mode = "automated-required"
            errors.append("Final managed replay requires connected automated behavior/browser parity.")
        else:
            behavior_mode = "database-plus-manual-browser-smoke"
            if database_behavior is None:
                errors.append(
                    "Automated behavior/browser report is unavailable/not PASS and database behavior evidence is missing."
                )
            if manual_browser is None:
                errors.append(
                    "Automated behavior/browser report is unavailable/not PASS and manual browser evidence is missing."
                )
            if database_behavior is not None and manual_browser is not None:
                errors.extend(
                    validate_manual_path(
                        database_behavior,
                        manual_browser,
                        candidate_ref,
                        golden_ref,
                    )
                )
                behavior_evidence["database_behavior_parity"] = str(database_behavior_path)
                behavior_evidence["manual_browser_smoke"] = str(manual_browser_path)

    layers = catalog.get("layers") or {}
    for layer in ("structural", "security", "api_contract"):
        if (layers.get(layer) or {}).get("status") != "PASS":
            errors.append(f"Catalog parity layer is not PASS: {layer}")

    report = {
        "format": "trustweave-d12-promotion-readiness-v2",
        "status": "READY_FOR_CANONICAL_PROMOTION_REVIEW" if not errors else "NOT_READY",
        "candidate_project_ref": candidate_ref,
        "golden_project_ref": golden_ref,
        "behavior_evidence_mode": behavior_mode,
        "evidence": {
            **({"committed_bootstrap_manifest": str(
                Path("supabase/bootstrap/releases")
                / Path("supabase/bootstrap/CURRENT").read_text(encoding="utf-8").strip()
                / "manifest.json"
            )} if managed else {"static_gate": str(root / "static-gate.json")}),
            "apply_receipt": str(root / "apply-receipt.json"),
            "catalog_parity": str(root / "catalog-parity.json"),
            **behavior_evidence,
        },
        "review_warnings": review_warnings,
        "errors": errors,
        "automatic_promotion_performed": False,
        "next_step": (
            "canonical-baseline-materialization"
            if not errors
            else "resolve-failed-parity-gates"
        ),
    }
    out = root / "promotion-readiness.json"
    out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"D12 promotion readiness: {report['status']} ({out})")
    print(f"Behavior evidence mode: {behavior_mode}")
    if review_warnings:
        print(f"Managed/environment warnings requiring review: {len(review_warnings)}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
