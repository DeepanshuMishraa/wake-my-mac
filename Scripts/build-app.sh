#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Wake My Mac"
EXECUTABLE_NAME="WatchMyMac"
BUNDLE_ID="com.dipxsy.watchmymac"
VERSION_FILE="$ROOT/VERSION"
APP_VERSION="${APP_VERSION:-$(<"$VERSION_FILE")}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
SPARKLE_FEED_URL="${SPARKLE_FEED_URL:-https://github.com/DeepanshuMishraa/wake-my-mac/releases/latest/download/appcast.xml}"
SPARKLE_PUBLIC_ED_KEY="${SPARKLE_PUBLIC_ED_KEY:-Co9AWWnH9corrdbp+CB3kMHaiYYprk5tw/o9rGsRiVQ=}"
APP_DIR="$ROOT/build/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
ASSET_OUTPUT="$ROOT/build/asset-output"

cd "$ROOT"
swift build -c release

rm -rf "$APP_DIR" "$ASSET_OUTPUT"
mkdir -p "$MACOS" "$RESOURCES"
cp "$ROOT/.build/release/$EXECUTABLE_NAME" "$MACOS/$EXECUTABLE_NAME"
cp -R "$ROOT/.build/release/WatchMyMac_WatchMyMac.bundle" "$RESOURCES/"
mkdir -p "$ASSET_OUTPUT"
xcrun actool \
  "$ROOT/Sources/HoldMyLid/Resources/Assets.xcassets" \
  --compile "$ASSET_OUTPUT" \
  --platform macosx \
  --minimum-deployment-target 14.0 \
  --app-icon AppIcon \
  --output-partial-info-plist "$ASSET_OUTPUT/asset-info.plist" \
  >/dev/null
cp "$ASSET_OUTPUT/AppIcon.icns" "$RESOURCES/AppIcon.icns"
cp "$ASSET_OUTPUT/Assets.car" "$RESOURCES/Assets.car"

SPARKLE_FRAMEWORK="$(find "$ROOT/.build" -type d -name Sparkle.framework -path '*release*' -print -quit)"
if [[ -n "$SPARKLE_FRAMEWORK" ]]; then
  mkdir -p "$CONTENTS/Frameworks"
  cp -R "$SPARKLE_FRAMEWORK" "$CONTENTS/Frameworks/"
fi

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$EXECUTABLE_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIconName</key>
  <string>AppIcon</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>SUFeedURL</key>
  <string>$SPARKLE_FEED_URL</string>
  <key>SUPublicEDKey</key>
  <string>$SPARKLE_PUBLIC_ED_KEY</string>
  <key>SUEnableAutomaticChecks</key>
  <true/>
  <key>SUAllowsAutomaticUpdates</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>Built locally.</string>
</dict>
</plist>
PLIST

echo "$APP_DIR"
