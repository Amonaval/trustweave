"""Promotion gate regression: fresh managed replay still needs connected evidence."""
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import unittest


PROJECT = Path(__file__).resolve().parents[2]
REF = "yqwitkoxyrujbzpjwuji"
COMMIT = "ce5eddfbedd2a1ab3a92bbd58ac24ca78e57bfe1"


def digest(value):
    return hashlib.sha256(value).hexdigest()


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value), encoding="utf-8")


class ManagedPromotionGate(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "scripts").symlink_to(PROJECT / "scripts", target_is_directory=True)
        (self.root / "supabase").symlink_to(PROJECT / "supabase", target_is_directory=True)
        self.evidence = self.root / "evidence"
        self.evidence.mkdir()
        release = (PROJECT / "supabase/bootstrap/CURRENT").read_text().strip()
        manifest_bytes = (PROJECT / "supabase/bootstrap/releases" / release / "manifest.json").read_bytes()
        manifest = json.loads(manifest_bytes)
        golden = manifest["golden_project_ref"]
        primary, supplement = b"candidate primary\n", b"candidate supplement\n"
        captures = self.evidence / "recapture"
        captures.mkdir()
        (captures / "candidate-primary.csv").write_bytes(primary)
        (captures / "candidate-supplement.csv").write_bytes(supplement)
        write(captures / "recapture-receipt.json", {
            "format": "trustweave-d12-candidate-recapture-v1", "candidate_project_ref": REF,
            "golden_project_ref": golden, "secrets_recorded": False,
            "primary_sha256": digest(primary), "supplement_sha256": digest(supplement),
        })
        write(self.evidence / "apply-receipt.json", {
            "format": "trustweave-d12-managed-sql-apply-receipt-v1",
            "status": "MANAGED_SQL_BOOTSTRAP_APPLIED_TO_FRESH_DISPOSABLE",
            "candidate_project_ref": REF, "golden_project_ref": golden,
            "source_commit": COMMIT, "manifest_sha256": digest(manifest_bytes),
            "direct_sql_files": len(manifest["direct_apply_order"]),
            "direct_apply_transactions": 8,
            "owner_context_files": manifest["storage_owner_context_files"],
            "owner_context_migration": "d12_final_storage_owner_context",
            "freshness_preflight": {"relations": 0, "functions": 0, "sequences": 0},
            "secrets_recorded": False, "psql_receipt": False,
        })
        write(self.evidence / "catalog-parity.json", {
            "format": "trustweave-d12-catalog-parity-v1", "status": "PASS", "warnings": [],
            "layers": {k: {"status": "PASS"} for k in ("structural", "security", "api_contract")},
            "inputs": {
                "golden_primary_sha256": manifest["primary_capture_sha256"],
                "golden_supplement_sha256": "0ce6507dc57ae79d96820800f76b5b38ba91e1be82004b3f51591295aaed4743",
                "candidate_primary_sha256": digest(primary),
                "candidate_supplement_sha256": digest(supplement),
            },
        })
        write(self.root / "qa-results/reliability/SUMMARY.json", {"status": "CERTIFIED", "mode": "connected"})
        write(self.root / "qa-results/d12-candidate-parity/notification-role-contract.json", {
            "status": "PASSED", "checks": [{"status": "passed"} for _ in range(14)],
        })
        self.report = self.root / "qa-results/d12-candidate-parity/SUMMARY.json"
        write(self.report, {
            "status": "D12_BEHAVIOR_BROWSER_PARITY_PASS", "candidateProjectRef": REF,
            "goldenProjectRef": golden, "applyMode": "managed-bootstrap",
            "catalogParity": "PASS", "steps": [
                {"name": "two-vertical-connected-reliability", "status": "passed"},
                {"name": "notification-role-drift-repair", "status": "passed"},
            ],
        })

    def run_gate(self):
        return subprocess.run(
            ["python", "scripts/d12-promotion-gate.py", "--candidate-root", "evidence"],
            cwd=self.root, capture_output=True, text=True, check=False,
        )

    def test_complete_fixture_is_ready_for_review_only(self):
        result = self.run_gate()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        report = json.loads((self.evidence / "promotion-readiness.json").read_text())
        self.assertEqual(report["status"], "READY_FOR_CANONICAL_PROMOTION_REVIEW")
        self.assertIs(report["automatic_promotion_performed"], False)

    def test_absent_connected_browser_evidence_is_not_ready(self):
        self.report.unlink()
        result = self.run_gate()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requires connected automated behavior/browser parity", result.stdout)

    def test_altered_receipt_is_not_ready(self):
        receipt = self.evidence / "apply-receipt.json"
        data = json.loads(receipt.read_text())
        data["manifest_sha256"] = "0" * 64
        write(receipt, data)
        result = self.run_gate()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("manifest checksum guard", result.stdout)

    def test_altered_capture_is_not_ready(self):
        with (self.evidence / "recapture/candidate-primary.csv").open("ab") as file:
            file.write(b"tampered")
        result = self.run_gate()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("candidate primary capture checksum differs", result.stdout)


if __name__ == "__main__":
    unittest.main()
