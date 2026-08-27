#!/bin/bash
# [streams] Second pass: the channel's /streams tab (1608 livestreams) was missed by the
# /videos enumeration entirely. Waits for the metadata sweep, then fetches + transcribes
# Josh Tolbert's and Matt Bassford's livestreams. Resumable throughout.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
AUDIO_DIR="$HOME/.cache/swiftbible-speakers/jackson-heights"
LOG="$HOME/.cache/swiftbible-speakers/streams.log"
say() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG" >&2; }
manifest() { python3 "$HERE/build_manifest.py" "$AUDIO_DIR" "$HERE/manifest.tsv" 2>>"$LOG"; }

fetch_ids() {   # $1=idfile $2=parallelism $3=tag
  local n; n=$(wc -l < "$1" | tr -d ' ')
  say "$3: $n to fetch, $2 parallel"
  [ "$n" -gt 0 ] || return 0
  cat "$1" | xargs -P "$2" -I{} bash -c '
    id="$1"; dir="$2"
    ls "$dir"/*-"$id".m4a >/dev/null 2>&1 && exit 0
    yt-dlp -f "bestaudio[ext=m4a]/bestaudio" --write-info-json --no-overwrites \
      --ignore-errors --no-abort-on-error --retries 10 --fragment-retries 10 \
      -N 4 --socket-timeout 30 \
      -o "$dir/%(upload_date)s-%(id)s.%(ext)s" \
      "https://www.youtube.com/watch?v=$id" >/dev/null 2>&1
  ' _ {} "$AUDIO_DIR"
  say "$3: fetched ($(ls -1 "$AUDIO_DIR"/*.m4a 2>/dev/null | wc -l | tr -d ' ') audio on disk)"
}

# ids for a speaker that do NOT yet have audio on disk
missing_for() {
  awk -v s="$1" 'BEGIN{FS="\t"} NR>1 && index($4,s)>0 && $5=="no" {print $2"\t"$1}' \
    "$HERE/manifest.tsv" | sort -r | cut -f2
}

say "=== streams pass start ==="
while pgrep -f meta_streams.sh >/dev/null 2>&1; do sleep 60; done
say "P1 stream metadata done: $(ls -1 "$AUDIO_DIR"/*.info.json | wc -l | tr -d ' ') info.json"
manifest; say "P2 manifest rebuilt over full channel"

missing_for "Josh Tolbert" > "$HERE/.josh_new.txt"
fetch_ids "$HERE/.josh_new.txt" 3 "P3 josh-streams"
manifest
SPEAKER="Josh Tolbert" bash "$HERE/transcribe.sh" 2>>"$LOG"
say "P3 Josh done: $(ls -1 "$HERE"/sermons/*.txt 2>/dev/null | wc -l | tr -d ' ') transcripts"

missing_for "Matt Bassford" > "$HERE/.matt_new.txt"
fetch_ids "$HERE/.matt_new.txt" 2 "P4 matt-streams"
manifest
OUT_DIR="$HERE/../matt-bassford/sermons" SPEAKER="Matt Bassford" bash "$HERE/transcribe.sh" 2>>"$LOG"
say "P4 Matt done: $(ls -1 "$HERE"/../matt-bassford/sermons/*.txt 2>/dev/null | wc -l | tr -d ' ') transcripts"

say "=== streams pass complete: josh=$(ls -1 "$HERE"/sermons/*.txt 2>/dev/null | wc -l | tr -d ' ') matt=$(ls -1 "$HERE"/../matt-bassford/sermons/*.txt 2>/dev/null | wc -l | tr -d ' ') audio=$(ls -1 "$AUDIO_DIR"/*.m4a | wc -l | tr -d ' ') disk=$(du -sh "$AUDIO_DIR" | cut -f1) ==="
