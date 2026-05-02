---
description: Bump the SwiftBible iOS app version (MARKETING_VERSION + CURRENT_PROJECT_VERSION) in swiftbible.xcodeproj/project.pbxproj. Use when shipping a release. Default bumps the marketing version by 0.01 and increments the build number; accepts an explicit version like `1.40` or `--build` for build-number-only.
disable-model-invocation: true
argument-hint: [<explicit-version> | --build | --major]
allowed-tools: Bash(grep:*) Bash(sed:*) Read Edit
---

# Bump SwiftBible app version

This skill updates the iOS app version in the Xcode project file.

**Two version fields, both in `swiftbible.xcodeproj/project.pbxproj`:**

| Field | Format | Purpose | Apple-facing |
|-------|--------|---------|--------------|
| `MARKETING_VERSION` | `X.YY` (e.g. `1.36`) | Public/App-Store-visible version | Yes — `CFBundleShortVersionString` |
| `CURRENT_PROJECT_VERSION` | integer (e.g. `1`, `2`) | Build number; must increment per App Store submission | Yes — `CFBundleVersion` |

Both fields appear 8 times in the pbxproj (one per build configuration × target). Always update with `replace_all` to keep all targets in sync — never edit just one occurrence.

## Behavior by argument

### No arguments (default)

Bump `MARKETING_VERSION` by 0.01 (e.g. 1.36 → 1.37) and increment `CURRENT_PROJECT_VERSION` by 1 (e.g. 1 → 2). This matches the convention of recent SwiftBible releases.

### Explicit version (e.g. `1.40`, `2.0`)

Set `MARKETING_VERSION` to the provided value. Increment `CURRENT_PROJECT_VERSION` by 1.

### `--build`

Only increment `CURRENT_PROJECT_VERSION`. `MARKETING_VERSION` stays put. Useful for re-submission of the same marketing version (e.g. after a TestFlight rejection).

### `--major`

Bump `MARKETING_VERSION` by 1 and reset the second decimal to 0 (e.g. 1.36 → 2.0). Increment `CURRENT_PROJECT_VERSION` by 1.

## Workflow

1. Read current values from the pbxproj:
   ```bash
   grep -E "MARKETING_VERSION|CURRENT_PROJECT_VERSION" swiftbible.xcodeproj/project.pbxproj | sort -u
   ```
2. Verify each field appears 8 times (one per config × target). If counts diverge, stop and ask — non-uniform version state may need manual triage.
3. Compute the new values per the argument rules above.
4. Apply both updates via `Edit` with `replace_all=true`.
5. Re-grep to verify. The output of step 1 should show the new values, still 8 each.
6. Report the bump in the form `1.36 (build 1) → 1.37 (build 2)`.

## What this skill does NOT do

- Does not touch any other field in the pbxproj.
- Does not commit or push. The user runs `/ship` (or commits manually) afterward.
- Does not update `CHANGELOG.md`, App Store metadata, release notes, or other markdown docs. If the user wants release notes, they should ask separately.
- Does not bump server-side versions (Edge Functions, migrations). Those have their own deploy cadence.

## Examples

```text
/bump-version                # 1.36 (build 1) → 1.37 (build 2)
/bump-version 1.40           # 1.36 (build 1) → 1.40 (build 2)
/bump-version --build        # 1.36 (build 1) → 1.36 (build 2)
/bump-version --major        # 1.36 (build 1) → 2.0  (build 2)
```

## Safety notes

- `swiftbible.xcodeproj/project.pbxproj` is also occasionally edited by other Claude sessions or by Xcode itself when files are added/removed. Before running this skill, ensure no in-progress structural changes are pending. The skill operates only on the version fields, but the file is shared.
- If `grep -c "MARKETING_VERSION = X.YY"` returns a number other than 8 before bumping, do not proceed without checking with the user.
