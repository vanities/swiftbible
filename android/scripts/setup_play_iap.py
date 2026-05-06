#!/usr/bin/env python3
"""Create or update SwiftBible's in-app donation products on Google Play.

Mirrors `app/src/main/java/biz/am2/swiftbible/donations/DonationProducts.kt`.
Idempotent — re-running upserts the same products and re-activates them.

Usage:
  uv run python3 scripts/setup_play_iap.py             # create + activate all
  uv run python3 scripts/setup_play_iap.py --list      # list current products
  uv run python3 scripts/setup_play_iap.py --dry-run   # show what would change

Prereqs:
  - android/play-key.json (service account, Release manager role)
  - uv pip install google-api-python-client google-auth (auto-installed via uv)
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
except ImportError:
    sys.stderr.write(
        "Missing deps. Run via uv:\n"
        "  uv run --with google-api-python-client --with google-auth "
        "python3 scripts/setup_play_iap.py\n"
    )
    sys.exit(1)

PACKAGE = "biz.am2.swiftbible"
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]
KEY_PATH = Path(__file__).parent.parent / "play-key.json"
REGIONS_VERSION = "2022/02"

# Source of truth: DonationProducts.kt
DONATIONS = [
    ("donation_3",  "Donation - $3",  "Support SwiftBible with a small donation",        2,  990000000),
    ("donation_5",  "Donation - $5",  "Support SwiftBible with a donation",              4,  990000000),
    ("donation_10", "Donation - $10", "Support SwiftBible with a generous donation",     9,  990000000),
    ("donation_25", "Donation - $25", "Support SwiftBible with a champion donation",     24, 990000000),
    ("donation_50", "Donation - $50", "Support SwiftBible with an extraordinary donation", 49, 990000000),
]


def make_service():
    if not KEY_PATH.exists():
        sys.exit(f"play-key.json not found at {KEY_PATH}")
    creds = service_account.Credentials.from_service_account_file(str(KEY_PATH), scopes=SCOPES)
    return build("androidpublisher", "v3", credentials=creds)


def list_products(service) -> list[dict]:
    resp = service.monetization().onetimeproducts().list(packageName=PACKAGE).execute()
    return resp.get("oneTimeProducts", [])


def upsert_product(service, sku: str, title: str, description: str, units: int, nanos: int, *, dry_run: bool):
    price = {"currencyCode": "USD", "units": str(units), "nanos": nanos}
    body = {
        "packageName": PACKAGE,
        "productId": sku,
        "listings": [{"languageCode": "en-US", "title": title, "description": description}],
        "taxAndComplianceSettings": {"isTokenizedDigitalAsset": False},
        "purchaseOptions": [{
            "purchaseOptionId": "default",
            "buyOption": {"legacyCompatible": True},
            "regionalPricingAndAvailabilityConfigs": [
                {"regionCode": "US", "price": price, "availability": "AVAILABLE"}
            ],
            "newRegionsConfig": {
                "usdPrice": price,
                "eurPrice": {"currencyCode": "EUR", "units": str(units), "nanos": nanos},
                "availability": "AVAILABLE",
            },
        }],
    }
    if dry_run:
        print(f"  [dry-run] would patch {sku} (${units}.{nanos // 10_000_000:02d})")
        return
    service.monetization().onetimeproducts().patch(
        packageName=PACKAGE,
        productId=sku,
        body=body,
        regionsVersion_version=REGIONS_VERSION,
        updateMask="listings,purchaseOptions,taxAndComplianceSettings",
        allowMissing=True,
    ).execute()
    print(f"  upserted {sku}")


def activate_options(service, skus: list[str], *, dry_run: bool):
    """Move each product's `default` purchase option from DRAFT to ACTIVE.

    The batchUpdateStates endpoint is per-product, so we call it once per SKU.
    """
    if dry_run:
        print(f"  [dry-run] would activate {len(skus)} purchase options")
        return
    for sku in skus:
        body = {
            "requests": [{
                "activatePurchaseOptionRequest": {
                    "packageName": PACKAGE,
                    "productId": sku,
                    "purchaseOptionId": "default",
                }
            }]
        }
        try:
            resp = service.monetization().onetimeproducts().purchaseOptions().batchUpdateStates(
                packageName=PACKAGE, productId=sku, body=body
            ).execute()
            states = [
                o.get("state")
                for p in resp.get("oneTimeProducts", [])
                for o in p.get("purchaseOptions", [])
            ]
            print(f"  {sku}: activated → {states}")
        except HttpError as e:
            # Already active is harmless — Play returns 400 if state isn't changing.
            msg = str(e)
            if "INVALID_ARGUMENT" in msg and "already" in msg.lower():
                print(f"  {sku}: already active")
            else:
                print(f"  {sku}: activation failed → {e}")
                raise


def cmd_list(service):
    products = list_products(service)
    print(f"Existing one-time products: {len(products)}")
    for p in products:
        sku = p.get("productId")
        title = next((l.get("title") for l in p.get("listings", []) if l.get("languageCode") == "en-US"), "?")
        opts = p.get("purchaseOptions", [])
        states = [o.get("state") for o in opts]
        print(f"  {sku}: {title!r} - states={states}")


def cmd_setup(service, dry_run: bool):
    print(f"Upserting {len(DONATIONS)} donation products...")
    for sku, title, desc, units, nanos in DONATIONS:
        upsert_product(service, sku, title, desc, units, nanos, dry_run=dry_run)
    print("\nActivating purchase options...")
    activate_options(service, [d[0] for d in DONATIONS], dry_run=dry_run)
    print("\nDone.")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true", help="List existing products and exit")
    ap.add_argument("--dry-run", action="store_true", help="Print actions without applying")
    args = ap.parse_args()

    service = make_service()
    if args.list:
        cmd_list(service)
    else:
        cmd_setup(service, args.dry_run)


if __name__ == "__main__":
    main()
