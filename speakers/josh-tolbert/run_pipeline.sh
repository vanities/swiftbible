#!/bin/bash
# [pipeline] Unattended build of the Jackson Heights corpus, Josh Tolbert first.
#   P1 manifest -> P2 Josh audio -> P3 transcribe Josh (GPU) || backfill channel (network)
#   -> P4 transcribe Matt Bassford (bonus) -> P5 retry today's livestream -> P6 report
# Every phase is resumable; re-running skips completed work.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
AUDIO_DIR="$HOME/.cache/swiftbible-speakers/jackson-heights"
LOG="$HOME/.cache/swiftbible-speakers/pipeline.log"
LIVE_ID="9j4O5z3MB0I"
mkdir -p "$AUDIO_DIR" "$HERE/sermons"

say() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG" >&2; }

manifest() { python3 "$HERE/build_manifest.py" "$AUDIO_DIR" "$HERE/manifest.tsv" 2>>"$LOG"; }

# ids for a speaker (substring match; manifest speakers col is comma-separated), newest first
ids_for() { awk -v s="$1" 'BEGIN{FS="\t"} NR>1 && index($4,s)>0 {print $2"\t"$1}' "$HERE/manifest.tsv" | sort -r | cut -f2; }
ids_not()  { awk -v s="$1" 'BEGIN{FS="\t"} NR>1 && index($4,s)==0 {print $2"\t"$1}' "$HERE/manifest.tsv" | sort -r | cut -f2; }

fetch_ids() {   # $1=idfile $2=parallelism $3=tag
  local n; n=$(wc -l < "$1" | tr -d ' ')
  say "$3: $n ids, $2 parallel"
  cat "$1" | xargs -P "$2" -I{} bash -c '
    id="$1"; dir="$2"
    ls "$dir"/*-"$id".m4a >/dev/null 2>&1 && exit 0
    yt-dlp -f "bestaudio[ext=m4a]/bestaudio" --write-info-json --no-overwrites \
      --ignore-errors --no-abort-on-error --retries 10 --fragment-retries 10 \
      -N 4 --socket-timeout 30 \
      -o "$dir/%(upload_date)s-%(id)s.%(ext)s" \
      "https://www.youtube.com/watch?v=$id" >/dev/null 2>&1
  ' _ {} "$AUDIO_DIR"
  say "$3: done ($(ls -1 "$AUDIO_DIR"/*.m4a 2>/dev/null | wc -l | tr -d ' ') audio on disk)"
}

say "=== pipeline v2 start ==="
manifest; say "P1 manifest built"

ids_for "Josh Tolbert" > "$HERE/.josh_ids.txt"
fetch_ids "$HERE/.josh_ids.txt" 3 "P2 josh-audio"
manifest

# P3: GPU transcription and network backfill are independent resources -> run together
( SPEAKER="Josh Tolbert" bash "$HERE/transcribe.sh" 2>>"$LOG" ) &
P3A=$!
ids_not "Josh Tolbert" > "$HERE/.rest_ids.txt"
( fetch_ids "$HERE/.rest_ids.txt" 2 "P3b backfill" ) &
P3B=$!
wait $P3A; say "P3a Josh transcription finished"
wait $P3B; say "P3b channel backfill finished"
manifest

# P4: bonus — Matt Bassford preached at this congregation and died in Nov 2023.
# The existing speakers/matt-bassford archive is 1639 blog posts with no audio at all.
# Idle GPU time overnight; output lands in speakers/matt-bassford/sermons/.
say "P4 bonus: transcribing Matt Bassford (92h; existing archive has no audio)"
OUT_DIR="$HERE/../matt-bassford/sermons" SPEAKER="Matt Bassford" bash "$HERE/transcribe.sh" 2>>"$LOG"
say "P4 Matt transcription finished"

# P5: today's livestream was still being processed by YouTube at start of run
say "P5 retrying still-processing livestream $LIVE_ID"
for attempt in 1 2 3 4 5 6; do
  ls "$AUDIO_DIR"/*-"$LIVE_ID".m4a >/dev/null 2>&1 && { say "P5 have it"; break; }
  yt-dlp -f "bestaudio[ext=m4a]/bestaudio" --write-info-json --no-overwrites --retries 5 -N 4 \
    -o "$AUDIO_DIR/%(upload_date)s-%(id)s.%(ext)s" \
    "https://www.youtube.com/watch?v=$LIVE_ID" >/dev/null 2>&1
  ls "$AUDIO_DIR"/*-"$LIVE_ID".m4a >/dev/null 2>&1 && { say "P5 got it on attempt $attempt"; break; }
  say "P5 attempt $attempt: still processing, waiting 30m"
  sleep 1800
done

manifest
SPEAKER="Josh Tolbert" bash "$HERE/transcribe.sh" 2>>"$LOG"
say "=== pipeline done: josh=$(ls -1 "$HERE"/sermons/*.txt 2>/dev/null | wc -l | tr -d ' ') matt=$(ls -1 "$HERE"/../matt-bassford/sermons/*.txt 2>/dev/null | wc -l | tr -d ' ') audio=$(ls -1 "$AUDIO_DIR"/*.m4a 2>/dev/null | wc -l | tr -d ' ') disk=$(du -sh "$AUDIO_DIR" | cut -f1) ==="
