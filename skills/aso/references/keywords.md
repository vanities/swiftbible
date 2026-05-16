# Keyword Strategy

## The combined-string rule

Apple indexes app **name + subtitle as one combined string** for search ranking. That means:
- Repeating a word between name and subtitle wastes characters with zero ranking benefit
- Words in the keyword field (the hidden 100-char field in App Store Connect) are also added to this combined index
- So the total "keyword surface" = name (30) + subtitle (30) + keyword field (100) = 160 unique chars

## App name (30 char max)

**Rule**: primary keyword first, brand second.

| Bad | Good |
|---|---|
| `Habit Kit` | `Habit Tracker - Habit Kit` |
| `SwiftBible` | `Bible KJV - SwiftBible` |
| `Cal AI` | `Calorie Counter AI - Cal` |

Why brand second: indie devs can't afford to put brand first. Companies like Duolingo can because the brand IS the search term. You're not Duolingo.

Common separators: ` - ` (most common), `: `, `&`, `/` (cleaner for stacking translations/variants).

**App Review risk**: heavy keyword stuffing (`Bible KJV ASV WEB Devotional`) may trigger reviewer kickback. The pattern `<Keyword> - <Brand>` is well-precedented and safe. Slashes and ampersands look cleaner than back-to-back words.

## Subtitle (30 char max)

**Rule**: secondary keywords ONLY, no overlap with name.

Examples (assuming name is `Bible KJV - SwiftBible`):
- `Devotional, Apocrypha, Greek` (28)
- `Daily Devotional & Apocrypha` (28)
- `Apocrypha, Enoch, Hebrew Greek` (30)

Each comma-separated term is a separate keyword in Apple's index.

## Keyword field (100 char max — App Store Connect, hidden from users)

Strict rules (validated against Apple docs):
1. **Comma-separated, NO spaces around commas**: `apple,banana,cherry` not `apple, banana, cherry`
2. **Don't repeat words from name or subtitle** — Apple already indexed them
3. **Don't use plurals if you used singular** (or vice versa) — Apple stems
4. **Don't include competitor app names** — Apple may reject
5. **Use all 100 characters** — every unused char is a missed keyword

**Stop-words Apple auto-strips** (don't waste chars): `the, and, of, for, a, an, to, with, in, on, app, free`

**Worked example for SwiftBible** (name `Bible KJV - SwiftBible`, subtitle `Devotional, Apocrypha, Greek`):
```
asv,web,scripture,gospel,prayer,jesus,christian,faith,study,notes,jubilees,enoch,hebrew,catholic,god
```
= 100 chars exactly. Catches translation variants (asv/web), Christian-search funnel (gospel/jesus/christian/faith/god/prayer), study-app intent (study/notes), unique-content moat (jubilees/enoch/hebrew), and Apocrypha-canonical audience (catholic).

## Picking the primary keyword

The bias: **go for the hard high-value keyword over dominating an easy low-volume one.** A primary keyword should match what the app actually IS, not a feature.

But this rule has a context: it assumes you're competing against other apps in your category, not against a category-defining giant. Two failure modes:

| Trap | Example | Fix |
|---|---|---|
| Picking a keyword owned by a 500M+ download giant | `Bible` (YouVersion owns it) | Qualify it: `KJV Bible`, `Bible Devotional` |
| Picking a feature keyword instead of an app keyword | `Devotional` for a Bible app | Use it as secondary (subtitle), not primary |

## Tools

- **Astro** (https://astro... — confirm URL): unlimited keyword tracking, popularity (5-100) + difficulty scores. Affordable, indie-friendly.
- **AppFigures, App Tweak, Sensor Tower**: more powerful but expensive
- **ChatGPT/Claude**: brainstorming candidate keywords from app description
- **Apple Search Ads**: the paid feedback loop — bid small on candidate keywords for 2-4 weeks, watch which ones convert. The keywords with high TTR + CR are your organic primary candidates. See [apple-search-ads.md](apple-search-ads.md).

Always validate gut intuition with popularity AND difficulty data. Popularity alone is misleading.

## Linking keywords to Custom Product Pages (Jul 2025+)

Since Apple opened CPPs to organic search in July 2025, you can build alternate product pages and tell Apple which keywords each one should serve. A "habit tracker" searcher and a "daily routine" searcher want different framings; you can now serve them different screenshots and promo text.

Practical impact on keyword strategy: you no longer have to optimize ONE product page for ALL your target keywords. Optimize the default for your strongest primary, then build CPPs for secondary keyword themes. See [product-pages.md](product-pages.md).

## Category

Search rankings are NOT category-locked — when a user searches "bible" they see results from every category. But:
- Category does affect Top Charts ranking (separate from search)
- Category match is one signal among many in the ranking algorithm
- The right category puts you alongside relevant competitors users compare against

Quick rule: pick the category your category-leaders are in, not the most general fit. Bible apps → **Reference** (where dictionaries, encyclopedias, religious texts live), not Books (where Kindle alternatives and novels live).

## Ranking timeline expectations

Metadata change → re-indexed in days, ranking shift in days-to-weeks. Don't bail on a strategy after 48h.

## Non-indexed fields (conversion-only)

Two App Store Connect fields that frequently get treated as keyword surface but are NOT indexed for search ranking:

- **Promotional text** (170 chars, top of description): conversion copy only. Updates without requiring a new app version. Use it for time-bounded announcements ("Daily Devotional now in Portuguese!"), not keyword stuffing.
- **What's New** (4000 chars, version notes): also conversion-only for ranking purposes. Recent app updates do feed a "freshness" signal indirectly (the algorithm rewards regularly-updated apps), so write something honest here every release rather than reusing "Bug fixes and improvements."

Putting target keywords in these fields wastes the slot. Put them in name, subtitle, keyword field, screenshot captions (OCR-indexed since Jun 2025), and CPP keyword links instead.
