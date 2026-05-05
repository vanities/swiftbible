#!/usr/bin/env bash
# Take Play Store screenshots from the running emulator.
# Boots a Pixel-class emulator if needed, navigates the app, captures key screens.
#
# Output:
#   metadata/en-US/screenshots/phone-{1..n}.png   (1080x2400)
#
# Tip: Pixel 6/7 series natively shoot 1080×2400, perfect for Play Store.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/metadata/en-US/screenshots"
mkdir -p "$OUT"

PACKAGE="biz.am2.swiftbible"
ACTIVITY="$PACKAGE/.MainActivity"

if ! adb get-state >/dev/null 2>&1; then
  echo "❌ No emulator/device. Boot one first:"
  echo "    \$ANDROID_HOME/emulator/emulator -avd <name> &"
  exit 1
fi

shoot() {
  local idx="$1" name="$2"
  local f="$OUT/phone-$idx-$name.png"
  adb shell screencap -p /sdcard/sb_shot.png
  adb pull /sdcard/sb_shot.png "$f" >/dev/null
  echo "📸 $f"
}

echo "🚀 Launching app fresh"
adb shell am force-stop "$PACKAGE"
sleep 1
adb shell pm clear "$PACKAGE" >/dev/null
adb shell am start -n "$ACTIVITY" >/dev/null
sleep 4

# 1. Onboarding
shoot 1 onboarding

# Skip onboarding
adb shell input tap 1000 130
sleep 2

# Wait for bible to load
sleep 5

# 2. Bible book list
shoot 2 bible-list

# 3. Tap Genesis (around y=400 in 1080 wide screen)
adb shell input tap 540 460
sleep 2
shoot 3 chapter-grid

# 4. Tap chapter 1
adb shell input tap 200 380
sleep 2
shoot 4 reader

# 5. Long-press a verse → highlight dialog
adb shell input swipe 540 800 540 800 800  # long press
sleep 2
shoot 5 highlight-dialog
adb shell input keyevent KEYCODE_BACK
sleep 1

# 6. Daily devotional
adb shell input keyevent KEYCODE_BACK
adb shell input keyevent KEYCODE_BACK
sleep 1
adb shell input tap 405 2300  # daily tab
sleep 2
shoot 6 daily

# 7. Search
adb shell input tap 675 2300  # search tab
sleep 1
adb shell input tap 540 250
adb shell input text "love"
sleep 1
shoot 7 search

# 8. Settings
adb shell input keyevent KEYCODE_BACK
adb shell input tap 945 2300
sleep 1
shoot 8 settings

echo ""
echo "✅ Captured screenshots in $OUT"
echo "   Resize/crop as needed for Play Store: 1080x1920 minimum, up to 8 screenshots, .png/.jpg"
