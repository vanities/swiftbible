#!/bin/bash
# [fill] Fetch .info.json for any channel video id that doesn't have one yet.
# The bulk `yt-dlp <channel>/streams` sweep silently drops videos under rate limiting
# (--ignore-errors hides it), so we diff against the full id list and fetch by id,
# repeating until the missing count stops falling.
set -uo pipefail
D="$HOME/.cache/swiftbible-speakers/jackson-heights"
IDS="${1:?usage: fill_metadata.sh <all-ids-file> [parallelism]}"
PAR="${2:-2}"
LOG="$HOME/.cache/swiftbible-speakers/fill.log"
say() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG" >&2; }

prev=999999
for round in 1 2 3 4 5 6; do
  ls -1 "$D"/*.info.json 2>/dev/null | sed 's/.*-//; s/\.info\.json//' | sort -u > /tmp/.have.$$
  sort -u "$IDS" > /tmp/.all.$$
  comm -23 /tmp/.all.$$ /tmp/.have.$$ > /tmp/.miss.$$
  n=$(wc -l < /tmp/.miss.$$ | tr -d ' ')
  say "round $round: $n missing"
  [ "$n" -eq 0 ] && { say "complete"; break; }
  [ "$n" -ge "$prev" ] && { say "no progress ($n >= $prev) — stopping"; break; }
  prev=$n
  cat /tmp/.miss.$$ | xargs -P "$PAR" -I{} bash -c '
    id="$1"; dir="$2"
    ls "$dir"/*-"$id".info.json >/dev/null 2>&1 && exit 0
    yt-dlp --skip-download --write-info-json --no-overwrites --retries 3 \
      -o "$dir/%(upload_date)s-%(id)s.%(ext)s" \
      "https://www.youtube.com/watch?v=$id" >/dev/null 2>&1
  ' _ {} "$D"
  rm -f /tmp/.have.$$ /tmp/.all.$$ /tmp/.miss.$$
done
say "fill done: $(ls -1 "$D"/*.info.json | wc -l | tr -d ' ') info.json on disk"
