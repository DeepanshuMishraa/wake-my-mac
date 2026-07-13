#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Wake My Mac"
VERSION_FILE="$ROOT/VERSION"
VERSION="${APP_VERSION:-$(<"$VERSION_FILE")}"
APP_PATH="$ROOT/build/$APP_NAME.app"
STAGING_DIR="$ROOT/build/dmg-root"
DMG_PATH="$ROOT/build/Wake-My-Mac-$VERSION.dmg"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Missing app bundle: $APP_PATH" >&2
  echo "Run Scripts/build-app.sh first." >&2
  exit 1
fi

rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

rm -rf "$STAGING_DIR"
echo "$DMG_PATH"
