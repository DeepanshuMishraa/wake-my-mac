#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?version is required}"
BUILD_NUMBER="${2:?build number is required}"
DOWNLOAD_URL="${3:?download URL is required}"
SIGNATURE_OUTPUT="${4:?Sparkle signature output is required}"
OUTPUT_PATH="${5:-appcast.xml}"

ED_SIGNATURE="$(printf '%s' "$SIGNATURE_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')"
FILE_LENGTH="$(printf '%s' "$SIGNATURE_OUTPUT" | sed -n 's/.*length="\([0-9]*\)".*/\1/p')"

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
