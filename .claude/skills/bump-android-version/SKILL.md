---
description: Bump the SwiftBible Android app version (versionCode + versionName) in android/app/build.gradle.kts. Use when shipping a release. Default bumps versionName by 0.01 and increments versionCode; accepts an explicit version like `1.40` or `--build` for build-number-only.
disable-model-invocation: true
argument-hint: [<explicit-version> | --build | --major]
allowed-tools: Bash(grep:*) Bash(sed:*) Read Edit
---

# Bump SwiftBible Android app version

This skill updates the Android app version in `android/app/build.gradle.kts`. Mirrors the iOS `bump-version` skill.

**Two version fields, both in `android/app/build.gradle.kts`:**

| Field | Format | Purpose | Play-facing |
|-------|--------|---------|-------------|
| `versionName` | `X.YY` (e.g. `1.40`) | Public/Play-Store-visible version | Yes |
| `versionCode` | integer (e.g. `1`, `2`) | Build counter; must increment monotonically per upload | Yes |

`versionCode` cannot decrease — Google Play rejects an upload with a versionCode less than or equal to anything already on the track.

## Behavior by argument

### No arguments (default)

Bump `versionName` by 0.01 (e.g. 1.40 → 1.41) and increment `versionCode` by 1 (e.g. 5 → 6). Matches the convention of recent SwiftBible iOS releases.

### Explicit version (e.g. `1.40`, `2.0`)

Set `versionName` to the provided value. Increment `versionCode` by 1.

### `--build`

Only increment `versionCode`. `versionName` stays put. Useful for re-uploading the same marketing version after a rejected submission.

### `--major`

Bump `versionName` major (e.g. 1.40 → 2.0). Increment `versionCode` by 1.

## Workflow

1. Read current values:
   ```bash
   grep -E 'versionCode|versionName' android/app/build.gradle.kts
   ```
2. Compute the new values per the argument rules above.
3. Apply both updates via `Edit` against `android/app/build.gradle.kts`. Each field appears once — straight string replacement.
4. Re-grep to verify.
5. Report the bump as `1.40 (build 5) → 1.41 (build 6)`.

## What this skill does NOT do

- Does not commit or push. The user runs `/ship-android` (or commits manually) afterward.
- Does not touch any other field in `build.gradle.kts`.
- Does not bump iOS versions. Use `/bump-version` for that.
- Does not bump server-side versions (Edge Functions, migrations).

## Examples

```text
/bump-android-version              # 1.40 (5) → 1.41 (6)
/bump-android-version 1.50         # 1.40 (5) → 1.50 (6)
/bump-android-version --build      # 1.40 (5) → 1.40 (6)
/bump-android-version --major      # 1.40 (5) → 2.0  (6)
```
