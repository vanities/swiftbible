# App Preview Videos

App preview videos are 15-30 second autoplay clips that appear in search results, on your product page, and in CPPs. Industry data: well-made previews lift conversion 20-35% vs no video. Done badly, they hurt — autoplay bias means the first impression is unskippable.

## What's mandatory vs optional

- App preview video is OPTIONAL — Apple does not require one
- If you submit one, it autoplays MUTED in search results — no audio cushion
- You can submit up to 3 per device size per locale
- The first preview is the primary; the others fall back

## Apple's specs (current as of 2026)

Apple is strict on aspect ratios — submissions get rejected for the wrong dimensions. Always cross-check the App Store Connect spec table before exporting.

| Device | Resolution (portrait) | Max length | File size cap |
|---|---|---|---|
| iPhone 6.9" | 886 x 1920 (or 1080 x 1920) | 30s | 500MB |
| iPhone 6.5" | 886 x 1920 | 30s | 500MB |
| iPad 13" | 1200 x 1600 | 30s | 500MB |

## The first 3 seconds

Search-results autoplay = silent + tiny. If your first 3 seconds are:
- Splash screen / logo animation → user scrolls past
- Loading state / blank UI → user scrolls past
- A face talking with no captions → user scrolls past (no audio)

Lead with the SINGLE most visually compelling moment of the app. The grid-based habit view animating in. The verse text fading to a translation switcher. The streak counter ticking up. Whatever your slot #1 screenshot would be — show it MOVING.

## Structure that converts

A 15-25 second preview that beats most:

| Time | What |
|---|---|
| 0-3s | Hook — the most compelling visual feature, in motion |
| 3-10s | Show 1-2 supporting features, with bold caption text |
| 10-20s | One emotional / outcome moment ("Your notes, every device") |
| 20-25s | Logo / app name (NOT the first thing — the LAST) |

Keep it under 25s if possible. Apple allows 30s but watch-rates fall off a cliff after ~20s in autoplay contexts.

## Captions in the video

Autoplay is muted by default. Captions ARE the message. Two rules:
1. Big, high-contrast text — readable at thumbnail size in search results
2. Same outcome-language as screenshot headlines — "Easy on your eyes" not "Dark mode"

## What NOT to do

- Don't show iOS chrome (status bar, home indicator) animating — Apple may reject
- Don't show prices or "Free" or "Download now" — Apple may reject
- Don't film a face speaking without captions — autoplay is muted, you're just showing a silent face
- Don't include trademarked content (other apps, brands, music)
- Don't use unreleased features — Apple's review must be able to verify the app does what the video shows

## Capture workflow for SwiftUI apps

```bash
# Record from a booted simulator
xcrun simctl io booted recordVideo --codec=h264 --type=mp4 preview.mp4

# Stop with Ctrl+C. Trim and add captions in iMovie or Final Cut.
```

For repeatable / automated previews, build a script around `xcrun simctl` + `ffmpeg` + a captions overlay step. If `generate_marketing_screenshots.py` exists in the repo, model the preview pipeline on it.

## A/B test before committing

PPO supports preview-video testing. If you've never had a video before, A/B test "with video" vs "no video" first to confirm a lift in your specific category. Then iterate on the variants.

## Localization

Subtitle text and on-screen text should be localized. Two paths:
- **Cheap**: same visual track, locale-specific captions
- **Premium**: locale-specific recordings showing localized app UI

Use cheap path first; upgrade to premium for high-revenue locales where the app actually localizes.
