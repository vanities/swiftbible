---
description: SwiftBible's full In-App Event pipeline — App Store Connect (push event metadata, upload images, submit for review) AND the iOS app side (asset catalog banner, AppEventRegistry entry, day-by-day reading plan content, EventDetailView). Use when shipping a new IAE end-to-end (Pentecost, Advent, Lent, Easter, etc.), drafting localized event copy, authoring reading-plan content, or troubleshooting any layer of the events pipeline.
allowed-tools:
  - Bash(uv run python appstore/push_event.py --pull*)
  - Bash(uv run python appstore/push_event.py *--dry-run*)
  - Bash(make pull-events*)
---

# In-App Events — End-to-End Shipping Guide

Ship an App Store In-App Event (IAE) for SwiftBible. **Two coupled sides** — App Store Connect (what users see in search/browse) AND the iOS app (the curated reading-plan view that opens when they tap the IAE).

Both sides are needed for a complete event. Don't ship one without the other.

## Files & components

### App Store Connect side (`appstore/`)

| File | Purpose |
|---|---|
| `appstore/push_event.py` | Script: create/update/submit events + upload images |
| `appstore/submit_version.py` | Sibling script for version submission |
| `appstore/events/<slug>/event.yaml` | Per-event definition (metadata + localized copy) |
| `appstore/events/<slug>/<slug>_event.png` | EVENT_CARD image, **1920×1080** landscape |
| `appstore/events/<slug>/<slug>_event_details.png` | EVENT_DETAILS_PAGE image, **1080×1920** portrait |
| `appstore/events/<slug>/SETUP.md` | Per-event setup notes (deep link, devotional content, etc.) |
| `appstore/EVENTS.md` | 12-month rolling calendar with submit-by dates per event |
| `appstore/.env` | Credentials (shared with push_listing.py) |

### iOS app side (`swiftbible/`)

| File | Purpose |
|---|---|
| `swiftbible/Models/AppEvent.swift` | `AppEventRegistry` — register events here so they appear in MoreView during their window |
| `swiftbible/Views/More/EventDetailView.swift` | The curated event view (TabView day pagination, locked future days, "Read in Bible" CTA) — generic; works for any event with a `readingPlan` |
| `swiftbible/Views/More/MoreView.swift` | Renders the "HAPPENING NOW" event card with optional banner image |
| `swiftbible/Views/ContentView.swift` | URL scheme handler — `swiftbible://event/<slug>` auto-routes to any event in the registry |
| `swiftbible/Views/Settings/SettingsView.swift` | Debug section: `Force-Show Events` toggle + "Open <event> Event View" buttons |
| `swiftbible/Assets.xcassets/<EventName>EventBanner.imageset/` | Asset catalog imageset for the MoreView card banner (same image as EVENT_CARD) |

## Quick command reference

```bash
make pull-events                       # list existing events in ASC
make push-event EVENT=pentecost DRY=1  # preview create/update
make push-event EVENT=pentecost        # actually push (creates DRAFT)
make push-event EVENT=pentecost REPLACE_IMAGES=1   # delete + re-upload images
make submit-event EVENT=pentecost      # push + submit for Apple review

uv run python appstore/push_event.py --pull
```

## End-to-end workflow: ship a new event

### 1. Plan from `appstore/EVENTS.md`
Pick the next event. The calendar tells you submit-by date, locale targeting, and copy hooks.

### 2. Generate the two event images
Use the GPT Image 2 prompt pattern (see project memory `feedback_event_image_workflow.md`). Always append:

```
This is for my SwiftBible Bible app: https://github.com/vanities/swiftbible
```

Required dimensions:
- **EVENT_CARD**: at least 1920×1080 (landscape) — what shows on product page + browse
- **EVENT_DETAILS_PAGE**: at least 1080×1920 (portrait) — shown on event detail page when tapped

GPT Image 2 outputs at 1024² or 1792×1024. Resize to exact dimensions:

```bash
sips -z 1080 1920 ~/Pictures/EVENT_CARD_landscape.png \
  --out appstore/events/<slug>/<slug>_event.png
sips -z 1920 1080 ~/Pictures/EVENT_DETAILS_PAGE_portrait.png \
  --out appstore/events/<slug>/<slug>_event_details.png
```

(`sips -z H W` — height first, then width.)

### 3. Author `event.yaml`
Use `appstore/events/pentecost/event.yaml` as the template. Field limits: name 30, short 50, long 120 (per locale). Schedule timestamps need full ISO 8601 with seconds.

**Deep link** must use the format the iOS handler understands:
- ✓ `swiftbible://event/<slug>` (routes to EventDetailView via the URL handler)
- ✓ `swiftbible://verse?book=Acts&chapter=2&verse=1` (legacy verse handler — query string, NOT path)

### 4. Add the banner to the iOS asset catalog

```bash
mkdir -p swiftbible/Assets.xcassets/<EventName>EventBanner.imageset
cp appstore/events/<slug>/<slug>_event.png \
   swiftbible/Assets.xcassets/<EventName>EventBanner.imageset/<slug>_event.png
cat > swiftbible/Assets.xcassets/<EventName>EventBanner.imageset/Contents.json <<'EOF'
{
  "images" : [
    { "filename" : "<slug>_event.png", "idiom" : "universal" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
EOF
```

Xcode auto-discovers `.imageset` folders inside `Assets.xcassets` — no `.pbxproj` edit required. Naming convention: `<EventName>EventBanner` (e.g., `PentecostEventBanner`, `AdventEventBanner`).

### 5. Add the AppEvent registry entry

In `swiftbible/Models/AppEvent.swift`, add to `AppEventRegistry.allEvents`:

```swift
static let advent2026 = AppEvent(
    id: "advent-2026",                 // matches deep_link slug
    name: "Advent Reading Plan",
    subtitle: "Through Christmas Eve",
    iconName: "star.fill",             // SF Symbol
    accent: .gold,                     // .gold | .red | .accent
    startDate: parseISO("2026-11-29T00:00:00Z"),
    endDate: parseISO("2026-12-24T23:59:59Z"),
    action: .openEvent,                // opens EventDetailView using readingPlan
    bannerImageName: "AdventEventBanner",
    readingPlan: adventReadingPlan
)
```

Then list it in `allEvents`. The MoreView card auto-shows during the date window.

### 6. Author the reading plan

`readingPlan: [EventReadingDay]` — one entry per day. Voice/format conventions (see project memory `feedback_devotional_voice.md`):

- Concrete > abstract; acknowledge cost; no preachy/AI tells
- 150-250 words per reflection
- KJV passages
- **Markdown blockquotes for scripture quotes** — the EventDetailView's MarkdownUI theme renders them with a gold left bar, italic, secondary color
- **`[J]` marker for Jesus's words** — red-letter convention. `> [J] "..."` blockquotes render in red (or normal if user has `Settings → Show Jesus's words in red` off). Only mark scripture where Jesus himself is the speaker; narrators / apostles / prophets / observers stay as plain `> "..."` blockquotes.

```swift
EventReadingDay(
    id: "advent-2026-day-1",
    date: parseISO("2026-11-29T00:00:00Z"),
    theme: "And the Word Became Flesh",
    passage: ScriptureRef(book: "John", chapter: 1, startVerse: 1, endVerse: 14),
    reflection: """
    Opening sentence framing the whole passage.

    > "In the beginning was the Word, and the Word was with God, and the Word was God." (v.1)

    Reflection text continues...
    """
)
```

### 7. Push + submit

```bash
make push-event EVENT=<slug> DRY=1   # preview
make push-event EVENT=<slug>          # creates DRAFT in ASC + uploads images
make pull-events                      # confirm state, schedule, image dimensions
make submit-event EVENT=<slug>        # transition DRAFT → READY_FOR_REVIEW
```

Submit at least 5-7 days before the publish_start date (Apple reviews 24-72h).

### 8. Test in the iOS app

```
Settings → Debug → "Force-Show Events" toggle ON   (overrides date-gating in DEBUG builds)
                → "Open <Event> Event View" button (opens EventDetailView immediately)
                → toggle OFF after testing
```

Or test the deep link from terminal:

```bash
xcrun simctl openurl booted "swiftbible://event/<slug>"
```

## event.yaml schema

```yaml
reference_name: "Pentecost 2026"        # private ASC name
event_type: "Special Event"             # → maps to badge: SPECIAL_EVENT, NEW_SEASON, PREMIERE, CHALLENGE, LIVE_EVENT, MAJOR_UPDATE, COMPETITION
priority: "HIGH"                        # LOW | NORMAL | HIGH
purpose: "Appropriate for All Users"    # or "Appropriate for Certain Users"
purchase_requirement: "FREE"
primary_locale: "en-US"

schedule:
  publish_start: "2026-05-25 00:00 UTC" # when card appears on product page
  event_start:   "2026-06-01 00:00 UTC" # the actual event moment
  event_end:     "2026-06-07 23:59 UTC" # event ends

deep_link: "swiftbible://event/pentecost"

locales:
  en-US:
    name:  "Pentecost Reading Plan"     # 30 chars max
    short: "Acts 2 + 7 days of devotionals"  # 50 chars max
    long:  "Walk through the birth of the Church..."  # 120 chars max
  es-ES: { ... }
  # etc — see Pentecost for full 14-locale Christian-population set
```

## Apple's IAE state machine

- **DRAFT** — newly created, fully editable via API
- **READY_FOR_REVIEW** — submitted to the queue (set via reviewSubmissions, NOT eventState PATCH)
- **WAITING_FOR_REVIEW** → **IN_REVIEW** → **ACCEPTED** / **REJECTED**
- **PUBLISHED** — live on the App Store at the publish_start time
- **PAST** — event_end has passed
- **ARCHIVED** — manually archived

To re-edit a non-DRAFT event, set it back to DRAFT in App Store Connect, edit, then re-submit.

## In-app behavior

### Day-locking
Future days show a lock icon + "Unlocks tomorrow / in N days / on <date>" message. Past + today's days are fully accessible. This drives daily-return engagement.

DEBUG override: `debug_forceShowEvents` AppStorage flag (Settings → Debug → Force-Show Events) unlocks every day for testing.

### EventDetailView UX
- TabView page-style swipe (horizontal, hardware-accelerated — no jank)
- Up/down chevrons in toolbar (prev/next day)
- Auto-opens to today's day on launch
- "Read <passage> in Bible" button dismisses sheet + navigates to Bible tab
- Page indicator dots show all days (locked or not)

### URL handler
ContentView's `onOpenURL` automatically routes `swiftbible://event/<slug>` for any event in `AppEventRegistry.allEvents`. Slug match is exact, OR by id-prefix (so `event/pentecost` matches `pentecost-2026`). No per-event handler code needed.

## Field rules (must follow)

| Field | Limit | Notes |
|---|---|---|
| `name` | 30 chars | Per locale. The big headline on the card. |
| `short` | 50 chars | One-line teaser. |
| `long` | 120 chars | Long form shown on event detail page. |
| EVENT_CARD image | 1920×1080+ landscape PNG | Original art. No app screenshots. No Apple trademarks. |
| EVENT_DETAILS_PAGE image | 1080×1920+ portrait PNG | Same rules. |
| Event window | Max 31 days | publish_start to event_end. |
| Active concurrent events | Max 10 per app | Apple's hard cap. |
| Reading plan day count | Match `event_end - publish_start` | One entry per day in the window. |

## Common errors → fixes

| Error | Fix |
|---|---|
| `'badge' must be one of [...]` | `event_type` in YAML doesn't map. Use one of: Special Event, New Season, Premiere, Challenge, Live Event, Major Update, Competition. |
| `'EVENT_DETAILS' is not a valid value for the attribute 'appEventAssetType'` | Apple uses `EVENT_DETAILS_PAGE`, not `EVENT_DETAILS`. Already fixed in push_event.py. |
| `imageAsset: 0x0` after upload | Image dimensions don't meet Apple's spec — EVENT_CARD wants ≥1920×1080 landscape, EVENT_DETAILS_PAGE wants ≥1080×1920 portrait. Resize and re-upload with `REPLACE_IMAGES=1`. |
| `territorySchedules` 500 UNEXPECTED_ERROR | Apple requires non-empty `territories` array. Already handled by push_event.py — fetches all 175 territories. |
| `'sourceFileChecksum' is not an attribute on the resource 'appEventScreenshots'` | Don't include checksum in commit body for event assets (works for app screenshots, not event ones). Already fixed. |
| `The attribute 'eventState' can not be included in a 'UPDATE' operation` | Submission is via reviewSubmissions flow, not eventState PATCH. Already fixed in `submit_event_for_review`. |
| `reviewSubmission state does not allow adding more items` | Existing reviewSubmission isn't in READY_FOR_REVIEW state. Script creates a new one — already fixed. |
| `Cannot transition to READY_FOR_REVIEW` | Required fields missing (image, primary localization, schedule). `pull-events` to inspect. |
| `INVALID locale` | Locale not supported as IAE locale. See project memory `project_apple_listing_locales.md` (e.g., `ml` is unsupported). Remove from YAML. |
| Deep link opens app but doesn't navigate | URL format mismatch. ContentView handler expects `swiftbible://event/<slug>` (path) for events, OR `swiftbible://verse?book=X&chapter=Y&verse=Z` (query) for verses. |

## Post-event housekeeping

When an event ends:
1. Add actual impressions / taps / installs to `appstore/EVENTS.md` tracking column (baseline for future events)
2. The event copy in event.yaml + AppEventRegistry entry stays — bump dates next year and reuse. The `isActive` filter auto-hides past events from MoreView.
3. The asset catalog banner can stay — small, doesn't bloat the binary meaningfully.

## Don't

- Don't push without dry-running first
- Don't submit before images are uploaded — Apple will reject
- Don't use the same `reference_name` for multiple events (script can't disambiguate)
- Don't deep-link to a paywall — Apple may reject and the engagement signal is wasted
- Don't include trademarked content (Apple logos, other apps' branding) in the event image
- Don't skip the notification opt-in copy — that's half the long-term re-engagement value
- Don't forget the iOS-app side after pushing to ASC — without the AppEventRegistry entry, the deep link hits the URL handler but doesn't surface a card during the event window

## Related

- `/aso` → `references/in-app-events.md` — strategic playbook (cadence, hooks, anti-patterns)
- `/app-store-listing` — adjacent skill for metadata + screenshots + version submission
- `/custom-devotional-crafter` — for daily devotionals in Supabase (different from event reading plans)
- `appstore/EVENTS.md` — 12-month calendar
- `appstore/events/pentecost/` — reference implementation
- Project memories:
  - `project_apple_iae_api_quirks.md` — territorySchedules, asset types, submission flow
  - `feedback_event_image_workflow.md` — GPT Image 2 prompt pattern
  - `feedback_devotional_voice.md` — voice for reflections
  - `project_apple_listing_locales.md` — supported locale codes
