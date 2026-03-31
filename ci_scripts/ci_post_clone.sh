#!/bin/sh
# Xcode Cloud post-clone script
# Reduces compiler parallelism to avoid memory pressure timeouts
# during whole-module-optimization of large SPM dependencies (Supabase, Sentry)

echo "Setting build parallelism limits for Xcode Cloud..."
defaults write com.apple.dt.XCBuild BuildSystemScheduleInherentlyParallelCommandsExclusively -bool YES
defaults write com.apple.dt.XCBuild IDEBuildOperationMaxNumberOfConcurrentCompileTasks 6
echo "Done."
