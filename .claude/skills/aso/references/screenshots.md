# Screenshots

Apple lets you upload 3-10 screenshots per device size. Most users never swipe past #3. Front-load ruthlessly.

**Major change (June 2025)**: Apple now uses OCR to extract text from screenshot captions and treats it as keyword metadata for search ranking. Captions are no longer just conversion copy — they are an indexed keyword surface. Every line of caption text now does double duty: it has to convert, AND it has to land target keywords.

This rewrites the old "feature → outcome" headline rule into a unified rule: **outcomes that contain target keywords**.

## The first frame

It is the difference between a download and a scroll-past. Two rules:

1. **Most visually impressive feature** — not a generic list, not onboarding, not a settings screen
2. **Differentiating** — something other apps in your category don't have

For a habit-tracking app it might be the grid-based habit view (unique + colorful). For a Bible app it might be the translation switcher (if you have Hebrew/Greek), an AI explanation popup, or a unique reading mode.

If your first screenshot is "list of items in your app," you are wasting it.

## Slot ordering (default playbook)

| Slot | Job | Lever |
|---|---|---|
| 1 | Hook — visually impressive, differentiating | Primacy |
| 2 | Visual contrast (different layout/color from #1) | Isolation |
| 3 | Daily value — the ongoing benefit | Habit anchoring |
| 4 | Trust — depth, breadth, or social proof | Competence signal |
| 5-7 | Features framed as outcomes (with keywords) | Coverage |
| 8 | Emotional close (no CTA) | Peak-End |

## Caption rules — post-OCR (Jun 2025+)

Apple's OCR appears to read text in the top and bottom regions of screenshots most reliably. Center text inside the device frame is less reliably extracted.

Rules:
- Place caption text in the top OR bottom band of the frame, not middle-overlay on the device
- Use high-contrast text (e.g. white on dark band, or dark on light) — OCR fails on low-contrast text
- Use legible fonts at large sizes — anything under ~28pt at 6.9" iPhone resolution risks OCR failure
- Each screenshot's caption should focus on ONE keyword theme — don't try to cram 5 keywords per frame
- Keywords in captions REINFORCE keywords in name/subtitle/keyword field — repetition across surfaces now boosts rankings rather than diluting them

### The unified outcome+keyword rule

Old rule (pre-2025): outcome > feature. "Easy on Your Eyes" beats "Dark Mode Support".

New rule (post-2025): outcome that *contains* the target keyword. Best of both.

| Bad (feature-only) | Old-school (outcome-only) | New (outcome + keyword) |
|---|---|---|
| Dark Mode Support | Easy on Your Eyes | Easy-on-Your-Eyes Dark Mode |
| iCloud Sync | Your Notes, Every Device | Your Notes Synced via iCloud |
| Multiple Translations | Three Translations. Your Choice. | KJV, ASV, WEB — Your Translation |
| Customizable Dashboard | See Everything That Matters | Your Habit Dashboard, Your Way |
| AI-Powered Explanations | Understand Any Verse | AI Verse Explanations, Instant |
| Offline Mode | Read Anywhere | Offline Bible Reading |

Rules for the new caption:
- 8 words max
- Lead with verb or outcome where possible
- Include the keyword you want this screenshot to reinforce
- Plain language, postage-stamp test (readable at thumbnail size?)
- Don't keyword-stuff to the point of breaking the outcome framing — both jobs matter

## A/B testing

Apple Product Page Optimization (PPO) lets you test up to 3 alternate "treatments" against your default page. See [product-pages.md](product-pages.md) for setup details and the relationship to Custom Product Pages.

Key warnings:
- "Professionally redesigned" treatments OFTEN LOSE against authentic self-made originals. Test, never assume.
- Don't test multiple variables at once (you won't know what moved the needle)
- Don't test during a metadata change (separate the keyword variable from the visual variable)

What to test:
- Slot #1 candidates (highest leverage)
- Caption text — feature vs outcome vs outcome+keyword framing
- Layout (hero vs split vs panoramic)
- Color/background tint
- With/without device frame

## Capture workflow

For a Swift/SwiftUI app, automate with UI tests:

```bash
xcodebuild test -project YourApp.xcodeproj -scheme YourApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:YourAppUITests/ScreenshotTests
```

Required device sizes (current Apple requirements as of 2026):

| Device | Size | Resolution (portrait) |
|---|---|---|
| iPhone | 6.9" | 1320 x 2868 |
| iPhone | 6.5" | 1284 x 2778 |
| iPad | 13" | 2048 x 2732 |
| Apple Watch | 46mm (if app exists) | 416 x 496 |

iPhone 6.9" is mandatory; others scale from it. Capture light AND dark variants if your app supports both — use the dark one when it shows the feature better.

## Compositing

Raw simulator captures need device frames + headlines + backgrounds. Two paths:

1. **Python + Pillow script** (preferred for repeatability, version control, batch updates)
2. **Sketch/Figma templates** (better for one-off creative work, harder to regenerate)

If a `generate_marketing_screenshots.py` already exists in `appstore/` or `scripts/`, READ IT FIRST and modify the config arrays — don't rewrite the rendering code.

## Layout mix

Don't use the same layout for every frame — variety holds attention.

| Layout | Use for |
|---|---|
| **Hero** | Single large device, overflows bottom edge. Scale 0.82-0.92. Best for slot #1. |
| **Halved** | Vertical split (light/dark, before/after). Zero dead space. |
| **Panoramic pair** | Two devices share continuous background, offset 30-35% from cut. |
| **Tilted** | Single device at 3-5°. Pattern breaker for mid-deck slots. |

## Audit checklist (run on every render)

Open every generated PNG. Don't trust the script.

- [ ] Caption in top OR bottom band (OCR-friendly), not center-overlaid on device
- [ ] Caption text high-contrast and large (≥28pt at 6.9" resolution)
- [ ] Caption contains the target keyword for that screenshot's theme
- [ ] No clipped text
- [ ] No dead space (device fills bottom or overflows)
- [ ] Readable at thumbnail size
- [ ] Each frame stands alone
- [ ] Consistent palette across the set
- [ ] Visual variety in layouts
- [ ] First screenshot is unique + visually impressive (not a list)
- [ ] No "Free", pricing, "Download now" copy
- [ ] No fake iOS UI elements
- [ ] No Apple trademarks visible
- [ ] 70/30 imagery-to-text ratio
