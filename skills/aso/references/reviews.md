# Reviews & Ratings

Ratings and review count drive both **search ranking** and **conversion rate**. They are the slowest-moving lever — built up over years — but the highest-leverage long-term defense against newer competitors.

**2025-2026 update**: Apple's algorithm now weights rating *velocity* (recent ratings, last ~30-60 days) more heavily than lifetime average. A 4.6 average that hasn't received a review in 90 days now ranks below a 4.5 average getting fresh reviews weekly. Strategy: keep the prompt running rather than batching it, and treat dry spells as a ranking risk.

## Apple's hard limit

`SKStoreReviewController` / `RequestReviewAction` is rate-limited to **3 prompts per 365 days per Apple ID**. You don't control how many show — Apple does. You only control WHEN you ask.

This means:
- Calling `requestReview()` 10 times this week ≠ 10 prompts. Apple shows ~3 max.
- Calling it on `.onAppear` of your main view burns all 3 on first-launch users who have no opinion yet.
- Your job is to make sure the ~3 prompts that DO fire land at moments where the user feels good about your app.

## Anti-pattern: `.onAppear`

```swift
// DO NOT DO THIS
.onAppear {
    requestReview()  // fires every time the view appears, including cold opens
}
```

Why it's bad: cold-open users haven't experienced the app yet. They'll dismiss or 1-star out of irritation. Apple still counts these against the 3/year cap.

## Pattern: happy-moment counter

Trigger after a meaningful positive action. Define "happy moment" broadly — any user-initiated action that signals investment or satisfaction:

| Action | Happy moment? |
|---|---|
| Saved/bookmarked something | ✓ Yes |
| Highlighted/favorited something | ✓ Yes (only on add, not remove) |
| Wrote a note | ✓ Yes |
| Shared content | ✓ Yes |
| Used an AI/premium feature successfully | ✓ Yes |
| Completed a task / streak / lesson | ✓ Yes |
| Opened the app | ✗ No |
| Logged in | ✗ No |
| Crashed / error path | ✗ Absolutely not |

Then gate the prompt on a milestone count so first-tap users don't get hit:

```swift
// AnalyticsService.swift (or any file already in the target)
import StoreKit
import SwiftUI

@MainActor
enum ReviewPromptService {
    private static let countKey = "engagementMomentCount"
    private static let milestones: Set<Int> = [3, 10, 25]

    static func recordHappyMoment(requestReview: RequestReviewAction) {
        let count = UserDefaults.standard.integer(forKey: countKey) + 1
        UserDefaults.standard.set(count, forKey: countKey)

        #if !DEBUG
        if milestones.contains(count) {
            requestReview()
        }
        #endif
    }
}
```

In each view that has a happy-moment trigger:

```swift
struct SomeView: View {
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        Button("Save") {
            saveTheThing()
            ReviewPromptService.recordHappyMoment(requestReview: requestReview)
        }
    }
}
```

Why milestones (3, 10, 25) and not "every time"?
- Apple throttles to 3/year regardless, so the milestones just decide WHICH 3 fire
- Milestone 3 = real engagement (not first-tap exploration)
- Milestone 10 = active user (different cohort, different time of year)
- Milestone 25 = power user (months into using the app)
- The throttle handles the rest — you can't over-ask

## Important: shared counter, multiple triggers

Don't put a separate counter on each view (e.g. `bookmarkSaveCount`, `noteSaveCount`). Use one unified `engagementMomentCount` so:
- Users who only use one feature still hit milestones at sensible cadence
- Users who use many features hit milestones faster (they should — they're more engaged)
- You don't need to coordinate logic across views

## Reply to every review

The other lever besides timing. Reply to every review. Patterns:
- Thank good reviewers (warmth, builds future loyalty)
- Help bad reviewers (often update 1★ → 5★ after you fix the issue)
- Use review themes as a product roadmap (if 20 people request the same feature, that's data)

## The email signature trick

Every reply to support email ends with:
> If you're enjoying the app, I'd be grateful for a review: [App Store link]

The user just got fast, kind help from the developer. A gentle ask in that moment converts well. Costs nothing, compounds.

Deep-link format: `https://apps.apple.com/us/app/<app-slug>/id<APP_ID>?action=write-review`

## Don't ask in these moments

- During or right after onboarding
- Right after an error, crash, or paywall hit
- During a checkout / payment flow
- Mid-task (interrupts flow)
- On a stale view returning from background

## When to bump the milestones

If your app has a high-engagement loop (e.g. daily app), milestones [3, 10, 25] hit appropriately fast. If it's a low-engagement utility (open once a month), consider [2, 5, 12] so the prompt fires before the user forgets about you.

If you're seeing low review velocity 6 months in, the issue is almost always:
1. Triggers aren't placed at actually-happy moments → audit each `recordHappyMoment` call
2. Prompts are firing but users have nothing to say → improve the underlying experience first

Don't lower milestones to compensate for a weak product. The 3-prompt cap means you only get 3 shots per user per year. Use them well.

## Reset summary rating — when (not) to use it

When you ship a new version, App Store Connect offers a checkbox to reset your overview rating. **Default: don't.** It's almost always the wrong move for indie developers.

Why:
- Once reset, you cannot restore the previous rating
- Until enough new ratings accumulate, your app shows blank stars (or "Not enough ratings"), which kills conversion
- Written reviews remain visible regardless — only the star average resets
- For an app with low review velocity, "blank stars" can persist for months

Narrow case where reset is justified:
- Your existing rating is genuinely low (≤ 3.0) AND tied to a specific issue you've now fixed
- Your install base is large enough that you'll re-accumulate ratings within weeks (not months)
- You'd rather have "not enough ratings" than a 2.8 visible to new users

Better strategy in most cases: improve the app, prompt users at happy moments, and let the rating drift up. Users can update their own ratings — and the new rating-velocity weighting (above) means recent positive reviews will outpace stale negative ones in the algorithm even if the lifetime average moves slowly.
