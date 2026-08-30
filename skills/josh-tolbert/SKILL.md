---
name: josh-tolbert
description: Voice reference for Josh Tolbert, a Bible-class teacher and occasional preacher at the Jackson Heights Church of Christ — the same congregation as Matt Bassford. Built from 73 transcribed lessons (~574k words, 2019–2026) — he works serially through Old Testament books (Isaiah, Nehemiah, Deuteronomy, Leviticus, Ezra, 1–2 Samuel, the Minor Prophets). Use when drafting devotionals or lessons in his voice, wanting a teacher's register (background-first, question-led, openly uncertain) rather than a pulpit register, checking a draft against how he actually teaches, or discussing his lessons. Sits beside the matt-bassford and james-edgar-green skills. Archive at speakers/josh-tolbert/.
allowed-tools: Bash(grep:*) Bash(rg:*) Bash(ls:*) Bash(wc:*) Bash(python3:*) Read
---

# Josh Tolbert

Voice reference for **Josh Tolbert**, who teaches Bible classes and occasionally preaches at the
**Jackson Heights Church of Christ** ([thebibleway.org](https://www.thebibleway.org)) — the same
congregation as [Matt Bassford](../matt-bassford/SKILL.md), for whom he sometimes substituted.

> **This is a teacher's voice, not a preacher's.** The overwhelming majority are Bible *classes*,
> and they are serial: he walks a congregation through a whole Old Testament book over months —
> the Minor Prophets (2020), Leviticus (2021), 1 Samuel (2022), 2 Samuel (2023), Ezra and Nehemiah
> (2024), Deuteronomy (2025), Isaiah (2026, ongoing). Only a handful are worship-assembly sermons.
> He walks a room through a text and takes questions; he does not build a sustained story from a
> pulpit. Use him for the classroom register.

## Corpus at a glance

| | |
|---|---|
| Transcripts on disk | 87 `.txt` files in `speakers/josh-tolbert/sermons/` |
| **Substantive lessons** | **73** (~**574,000** words), **2019-10-03 → 2026-08-23** |
| Excluded from that count | 13 aborted livestream fragments (under 1,500 words; one is 4 words) and 1 byte-identical duplicate |
| Known to exist | 107 recordings, ~86.5 hours, 2018-11-29 → 2026-08-23 (manifest) |
| Centre of gravity | book-by-book OT exposition — Isaiah 14, Leviticus 11, Deuteronomy 8, Nehemiah 7, Minor Prophets 7, Ezra 5, 2 Samuel 4, 1 Samuel 2 |
| Also | 2 hymnody classes (2021), 1 co-taught with Matt Bassford, topical sermons (*Why I Am Still a Christian*, *Paul and Felix*, *Depression with Faith*, *Fall of Babylon*, *Nicodemus*, *Avoiding Vengeance*) |
| Source | YouTube audio → `mlx_whisper` `large-v3-turbo` |

Series counts are **transcripts**, not recordings — the manifest knows of more than were
transcribed (Leviticus Pt. 4 and one Ezra class, among others).

Transcripts are **local only** (gitignored — see the archive README for why and how to rebuild).
Full detail, caveats, and the channel-wide speaker roster:
[speakers/josh-tolbert/README.md](../../speakers/josh-tolbert/README.md).

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
7. **Measured hedging** — per 10k words: `I think` 10.6, `probably` 8.4, `right?` 5.5,
   `I don't know` 4.5, `maybe` 3.6.
8. **Hands the floor to the room** — `any comments / questions / thoughts` 9.7 per 10k words, about
   eight invitations per class.
9. **Self-deprecation only at himself** — *"You guys do the math. You know, I'm not good at that."*

## References

| File | What's in it |
|---|---|
| [`references/voice.md`](references/voice.md) | The voice: measured frequencies, a 17-point fingerprint with citations, how to write it, what he is not. |
| [`references/teaching-method.md`](references/teaching-method.md) | The classroom mechanics: the shape of an hour, the five moves, and a worked example of the attribution trap. |
| [`references/themes.md`](references/themes.md) | Eight recurring themes with anchor recordings and verified quotes — plus the themes the corpus does *not* support. |
| [`references/essential-listens.md`](references/essential-listens.md) | Where to start, by use case; and the files to be careful with or skip. |
| [`references/few-shot-anchors.md`](references/few-shot-anchors.md) | Ten ready-to-paste excerpts, each tagged "use for" / "do NOT use for". |
| [`references/theology.md`](references/theology.md) | Positions, each graded *stated* / *stated once* / *implied* / *unconfirmed*. |
| [`references/biography.md`](references/biography.md) | Only what the recordings evidence, and an explicit TODO list for Adam. |

## How to use this archive

```bash
# search his teaching (handles the manifest, skips fragments, reports line numbers)
python3 .claude/skills/josh-tolbert/scripts/search.py "definition of holy"
python3 .claude/skills/josh-tolbert/scripts/search.py "remnant" --series nehemiah --top 10
python3 .claude/skills/josh-tolbert/scripts/search.py --list

# or straight to ripgrep
rg -n -i "definition of holy" speakers/josh-tolbert/sermons/
grep -rn "why am I talking to you" speakers/josh-tolbert/sermons/

# what did he teach, when
awk -F'\t' 'NR>1 && index($4,"Josh Tolbert")>0 {print $2, $6}' speakers/josh-tolbert/manifest.tsv
```

`search.py` degrades to a manifest listing when the transcripts aren't on disk, and prints the
rebuild command. Timestamped `.srt` files sit beside each `.txt` for locating a passage in the audio.

## Three things to check before quoting him

1. **The transcripts are not speaker-separated.** The classes are dialogic and other men speak at
   length. Read the surrounding lines and confirm the words are Josh's before attributing them.
   [`teaching-method.md`](references/teaching-method.md) has a real 20-line example where lines
   48–63 belong to a class member and lines 47 and 64 to Josh.
2. **The Sunday files are whole worship services** — another man's announcements, prayers, and
   congregational singing precede his lesson. In
   `20220120-sunday-pm-worship-paul-and-felix-rkuCjQw1yjk.txt` (the Acts 24 lesson) his portion
   starts at **line 169**; everything above it is hymn text.
3. **His memorable lines are mostly one-offs.** Don't inflate a single striking sentence into a
   catchphrase. What recurs are the habits, not the phrases.

Also worth knowing: the text is ASR output, so proper nouns are unreliable ("Tertullian" for
Tertullus), and *Why I Am Still a Christian* exists as two independently transcribed cuts of the
same sermon whose punctuation and small wordings differ.

## The deployed devotional prompt

`references/devotional-prompt.ts` is a **symlink** to
`supabase/functions/_shared/devotional-voice.ts` — the exact text the
`daily-devotional` edge function sends to the model. It is one file with four
paths, so it cannot drift from this skill; editing it through this symlink edits
the deployed prompt.

That file is a *distillation*, not a copy of this research — the function can't
read the repo at runtime, and the full references would swamp the prompt. When
you materially change this skill's voice or theology findings, update it.
A test in `holidays_test.ts` fails if the constants get re-inlined into
`index.ts`, which is how they drifted last time.

**Structural homage, never impersonation** — never sign, attribute, or invent a
first-person life for the author.

---

## When to use this skill

- **Drafting a lesson or devotional in a teaching register** — question-led, background-first,
  working through a text rather than around it.
- **Old Testament law, holiness, and Leviticus** — his deepest and best-documented material.
- **Post-exilic history** — Ezra and Nehemiah read as one continuous story.
- **Hymnody questions** — whether a hymn's origin or secular use bears on its use in worship.
- **Apologetics and deconstruction** — *Why I Am Still a Christian* is his most personal lesson,
  and unusually candid about which arguments never moved him.
- **Suffering and depression** — *Depression with Faith* argues against "where sadness ends, faith
  begins" by piling up scripture rather than asserting.
- **Measuring a draft against him** — does it price its claims? concede the strongest objection?
  ask before it tells?

## What this skill is NOT for

- **Inventing biography.** Only the recordings are evidence; see
  [references/biography.md](references/biography.md) for what's known and what needs Adam. His
  role, location, and even who Rachel is are all unconfirmed.
- **Filling in doctrinal positions he never argued.** [`theology.md`](references/theology.md) marks
  where the corpus runs out — instrumental music, eschatology, church organisation, and divorce and
  remarriage are all **unconfirmed**, and a Church of Christ teacher's "obvious" answer is a guess,
  not evidence.
- **Writing him as certain.** Flattening the hedges produces someone else.
- **Presenting generated text as a quotation.** He is living.
- **Blurring him into Matt or Brother Jim.** Same fellowship, three different instruments: Matt is
  wry and aphoristic on the page, Brother Jim builds one long story from the pulpit, Josh reasons
  aloud at a whiteboard.
