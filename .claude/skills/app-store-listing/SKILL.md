---
description: SwiftBible's App Store Connect listing automation — push localized name, subtitle, keywords, description, promo text, what's new, and screenshots across 20+ locales without Fastlane, AND submit the version for Apple review. Use when the user wants to update App Store listings, add what's new for a new release, refresh promotional text, add a new locale, translate version notes across all locales, pull current ASC state, push localized screenshots, submit the current version for review, or troubleshoot the push_listing.py / push_screenshots.py / submit_version.py workflow.
allowed-tools:
  - Bash(uv run python appstore/push_listing.py --dry-run*)
  - Bash(uv run python appstore/push_listing.py --pull*)
  - Bash(uv run python appstore/push_screenshots.py --pull*)
  - Bash(uv run python appstore/push_screenshots.py *--dry-run*)
  - Bash(uv run python appstore/submit_version.py --dry-run*)
  - Bash(make pull-listings*)
  - Bash(make dry-listings*)
  - Bash(make pull-screenshots*)
  - Bash(make dry-screenshots*)
---

# App Store Listing Automation

Automation for pushing localized App Store metadata (name / subtitle / keywords / description / promo text / what's new) across 20+ locales via the App Store Connect API. No Fastlane required.

## Files

| File | Purpose |
|---|---|
| `appstore/push_listing.py` | Metadata script — auths to ASC, pulls or pushes localizations |
| `appstore/push_screenshots.py` | Screenshot upload script — three-step asset upload |
| `appstore/submit_version.py` | App-version submission — wraps the `reviewSubmissions` flow to transition the editable AppStoreVersion → READY_FOR_REVIEW |
| `appstore/listings.yaml` | Source of truth for metadata (committed) |
| `appstore/listings.pulled.yaml` | Output of `--pull` for diffing (gitignored) |
| `appstore/marketing/<set>/<device>/*.png` | Source screenshots (e.g. `marketing/ultimate/iphone-6.9/`) |
| `appstore/.env` | Credentials (gitignored). See `.env.example` |
| `appstore/listing-requirements.txt` | Python deps (PyJWT, requests, python-dotenv, PyYAML) |
| `Makefile` (`*-listings`, `*-screenshots`, `submit-version` targets) | One-liner wrappers |

## Quick command reference

### Metadata (name, subtitle, keywords, descriptions, what's new)

```bash
make pull-listings                # Download current ASC state → listings.pulled.yaml
make dry-listings                 # Preview what would change
make push-listings                # Push everything in listings.yaml
make push-listing LOCALES=ml,hi   # Push specific locales
```

### Screenshots

```bash
make pull-screenshots                                          # List current screenshots in ASC for en-US
make pull-screenshots LOCALE=es-ES                             # ...or a specific locale
make dry-screenshots                                           # Preview upload from appstore/marketing/ultimate
make push-screenshots                                          # Upload to en-US (skips existing sets)
make push-screenshots SOURCE=appstore/marketing/ultimate FORCE=1   # Replace existing
make push-screenshots SOURCE=appstore/marketing/es-ES LOCALE=es-ES # Localized push
```

Source directory layout the script expects:
```
<source>/iphone-6.9/01_*.png         → uploaded as APP_IPHONE_69
<source>/ipad-13/01_*.png            → uploaded as APP_IPAD_PRO_3GEN_129
<source>/iphone-6.5/01_*.png         → uploaded as APP_IPHONE_65   (optional)
<source>/watch-46mm/01_*.png         → uploaded as APP_WATCH_SERIES_10 (optional)
```
Files are sorted by filename — name them `01_*.png`, `02_*.png` etc. for stable display order.

### Submit the current app version for review

```bash
make submit-version DRY=1                                      # Preview the reviewSubmission flow
make submit-version                                            # Actually submit (DRAFT → READY_FOR_REVIEW)
```

### Direct invocation (no Make)

```bash
uv run python appstore/push_listing.py --pull
uv run python appstore/push_screenshots.py --pull
uv run python appstore/push_screenshots.py --source appstore/marketing/ultimate --force
uv run python appstore/submit_version.py --dry-run
```

## When to push

| Lifecycle moment | What to update | Submission needed? |
|---|---|---|
| New version cut in Xcode | `whats_new` per locale (always); optionally `description`/`keywords`/`name`/`subtitle` | Yes (the version) |
| Mid-version refresh | `promo_text` only — Apple lets you edit it live | **No** |
| Adding a new locale | New top-level entry in `listings.yaml` | Yes |
| Marketing campaign | `promo_text` (e.g. "Now in Portuguese!") | No |

Default workflow: always `make dry-listings` before `make push-listings`. Catches over-limit fields and shows what will change.

## Workflow: update "what's new" for a new release

The most common operation. When you ship a new version:

1. Confirm an editable App Store version exists in App Store Connect (state `PREPARE_FOR_SUBMISSION`).
2. **Draft the English what's new from git commits** since the last version bump:
   ```bash
   # Find the last version-bump commit (preceding the current one)
   git log --oneline | grep -i "bump version" | head -2
   # Then read the commits between them
   git log <prev-version-bump>..HEAD --pretty=format:"%s%n%b" -- . ':(exclude)appstore' ':(exclude)*.png'
   ```
   Read those commits, and draft a short, user-facing what's new (one or two sentences, or a tiny bullet list). **Always confirm with the user before treating the draft as final** — commit messages are developer-facing, not marketing copy. The user may want a casual one-liner ("new marketing stuff, fix some dark mode issues") rather than a structured list.
3. Save the agreed English text to `appstore/APP_STORE_WHATS_NEW.txt` AND to the en-US `whats_new:` field in `appstore/listings.yaml`.
4. Translate to all locales in `appstore/listings.yaml`. **Claude can do this directly** — open the YAML, replace each locale's `whats_new:` block with a localized version. Match the user's chosen tone (casual short blurb stays casual; structured list stays structured). Don't translate trademarked/iOS-specific terms (`VoiceOver`, `Dynamic Type`, `Cmd+1-4`, `Apple Intelligence`).
5. Run `make dry-listings` and verify all locales appear with `whats_new` in the PATCH list.
6. `make push-listings`.

Don't recycle last release's notes — Apple uses freshness as a signal, and a stale "what's new" hurts conversion.

### Heuristic: what's the right tone for this app's notes?

Check the previous release's `whats_new` value via `make pull-listings`. If it was a structured bullet list (Accessibility / Siri sections), match that. If it was a casual one-liner, match that. Don't change tone between releases — it looks unprofessional.

## Workflow: add a new locale

1. Pick the locale code from Apple's supported list (e.g. `tagalog` doesn't have an iOS App Store locale — use `en` fallback; `tl` is not supported as of 2025).
2. Add a new top-level entry to `appstore/listings.yaml`. Required minimum:
   - `name` (≤30, lead with primary keyword in target language)
   - `subtitle` (≤30, secondary keywords)
   - `keywords` (≤100, comma-separated, no spaces)
   - `promo_text` (≤170)
   - `description` (≤4000)
   - `whats_new` (≤4000)
3. For keyword research:
   - Identify the language's most-searched Bible-related term (don't auto-translate from English; native search behavior differs)
   - Pull `/aso` for the deeper ASO playbook on locale keyword strategy
4. Run `make dry-listings --locales <new-locale>` to preview.
5. Push: `make push-listing LOCALES=<new-locale>`.

If Apple rejects the locale code (not in their supported list for this app), the script surfaces the API error and skips it — other locales still push.

## Workflow: upload screenshots

1. Generate screenshots into `appstore/marketing/<set>/<device>/01_*.png` etc. The "set" is just a folder name — `ultimate` is the current WIP base set.
2. List what's already in ASC: `make pull-screenshots`.
3. Preview the upload: `make dry-screenshots SOURCE=appstore/marketing/ultimate`.
4. Push:
   - First time for a device size: `make push-screenshots` creates the set and uploads.
   - Replacing an existing set: `make push-screenshots FORCE=1` deletes existing then uploads.
5. For localized screenshots (later): regenerate with locale-specific captions into `appstore/marketing/<locale>/{iphone-6.9,ipad-13}/...`, then `make push-screenshots SOURCE=... LOCALE=<code>`.

Apple auto-falls back to en-US screenshots for any locale without its own — so en-US first is the right order.

### Three-step upload protocol (informational)

The script handles this automatically. For debugging:
1. POST `/v1/appScreenshots` to reserve the asset (returns `uploadOperations` with signed URLs)
2. PUT each chunk to its signed URL — DO NOT include the bearer token in those requests
3. PATCH `/v1/appScreenshots/{id}` with `uploaded: true` and the MD5 checksum to commit

If a script run dies between step 1 and step 3, the screenshot may be left in a half-uploaded state. Apple cleans these up eventually; you can also `--force` to delete and re-upload.

## Workflow: submit the current version for review

When everything is staged (metadata, screenshots, build attached), submit via the API:

```bash
make submit-version DRY=1   # preview
make submit-version         # actually submit
```

The script wraps Apple's review submission flow:
1. Finds the editable AppStoreVersion
2. Creates a `reviewSubmission` (or reuses an in-progress one)
3. Adds the version as an item
4. Sets `submitted: true` — this triggers Apple's review queue

Apple typically reviews in 24-48h. Track status at App Store Connect → SwiftBible → App Store → version → Submission Status.

### Pre-submission checklist (the script doesn't validate these — Apple will reject if missing)

- [ ] Build uploaded and selected for the version (via Xcode `make release` or Transporter)
- [ ] All required device size screenshots present (at least 6.9" iPhone + 13" iPad)
- [ ] Privacy policy URL set in every locale (use `make push-listings` after editing `listings.yaml`)
- [ ] Age rating questionnaire completed
- [ ] Pricing & availability set
- [ ] App Review notes (if any features need explanation)
- [ ] Encryption / export compliance set in `Info.plist` (`ITSAppUsesNonExemptEncryption`)

If the submission errors with `Cannot create review submission`, one of those is missing. The error message usually points at the field.

## Workflow: refresh promo text without resubmitting

Promo text (170 chars, top of description) is the only field you can change without a new App Store version. Useful for:
- Time-bounded announcements ("Easter Reading Plan now live!")
- Localization milestones ("Available in Malayalam!")
- New feature teases between releases

1. Edit each locale's `promo_text:` line in `listings.yaml`.
2. `make dry-listings`.
3. `make push-listings`.

The push lands within minutes; no Apple review wait.

## Field rules (must follow or Apple rejects)

| Field | Limit | Indexed for search? | Notes |
|---|---|---|---|
| `name` | 30 | **Yes** | Lead with primary keyword, brand second |
| `subtitle` | 30 | **Yes** | Secondary keywords, NO overlap with name |
| `keywords` | 100 | **Yes** | Comma-separated, NO spaces around commas, no overlap with name/subtitle, no plurals if singular used, no competitor names |
| `promo_text` | 170 | No | Conversion copy only |
| `description` | 4000 | No | Conversion copy only |
| `whats_new` | 4000 | No | Per-version |

**Screenshot captions are also indexed** since June 2025 (OCR). When updating localized screenshots, treat their text as additional keyword surface — see `/aso` for details.

## Common errors → fixes

| Error | Fix |
|---|---|
| `no editable AppStoreVersion found` | Create a new version in App Store Connect (Distribution → App Store → "+" version) |
| `PARAMETER_ERROR.INVALID locale` | Locale code not supported by Apple for this app. Remove from `listings.yaml` or use a fallback. |
| `PARAMETER_ERROR.LENGTH_EXCEEDED` | Field over its char limit. Re-run `make dry-listings` — script warns before push. |
| `JWT expired` | Tokens last 20 min. Just re-run; the script generates a fresh token each invocation. |
| `403 FORBIDDEN_KEY_INVALID` | Check `appstore/.env`: `ASC_KEY_ID` matches the .p8 filename, `ASC_ISSUER_ID` is the team UUID. |
| `key file not found` | `ASC_KEY_FILE` path in `.env` is wrong. Path is relative to repo root. |

## Translating what's new — guidance for Claude

When the user says "translate what's new" or "update version notes":

1. Read the new English text from `appstore/APP_STORE_WHATS_NEW.txt` (or ask the user for it).
2. Open `appstore/listings.yaml` and update each locale's `whats_new:` block.
3. Translate idiomatically, not literally:
   - Match each locale's tech vocabulary (VoiceOver stays VoiceOver, but "Dynamic Type" can be translated where the locale convention does so).
   - Preserve section headers and bullet structure for scannability.
   - Keep "Cmd+1-4", `Apple Intelligence`, `Siri`, `Shortcuts`/`Atajos`/`Kurzbefehle` consistent with the locale's macOS / iOS UI conventions.
4. After updating: run `make dry-listings` and confirm each locale shows `whats_new` in its PATCH list.
5. Don't push without explicit user confirmation.

## Credentials reference

The script reads credentials from `appstore/.env` (gitignored). The repo also has `APP_STORE_API_KEY` / `APP_STORE_API_ISSUER` shell env vars used by the existing `make upload` target — they should match the `.env` values, but the listing script reads from `.env` only.

```
ASC_KEY_ID=<10-char ID>             # matches AuthKey_<ID>.p8 filename
ASC_ISSUER_ID=<team UUID>           # ASC → Users and Access → Integrations → Keys
ASC_APP_ID=6670373108               # SwiftBible's App Store Apple ID
ASC_KEY_FILE=AuthKey_<ID>.p8        # path relative to repo root
```

The `.p8` lives at the repo root (gitignored via `*.p8`). Apple's centralized location `~/.appstoreconnect/private_keys/AuthKey_*.p8` (used by `make upload`) is a different copy of the same key; either works but `.env` references the repo-local copy.

## Related

- `/aso` — full ASO playbook (keyword strategy, screenshots/OCR, In-App Events, CPPs, ratings)
- `/app-store-events` — adjacent skill for In-App Events (Pentecost, Advent, Lent, etc.)
- `appstore/README.md` — extended setup docs and screenshot pipeline
- `appstore/EVENTS.md` — 12-month event calendar
- `CLAUDE.md` — repo overview and deployment policy

## Don't

- Don't push without dry-running first.
- Don't push when Apple is reviewing the version (state `IN_REVIEW`) — your edits will cancel the review and require resubmission.
- Don't put keywords in `promo_text` or `description` — they're not indexed. Conversion-only.
- Don't translate the `keywords` field literally between languages — what people search for differs per locale. Native input or locale-specific Apple Search Ads research wins.
