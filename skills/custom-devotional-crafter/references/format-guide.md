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
  ]
}
```

## Testament mapping

- `old`: Genesis through Malachi
- `new`: Matthew through Revelation

When mixed references are used, set `testament` to the first primary scripture's testament.
