#!/usr/bin/env python3
"""Push localized App Store screenshots via the App Store Connect API.

Reads PNG files from a source directory containing device-named subfolders:
    <source>/iphone-6.9/*.png   → uploaded as APP_IPHONE_69
    <source>/ipad-13/*.png      → uploaded as APP_IPAD_PRO_3GEN_129
    <source>/iphone-6.5/*.png   → uploaded as APP_IPHONE_65    (optional)

Files are sorted by filename, so name them 01_*.png, 02_*.png, ... for ordering.

Usage:
    uv run python push_screenshots.py --pull
    uv run python push_screenshots.py --source appstore/marketing/ultimate --dry-run
    uv run python push_screenshots.py --source appstore/marketing/ultimate
    uv run python push_screenshots.py --source appstore/marketing/ultimate --force
    uv run python push_screenshots.py --source appstore/marketing/es-ES --locale es-ES

Flags:
    --pull              List current screenshots in ASC for the target locale
    --dry-run           Show what would be uploaded without uploading
    --source <dir>      Directory containing device subfolders (default: appstore/marketing/ultimate)
    --locale <code>     Locale to upload to (default: en-US)
    --force             Delete existing screenshots in the set before uploading
    --devices <list>    Comma-separated device dirs to upload (default: all matching folders)
"""

import argparse
import hashlib
import os
import sys
import time
from pathlib import Path

import jwt
import requests
from dotenv import load_dotenv

ASC_BASE = "https://api.appstoreconnect.apple.com/v1"
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent

# Map our directory naming convention to Apple's screenshotDisplayType.
# Note: Apple's iPhone 16 Pro Max (6.9", 1320x2868) uses APP_IPHONE_67 — they
# kept the legacy "6.7" bracket name when bumping the required resolution.
# Add new entries when you support new device sizes.
DEVICE_TYPE_MAP = {
    "iphone-6.9": "APP_IPHONE_67",
    "iphone-6.7": "APP_IPHONE_67",
    "iphone-6.5": "APP_IPHONE_65",
    "iphone-6.1": "APP_IPHONE_61",
    "iphone-5.8": "APP_IPHONE_58",
    "ipad-13":    "APP_IPAD_PRO_3GEN_129",
    "ipad-12.9":  "APP_IPAD_PRO_3GEN_129",
    "ipad-11":    "APP_IPAD_PRO_11",
    "watch-49mm": "APP_WATCH_ULTRA",
    "watch-46mm": "APP_WATCH_SERIES_10",
}

# Same priority list as push_listing.py
VERSION_STATE_PRIORITY = [
    "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
    "METADATA_REJECTED", "WAITING_FOR_REVIEW", "READY_FOR_REVIEW",
]


def load_env():
    load_dotenv(SCRIPT_DIR / ".env")
    required = ["ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_APP_ID", "ASC_KEY_FILE"]
    missing = [k for k in required if not os.environ.get(k)]
    if missing:
        sys.exit(f"ERROR: missing env vars: {', '.join(missing)}. See .env.example.")
    key_file = Path(os.environ["ASC_KEY_FILE"])
    if not key_file.is_absolute():
        key_file = REPO_ROOT / key_file
    if not key_file.exists():
        sys.exit(f"ERROR: key file not found: {key_file}")
    return {
        "key_id": os.environ["ASC_KEY_ID"],
        "issuer_id": os.environ["ASC_ISSUER_ID"],
        "app_id": os.environ["ASC_APP_ID"],
        "key_file": key_file,
    }


def make_token(env):
    private_key = env["key_file"].read_text()
    payload = {
        "iss": env["issuer_id"], "iat": int(time.time()),
        "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1",
    }
    return jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": env["key_id"]})


def api(method, path, token, **kwargs):
    url = path if path.startswith("http") else f"{ASC_BASE}{path}"
    headers = kwargs.pop("headers", {})
    headers["Authorization"] = f"Bearer {token}"
    if "json" in kwargs:
        headers["Content-Type"] = "application/json"
    r = requests.request(method, url, headers=headers, timeout=120, **kwargs)
    if not r.ok:
        sys.stderr.write(f"\nAPI ERROR {r.status_code} on {method} {path}:\n{r.text}\n")
        r.raise_for_status()
    if r.status_code == 204 or not r.text:
        return None
    return r.json()


def get_editable_version(token, app_id):
    r = api("GET", f"/apps/{app_id}/appStoreVersions?limit=20", token)
    for state in VERSION_STATE_PRIORITY:
        for v in r["data"]:
            if v["attributes"]["appStoreState"] == state:
                return v["id"], v["attributes"]["versionString"], v["attributes"]["appStoreState"]
    sys.exit("ERROR: no editable AppStoreVersion found.")


def list_version_localizations(token, version_id):
    r = api("GET", f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200", token)
    return {item["attributes"]["locale"]: item["id"] for item in r["data"]}


def list_screenshot_sets(token, loc_id):
    r = api("GET", f"/appStoreVersionLocalizations/{loc_id}/appScreenshotSets?limit=20", token)
    return {item["attributes"]["screenshotDisplayType"]: item for item in r["data"]}


def list_screenshots(token, set_id):
    r = api("GET", f"/appScreenshotSets/{set_id}/appScreenshots?limit=20", token)
    return r["data"]


def md5(path):
    h = hashlib.md5()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def find_local(source_dir, devices_filter=None):
    """Return {device_dir_name: [Path, ...]} for device subdirs containing PNGs."""
    result = {}
    if not source_dir.is_dir():
        sys.exit(f"ERROR: source directory does not exist: {source_dir}")
    for device_dir in sorted(source_dir.iterdir()):
        if not device_dir.is_dir():
            continue
        if devices_filter and device_dir.name not in devices_filter:
            continue
        if device_dir.name not in DEVICE_TYPE_MAP:
            continue
        files = sorted(
            f for f in device_dir.iterdir()
            if f.suffix.lower() == ".png" and not f.name.startswith(".")
        )
        if files:
            result[device_dir.name] = files
    return result


def create_screenshot_set(token, loc_id, display_type):
    body = {
        "data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": display_type},
            "relationships": {
                "appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations", "id": loc_id}
                }
            },
        }
    }
    r = api("POST", "/appScreenshotSets", token, json=body)
    return r["data"]["id"]


def delete_screenshot(token, screenshot_id):
    api("DELETE", f"/appScreenshots/{screenshot_id}", token)


def upload_one(token, set_id, file_path):
    """Three-step screenshot upload: reserve → PUT chunks → commit."""
    file_size = file_path.stat().st_size

    # 1. Reserve
    body = {
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": file_path.name, "fileSize": file_size},
            "relationships": {
                "appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}
            },
        }
    }
    r = api("POST", "/appScreenshots", token, json=body)
    screenshot_id = r["data"]["id"]
    upload_ops = r["data"]["attributes"]["uploadOperations"]

    # 2. Upload chunks (Apple's signed URLs — DO NOT include our bearer token here)
    file_bytes = file_path.read_bytes()
    for op in upload_ops:
        chunk = file_bytes[op["offset"]:op["offset"] + op["length"]]
        chunk_headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        resp = requests.request(
            op["method"], op["url"], headers=chunk_headers, data=chunk, timeout=120,
        )
        if not resp.ok:
            sys.stderr.write(f"Upload chunk failed: {resp.status_code} {resp.text}\n")
            resp.raise_for_status()

    # 3. Commit
    commit_body = {
        "data": {
            "type": "appScreenshots",
            "id": screenshot_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": md5(file_path)},
        }
    }
    api("PATCH", f"/appScreenshots/{screenshot_id}", token, json=commit_body)
    return screenshot_id


def reorder_set(token, set_id, screenshot_ids):
    body = {"data": [{"type": "appScreenshots", "id": sid} for sid in screenshot_ids]}
    api("PATCH", f"/appScreenshotSets/{set_id}/relationships/appScreenshots", token, json=body)


def cmd_pull(token, version_locs, locale):
    if locale not in version_locs:
        sys.exit(f"ERROR: locale '{locale}' not found in version localizations.")
    loc_id = version_locs[locale]
    sets = list_screenshot_sets(token, loc_id)
    if not sets:
        print(f"  {locale}: no screenshot sets")
        return
    for display_type, sset in sets.items():
        screenshots = list_screenshots(token, sset["id"])
        print(f"  {locale} {display_type}: {len(screenshots)} screenshots")
        for s in screenshots:
            attrs = s["attributes"]
            uploaded = "✓" if attrs.get("assetDeliveryState", {}).get("state") == "COMPLETE" else "?"
            print(f"      {uploaded} {attrs.get('fileName', '<no name>')}")


def cmd_push(token, version_locs, locale, source, devices_filter, force, dry_run):
    if locale not in version_locs:
        sys.exit(
            f"ERROR: locale '{locale}' not found in version localizations.\n"
            f"Run: uv run python push_listing.py --locales {locale}  first."
        )
    loc_id = version_locs[locale]
    by_device = find_local(source, devices_filter)
    if not by_device:
        sys.exit(f"ERROR: no PNG files found in {source}/<device>/ matching known device names.")

    print(f"\nLocale: {locale} (loc_id {loc_id})")
    print(f"Source: {source}")
    existing_sets = list_screenshot_sets(token, loc_id)

    for device_dir, files in by_device.items():
        display_type = DEVICE_TYPE_MAP[device_dir]
        existing_set = existing_sets.get(display_type)
        print(f"\n  [{device_dir} → {display_type}] {len(files)} local file(s)")

        if existing_set:
            set_id = existing_set["id"]
            existing_screenshots = list_screenshots(token, set_id)
            if existing_screenshots and not force:
                print(f"    skip: {len(existing_screenshots)} screenshot(s) already exist (use --force to replace)")
                continue
            if existing_screenshots and force:
                print(f"    deleting {len(existing_screenshots)} existing screenshot(s)...")
                if not dry_run:
                    for s in existing_screenshots:
                        delete_screenshot(token, s["id"])
        else:
            print(f"    creating screenshot set...")
            if not dry_run:
                set_id = create_screenshot_set(token, loc_id, display_type)
            else:
                set_id = "<dry-run-set-id>"

        uploaded_ids = []
        for f in files:
            size_kb = f.stat().st_size // 1024
            print(f"    uploading {f.name} ({size_kb}KB)...")
            if not dry_run:
                sid = upload_one(token, set_id, f)
                uploaded_ids.append(sid)

        if uploaded_ids and not dry_run:
            print(f"    setting display order...")
            reorder_set(token, set_id, uploaded_ids)


def main():
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--pull", action="store_true",
                   help="List current screenshots in ASC for the target locale")
    p.add_argument("--dry-run", action="store_true",
                   help="Show what would be uploaded without uploading")
    p.add_argument("--source", default=str(SCRIPT_DIR / "marketing" / "ultimate"),
                   help="Directory containing device subfolders (default: appstore/marketing/ultimate)")
    p.add_argument("--locale", default="en-US",
                   help="Locale to upload screenshots for (default: en-US)")
    p.add_argument("--force", action="store_true",
                   help="Delete existing screenshots before uploading")
    p.add_argument("--devices",
                   help="Comma-separated device folder names (default: all matching DEVICE_TYPE_MAP)")
    args = p.parse_args()

    env = load_env()
    print(f"Authenticating to App Store Connect (key {env['key_id']})...")
    token = make_token(env)

    version_id, vstr, vstate = get_editable_version(token, env["app_id"])
    print(f"App: {env['app_id']}, version {vstr} ({vstate})")
    version_locs = list_version_localizations(token, version_id)

    if args.pull:
        cmd_pull(token, version_locs, args.locale)
        return

    devices_filter = set(args.devices.split(",")) if args.devices else None
    cmd_push(
        token, version_locs, args.locale,
        Path(args.source).resolve(),
        devices_filter, args.force, args.dry_run,
    )
    print(f"\nDone." + (" (dry-run)" if args.dry_run else ""))


if __name__ == "__main__":
    main()
