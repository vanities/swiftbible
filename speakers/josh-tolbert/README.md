# Josh Tolbert

A Bible-class teacher and occasional preacher at the **Jackson Heights Church of Christ**
([thebibleway.org](https://www.thebibleway.org)), whose lessons are posted to the congregation's
[YouTube channel](https://www.youtube.com/channel/UClxm3vs2EhAdUPzyXiW0Hww).

This archive holds his teaching for reference and voice study, beside
[`../matt-bassford/`](../matt-bassford/) and [`../james-edgar-green/`](../james-edgar-green/) —
the same congregation, in Matt's case.

## What's here

```
josh-tolbert/
├── README.md              # this file
├── manifest.tsv           # every channel video with resolved speaker (not just Josh's)
├── build_manifest.py      # info.json -> manifest; learns the speaker roster, then resolves
├── transcribe.sh          # resumable mlx_whisper runner, filtered by speaker
├── fill_metadata.sh       # fetch info.json by id, retrying until the missing count converges
├── run_pipeline.sh        # first pass (the /videos tab)
├── run_streams.sh         # second pass (the /streams tab)
├── run_final.sh           # convergence pass: retry-until-no-progress fetch + transcribe
└── sermons/               # <date>-<slug>-<videoid>.txt + .srt  (LOCAL ONLY, gitignored)
```


> **Transcripts are not in this repo.** They are verbatim transcriptions of another congregation's
> sermons and worship services, and this repo is public — so they stay local as a research archive
> and are regenerated from the tooling here (`speakers/.gitignore` excludes them). What *is* tracked:
> the pipeline, the manifest, the voice profiles, and the gotchas. Rebuild with the runbook in
> [`speakers/README.md`](../README.md).

## The corpus

| | |
|---|---|
| Transcribed | **64** recordings, ~396,000 words |
| Known to exist | **97** recordings, ~77 hours |
| Span | 2021 → 2026 (2018–2020 items appear in the manifest) |
| Source | YouTube audio → `mlx_whisper` `large-v3-turbo` (~50x realtime) |

**He is a serial expositor of Old Testament books.** The centre of gravity is not one series but a
continuing curriculum, a book at a time over months:

| Series | Recordings | Era |
|---|---:|---|
| Isaiah | 15 | 2026 (ongoing) |
| Nehemiah | 17 | 2024–25 |
| Deuteronomy | 9 | 2025 |
| Leviticus ("God's Definition of Holy") | 9 | 2021 |
| Ezra | 3 | 2024 |

Plus two Sunday-AM classes on hymnody, one class co-taught with Matt Bassford, and a few topical
sermons (*Why I Am Still a Christian*, *Paul and Felix*, *Depression with Faith*).

## Caveats that matter

1. **Transcripts are not speaker-separated.** Whisper does not diarize, and the classes are
   genuinely dialogic — class members answer at length. **Check the surrounding lines before
   attributing a quote to Josh.**
2. **Livestreamed recordings are whole worship services** — another man's announcements, prayers,
   and congregational singing precede the lesson. Word counts overstate Josh, and any per-word rate
   computed over a whole file is a lower bound on his real frequency.
3. **Never compare early-era to late-era word rates.** Pre-2022 files came from the `/videos` tab
   and are mostly pure class recordings; later ones are whole-service livestreams. An apparent
   change in his speech is an artefact of that mix.
4. **`--condition-on-previous-text False` is mandatory.** Without it whisper locks into repetition
   loops minutes in — one class produced 139 good lines then a single word repeated 2,407 times —
   **and still exits 0**. Audit for repeated-line runs; never trust the exit code.
5. **Recordings under ~10 minutes are aborted stream fragments**, not lessons. One was 294 seconds
   of silence that transcribed as a single repeated word. The tooling skips anything shorter.

## The channel is bigger than one tab

The single most important gotcha here. `yt-dlp <channel>/videos` returns **394** videos and looks
complete. It is not — the channel has three disjoint tabs:

| Tab | Videos | Overlap |
|---|---:|---|
| `/videos` | 394 | — |
| `/streams` | 1,608 | **zero** with `/videos` |
| `/shorts` | 120 | zero |

**2,122 videos total.** Everything after the congregation moved to livestreaming — including the
current Isaiah series — lives only in `/streams`. Always enumerate all three.

Equally: a bulk `yt-dlp <channel>/<tab>` sweep with `--ignore-errors` **silently drops videos under
rate limiting and reports success** — one sweep returned 502 of 1,608. `fill_metadata.sh` exists
for exactly this: diff the full id list against what's on disk and refetch, repeating until the
missing count stops falling.

## Speaker roster

From `manifest.tsv` (1,582 videos resolved so far):

| Speaker | Videos | Hours |
|---|---:|---:|
| Clay Gentry | 448 | 472.0 |
| **Matt Bassford** | **190** | **183.9** |
| **Josh Tolbert** | **97** | **76.8** |
| Shawn Jeffries | 81 | 55.7 |
| Charlie Norman | 64 | 56.4 |
| Doug Arney | 57 | 49.6 |
| Blaine Hyle / Ben Prasser | 25 each | ~23 each |
| *(unresolved)* | 515 | 359.2 |

Descriptions credit speakers inconsistently (`Speaker:`, `Speakers:`, `Speakers;`, or a bare name),
so `build_manifest.py` learns the roster from labelled videos first, then resolves the rest.

> **Note.** The Matt Bassford recordings found on this channel now live in his own archive at
> [`../matt-bassford/sermons/`](../matt-bassford/sermons/) — 89 transcripts, ~634k words. They were
> transcribed by this directory's tooling, which is why the orchestrators here still write to that
> path.

## Unfinished

- **29 Josh recordings** (≥10 min) are known but have no audio yet.
- **~324 videos** have no metadata, so their speaker is unknown — some are likely Josh's.
- Both are blocked by YouTube bot detection (`Sign in to confirm you're not a bot`) after sustained
  scraping. The block is IP-based and lifts with time; **no cookies or credentials were used.**

When the block lifts, one command converges everything (safe to re-run; skips completed work):

```bash
bash speakers/josh-tolbert/fill_metadata.sh speakers/josh-tolbert/.all_ids.txt 2   # metadata
bash speakers/josh-tolbert/run_final.sh                                            # audio + transcribe
```

Audio is cached outside the repo at `~/.cache/swiftbible-speakers/jackson-heights/` (21 GB) so it
can never be committed.

## See also

- Voice profile: [`../../.claude/skills/josh-tolbert/SKILL.md`](../../.claude/skills/josh-tolbert/SKILL.md)
