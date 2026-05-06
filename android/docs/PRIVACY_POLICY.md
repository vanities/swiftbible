# SwiftBible Privacy Policy

_Last updated: May 6, 2026_

SwiftBible is built and maintained by **AM2 LLC** ("we", "us"). We try to collect as little as possible, and to be honest about what we do collect.

## Summary

- We don't sell your data. We don't share it with advertisers. We don't run ads.
- The Bible texts and the app run entirely on your device. You can use the app fully without signing in.
- If you sign in (optional), donate, crash, or use the app, a small amount of data is collected for the purposes described below — all routed through standard tools (Supabase, PostHog, Sentry, Google Play). We do not have third-party advertising or marketing trackers.

## What stays only on your device

By default, none of the following ever leaves your device:

- Highlights, bookmarks, and reading history.
- Reading preferences (Bible version, theme, font, font size, accent color).
- The Bible texts themselves and any cached daily devotional content.

If you back your phone up with iCloud (iOS) or Google Drive (Android), those backups are governed by Apple's or Google's privacy practices, not ours.

## What is collected

### 1. Anonymous usage analytics (PostHog)

We send anonymous event data to **PostHog** to understand which features people use. Examples:

- Tab switches, chapters opened, search queries, settings toggled.
- Devotional viewed / saved / shared.
- Donation funnel: prompt shown, started, completed, cancelled.
- Onboarding flow: started, completed, skipped.

Each event includes the OS (`iOS` or `Android`), OS version, app version, and a randomly-generated anonymous identifier. **No name, email, location, or contact data is attached to these events.** The identifier resets if you reinstall the app.

PostHog is hosted at `us.i.posthog.com`. Read PostHog's privacy practices at https://posthog.com/privacy.

### 2. Optional sign-in (Supabase)

If you choose to sign in to sync your notes across devices, you provide an email address that we use to send a one-time login code (OTP). Your email and any verse-level notes you write are stored in our database, hosted by **Supabase**. You can delete your account by emailing us (see "Contact" below).

If you never sign in, none of this applies.

### 3. Crash reports (Sentry, iOS only)

When the iOS app crashes, a stack trace and basic device metadata (model, OS version, app version) are sent to **Sentry** so we can fix the bug. Crash reports do not include the contents of your notes, highlights, or any text you've typed. Android does not currently send crash reports.

### 4. Donations (Google Play / App Store)

If you donate through the app, the actual payment is processed by Apple (App Store) or Google (Play Store) and is governed by their respective privacy policies. We do not see your card or payment method. We do see, locally on your device, that a donation was made (the SKU and time), so the app can show your donation history and unlock donor perks. The same record is anonymized as part of the analytics events above.

## Permissions

The app requests:

- **Notifications** (optional) — only used to deliver the daily devotional reminder you opt into. If you don't enable the reminder, no notifications are scheduled.

The app does **not** request: camera, microphone, location, contacts, photos, calendar, or background location.

## Children

SwiftBible is appropriate for all ages but does not target children under 13. We do not knowingly collect data from children, and the analytics described above never include identifying information.

## Open source

The full source code for both the iOS and Android apps is publicly available, so anyone can verify these claims:

- iOS + Android: https://github.com/vanities/swiftbible

## Third-party content

The biblical texts in SwiftBible are public-domain editions:
- KJV (1611), ASV (1901), WEB (2000+)
- Apocrypha and pseudepigrapha from public-domain editions
- Original Hebrew (Masoretic) and Greek (Textus Receptus) source texts

## Your choices

- **Stop analytics**: Uninstall the app. We do not currently expose an in-app opt-out for PostHog; if you'd like one, email us and we'll add it.
- **Delete your account**: If you signed in with email, email **mischke@proton.me** and we'll remove your record from Supabase within 30 days.
- **Stop notifications**: Toggle off the Daily Reminder in Settings, or revoke notification permission in your OS settings.

## Changes

If this policy changes materially, the "Last updated" date will change and the in-app what's-new will mention it.

## Contact

Questions or deletion requests? Email **mischke@proton.me**.
