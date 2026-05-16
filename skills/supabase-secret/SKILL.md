---
description: Set, unset, or list Supabase Edge Function secrets for SwiftBible without changing code. Use when bumping LLM models (DEVOTIONAL_MODEL / VERSE_SELECTION_MODEL), rotating API keys, or any other env-var override on the daily-devotional function. Always prefer this over editing default constants in index.ts.
disable-model-invocation: true
argument-hint: [KEY=value | --unset KEY | --list]
allowed-tools: Bash(supabase secrets:*) Bash(supabase status:*)
---

# SwiftBible Supabase secrets

Project ref: `yvanxjoayoiocwzfpkfm`

This skill is the **canonical way** to change a Supabase Edge Function env var
for SwiftBible. Code defaults in `supabase/functions/daily-devotional/index.ts`
exist only as a fallback when the secret is unset. Bumping a model or rotating
a key should always go through this skill — never via committed default
changes, which require a redeploy and create unnecessary churn.

## Known overridable secrets

| Key | Code default | Purpose |
|-----|--------------|---------|
| `DEVOTIONAL_MODEL` | `gpt-5.4` | Main model for devotional writing (`generateDevotional`) |
| `VERSE_SELECTION_MODEL` | `gpt-5.4-mini` | Cheap model for verse picking (`selectMultiVerses`, multi only) |
| `OPENAI_API_KEY` | (required, no default) | OpenAI auth — sensitive, ask before changing |
| `SUPABASE_URL` | (auto, set by platform) | Supabase project URL — do not change |
| `SUPABASE_SERVICE_ROLE_KEY` | (auto, set by platform) | Internal service role — do not change |
| `SENTRY_DSN` | (none) | Sentry error reporting endpoint |

When the user asks for any other env var that isn't in this table, set it
anyway but flag it as not-yet-documented and suggest adding it.

## Behavior by argument

### `--list` (or no arguments)

Run `supabase secrets list --project-ref yvanxjoayoiocwzfpkfm` and show the
result. Note: Supabase masks values; only names + digests are visible.

### `KEY=value` (e.g. `DEVOTIONAL_MODEL=gpt-5.5`)

Run:

```bash
supabase secrets set KEY=value --project-ref yvanxjoayoiocwzfpkfm
```

For the API-key-style sensitive values (`OPENAI_API_KEY`, etc.), confirm with
the user before setting if the value would be visible in the conversation.
Edge Functions read env vars at runtime, so changes take effect on the next
function invocation — no redeploy needed.

### `--unset KEY`

Run:

```bash
supabase secrets unset KEY --project-ref yvanxjoayoiocwzfpkfm
```

After unsetting, the function falls back to the code default for that key.

## Workflow

1. Parse `$ARGUMENTS` for one of the three forms above.
2. Execute the appropriate `supabase secrets` command.
3. Confirm success. Report back which key changed and (for set) the new value.
4. Suggest a verification step: trigger a generation with `make test_daily_devotional` (or the same `curl` with `forDate`) and check the resulting row's `model` column to confirm the override took effect.

## Examples

```text
/supabase-secret DEVOTIONAL_MODEL=gpt-5.5
  → sets the secret; next AI generation uses gpt-5.5.

/supabase-secret VERSE_SELECTION_MODEL=gpt-5.4-mini
  → ensures verse selection stays on the cheap model.

/supabase-secret --unset DEVOTIONAL_MODEL
  → removes the override; falls back to the code default.

/supabase-secret --list
  → lists every secret currently set on the project (names only).
```

## Why this exists

Earlier in the project's history, model bumps were attempted by editing the
default in `index.ts` and redeploying. That created multi-commit churn for what
is fundamentally a config change. The env-var override pattern was added to
the constants in 2026-05 specifically so this skill could exist and code
defaults could remain stable across model experiments.

## Reference

- Supabase CLI docs: https://supabase.com/docs/reference/cli/supabase-secrets
- Edge Function env reading: `Deno.env.get("KEY") ?? "fallback"` pattern in `supabase/functions/daily-devotional/index.ts`
