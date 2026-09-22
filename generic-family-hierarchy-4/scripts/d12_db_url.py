"""Accept only project-bound Supabase Postgres connections for D12 disposable work.

A session pooler URL is required from IPv4-only GitHub hosted runners. The
project ref lives in its username, whereas direct URLs carry it in the host.
"""
from __future__ import annotations

import re
from urllib.parse import urlsplit

_REF = re.compile(r"[a-z0-9]{20}\Z")
_POOLER = re.compile(r"aws-[0-9]+-[a-z0-9-]+\.pooler\.supabase\.com\Z")


def project_ref_from_db_url(value: str) -> str | None:
    try:
        parsed = urlsplit(value)
        host = (parsed.hostname or "").lower()
        port = parsed.port
        username = parsed.username
    except ValueError:
        return None

    if (
        parsed.scheme not in ("postgresql", "postgres")
        or port != 5432
        or parsed.path != "/postgres"
        or parsed.query
        or parsed.fragment
        or not parsed.password
    ):
        return None

    if host.startswith("db.") and host.endswith(".supabase.co"):
        ref = host[len("db.") : -len(".supabase.co")]
        return ref if username == "postgres" and _REF.fullmatch(ref) else None

    if _POOLER.fullmatch(host):
        if username and username.startswith("postgres."):
            ref = username[len("postgres.") :]
            return ref if _REF.fullmatch(ref) else None
    return None
