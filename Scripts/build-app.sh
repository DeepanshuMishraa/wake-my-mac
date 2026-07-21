#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Wake My Mac"
EXECUTABLE_NAME="WatchMyMac"
HELPER_NAME="WakeMyMacHelper"
HELPER_ID="com.dipxsy.watchmymac.helper.v2"
LEGACY_HELPER_ID="com.dipxsy.watchmymac.helper"
BUNDLE_ID="com.dipxsy.watchmymac"
VERSION_FILE="$ROOT/VERSION"
APP_VERSION="${APP_VERSION:-$(<"$VERSION_FILE")}"
if [[ ! "$APP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "APP_VERSION must use semantic versioning (for example, 0.0.3); received: $APP_VERSION" >&2
  exit 1
fi
IFS=. read -r MAJOR MINOR PATCH <<< "$APP_VERSION"
EXPECTED_BUILD_NUMBER=$((MAJOR * 1000000 + MINOR * 1000 + PATCH))
if [[ -n "${BUILD_NUMBER:-}" && "$BUILD_NUMBER" != "$EXPECTED_BUILD_NUMBER" ]]; then
  echo "BUILD_NUMBER $BUILD_NUMBER does not match APP_VERSION $APP_VERSION (expected $EXPECTED_BUILD_NUMBER)" >&2
  exit 1
fi
BUILD_NUMBER="$EXPECTED_BUILD_NUMBER"
SPARKLE_FEED_URL="${SPARKLE_FEED_URL:-https://github.com/DeepanshuMishraa/wake-my-mac/releases/latest/download/appcast.xml}"
SPARKLE_PUBLIC_ED_KEY="${SPARKLE_PUBLIC_ED_KEY:-Co9AWWnH9corrdbp+CB3kMHaiYYprk5tw/o9rGsRiVQ=}"
if [[ -z "${CODE_SIGN_IDENTITY:-}" ]]; then
  CODE_SIGN_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' '/Apple Development:/{print $2; exit}')"
fi
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"
APP_DIR="$ROOT/build/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
LAUNCH_DAEMONS="$CONTENTS/Library/LaunchDaemons"
ASSET_OUTPUT="$ROOT/build/asset-output"

cd "$ROOT"
swift build -c release

rm -rf "$APP_DIR" "$ASSET_OUTPUT"
mkdir -p "$MACOS" "$RESOURCES" "$LAUNCH_DAEMONS"
cp "$ROOT/.build/release/$EXECUTABLE_NAME" "$MACOS/$EXECUTABLE_NAME"
cp "$ROOT/.build/release/$HELPER_NAME" "$RESOURCES/$HELPER_NAME"
HELPER_BUILD_ID="$(shasum -a 256 "$RESOURCES/$HELPER_NAME" | awk '{print $1}')"
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

cat > "$LAUNCH_DAEMONS/$HELPER_ID.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$HELPER_ID</string>
  <key>BundleProgram</key>
  <string>Contents/Resources/$HELPER_NAME</string>
  <key>MachServices</key>
  <dict>
    <key>$HELPER_ID</key>
    <true/>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>ProcessType</key>
  <string>Adaptive</string>
</dict>
</plist>
PLIST

# Kept only so upgraded builds can unregister the unreleased legacy helper.
# The app never registers this plist.
cat > "$LAUNCH_DAEMONS/$LEGACY_HELPER_ID.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LEGACY_HELPER_ID</string>
  <key>BundleProgram</key>
  <string>Contents/Resources/$HELPER_NAME</string>
  <key>MachServices</key>
  <dict>
    <key>$LEGACY_HELPER_ID</key>
    <true/>
  </dict>
</dict>
</plist>
PLIST

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
  <key>WakeHelperBuildIdentifier</key>
  <string>$HELPER_BUILD_ID</string>
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

# Local builds use ad-hoc signing. Releases provide a Developer ID identity and
# hardened-runtime signatures so Service Management can trust the daemon.
SIGN_OPTIONS=(--force --sign "$CODE_SIGN_IDENTITY")
if [[ "$CODE_SIGN_IDENTITY" != "-" ]]; then
  SIGN_OPTIONS+=(--options runtime --timestamp)
fi
codesign "${SIGN_OPTIONS[@]}" --identifier "$HELPER_ID" "$RESOURCES/$HELPER_NAME"
if [[ -d "$CONTENTS/Frameworks/Sparkle.framework" ]]; then
  codesign "${SIGN_OPTIONS[@]}" "$CONTENTS/Frameworks/Sparkle.framework"
fi
codesign "${SIGN_OPTIONS[@]}" --identifier "$BUNDLE_ID" "$APP_DIR"

echo "$APP_DIR"
