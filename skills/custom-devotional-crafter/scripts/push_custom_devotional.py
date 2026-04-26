#!/usr/bin/env python3
"""Upsert a custom devotional payload into Supabase production."""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="Push custom devotional payload to Supabase")
    parser.add_argument("--file", required=True, help="Path to JSON payload file")
    parser.add_argument("--dry-run", action="store_true", help="Print request details without sending")
    args = parser.parse_args()

    payload = json.loads(Path(args.file).read_text(encoding="utf-8"))
    required = ["for_date", "message", "devotional_type", "verses", "testament"]
    missing = [k for k in required if k not in payload]
    if missing:
        raise SystemExit(f"Missing required payload keys: {', '.join(missing)}")

    if payload["devotional_type"] != "custom":
        raise SystemExit("devotional_type must be 'custom' for this script")

    if args.dry_run:
        supabase_url = os.getenv("SUPABASE_URL", "https://<project-ref>.supabase.co")
        endpoint = f"{supabase_url.rstrip('/')}/rest/v1/Daily%20Devotional?on_conflict=for_date"
        print("Dry run only. Would upsert to:", endpoint)
        print(json.dumps(payload, indent=2))
        return

    supabase_url = os.getenv("SUPABASE_URL")
    service_role = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_SERVICE_KEY")
    if not supabase_url or not service_role:
        raise SystemExit("Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY (or SUPABASE_SERVICE_KEY)")

    endpoint = f"{supabase_url.rstrip('/')}/rest/v1/Daily%20Devotional?on_conflict=for_date"
    body = json.dumps(payload).encode("utf-8")

    req = urllib.request.Request(
        endpoint,
        data=body,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "apikey": service_role,
            "Authorization": f"Bearer {service_role}",
            "Prefer": "resolution=merge-duplicates,return=representation",
        },
    )

    try:
        with urllib.request.urlopen(req) as response:
            output = response.read().decode("utf-8")
            print("Success:", response.status)
            print(output)
    except urllib.error.HTTPError as err:
        detail = err.read().decode("utf-8", errors="replace")
        print(f"HTTP {err.code}: {detail}", file=sys.stderr)
        raise SystemExit(1) from err


if __name__ == "__main__":
    main()
