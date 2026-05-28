#!/bin/sh
set -eu

# Xcode Cloud exposes custom workflow environment variables to this script and
# to xcodebuild. swiftbible/Info.plist references these via $(VARIABLE_NAME),
# which keeps production service keys out of git while still embedding the
# public client config in official app builds.

if [ "${CI_XCODE_CLOUD:-}" != "TRUE" ]; then
  echo "Not running in Xcode Cloud; skipping Xcode Cloud secret validation."
  exit 0
fi

missing=0
for name in \
  SUPABASE_URL \
  SUPABASE_KEY \
  POSTHOG_API_KEY \
  SENTRY_DSN \
  DEVOTIONAL_READ_SECRET
 do
  value=$(eval "printf '%s' \"\${$name:-}\"")
  if [ -z "$value" ]; then
    echo "error: Missing required Xcode Cloud environment variable: $name" >&2
    missing=1
  else
    echo "Using Xcode Cloud environment variable: $name=<redacted>"
  fi
done

# Debug/local Supabase values are optional. If unset, the corresponding plist
# entries expand to an empty string and AppEnvironment.local falls back to the
# hardcoded local Supabase defaults where applicable.

if [ "$missing" -ne 0 ]; then
  echo "Configure the missing values in Xcode Cloud workflow Environment and mark secrets as redacted." >&2
  exit 1
fi
