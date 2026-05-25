---
description: Build the SwiftBible Android release AAB and upload it to Google Play. Defaults to the internal track. Use `--production` to promote the latest internal build to production with status COMPLETED (kicks off Google's automated review). Use when shipping an Android release locally.
argument-hint: [--internal | --beta | --production | --rebuild-production]
allowed-tools: Bash(test:*) Bash(git status:*) Bash(grep:*) Bash(./gradlew clean*) Bash(./gradlew :app:bundleRelease*) Bash(./gradlew :app:publishBundle*) Bash(./gradlew :app:promoteArtifact*)
---

# Ship SwiftBible Android

Builds a signed AAB and pushes it to Google Play via `gradle-play-publisher`. Mirrors the role of iOS `submit-version` but adapted to Play's deployment model (which has no separate "submit for review" — uploading to a production-grade track *is* the submission).

## Tracks

| Argument | Track | Status | Review? | Use when |
|---|---|---|---|---|
| (default) / `--internal` | `internal` | `completed` | No | Quick check by your testers list |
| `--beta` | `beta` | `completed` | Yes | Open beta channel (limited public) |
| `--production` | `production` | `completed` | Yes | Promote the existing internal build to prod |
| `--rebuild-production` | `production` | `completed` | Yes | Rebuild + push directly to prod (skip internal) |

`--production` uses `promoteArtifact` so it does **not** rebuild — it promotes the most recent internal release to production. Use `--rebuild-production` only when you skipped internal and want to ship straight to prod.

## Prerequisites

Before doing anything, this skill verifies:

| File | Purpose | How to obtain |
|---|---|---|
| `android/keystore.properties` | Signing config (passwords) | `android/scripts/generate_keystore.sh` |
| `android/release.keystore` | Signing key (gitignored) | Generated alongside `keystore.properties` |
| `android/play-key.json` | Service account credentials (gitignored) | Google Cloud Console — see `android/docs/PLAY_PUBLISHER_SETUP.md` |

If any are missing, stop and tell the user how to generate them — do not silently fall back to a debug build.

## Workflow

1. Check prereqs. If a file is missing, stop with a clear error.
2. `git status --porcelain` → if dirty, ask the user to commit or stash. A dirty tree makes the deployed bundle hard to trace back to a commit.
3. Read the current `versionCode` and `versionName` from `android/app/build.gradle.kts`. Confirm with the user before continuing if shipping to production.
4. Run the gradle command for the chosen track (commands below).
5. Report what was uploaded — including the versionCode and the track.

### Default / `--internal`

```bash
cd android && ./gradlew clean :app:bundleRelease
cd android && ./gradlew :app:publishBundle --track=internal --release-status=completed
```

The internal track is for testers added in Play Console. No review.

### `--beta`

```bash
cd android && ./gradlew clean :app:bundleRelease
cd android && ./gradlew :app:publishBundle --track=beta --release-status=completed
```

### `--production` (promote from internal)

```bash
cd android && ./gradlew :app:promoteArtifact --from-track=internal --promote-track=production --release-status=completed
```

This re-uses the AAB already on internal, so no rebuild and no signing. Triggers Google's automated review — typically completes within a few hours.

### `--rebuild-production` (build + push directly to prod)

```bash
cd android && ./gradlew clean :app:bundleRelease
cd android && ./gradlew :app:publishBundle --track=production --release-status=completed
```

Use only when you skipped internal entirely.

## Shipping via CI instead of locally

The `release-android.yml` workflow handles the same flow:

- **Push to master** with android changes → auto-publishes to `internal` (with `--release-status=completed`).
- **Manual**: `gh workflow run release-android.yml -f track=production` (or `track=beta`) to push the next build to a different track. Requires the version to have been bumped (CI skips if the tag `android-v<name>-<code>` already exists).

Use the local skill when you want to inspect the build first; use CI for routine pushes.

## What this skill does NOT do

- Does not bump version. Run `/bump-version --android-only` first if you need a new versionCode.
- Does not commit or tag (CI tagging happens in `release-android.yml` after a successful publish).
- Does not handle keystore setup. Run `android/scripts/generate_keystore.sh` separately.
- Does not push iOS. Use the iOS `app-store-listing` skill / `submit-version` flow.

## Notes

- `gradle-play-publisher` does not have a `--dry-run`. To preview without affecting Play, leave the `play{}` block in `app/build.gradle.kts` set to `track=internal` + `releaseStatus=DRAFT` (current default) and run `./gradlew :app:publishBundle` without overrides — drafts on internal aren't visible to anyone.
- Google Play does **not** require a separate "submit for review" step. Uploading to a production-grade track triggers review automatically.
- If the Play API rejects the bundle for `versionCode already exists`, run `/bump-version --android-only --build` and try again.
