---
description: End-to-end runbook for cutting a SwiftBible release on both iOS and Android — bump version, push, push localized release notes, build and submit iOS, promote Android to production. Orchestrates the atomic skills (bump-version, app-store-listing, ship-android) into one ordered flow.
argument-hint: [<explicit-version> | --build | --major]
allowed-tools: Bash Read Edit Write
---

# Cut a release (iOS + Android)

Orchestrates a full feature-set release across both stores. Use when shipping new functionality on both platforms with synced version numbers. For single-platform fixes, use `/bump-version --ios-only` (or `--android-only`) and the platform-specific ship skills directly.

## What this runbook does NOT replace

- `bump-version` — version edits in pbxproj + gradle
- `app-store-listing` — iOS listings.yaml + push + submit scripts
- `ship-android` — gradle-play-publisher tracks
- `play-store-listing` — Android Play console metadata

This runbook calls those in the right order with the right gotchas baked in.

## One-time gotchas (already fixed in repo, listed for reference)

| Symptom | Cause | Fix in repo |
|---|---|---|
| `xcodebuild: error: The -authenticationKeyPath flag must be an absolute path to an existing file` | Makefile referenced `$(APP_STORE_API_KEY)` which is empty unless caller exports it | `make upload` now sources `appstore/.env` and uses `$ASC_KEY_ID` / `$ASC_ISSUER_ID` directly |
| `rsync: --extended-attributes: unknown option` (during exportArchive) | Homebrew rsync 3.4+ on PATH; Xcode invokes it for IPA packaging | `make upload` prepends `/usr/bin` to PATH so Apple's rsync wins |
| `submit-version` succeeds but Apple shows "no build attached" | `submit_version.py` didn't attach builds | Script now auto-finds the latest VALID build for the version's marketing string and PATCHes the relationship before submitting |
| `make release` log says `Upload complete!` and `EXPORT SUCCEEDED`, but submit-version errors with `no VALID build found` | Apple's `/v1/builds` endpoint can lag the upload pipeline by 30-60+ min — sometimes the build is in the preReleaseVersions relation before it surfaces in the `/builds` index. Not a real failure | Wait it out. If still missing after an hour, query `GET /v1/preReleaseVersions?filter[app]=...&filter[version]=1.43&include=builds` directly — that endpoint surfaces in-flight builds earlier than `/builds` does |
| `warning: exportArchive Upload Symbols Failed. The archive did not include a dSYM for the Sentry.framework` | Sentry SDK frameworks ship without dSYMs in the xcarchive; Xcode's upload-symbols step can't ship them to Apple | Not fatal — upload still succeeds. But until Sentry's own dSYMs are uploaded via `sentry-cli upload-dif` against `build/swiftbible.xcarchive/dSYMs`, Sentry crash reports for this build won't symbolicate. TODO: add a sentry-cli step to `make release` after upload succeeds |

## Workflow

Every step assumes you're in the repo root.

### 1. Bump versions

```bash
/bump-version 1.42         # explicit, recommended for major feature releases
# or
/bump-version              # default: 0.01 bump on both platforms
```

The bump skill stops and asks if iOS/Android marketing versions disagree (they shouldn't unless you've been platform-bumping). Use a fresh version that's higher than both.

### 2. Commit + push

Single commit message, both platforms. Push triggers:
- `tag-ios-version.yml` → tags `v<marketing>-<build>` on master
- `release-android.yml` → uploads AAB to Play **internal** track via gradle-play-publisher

```bash
git add swiftbible.xcodeproj/project.pbxproj android/app/build.gradle.kts
git commit -m "Bump to <version> (iOS build N, Android build M)"
git push
```

### 3. Wait for CI

```bash
gh -R vanities/swiftbible run list --limit 3 --json status,conclusion,name
```

Both `Tag iOS Version` and `Release Android` should be `success`. The Android internal upload must finish before step 6.

### 4. Draft + push iOS what's-new across all locales

The hardest step. Edit `appstore/listings.yaml` — every locale has a `whats_new: |-` block; replace the previous release's content with the new version's notes. SwiftBible currently ships in 20 locales (en-US, es-ES/MX, pt-BR/PT, fr-FR, de-DE, it, nl-NL, pl, ru, ko, ja, zh-Hans/Hant, id, el, ro, tr, hi).

Then create the editable AppStoreVersion in ASC and push:

```bash
make create-version VERSION=1.42       # creates editable PREPARE_FOR_SUBMISSION version
make dry-listings                      # preview — should show 20 locales PATCH whatsNew
make push-listings                     # actual push
```

If a locale fails the 4000-char limit, the dry-run will tell you.

### 5. Write Android release notes

Single file in en-US:

```bash
mkdir -p android/app/src/main/play/release-notes/en-US
$EDITOR android/app/src/main/play/release-notes/en-US/default.txt   # 500-char Play limit
```

`default.txt` covers all tracks. Translate to additional locales at `release-notes/<locale>/default.txt` only if you've localized the rest of the Play listing for that locale.

### 6. Build + upload iOS

```bash
make release    # archive + exportArchive + upload to ASC
```

Takes ~5-15 min depending on machine. Watch for `** EXPORT SUCCEEDED **` and `Upload complete!`. The build then needs Apple-side processing before `make submit-version` can attach it — historically this was 1-5 min, but **has been observed to take up to ~1 hour** during busy Apple-side periods. The `/v1/builds` endpoint specifically can lag; `/v1/preReleaseVersions?include=builds` often surfaces the build earlier.

Expect a non-fatal warning at the end of upload:

```
warning: exportArchive Upload Symbols Failed. The archive did not include a dSYM for the Sentry.framework...
```

This doesn't block the build. It does mean Sentry crash reports for this build won't be symbolicated until `sentry-cli upload-dif build/swiftbible.xcarchive/dSYMs` is run separately. See the gotchas table; eventually fold this into `make release`.

### 7. Submit iOS for review

```bash
make submit-version DRY=1     # preview — shows the build it found, the attach, and the submit
make submit-version           # actual submit
```

`submit_version.py` now auto-attaches the latest VALID build for the version. If the build hasn't finished processing, it errors with "no VALID build found" — wait and retry. **Plan for ~30-60 min of Apple-side processing** on top of the upload time (the historical "1-5 min" estimate has not held lately). Any retry loop should cap at 60+ min, not under 10. To check progress without retrying the submit, hit `/v1/preReleaseVersions?filter[app]=$ASC_APP_ID&filter[version]=1.43&include=builds` directly — it surfaces in-flight builds earlier than `/v1/builds` does.

### 8. Promote Android internal → production

Once CI's internal upload from step 3 is done:

```bash
cd android && ./gradlew :app:promoteArtifact \
  --from-track=internal --promote-track=production --release-status=completed
```

(This is what `/ship-android --production` runs.) Triggers Google's automated review. Typically lands in a few hours.

### 9. Commit + push the release-notes files

Don't forget the `appstore/listings.yaml` and `android/app/src/main/play/release-notes/en-US/default.txt` edits — commit them after the release is submitted. Push will retrigger `release-android.yml` but it'll be a no-op since versionCode already exists on internal.

```bash
git add appstore/listings.yaml android/app/src/main/play/release-notes/
git commit -m "<version> release notes: <one-line summary of new features>"
git push
```

## What's-new drafting source

Use `git log <last-release-tag>..HEAD` to find user-facing changes. iOS-tagged commits (`iOS:` prefix) and Android-tagged commits (`Android:` prefix) help separate platform-specific notes. Server-side daily-devotional changes affect both platforms but are usually too granular for store copy — collapse to "Daily devotional improvements."

## Troubleshooting

- **"versionCode already exists" on Android push** — push retrigger is a no-op (CI already uploaded). Skip step 3's wait if you've already promoted.
- **iOS submit says "no editable AppStoreVersion"** — run `make create-version VERSION=<x>` first.
- **Apple rejects what's-new for length** — limit is 4000 chars per locale; dry-listings catches this.
- **Apple rejects the build** — the rejection email/notification has details. After fixing, `/bump-version --build` (build-only bump) and re-run from step 6.
- **You skipped step 5 (Android release notes)** — the new build inherits the prior release's notes. Add the file and push; gradle-play-publisher will pick it up on the next promotion or rebuild.

## Quick reference (happy path)

```bash
/bump-version 1.42
git add swiftbible.xcodeproj/project.pbxproj android/app/build.gradle.kts
git commit -m "Bump to 1.42 (iOS build N, Android build M)"
git push
# wait for CI
$EDITOR appstore/listings.yaml                                          # 20 whats_new blocks
make create-version VERSION=1.42 && make dry-listings && make push-listings
mkdir -p android/app/src/main/play/release-notes/en-US
$EDITOR android/app/src/main/play/release-notes/en-US/default.txt
make release
make submit-version DRY=1 && make submit-version
cd android && ./gradlew :app:promoteArtifact \
  --from-track=internal --promote-track=production --release-status=completed
cd ..
git add appstore/listings.yaml android/app/src/main/play/release-notes/
git commit -m "1.42 release notes: <summary>"
git push
```
