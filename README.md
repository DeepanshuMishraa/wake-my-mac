# Wake My Mac

A native macOS utility that keeps your Mac awake when something important is still running.

Use it for remote SSH access, long downloads, builds, exports, backups, selected apps, or coding agents. The menu-bar control handles quick changes; the dashboard shows when the Mac stayed awake, why, and the measured battery change.

## Modes

- **Agents** — activates for supported agent sessions and activity rules.
- **SSH** — keeps the system and network reachable while the display can sleep and lock.
- **Manual** — stays awake until you switch it off.

Activity rules can watch common download, rendering, compiling, exporting, and backup processes, or applications you choose.

## Privacy

History stays on the Mac. Wake My Mac records timestamps, wake reasons, agent names, and battery percentage changes. It does not record command arguments, terminal contents, filenames, URLs, or network destinations.

## Install

Download the latest DMG from [Releases](https://github.com/DeepanshuMishraa/wake-my-mac/releases).

The app is currently not Developer ID signed or notarized. Release downloads are independently verified by Sparkle using EdDSA signatures.

## Build

Requires macOS 14 or later and a current Xcode toolchain.

```sh
make app
open "build/Wake My Mac.app"
```

Run the test suite with:

```sh
swift test
```

## Releases

Publish a GitHub Release with a tag such as `V0.0.1`. The release workflow runs the tests, builds the app, creates a DMG, signs it for Sparkle, generates the appcast, and attaches both assets to the release.

The repository must define `SPARKLE_PUBLIC_ED_KEY` and `SPARKLE_PRIVATE_KEY` as Actions secrets before publishing.

## Notes

Wake My Mac uses documented IOKit power assertions. macOS can still enforce sleep for thermal, battery, hardware, or managed-device safety policies.
