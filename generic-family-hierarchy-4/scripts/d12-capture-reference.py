#!/usr/bin/env python3
"""Read-only D12 PostgreSQL reference capture using native psql/pg_dump."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent
SENSITIVE = [
    re.compile(rb"(?i)(?:postgres(?:ql)?|supabase)://[^\s\"']+:[^\s\"'@]+@"),
    re.compile(rb"(?i)(?:service_role|anon|secret|api[_-]?key|password|token)\s*[=:]\s*['\"]?[^\s,'\"]{12,}"),
    re.compile(rb"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    re.compile(rb"\b(?:eyJ[A-Za-z0-9_-]{35,}\.[A-Za-z0-9_-]{20,})\b"),
]


def run(executable, args, env, output=None):
    if output:
        with output.open("wb") as stream:
            result = subprocess.run([executable, *args], env=env, stdout=stream,
                                    stderr=subprocess.PIPE, check=False)
    else:
        result = subprocess.run([executable, *args], env=env, stdout=subprocess.DEVNULL,
                                stderr=subprocess.PIPE, check=False)
    if result.returncode:
        # Tool stderr can echo connection strings, so never print it verbatim.
        raise RuntimeError(f"{executable} failed (exit {result.returncode}); check local connection and PostgreSQL client version")


def validate(directory):
    expected = ["schema.sql", "metadata.json", "storage-buckets.json", "migration-history.json"]
    for name in expected:
        if not (directory / name).is_file():
            raise ValueError(f"missing {name}")
    inventory = json.loads((directory / "metadata.json").read_text())
    if not isinstance(inventory, dict) or not inventory.get("relations") or not inventory.get("functions"):
        raise ValueError("metadata is empty or incomplete; check project and database permissions")
    for name in ("storage-buckets.json", "migration-history.json"):
        data = json.loads((directory / name).read_text())
        if not isinstance(data, list):
            raise ValueError(f"{name} must be an array")
    for path in directory.iterdir():
        if not path.is_file():
            raise ValueError("unexpected directory inside capture")
        data = path.read_bytes()
        if path.suffix in (".sql", ".json"):
            if re.search(rb"(?im)^\s*(?:COPY\s+\S+\s+.*FROM stdin|INSERT\s+INTO\s+)", data):
                raise ValueError(f"data statement in {path.name}")
            if any(pattern.search(data) for pattern in SENSITIVE):
                raise ValueError(f"possible secret in {path.name}; inspect locally, redact, and rerun validation")
    hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in directory.iterdir() if p.is_file() and p.name != "manifest.json"}
    if (directory / "manifest.json").exists():
        manifest = json.loads((directory / "manifest.json").read_text())
        if manifest.get("sha256") != hashes:
            raise ValueError("capture checksum mismatch")
    return hashes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", default=".d12-reference", help="local untracked output directory")
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()
    directory = Path(args.output).resolve()
    if args.validate_only:
        print(json.dumps({"status": "passed", "files": validate(directory)}, indent=2))
        return
    if directory.exists() and any(directory.iterdir()):
        raise ValueError("output directory must be new or empty; refusing overwrite")
    env = os.environ.copy()
    if env.get("TW_D12_DATABASE_URL"):
        env["PGDATABASE"] = env.pop("TW_D12_DATABASE_URL")
    if not env.get("PGDATABASE"):
        raise ValueError("set PGDATABASE (or TW_D12_DATABASE_URL) locally; do not send credentials in chat")
    psql, pg_dump = shutil.which("psql"), shutil.which("pg_dump")
    if not psql or not pg_dump:
        raise RuntimeError("native PostgreSQL psql and pg_dump are required; Docker is not required")
    directory.mkdir(parents=True, exist_ok=True)
    try:
        base = ["-X", "-w", "-q", "-v", "ON_ERROR_STOP=1", "-t", "-A"]
        run(psql, [*base, "-f", str(ROOT / "d12-capture-reference.sql")], env, directory / "metadata.json")
        run(pg_dump, ["--no-password", "--schema-only", "--no-owner", "--schema=public", "--file=" + str(directory / "schema.sql")], env)
        metadata = json.loads((directory / "metadata.json").read_text().strip())
        for present, filename, query in [
            ("storage_relation_present", "storage-buckets.json", "SELECT coalesce(json_agg(json_build_object('id',id,'name',name,'public',public,'file_size_limit',file_size_limit,'allowed_mime_types',allowed_mime_types) ORDER BY id),'[]'::json)::text FROM storage.buckets"),
            ("migration_relation_present", "migration-history.json", "SELECT coalesce(json_agg(json_build_object('version',version,'name',name) ORDER BY version),'[]'::json)::text FROM supabase_migrations.schema_migrations"),
        ]:
            if metadata[present]:
                run(psql, [*base, "-c", query], env, directory / filename)
            else:
                (directory / filename).write_text("[]\n")
        hashes = validate(directory)
        (directory / "manifest.json").write_text(json.dumps({"version": 1, "sha256": hashes}, indent=2) + "\n")
    except Exception:
        # A partial or sensitive dump must never look like a completed package.
        for file in directory.iterdir():
            if file.is_file():
                file.unlink()
        raise
    print(f"D12 capture validated: {directory} ({len(hashes)} files); share only after local review")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, ValueError, OSError, json.JSONDecodeError) as exc:
        print(f"D12 capture failed: {exc}", file=sys.stderr)
        sys.exit(1)
