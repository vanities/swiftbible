---
description: Bump SwiftBible's marketing version + build number on iOS and Android in lockstep. Default bumps both platforms; `--ios-only` / `--android-only` scopes to one. Use when shipping a release.
argument-hint: [<explicit-version> | --build | --major] [--ios-only | --android-only]
allowed-tools: Bash(grep:*) Bash(sed:*) Read Edit
---

# Bump SwiftBible app version (iOS + Android)

Updates marketing version and build number in **both** the iOS Xcode project and the Android Gradle build, keeping them in sync. iOS and Android share the same `versionName` (marketing) but each has its own build counter.

## Files this skill touches

| Platform | File | Marketing field | Build field |
|---|---|---|---|
| iOS | `ios/swiftbible.xcodeproj/project.pbxproj` | `MARKETING_VERSION` | `CURRENT_PROJECT_VERSION` |
| Android | `android/app/build.gradle.kts` | `versionName` | `versionCode` |

iOS fields appear 8 times each in pbxproj (one per build configuration × target) — always update with `replace_all`. Android fields appear once each.

`versionCode` cannot decrease — Google Play rejects uploads ≤ what's already on the track.

## Scope

- **No flag** (default): bump both platforms.
- **`--ios-only`**: only update the pbxproj.
- **`--android-only`**: only update the gradle file.

## Bump rules

These apply to whichever platform(s) are in scope:

### No arguments (default)

Bump marketing version by 0.01 (e.g. 1.40 → 1.41), increment build by 1.

### Explicit version (e.g. `1.50`, `2.0`)

Set marketing version to the value, increment build by 1.

### `--build`

Increment build only. Marketing version stays put. Use for resubmission of the same marketing version after a rejection.

### `--major`

Bump major (e.g. 1.40 → 2.0), increment build by 1.

## Workflow

1. Read both files' current values:
   ```bash
   grep -E "MARKETING_VERSION|CURRENT_PROJECT_VERSION" ios/swiftbible.xcodeproj/project.pbxproj | sort -u
   grep -E 'versionCode|versionName' android/app/build.gradle.kts
   ```
2. If the two platforms' marketing versions disagree, **stop and ask** which to use as the basis (or whether the user wants to resync them). Don't auto-pick.
3. For iOS pbxproj fields, verify `grep -c "MARKETING_VERSION = X.YY"` returns 8 (one per config × target). If not, stop and check.
4. Compute new values per the bump rules.
5. Apply edits:
   - iOS: `Edit` with `replace_all=true` for both fields.
   - Android: single `Edit` per field (each appears once).
6. Re-grep to verify. iOS fields should still be 8 each.
7. Report: `1.40 (iOS build 5, Android build 5) → 1.41 (iOS build 6, Android build 6)`.

## What this skill does NOT do

- Does not commit or push. Run `/ship` (iOS) and/or `/ship-android` afterward.
- Does not update App Store metadata, release notes, or `CHANGELOG.md`. Ask separately.
- Does not bump server-side versions (Edge Functions, migrations).

## Examples

```text
/bump-version                       # both: 1.40(5/5) → 1.41(6/6)
/bump-version 1.50                  # both: 1.40(5/5) → 1.50(6/6)
/bump-version --build               # both: 1.40(5/5) → 1.40(6/6)
/bump-version --major               # both: 1.40(5/5) → 2.0(6/6)
/bump-version --ios-only            # only iOS:     1.40(5) → 1.41(6)
/bump-version 1.50 --android-only   # only Android: 1.40(5) → 1.50(6)
```

## Safety notes

- pbxproj is shared with Xcode and other Claude sessions. Before running, ensure no structural changes (file adds/removes) are pending.
- If iOS and Android marketing versions have diverged for legitimate reasons (rare), use the platform-scoped flags rather than the unified bump.
