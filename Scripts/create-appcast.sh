#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?version is required}"
BUILD_NUMBER="${2:?build number is required}"
DOWNLOAD_URL="${3:?download URL is required}"
SIGNATURE_OUTPUT="${4:?Sparkle signature output is required}"
OUTPUT_PATH="${5:-appcast.xml}"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "VERSION must use semantic versioning (for example, 0.0.3); received: $VERSION" >&2
  exit 1
fi

IFS=. read -r MAJOR MINOR PATCH <<< "$VERSION"
EXPECTED_BUILD_NUMBER=$((MAJOR * 1000000 + MINOR * 1000 + PATCH))
if [[ "$BUILD_NUMBER" != "$EXPECTED_BUILD_NUMBER" ]]; then
  echo "BUILD_NUMBER $BUILD_NUMBER does not match VERSION $VERSION (expected $EXPECTED_BUILD_NUMBER)" >&2
  exit 1
fi

ED_SIGNATURE="$(printf '%s\n' "$SIGNATURE_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p' | head -n 1)"
FILE_LENGTH="$(printf '%s\n' "$SIGNATURE_OUTPUT" | sed -n 's/.*length="\([0-9]*\)".*/\1/p' | head -n 1)"

if [[ -z "$ED_SIGNATURE" || -z "$FILE_LENGTH" ]]; then
  echo "Could not parse Sparkle signature output: $SIGNATURE_OUTPUT" >&2
  exit 1
fi

cat > "$OUTPUT_PATH" <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Wake My Mac Updates</title>
    <link>$DOWNLOAD_URL</link>
    <description>Wake My Mac release updates</description>
    <language>en</language>
    <item>
      <title>Wake My Mac $VERSION</title>
      <pubDate>$(LC_ALL=C date -R)</pubDate>
      <sparkle:version>$BUILD_NUMBER</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <enclosure url="$DOWNLOAD_URL" length="$FILE_LENGTH" type="application/octet-stream" sparkle:edSignature="$ED_SIGNATURE" />
    </item>
  </channel>
</rss>
XML

echo "$OUTPUT_PATH"
