#!/usr/bin/env python3
"""Upload an Android App Bundle (.aab) to Google Play.

Prereqs:
  uv pip install google-api-python-client google-auth httplib2

Setup (do this once):
  1. Go to Google Play Console → Setup → API access
  2. Create or link a Google Cloud project
  3. Create a Service Account (Cloud Console)
  4. Grant the service account "Release manager" or "Admin" in the Play Console
     (Users and permissions → Invite new users → service account email)
  5. Download a JSON key for the service account
  6. Save it as service-account.json next to this script (or pass --key)

Usage:
  ./scripts/upload_to_play.py --track internal app/build/outputs/bundle/release/app-release.aab
  ./scripts/upload_to_play.py --track production --release-notes "Bug fixes" path/to.aab

Tracks:
  internal   - up to 100 testers, fastest review
  alpha      - closed testing
  beta       - open testing
  production - public Play Store listing
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

try:
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaFileUpload
except ImportError as e:
    sys.stderr.write("❌ Missing deps. Run: uv pip install google-api-python-client google-auth\n")
    sys.exit(1)

PACKAGE_NAME = "biz.am2.swiftbible"
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("aab", help="Path to the .aab file to upload")
    parser.add_argument("--track", default="internal", choices=["internal", "alpha", "beta", "production"])
    parser.add_argument("--release-notes", default=None, help="What's new text (en-US)")
    parser.add_argument("--release-name", default=None, help="Optional release name (defaults to versionName)")
    parser.add_argument(
        "--key",
        default=os.environ.get("GOOGLE_PLAY_SERVICE_ACCOUNT", "service-account.json"),
        help="Path to service account JSON key (env: GOOGLE_PLAY_SERVICE_ACCOUNT)",
    )
    parser.add_argument(
        "--rollout",
        type=float,
        default=1.0,
        help="Staged rollout fraction 0.0..1.0 (production only). Default: 1.0 (full release).",
    )
    parser.add_argument("--package", default=PACKAGE_NAME)
    args = parser.parse_args()

    aab_path = Path(args.aab)
    if not aab_path.exists():
        sys.stderr.write(f"❌ AAB not found: {aab_path}\n")
        return 1

    key_path = Path(args.key)
    if not key_path.exists():
        sys.stderr.write(f"❌ Service account key not found: {key_path}\n")
        sys.stderr.write("   See header of this file for setup instructions.\n")
        return 1

    creds = service_account.Credentials.from_service_account_file(str(key_path), scopes=SCOPES)
    service = build("androidpublisher", "v3", credentials=creds, cache_discovery=False)
    edits = service.edits()

    # 1. Create a new edit
    edit = edits.insert(packageName=args.package, body={}).execute()
    edit_id = edit["id"]
    print(f"📝 Created edit {edit_id}")

    # 2. Upload bundle
    print(f"⬆  Uploading {aab_path.name} ({aab_path.stat().st_size / 1_048_576:.1f} MiB)…")
    media = MediaFileUpload(str(aab_path), mimetype="application/octet-stream", resumable=True)
    bundle = edits.bundles().upload(packageName=args.package, editId=edit_id, media_body=media).execute()
    version_code = bundle["versionCode"]
    print(f"   Uploaded version code: {version_code}")

    # 3. Assign to track
    release: dict = {
        "name": args.release_name or f"v{version_code}",
        "versionCodes": [str(version_code)],
        "status": "completed",
    }
    if args.track == "production" and 0.0 < args.rollout < 1.0:
        release["status"] = "inProgress"
        release["userFraction"] = args.rollout
    if args.release_notes:
        release["releaseNotes"] = [{"language": "en-US", "text": args.release_notes}]

    edits.tracks().update(
        packageName=args.package,
        editId=edit_id,
        track=args.track,
        body={"track": args.track, "releases": [release]},
    ).execute()
    print(f"🎯 Assigned version {version_code} to track: {args.track}")

    # 4. Commit
    commit = edits.commit(packageName=args.package, editId=edit_id).execute()
    print(f"✅ Committed edit {edit_id}: {json.dumps(commit, indent=2)}")
    print(f"\nView at https://play.google.com/console/u/0/developers/-/app-list")
    return 0


if __name__ == "__main__":
    sys.exit(main())
