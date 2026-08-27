#!/usr/bin/env python3
"""List the app's App Store versions with state and attached build.

Read-only. Run before cutting a release to confirm whether the previous
marketing version actually shipped, or is still sitting editable/in review.

Usage: uv run --with pyjwt --with requests --with python-dotenv --with cryptography \
         python appstore/list_versions.py
"""
import os
import time
from pathlib import Path

import jwt
import requests
from dotenv import load_dotenv

ASC_BASE = "https://api.appstoreconnect.apple.com/v1"
SCRIPT_DIR = Path(__file__).resolve().parent
load_dotenv(SCRIPT_DIR / ".env")

key_file = Path(os.environ["ASC_KEY_FILE"])
if not key_file.is_absolute():
    key_file = SCRIPT_DIR.parent / key_file

token = jwt.encode(
    {
        "iss": os.environ["ASC_ISSUER_ID"],
        "iat": int(time.time()),
        "exp": int(time.time()) + 1200,
        "aud": "appstoreconnect-v1",
    },
    key_file.read_text(),
    algorithm="ES256",
    headers={"kid": os.environ["ASC_KEY_ID"]},
)

r = requests.get(
    f"{ASC_BASE}/apps/{os.environ['ASC_APP_ID']}/appStoreVersions",
    headers={"Authorization": f"Bearer {token}"},
    params={"limit": 10, "include": "build"},
    timeout=30,
)
r.raise_for_status()
payload = r.json()
builds = {b["id"]: b["attributes"].get("version") for b in payload.get("included", [])}

print(f"{'version':<10} {'state':<28} {'released':<10} build")
for v in payload.get("data", []):
    a = v["attributes"]
    rel = a.get("releaseType") or ""
    bid = (v.get("relationships", {}).get("build", {}).get("data") or {}).get("id")
    print(f"{a['versionString']:<10} {a['appStoreState']:<28} {rel:<10} {builds.get(bid, '(none)')}")
