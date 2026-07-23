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

Download the latest DMG from [wakemymac.dipxsy.app](https://wakemymac.dipxsy.app).

## Signing

Public builds are not Developer ID signed yet. Sparkle update archives are independently signed with EdDSA and verified before installation. Local and release builds use ad-hoc code signing unless a signing identity is supplied.

On first use, macOS may require one explicit approval for the reliable-wake background item. Wake My Mac registers both itself and the helper automatically; it never asks you to copy files into system folders.

## Updates

Sparkle discovers the latest version from the `appcast.xml` attached to the newest GitHub release, then downloads the matching versioned DMG from:

```text
https://pub-0f452c90e334438d8e4a54f9b977a5ea.r2.dev/Wake-My-Mac-{version}.dmg
```

The release workflow validates the tag and build number, signs the DMG with Sparkle, uploads it to R2, verifies the public URL, and publishes the appcast to GitHub. It requires these repository secrets:

- `SPARKLE_PRIVATE_KEY`
- `SPARKLE_PUBLIC_ED_KEY`
- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ACCOUNT_ID`
- `R2_BUCKET_NAME`

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
