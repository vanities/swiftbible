---
name: aso
description: iOS App Store Optimization playbook — keyword strategy (name/subtitle/keyword field), screenshot ordering and conversion, review prompt timing, localization, In-App Events, Custom Product Pages, App Preview videos, and the 2025-2026 algorithm changes (screenshot OCR indexing, organic CPPs, engagement signals). Use when the user asks about ASO, app store ranking, why their app isn't being found, keyword research, screenshot conversion, ratings/reviews strategy, or any iOS App Store growth topic.
---

# iOS ASO Playbook

A field guide for indie iOS developers competing for App Store visibility, built on indie-tested practice and updated for the 2025-2026 algorithm shifts.

## When to use

User asks about:
- ASO / App Store Optimization
- Why their app isn't ranking or getting downloads
- Keyword strategy (app name, subtitle, keyword field)
- Screenshot conversion / first-impression
- Review prompts / star rating strategy
- Localization, In-App Events, Custom Product Pages, or App Preview videos
- Apple Search Ads as a growth or research lever
- New app launch checklist

## What changed in 2025-2026

Several algorithm and platform shifts make older ASO advice incomplete. Read the relevant reference if your work touches these:

| Change | Date | Impact | Where to look |
|---|---|---|---|
| Screenshot text indexed via OCR | Jun 2025 | Caption text is now keyword surface, not just conversion copy | [references/screenshots.md](references/screenshots.md) |
| Custom Product Pages eligible for organic search | Jul 2025 | CPPs (up to 70/app) can be linked to keyword themes and surface organically | [references/product-pages.md](references/product-pages.md) |
| Engagement / retention as ranking signal | 2025-2026 | Apple rewards "healthy" installs (D1/D7 retention, sessions per user); raw download volume alone does less | "Time horizon" section below |
| Rating velocity over total | 2025-2026 | Recent ratings now weigh more than lifetime average | [references/reviews.md](references/reviews.md) |
| Apple Search Ads in positions #2-5 | Mar 2026 | Search results page is more ad-saturated; brand defense bidding is now table stakes | [references/apple-search-ads.md](references/apple-search-ads.md) |

## The four levers (ordered by impact)

### 1. Keywords — name + subtitle + keyword field (#1 ASO factor)

See [references/keywords.md](references/keywords.md) for full rules and worked examples.

Quick rules:
- **App name (30 char max)**: primary keyword FIRST, brand second. e.g. `Habit Tracker - Habit Kit`, not `Habit Kit`.
- **Subtitle (30 char max)**: secondary keywords ONLY. Apple indexes name+subtitle as one combined string — repeating wastes characters.
- **Keyword field (100 char max, hidden)**: comma-separated, NO spaces, no repeats from name/subtitle, no plurals if singular used, no competitor names, USE ALL 100 chars.
- **Compete for the hard high-value keyword > dominate an easy low-volume one** — UNLESS the high-value keyword is owned by a category-defining giant (e.g. YouVersion for "Bible"). Then qualify it (`KJV Bible` instead of `Bible`).

Tools: ChatGPT/Claude for brainstorming. **Astro** for popularity + difficulty scoring (sweet spot: high popularity + manageable difficulty). **Apple Search Ads** as a paid lab to validate organic keyword bets — see [references/apple-search-ads.md](references/apple-search-ads.md).

### 2. Screenshots — first 3 win or lose, AND captions are now indexed

See [references/screenshots.md](references/screenshots.md) for OCR-aware caption rules, ordering, capture workflow, and AB testing.

- 3-5 second decision window per user
- **Caption text is keyword surface** as of June 2025 — write outcomes that *contain* keywords, not just outcomes
- Place caption text near top or bottom of frame (where Apple appears to read)
- Lead with most visually impressive AND unique feature (NOT a generic list view, NOT onboarding)
- AB test via Apple Product Page Optimization — see [references/product-pages.md](references/product-pages.md). "Professionally redesigned" screenshots often LOSE against authentic self-made ones — always test, never assume.

### 3. Reviews & ratings

See [references/reviews.md](references/reviews.md) for the Swift `ReviewPromptService` pattern, trigger taxonomy, and the rating-reset decision.

- Apple rate-limits to 3 prompts per 365 days per user — never burn them on cold opens / `.onAppear`
- Trigger at "happy moments": after a meaningful save, complete, share, or earned-result event
- **Rating velocity (recent reviews) now outweighs lifetime average** — a sustained drip beats one big push
- Reply to EVERY review — bad reviewers will often update 1★ → 5★ after a fix
- Email signature trick: every support reply ends with "if you're enjoying the app, I'd be grateful for a review" + deep-link to `apps.apple.com/.../id<APP_ID>?action=write-review`

### 4. Localization

See [references/localization.md](references/localization.md) for the high-ROI markets, what to translate, and the keyword-research-per-locale workflow.

The single highest-ROI move many indie devs skip. You don't need to localize the *app* to localize the *listing*: name, subtitle, keyword field, screenshots, and description in Spanish, Portuguese, French, German, Japanese can rank #1 in markets where English-only competitors are invisible.

## Other levers worth knowing

- **In-App Events** — promotional cards on your product page and in browse/search. ~55% of top-200 apps run them; +15-20% impressions when active. See [references/in-app-events.md](references/in-app-events.md).
- **App Preview Videos** — autoplay in search; well-made previews lift conversion 20-35%. First 3 seconds decide. See [references/preview-videos.md](references/preview-videos.md).
- **Custom Product Pages** — up to 70 per app, organic-eligible since Jul 2025. Personalize per keyword/channel. See [references/product-pages.md](references/product-pages.md).
- **Apple Search Ads** — paid acquisition with halo into organic ranking; useful as a research lever. See [references/apple-search-ads.md](references/apple-search-ads.md).

## Time horizon

ASO is a marathon. A reference timeline (an indie habit-tracker that reached top-3 in US):
- ~6 months: top 10 in non-US markets (UK, Germany)
- ~1 year: occasional US top 10
- ~3 years: consistent US top 5

Don't bail on a strategy after 48 hours. Metadata changes can move rank within days; a stable position takes weeks.

The 2025-2026 shift toward engagement signals means **a great product retains the ranking better than a great metadata sprint**. If retention is bad, fix the product before optimizing the listing — Apple's algorithm is increasingly looking at D1/D7/D30 retention, sessions per user, and "did they keep the app" as ranking signals. Bought / metadata-tricked installs that bounce now hurt rather than help.

## Audit checklist

When auditing an existing iOS app's ASO, run through this in order:

1. **Name**: does it lead with primary keyword, or just brand?
2. **Subtitle**: present and stuffed with non-overlapping secondary keywords?
3. **Keyword field**: 100/100 chars, no overlap with name/subtitle, no plurals, no competitor names?
4. **Category**: primary category match the app's actual purpose vs. a noisier crowd? (e.g. Bible apps belong in Reference, not Books)
5. **Screenshot #1**: visually impressive + differentiating, or a generic list?
6. **Screenshot captions**: contain target keywords (OCR-indexed since Jun 2025)? Top/bottom placement?
7. **App preview video**: present? First 3 seconds compelling without sound?
8. **Review prompt**: where in code is `requestReview()` called? Is it gated to a happy moment?
9. **Listing fields**: subtitle, promo text (170, conversion-only), "what's new" (4000, conversion-only) all filled in?
10. **Localization**: at least Spanish + Portuguese + one of (Japanese / German / French)?
11. **Custom Product Pages**: any in use, or running on the default page only?
12. **In-App Events**: any seasonal / launch events scheduled in App Store Connect?
13. **Engagement metrics**: D1/D7 retention healthy? If not, fix the product before optimizing the listing.
