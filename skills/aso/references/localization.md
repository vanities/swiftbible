# Localization

The single highest-ROI ASO move most indie devs skip. You don't have to localize the app to localize the listing — and the listing is what shows up in search.

## Why it works

The English App Store is the most competitive market in the world. The same keyword that has 50+ established competitors in `en-US` may have 3-5 in `pt-BR` or `tr-TR`. Same algorithm, far less competition, often the same total addressable market once you account for English speakers in those locales who now see *your* app instead of an English-only one.

A localized listing in a less competitive market can rank #1 with a fraction of the work an en-US #20 takes.

## What you can localize without changing the app

Per-locale fields in App Store Connect:
- **App name** (30 chars per locale)
- **Subtitle** (30 chars per locale)
- **Keyword field** (100 chars per locale)
- **Description** (4000 chars per locale)
- **Promotional text** (170 chars per locale)
- **Screenshots** (10 per device size per locale)
- **App Preview videos** (3 per device size per locale)
- **In-App Events** (separate copy per locale)

You don't have to ship strings in those languages inside the app. The listing localizes independently.

## High-ROI starter set for indie devs

Order matters. Each is a high-population locale with relatively low ASO competition compared to en-US:

| Locale | Speakers | ASO competition | Notes |
|---|---|---|---|
| Spanish (es-ES + es-MX) | 500M+ | Medium | Two locales, both worth filling |
| Portuguese (pt-BR) | 215M | Low | High mobile penetration, low ASO competition |
| German (de-DE) | 95M | Medium | High purchase intent / spend per user |
| French (fr-FR) | 80M+ | Medium | |
| Japanese (ja-JP) | 125M | Low | High spend per user; language barrier deters competitors |
| Turkish (tr-TR) | 85M | Very low | |
| Korean (ko-KR) | 51M | Low | High engagement, good for sticky apps |
| Indonesian (id-ID) | 270M | Very low | Volume play, lower per-user revenue |
| Hindi (hi-IN) | 600M+ | Very low | iOS share lower than Android in India, but high-spend end |
| Tamil (ta-IN), Malayalam (ml-IN), Telugu (te-IN), Bengali (bn-IN) | 70-90M each | Very low | Worth localizing per app subject — see "your app, your locale" below |

Starter set for one weekend's work: Spanish, Portuguese, German, Japanese. Ships your listing into ~900M potential users in markets where you face a fraction of the en-US competition.

## "Your app, your locale" — match locales to subject

Population alone is misleading. The right locales for your app depend on what your app does and where its natural audience lives. Two examples:

- **A Bible / Christian app**: Tamil (ta-IN) and Malayalam (ml-IN) outperform Hindi (hi-IN) per-locale despite smaller populations, because Christian populations in India concentrate in Kerala (Malayalam) and Tamil Nadu (Tamil). Northeast India (Assamese, smaller languages) is also disproportionately Christian. Pair with high-Christian-density Latin American (es / pt-BR), Korean (large Christian minority), and African Portuguese (Angola, Mozambique) markets.
- **A meditation / wellness app**: Japanese (ja-JP) and Korean (ko-KR) over-index on wellness spending; Indonesian (id-ID) under-indexes despite population.

Check your existing analytics (PostHog country breakdown, App Store Connect's "App Analytics → Sources → Territory") before localizing — if you already have organic users in a locale you haven't localized for, that's a free signal you'd convert better with a localized listing.

## What to translate (and what NOT to)

| Field | Translate? | Notes |
|---|---|---|
| App name | Yes (with research) | Primary keyword may differ per locale |
| Subtitle | Yes | Secondary keywords per locale |
| Keyword field | Yes (with research, NOT direct translation) | Stems differ per language |
| Description | Yes | Full localization |
| Promotional text | Yes | Cultural references matter |
| Screenshot captions | Yes | These are NOW indexed (OCR, Jun 2025) — same keyword rigor as the keyword field |
| App icon | Usually no | Cultural sensitivity exception (e.g. religious symbols for some MENA locales) |
| In-App Events | Yes | Tied to local seasonal calendars |

**Anti-pattern**: machine-translating the keyword field. Apple's stemming differs per language. "Habit" → "Hábito" is one word; "habits" → "hábitos" is different. Brand names don't translate. Native speakers (or a localization-aware AI prompt: "what would a native pt-BR App Store user actually search for to find a habit tracker?") beat Google Translate every time.

## Per-locale keyword research workflow

Same playbook as en-US, repeated:
1. Brainstorm 30-40 candidate keywords in the target language with native-speaker input or AI grounded in the locale
2. Score popularity + difficulty in Astro / AppFigures with the locale set
3. Pick a primary that's high-popularity + manageable-difficulty for THAT locale
4. Check what category-leaders in that locale use as their primary
5. Construct name + subtitle + keyword field with the same rules as en-US (no overlap, no spaces in keyword field, USE ALL 100 chars)

Don't assume your en-US primary keyword has a direct equivalent. "Habit tracker" in pt-BR isn't necessarily "rastreador de hábitos" — could be "controle de hábitos" or even just "hábitos diários" depending on actual search behavior.

## Localized screenshots — when to make new ones

**Cheap option**: keep visuals the same, translate captions only. Captions are now keyword surface (OCR), so the *translated keywords* go on the *translated screenshots*.

**Expensive option**: re-render screenshots showing the localized app UI. Justified for:
- App actually localizes (showing English UI in pt-BR screenshots looks lazy / hurts conversion)
- A locale where text density on screen is meaningfully different (Japanese, Korean — vertical text and density change layout)
- Cultural elements in the screenshot (faces, holidays, religious references) that need to match the locale

## Cost / time

For metadata-only localization (no app strings, no new screenshot renders, just translated captions):
- ~2-3 hours per locale once the en-US listing is solid
- ~$50-200 per locale outsourced to a native translator with ASO familiarity
- DIY with Claude / GPT + native-speaker spot-check is the indie default

ROI shows in 2-4 weeks. If a locale doesn't move in 8 weeks, the issue is usually the keyword choice (not the translation) — re-run keyword research with stronger native input.

## Maintenance

Localized listings are a long-term commitment. When you ship:
- New screenshots → re-translate captions for every locale
- New In-App Events → re-localize event copy
- New "What's New" notes → at minimum machine-translate, ideally have a native check key locales

If you can't keep them in sync, ship fewer locales but maintain them well. A stale pt-BR listing converts worse than no pt-BR listing.
