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

## Not Developer Signed

Wake My Mac is not Developer ID signed or notarized at the moment. macOS may refuse to open it or move it to the Trash.

## Remove the Quarantine Attribute

Only do this if you downloaded Wake My Mac from this repository and trust the file. Move the app to `/Applications`, then run:

```sh
xattr -dr com.apple.quarantine "/Applications/Wake My Mac.app"
```

Open the app normally after the command finishes.

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

## Notes

Wake My Mac uses documented IOKit power assertions. macOS can still enforce sleep for thermal, battery, hardware, or managed-device safety policies.
