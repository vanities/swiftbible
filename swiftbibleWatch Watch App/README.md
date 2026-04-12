# SwiftBible Watch App

watchOS companion to the SwiftBible iOS app. Shows the daily devotional on the wrist.

## Phase 1 (shipped)

- Scrollable markdown devotional with Digital Crown
- Pull-to-refresh, error + retry
- Cache-first load via shared App Group (`group.com.am2.swiftbible`), falls back to direct Supabase fetch
- Daily haptic reminder (`UNCalendarNotificationTrigger`) — user picks the time

## Phase 2 ideas

### Watch face complications
Tiny widgets for the watch face itself, so users see the devotional without opening the app. Three families to support:
- **Rectangular** — heading + 2-line snippet (Modular face)
- **Circular** — book glyph + "Daily" label (Infograph)
- **Inline** — single-line heading at the top of the face

Tap → opens app to today's devotional. Implementation requires a separate Widget Extension target on the watch side; reads from the same App Group container the watch app writes to.

### Reading aids
- **Verse of the hour** — rotate through verses from the devotional's referenced chapter throughout the day
- **Read-aloud** — `AVSpeechSynthesizer` plays the devotional; great for commutes/walks
- **Smart Stack widget** (watchOS 10+) — rectangular complication that bubbles up in the morning

### Reflection
- **One-tap reactions** — 🙏 / ❤️ / ✝️ logged to Supabase, builds a streak
- **Voice journal** — dictate a short reflection, sync to iPhone (extend the existing `verse_info` table)
- **Prayer streak** — simple counter, "you've read N days in a row"

### Navigation
- **Random verse** — long press for a random verse pick-me-up
- **Bookmark today** — save to the iOS app's highlights

### Nice extras
- **SharePlay / FaceTime** — read the devotional together with family (watchOS 10+)
- **Focus filter** — auto-surface devotional when "Personal" focus is on
- **WatchConnectivity push** — phone pushes today's devotional to the watch so the watch never has to hit Supabase directly

## Architecture notes

- App Group ID: `group.com.am2.swiftbible` (shared with iOS app + iOS widget)
- Devotional cache path: `<App Group>/Devotionals/{yyyy-MM-dd}.json`
- Supabase REST endpoint: `GET /rest/v1/Daily Devotional?for_date=eq.{date}` with anon key
- Edge Function source: `supabase/functions/daily-devotional/index.ts`
- watchOS deployment target: 11.0 (matches iOS 18 minimum)
