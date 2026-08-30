# Speaker archives

Voice archives for preachers and teachers whose material informs SwiftBible's devotional writing.
Each has a matching skill in [`../skills/`](../skills/) holding the voice profile; the transcripts
and source material live here.

| Archive | Source | Size | Skill |
|---|---|---|---|
| [`matt-bassford/`](matt-bassford/) | 1639 blog posts (2014–2024) + 88 transcribed sermons (2020–2022) | ~1.6k posts, ~628k spoken words | [`matt-bassford`](../skills/matt-bassford/) |
| [`josh-tolbert/`](josh-tolbert/) | 64 transcribed recordings, 2021–2026 | ~396k words | [`josh-tolbert`](../skills/josh-tolbert/) |
| [`james-edgar-green/`](james-edgar-green/) | 1 sermon, two deliveries | ~26k words | [`james-edgar-green`](../skills/james-edgar-green/) |

Matt Bassford and Josh Tolbert taught at the **same congregation** (Jackson Heights Church of
Christ, [thebibleway.org](https://www.thebibleway.org)) and appear in each other's recordings.
James Edgar Green is Adam's grandfather, unrelated to that congregation.

## The Jackson Heights YouTube channel

Channel `UClxm3vs2EhAdUPzyXiW0Hww` — **2,122 videos**, the source for both the Josh and the
audio-side Matt material. Resolved speaker roster (from `josh-tolbert/manifest.tsv`):

| Speaker | Videos | Hours |
|---|---:|---:|
| Clay Gentry | 448 | 472.0 |
| Matt Bassford | 190 | 183.9 |
| Josh Tolbert | 97 | 76.8 |
| Shawn Jeffries | 81 | 55.7 |
| Charlie Norman | 64 | 56.4 |
| Doug Arney | 57 | 49.6 |
| *(unresolved)* | 515 | 359.2 |

Tooling lives in [`josh-tolbert/`](josh-tolbert/) but is speaker-agnostic — `build_manifest.py`,
`fill_metadata.sh`, `transcribe.sh`, and `run_final.sh` all take a speaker or id list.

## Gotchas — read before scraping or transcribing anything

Each of these produced a **silent** failure: work that reported success while emitting nothing or
garbage. They cost hours apiece.

### 1. A YouTube channel is more than its `/videos` tab
`yt-dlp <channel>/videos` returned 394 and looked complete. The channel actually has three disjoint
tabs — `/videos` 394, `/streams` **1,608**, `/shorts` 120, with **zero overlap**. Everything after
the congregation began livestreaming lives only in `/streams`. Always enumerate all three.

### 2. `--ignore-errors` turns rate-limiting into fake success
A bulk `yt-dlp <channel>/streams` sweep fetched 502 of 1,608 and reported "done." Dropped videos are
indistinguishable from absent ones. **Diff the full id list against what landed on disk and refetch,
repeating until the missing count stops falling** — that is what `fill_metadata.sh` does.

### 3. Whisper repetition loops exit 0
Without `--condition-on-previous-text False`, `mlx_whisper` locks into a loop minutes into a long
recording. One 48-minute class produced 139 good lines then the word "Yeah." repeated 2,407 times —
**and exited successfully**. 11 of 17 files were garbage while the run reported "17 new, 0 failed."

```bash
mlx_whisper --model mlx-community/whisper-large-v3-turbo --language en \
  --condition-on-previous-text False \
  --compression-ratio-threshold 2.4 --logprob-threshold -1.0 --no-speech-threshold 0.6 \
  --output-format all   # NOT "txt,srt" — it takes one value or "all"
```

Audit afterward for repeated-line runs. Never trust the exit code.

### 4. Sustained scraping trips bot detection
After ~12 hours, YouTube returns `Sign in to confirm you're not a bot` for every request from the
IP. It is not per-video and the videos are fine. It lifts with time. **No cookies or credentials
have been used against this channel** — `--cookies-from-browser` would tie scraping to a real
Google identity, which is a decision for Adam, not a default.

### 5. Transcripts are not speaker-separated
Whisper does not diarize. Three consequences:
- **Classes are dialogic** — members answer at length; a quote is not the teacher's by default.
- **Livestreams are whole worship services** — another man's announcements, prayers, and
  congregational singing precede the lesson. Word counts overstate the speaker.
- **Some series are multi-speaker.** 22 of Matt's 88 transcripts have a second voice: 19 with Clay
  Gentry (13 of them titled "The Matt and Clay Show"), 1 with Josh Tolbert, and 2 singing nights
  with Ben Prasser / Mike Young. None yield a clean voice profile. The other 66 are solo Matt.

Always check surrounding lines before attributing a quote, and prefer solo recordings for voice work.

### 6. Don't compare word rates across eras
Pre-2022 files came from `/videos` and are mostly pure class recordings; later ones are
whole-service livestreams. Raw per-word rates appear to fall sharply over time — that is the
recording format changing, not the speaker. Normalise per 10k words, and treat cross-era
comparisons as invalid.

### 7. A speaker's name in a description does not mean they are speaking
The Jackson Heights channel hosts the **memorial service for Matt Bassford** (2023-11-04). The
resolver credits it to him — his name is right there — but he is the subject, not the speaker.
Including it would have attributed 81 minutes of other people's eulogies to him. Kept outside the
repo at `~/.cache/swiftbible-speakers/excluded/`; a rebuild will re-resolve it, so drop it again.
Check that a "sermon by X" is not in fact a recording *about* X.

### 8. Sub-10-minute recordings are aborted fragments
Not lessons. One was 294 seconds of silence that transcribed as a single repeated word. The tooling
skips anything shorter.

## Runbook — archiving a new speaker from a YouTube channel

The tooling lives in [`josh-tolbert/`](josh-tolbert/) but is speaker-agnostic. Nothing here is
specific to Josh except the directory it happens to sit in.

**Prerequisites:** `yt-dlp` (keep it current — YouTube breaks old versions), `mlx_whisper`
(Apple Silicon; ~50x realtime on `large-v3-turbo`), `jq`, `python3`, and bash 5+
(`/opt/homebrew/bin/bash` — macOS ships bash 3.2, which lacks `mapfile`).

### 1. Enumerate every tab

Do not trust `/videos` alone (gotcha #1). Collect ids from all three tabs into one list:

```bash
CH="https://www.youtube.com/channel/<CHANNEL_ID>"
for tab in videos streams shorts; do
  yt-dlp --flat-playlist --skip-download --print "%(id)s" "$CH/$tab" 2>/dev/null
done | sort -u > speakers/<name>/.all_ids.txt
wc -l speakers/<name>/.all_ids.txt      # this is your real channel size
```

### 2. Fetch metadata for every id, and verify it converged

A single bulk sweep silently drops videos (gotcha #2). Use the converging fetcher, which diffs the
id list against what is on disk and repeats until the missing count stops falling:

```bash
bash speakers/josh-tolbert/fill_metadata.sh speakers/<name>/.all_ids.txt 2
# then CONFIRM — never assume:
ls -1 ~/.cache/swiftbible-speakers/<channel>/*.info.json | wc -l   # vs .all_ids.txt
```

Keep parallelism low (2). Higher is what triggers the drops and, eventually, the bot block.

### 3. Resolve who preached what

Descriptions credit speakers inconsistently (`Speaker:`, `Speakers:`, `Speakers;`, or a bare name),
and channel boilerplate looks like a name to a naive parser. `build_manifest.py` learns the roster
from the explicitly-labelled videos first, then resolves the rest against it:

```bash
python3 speakers/josh-tolbert/build_manifest.py \
  ~/.cache/swiftbible-speakers/<channel> speakers/<name>/manifest.tsv
```

It prints a speaker tally. **Read it.** If your target shows 0 videos, the parser is wrong for this
channel's conventions — fix it before downloading anything.

### 4. Fetch audio, then transcribe

```bash
bash speakers/josh-tolbert/run_final.sh     # converging fetch + transcribe, resumable
```

Or for one speaker directly:

```bash
SPEAKER="Full Name" OUT_DIR=speakers/<name>/sermons \
  bash speakers/josh-tolbert/transcribe.sh
```

`transcribe.sh` already carries the correct whisper flags (gotcha #3) and skips anything already
transcribed, so it is always safe to re-run.

### 5. Audit the transcripts — the exit code is not evidence

This step is not optional. A run reporting "0 failed" has twice produced mostly-garbage output:

```bash
python3 - <<'EOF'
import glob
from itertools import groupby
for f in sorted(glob.glob("speakers/<name>/sermons/*.txt")):
    lines=[l.strip() for l in open(f,encoding="utf-8") if l.strip()]
    runs=[(k,len(list(g))) for k,g in groupby(lines)]
    loop=sum(n for _,n in runs if n>=5)
    pct=100*loop/max(len(lines),1)
    if pct>10: print(f"{pct:5.0f}% loop  {f}")
EOF
```

Anything above ~10% is a failed transcription (or a sub-10-minute junk fragment — check the audio
duration before re-running). Cross-check total words against total audio hours: roughly 8–9k words
per hour of speech. Far under that means silence or looping.

### 6. Only then, write the voice profile

Read actual teaching content before characterising anyone — and locate it first, since livestreamed
files are whole worship services and the lesson may start hundreds of lines in. Verify every quote
against its surrounding lines (gotcha #5). Normalise frequencies per 10k words, never raw counts,
and never compare across eras (gotcha #6).

## What is and isn't tracked

| | Tracked | Where it lives |
|---|---|---|
| Tooling, manifest, voice profiles, this doc | **yes** | this repo |
| Transcripts (`*/sermons/*.txt`, `*.srt`) | **no** | local only — `speakers/.gitignore` |
| Audio (`*.m4a`, `*.info.json`) | **no** | `~/.cache/swiftbible-speakers/` (~21 GB) |
| Matt's blog posts (`matt-bassford/posts/`) | yes | this repo (pre-existing) |

The transcripts are verbatim transcriptions of another congregation's sermons and worship services,
including congregational singing captured in the livestreams. This repo is public, so they are kept
as a **local research archive** rather than republished. Anyone cloning this repo can rebuild the
corpus from the runbook below — the tooling is the deliverable, not the text.

## Where the audio lives

**Outside the repo**, at `~/.cache/swiftbible-speakers/jackson-heights/` (~21 GB), so it can never
be committed. Only transcripts and metadata belong in git.

## How these feed the app

`supabase/functions/daily-devotional/index.ts` rotates a `TRACK_CYCLE` of devotional styles. Two
tracks — `matt` and `josh` — are **structural homages** derived from these archives: they borrow
the teaching method and cadence, never the person.

> **They are not impersonations, are never signed, and are never attributed.** Matt Bassford died
> in 2023 and has a living family; Josh Tolbert is alive and has not been asked. The voice profiles
> exist so devotionals can be *shaped by* how these men taught — not so a machine can speak in a
> real person's name. Keep it that way, and keep the app's labelling honest about it.

## Unfinished

- Josh: recordings still being fetched/transcribed; Matt: ~110 known recordings not yet fetched.
- ~324 videos still have no metadata, so their speaker is unknown.
- Nothing in `josh-tolbert/` is committed yet.
