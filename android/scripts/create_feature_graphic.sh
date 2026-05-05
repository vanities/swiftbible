#!/usr/bin/env bash
# Create the Play Store feature graphic (1024x500) using ImageMagick.
# Outputs metadata/en-US/listing/feature-graphic.png

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/metadata/en-US/listing/feature-graphic.png"

if ! command -v magick >/dev/null 2>&1 && ! command -v convert >/dev/null 2>&1; then
  echo "❌ ImageMagick not found. Install with: brew install imagemagick"
  exit 1
fi

CMD=magick
command -v magick >/dev/null 2>&1 || CMD=convert

mkdir -p "$(dirname "$OUT")"

$CMD -size 1024x500 \
  gradient:'#0D1226-#1B2240' \
  -gravity center \
  -fill '#FFFBF7' \
  -font Helvetica-Bold -pointsize 92 -annotate +0-30 'SwiftBible' \
  -fill '#FFEDBA' \
  -font Helvetica -pointsize 32 -annotate +0+50 'Scripture, beautifully read.' \
  -fill '#00C8B4' \
  -font Helvetica -pointsize 22 -annotate +0+110 'KJV  •  ASV  •  WEB  •  Apocrypha  •  Enoch' \
  "$OUT"

echo "✅ Feature graphic written to $OUT"
