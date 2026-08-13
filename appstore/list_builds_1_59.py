#!/usr/bin/env python3
"""List every build Apple has under a given marketing version, with its build
number, processing state, and upload time.

Guards the known hazard: an automated uploader (server-side Xcode Cloud) can push
its own high-numbered build for the same marketing version and race the manual
`make release` build, so "attach the newest VALID build" can grab the wrong one.
Run this before `make submit-version` and confirm the expected build number.

Usage: uv run python appstore/list_builds_1_59.py 1.59
"""
import os
import sys
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

app_id = os.environ["ASC_APP_ID"]
vstr = sys.argv[1] if len(sys.argv) > 1 else "1.59"

r = requests.get(
    f"{ASC_BASE}/builds",
    headers={"Authorization": f"Bearer {token}"},
    params={
        "filter[app]": app_id,
        "filter[preReleaseVersion.version]": vstr,
        "include": "preReleaseVersion",
        "limit": 50,
    },
    timeout=30,
)
r.raise_for_status()
data = r.json().get("data", [])

if not data:
    print(f"no builds yet for {vstr}")
    sys.exit(2)

print(f"builds under marketing version {vstr}:")
for b in data:
    a = b["attributes"]
    print(
        f"  build {a.get('version'):>5}  {a.get('processingState'):<10} "
        f"uploaded={a.get('uploadedDate')}  id={b['id']}"
    )

valid = [b for b in data if b["attributes"].get("processingState") == "VALID"]
print(f"\nVALID count: {len(valid)}")
if len(valid) > 1:
    print("WARNING: more than one VALID build — submit_version picks the newest.")
sys.exit(0 if valid else 3)
