---
name: church-of-christ
description: Researched reference for the Churches of Christ (the Stone–Campbell / American Restoration Movement) — history, hermeneutics, doctrine, the movement's divisions, the non-institutional branch specifically, culture and politics, institutions, and a passage-by-passage scripture index. Use when drafting devotional or teaching content in this tradition, checking whether a draft assumes something the tradition doesn't hold, writing in the voice of Matt Bassford, Josh Tolbert, or James Edgar Green (all non-institutional Churches of Christ), or answering a question about what this tradition believes and why. Every claim is confidence-tagged and sourced; the tradition's internal disagreements are marked rather than flattened.
allowed-tools: Bash(grep:*) Bash(rg:*) Bash(ls:*) Bash(wc:*) Read
---

# Churches of Christ

Reference for the tradition behind the three speaker skills in this repo —
[matt-bassford](../matt-bassford/SKILL.md), [josh-tolbert](../josh-tolbert/SKILL.md), and
[james-edgar-green](../james-edgar-green/SKILL.md). All three men are **non-institutional**
Churches of Christ, which is a minority within a minority. Most general writing about "the
Churches of Christ" describes the mainstream institutional churches instead, and applying it
to their voices will put assumptions in their mouths they did not hold.

> **This file is orientation only.** It is deliberately short. The substance lives in
> `references/`, which is loaded on demand — go there before writing anything that makes a
> factual or doctrinal claim.

---

## Confidence markers — used throughout `references/`

Every branch of this movement writes tendentious history about its opponents. That is itself
a documented fact about the field, and the reason claims carry a tag:

| Tag | Meaning | How it may be used in a draft |
|---|---|---|
| **F** | Established fact — dated document, census return, uncontested record | State it plainly |
| **S** | Mainstream scholarly interpretation — an argument, not a datum | "Historians generally argue…" |
| **C** | Contested between branches — each side tells it differently | Name both sides, or "in this tradition's telling" |
| **?** | Unverified in this research | **Do not use until checked** |

Each file also ends with a Sources section separating **scholarly** from **partisan** sources.
Partisan does not mean useless — the movement's periodicals are often the only record of an
event — but it means the framing is a party's, not a historian's.

---

## The references

| File | Use it for |
|---|---|
| [`history.md`](references/history.md) | The narrative, 1790s→present: Stone and Campbell, the 1832 union, the restoration ideal's actual intellectual debts, the Civil War fracture, 1906, the 20th century, the historiography of who writes these accounts |
| [`timeline.md`](references/timeline.md) | The same material as ~140 dated rows, each with a "why it matters," plus the rows most often gotten wrong |
| [`hermeneutics.md`](references/hermeneutics.md) | **How this tradition reads the Bible** — CENI, the silence principle, the three dispensations, generic vs. specific authority, why the argumentation reads like a legal brief, and the internal hermeneutics debate |
| [`doctrine.md`](references/doctrine.md) | The positions themselves — plan of salvation, the rejection of Calvinism, worship, ecclesiology, eschatology, and the live disputed questions — each with its scriptures, its internal disagreements, and how it differs from broader Christendom |
| [`scripture-index.md`](references/scripture-index.md) | Passage → what it establishes → the argument → the principal counter-reading. ~130 references, all verified against the KJV bundled in this repo |
| [`divisions.md`](references/divisions.md) | The fractures: 1906, premillennial, one-cup, non-class, the 1950s institutional division, the ICOC, and the current mainstream fault lines |
| [`non-institutional.md`](references/non-institutional.md) | **Start here for Matt, Josh, and Brother Jim.** What the branch holds, why, what the objection is *not*, where they divide internally, and a writing checklist |
| [`culture-and-politics.md`](references/culture-and-politics.md) | Demographics and the decline, geography, race and the separate African American Churches of Christ, what surveys actually measure about politics, the abandoned pacifist inheritance, social positions taught vs. practiced, and a vocabulary table |
| [`institutions.md`](references/institutions.md) | Colleges, preacher schools, periodicals, missions and benevolence, lectureships and hymnody — with branch affiliation and current status |

---

## The eight things most often gotten wrong

Each is treated at length in the file named.

1. **Three bodies, one root.** Churches of Christ (a cappella), the Independent Christian
   Churches, and the Disciples of Christ are distinct. Confusing them is the single most
   common error in popular writing. Also distinct: the **ICOC** and the **United Church of
   Christ**, neither of which is related. → `history.md`, `divisions.md`

2. **"Where the Scriptures speak, we speak; where the Scriptures are silent, we are silent"
   is not in the *Declaration and Address*.** Two agents independently read the 1809 text to
   confirm. It is a *spoken* remark preserved in Richardson's 1868 memoir. "Christians only,
   but not the only Christians" has no confirmed origin at all. Both are routinely cited as
   clauses of the founding document. → `hermeneutics.md` §3

3. **1906 is a publication date, not an event.** The separate census listing was *requested*
   by the churches; the division was decades old and effectively complete by then. → `history.md`

4. **Non-institutional does not mean "against helping orphans."** The objection is to the
   *church treasury funding a separate corporation* — and their own preachers press the
   **individual** obligation harder than the mainstream does. → `non-institutional.md` §4

5. **One-cup, non-class, and non-institutional are three different things.** Most non-class
   churches use individual cups. They separated decades apart over different questions and are
   not in fellowship with each other. Jackson Heights runs graded Bible classes for all ages.
   → `divisions.md` §4

6. **The tradition was historically pacifist and apolitical.** David Lipscomb taught that
   Christians should not vote, hold office, or serve in the military. That was abandoned across
   the 20th century — and the reversal is often unknown to the tradition's own members. It did
   **not** survive in the non-institutional branch either. → `culture-and-politics.md` §8

7. **"Conservative" and "liberal" mean opposite things inside and outside this fellowship.**
   → `divisions.md`, `non-institutional.md` §1

8. **Directory numbers are not census data.** They are partisan-compiled and published figures
   vary by over 100%. Cite a range with its source and year, never a single bare number. The
   safest durable claim is proportional: the non-institutional branch has held ~15% of
   congregations and ~9% of members for thirty years. → `culture-and-politics.md` §1–2

---

## Two textual cautions

Both are load-bearing proof texts that congregations quote freely, and a careful writer should
know the manuscript situation before leaning on either:

- **Mark 16:16** sits in the "longer ending" (Mark 16:9–20), absent from Codex Sinaiticus and
  Codex Vaticanus and bracketed in most critical editions.
- **Acts 8:37** — the confession proof text, step four of the "five steps" — is absent from the
  earliest manuscripts and omitted or bracketed in modern critical texts.

Details and the CoC response to each: `scripture-index.md` §1.

---

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

## Before you draft

1. **Identify the branch first.** "Churches of Christ believe X" is usually false, because the
   branches differ. For anything in this repo's voice work, assume **non-institutional** and
   read `non-institutional.md` §10 (the writing checklist).
2. **Get the vocabulary right.** *Assembly* not "worship service," *gospel meeting* not
   "revival," *placing membership*, *the invitation*, *brother/sister*. The table is in
   `culture-and-politics.md` §11 — wrong vocabulary is the fastest way to sound like an outsider.
3. **Check the confidence tag** before stating anything as fact. A **?** is a lead, not a source.
4. **Don't cite a verse from memory.** `scripture-index.md` is verified against
   `ios/swiftbible/Text/bible.json`; check there.

---

## What this skill is NOT for

- **Adjudicating between branches.** It documents what each holds and why; it does not rule.
- **Speaking for a living congregation.** Jackson Heights' own site never uses the word
  "non-institutional" — the branch identification comes from Matt Bassford's explicit
  self-description, not from the congregation. Details it does not state (cup practice,
  membership size, positions on internal disputes) are marked unverified and should stay that way.
- **Substituting for the speaker skills.** This is the tradition; those are the men. A position
  held by the fellowship is not automatically a position Matt, Josh, or Brother Jim argued —
  check their own skill before putting it in their voice.
- **Treating a partisan retrospective as neutral.** Some of the most useful data in these files
  comes from party periodicals. Use it, label it.

## A note on research method

Two independent passes nearly recorded **Bear Valley Bible Institute** as defunct because
`bvbid.org` has been parked since 2019. It is operating, at a different domain. A dead domain is
not evidence of a closed institution — confirm status positively before writing one off.
`institutions.md` carries the correction and the warning.
