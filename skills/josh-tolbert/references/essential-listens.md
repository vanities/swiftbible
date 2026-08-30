# Josh Tolbert — essential listens

Where to start, by what you are trying to do. Filenames are relative to
`speakers/josh-tolbert/sermons/` (`.txt` transcript + timestamped `.srt` beside it).
Word counts are of the whole file — for livestreamed services that includes announcements,
prayers, and congregational singing, so the *lesson* is shorter than the number suggests.

List the whole corpus with `python3 scripts/search.py --list`.

---

## The five-recording orientation

If you read nothing else, read these. They cover both registers, the full date range, and every
habit in [`voice.md`](voice.md).

| # | Recording | ~words | Why this one |
|---|---|---:|---|
| 1 | `20220120-sunday-pm-worship-paul-and-felix-rkuCjQw1yjk.txt` | 9,200 | The best single file in the archive. His stated method (line 178), background-first structure, a priced source, self-deprecation, and an unscripted admission — all within 70 lines. His portion starts at **line 169**; everything before is announcements and singing. |
| 2 | `20210728-…-god-s-definition-of-holy-leviticus--MtxfZIo3khM.txt` | 8,100 | The purest classroom file. Socratic opening in the first 15 lines, the "whose definition?" thesis, coined nicknames, explicit memory management. |
| 3 | `20250331-why-i-am-still-a-christian-3-30-2025-1QkhEtf0QU4.txt` | 5,100 | The most personal and the most argued. Lesson only, no service around it. |
| 4 | `20240819-sunday-pm-worship-depression-with-faith-8-18-2024-ch3IsHmRgJ8.txt` | 9,400 | Him at his warmest, and his clearest example of arguing against a received idea by piling up text. |
| 5 | `20240704-wednesday-bible-class-nehemiah-7-3-2024-UywwHpoFciA.txt` | 8,200 | A mid-series class: review, cross-references to his own earlier series and to colleagues' concurrent ones, class Q&A. This is what a normal Wednesday sounds like. |

---

## By use case

### Writing a devotional or lesson in his voice
1. `20250331-why-i-am-still-a-christian-3-30-2025-1QkhEtf0QU4.txt` — first-person, argued, unsentimental.
2. `20240819-…-depression-with-faith-…-ch3IsHmRgJ8.txt` — first-person and pastoral without going soft.
3. `20211203-fall-focus-series-becoming-children-of-light-uVeYKpFz4GE.txt` — a clean three-part New Testament lesson; the most "devotional-shaped" thing he does.

Ready-made excerpts to paste into a prompt: [`few-shot-anchors.md`](few-shot-anchors.md).

### Learning how he runs a class (mechanics, not prose)
1. `20210728-…-leviticus--MtxfZIo3khM.txt` — the opening move, done cleanly.
2. `20240704-…-nehemiah-7-3-2024-UywwHpoFciA.txt` — review → background → text → invited comments.
3. `20210512-…-does-the-origin-of-a-hymn-matter-…-1C72Yy135MA.txt` — a class where the room does most of the talking.

See [`teaching-method.md`](teaching-method.md).

### Old Testament law and holiness
The Leviticus series, *God's Definition of Holy* (11 transcripts, Jul–Nov 2021). Start at
`20210728-…-MtxfZIo3khM.txt` and read forward; the parts are numbered in the titles. Note Pt. 4 (`56_m4e-Gy_s`,
2021-08-11) is in the manifest but was never transcribed, so the series jumps Pt. 3 → Pt. 5.

### Prophets and the reliability of prophecy
- Isaiah series, 14 transcripts, Apr–Aug 2026 (ongoing). Begin at
  `20260416-…-isaiah-4-15-2026-2CS6kMu1UCU.txt`, which reviews the prior week's introduction —
  **the actual first Isaiah class is in neither the transcripts nor the manifest** — all 15 Isaiah videos the manifest knows about start here.
- *Jesus in the Minor Prophets*, 7 transcripts, Jul–Oct 2020 — his earliest transcribed series,
  and messianic rather than historical in emphasis.

### Post-exilic history
Ezra (5, Apr–Jun 2024) → Nehemiah (7, Jul–Sep 2024) read in order; he treats them as one
continuous story and back-references Ezra constantly during Nehemiah.
`20240512-…-from-creation-to-eternity-…-W96EXQbSqIU.txt` is the whole arc compressed into one
lesson and is the best single entry point.

### Apologetics and deconstruction
`20250331-why-i-am-still-a-christian-3-30-2025-1QkhEtf0QU4.txt`, and nothing else comes close.
He surveys Islam, Judaism, Hinduism, Buddhism, ancient paganism, Mormonism, Jehovah's Witnesses,
Catholicism, mainstream Protestantism, and evolution, and says what he found wanting in each.

### Worship and hymnody
`20210428-…-singing-with-understanding-pt-3-…-jQ94aWFjt_c.txt` and
`20210512-…-does-the-origin-of-a-hymn-matter-…-1C72Yy135MA.txt`. Both are substitute classes for
Matt Bassford, and both lean hard on the room — quote from them with extra care.

### Authority, doctrine, and how his tradition argues
`20220725-sunday-evening-worship-you-have-gone-too-far-9JVCnJMenH0.txt` (Korah). The closest
thing in the corpus to a statement of his doctrinal epistemology. See
[`theology.md`](theology.md).

### Him beside Matt Bassford
`20210110-the-matt-and-clay-show-overcoming-the-temptation-of-prosperi-KhX3eiKsrSM.txt` — the only
two-speaker recording. Clay Gentry is absent; Josh hosts and Matt is the guest. Useful for hearing
the two voices back to back, **and the single worst file to quote from carelessly.**

---

## Files to be careful with, or skip

| File(s) | Problem |
|---|---|
| 13 transcripts under 1,500 words (e.g. `20240814-…-wMGNGIkvLDM.txt`, 1 word) | Aborted livestream fragments, not lessons. `search.py` excludes them by default. |
| `20240513-…-from-creation-to-eternity-…-W96EXQbSqIU.txt` | Byte-identical duplicate of the `20240512` file — same video id written under two dates. Cite the `20240512` one. |
| The two `20250331` *Why I Am Still a Christian* files | Same sermon, two YouTube uploads, transcribed independently. Wording and punctuation differ; the `yVZb4YFZfok` (whole-service) cut is punctuated, the `1QkhEtf0QU4` (lesson-only) cut largely is not. Quote from whichever you actually read, and don't treat the differences as him saying it twice. |
| Every Sunday and livestreamed file | Whole worship services. Announcements, prayers, and singing come first — sometimes 150+ lines — and there is often a second man speaking. |
| `20210110-the-matt-and-clay-show-…-KhX3eiKsrSM.txt` | Two speakers, unlabelled. |
