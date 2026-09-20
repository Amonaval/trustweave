#!/usr/bin/env python3
"""Compare D12 golden and disposable-candidate catalog captures.

This is the structural/security/API-contract parity gate. It intentionally ignores
application data and Storage object rows. The only expected API difference is that
the candidate restores the two reviewed notification-role mutators missing live in
the golden project.
"""
from __future__ import annotations

import argparse
import csv
import json
import re
from pathlib import Path
from typing import Any


RESTORED_FUNCTION_NAMES = {
    "set_network_notification_role",
    "remove_network_notification_role",
}
MAX_SAMPLES = 50


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


def clean_name(value: str) -> str:
    return value.replace('"', "").lower()


def function_key(row: dict[str, Any]) -> str:
    return f"{clean_name(row['name'])}({str(row.get('identity_arguments') or '').strip().lower()})"


def function_leaf(key: str) -> str:
    return key.split("(", 1)[0].split(".")[-1]


def stable(value: Any) -> Any:
    if isinstance(value, dict):
        return {k: stable(v) for k, v in sorted(value.items())}
    if isinstance(value, list):
        return [stable(x) for x in value]
    return value


def normalize_constraint_definition(value: str | None) -> str | None:
    """Normalize PostgreSQL-equivalent CHECK rendering after dump/recreate.

    PG can render ARRAY varchar literals as either:
      ARRAY['x'::varchar, ...]::text[]
    or:
      ARRAY['x'::varchar::text, ...]
    after recreating the exact captured CHECK. These forms are semantically
    equivalent and were proven across all 173 affected golden constraints on
    the D12 disposable candidate. Other constraint text remains strict.
    """
    if value is None:
        return None
    text = re.sub(r"::character varying::text", "::character varying", value)
    text = re.sub(r"\]::text\[\]", "]", text)
    return re.sub(r"\s+", " ", text).strip()


def normalized_constraint_rows(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [
        {**row, "definition": normalize_constraint_definition(row.get("definition"))}
        for row in rows
    ]


def parse_acl(acl: str | None) -> list[tuple[str, str, tuple[str, ...]]]:
    if not acl or acl == "{}":
        return []
    raw = acl.strip("{}")
    result: list[tuple[str, str, tuple[str, ...]]] = []
    # Captured TrustWeave roles do not contain commas; keep this parser deliberately small.
    for entry in raw.split(","):
        left = entry.split("/", 1)[0]
        if "=" not in left:
            continue
        principal, encoded = left.split("=", 1)
        principal = principal.strip('"') or "PUBLIC"
        privileges: list[str] = []
        grantable: list[str] = []
        i = 0
        while i < len(encoded):
            char = encoded[i]
            if char == "*":
                i += 1
                continue
            privileges.append(char)
            if i + 1 < len(encoded) and encoded[i + 1] == "*":
                grantable.append(char)
                i += 1
            i += 1
        result.append((principal, "".join(privileges), tuple(sorted(grantable))))
    return sorted(result)


def map_rows(rows: list[dict[str, Any]], key_fields: tuple[str, ...], fields: tuple[str, ...]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for row in rows:
        key = "|".join(str(row.get(x) or "") for x in key_fields)
        result[key] = stable({field: row.get(field) for field in fields})
    return result


def add_map_diff(
    bucket: list[dict[str, Any]],
    name: str,
    golden: dict[str, Any],
    candidate: dict[str, Any],
    *,
    allow_candidate_extra: set[str] | None = None,
    allow_extra_predicate=None,
) -> None:
    allow_candidate_extra = allow_candidate_extra or set()
    missing = sorted(set(golden) - set(candidate))
    extra = []
    for key in sorted(set(candidate) - set(golden)):
        allowed = key in allow_candidate_extra
        if allow_extra_predicate is not None:
            allowed = allowed or bool(allow_extra_predicate(key))
        if not allowed:
            extra.append(key)
    changed = sorted(key for key in set(golden) & set(candidate) if golden[key] != candidate[key])
    if missing or extra or changed:
        bucket.append({
            "object_type": name,
            "missing_count": len(missing),
            "extra_count": len(extra),
            "changed_count": len(changed),
            "missing_samples": missing[:MAX_SAMPLES],
            "extra_samples": extra[:MAX_SAMPLES],
            "changed_samples": [
                {"key": key, "golden": golden[key], "candidate": candidate[key]}
                for key in changed[:MAX_SAMPLES]
            ],
        })


def acl_map(rows: list[dict[str, Any]], key_fields: tuple[str, ...]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for row in rows:
        key = "|".join(str(row.get(x) or "") for x in key_fields)
        result[key] = parse_acl(row.get("acl"))
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("golden_primary", type=Path)
    parser.add_argument("--golden-supplement", required=True, type=Path)
    parser.add_argument("--candidate-primary", required=True, type=Path)
    parser.add_argument("--candidate-supplement", required=True, type=Path)
    parser.add_argument(
        "--out",
        type=Path,
        default=Path(".d12-work") / "candidate" / "catalog-parity.json",
    )
    args = parser.parse_args()

    gp = load_capture(args.golden_primary)
    gs = load_capture(args.golden_supplement)
    cp = load_capture(args.candidate_primary)
    cs = load_capture(args.candidate_supplement)

    structural: list[dict[str, Any]] = []
    security: list[dict[str, Any]] = []
    api: list[dict[str, Any]] = []
    warnings: list[dict[str, Any]] = []

    if sorted(gp.get("schemas") or []) != sorted(cp.get("schemas") or []):
        structural.append({
            "object_type": "schemas",
            "golden": sorted(gp.get("schemas") or []),
            "candidate": sorted(cp.get("schemas") or []),
        })

    add_map_diff(
        structural,
        "relations",
        map_rows(gp.get("relations") or [], ("name",), ("kind", "rls", "force_rls")),
        map_rows(cp.get("relations") or [], ("name",), ("kind", "rls", "force_rls")),
    )
    add_map_diff(
        structural,
        "columns",
        map_rows(
            gp.get("columns") or [],
            ("relation", "name"),
            ("type", "not_null", "identity", "generated", "default"),
        ),
        map_rows(
            cp.get("columns") or [],
            ("relation", "name"),
            ("type", "not_null", "identity", "generated", "default"),
        ),
    )
    add_map_diff(
        structural,
        "constraints",
        map_rows(normalized_constraint_rows(gp.get("constraints") or []), ("relation", "name"), ("kind", "definition")),
        map_rows(normalized_constraint_rows(cp.get("constraints") or []), ("relation", "name"), ("kind", "definition")),
    )
    add_map_diff(
        structural,
        "indexes",
        map_rows(gp.get("indexes") or [], ("relation", "name"), ("definition",)),
        map_rows(cp.get("indexes") or [], ("relation", "name"), ("definition",)),
    )
    add_map_diff(
        structural,
        "views",
        map_rows(gp.get("views") or [], ("name",), ("definition",)),
        map_rows(cp.get("views") or [], ("name",), ("definition",)),
    )
    add_map_diff(
        structural,
        "triggers",
        map_rows(gp.get("triggers") or [], ("relation", "name"), ("definition", "enabled")),
        map_rows(cp.get("triggers") or [], ("relation", "name"), ("definition", "enabled")),
    )

    golden_functions = {
        function_key(row): stable({
            "result": row.get("result"),
            "security_definer": row.get("security_definer"),
            "config": row.get("config"),
            "definition": row.get("definition"),
        })
        for row in gp.get("functions") or []
    }
    candidate_functions = {
        function_key(row): stable({
            "result": row.get("result"),
            "security_definer": row.get("security_definer"),
            "config": row.get("config"),
            "definition": row.get("definition"),
        })
        for row in cp.get("functions") or []
    }
    add_map_diff(
        api,
        "functions",
        golden_functions,
        candidate_functions,
        allow_extra_predicate=lambda key: function_leaf(key) in RESTORED_FUNCTION_NAMES,
    )

    candidate_restored = {
        function_leaf(key) for key in candidate_functions if function_leaf(key) in RESTORED_FUNCTION_NAMES
    }
    if candidate_restored != RESTORED_FUNCTION_NAMES:
        api.append({
            "object_type": "restored_notification_mutators",
            "expected": sorted(RESTORED_FUNCTION_NAMES),
            "candidate": sorted(candidate_restored),
        })

    add_map_diff(
        security,
        "policies",
        map_rows(
            gp.get("policies") or [],
            ("schema", "table", "name"),
            ("permissive", "roles", "command", "using", "check"),
        ),
        map_rows(
            cp.get("policies") or [],
            ("schema", "table", "name"),
            ("permissive", "roles", "command", "using", "check"),
        ),
    )

    # Strict application-table grants. Storage grants are managed by Supabase and reported separately.
    golden_grants = [
        row for row in gp.get("grants") or [] if str(row.get("schema") or "") != "storage"
    ]
    candidate_grants = [
        row for row in cp.get("grants") or [] if str(row.get("schema") or "") != "storage"
    ]
    add_map_diff(
        security,
        "table_grants",
        map_rows(golden_grants, ("schema", "table", "grantee", "privilege"), ("grantable",)),
        map_rows(candidate_grants, ("schema", "table", "grantee", "privilege"), ("grantable",)),
    )

    golden_storage_grants = [
        row for row in gp.get("grants") or [] if str(row.get("schema") or "") == "storage"
    ]
    candidate_storage_grants = [
        row for row in cp.get("grants") or [] if str(row.get("schema") or "") == "storage"
    ]
    storage_diff: list[dict[str, Any]] = []
    add_map_diff(
        storage_diff,
        "storage_table_grants_managed",
        map_rows(golden_storage_grants, ("schema", "table", "grantee", "privilege"), ("grantable",)),
        map_rows(candidate_storage_grants, ("schema", "table", "grantee", "privilege"), ("grantable",)),
    )
    warnings.extend(storage_diff)

    # Effective routine grants may contain rows for the two intentionally restored RPCs.
    golden_routine = map_rows(
        gp.get("routine_grants") or [],
        ("schema", "name", "grantee", "privilege"),
        (),
    )
    candidate_routine = map_rows(
        cp.get("routine_grants") or [],
        ("schema", "name", "grantee", "privilege"),
        (),
    )
    add_map_diff(
        security,
        "routine_grants",
        golden_routine,
        candidate_routine,
        allow_extra_predicate=lambda key: any(f"|{name}|" in f"|{key}|" for name in RESTORED_FUNCTION_NAMES),
    )

    add_map_diff(
        security,
        "usage_grants",
        map_rows(
            gp.get("usage_grants") or [],
            ("schema", "object", "type", "grantee", "privilege"),
            (),
        ),
        map_rows(
            cp.get("usage_grants") or [],
            ("schema", "object", "type", "grantee", "privilege"),
            (),
        ),
    )

    add_map_diff(
        structural,
        "enums",
        map_rows(gs.get("enums") or [], ("schema", "type", "label"), ("order",)),
        map_rows(cs.get("enums") or [], ("schema", "type", "label"), ("order",)),
    )
    add_map_diff(
        structural,
        "domains",
        map_rows(
            gs.get("domains") or [],
            ("schema", "name"),
            ("base_type", "not_null", "default"),
        ),
        map_rows(
            cs.get("domains") or [],
            ("schema", "name"),
            ("base_type", "not_null", "default"),
        ),
    )
    add_map_diff(
        structural,
        "sequences",
        map_rows(
            gs.get("sequences") or [],
            ("schema", "name"),
            ("data_type", "start", "increment", "min", "max", "cache", "cycle"),
        ),
        map_rows(
            cs.get("sequences") or [],
            ("schema", "name"),
            ("data_type", "start", "increment", "min", "max", "cache", "cycle"),
        ),
    )

    add_map_diff(
        security,
        "schema_acl",
        acl_map(gs.get("schema_grants") or [], ("schema",)),
        acl_map(cs.get("schema_grants") or [], ("schema",)),
    )
    add_map_diff(
        security,
        "relation_acl",
        acl_map(gs.get("relation_grants") or [], ("schema", "name")),
        acl_map(cs.get("relation_grants") or [], ("schema", "name")),
    )
    add_map_diff(
        security,
        "function_acl",
        acl_map(gs.get("function_grants") or [], ("schema", "name", "identity_arguments")),
        acl_map(cs.get("function_grants") or [], ("schema", "name", "identity_arguments")),
        allow_extra_predicate=lambda key: any(f"|{name}|" in f"|{key}|" for name in RESTORED_FUNCTION_NAMES),
    )

    add_map_diff(
        security,
        "storage_buckets",
        map_rows(
            gs.get("storage_buckets") or [],
            ("id",),
            ("name", "public", "file_size_limit", "allowed_mime_types"),
        ),
        map_rows(
            cs.get("storage_buckets") or [],
            ("id",),
            ("name", "public", "file_size_limit", "allowed_mime_types"),
        ),
    )
    add_map_diff(
        security,
        "storage_relation_security",
        map_rows(
            gs.get("storage_relation_security") or [],
            ("name",),
            ("rls", "force_rls"),
        ),
        map_rows(
            cs.get("storage_relation_security") or [],
            ("name",),
            ("rls", "force_rls"),
        ),
    )

    # Built-in Storage relation ACL is environment-managed: report mismatch as warning.
    storage_acl_diff: list[dict[str, Any]] = []
    add_map_diff(
        storage_acl_diff,
        "storage_relation_acl_managed",
        acl_map(gs.get("storage_relation_security") or [], ("name",)),
        acl_map(cs.get("storage_relation_security") or [], ("name",)),
    )
    warnings.extend(storage_acl_diff)

    golden_presence = gs.get("contract_rpc_presence") or {}
    candidate_presence = cs.get("contract_rpc_presence") or {}
    for name in sorted(RESTORED_FUNCTION_NAMES | {"reconcile_network_media_usage"}):
        if candidate_presence.get(name) is not True:
            api.append({
                "object_type": "contract_rpc_presence",
                "rpc": name,
                "candidate_present": candidate_presence.get(name),
                "golden_present": golden_presence.get(name),
            })

    # Environment/platform metadata is informative, not canonical application schema.
    if gp.get("server_version") != cp.get("server_version"):
        warnings.append({
            "object_type": "server_version",
            "golden": gp.get("server_version"),
            "candidate": cp.get("server_version"),
        })
    golden_ext = {
        (row.get("name"), row.get("schema")): row.get("version")
        for row in gp.get("extensions") or []
    }
    candidate_ext = {
        (row.get("name"), row.get("schema")): row.get("version")
        for row in cp.get("extensions") or []
    }
    if set(golden_ext) != set(candidate_ext):
        structural.append({
            "object_type": "extensions",
            "missing": sorted(str(x) for x in set(golden_ext) - set(candidate_ext)),
            "extra": sorted(str(x) for x in set(candidate_ext) - set(golden_ext)),
        })
    elif golden_ext != candidate_ext:
        warnings.append({
            "object_type": "extension_versions",
            "golden": {str(k): v for k, v in golden_ext.items()},
            "candidate": {str(k): v for k, v in candidate_ext.items()},
        })

    if bool(gp.get("storage_relation_present")) != bool(cp.get("storage_relation_present")):
        structural.append({
            "object_type": "storage_relation_present",
            "golden": gp.get("storage_relation_present"),
            "candidate": cp.get("storage_relation_present"),
        })

    errors = structural + security + api
    report = {
        "format": "trustweave-d12-catalog-parity-v1",
        "status": "PASS" if not errors else "FAIL",
        "layers": {
            "structural": {"status": "PASS" if not structural else "FAIL", "differences": structural},
            "security": {"status": "PASS" if not security else "FAIL", "differences": security},
            "api_contract": {"status": "PASS" if not api else "FAIL", "differences": api},
        },
        "warnings": warnings,
        "intentional_differences": {
            "candidate_restores_functions": sorted(RESTORED_FUNCTION_NAMES),
            "migration_catalog_visibility": "environment evidence only",
            "database_name": "ignored",
            "roles": "Supabase environment managed; not an application-schema parity gate",
            "storage_builtin_acl": "Supabase managed; mismatches are warnings, RLS/user policies remain strict",
            "extension_version": "warning when extension name/schema match",
        },
        "next_gate": "behavioral-and-browser-parity" if not errors else "resolve-catalog-parity",
    }

    out = args.out.resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    print(
        "D12 catalog parity:",
        report["status"],
        f"(structural={len(structural)}, security={len(security)}, api={len(api)}, warnings={len(warnings)})",
    )
    print(out)
    if errors:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
