# Google Play Data Safety form — answers for SwiftBible

_Last updated: May 6, 2026_

This is the canonical fill-out for **Play Console → App content → Data safety**. The form can only be edited via the Play Console web UI, not the API — copy these answers in, save, and submit. Each save requires re-review by Google (~24h turnaround).

If you change what data the app collects, update this doc, then mirror the change in the form.

---

## Section 1 — Data collection and security

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (HTTPS to Supabase, PostHog, Google Play) |
| Do you provide a way for users to request that their data be deleted? | **Yes** — by emailing mischke@proton.me |

---

## Section 2 — Data types collected

For each data type, declare: **Collected? Shared? Optional? Purpose?** Always say "Not shared" unless you actually pass data to a third-party for their own use (analytics processors don't count as "shared").

### Personal info → Email address

- **Collected**: Yes
- **Shared**: No
- **Optional or required**: Optional — only if user signs in to sync notes
- **Purpose**: Account management, App functionality
- **Processed ephemerally**: No

### Financial info → Purchase history

- **Collected**: Yes
- **Shared**: No
- **Optional or required**: Optional — only if user makes a donation
- **Purpose**: App functionality, Fraud prevention, Compliance
- **Processed ephemerally**: No

### App activity → App interactions

- **Collected**: Yes
- **Shared**: No
- **Optional or required**: Required (no in-app opt-out today)
- **Purpose**: Analytics, App functionality
- **Processed ephemerally**: No

### App activity → In-app search history

- **Collected**: Yes (the search query length and result count are sent to PostHog as part of the `search_performed` event; the literal query string is **not** sent)
- **Shared**: No
- **Optional or required**: Required
- **Purpose**: Analytics, App functionality

### App activity → Other user-generated content (highlights, notes)

- **Collected**: Yes — only if user signs in to sync
- **Shared**: No
- **Optional or required**: Optional — sign-in is optional
- **Purpose**: Account management, App functionality
- **Processed ephemerally**: No

### Device or other IDs → Device or other IDs

- **Collected**: Yes — PostHog assigns a random anonymous ID per install
- **Shared**: No
- **Optional or required**: Required
- **Purpose**: Analytics

---

## Section 3 — Data NOT collected (declare these as "No")

- Approximate / precise location
- Photos / videos / audio files
- Files / documents
- Calendar / contacts
- Health / fitness / medical info
- Web browsing history (outside the app)
- App diagnostics (crash logs, performance) — _Android does not send crash reports today; iOS does via Sentry, but this Play form is Android-only_
- Voice / sound recordings
- Race / ethnicity / sexual orientation / political or religious beliefs / etc.

---

## Section 4 — Security practices

| Question | Answer |
|---|---|
| Is data encrypted in transit between user device and your servers? | **Yes** |
| Do you provide a way to request data deletion? | **Yes** (email contact) |
| Have you committed to following Play's Families Policy? | **No** (app does not target children) |
| Independent security review? | **No** (skip if not applicable) |

---

## Section 5 — Privacy policy URL

```
https://am2.biz/swiftbible
```

(Make sure that page is the live, public privacy policy — i.e., the contents of `android/docs/PRIVACY_POLICY.md` rendered to HTML. If the page redirects, Play will mark the listing as "non-compliant".)

---

## After submission

1. Form goes into review (~24h, sometimes faster).
2. While in review, the app remains live; the new declarations don't apply until accepted.
3. If rejected, Google emails the developer account holder with the specific data type that was inconsistent. Common rejection: "App activity declared as not collected, but observed analytics SDK". Update this doc + the form together.

---

## Why we collect what we collect

| Data | Why |
|---|---|
| PostHog events | Understand which features matter, prioritize improvements, debug funnels (donation, onboarding) |
| Email (sign-in) | Sync notes across devices for users who opt in |
| Donation history | Show user their giving over time; unlock donor perks |
| Random install ID | Distinguish events from different users without identifying them |

We don't use any of this for advertising, profiling, or third-party sales.
