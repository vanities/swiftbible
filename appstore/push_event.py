#!/usr/bin/env python3
"""Create / update / submit App Store In-App Events via the App Store Connect API.

Reads from appstore/events/<slug>/event.yaml. Handles:
- Create AppEvent if it doesn't exist (matching by referenceName), else PATCH
- Create or PATCH AppEventLocalizations per locale (name, short, long, deep link)
- Upload event image (3-step asset flow: reserve → PUT chunks → commit)
- Set territorySchedules from event.yaml schedule
- Optionally submit for review (--submit) by transitioning eventState to READY_FOR_REVIEW

Usage:
    uv run python appstore/push_event.py --event pentecost
    uv run python appstore/push_event.py --event pentecost --dry-run
    uv run python appstore/push_event.py --event pentecost --submit
    uv run python appstore/push_event.py --pull         # list current events

Reads:
    .env                          credentials
    events/<slug>/event.yaml      event definition + localizations
    events/<slug>/*.png           event image (1080x1080)
"""

import argparse
import hashlib
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
EVENTS_DIR = SCRIPT_DIR / "events"

# Map our event_type strings to Apple's badge enum values.
BADGE_MAP = {
    "Special Event":  "SPECIAL_EVENT",
    "New Season":     "NEW_SEASON",
    "Premiere":       "PREMIERE",
    "Challenge":      "CHALLENGE",
    "Live Event":     "LIVE_EVENT",
    "Major Update":   "MAJOR_UPDATE",
    "Competition":    "COMPETITION",
}

PRIORITY_MAP = {"LOW": "LOW", "NORMAL": "NORMAL", "HIGH": "HIGH"}

PURPOSE_MAP = {
    "Appropriate for All Users":     "APPROPRIATE_FOR_ALL_USERS",
    "Appropriate for Certain Users": "APPROPRIATE_FOR_CERTAIN_USERS",
}

PURCHASE_REQ_MAP = {
    "FREE":              "NO_COST_ASSOCIATED",
    "Free":              "NO_COST_ASSOCIATED",
    "In-App Purchase":   "IN_APP_PURCHASE",
    "Subscription":      "REQUIRES_AUTO_RENEWING_SUBSCRIPTION",
}


def load_env():
    load_dotenv(SCRIPT_DIR / ".env")
    required = ["ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_APP_ID", "ASC_KEY_FILE"]
    missing = [k for k in required if not os.environ.get(k)]
    if missing:
        sys.exit(f"ERROR: missing env vars: {', '.join(missing)}")
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
    pk = env["key_file"].read_text()
    payload = {
        "iss": env["issuer_id"], "iat": int(time.time()),
        "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1",
    }
    return jwt.encode(payload, pk, algorithm="ES256", headers={"kid": env["key_id"]})


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


def md5(path):
    h = hashlib.md5()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def list_events(token, app_id):
    r = api("GET", f"/apps/{app_id}/appEvents?limit=200", token)
    return r["data"]


def find_event_by_reference_name(token, app_id, reference_name):
    for ev in list_events(token, app_id):
        if ev["attributes"].get("referenceName") == reference_name:
            return ev
    return None


def list_event_localizations(token, event_id):
    r = api("GET", f"/appEvents/{event_id}/localizations?limit=200", token)
    return {item["attributes"]["locale"]: item for item in r["data"]}


def list_event_assets(token, event_id, locale_id):
    r = api("GET", f"/appEventLocalizations/{locale_id}/appEventScreenshots?limit=20", token)
    return r["data"]


def build_event_attributes(cfg):
    attrs = {
        "referenceName": cfg["reference_name"],
        "badge": BADGE_MAP.get(cfg.get("event_type"), "SPECIAL_EVENT"),
        "priority": PRIORITY_MAP.get(cfg.get("priority", "NORMAL").upper(), "NORMAL"),
        "purpose": PURPOSE_MAP.get(cfg.get("purpose", "Appropriate for All Users"),
                                   "APPROPRIATE_FOR_ALL_USERS"),
        "purchaseRequirement": PURCHASE_REQ_MAP.get(cfg.get("purchase_requirement", "FREE"),
                                                     "NO_COST_ASSOCIATED"),
        "primaryLocale": cfg.get("primary_locale", "en-US"),
        "deepLink": cfg.get("deep_link"),
    }
    sched = cfg.get("schedule") or {}
    if sched:
        attrs["territorySchedules"] = [{
            "publishStart": _iso(sched.get("publish_start") or sched.get("start")),
            "eventStart":   _iso(sched.get("event_start")   or sched.get("start")),
            "eventEnd":     _iso(sched.get("event_end")     or sched.get("end")),
        }]
    return {k: v for k, v in attrs.items() if v is not None}


def _iso(s):
    """Convert a yaml-friendly date string to API-friendly ISO 8601 (with seconds)."""
    if not s:
        return None
    from datetime import datetime
    raw = str(s).strip().replace(" UTC", "").replace("Z", "")
    # Try a few common forms; fall through on the first parseable.
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M",
                "%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M",
                "%Y-%m-%d"):
        try:
            return datetime.strptime(raw, fmt).strftime("%Y-%m-%dT%H:%M:%SZ")
        except ValueError:
            continue
    return raw  # let the API surface the error if we couldn't parse


def create_event(token, app_id, attrs, dry_run):
    body = {
        "data": {
            "type": "appEvents",
            "attributes": attrs,
            "relationships": {
                "app": {"data": {"type": "apps", "id": app_id}}
            }
        }
    }
    print(f"  POST /appEvents (referenceName={attrs['referenceName']})")
    if dry_run:
        return "<dry-run-event-id>"
    r = api("POST", "/appEvents", token, json=body)
    return r["data"]["id"]


def update_event(token, event_id, attrs, dry_run):
    body = {"data": {"type": "appEvents", "id": event_id, "attributes": attrs}}
    print(f"  PATCH /appEvents/{event_id}")
    if dry_run:
        return
    api("PATCH", f"/appEvents/{event_id}", token, json=body)


def upsert_event_localization(token, event_id, locale, payload, existing, dry_run):
    attrs = {
        "name": payload.get("name"),
        "shortDescription": payload.get("short"),
        "longDescription": payload.get("long"),
    }
    attrs = {k: v for k, v in attrs.items() if v}
    if not attrs:
        return None
    if locale in existing:
        loc_id = existing[locale]["id"]
        body = {"data": {"type": "appEventLocalizations", "id": loc_id, "attributes": attrs}}
        print(f"  [loc] PATCH {locale:8s} {', '.join(sorted(attrs.keys()))}")
        if not dry_run:
            api("PATCH", f"/appEventLocalizations/{loc_id}", token, json=body)
        return loc_id
    body = {
        "data": {
            "type": "appEventLocalizations",
            "attributes": {**attrs, "locale": locale},
            "relationships": {"appEvent": {"data": {"type": "appEvents", "id": event_id}}},
        }
    }
    print(f"  [loc] POST  {locale:8s} {', '.join(sorted(attrs.keys()))}")
    if dry_run:
        return f"<dry-run-loc-{locale}>"
    r = api("POST", "/appEventLocalizations", token, json=body)
    return r["data"]["id"]


def upload_event_image(token, locale_id, image_path, dry_run):
    """Three-step asset upload for the event image, attached to a locale."""
    if not image_path.exists():
        print(f"  ! image not found: {image_path}", file=sys.stderr)
        return
    file_size = image_path.stat().st_size
    print(f"  [img] uploading {image_path.name} ({file_size//1024}KB) → locale {locale_id}")
    if dry_run:
        return

    # 1. Reserve
    body = {
        "data": {
            "type": "appEventScreenshots",
            "attributes": {"fileName": image_path.name, "fileSize": file_size},
            "relationships": {
                "appEventLocalization": {
                    "data": {"type": "appEventLocalizations", "id": locale_id}
                }
            }
        }
    }
    r = api("POST", "/appEventScreenshots", token, json=body)
    sid = r["data"]["id"]
    ops = r["data"]["attributes"]["uploadOperations"]

    # 2. PUT chunks
    file_bytes = image_path.read_bytes()
    for op in ops:
        chunk = file_bytes[op["offset"]:op["offset"] + op["length"]]
        ch_headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        resp = requests.request(op["method"], op["url"], headers=ch_headers, data=chunk, timeout=120)
        resp.raise_for_status()

    # 3. Commit
    commit = {
        "data": {
            "type": "appEventScreenshots",
            "id": sid,
            "attributes": {"uploaded": True, "sourceFileChecksum": md5(image_path)},
        }
    }
    api("PATCH", f"/appEventScreenshots/{sid}", token, json=commit)
    print(f"        ✓ committed")


def submit_event_for_review(token, event_id, dry_run):
    """Transition the event from DRAFT to READY_FOR_REVIEW."""
    body = {
        "data": {
            "type": "appEvents",
            "id": event_id,
            "attributes": {"eventState": "READY_FOR_REVIEW"},
        }
    }
    print(f"  → submitting event {event_id} (READY_FOR_REVIEW)")
    if dry_run:
        return
    api("PATCH", f"/appEvents/{event_id}", token, json=body)
    print(f"        ✓ submitted for review")


def cmd_pull(token, app_id):
    events = list_events(token, app_id)
    if not events:
        print("No events.")
        return
    print(f"{len(events)} event(s):\n")
    for ev in events:
        a = ev["attributes"]
        print(f"  {a.get('referenceName', '<no name>')}")
        print(f"    id:     {ev['id']}")
        print(f"    state:  {a.get('eventState', '?')}")
        print(f"    badge:  {a.get('badge', '?')}")
        print(f"    deepLink: {a.get('deepLink', '-')}")
        scheds = a.get("territorySchedules") or []
        if scheds:
            s = scheds[0]
            print(f"    schedule: publish {s.get('publishStart')} → event {s.get('eventStart')} → end {s.get('eventEnd')}")
        locs = list_event_localizations(token, ev['id'])
        print(f"    locales: {sorted(locs.keys())}")
        print()


def cmd_push(token, app_id, event_slug, submit, dry_run):
    event_dir = EVENTS_DIR / event_slug
    yaml_path = event_dir / "event.yaml"
    if not yaml_path.exists():
        sys.exit(f"ERROR: {yaml_path} not found")
    with open(yaml_path) as f:
        cfg = yaml.safe_load(f)

    print(f"Event: {cfg['reference_name']}")
    print(f"Source: {yaml_path}")

    # Find the event image (any 1080x1080 PNG in the dir)
    image_path = None
    for p in event_dir.glob("*.png"):
        image_path = p
        break

    # 1. Find or create the AppEvent
    attrs = build_event_attributes(cfg)
    # Apple's API doesn't accept territorySchedules at creation time — split it out.
    schedules = attrs.pop("territorySchedules", None)

    existing = find_event_by_reference_name(token, app_id, cfg["reference_name"])
    if existing:
        event_id = existing["id"]
        state = existing["attributes"].get("eventState")
        print(f"  Found existing event {event_id} (state {state})")
        if state and state != "DRAFT":
            print(f"  ! event is in state {state}, attribute changes may be limited")
        update_event(token, event_id, attrs, dry_run)
    else:
        event_id = create_event(token, app_id, attrs, dry_run)
        print(f"  Created event {event_id}")

    # 1b. Apply territorySchedules via PATCH (must happen after the event exists).
    if schedules:
        update_event(token, event_id, {"territorySchedules": schedules}, dry_run)

    # 2. Localizations
    if not dry_run and existing:
        existing_locs = list_event_localizations(token, event_id)
    else:
        existing_locs = {}

    locale_ids = {}
    for locale, payload in cfg.get("locales", {}).items():
        loc_id = upsert_event_localization(token, event_id, locale, payload, existing_locs, dry_run)
        if loc_id:
            locale_ids[locale] = loc_id

    # 3. Image upload — attach to primary locale (per Apple's IAE asset model)
    if image_path:
        primary_locale = cfg.get("primary_locale", "en-US")
        primary_loc_id = locale_ids.get(primary_locale)
        if primary_loc_id and not str(primary_loc_id).startswith("<dry-run"):
            existing_assets = list_event_assets(token, event_id, primary_loc_id) if not dry_run else []
            if existing_assets:
                print(f"  [img] {len(existing_assets)} existing asset(s) — skipping upload (delete in ASC to replace)")
            else:
                upload_event_image(token, primary_loc_id, image_path, dry_run)
        elif dry_run:
            print(f"  [img] DRY would upload {image_path.name}")
    else:
        print("  ! no PNG found in event dir — skipping image upload")

    # 4. Submit if requested
    if submit:
        submit_event_for_review(token, event_id, dry_run)

    print(f"\nDone." + (" (dry-run)" if dry_run else ""))


def main():
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--pull", action="store_true", help="List existing events in ASC")
    p.add_argument("--event", help="Event slug (folder name under appstore/events/)")
    p.add_argument("--submit", action="store_true", help="Also transition to READY_FOR_REVIEW")
    p.add_argument("--dry-run", action="store_true", help="Preview without making changes")
    args = p.parse_args()

    env = load_env()
    print(f"Authenticating to App Store Connect (key {env['key_id']})...")
    token = make_token(env)

    if args.pull:
        cmd_pull(token, env["app_id"])
        return

    if not args.event:
        sys.exit("ERROR: --event <slug> required (or use --pull)")

    cmd_push(token, env["app_id"], args.event, args.submit, args.dry_run)


if __name__ == "__main__":
    main()
