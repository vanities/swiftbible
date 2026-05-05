#!/usr/bin/env bash
# Build a release Android App Bundle (AAB) ready for Google Play upload.
#
# Usage:
#   ./scripts/build_release.sh
#
# Output:
#   app/build/outputs/bundle/release/app-release.aab

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f keystore.properties ]]; then
  echo "❌ keystore.properties not found at $ROOT/keystore.properties"
  echo "   Run ./scripts/generate_keystore.sh first."
  exit 1
fi

echo "🔨 Building release bundle…"
./gradlew clean bundleRelease

AAB="app/build/outputs/bundle/release/app-release.aab"
if [[ ! -f "$AAB" ]]; then
  echo "❌ Build did not produce $AAB"
  exit 1
fi

SIZE=$(du -h "$AAB" | cut -f1)
echo ""
echo "✅ Release bundle built"
echo "   Path: $ROOT/$AAB"
echo "   Size: $SIZE"
echo ""
echo "Next steps:"
echo "  • Upload manually:  Google Play Console → Production → Create new release → upload this .aab"
echo "  • Upload via API:   ./scripts/upload_to_play.py --track internal $AAB"
