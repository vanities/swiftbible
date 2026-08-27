---
name: josh-tolbert
description: Voice reference for Josh Tolbert, a Bible-class teacher and occasional preacher at the Jackson Heights Church of Christ — the same congregation as Matt Bassford. Built from 64 recordings (~396k words, 2021–2026) — he works serially through Old Testament books (Isaiah, Nehemiah, Deuteronomy, Leviticus, Ezra). Use when drafting devotionals or lessons in his voice, wanting a teacher's register (background-first, question-led, openly uncertain) rather than a pulpit register, checking a draft against how he actually teaches, or discussing his lessons. Sits beside the matt-bassford and james-edgar-green skills. Archive at speakers/josh-tolbert/.
allowed-tools: Bash(grep:*) Bash(rg:*) Bash(ls:*) Bash(wc:*) Read
---

# Josh Tolbert

Voice reference for **Josh Tolbert**, who teaches Bible classes and occasionally preaches at the
**Jackson Heights Church of Christ** ([thebibleway.org](https://www.thebibleway.org)) — the same
congregation as [Matt Bassford](../matt-bassford/SKILL.md), for whom he sometimes substituted.

> **This is a teacher's voice, not a preacher's.** The overwhelming majority are Bible *classes*,
> and they are serial: he walks a congregation through a whole Old Testament book over months —
> Leviticus (2021), Ezra, Nehemiah (2024–25), Deuteronomy (2025), Isaiah (2026, ongoing).
> Only a handful are worship-assembly sermons. He walks a room through a text and takes
> questions; he does not build a sustained story from a pulpit. Use him for the classroom register.

## Corpus at a glance

| | |
|---|---|
| Recordings | 64 (~396,000 words), 2021 → 2026 |
| Centre of gravity | book-by-book OT exposition: Isaiah 15, Nehemiah 17, Deuteronomy 9, Leviticus 9, Ezra 3 |
| Also | 2 hymnody classes, 1 co-taught with Matt Bassford, topical sermons (*Why I Am Still a Christian*, *Paul and Felix*, *Depression with Faith*) |
| Source | YouTube audio → `mlx_whisper` `large-v3-turbo` |

Transcripts are **local only** (gitignored — see the archive README for why and how to rebuild).
Full detail, caveats, and the channel-wide speaker roster:
[speakers/josh-tolbert/README.md](../../../speakers/josh-tolbert/README.md).

## The voice in one paragraph

A curious, self-auditing teacher who tells you the confidence level of everything he says. He
earns a passage by reconstructing the world around it first, prices his sources out loud, opens by
asking the class to define the term before he does, and is unembarrassed about not knowing. He
critiques his own tradition from inside it, dismantles positions he used to hold, and aims all his
deprecation at himself. The hedging is not weakness in the voice — it *is* the voice.

Full breakdown with measured frequencies: [references/voice.md](references/voice.md).

## Top tells

1. **The learn-something rule** — *"I have this rule anytime that I preach or anytime that I teach
   that I have to learn something. Otherwise, why am I talking to you?"*
2. **Background before text** — the political and historical world first, the passage read through it.
3. **Priced sources** — cites Josephus, then notes Josephus exaggerates, then re-runs the number at
   10% of the claim.
4. **Socratic opening** — *"What is a good definition to you?"* before he supplies one.
5. **"Whose definition?"** — *"the danger of using my definition of blameless rather than trying to
   fit with God's definition."*
6. **Audits his own tradition** — of a stock slogan: *"Which is not always true, even though we have
   good intentions when we say that."*
7. **Measured hedging** — per 10k words: `I think` 9.8, `right?` 5.2, `I don't know` 4.1.
8. **Self-deprecation only at himself** — *"You guys do the math. You know, I'm not good at that."*

## How to use this archive

```bash
# search his teaching
rg -i "definition of holy" speakers/josh-tolbert/sermons/
grep -rn "why am I talking to you" speakers/josh-tolbert/sermons/

# what did he teach, when
awk -F'\t' 'NR>1 && index($4,"Josh Tolbert")>0 {print $2, $6}' speakers/josh-tolbert/manifest.tsv
```

Timestamped `.srt` files sit beside each `.txt` for locating a passage in the audio.

## Three things to check before quoting him

1. **The transcripts are not speaker-separated.** The classes are dialogic and other men speak at
   length. Read the surrounding lines and confirm the words are Josh's before attributing them.
2. **The Sunday files are whole worship services** — another man's announcements, prayers, and
   congregational singing precede his lesson. In the Acts 24 file his portion starts around line 169.
3. **His memorable lines are mostly one-offs.** Don't inflate a single striking sentence into a
   catchphrase. What recurs are the habits, not the phrases.

## When to use this skill

- **Drafting a lesson or devotional in a teaching register** — question-led, background-first,
  working through a text rather than around it.
- **Old Testament law, holiness, and Leviticus** — his deepest and best-documented material.
- **Hymnody questions** — whether a hymn's origin or secular use bears on its use in worship.
- **Apologetics and deconstruction** — *Why I Am Still a Christian* is his most personal lesson,
  and unusually candid about which arguments never moved him.
- **Measuring a draft against him** — does it price its claims? concede the strongest objection?
  ask before it tells?

## What this skill is NOT for

- **Inventing biography.** Only the recordings are evidence; see
  [references/biography.md](references/biography.md) for what's known and what needs Adam. His role,
  location, and even who Rachel is are all unconfirmed.
- **Writing him as certain.** Flattening the hedges produces someone else.
- **Blurring him into Matt or Brother Jim.** Same fellowship, three different instruments: Matt is
  wry and aphoristic on the page, Brother Jim builds one long story from the pulpit, Josh reasons
  aloud at a whiteboard.
