#!/usr/bin/env bash
# Extract raw simulator screenshots from an xcresult bundle into a target dir.
# Usage: ./extract_screenshots.sh <xcresult-path> <output-dir>
# Example: ./extract_screenshots.sh /tmp/swiftbible-screenshots-iphone-6.9.xcresult appstore/screenshots/iphone-6.9

set -euo pipefail

XCRESULT="${1:?Usage: $0 <xcresult-path> <output-dir>}"
OUTDIR="${2:?Usage: $0 <xcresult-path> <output-dir>}"

if [[ ! -d "$XCRESULT" ]]; then
  echo "Error: xcresult not found: $XCRESULT" >&2
  exit 1
fi

mkdir -p "$OUTDIR"

# Use the modern (Xcode 16+) test-results JSON API
TMP_JSON=$(mktemp)
xcrun xcresulttool get test-results tests --path "$XCRESULT" --format json > "$TMP_JSON"

# Each test has attachments; each attachment has a payloadId and a name like "01_bible_books"
# We want to write out <name>.png for each unique attachment.
SEEN=$(mktemp)

jq -r '
  .. | objects | select(has("attachments")) | .attachments[]
  | select(.name | test("^[0-9]+_"))
  | "\(.payloadId)\t\(.name)"
' "$TMP_JSON" | while IFS=$'\t' read -r payload_id name; do
  # Strip any extension just in case, then re-add .png
  base="${name%.png}"
  out="$OUTDIR/${base}.png"

  # Skip duplicates (same name appearing multiple times)
  if grep -qx "$base" "$SEEN" 2>/dev/null; then
    continue
  fi
  echo "$base" >> "$SEEN"

  echo "  -> $out"
  xcrun xcresulttool get object \
    --path "$XCRESULT" \
    --id "$payload_id" \
    --output-path "$out" \
    --legacy 2>/dev/null || \
  xcrun xcresulttool export attachments \
    --path "$XCRESULT" \
    --output-path "$OUTDIR" 2>/dev/null
done

rm -f "$TMP_JSON" "$SEEN"
echo "Done: $OUTDIR"
ls -la "$OUTDIR" | grep -E '\.png$' | head -20
