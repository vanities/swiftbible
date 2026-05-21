#!/bin/bash
# CloudKit schema helper for SwiftBible.
# Loads the management token from the repo-root .env (ICLOUD_MANAGEMENT_TOKEN)
# and wraps `xcrun cktool` for the SwiftBible container.
#
# Usage:
#   ./cktool.sh verify [production|development]      # check expected CD_* record types exist
#   ./cktool.sh export [production|development] [out] # dump schema (stdout or to file)
#   ./cktool.sh diff                                  # show types in dev but not prod (pending deploy)
#   ./cktool.sh validate <env> <schema-file>          # validate a .ckdb before importing
#   ./cktool.sh import   <env> <schema-file>          # IMPORT schema (mutates the container)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TEAM_ID="8Q3RG3ULSU"
CONTAINER="iCloud.swiftbible"
# SwiftData entities → NSPersistentCloudKitContainer record types (CD_ prefix).
EXPECTED_TYPES=(CD_ReadingSession CD_EarnedBadge CD_HighlightedVerse CD_Note CD_SavedDevotional CD_LocalDonationRecord)

load_token() {
  local t
  t=$(grep -E '^ICLOUD_MANAGEMENT_TOKEN=' "$REPO_ROOT/.env" 2>/dev/null | head -1 | cut -d= -f2-)
  t="${t%\"}"; t="${t#\"}"; t="${t%\'}"; t="${t#\'}"
  if [ -z "$t" ]; then
    echo "ERROR: ICLOUD_MANAGEMENT_TOKEN not found in $REPO_ROOT/.env" >&2
    echo "Create one: CloudKit Console -> Settings -> Tokens -> CloudKit Management Token" >&2
    exit 1
  fi
  printf '%s' "$t"
}

ck() { xcrun cktool "$@" --token "$TOKEN" --team-id "$TEAM_ID" --container-id "$CONTAINER"; }

cmd="${1:-help}"
TOKEN="$(load_token)"

case "$cmd" in
  export)
    env="${2:-production}"; out="${3:-}"
    if [ -n "$out" ]; then ck export-schema --environment "$env" --output-file "$out"; echo "wrote $out"
    else ck export-schema --environment "$env"; fi
    ;;
  verify)
    env="${2:-production}"; tmp="$(mktemp)"
    ck export-schema --environment "$env" > "$tmp"
    echo "Record types present in $env:"; miss=0
    for t in "${EXPECTED_TYPES[@]}"; do
      if grep -q "RECORD TYPE $t (" "$tmp"; then echo "  OK  $t"; else echo "  MISSING  $t"; miss=1; fi
    done
    rm -f "$tmp"; exit $miss
    ;;
  diff)
    d="$(mktemp)"; p="$(mktemp)"
    ck export-schema --environment development > "$d"
    ck export-schema --environment production  > "$p"
    echo "Record types in DEVELOPMENT not yet in PRODUCTION (pending deploy):"
    comm -23 \
      <(grep -oE 'RECORD TYPE [A-Za-z0-9_]+' "$d" | sort -u) \
      <(grep -oE 'RECORD TYPE [A-Za-z0-9_]+' "$p" | sort -u) || true
    rm -f "$d" "$p"
    ;;
  validate|import)
    env="${2:?usage: $cmd <env> <schema-file>}"; file="${3:?schema file required}"
    if [ "$env" = "production" ]; then
      echo "ERROR: cktool cannot $cmd the production schema (CloudKit returns" >&2
      echo "'endpoint not applicable in the environment production'). Seed development," >&2
      echo "then deploy dev->prod in the CloudKit Console." >&2
      exit 2
    fi
    if [ "$cmd" = "import" ]; then
      echo ">>> IMPORTING schema into $env of $CONTAINER (mutates the container)." >&2
      ck import-schema --environment "$env" --validate --file "$file"
    else
      ck validate-schema --environment "$env" --file "$file"
    fi
    ;;
  *)
    echo "usage: $0 {verify|export|diff|validate|import} [development|production] [file]"
    ;;
esac
