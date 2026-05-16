# Product Page Optimization & Custom Product Pages

Apple lets you create alternate versions of your product page. Two distinct features, often confused:

| | PPO (Product Page Optimization) | CPP (Custom Product Pages) |
|---|---|---|
| Purpose | A/B test your DEFAULT page | Serve ALTERNATE pages to specific traffic |
| Reach | Random slice of all organic traffic | Only people who hit the unique URL or matched keyword |
| Quantity | Up to 3 active treatments | Up to 70 per app (raised from 35 in Jul 2025) |
| Duration | Up to 90 days per test | Always-on |
| Organic impact | The winner becomes your default | Eligible for organic search since Jul 2025 |
| Use when | Validating a hypothesis | Personalizing per channel/keyword/segment |

## Product Page Optimization (PPO) — A/B testing

Apple's free A/B testing for your default product page. Test up to 3 alternate "treatments" against your current page (the control) on a randomized slice of traffic.

### What you can test

- App icon
- Up to 10 screenshots per treatment
- App preview videos

You CANNOT test name, subtitle, keyword field, description, or promotional text via PPO. Those are global, all-traffic changes via the regular App Store Connect submission.

### Setup

1. App Store Connect → your app → "Product Page Optimization"
2. Create a new test, name it descriptively (`hero-screenshot-grid-vs-list`)
3. Upload up to 3 treatments
4. Set treatment % (e.g. 33% / 33% / 33% means each treatment + control gets 25% of traffic)
5. Set duration (max 90 days; longer = more confident result)
6. Submit (treatments require Apple review, ~24-48h)

### Common pitfalls

- **Testing too many variables at once**: change ONE element per test (icon, OR slot #1, OR video — not all three)
- **Stopping too early**: 90 days exists for a reason. Conversion lift signals need volume.
- **Testing during a metadata change**: separate the keyword variable from the visual variable. Don't run a PPO test the same week you change your subtitle.
- **Trusting "looks better" intuition**: "professionally redesigned" treatments often LOSE against authentic self-made originals. Test, never assume.

### What to test (highest leverage first)

1. Slot #1 screenshot — single highest-impact frame
2. App icon — affects every impression including search results
3. Headline copy on screenshot #1 (feature framing vs outcome framing)
4. App preview video presence (with vs without)
5. Layout per slot (hero vs split vs panoramic)

## Custom Product Pages (CPPs) — alternate pages for segments

A CPP is a complete alternate version of your product page (screenshots, video, promo text) reachable via:
1. A unique URL Apple generates
2. Apple Search Ads campaigns targeting the CPP
3. **Organic search keyword links (since Jul 2025)** — you tell Apple "this CPP is the one to show for these keywords"

You can have up to 70 active CPPs per app (raised from 35 in mid-2025).

### Why CPPs matter (the Jul 2025 organic shift)

Pre-Jul 2025: CPPs only fired when traffic came from a campaign URL. Useless for organic discovery.

Post-Jul 2025: each CPP can be linked to keyword themes in App Store Connect. When a user searches one of those keywords, Apple may serve the matched CPP instead of your default page. CPPs are now an organic ranking + conversion lever, not just a paid one.

Practical implication: if you target multiple keyword themes with a single product page, you're under-using the surface. A "habit tracker" searcher and a "daily routine" searcher are looking for different framings; serve them different screenshots.

### Common CPP patterns

| Pattern | Use case |
|---|---|
| Per primary keyword | Different screenshot ordering for each major keyword theme |
| Per persona | Power user vs newcomer framing |
| Per channel | TikTok ad → video-led CPP; podcast ad → trust-led CPP |
| Per feature | Promote one specific feature for a launch / press cycle |
| Per locale-within-locale | E.g. Spanish-Mexico vs Spanish-Spain framing |

### Strategy: PPO → CPP sequence

Most-recommended workflow:
1. Run PPO to find a winning **base** treatment for your default page
2. Promote that winner to your default
3. Build CPPs that personalize the winner for specific keywords / channels
4. Track per-CPP: a CPP should outperform the default for its target keyword by enough to justify maintenance

### CPP setup (organic search linking)

App Store Connect → CPPs → Create → upload screenshots/video/promo text → "Add as a search result for keywords" → enter the keyword themes you want this CPP to serve.

Apple decides whether to actually show it (relevance + quality scoring), but that's the lever you have.

### Anti-patterns

- 70 CPPs for the sake of using all 70 — each one needs to outperform the default for its target, or it's noise
- CPP that only differs by 1 screenshot — Apple may treat it as duplicative; commit to a real variant
- Forgetting to update CPPs when you ship app changes that invalidate the screenshots
- Building CPPs before establishing a strong default page via PPO — you're optimizing variants of an unvalidated baseline
