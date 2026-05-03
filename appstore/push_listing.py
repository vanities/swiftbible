#!/usr/bin/env python3
"""Push and pull localized App Store listings via the App Store Connect API.

Usage:
    uv run python push_listing.py --pull                    # download current state
    uv run python push_listing.py --dry-run                 # show what would change
    uv run python push_listing.py --locales es-ES,pt-BR     # push specific locales
    uv run python push_listing.py                           # push all locales

Reads:
    .env                   credentials (gitignored)
    listings.yaml          per-locale content (committed)

Writes (in --pull mode):
    listings.pulled.yaml   current state from ASC

Per-locale fields supported:
    name (30)              | App name              [appInfoLocalizations]
    subtitle (30)          | Subtitle              [appInfoLocalizations]
    keywords (100)         | Hidden keyword field  [appStoreVersionLocalizations]
    promo_text (170)       | Promotional text      [appStoreVersionLocalizations]
    description (4000)     | Description           [appStoreVersionLocalizations]
    whats_new (4000)       | Version notes         [appStoreVersionLocalizations]
    marketing_url          |                       [appStoreVersionLocalizations]
    support_url            |                       [appStoreVersionLocalizations]
"""

import argparse
import os
import sys
import time
from pathlib import Path

import jwt
import requests
import yaml
from dotenv import load_dotenv

ASC_BASE = "https://api.appstoreconnect.apple.com/v1"
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent

APP_INFO_FIELDS = {
    "name": "name",
    "subtitle": "subtitle",
    "privacy_policy_url": "privacyPolicyUrl",
    "privacy_policy_text": "privacyPolicyText",
}
VERSION_FIELDS = {
    "description": "description",
    "keywords": "keywords",
    "promo_text": "promotionalText",
    "whats_new": "whatsNew",
    "marketing_url": "marketingUrl",
    "support_url": "supportUrl",
}

# Ordered by preference: try PREPARE_FOR_SUBMISSION first since it's the editable
# in-flight record. READY_FOR_DISTRIBUTION is the live record — only use as fallback.
VERSION_STATE_PRIORITY = [
    "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
    "METADATA_REJECTED", "WAITING_FOR_REVIEW", "READY_FOR_REVIEW",
]
INFO_STATE_PRIORITY = [
    "PREPARE_FOR_SUBMISSION", "READY_FOR_REVIEW", "WAITING_FOR_REVIEW",
    "REJECTED", "READY_FOR_DISTRIBUTION",
]


def load_env():
    load_dotenv(SCRIPT_DIR / ".env")
    required = ["ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_APP_ID", "ASC_KEY_FILE"]
    missing = [k for k in required if not os.environ.get(k)]
    if missing:
        sys.exit(f"ERROR: missing env vars: {', '.join(missing)}. Copy .env.example to .env and fill in.")
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
        "iss": env["issuer_id"],
        "iat": int(time.time()),
        "exp": int(time.time()) + 1200,
        "aud": "appstoreconnect-v1",
    }
    headers = {"kid": env["key_id"]}
    return jwt.encode(payload, private_key, algorithm="ES256", headers=headers)


def api(method, path, token, **kwargs):
    url = f"{ASC_BASE}{path}"
    headers = {"Authorization": f"Bearer {token}"}
    if "json" in kwargs:
        headers["Content-Type"] = "application/json"
    r = requests.request(method, url, headers=headers, timeout=30, **kwargs)
    if not r.ok:
        sys.stderr.write(f"\nAPI ERROR {r.status_code} on {method} {path}:\n{r.text}\n")
        r.raise_for_status()
    if r.status_code == 204 or not r.text:
        return None
    return r.json()


def get_editable_app_info(token, app_id):
    r = api("GET", f"/apps/{app_id}/appInfos?limit=10", token)
    for state in INFO_STATE_PRIORITY:
        for info in r["data"]:
            if info["attributes"]["state"] == state:
                return info["id"]
    if r["data"]:
        first = r["data"][0]
        sys.stderr.write(f"WARN: no clearly-editable AppInfo; using first ({first['attributes']['state']}).\n")
        return first["id"]
    sys.exit("ERROR: no AppInfo records found.")


def get_editable_version(token, app_id):
    r = api("GET", f"/apps/{app_id}/appStoreVersions?limit=20", token)
    for state in VERSION_STATE_PRIORITY:
        for v in r["data"]:
            if v["attributes"]["appStoreState"] == state:
                return v["id"], v["attributes"]["versionString"], v["attributes"]["appStoreState"]
    sys.exit(
        "ERROR: no editable AppStoreVersion found. Create a new version in App Store Connect first "
        "(or wait for an in-flight version to enter an editable state)."
    )


def list_app_info_localizations(token, info_id):
    r = api("GET", f"/appInfos/{info_id}/appInfoLocalizations?limit=200", token)
    return {item["attributes"]["locale"]: item for item in r["data"]}


def list_version_localizations(token, version_id):
    r = api("GET", f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200", token)
    return {item["attributes"]["locale"]: item for item in r["data"]}


def upsert_app_info_loc(token, info_id, locale, payload, existing, dry_run):
    attrs = {APP_INFO_FIELDS[k]: v for k, v in payload.items() if k in APP_INFO_FIELDS and v is not None}
    if not attrs:
        return
    if locale in existing:
        loc_id = existing[locale]["id"]
        body = {"data": {"type": "appInfoLocalizations", "id": loc_id, "attributes": attrs}}
        verb, where = "PATCH", f"/appInfoLocalizations/{loc_id}"
    else:
        body = {
            "data": {
                "type": "appInfoLocalizations",
                "attributes": {**attrs, "locale": locale},
                "relationships": {"appInfo": {"data": {"type": "appInfos", "id": info_id}}},
            }
        }
        verb, where = "POST", "/appInfoLocalizations"
    print(f"  [appInfo] {verb:5s} {locale:8s} {', '.join(sorted(attrs.keys()))}")
    if not dry_run:
        api(verb, where, token, json=body)


def upsert_version_loc(token, version_id, locale, payload, existing, dry_run):
    attrs = {VERSION_FIELDS[k]: v for k, v in payload.items() if k in VERSION_FIELDS and v is not None}
    if not attrs:
        return
    if locale in existing:
        loc_id = existing[locale]["id"]
        body = {"data": {"type": "appStoreVersionLocalizations", "id": loc_id, "attributes": attrs}}
        verb, where = "PATCH", f"/appStoreVersionLocalizations/{loc_id}"
    else:
        body = {
            "data": {
                "type": "appStoreVersionLocalizations",
                "attributes": {**attrs, "locale": locale},
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
            }
        }
        verb, where = "POST", "/appStoreVersionLocalizations"
    print(f"  [version] {verb:5s} {locale:8s} {', '.join(sorted(attrs.keys()))}")
    if not dry_run:
        api(verb, where, token, json=body)


def cmd_pull(token, env):
    info_id = get_editable_app_info(token, env["app_id"])
    version_id, vstr, vstate = get_editable_version(token, env["app_id"])
    info_locs = list_app_info_localizations(token, info_id)
    version_locs = list_version_localizations(token, version_id)

    inv_info = {v: k for k, v in APP_INFO_FIELDS.items()}
    inv_version = {v: k for k, v in VERSION_FIELDS.items()}

    pulled = {}
    for locale in sorted(set(info_locs.keys()) | set(version_locs.keys())):
        loc_data = {}
        if locale in info_locs:
            for api_key, our_key in inv_info.items():
                val = info_locs[locale]["attributes"].get(api_key)
                if val:
                    loc_data[our_key] = val
        if locale in version_locs:
            for api_key, our_key in inv_version.items():
                val = version_locs[locale]["attributes"].get(api_key)
                if val:
                    loc_data[our_key] = val
        pulled[locale] = loc_data

    out = SCRIPT_DIR / "listings.pulled.yaml"
    with open(out, "w") as f:
        yaml.safe_dump(
            pulled, f, allow_unicode=True, sort_keys=False,
            default_flow_style=False, width=200,
        )
    print(f"\nPulled {len(pulled)} locales (version {vstr}, state {vstate}) → {out}")


def validate_lengths(payload, locale):
    """Warn (don't fail) when a field exceeds Apple's character limit."""
    limits = {"name": 30, "subtitle": 30, "keywords": 100, "promo_text": 170,
              "description": 4000, "whats_new": 4000}
    for k, limit in limits.items():
        v = payload.get(k)
        if v and len(v) > limit:
            sys.stderr.write(f"  WARN [{locale}]: {k} is {len(v)} chars (max {limit}). Apple will reject.\n")


def cmd_push(token, env, listings, target_locales, dry_run):
    info_id = get_editable_app_info(token, env["app_id"])
    version_id, vstr, vstate = get_editable_version(token, env["app_id"])
    print(f"App: {env['app_id']}, version {vstr} ({vstate})")

    info_locs = list_app_info_localizations(token, info_id)
    version_locs = list_version_localizations(token, version_id)
    print(f"Existing AppInfo locales: {len(info_locs)} | Version locales: {len(version_locs)}")

    succeeded, failed = [], []
    for locale in target_locales:
        if locale not in listings:
            print(f"\nWARN: '{locale}' not in listings.yaml, skipping")
            continue
        payload = listings[locale]
        validate_lengths(payload, locale)
        print(f"\n{locale}:")
        try:
            upsert_app_info_loc(token, info_id, locale, payload, info_locs, dry_run)
            upsert_version_loc(token, version_id, locale, payload, version_locs, dry_run)
            succeeded.append(locale)
        except requests.HTTPError as e:
            print(f"  FAILED: {e}", file=sys.stderr)
            failed.append(locale)

    print(f"\n--- Summary ---")
    print(f"Succeeded: {len(succeeded)} ({', '.join(succeeded) if succeeded else 'none'})")
    if failed:
        print(f"Failed:    {len(failed)} ({', '.join(failed)})")


def main():
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--pull", action="store_true", help="Download current state to listings.pulled.yaml")
    p.add_argument("--dry-run", action="store_true", help="Show what would be pushed without changing anything")
    p.add_argument("--locales", help="Comma-separated locale codes to push (default: all in listings.yaml)")
    p.add_argument("--listings", default=str(SCRIPT_DIR / "listings.yaml"), help="Path to listings YAML")
    args = p.parse_args()

    env = load_env()
    print(f"Authenticating to App Store Connect (key {env['key_id']})...")
    token = make_token(env)

    if args.pull:
        cmd_pull(token, env)
        return

    listings_path = Path(args.listings)
    if not listings_path.exists():
        sys.exit(
            f"ERROR: {listings_path} not found.\n"
            f"Run with --pull first to bootstrap from current ASC state, or create it manually."
        )

    with open(listings_path) as f:
        listings = yaml.safe_load(f)

    target_locales = args.locales.split(",") if args.locales else list(listings.keys())
    cmd_push(token, env, listings, target_locales, args.dry_run)
    print(f"\nDone." + (" (dry-run)" if args.dry_run else ""))


if __name__ == "__main__":
    main()
