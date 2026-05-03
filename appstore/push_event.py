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


_territory_cache = None


def list_all_territories(token):
    """Fetch every territory Apple supports — needed to set a 'worldwide' IAE
    (territories array MUST be non-empty or Apple's API 500s)."""
    global _territory_cache
    if _territory_cache is not None:
        return _territory_cache
    out = []
    url = f"{ASC_BASE}/territories?limit=200"
    while url:
        r = requests.get(url, headers={"Authorization": f"Bearer {token}"}, timeout=30)
        r.raise_for_status()
        j = r.json()
        out.extend([t["id"] for t in j["data"]])
        url = j.get("links", {}).get("next")
    _territory_cache = out
    return out


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


def delete_event_asset(token, asset_id):
    api("DELETE", f"/appEventScreenshots/{asset_id}", token)


# Map filename suffix → Apple's appEventAssetType.
# Drop these naming conventions in appstore/events/<slug>/:
#   <slug>_event.png         OR  event_card.png    →  EVENT_CARD       (1080x1080)
#   <slug>_event_details.png OR  event_details.png →  EVENT_DETAILS_PAGE    (1920x1080)
def find_event_images(event_dir):
    """Return [(path, asset_type), ...] for the recognized images in event_dir."""
    images = []
    for p in sorted(event_dir.glob("*.png")):
        name = p.stem.lower()
        if name.endswith("_event_details") or name in ("event_details", "details"):
            images.append((p, "EVENT_DETAILS_PAGE"))
        elif (name.endswith("_event") or name.endswith("_event_card")
              or name in ("event_card", "card")):
            images.append((p, "EVENT_CARD"))
    return images


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
    # territorySchedules is set later (needs explicit territories list)
    return {k: v for k, v in attrs.items() if v is not None}


def build_territory_schedule(cfg, token):
    sched = cfg.get("schedule") or {}
    if not sched:
        return None
    territories = cfg.get("territories")
    if not territories or territories == "all":
        territories = list_all_territories(token)
    return [{
        "publishStart": _iso(sched.get("publish_start") or sched.get("start")),
        "eventStart":   _iso(sched.get("event_start")   or sched.get("start")),
        "eventEnd":     _iso(sched.get("event_end")     or sched.get("end")),
        "territories":  territories,
    }]


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


def upload_event_image(token, locale_id, image_path, asset_type, dry_run):
    """Three-step asset upload for an event image of the given asset_type
    (EVENT_CARD or EVENT_DETAILS_PAGE), attached to a locale."""
    if not image_path.exists():
        print(f"  ! image not found: {image_path}", file=sys.stderr)
        return
    file_size = image_path.stat().st_size
    print(f"  [img] uploading {image_path.name} ({file_size//1024}KB) as {asset_type} → locale {locale_id}")
    if dry_run:
        return

    # 1. Reserve.
    body = {
        "data": {
            "type": "appEventScreenshots",
            "attributes": {
                "fileName": image_path.name,
                "fileSize": file_size,
                "appEventAssetType": asset_type,
            },
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

    # 3. Commit. appEventScreenshots doesn't accept sourceFileChecksum
    # (unlike appScreenshots which does).
    commit = {
        "data": {
            "type": "appEventScreenshots",
            "id": sid,
            "attributes": {"uploaded": True},
        }
    }
    api("PATCH", f"/appEventScreenshots/{sid}", token, json=commit)
    print(f"        ✓ committed")


def submit_event_for_review(token, app_id, event_id, dry_run):
    """Submit an IAE through Apple's reviewSubmissions flow (same flow as
    version submission, just with appEvent items instead of appStoreVersion)."""
    if dry_run:
        print(f"  → DRY would submit event {event_id} via reviewSubmissions")
        return

    # 1. Find or create an in-progress reviewSubmission for this app.
    # Only READY_FOR_REVIEW state allows adding items / submitting; anything
    # else (COMPLETE, IN_REVIEW, etc) needs a fresh submission.
    r = api("GET", f"/apps/{app_id}/reviewSubmissions?limit=20", token)
    existing = None
    for s in r.get("data", []):
        if s["attributes"].get("state") == "READY_FOR_REVIEW":
            existing = s
            break
    if existing:
        sub_id = existing["id"]
        print(f"  → using existing review submission {sub_id} (state READY_FOR_REVIEW)")
    else:
        body = {
            "data": {
                "type": "reviewSubmissions",
                "attributes": {"platform": "IOS"},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
            }
        }
        sub = api("POST", "/reviewSubmissions", token, json=body)
        sub_id = sub["data"]["id"]
        print(f"  → created review submission {sub_id}")

    # 2. Add the appEvent as an item on the submission.
    item_body = {
        "data": {
            "type": "reviewSubmissionItems",
            "relationships": {
                "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
                "appEvent":         {"data": {"type": "appEvents", "id": event_id}},
            }
        }
    }
    api("POST", "/reviewSubmissionItems", token, json=item_body)
    print(f"  → added event {event_id} as submission item")

    # 3. Mark submitted: true to send to Apple's review queue.
    submit_body = {
        "data": {
            "type": "reviewSubmissions",
            "id": sub_id,
            "attributes": {"submitted": True},
        }
    }
    api("PATCH", f"/reviewSubmissions/{sub_id}", token, json=submit_body)
    print(f"  ✓ submitted for review (Apple will respond in 24-72h)")


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


def cmd_push(token, app_id, event_slug, submit, dry_run, replace_images=False):
    event_dir = EVENTS_DIR / event_slug
    yaml_path = event_dir / "event.yaml"
    if not yaml_path.exists():
        sys.exit(f"ERROR: {yaml_path} not found")
    with open(yaml_path) as f:
        cfg = yaml.safe_load(f)

    print(f"Event: {cfg['reference_name']}")
    print(f"Source: {yaml_path}")

    # Find recognized event images (EVENT_CARD + optional EVENT_DETAILS_PAGE).
    image_specs = find_event_images(event_dir)

    # 1. Find or create the AppEvent
    attrs = build_event_attributes(cfg)
    schedules = build_territory_schedule(cfg, token) if not dry_run else None

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

    # 1b. Apply territorySchedules via PATCH (must happen after the event exists,
    # and territories array MUST be non-empty or Apple's API 500s).
    if schedules and not dry_run:
        n_terr = len(schedules[0].get("territories", []))
        print(f"  Setting schedule across {n_terr} territor{'y' if n_terr == 1 else 'ies'}")
        try:
            update_event(token, event_id, {"territorySchedules": schedules}, dry_run)
        except requests.HTTPError as e:
            sys.stderr.write(
                f"  ! territorySchedules PATCH failed ({e.response.status_code}). "
                f"Set schedule manually in ASC web UI before submitting.\n"
            )

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

    # 3. Image upload(s) — attach to primary locale per Apple's IAE asset model.
    if image_specs:
        primary_locale = cfg.get("primary_locale", "en-US")
        primary_loc_id = locale_ids.get(primary_locale)
        if primary_loc_id and not str(primary_loc_id).startswith("<dry-run"):
            existing_assets = list_event_assets(token, event_id, primary_loc_id)
            existing_by_type = {
                a["attributes"].get("appEventAssetType"): a for a in existing_assets
            }
            for image_path, asset_type in image_specs:
                existing = existing_by_type.get(asset_type)
                if existing and not replace_images:
                    print(f"  [img] {asset_type} already exists ({existing['attributes'].get('fileName')}) — pass REPLACE_IMAGES=1 to overwrite")
                    continue
                if existing and replace_images:
                    print(f"  [img] deleting existing {asset_type} ({existing['attributes'].get('fileName')})")
                    if not dry_run:
                        delete_event_asset(token, existing["id"])
                upload_event_image(token, primary_loc_id, image_path, asset_type, dry_run)
        elif dry_run:
            for image_path, asset_type in image_specs:
                print(f"  [img] DRY would upload {image_path.name} as {asset_type}")
    else:
        print("  ! no recognized event PNG in dir (looking for *_event.png or *_event_details.png)")

    # 4. Submit if requested
    if submit:
        submit_event_for_review(token, app_id, event_id, dry_run)

    print(f"\nDone." + (" (dry-run)" if dry_run else ""))


def main():
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--pull", action="store_true", help="List existing events in ASC")
    p.add_argument("--event", help="Event slug (folder name under appstore/events/)")
    p.add_argument("--submit", action="store_true", help="Also transition to READY_FOR_REVIEW")
    p.add_argument("--dry-run", action="store_true", help="Preview without making changes")
    p.add_argument("--replace-images", action="store_true",
                   help="Delete existing event assets before uploading (otherwise existing ones are preserved)")
    args = p.parse_args()

    env = load_env()
    print(f"Authenticating to App Store Connect (key {env['key_id']})...")
    token = make_token(env)

    if args.pull:
        cmd_pull(token, env["app_id"])
        return

    if not args.event:
        sys.exit("ERROR: --event <slug> required (or use --pull)")

    cmd_push(token, env["app_id"], args.event, args.submit, args.dry_run, args.replace_images)


if __name__ == "__main__":
    main()
