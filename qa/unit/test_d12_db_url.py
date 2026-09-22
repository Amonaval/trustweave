"""URL identity guard tests; no database or credentials needed."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))
from d12_db_url import project_ref_from_db_url  # noqa: E402

REF = "abcdefghijklmnopqrst"
DIRECT = f"postgresql://postgres:encoded%23password@db.{REF}.supabase.co:5432/postgres"
POOLER = f"postgresql://postgres.{REF}:encoded%23password@aws-0-ap-south-1.pooler.supabase.com:5432/postgres"


class DatabaseUrlGuardTest(unittest.TestCase):
    def test_supported_project_bound_urls(self):
        self.assertEqual(project_ref_from_db_url(DIRECT), REF)
        self.assertEqual(project_ref_from_db_url(POOLER), REF)

    def test_refuses_unsafe_or_ambiguous_endpoints(self):
        variants = [
            POOLER.replace(":5432/", ":6543/"),
            POOLER.replace(f"postgres.{REF}:", "postgres:"),
            POOLER.replace("pooler.supabase.com", "pooler.supabase.com.attacker.test"),
            POOLER.replace("aws-0-ap-south-1", "evil"),
            DIRECT.replace(f"db.{REF}.supabase.co", f"db.{REF}.supabase.co.attacker.test"),
            DIRECT.replace(":5432/", ":6543/"),
            DIRECT.replace("/postgres", "/another"),
            DIRECT.replace("postgresql://", "http://"),
            DIRECT.replace("encoded%23password", ""),
            DIRECT + "?hostaddr=127.0.0.1",
            POOLER + "?sslmode=disable",
            DIRECT + "#fragment",
            DIRECT.replace(REF, "short"),
            "not a url",
        ]
        for value in variants:
            with self.subTest(value=value):
                self.assertIsNone(project_ref_from_db_url(value))


if __name__ == "__main__":
    unittest.main()
