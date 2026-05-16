# In-App Events

In-App Events (IAEs) are time-bounded promotional cards Apple lets you publish that surface on your product page, in search results, and in editorial / browse placements. Different from app updates — these are events tied to your app, with a start and end date.

## What an IAE looks like

A small card with: event name (30 char), short description (50 char), long description (120 char), event image/video, deep link into your app. Shown:
- On your product page (above screenshots when active)
- In search results (small badge next to your app)
- In Today / Apps / Games tabs (browse placements, when Apple promotes it)
- In notifications to users who have your app and opted in

## Why they matter for ASO

Per industry data: ~55% of top-200 apps run IAEs regularly. Apps with active events see ~15-20% more impressions from editorial / browse placements vs the same app without an event.

Two ranking signals:
1. **Discovery surface expansion** — IAEs unlock browse placements you can't reach via metadata alone
2. **Engagement signal** — users who tap an IAE and open the app are a strong "active interest" signal that feeds the post-2025 retention-aware ranking algorithm

## Event types Apple supports

- **Challenge** — limited-time goal (e.g. "30-day reading streak")
- **Competition** — leaderboard / tournament
- **Live Event** — real-time event (e.g. live-streamed sermon)
- **Major Update** — feature reveal tied to a specific launch
- **New Season** — recurring content drop (e.g. seasonal devotional series)
- **Premiere** — new content launch (movie, episode, level)
- **Special Event** — catch-all for promotions

Apple uses the type to decide which surfaces to consider promoting it on.

## Cadence

- Up to 10 active events at once
- Each event runs up to 31 days
- Industry recommendation: 2-4 active events per month for sustained visibility

If you ship one IAE then nothing for 3 months, you signal a stale app. If you ship 10 and they're all generic, you signal noise.

## Pattern: tying IAEs to evergreen functionality

Most indie apps don't have a Coachella to promote. The trick: tie an existing app feature to a real-world calendar moment.

Examples:
- A Bible app: Lenten reading plan (Mar), Advent devotional (Dec), Holy Week (Apr), New Year reading-plan reset (Jan)
- A habit tracker: New Year's habit reset (Jan), back-to-school routine builder (Aug)
- A meditation app: Stress Awareness Month (Apr), seasonal sleep series (Nov)
- A budgeting app: tax-prep checklist (Mar), holiday spending tracker (Nov)

Each event is a real-world hook + a deep link into the existing feature. Costs near zero to author; unlocks Apple browse placements that pure metadata cannot.

## Setup

App Store Connect → your app → In-App Events → Create New Event:
1. Pick event type (Apple uses this for placement)
2. Set name + short + long description (every char counts; search may use this text)
3. Upload event image (must be original — no app screenshots reused, no Apple trademarks)
4. Set start + end dates
5. Configure deep link into your app
6. Configure notification opt-in copy (this is half the long-term value — re-engagement)
7. Submit (Apple reviews, ~24-72h)

## Localization

IAEs are per-locale. A "Lenten reading plan" event makes sense in es-ES, pt-BR, en-US, en-GB; less so in ja-JP. Localize where the cultural moment lands; skip where it doesn't.

Maintain at least the locales where you've localized the main listing — a Spanish listing without Spanish IAEs leaves visibility on the table.

## Anti-patterns

- Promoting "the app exists" — IAEs need a TIME-BOUNDED hook, not generic feature copy
- Reusing the same event copy every quarter — Apple's editorial team notices stale content
- Deep-linking to a paywall — burns the click without the engagement signal
- Skipping the notification opt-in — that's half the long-term value (re-engagement)
- Submitting an event right at its start date — Apple's review window may make you miss the moment; submit 5-7 days ahead
