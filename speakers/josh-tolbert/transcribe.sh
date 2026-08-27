#!/bin/bash
# [transcribe] Run mlx_whisper (large-v3-turbo) over every sermon by $SPEAKER in the manifest.
# Resumable: skips any video whose .txt already exists. Portable to bash 3.2 (no mapfile).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
AUDIO_DIR="${AUDIO_DIR:-$HOME/.cache/swiftbible-speakers/jackson-heights}"
MANIFEST="${MANIFEST:-$HERE/manifest.tsv}"
OUT_DIR="${OUT_DIR:-$HERE/sermons}"
MODEL="${MODEL:-mlx-community/whisper-large-v3-turbo}"
SPEAKER="${SPEAKER:-Josh Tolbert}"

mkdir -p "$OUT_DIR"
[ -f "$MANIFEST" ] || { echo "[transcribe] no manifest at $MANIFEST" >&2; exit 1; }

rows_file=$(mktemp)
awk -v s="$SPEAKER" 'BEGIN{FS="\t"} NR>1 && index($4,s)>0 && $5=="yes" {print $1"\t"$2"\t"$3"\t"$6}' \
  "$MANIFEST" > "$rows_file"
total=$(wc -l < "$rows_file" | tr -d ' ')
echo "[transcribe] $SPEAKER: $total videos with audio on disk" >&2
[ "$total" -gt 0 ] || { rm -f "$rows_file"; exit 0; }

i=0; done_n=0; skip_n=0; fail_n=0; t_all=$(date +%s)
while IFS="	" read -r id date dur title; do
  i=$((i+1))
  [ -n "$id" ] || continue
  slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' \
          | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//' | cut -c1-60)
  base="${date}-${slug}-${id}"
  audio=$(ls "$AUDIO_DIR"/*-"$id".m4a 2>/dev/null | head -1)

  if [ -z "$audio" ]; then echo "[transcribe] ($i/$total) MISSING AUDIO $id" >&2; continue; fi
  if [ -f "$OUT_DIR/$base.txt" ]; then skip_n=$((skip_n+1)); continue; fi

  t0=$(date +%s)
  echo "[transcribe] ($i/$total) $base ($(awk -v d="$dur" 'BEGIN{printf "%.0f", d/60}')min)" >&2
  # condition-on-previous-text=False is essential: with it on, whisper locks into
  # repetition loops on long class recordings (one word repeated for 2000+ lines).
  if mlx_whisper --model "$MODEL" --language en --task transcribe \
       --condition-on-previous-text False \
       --compression-ratio-threshold 2.4 --logprob-threshold -1.0 --no-speech-threshold 0.6 \
       --output-dir "$OUT_DIR" --output-name "$base" --output-format all \
       --verbose False "$audio" >/dev/null 2>"$OUT_DIR/.$base.err"; then
    el=$(( $(date +%s) - t0 ))
    echo "[transcribe] ($i/$total) ok in ${el}s ($(awk -v d="$dur" -v e="$el" 'BEGIN{printf "%.1f", (e>0?d/e:0)}')x realtime)" >&2
    rm -f "$OUT_DIR/.$base.err" "$OUT_DIR/$base.vtt" "$OUT_DIR/$base.tsv" "$OUT_DIR/$base.json"
    done_n=$((done_n+1))
  else
    echo "[transcribe] ($i/$total) FAILED $base (see $OUT_DIR/.$base.err)" >&2; fail_n=$((fail_n+1))
  fi
done < "$rows_file"
rm -f "$rows_file"
echo "[transcribe] $SPEAKER complete: $done_n new, $skip_n existing, $fail_n failed, $(( $(date +%s) - t_all ))s" >&2
