---
name: custom-devotional-crafter
description: Create, refine, and publish custom devotionals for SwiftBible production data. Use when users want guided devotional drafting (questions, verse selection help, structure checks) and/or need to upsert custom devotionals into Supabase production.
---

# Custom Devotional Crafter

Use this workflow to help users author high-quality custom devotionals and publish them safely.

## 1) Gather essentials first

Ask for (at minimum):
- `for_date` in `YYYY-MM-DD`
- Theme / big idea
- Audience (general church, youth, grief, leadership, etc.)
- Desired tone (pastoral, encouraging, prophetic, reflective)
- 1+ Bible references (or ask me to suggest)

If verses are missing, propose 5-10 options and ask the user to pick final references.

## 2) Draft in app-ready format

Run:

```bash
python3 skills/custom-devotional-crafter/scripts/compose_custom_devotional.py \
  --for-date 2026-04-26 \
  --theme "Hope after disappointment" \
  --audience "General" \
  --tone "Encouraging" \
  --verse "Romans 5:3-5" \
  --verse "Psalm 34:18"
```

This produces:
- Markdown devotional content with predictable sections
- JSON payload ready for Supabase (`devotional_type: "custom"`)

## 3) Collaborate and refine

Before publishing, review with the user:
- The opening hook relevance
- Scripture alignment and theological accuracy
- Practical application clarity
- Reflection questions quality
- Prayer specificity

## 4) Publish to production

When approved, save payload to a file (example `custom-devotional.json`) and run:

```bash
python3 skills/custom-devotional-crafter/scripts/push_custom_devotional.py \
  --file custom-devotional.json
```

Required env vars:
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

The script upserts into `Daily Devotional` on `for_date`, preserving one devotional per day.

## 5) Safety checks

- Default to `--dry-run` first for confirmation.
- Never publish without explicit user approval.
- Ensure `devotional_type` is `custom` for user-authored entries.
- Confirm the exact date being edited to avoid accidental overwrite.

## References

- For payload shape and section standards, read: `references/format-guide.md`.
