#!/usr/bin/env bash
set -euo pipefail

DMG_PATH="${1:?DMG path is required}"
EXPECTED_VERSION="${2:?expected version is required}"
EXPECTED_BUILD_NUMBER="${3:?expected build number is required}"
EXPECTED_FEED_URL="${SPARKLE_FEED_URL:-https://github.com/DeepanshuMishraa/wake-my-mac/releases/latest/download/appcast.xml}"

if [[ ! -f "$DMG_PATH" ]]; then
  echo "Release verification failed: DMG not found at $DMG_PATH." >&2
  exit 1
fi

EXPECTED_FROM_VERSION="$(cd "$(dirname "$0")" && ./version-build-number.sh "$EXPECTED_VERSION")"
if [[ "$EXPECTED_BUILD_NUMBER" != "$EXPECTED_FROM_VERSION" ]]; then
  echo "Release verification failed: build $EXPECTED_BUILD_NUMBER does not match version $EXPECTED_VERSION (expected $EXPECTED_FROM_VERSION)." >&2
  exit 1
fi

WORK_DIR="$(mktemp -d "${RUNNER_TEMP:-/tmp}/wake-release-check.XXXXXX")"
MOUNT_POINT="$WORK_DIR/mount"
mkdir -p "$MOUNT_POINT"

cleanup() {
  if mount | grep -Fq "on $MOUNT_POINT "; then
    hdiutil detach "$MOUNT_POINT" >/dev/null
  fi
  trash "$WORK_DIR" 2>/dev/null || true
}
trap cleanup EXIT

hdiutil verify "$DMG_PATH" >/dev/null
hdiutil attach -readonly -nobrowse -mountpoint "$MOUNT_POINT" "$DMG_PATH" >/dev/null

APP_PATH="$MOUNT_POINT/Wake My Mac.app"
INFO_PLIST="$APP_PATH/Contents/Info.plist"
if [[ ! -d "$APP_PATH" || ! -f "$INFO_PLIST" ]]; then
  echo "Release verification failed: Wake My Mac.app is missing from the DMG." >&2
  exit 1
fi
if [[ ! -L "$MOUNT_POINT/Applications" ]]; then
  echo "Release verification failed: the Applications shortcut is missing from the DMG." >&2
  exit 1
fi

ACTUAL_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
ACTUAL_BUILD_NUMBER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PLIST")"
ACTUAL_FEED_URL="$(/usr/libexec/PlistBuddy -c 'Print :SUFeedURL' "$INFO_PLIST")"
PUBLIC_KEY="$(/usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' "$INFO_PLIST")"

if [[ "$ACTUAL_VERSION" != "$EXPECTED_VERSION" ]]; then
  echo "Release verification failed: app version is $ACTUAL_VERSION; expected $EXPECTED_VERSION." >&2
  exit 1
fi
if [[ "$ACTUAL_BUILD_NUMBER" != "$EXPECTED_BUILD_NUMBER" ]]; then
  echo "Release verification failed: app build is $ACTUAL_BUILD_NUMBER; expected $EXPECTED_BUILD_NUMBER." >&2
  exit 1
fi
if [[ "$ACTUAL_FEED_URL" != "$EXPECTED_FEED_URL" ]]; then
  echo "Release verification failed: feed URL is $ACTUAL_FEED_URL; expected $EXPECTED_FEED_URL." >&2
  exit 1
fi
if [[ -z "$PUBLIC_KEY" ]]; then
  echo "Release verification failed: SUPublicEDKey is missing." >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
echo "Verified Wake My Mac $EXPECTED_VERSION ($EXPECTED_BUILD_NUMBER) at $DMG_PATH"
