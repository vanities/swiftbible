#!/bin/bash
# [final] Converge the corpus. Waits for metadata fill, then repeatedly fetches missing audio
# for each speaker until the missing count stops falling (single-pass yt-dlp sweeps silently
# drop videos under rate limiting), then transcribes. Flags junk: recordings under 10 min,
# which on this channel are aborted stream fragments, not lessons.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
D="$HOME/.cache/swiftbible-speakers/jackson-heights"
LOG="$HOME/.cache/swiftbible-speakers/final.log"
say() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG" >&2; }
manifest() { python3 "$HERE/build_manifest.py" "$D" "$HERE/manifest.tsv" 2>>"$LOG"; }

# fetch audio for a speaker, retrying rounds until no further progress
converge_fetch() {
  local spk="$1" par="${2:-3}" prev=999999
  for round in 1 2 3 4 5; do
    manifest
    # skip fragments under 600s — aborted streams, not lessons
    awk -v s="$spk" 'BEGIN{FS="\t"} NR>1 && index($4,s)>0 && $5=="no" && $3+0>=600 {print $1}' \
      "$HERE/manifest.tsv" > "$HERE/.want.txt"
    local n; n=$(wc -l < "$HERE/.want.txt" | tr -d ' ')
    say "$spk round $round: $n missing audio"
    [ "$n" -eq 0 ] && { say "$spk: all audio present"; return 0; }
    [ "$n" -ge "$prev" ] && { say "$spk: no progress ($n >= $prev), giving up on the rest"; return 0; }
    prev=$n
    cat "$HERE/.want.txt" | xargs -P "$par" -I{} bash -c '
      id="$1"; dir="$2"
      ls "$dir"/*-"$id".m4a >/dev/null 2>&1 && exit 0
      yt-dlp -f "bestaudio[ext=m4a]/bestaudio" --write-info-json --no-overwrites \
        --retries 10 --fragment-retries 10 -N 4 --socket-timeout 30 \
        -o "$dir/%(upload_date)s-%(id)s.%(ext)s" \
        "https://www.youtube.com/watch?v=$id" >/dev/null 2>&1
    ' _ {} "$D"
  done
}

say "=== final pass start ==="
while pgrep -f fill_metadata.sh >/dev/null 2>&1; do sleep 60; done
say "P1 metadata fill finished: $(ls -1 "$D"/*.info.json | wc -l | tr -d ' ')/2122"

converge_fetch "Josh Tolbert" 3
manifest
SPEAKER="Josh Tolbert" bash "$HERE/transcribe.sh" 2>>"$LOG"
say "P2 Josh: $(ls -1 "$HERE"/sermons/*.txt 2>/dev/null | wc -l | tr -d ' ') transcripts"

converge_fetch "Matt Bassford" 2
manifest
OUT_DIR="$HERE/../matt-bassford/sermons" SPEAKER="Matt Bassford" bash "$HERE/transcribe.sh" 2>>"$LOG"
say "P3 Matt: $(ls -1 "$HERE"/../matt-bassford/sermons/*.txt 2>/dev/null | wc -l | tr -d ' ') transcripts"

say "=== final pass complete: josh=$(ls -1 "$HERE"/sermons/*.txt 2>/dev/null | wc -l | tr -d ' ') matt=$(ls -1 "$HERE"/../matt-bassford/sermons/*.txt 2>/dev/null | wc -l | tr -d ' ') audio=$(ls -1 "$D"/*.m4a | wc -l | tr -d ' ') disk=$(du -sh "$D" | cut -f1) ==="
