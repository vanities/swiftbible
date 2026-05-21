---
description: Inspect, migrate, and deploy SwiftBible's CloudKit schema with cktool. SwiftBible's SwiftData store is CloudKit-backed (iCloud entitlement → automatic CloudKit), so adding/changing an @Model is a CloudKit schema migration. Use to verify which record types are live in production, diff development vs production, deploy schema changes (dev → prod), or troubleshoot why synced data (reading stats, highlights, notes, devotionals, badges) isn't appearing on other devices / after reinstall. Auth uses ICLOUD_MANAGEMENT_TOKEN from the repo-root .env.
allowed-tools:
  - Bash(.claude/skills/cloudkit-schema/cktool.sh verify*)
  - Bash(.claude/skills/cloudkit-schema/cktool.sh export*)
  - Bash(.claude/skills/cloudkit-schema/cktool.sh diff*)
  - Bash(.claude/skills/cloudkit-schema/cktool.sh validate*)
  - Bash(xcrun cktool export-schema*)
  - Bash(xcrun cktool validate-schema*)
  - Bash(xcrun cktool get-teams*)
---

# CloudKit Schema Migration (SwiftBible)

SwiftBible's SwiftData store is **CloudKit-backed**. `swiftbibleApp.swift` uses a
plain `.modelContainer(for:)`, but the iCloud entitlement
(`swiftbible.entitlements`, container `iCloud.swiftbible`) makes SwiftData default
`cloudKitDatabase` to `.automatic` → CloudKit is on. Every `@Model` becomes a
`CD_<EntityName>` record type with `CD_<attr>` fields. So **changing the data model
is a CloudKit schema migration**, and that schema has separate **Development** and
**Production** environments.

| Fact | Value |
|---|---|
| Container | `iCloud.swiftbible` |
| Team ID | `8Q3RG3ULSU` |
| Management token | `ICLOUD_MANAGEMENT_TOKEN` in repo-root `.env` (gitignored) |
| Record types | `CD_ReadingSession`, `CD_EarnedBadge`, `CD_HighlightedVerse`, `CD_Note`, `CD_SavedDevotional`, `CD_LocalDonationRecord` |

## Helper

`.claude/skills/cloudkit-schema/cktool.sh` loads the token from `.env` and wraps `xcrun cktool`:

```bash
S=.claude/skills/cloudkit-schema/cktool.sh
$S verify production        # are all expected CD_* types live in prod? (exit≠0 if any missing)
$S verify development
$S diff                     # record types in development not yet promoted to production
$S export production [out]  # dump full schema (stdout, or to a .ckdb file)
$S validate <env> <file>    # validate a schema file before importing
$S import   <env> <file>    # IMPORT a schema (mutates the container — see warnings)
```

## The golden rule (why a new model "doesn't sync")

**CloudKit only creates a record type in the *Development* schema when the first
record of that type actually syncs.** Adding a new `@Model` is not enough — until
the app (a *development* build, signed into iCloud, online) saves and syncs a
record of that type, the type does not exist in the schema, so it can't be
deployed to production, so production devices can't sync it.

This is exactly how `CD_EarnedBadge` got left out of a deploy: the dev run created
a `ReadingSession` but never earned a badge, so only `CD_ReadingSession` made it
into the schema.

## Workflow A — deploy a model change (the safe, model-correct path)

1. **Populate Development.** Run the app from Xcode (Run, dev build) on a
   simulator/device **signed into iCloud**, and **exercise every new/changed
   model** so at least one record of each type syncs (e.g. read a chapter →
   `ReadingSession`; earn a badge → `EarnedBadge`; add a highlight/note).
2. **Confirm the type landed in dev:** `cktool.sh verify development` (and/or `cktool.sh diff`).
3. **Promote dev → production:** CloudKit Console (icloud.developer.apple.com/dashboard)
   → container `iCloud.swiftbible` → **Schema → Deploy Schema Changes…** →
   Development → **Production** → Deploy. (This is the only "promote" path; cktool
   has no promote command.)
4. **Verify production:** `cktool.sh verify production` — every expected `CD_*` type should print `OK`.

Production schema is **read-only at runtime** — App Store / TestFlight builds
cannot create record types, they can only use what's been deployed. That's why
the deploy is mandatory for sync to work for real users; local persistence works
regardless.

## Workflow B — seed a missing type via cktool (when no signed-in dev build is handy)

`cktool` can only write the **Development** schema. `validate`/`import` against
`production` fail with `endpoint not applicable in the environment 'production'`,
and there is **no promote/deploy command** — production is changed *only* by the
Console deploy in Workflow A. So Workflow B just replaces **step 1** of Workflow A:
it seeds Development without needing a record to sync (handy when no device/sim is
signed into iCloud). You still finish with the Console deploy.

```bash
S=.claude/skills/cloudkit-schema/cktool.sh
$S export development dev.ckdb
# edit dev.ckdb: insert a RECORD TYPE CD_<Entity> block after "DEFINE SCHEMA",
# mirroring an existing CD_* type exactly — CD_<attr> fields + CD_entityName +
# the six "___*" system fields + the three GRANT lines.
$S validate development dev.ckdb     # must print "Schema is valid."
$S import   development dev.ckdb     # additive — existing types are preserved
$S verify   development              # confirm the new type is present
```

Field mapping: `String→STRING`, `Int→INT64`, `Double→DOUBLE`, `Bool→INT64`,
`Date→TIMESTAMP`; every `CD_*` type also has `CD_entityName STRING`.

**Then deploy dev → production** via the Console (Workflow A, step 3) — that is the
only way to change production. `verify production` should then go green.

## NEVER add a unique constraint

CloudKit forbids unique constraints. An `@Attribute(.unique)` on any `@Model` makes
the **entire store fail to load** (`NSCocoaError 134060`) and silently breaks ALL
local persistence — no crash, just nothing saves. Enforce uniqueness in code
(fetch-then-skip, like `BadgeService.checkBadges`). This shipped once on
`EarnedBadge.badgeId` and was the real cause of "0 reading progress." Keep all
model properties optional or defaulted (also a CloudKit requirement).

## Token setup

If `ICLOUD_MANAGEMENT_TOKEN` is missing/expired: CloudKit Console → **Settings →
Tokens → CloudKit Management Token** (or `xcrun cktool save-token --type management`,
which opens a browser login), then put it in the repo-root `.env` as
`ICLOUD_MANAGEMENT_TOKEN=...`. It's distinct from the App Store Connect API key
(`appstore/.env`) — that one can't touch CloudKit.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `No management token found` | Token missing/expired in `.env` — see Token setup. |
| Data syncs on one device but not a fresh install | The record type isn't in **production** — run `verify production`, then deploy (Workflow A). |
| `verify` shows a `CD_*` type MISSING | That model's first record never synced in dev (golden rule) — exercise it in a dev build, then deploy. |
| Sync silently does nothing in a TestFlight/App Store build | Production schema not deployed, or device not signed into iCloud. |
| Whole store won't persist anything | Check for a `@Attribute(.unique)` that slipped into a model (134060). |
| `endpoint not applicable in the environment 'production'` | `cktool` can't write production. Seed Development (Workflow B), then deploy dev→prod in the Console. |
