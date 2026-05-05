#!/usr/bin/env bash
# Generate a release keystore for SwiftBible Android.
# Run ONCE per project. Back up the resulting .jks file securely — if you lose it,
# you can no longer publish updates to your app on Google Play.
#
# Usage:
#   ./scripts/generate_keystore.sh [keystore_path] [alias]
# Defaults:
#   keystore_path = release.keystore
#   alias = swiftbible

set -euo pipefail

KEYSTORE_PATH="${1:-release.keystore}"
ALIAS="${2:-swiftbible}"

if [[ -f "$KEYSTORE_PATH" ]]; then
  echo "❌ Keystore already exists at $KEYSTORE_PATH"
  echo "   Refusing to overwrite. Move or delete it first if you really mean to."
  exit 1
fi

if ! command -v keytool >/dev/null 2>&1; then
  echo "❌ keytool not found. Install JDK 17+ (e.g. brew install openjdk@17)"
  exit 1
fi

echo "Generating release keystore: $KEYSTORE_PATH (alias: $ALIAS)"
echo "You will be prompted for two passwords (the keystore password and key password)."
echo "Use the SAME password for both unless you really want to deal with two."
echo ""

# Read passwords interactively
read -r -s -p "Keystore password: " STORE_PW
echo
read -r -s -p "Confirm keystore password: " STORE_PW_CONF
echo
[[ "$STORE_PW" == "$STORE_PW_CONF" ]] || { echo "Passwords don't match"; exit 1; }

read -r -p "Your full name: " NAME
read -r -p "Organization (or your name again): " ORG
read -r -p "City: " CITY
read -r -p "State or province: " STATE
read -r -p "Country code (e.g. US): " COUNTRY

DNAME="CN=${NAME},OU=${ORG},O=${ORG},L=${CITY},S=${STATE},C=${COUNTRY}"

keytool -genkeypair -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 36500 \
  -storepass "$STORE_PW" \
  -keypass "$STORE_PW" \
  -dname "$DNAME"

echo ""
echo "✅ Keystore created at: $KEYSTORE_PATH"
echo ""
echo "Next, create keystore.properties at the repo root with these contents:"
echo ""
cat <<EOF
# keystore.properties — DO NOT COMMIT TO GIT
storeFile=$(realpath "$KEYSTORE_PATH")
storePassword=<your password>
keyAlias=$ALIAS
keyPassword=<your password>
EOF
echo ""
echo "⚠️  IMPORTANT: back up $KEYSTORE_PATH to a secure password manager"
echo "    (1Password, Bitwarden, etc.) and to a separate offline location."
echo "    Losing this file means you can never publish updates again."
