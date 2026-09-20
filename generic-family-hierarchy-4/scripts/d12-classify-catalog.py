#!/usr/bin/env python3
"""D12 source↔live inventory/classification helper.

Consumes the one-row SQL Editor primary capture and optional supplement capture.
It never connects to or mutates a database and never copies raw function bodies into
its JSON output. Historical migration SQL is scanned only for object provenance.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path
import re
from typing import Any


def load_capture(path: Path) -> dict[str, Any]:
    csv.field_size_limit(2**31 - 1)
    with path.open(encoding="utf-8-sig", newline="") as stream:
        rows = list(csv.DictReader(stream))
    if len(rows) != 1 or "doc" not in rows[0]:
        raise ValueError(f"{path}: expected one CSV row with a doc column")
    value = json.loads(rows[0]["doc"])
    if not isinstance(value, dict):
        raise ValueError(f"{path}: doc is not a JSON object")
    return value


def sha256_text(value: str | None) -> str | None:
    if value is None:
        return None
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def norm_name(value: str) -> str:
    return value.replace('"', "").lower()


def migration_files(project: Path) -> list[Path]:
    return sorted((project / "supabase" / "migrations").glob("[0-9]*.sql"))


def source_text(files: list[Path]) -> str:
    return "\n".join(f"\n-- FILE:{p.name}\n" + p.read_text(errors="replace") for p in files)


def create_name_set(source: str, kind: str) -> set[str]:
    if kind == "table":
        rx = r"\bcreate\s+table\s+(?:if\s+not\s+exists\s+)?((?:\"?\w+\"?\.)?\"?\w+\"?)"
    elif kind == "function":
        rx = r"\bcreate\s+(?:or\s+replace\s+)?function\s+((?:\"?\w+\"?\.)?\"?\w+\"?)\s*\("
    elif kind == "sequence":
        rx = r"\bcreate\s+sequence\s+(?:if\s+not\s+exists\s+)?((?:\"?\w+\"?\.)?\"?\w+\"?)"
    else:
        raise ValueError(kind)
    return {norm_name(x) for x in re.findall(rx, source, flags=re.I)}


def object_provenance(files: list[Path], object_name: str) -> list[str]:
    leaf = object_name.split(".")[-1].replace('"', "")
    token = re.compile(rf"\b{re.escape(leaf)}\b", re.I)
    return [p.name for p in files if token.search(p.read_text(errors="replace"))]


def module_manifest(project: Path) -> dict[str, Any]:
    path = project / "db" / "canonical" / "modules.json"
    return json.loads(path.read_text(encoding="utf-8"))


def assign_module(name: str, kind: str, manifest: dict[str, Any]) -> str:
    leaf = name.split(".")[-1].replace('"', "").lower()
    rules: dict[str, dict[str, Any]] = manifest["ownership_rules"]
    existing = {m["id"] for m in manifest["modules"]}
    preferred = ["housing", "family-community", "federation", "notifications", "family",
                 "future-specializations", "activity", "workflow", "identity", "platform-core"]
    ordered = [m for m in preferred if m in existing]

    # Exact ownership overrides are evaluated globally before any prefix rule.
    names_key = "table_names" if kind in {"table", "sequence"} else "function_names"
    for module in ordered:
        if leaf in {x.lower() for x in rules.get(module, {}).get(names_key, [])}:
            return module

    for module in ordered:
        rule = rules.get(module, {})
        if kind in {"table", "sequence"}:
            if any(leaf.startswith(x.lower()) for x in rule.get("table_prefixes", [])):
                return module
        else:
            if any(leaf.startswith(x.lower()) for x in rule.get("function_prefixes", [])):
                return module
            if any(x.lower() in leaf for x in rule.get("function_keywords", [])):
                return module
    return "platform-core"


def live_signature(fn: dict[str, Any]) -> str:
    return f"{norm_name(fn['name'])}({fn.get('identity_arguments','').strip().lower()})"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("primary", type=Path)
    ap.add_argument("--supplement", type=Path)
    ap.add_argument("--project", type=Path, default=Path(__file__).resolve().parent.parent)
    ap.add_argument("--out", type=Path)
    args = ap.parse_args()

    project = args.project.resolve()
    primary = load_capture(args.primary)
    supplement = load_capture(args.supplement) if args.supplement else {}
    files = migration_files(project)
    source = source_text(files)
    manifest = module_manifest(project)

    source_tables = create_name_set(source, "table")
    source_functions = create_name_set(source, "function")
    source_sequences = create_name_set(source, "sequence")

    live_tables = {norm_name(x["name"]): x for x in primary.get("relations", []) if x.get("kind") in ("r", "p")}
    live_functions = {live_signature(x): x for x in primary.get("functions", [])}
    live_function_names = {norm_name(x["name"]) for x in primary.get("functions", [])}
    live_sequences = {norm_name(f"{x['schema']}.{x['name']}"): x for x in supplement.get("sequences", [])}

    inventory: list[dict[str, Any]] = []
    for name, rel in sorted(live_tables.items()):
        present = name in source_tables or name.split(".")[-1] in source_tables
        inventory.append({
            "kind": "table", "object": name, "module": assign_module(name, "table", manifest),
            "classification": "MATCH" if present else "EXTRA",
            "evidence_level": "name-only" if present else "live-only-name",
            "rls": bool(rel.get("rls")), "force_rls": bool(rel.get("force_rls")),
            "source_files": object_provenance(files, name),
        })

    confirmed_missing = {
        "public.set_network_notification_role(text,text,uuid,boolean)",
        "public.remove_network_notification_role(text,uuid)",
    }
    for sig, fn in sorted(live_functions.items()):
        name = norm_name(fn["name"])
        source_present = name in source_functions or name.split(".")[-1] in source_functions
        classification = "MATCH" if source_present else "EXTRA"
        if sig == "public.reconcile_network_media_usage(p_network_id uuid)" or name.endswith(".reconcile_network_media_usage"):
            classification = "EXTRA" if not source_present else classification
        inventory.append({
            "kind": "function", "object": sig, "module": assign_module(name, "function", manifest),
            "classification": classification,
            "evidence_level": "name+live-signature" if source_present else "live-only-signature",
            "security_definer": bool(fn.get("security_definer")),
            "config": fn.get("config"),
            "definition_sha256": sha256_text(fn.get("definition")),
            "source_files": object_provenance(files, name),
        })

    # Explicit source/live contract checks stabilized by the supplement capture.
    rpc_presence = supplement.get("contract_rpc_presence", {})
    for sig in sorted(confirmed_missing):
        fname = sig.split("(", 1)[0].split(".")[-1]
        live_present = bool(rpc_presence.get(fname, any(k.startswith(f"public.{fname}(") for k in live_functions)))
        if not live_present:
            inventory.append({
                "kind": "function", "object": sig, "module": "notifications",
                "classification": "MISSING", "drift": True,
                "evidence_level": "exact-signature-presence",
                "source_files": object_provenance(files, fname),
                "reason": "Source/application contract exists but exact live signature is absent.",
            })

    for name, seq in sorted(live_sequences.items()):
        source_present = name in source_sequences or name.split(".")[-1] in source_sequences or name.split(".")[-1] in source.lower()
        inventory.append({
            "kind": "sequence", "object": name, "module": assign_module(name, "sequence", manifest),
            "classification": "MATCH" if source_present else "EXTRA",
            "evidence_level": "name-only",
        })

    inventory.append({
        "kind": "environment", "object": "supabase_migrations.schema_migrations",
        "module": "platform-core", "classification": "DIFFERENT-BY-DESIGN",
        "evidence_level": "exact-regclass-presence",
        "reason": "Migration catalog is not visible in the captured environment; do not infer applied versions from filenames.",
    })

    # Validate the architectural module graph against actual live public foreign keys.
    # depends_on is intentionally a schema/FK graph only; runtime function calls are
    # integration edges and are not required to be acyclic.
    declared = {m["id"]: set(m.get("depends_on", [])) for m in manifest["modules"]}
    edge_counts: dict[tuple[str, str], int] = {}
    edge_examples: dict[tuple[str, str], list[dict[str, str]]] = {}
    for con in primary.get("constraints", []):
        if con.get("kind") != "f":
            continue
        match = re.search(r"\bREFERENCES\s+((?:\"?\w+\"?\.)?\"?\w+\"?)", con.get("definition", ""), flags=re.I)
        if not match:
            continue
        target = norm_name(match.group(1))
        if "." not in target:
            target = "public." + target
        source = norm_name(con["relation"])
        if not source.startswith("public.") or not target.startswith("public."):
            continue
        source_module = assign_module(source, "table", manifest)
        target_module = assign_module(target, "table", manifest)
        if source_module == target_module:
            continue
        key = (source_module, target_module)
        edge_counts[key] = edge_counts.get(key, 0) + 1
        edge_examples.setdefault(key, [])
        if len(edge_examples[key]) < 5:
            edge_examples[key].append({
                "source": source,
                "constraint": con["name"],
                "target": target,
            })

    schema_dependency_edges = [
        {
            "source_module": source_module,
            "target_module": target_module,
            "foreign_keys": count,
            "declared": target_module in declared.get(source_module, set()),
            "examples": edge_examples[(source_module, target_module)],
        }
        for (source_module, target_module), count in sorted(edge_counts.items())
    ]
    schema_dependency_violations = [x for x in schema_dependency_edges if not x["declared"]]

    counts: dict[str, int] = {}
    modules: dict[str, int] = {}
    for row in inventory:
        counts[row["classification"]] = counts.get(row["classification"], 0) + 1
        modules[row["module"]] = modules.get(row["module"], 0) + 1

    out = {
        "format": "trustweave-d12-classification-v1",
        "primary_sha256": hashlib.sha256(args.primary.read_bytes()).hexdigest(),
        "supplement_sha256": hashlib.sha256(args.supplement.read_bytes()).hexdigest() if args.supplement else None,
        "server_version": primary.get("server_version"),
        "migration_files": len(files),
        "migration_versions_note": "121 accepted files through 123; 096/097 reserved",
        "counts": counts,
        "module_counts": modules,
        "schema_dependency_edges": schema_dependency_edges,
        "schema_dependency_violations": schema_dependency_violations,
        "limits": [
            "MATCH with evidence_level=name-only is a candidate, not definition/security equivalence.",
            "Final MATCH promotion requires candidate fresh-project replay and catalog parity.",
            "Historical migration provenance is lexical and may include obsolete references.",
        ],
        "inventory": inventory,
    }
    payload = json.dumps(out, indent=2, sort_keys=False) + "\n"
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(payload, encoding="utf-8")
    else:
        print(payload, end="")


if __name__ == "__main__":
    main()
