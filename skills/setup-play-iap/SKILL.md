---
description: Create or refresh SwiftBible's in-app donation products on Google Play. Use when adding new donation tiers, fixing prices/titles, or after first-time setup of a new Android app. Mirrors `app/src/main/java/biz/am2/swiftbible/donations/DonationProducts.kt` to the Play monetization API. Idempotent — safe to re-run.
disable-model-invocation: true
allowed-tools:
  - Bash(uv run *)
  - Bash(./gradlew tasks*)
  - Read
---

# Set up Play IAP donations

Wraps `android/scripts/setup_play_iap.py`. Talks to Google's `androidpublisher.monetization.onetimeproducts` API directly (the older `inappproducts` endpoint is rejected for new apps).

## Source of truth

Donation IDs and prices live in **`android/app/src/main/java/biz/am2/swiftbible/donations/DonationProducts.kt`**. The Python script at `android/scripts/setup_play_iap.py` mirrors that list to Play. If you change the Kotlin file, update the script's `DONATIONS` list to match, then re-run.

## Quick commands

All from `android/`:

```bash
# List what's currently on Play (use this first to check state)
uv run --with google-api-python-client --with google-auth python3 scripts/setup_play_iap.py --list

# Show what would change without applying
uv run --with google-api-python-client --with google-auth python3 scripts/setup_play_iap.py --dry-run

# Upsert + activate all donations
uv run --with google-api-python-client --with google-auth python3 scripts/setup_play_iap.py
```

## What it does

For each SKU in `DONATIONS`:

1. **Upsert** via `monetization.onetimeproducts.patch` with `allowMissing=true` — creates if missing, updates if present.
2. Configures one purchase option (`purchaseOptionId="default"`) with USD price + `legacyCompatible=true` so older Play Billing client versions can find it.
3. Sets a `newRegionsConfig` so Play auto-prices in regions launched after this point (USD anchor + EUR anchor).
4. **Activate** the purchase option via `purchaseOptions.batchUpdateStates` — products land in `DRAFT` state on creation and aren't queryable from the app until activated.

Re-running the script with no SKU changes is a no-op aside from re-confirming the active state.

## Adding a new donation tier

1. Add the constant + cents value to `DonationProducts.kt`.
2. Add the same SKU + USD units/nanos to `DONATIONS` in `setup_play_iap.py`.
3. `uv run --with google-api-python-client --with google-auth python3 scripts/setup_play_iap.py`
4. Wire it into the donations UI as needed.

## Auth

Uses `android/play-key.json` (gitignored) — the same service-account credential used by `gradle-play-publisher`. Service account needs **Release manager** or **Admin** in Play Console. See `android/docs/PLAY_PUBLISHER_SETUP.md` for first-time setup.

## Why not `./gradlew :app:publishProducts`?

That gradle task targets the deprecated `inappproducts` endpoint. New Play apps (created after 2024) get a `403 "Please migrate to the new publishing API"` from that endpoint. The Python script uses the current `monetization.onetimeproducts` API.

## Verification

After running, confirm in Play Console → **Monetize with Play** → **Products** → **In-app products**. All five donations should be `Active`. The app's `DonationService` will pick them up via `BillingClient.queryProductDetails(ProductType.INAPP)`.
