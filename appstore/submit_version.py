#!/usr/bin/env python3
"""Submit the editable App Store version for review.

Wraps Apple's `/v1/reviewSubmissions` flow:
1. Find the editable AppStoreVersion (state PREPARE_FOR_SUBMISSION)
2. Create a ReviewSubmission for the app
3. Add the version as an item in the submission
4. Set the submission to SUBMITTED

Usage:
    uv run python appstore/submit_version.py --dry-run     # preview
    uv run python appstore/submit_version.py               # submit

This is the API equivalent of clicking "Submit for Review" in App Store Connect.
"""

import argparse
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

EDITABLE_VERSION_STATES = {
    "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
    "METADATA_REJECTED", "READY_FOR_REVIEW",
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
    r = requests.request(method, url, headers=headers, timeout=60, **kwargs)
    if not r.ok:
        sys.stderr.write(f"\nAPI ERROR {r.status_code} on {method} {path}:\n{r.text}\n")
        r.raise_for_status()
    if r.status_code == 204 or not r.text:
        return None
    return r.json()


def get_editable_version(token, app_id):
    r = api("GET", f"/apps/{app_id}/appStoreVersions?limit=20&include=build", token)
    for state in EDITABLE_VERSION_STATES:
        for v in r["data"]:
            if v["attributes"]["appStoreState"] == state:
                attached = (v.get("relationships", {}).get("build", {}).get("data") or {}).get("id")
                return v["id"], v["attributes"]["versionString"], state, attached
    sys.exit("ERROR: no editable AppStoreVersion found.")


def find_build_for_version(token, app_id, vstr):
    """Return the most recent VALID build whose preReleaseVersion matches vstr, or None."""
    r = api(
        "GET",
        f"/builds?filter[app]={app_id}&filter[processingState]=VALID&filter[preReleaseVersion.version]={vstr}"
        "&sort=-uploadedDate&limit=1&fields[builds]=version,uploadedDate",
        token,
    )
    data = r.get("data", [])
    return data[0]["id"] if data else None


def attach_build(token, version_id, build_id, dry_run):
    print(f"  PATCH /appStoreVersions/{version_id}/relationships/build (build {build_id})")
    if dry_run:
        return
    body = {"data": {"type": "builds", "id": build_id}}
    api("PATCH", f"/appStoreVersions/{version_id}/relationships/build", token, json=body)


def find_inflight_review_submission(token, app_id):
    """Find a reviewSubmission we can still add items to / submit. Only the
    READY_FOR_REVIEW state is editable; COMPLETE / IN_REVIEW / etc are not."""
    r = api("GET", f"/apps/{app_id}/reviewSubmissions?limit=20", token)
    for s in r.get("data", []):
        if s["attributes"].get("state") == "READY_FOR_REVIEW":
            return s
    return None


def create_review_submission(token, app_id, dry_run):
    body = {
        "data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}
        }
    }
    print("  POST /reviewSubmissions")
    if dry_run:
        return "<dry-run-submission-id>"
    r = api("POST", "/reviewSubmissions", token, json=body)
    return r["data"]["id"]


def add_version_item(token, submission_id, version_id, dry_run):
    body = {
        "data": {
            "type": "reviewSubmissionItems",
            "relationships": {
                "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                "appStoreVersion":  {"data": {"type": "appStoreVersions", "id": version_id}},
            }
        }
    }
    print(f"  POST /reviewSubmissionItems (version {version_id} → submission {submission_id})")
    if dry_run:
        return
    try:
        api("POST", "/reviewSubmissionItems", token, json=body)
    except requests.exceptions.HTTPError as e:
        # 409 = this version is already an item on the submission. Safe on a
        # retry after a transient failure — treat as already present.
        if e.response is not None and e.response.status_code == 409:
            print(f"  Version {version_id} already on submission {submission_id} (409 — treating as present)")
        else:
            raise


def list_submission_items(token, submission_id):
    # include=appStoreVersion so each item carries its appStoreVersion relationship
    # linkage (data.id). Without include, Apple omits the linkage, so the
    # "already on submission" check in main() can't recognize an item it already
    # created — and re-adding it returns 409 Conflict on a retry.
    r = api("GET", f"/reviewSubmissions/{submission_id}/items?limit=20&include=appStoreVersion", token)
    return r.get("data", [])


def mark_submitted(token, submission_id, dry_run):
    """Set the review submission's submitted attribute to true."""
    body = {
        "data": {
            "type": "reviewSubmissions",
            "id": submission_id,
            "attributes": {"submitted": True},
        }
    }
    print(f"  PATCH /reviewSubmissions/{submission_id} (submitted: true)")
    if dry_run:
        return
    api("PATCH", f"/reviewSubmissions/{submission_id}", token, json=body)


def main():
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--dry-run", action="store_true", help="Preview without submitting")
    args = p.parse_args()

    env = load_env()
    print(f"Authenticating to App Store Connect (key {env['key_id']})...")
    token = make_token(env)

    version_id, vstr, vstate, attached_build = get_editable_version(token, env["app_id"])
    print(f"Version: {vstr} (id {version_id}, state {vstate}, attached_build={attached_build or 'none'})")

    if not attached_build:
        build_id = find_build_for_version(token, env["app_id"], vstr)
        if not build_id:
            sys.exit(f"ERROR: no VALID build found for version {vstr}. Run `make release` and wait for processing.")
        attach_build(token, version_id, build_id, args.dry_run)

    existing = find_inflight_review_submission(token, env["app_id"])
    if existing:
        sub_id = existing["id"]
        sub_state = existing["attributes"].get("state")
        sub_submitted = existing["attributes"].get("submitted")
        print(f"Existing review submission: {sub_id} (state {sub_state}, submitted={sub_submitted})")
        if sub_submitted:
            sys.exit("ERROR: a submission is already in progress with Apple. Wait for it to resolve.")
    else:
        sub_id = create_review_submission(token, env["app_id"], args.dry_run)
        print(f"Created review submission: {sub_id}")

    # Add the version as an item if it isn't already
    if existing and not args.dry_run:
        items = list_submission_items(token, sub_id)
        already = any(
            (i.get("relationships", {}).get("appStoreVersion", {}).get("data", {}) or {}).get("id") == version_id
            for i in items
        )
        if already:
            print(f"  Version {vstr} already on submission {sub_id}")
        else:
            add_version_item(token, sub_id, version_id, args.dry_run)
    else:
        add_version_item(token, sub_id, version_id, args.dry_run)

    mark_submitted(token, sub_id, args.dry_run)

    print(f"\nDone." + (" (dry-run)" if args.dry_run else ""))
    if not args.dry_run:
        print(f"Apple is now reviewing version {vstr}. Typical review time: 24-48h.")
        print("Track at: App Store Connect → SwiftBible → App Store → 1.x → Submission Status")


if __name__ == "__main__":
    main()
