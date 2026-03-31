#!/bin/sh
set -e

echo "=== ci_post_clone.sh started at $(date) ==="

# Pre-resolve SPM dependencies to prevent silent timeout during archive.
echo "Resolving Swift Package dependencies..."
xcodebuild -resolvePackageDependencies \
  -project "$CI_PRIMARY_REPOSITORY_PATH/swiftbible.xcodeproj" \
  -scheme swiftbible \
  -clonedSourcePackagesDirPath "$CI_DERIVED_DATA_PATH/SourcePackages"
echo "Package resolution complete at $(date)."

# Use incremental compilation on CI to avoid WMO 30-minute silence timeout.
# WMO compiles the entire module as one unit with zero stdout output.
# Local builds keep WMO via project settings for optimal binaries.
echo "Setting incremental compilation for CI..."
sed -i '' 's/SWIFT_COMPILATION_MODE = wholemodule/SWIFT_COMPILATION_MODE = incremental/g' \
  "$CI_PRIMARY_REPOSITORY_PATH/swiftbible.xcodeproj/project.pbxproj"
echo "Done."

echo "=== ci_post_clone.sh finished at $(date) ==="
