---
name: custom-devotional-crafter
description: Create, refine, and publish custom (hand-authored) daily devotionals for SwiftBible. Use when the user wants help drafting a devotional with verse selection, structure checks, or refining tone — and when they want to upsert it into the Supabase `Daily Devotional` table with `devotional_type: "custom"`.
allowed-tools: Bash(python3:*), Read, Write, Edit
---

# Custom Devotional Crafter

Author and publish hand-crafted devotionals for SwiftBible. Bundled scripts live alongside this `SKILL.md` under `scripts/` — invoke them by their skill-relative paths so this works whether the skill is loaded from the SwiftBible repo or via symlink in `~/.claude/skills/`.

## 1) Gather essentials

Ask the user for:
- `for_date` in `YYYY-MM-DD`
- Theme / big idea
- Audience (general, youth, grief, leadership, etc.)
- Tone (pastoral, encouraging, prophetic, reflective)
- 1+ Bible references (or offer 5–10 suggestions if they don't have any)

## 2) Compose a draft

Run the composer script bundled with this skill (`scripts/compose_custom_devotional.py`):

```bash
python3 scripts/compose_custom_devotional.py \
  --for-date 2026-04-26 \
  --theme "Hope after disappointment" \
  --audience "General" \
  --tone "Encouraging" \
  --verse "Romans 5:3-5" \
  --verse "Psalm 34:18" \
  --output /tmp/custom-devotional.json
```

The output JSON has markdown content and `devotional_type: "custom"`.

## 3) Review with the user

Before publishing, walk through:
- Opening hook relevance to the theme
- Scripture alignment and theological accuracy
- Practical application clarity
- Reflection question quality (3 concise, action-oriented)
- Prayer specificity

Iterate on the markdown directly in the JSON file until approved.

## 4) Publish to production

When approved, run the publisher script:

```bash
SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... \
  python3 scripts/push_custom_devotional.py --file /tmp/custom-devotional.json
```

Always run with `--dry-run` first to confirm the endpoint and payload before sending.

The script upserts on `for_date`, so re-running for the same date overwrites the previous entry.

## 5) Safety checks

- Confirm `for_date` matches what the user actually wants (typos overwrite the wrong day).
- Never publish without explicit user approval of the final markdown.
- `devotional_type` must be `custom` — the publisher refuses anything else.
- The iOS app keys off `devotional_type` to render the "Custom" badge instead of the AI-generated badge. Don't change the type unless you mean to change the UI affordance too.

## References

- `references/format-guide.md` — payload schema, section ordering, testament mapping.
