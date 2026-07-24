#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:?version is required}"
RELEASE_FILE="$ROOT/web/app/release.ts"
TARGET_BUILD_NUMBER="$("$ROOT/Scripts/version-build-number.sh" "$VERSION")"

if [[ -f "$RELEASE_FILE" ]]; then
  CURRENT_VERSION="$(sed -n 's/^export const releaseVersion = "\([^"]*\)";$/\1/p' "$RELEASE_FILE")"
  if [[ -z "$CURRENT_VERSION" ]]; then
    echo "Could not read releaseVersion from $RELEASE_FILE." >&2
    exit 1
  fi
  CURRENT_BUILD_NUMBER="$("$ROOT/Scripts/version-build-number.sh" "$CURRENT_VERSION")"
  if (( TARGET_BUILD_NUMBER < CURRENT_BUILD_NUMBER )); then
    echo "Refusing to move the website from $CURRENT_VERSION back to $VERSION." >&2
    exit 1
  fi
fi

TEMP_FILE="$(mktemp "$ROOT/web/app/release.ts.XXXXXX")"
trap 'rm -f -- "$TEMP_FILE"' EXIT
cat > "$TEMP_FILE" <<EOF
export const releaseVersion = "$VERSION";

export const downloadUrl =
  \`https://pub-0f452c90e334438d8e4a54f9b977a5ea.r2.dev/StayRunning-\${releaseVersion}.dmg\`;
EOF
mv "$TEMP_FILE" "$RELEASE_FILE"
trap - EXIT
