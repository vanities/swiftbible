---
description: SwiftBible's Google Play Store listing automation — pull current state from Play, push localized listings (title/short-description/full-description/graphics), push IAP products, and manage release notes via gradle-play-publisher. Use when updating the Play Store listing, adding screenshots, refreshing what's-new, adding a new locale, or pulling current Play state into the repo.
allowed-tools:
  - Bash(./gradlew bootstrapListing*)
  - Bash(./gradlew :app:bootstrapListing*)
  - Bash(./gradlew publishListing*)
  - Bash(./gradlew :app:publishListing*)
  - Bash(./gradlew publishProducts*)
  - Bash(./gradlew :app:publishProducts*)
  - Bash(./gradlew tasks*)
  - Bash(./gradlew help*)
  - Bash(ls *)
  - Bash(cat *)
---

# Google Play Listing Automation

Wraps the [`com.github.triplet.play`](https://github.com/Triple-T/gradle-play-publisher) plugin's tasks for the SwiftBible Play Store listing. No Fastlane required.

## Files

| Path | Purpose |
|---|---|
| `android/app/src/main/play/contact-email.txt` | Developer contact email |
| `android/app/src/main/play/contact-website.txt` | Developer website URL |
| `android/app/src/main/play/default-language.txt` | Default listing locale (e.g. `en-US`) |
| `android/app/src/main/play/listings/<locale>/title.txt` | App name (max 50 chars) |
| `android/app/src/main/play/listings/<locale>/short-description.txt` | Short description (max 80 chars) |
| `android/app/src/main/play/listings/<locale>/full-description.txt` | Full description (max 4000 chars) |
| `android/app/src/main/play/listings/<locale>/graphics/icon/icon.png` | 512×512 high-res icon |
| `android/app/src/main/play/listings/<locale>/graphics/feature-graphic/feature.png` | 1024×500 feature graphic |
| `android/app/src/main/play/listings/<locale>/graphics/phone-screenshots/*.png` | Phone screenshots (sorted by filename) |
| `android/app/src/main/play/listings/<locale>/graphics/tablet-screenshots/*.png` | 7-inch tablet screenshots (optional) |
| `android/app/src/main/play/listings/<locale>/graphics/large-tablet-screenshots/*.png` | 10-inch tablet screenshots (optional) |
| `android/app/src/main/play/release-notes/<locale>/<track>.txt` | Release notes for a specific track (e.g. `production.txt`) |
| `android/play-key.json` | Service account credentials (gitignored). See `android/docs/PLAY_PUBLISHER_SETUP.md` |

## Quick command reference

All commands run from the `android/` directory.

### Pull current Play state (destructive — overwrites local files)

The single `bootstrapListing` task accepts flags for which categories to pull. Combine flags as needed:

```bash
cd android
./gradlew :app:bootstrapListing --listings --release-notes --app-details
./gradlew :app:bootstrapListing --products            # IAP managed products
./gradlew :app:bootstrapListing --subscriptions       # IAP subscriptions (monetization API)
./gradlew :app:bootstrapListing                       # Default — bootstraps everything
```

Available flags: `--app-details`, `--listings`, `--release-notes`, `--products`, `--subscriptions`. Each has a `--no-X` variant to opt out. `bootstrapListing` overwrites local files with whatever is in Play, so commit (or stash) any local edits first.

### Push listing changes

```bash
cd android
./gradlew :app:publishListing            # Push title/description/graphics + app details
./gradlew :app:publishProducts           # Push IAP products (donations)
```

### Inspect available tasks

```bash
cd android
./gradlew tasks --group=play
```

## Locale layout

```
android/app/src/main/play/
├── contact-email.txt
├── contact-website.txt
├── default-language.txt
├── listings/
│   ├── en-US/
│   │   ├── title.txt
│   │   ├── short-description.txt
│   │   ├── full-description.txt
│   │   └── graphics/
│   │       ├── icon/icon.png
│   │       ├── feature-graphic/feature.png
│   │       └── phone-screenshots/
│   │           ├── 01.png
│   │           ├── 02.png
│   │           └── ...
│   └── es-ES/...
└── release-notes/
    ├── en-US/
    │   ├── internal.txt
    │   └── production.txt
    └── es-ES/...
```

Files are sorted by filename — name screenshots `01.png`, `02.png` for stable display order.

## Workflow examples

### Refresh release notes for a new version

1. Update `android/app/src/main/play/release-notes/<locale>/production.txt` with what's new (max 500 chars per locale).
2. Release notes are picked up automatically the next time `./gradlew :app:publishBundle --track=production` runs (CI or `/ship-android --rebuild-production`).

### Add a new locale

1. Copy `play/listings/en-US/` to `play/listings/<new-locale>/` (use a Play-supported locale code — see `android/docs/SUPPORTED_LOCALES.md` if present).
2. Translate `title.txt`, `short-description.txt`, `full-description.txt`.
3. Translate any release notes under `play/release-notes/<new-locale>/`.
4. `cd android && ./gradlew :app:publishListing` to push.

### Refresh from Play state (audit drift)

```bash
cd android
./gradlew :app:bootstrapListing --listings --release-notes
git diff app/src/main/play   # See what Play has that the repo doesn't
```

If the diff shows changes you didn't expect, someone edited the listing through the Play Console UI — decide whether to keep their edits (commit) or push your version back (`./gradlew :app:publishListing`).

## Notes

- `gradle-play-publisher` doesn't have a `--dry-run`. To test safely, push to internal-track only with `releaseStatus=DRAFT` (configured by default in `app/build.gradle.kts`) — drafts aren't visible.
- The plugin auto-disables (`enabled.set(false)`) when `play-key.json` is missing, so local debug builds work fine without credentials.
- For first-time publishes, the bundle must be uploaded **manually** through the Play Console UI before gradle-play-publisher can take over. Already done for SwiftBible (package `biz.am2.swiftbible`).
- Google Play has no equivalent of Apple's "submit for review" — uploading to a non-internal track *is* the submission. See `/ship-android` for the upload flow.
- The Play Store does not support `ml` (Malayalam) as a listing locale; reach Kerala users via `hi-IN` or `en-US`. (Same as the iOS App Store quirk.)
