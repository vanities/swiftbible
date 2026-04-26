# Custom Devotional Format Guide

## Recommended Markdown structure

Use this section order for consistency in app rendering:

1. `# Title`
2. `## Scripture Focus`
3. `## Reflection`
4. `## Application`
5. `## Prayer`
6. `## Reflection Questions`

## Reflection question style

- Prefer 3 concise questions.
- Keep questions action-oriented and introspective.
- Avoid yes/no-only questions.

## Payload schema for Supabase

```json
{
  "for_date": "2026-04-26",
  "message": "# ...markdown...",
  "testament": "new",
  "devotional_type": "custom",
  "verses": [
    { "book": "Romans", "chapter": 5, "verse": 3, "testament": "new" }
  ],
  "series_name": "Extreme Faith",
  "series_part": 1
}
```

`series_name` and `series_part` are optional. When set, the iOS app renders a context line under the date picker (e.g. *"Extreme Faith · Week 1"*) so readers know which series the devotional belongs to. Holiday and AI-generated devotionals use `holiday_name`/`holiday_url` and `anchor_verse` respectively — those are populated by the Edge Function, not by this skill.

## Testament mapping

- `old`: Genesis through Malachi
- `new`: Matthew through Revelation

When mixed references are used, set `testament` to the first primary scripture's testament.
