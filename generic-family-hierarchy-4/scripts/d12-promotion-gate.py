#!/usr/bin/env python3
"""Evaluate whether D12 evidence is ready for canonical-promotion review.

This gate is read-only. It never copies generated SQL into permanent canonical
source and never changes bootstrap/migrations. Passing means the founder may review
promotion; it does not silently promote anything.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def load(path: Path) -> dict[str, Any]:
    if not path.is_file():
        raise SystemExit(f"Required D12 evidence missing: {path}")
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise SystemExit(f"Invalid D12 evidence JSON: {path}")
    return value


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--candidate-root",
        type=Path,
        default=Path(".d12-work") / "candidate",
    )
    parser.add_argument(
        "--behavior-report",
        type=Path,
        default=Path("qa-results") / "d12-candidate-parity" / "SUMMARY.json",
    )
    args = parser.parse_args()

    root = args.candidate_root.resolve()
    static_gate = load(root / "static-gate.json")
    apply_receipt = load(root / "apply-receipt.json")
    catalog = load(root / "catalog-parity.json")
    behavior = load(args.behavior_report.resolve())

    errors: list[str] = []
    review_warnings: list[Any] = list(catalog.get("warnings") or [])

    if static_gate.get("status") != "PASS":
        errors.append("Static candidate gate is not PASS.")
    if apply_receipt.get("status") != "APPLIED_TO_DISPOSABLE_CANDIDATE":
        errors.append("Disposable candidate apply receipt is not PASS.")
    if catalog.get("status") != "PASS":
        errors.append("Structural/security/API catalog parity is not PASS.")
    if behavior.get("status") != "D12_BEHAVIOR_BROWSER_PARITY_PASS":
        errors.append("Behavioral/browser parity is not PASS.")

    candidate_ref = str(apply_receipt.get("candidate_project_ref") or "").lower()
    golden_ref = str(apply_receipt.get("golden_project_ref") or "").lower()
    behavior_candidate = str(behavior.get("candidateProjectRef") or "").lower()
    behavior_golden = str(behavior.get("goldenProjectRef") or "").lower()
    if not candidate_ref or not golden_ref or candidate_ref == golden_ref:
        errors.append("Apply receipt does not prove distinct candidate/golden project refs.")
    if behavior_candidate != candidate_ref:
        errors.append("Behavior report candidate ref does not match apply receipt.")
    if behavior_golden != golden_ref:
        errors.append("Behavior report golden ref does not match apply receipt.")

    layers = catalog.get("layers") or {}
    for layer in ("structural", "security", "api_contract"):
        if (layers.get(layer) or {}).get("status") != "PASS":
            errors.append(f"Catalog parity layer is not PASS: {layer}")

    report = {
        "format": "trustweave-d12-promotion-readiness-v1",
        "status": "READY_FOR_CANONICAL_PROMOTION_REVIEW" if not errors else "NOT_READY",
        "candidate_project_ref": candidate_ref,
        "golden_project_ref": golden_ref,
        "evidence": {
            "static_gate": str(root / "static-gate.json"),
            "apply_receipt": str(root / "apply-receipt.json"),
            "catalog_parity": str(root / "catalog-parity.json"),
            "behavior_browser_parity": str(args.behavior_report.resolve()),
        },
        "review_warnings": review_warnings,
        "errors": errors,
        "automatic_promotion_performed": False,
        "next_step": (
            "founder-review-then-canonical-promotion"
            if not errors
            else "resolve-failed-parity-gates"
        ),
    }
    out = root / "promotion-readiness.json"
    out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"D12 promotion readiness: {report['status']} ({out})")
    if review_warnings:
        print(f"Managed/environment warnings requiring review: {len(review_warnings)}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
