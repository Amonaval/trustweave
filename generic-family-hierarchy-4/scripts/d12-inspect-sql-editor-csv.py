#!/usr/bin/env python3
"""Summarize a one-row D12 SQL Editor CSV without copying raw definitions."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import re
import sys


def inspect(path, project):
    csv.field_size_limit(sys.maxsize)
    with path.open(encoding="utf-8-sig", newline="") as stream:
        rows = list(csv.DictReader(stream))
    if len(rows) != 1 or "doc" not in rows[0]:
        raise ValueError("expected exactly one CSV row with a doc column")
    doc = json.loads(rows[0]["doc"])
    required = ("relations", "columns", "functions", "policies", "grants", "extensions", "indexes", "constraints")
    if any(not isinstance(doc.get(k), list) for k in required):
        raise ValueError("missing one or more required catalog arrays")
    migrations = sorted((project / "supabase/migrations").glob("[0-9]*.sql"))
    source = "\n".join(p.read_text(errors="replace") for p in migrations)
    source_functions = {name.lower().replace('"', "").split(".")[-1] for name in re.findall(
        r"\bCREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+((?:\"?\w+\"?\.)?\"?\w+\"?)\s*\(", source, re.I)}
    live_functions = {x["name"].split(".")[-1] for x in doc["functions"]}
    calls = set()
    for directory in ("app", "components", "capabilities", "verticals", "lib", "server"):
        for file in (project / directory).rglob("*"):
            if file.suffix in (".ts", ".tsx", ".js", ".mjs"):
                calls.update(re.findall(r"\.rpc\(\s*['\"]([A-Za-z_][A-Za-z_0-9]*)['\"]", file.read_text(errors="replace")))
    return {
        "capture_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "server_version": doc.get("server_version"),
        "migration_files": len(migrations),
        "counts": {key: len(doc[key]) for key in required},
        "rls_enabled_relations": sum(bool(x["rls"]) for x in doc["relations"]),
        "security_definer_functions": sum(bool(x["security_definer"]) for x in doc["functions"]),
        "migration_relation_present": doc.get("migration_relation_present"),
        "storage_relation_present": doc.get("storage_relation_present"),
        "live_functions_without_literal_source_definition": sorted(live_functions - source_functions),
        "literal_app_rpc_names_absent_from_live": sorted(calls - live_functions),
        "limits": ["Name matching is a triage aid, not definition or signature equivalence.",
                   "CSV does not contain pg_dump DDL, Storage bucket rows, or migration application history."],
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv", type=Path)
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args()
    try:
        print(json.dumps(inspect(args.csv, args.project), indent=2))
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
        print(f"D12 inspect failed: {exc}", file=sys.stderr)
        sys.exit(1)
