# Matt Bassford — the preaching voice

Everything else in this skill is built from **1639 blog posts**. This file is built from
**66 solo sermons and classes (453,280 words), Nov 2020 – Aug 2022**, transcribed from the
Jackson Heights congregation's YouTube channel. Transcripts live at `speakers/matt-bassford/sermons/` — **local only, gitignored**; rebuild them
with the runbook in [`speakers/README.md`](../../../speakers/README.md).

**The spoken voice is not the written voice.** Do not assume the blog tells transfer to the pulpit;
several of them do not. Use [voice.md](voice.md) when writing prose in his manner, and this file
when you want how he *taught a room*.

## Why this window matters

The recordings run Nov 2020 → Aug 2022 (earliest recording 11/22/20; the last two are the Aug 2022
"Unity" Bible classes). His ALS diagnosis lands in **July 2021**, squarely inside that range, and his
final Jackson Heights sermon was preached Aug 28, 2022 (published as `2022-09-13-the-bible.md`). So this corpus
captures the same arc [late-voice.md](late-voice.md) traces through his writing — except here you
can hear it. The illness enters the sermons as *logistics*, stated flatly and without self-pity,
mid-argument: **"For the sake of my voice, I'm going to skip on down to verse 46."**
(`20220302-sunday-am-worship-if-christ-is-raised-9IsN5c1sH8U.txt`) No comment on
it, no pause for sympathy; he simply routes around a failing body and keeps preaching.

That is the single most characteristic thing in the spoken corpus, and it matches the written
late voice exactly: the fact is named, then set down, and the work continues.

## Written voice vs spoken voice

| | Blog | Pulpit |
|---|---|---|
| Structure | aphoristic; turns on one sentence | **architectural**; enumerated consequences |
| Openings | concrete domestic detail | credits last week's preacher, then differentiates |
| Person | first-person confession, freely | almost none; "we" and "brethren" |
| Closings | 3–5 verdict imperatives | returns to the conditional he opened with |
| Register | wry, compressed, sometimes bleak | patient, warm, teacherly |
| Humour | dry, frequent | present but rarer; never at the text's expense |

The compression that defines his prose is largely **absent** when he preaches. He has forty minutes
and he uses them: long passages read aloud in full, then unpacked.

## Measured spoken tells

Rates per 10,000 words across the 66 solo recordings (453,280 words). Counted case-insensitively
with the regex in the right-hand column. The denominator includes whole-service material
(announcements, singing), so treat these as lower bounds.

| Tell | Count | per 10k | Regex |
|---|---:|---:|---|
| `brethren` | 120 | 2.6 | `\bbrethren\b` |
| `the first/second/third of these` | 27 | 0.6 | `\b(first\|second\|third\|fourth\|fifth) of these\b` |
| `turn with me` / `turn to` | 33 | 0.7 | `\bturn (with me\|to)\b` |
| `look with me` | 18 | 0.4 | `\blook with me\b` |
| `notice that` / `notice how` | 19 | 0.4 | `\bnotice (that\|how)\b` |

**`brethren` is the signature.** It is his default address to the congregation and essentially
absent from the blog. If you are writing spoken-Matt and not reaching for it, you are writing
blog-Matt.

## The sermon architecture

1. **Locate the lesson in the congregation's ongoing conversation.** He opens by crediting the
   previous week by name and saying how today differs — *"Last week, Clay did a good job of
   emphasizing… This morning, though, I want to go in a slightly different direction."* The
   congregation's teaching is a shared, continuing project and he speaks inside it.
2. **State the thesis as a conditional with everything riding on it** — *"If indeed Christ has been
   raised from the dead, then everything changes."*
3. **Enumerate the consequences of that conditional**, each announced before it is argued:
   *"The first of these that I want us to consider is that if Christ is raised, then he is a true
   prophet."* The sermon is a chain of entailments, not a list of topics.
4. **Bring the room into the text with precise boundaries** — *"Look with me at… Deuteronomy chapter
   18, and there we'll consider verses, I'll start in verse 17, verses 17 through 22."* He names the
   exact range, then reads it in full.
5. **Corroborate inspiration with ordinary reasoning.** Having read an inspired test, he checks it
   against common sense — *"Even though the test that we see here is inspired, I think this is a
   test that makes perfect sense from a common sense level"* — then illustrates from ordinary life
   (weather forecasters with advanced degrees who still cannot predict the future).
6. **Return to the conditional.** The close restates the opening "if," now loaded with everything
   established.

## Writing spoken-Matt

- Open by placing the lesson in a continuing conversation, crediting someone by name.
- Put the whole weight on one conditional and say so at the top.
- Enumerate. Announce each consequence before arguing it.
- Say *"Look with me at…"* and name the exact verse range.
- Corroborate the text with plain reasoning and a mundane illustration.
- Address the room as *brethren*.
- If a limitation intrudes, name it in one clause and move on. Never dwell, never apologise.

## Caveats

1. **22 of the 88 transcripts have more than one speaker** and are excluded from everything above.
   19 are with Clay Gentry — the 13 titled "The Matt and Clay Show" plus the joint "Introduction to
   Romans" evenings and the Esther classes; 1 is with Josh Tolbert; 2 are singing nights with Ben
   Prasser (one also with Mike Young). None of them can be used for voice work — Whisper does not
   diarize, so Matt's words and the other speaker's are indistinguishable in the text. Speaker
   attribution comes from the `speakers` column of `speakers/josh-tolbert/manifest.tsv`, keyed on
   the YouTube id at the end of each transcript filename.
2. **Even "solo" recordings are whole worship services.** A file labelled Matt opens with another
   man's announcements, prayers, and congregational singing. His sermon often starts hundreds of
   lines in — in the Mar 2022 recording, around line 490 of 823. Locate the sermon before quoting.
3. **Verify any quote against its surrounding lines.** The speaker label says who preached, not who
   is speaking on a given line.
4. Rates above are not comparable to the blog corpus — different medium, different denominator.
5. **His memorial service is not in this corpus, and must not be added.** The channel hosts a
   recording of the memorial service held for Matt on 2023-11-04. The manifest resolver credits it
   to "Matt Bassford" because his name is in the description — but he is its *subject*, not its
   speaker, and it is 81 minutes of other people speaking about him. Including it would attribute
   their words to him and corrupt every measurement here. It is kept outside the repo at
   `~/.cache/swiftbible-speakers/excluded/`. **A corpus rebuild will re-resolve it as his — drop it
   again.** It is still usable as a *biographical* source — the obituary read aloud in it is the
   only record of his birth and death dates (see [biography.md](biography.md)) — but never as a
   voice source.
