#!/bin/sh
set -e

echo "=== ci_post_clone.sh started at $(date) ==="

# Pre-resolve SPM dependencies to prevent silent timeout during archive.
echo "Resolving Swift Package dependencies..."
xcodebuild -resolvePackageDependencies \
  -project "$CI_PRIMARY_REPOSITORY_PATH/ios/swiftbible.xcodeproj" \
  -scheme swiftbible \
  -clonedSourcePackagesDirPath "$CI_DERIVED_DATA_PATH/SourcePackages"
echo "Package resolution complete at $(date)."

# Force incremental compilation on CI to avoid WMO 30-minute silence timeout.
# WMO compiles the entire module as one unit with zero stdout output, hitting
# Xcode Cloud's 30-minute inactivity watchdog. Incremental compiles per-file.
PBXPROJ="$CI_PRIMARY_REPOSITORY_PATH/ios/swiftbible.xcodeproj/project.pbxproj"
echo "Before sed:"
grep "SWIFT_COMPILATION_MODE" "$PBXPROJ"
sed -i '' 's/SWIFT_COMPILATION_MODE = wholemodule/SWIFT_COMPILATION_MODE = singlefile/' "$PBXPROJ"
echo "After sed:"
grep "SWIFT_COMPILATION_MODE" "$PBXPROJ"

echo "=== ci_post_clone.sh finished at $(date) ==="
