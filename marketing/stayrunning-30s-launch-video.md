# StayRunning — 30-Second Product Launch Video

**Format:** 16:9 landscape, 1920×1080, 30 seconds, 30 fps  
**Audience:** Mac users who run long builds, downloads, exports, backups, coding agents, or remote sessions  
**Tone:** calm, precise, quietly confident; the Mac is working, not shouting  
**Visual language:** warm paper `#FFF0DF`, dark ink `#292524`, fluorescent lime `#D8FF4F`, rounded native macOS surfaces, restrained motion  
**Audio:** soft mechanical pulse at 92 BPM, low-volume; subtle click, sleep-thud, wake chime, and final resolved chord

## Core message

StayRunning keeps a Mac awake when meaningful work is still active, then releases it when the work is done. It is built for work-aware automation: agents, SSH, downloads, renders, compiles, exports, backups, and selected apps. Unlike a simple manual keep-awake toggle, it gives the user a reason, a condition, and an exit state.

The honest competitive position is:

- **Caffeine/Coffee:** excellent for a simple manual on/off or timed keep-awake session; StayRunning is better when the Mac should decide from activity rules and stop automatically.
- **Amphetamine:** powerful and broad, with sessions and triggers; StayRunning is more focused on developer/agent workflows, explains why the Mac is awake, keeps activity history local, and makes battery/display guardrails part of the central workflow.
- **`caffeinate`:** built into macOS and useful from Terminal; StayRunning turns that low-level idea into a native menu-bar/dashboard experience with rules, SSH mode, notifications, and history.

Do not say that StayRunning has more features than Amphetamine. Say that it is more focused for this particular problem.

## Master voiceover — approximately 75 words

> Your Mac went to sleep. The download didn’t finish.  
> Meet StayRunning: the native utility that keeps your Mac working when you step away.  
> It watches the work that matters—agents, builds, renders, backups, downloads, and SSH.  
> Set the rule once. Let the display sleep. Respect the battery.  
> When the work is done, StayRunning lets your Mac sleep again.  
> Not a permanent keep-awake switch. A smarter handoff between work and sleep.  
> StayRunning. Keep going, on your terms.

## Scene-by-scene production script

### Scene 1 — The interruption (0:00–0:03.5)

**Picture:** Close shot of a dark MacBook-style product silhouette. A slim progress bar reads `DOWNLOAD 94%`. The lid closes; the screen cuts to black with a soft, heavy “sleep” sound. The progress bar freezes at 94%.

**On-screen text:** `94%` → `Mac asleep`

**Voiceover:** “Your Mac went to sleep. The download didn’t finish.”

**Motion:** Slow push-in. The progress bar stops exactly on the lid-close cut. Keep this scene legible and uncomfortable, not frantic.

**Asset:** Abstract CSS/shape animation; no competitor logo or third-party footage.

### Scene 2 — The waiting parts (0:03.5–0:07.0)

**Picture:** Four compact cards slide in around a quiet central Mac dot: `BUILD`, `RENDER`, `BACKUP`, `SSH`. Each card shows a small moving activity line. The cards pause as if waiting for someone to keep watching.

**On-screen text:** `The waiting part is still work.`

**Voiceover:** “Meet StayRunning: the native utility that keeps your Mac working when you step away.”

**Motion:** Cards enter one beat apart. Use lime only on the active pulse, not as a full background.

### Scene 3 — Product reveal (0:07.0–0:11.0)

**Picture:** Existing StayRunning icon rises from the dark product vignette. Behind it, a clean menu-bar pill changes from `IDLE` to `WORKING`.

**On-screen text:** `StayRunning`  
`Work-aware. Local. Native macOS.`

**Voiceover:** “It watches the work that matters—”

**Motion:** Icon scale 92% → 100%; one lime status pulse; title wipes on from left.

**Assets:** `Sources/HoldMyLid/Resources/AppIcon.png`; optional cropped menu-bar UI capture from the app.

### Scene 4 — It knows why to stay awake (0:11.0–0:16.0)

**Picture:** Existing dashboard preview fills the frame in a dark rounded product stage. Highlight in sequence: `Agent activity`, `Download`, `Rendering`, `SSH mode`. A small history strip records `Why: Build + Agent activity`.

**On-screen text:** `Rules that match the work.`

**Voiceover:** “Agents, builds, renders, backups, downloads, and SSH.”

**Motion:** Use a controlled horizontal pan across the dashboard; add four precise lime callouts. Avoid generic UI zooms that make text unreadable.

**Asset:** `web/public/dashboard-preview.png`.

### Scene 5 — The better fit (0:16.0–0:21.0)

**Picture:** Three-column comparison, presented respectfully and quickly:

| Tool | Best at | StayRunning’s difference |
| --- | --- | --- |
| Caffeine/Coffee | Manual keep-awake | Activity-based start/stop |
| Amphetamine | Broad sessions + triggers | Focused developer/agent workflow |
| `caffeinate` | Terminal power assertion | Native UI, rules, history |

**On-screen headline:** `Not “never sleep.”`  
**Follow-up:** `Know when to keep going.`

**Voiceover:** “Set the rule once. Let the display sleep. Respect the battery.”

**Motion:** Never show competitor app icons or screenshots. Use neutral typographic labels and a lime check only in the StayRunning column.

### Scene 6 — The handoff (0:21.0–0:26.0)

**Picture:** Split sequence: left side shows a closed lid / dark display while a small `SSH reachable` indicator stays on; right side shows a battery card with `Plugged in only` and `Battery cutoff`. Then the activity line reaches `DONE`.

**On-screen text:** `Display off.`  
`Mac reachable.`  
`Battery respected.`

**Voiceover:** “When the work is done, StayRunning lets your Mac sleep again.”

**Motion:** The active lime line resolves to a small checkmark. The product should feel like it disappears at the right moment.

### Scene 7 — Close / CTA (0:26.0–0:30.0)

**Picture:** Warm paper background. Icon and wordmark centered. A tiny status line changes from `WORKING` to `SLEEPING NORMALLY`.

**On-screen text:** `Keep going. On your terms.`  
`StayRunning`  
`Free · Local · macOS 14+`

**Voiceover:** “Not a permanent keep-awake switch. A smarter handoff between work and sleep. StayRunning. Keep going, on your terms.”

**Motion:** Hold the final frame for the last 1.2 seconds so the product name and CTA can be read without pausing.

## Edit and performance notes

- Use hard cuts for Scenes 1→2 and 2→3; use soft crossfades or masked wipes after the product reveal.
- Keep all supers to one short thought at a time. The voiceover carries the explanation; the screen carries the proof.
- Use no fake claims such as “the only smart keep-awake app,” “zero battery impact,” or “better than Amphetamine for everyone.”
- Use the actual dashboard preview and icon from the repository. If recording new UI footage, capture the menu-bar state, Overview dashboard, Activity Rules, SSH settings, and History views at 60 fps.
- Export a clean master at 1920×1080 H.264, 30 fps, with a separate captioned version for social feeds.

## Fact-check references

- StayRunning product behavior: repository [`README.md`](../README.md), `AppState.swift`, `ActivityRules.swift`, and `DashboardView.swift`.
- [Amphetamine Mac App Store listing](https://apps.apple.com/us/app/amphetamine/id937984704?mt=12) — sessions, triggers, closed-display mode, display sleep, battery ending, and Drive Alive.
- [Caffeine official site](https://www.caffeine-app.net/?macos=tahoe) — simple menu-bar toggle and timed keep-awake behavior.
- [Amphetamine project comparison of `caffeinate`](https://github.com/amphetamine-app-mac/amphetamine) — Terminal-based manual assertion versus an app UI and automation.
