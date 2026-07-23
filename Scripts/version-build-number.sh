#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?version is required}"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must use numeric semantic versioning (for example, 0.0.3); received: $VERSION" >&2
  exit 1
fi

IFS=. read -r MAJOR MINOR PATCH <<< "$VERSION"
for component in "$MAJOR" "$MINOR" "$PATCH"; do
  if (( 10#$component > 999 )); then
    echo "Each version component must be between 0 and 999; received: $VERSION" >&2
    exit 1
  fi
done

printf '%s\n' "$((10#$MAJOR * 1000000 + 10#$MINOR * 1000 + 10#$PATCH))"
