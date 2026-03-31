#!/bin/sh
set -e

echo "=== ci_post_clone.sh started at $(date) ==="

# Pre-resolve SPM dependencies to prevent silent timeout during archive.
# Without this, SPM resolution happens silently inside xcodebuild archive,
# producing no stdout/stderr and triggering the 30-minute inactivity watchdog.
echo "Resolving Swift Package dependencies..."
xcodebuild -resolvePackageDependencies \
  -project "$CI_PRIMARY_REPOSITORY_PATH/swiftbible.xcodeproj" \
  -scheme swiftbible \
  -clonedSourcePackagesDirPath "$CI_DERIVED_DATA_PATH/SourcePackages"
echo "Package resolution complete at $(date)."

echo "=== ci_post_clone.sh finished at $(date) ==="
