---
description: SwiftBible's App Store Connect In-App Event automation — create, update, upload images for, and submit IAEs (Pentecost, Advent, Lent, Easter, etc.) via the App Store Connect API. Use when the user wants to build a new In-App Event, push event metadata + image to ASC, submit an event for Apple review, list existing events, draft localized event copy, or plan the events calendar. Reads from appstore/events/<slug>/event.yaml + image; uses appstore/push_event.py.
allowed-tools:
  - Bash(uv run python appstore/push_event.py --pull*)
  - Bash(uv run python appstore/push_event.py *--dry-run*)
  - Bash(make pull-events*)
---

# App Store In-App Events Automation

Create, update, and submit In-App Events (IAEs) in App Store Connect via the API. IAEs surface on your product page, in search results, and in editorial / browse placements — see `/aso` for the strategic playbook.

## Files

| File | Purpose |
|---|---|
| `appstore/push_event.py` | Script: create/update/submit events + upload images |
| `appstore/events/<slug>/event.yaml` | Per-event definition (metadata + localized copy) |
| `appstore/events/<slug>/*.png` | Event image (1080×1080) |
| `appstore/events/<slug>/SETUP.md` | Per-event setup notes (deep link, devotional content, etc.) |
| `appstore/EVENTS.md` | 12-month rolling calendar of events to plan around |
| `appstore/.env` | Credentials (shared with push_listing.py) |

## Quick command reference

```bash
# List existing events in ASC
make pull-events

# Push event from local YAML (creates if new, updates if exists)
make push-event EVENT=pentecost

# Preview without making changes
make push-event EVENT=pentecost DRY=1

# Push AND submit for Apple review (transition to READY_FOR_REVIEW)
make submit-event EVENT=pentecost

# Direct invocation
uv run python appstore/push_event.py --pull
uv run python appstore/push_event.py --event pentecost --dry-run
uv run python appstore/push_event.py --event pentecost --submit
```

## Workflow: ship a new event

1. **Pick the event from `appstore/EVENTS.md`** (or add a new one). The calendar tells you the submit-by date and locale targeting.
2. **Create the event folder**: `mkdir appstore/events/<slug>`
3. **Author `event.yaml`** with all metadata + per-locale copy. Use `appstore/events/pentecost/event.yaml` as the template. Field limits: name 30, short 50, long 120.
4. **Generate or design the event image** (1080×1080 PNG, original art — no app screenshots, no Apple trademarks). For procedural images, copy `appstore/events/pentecost/generate_event_image.py` and adapt the visuals.
5. **Add the deep-link route in Swift** if the event needs custom routing (or reuse an existing `swiftbible://verse/<book>/<chapter>/<verse>` URL — the simplest path).
6. **Add an entry to `AppEventRegistry.allEvents`** in `swiftbible/Models/AppEvent.swift` so the in-app More-tab card surfaces during the event window.
7. **Dry-run**: `make push-event EVENT=<slug> DRY=1`
8. **Push (creates draft)**: `make push-event EVENT=<slug>`
9. **Submit for review** when ready: `make submit-event EVENT=<slug>`. Apple reviews 24-72h.

Always `pull-events` after pushing to confirm state.

## event.yaml schema

```yaml
reference_name: "Pentecost 2026"        # private ASC name
event_type: "Special Event"             # Special Event | New Season | Premiere | Challenge | Live Event | Major Update | Competition
priority: "HIGH"                        # LOW | NORMAL | HIGH
purpose: "Appropriate for All Users"    # or "Appropriate for Certain Users"
purchase_requirement: "FREE"            # FREE | In-App Purchase | Subscription
primary_locale: "en-US"

schedule:
  publish_start: "2026-05-25 00:00 UTC" # when card appears on product page
  event_start:   "2026-06-01 00:00 UTC" # the actual event moment
  event_end:     "2026-06-07 23:59 UTC" # event ends

deep_link: "swiftbible://verse/Acts/2/1"

locales:
  en-US:
    name:  "Pentecost Reading Plan"     # 30 chars max
    short: "Acts 2 + 7 days of devotionals"  # 50 chars max
    long:  "Walk through the birth of the Church..."  # 120 chars max
  es-ES:
    name: "..."
    ...
```

## Apple's IAE state machine

- **DRAFT** — newly created, not visible. You can PATCH attributes freely.
- **READY_FOR_REVIEW** — submitted to Apple. PATCHes mostly locked.
- **WAITING_FOR_REVIEW** → **IN_REVIEW** → **ACCEPTED** / **REJECTED** — Apple's process.
- **PUBLISHED** — live on the App Store at the publish_start time.
- **PAST** — event_end has passed.
- **ARCHIVED** — manually archived.

To re-edit a non-DRAFT event, set it back to DRAFT in App Store Connect (or via API), edit, then re-submit.

## Field rules (must follow)

| Field | Limit | Notes |
|---|---|---|
| `name` | 30 chars | Per locale. The big headline on the card. |
| `short` | 50 chars | One-line teaser shown on smaller surfaces. |
| `long` | 120 chars | Long form shown on the event detail page. |
| Image | 1080×1080 PNG | Original art only. No app screenshots. No Apple trademarks. No price/sale claims. |
| Event window | Max 31 days | publish_start to event_end. |
| Active concurrent events | Max 10 per app | Apple's hard cap. |

## Common errors → fixes

| Error | Fix |
|---|---|
| `'badge' must be one of [...]` | The `event_type` in YAML doesn't map to a valid Apple badge. Use one of: Special Event, New Season, Premiere, Challenge, Live Event, Major Update, Competition. |
| `Image dimensions must be 1080x1080` | Resize / re-render. The asset is a single 1:1 image, not multiple device sizes. |
| `Event already exists` | Script matches by `referenceName` — change the `reference_name` in YAML, or update the existing event. |
| `Cannot transition to READY_FOR_REVIEW` | Required fields missing (image, primary localization, schedule). Re-run `pull-events` to inspect. |
| `INVALID locale` | Locale code not supported as an IAE locale (see project memory `project_apple_listing_locales.md` — `ml` for example is not supported). Remove from YAML. |

## Post-event housekeeping

When an event ends:
1. Add actual impressions / taps / installs to `appstore/EVENTS.md`'s tracking column (so future events have a baseline)
2. Remove the corresponding entry from `AppEventRegistry.allEvents` after a brief lag, OR leave it (the `isActive` filter auto-hides past events)
3. The event copy becomes a template for next year — bump dates and reuse

## Don't

- Don't push without dry-running first
- Don't submit (transition to READY_FOR_REVIEW) before the image is uploaded — Apple will reject
- Don't use the same `reference_name` for multiple events (script can't disambiguate)
- Don't deep-link to a paywall — Apple may reject and the engagement signal is wasted
- Don't include trademarked content (Apple logos, other apps' branding) in the event image
- Don't skip the notification opt-in copy — it's half the long-term value (re-engagement)

## Related

- `/aso` → `references/in-app-events.md` — strategic playbook (cadence, hooks, anti-patterns)
- `/app-store-listing` — adjacent skill for metadata + screenshots + version submission
- `appstore/EVENTS.md` — 12-month calendar with submit-by dates per event
- `appstore/events/pentecost/` — reference implementation of a complete event setup
