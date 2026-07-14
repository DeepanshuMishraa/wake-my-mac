# Expanded production prompt — Wake My Mac launch film

## Title and style

**Wake My Mac — Keep going, on your terms.**

Use the existing Wake My Mac design system exactly: warm paper `#FFF0DF`, dark ink `#292524`, secondary `#705F54`, peach `#F6E5D4`, fluorescent lime `#D8FF4F`, borders `rgba(41, 37, 36, .17)`, DM Sans for body/UI, Instrument Serif italic for emphasis. The mood is refined minimalism for a native Mac utility: quiet, editorial, tactile, and conversion-focused. Keep the product vignette dark while the surrounding world stays warm paper.

## Rhythm declaration

`friction-PUNCH → waiting-pulse → reveal → proof-cascade → respectful-compare → low-power-handoff → breathe-CTA`

Thirty seconds at 60 fps. The narration is approximately 75 words at a natural 2.5 words-per-second pace. Leave short gaps around the sleep cut, product reveal, and final CTA. If TTS runs longer than 30 seconds, preserve every scene and extend the hold between scenes rather than speeding the voice.

## Global rules

- Canvas: 1920×1080, 60 fps, deterministic render.
- Use a 12-column editorial grid with large edge anchors; avoid centered floating cards except for the final brand lockup.
- Every scene gets a texture layer, a structural layer, midground product/content, and a small foreground data detail.
- Use full-saturation lime only for active state, progress, and the final check. Do not turn the whole film neon.
- Motion vocabulary: sleep-thud hard cut, measured slides, rule-line wipes, dashboard pan, one clean status pulse, and a held final frame.
- No competitor app icons, screenshots, or unlicensed third-party footage. Compare by neutral typography only.
- No fake performance claims, no “better than Amphetamine at everything,” no “zero battery impact,” and no “never sleeps.”
- Use actual repository assets: `Sources/HoldMyLid/Resources/AppIcon.png` and `web/public/dashboard-preview.png`.

## Scene beats

### 1. Friction / the interrupted handoff — 0:00–0:03.5

**Concept:** A download reaches 94% and the Mac goes to sleep before the handoff is complete. The viewer feels the tiny interruption that costs real time.

**Mood:** cinematic restraint, physical product close-up, one sharp interruption.

**Depth layers:** warm paper grain; dark Mac silhouette; lime progress bar; 94% counter; lid-close shadow; small system status label; one hairline rule; tiny `POWER STATE / IDLE` metadata.

**Choreography:** progress crawls; counter ticks once; lid shadow drops; screen blacks out; progress freezes. Hard cut to Scene 2.

### 2. The waiting parts — 0:03.5–0:07.0

**Concept:** Long work is made of waiting states: builds, renders, backups, downloads, and SSH. The Mac should know that waiting is still work.

**Mood:** editorial systems diagram, calm but purposeful.

**Depth layers:** faint dotted grid; oversized ghost word `WAIT`; four activity cards; central Mac status node; tiny waveform lines; lime pulse; peach divider; timestamp labels; two drifting registration marks.

**Choreography:** cards cascade one beat apart; waveform lines breathe; central node pulses once; the headline rule expands. Masked wipe into Scene 3.

### 3. Product reveal — 0:07.0–0:11.0

**Concept:** Introduce Wake My Mac as a native local utility, not a generic stay-awake hack.

**Mood:** premium product reveal, soft but confident.

**Depth layers:** dark vignette; icon glow plate; actual app icon; menu-bar state pill; `IDLE` → `WORKING` label; title; subtitle; lime status dot; small `macOS 14+ / LOCAL` metadata.

**Choreography:** vignette reveals by width; icon rises and settles; status pill changes; wordmark slides from the left; subtitle fades after the title. Soft crossfade into Scene 4.

### 4. Work-aware proof — 0:11.0–0:16.0

**Concept:** Show the actual dashboard and its reason-based state: agents, downloads, renders, SSH, history. Make the claim visible rather than abstract.

**Mood:** product demo, precise, native, legible.

**Depth layers:** dark stage; dashboard image; four lime callout rails; `Agent activity`, `Download`, `Rendering`, `SSH mode` tags; a history strip; tiny battery indicator; page index `01 / OVERVIEW`; subtle scanline.

**Choreography:** dashboard pans horizontally; callout rails draw on one by one; history item stamps in; battery marker settles. Use a short push-through transition into Scene 5.

### 5. Respectful comparison — 0:16.0–0:21.0

**Concept:** Acknowledge the existing tools. Caffeine/Coffee is simple manual control; Amphetamine is broad and powerful; `caffeinate` is a Terminal primitive. Wake My Mac is the focused work-aware fit.

**Mood:** editorial comparison table, no attack-ad energy.

**Depth layers:** paper canvas; vertical rules; three neutral tool labels; concise “best at” phrases; one highlighted Wake My Mac row; lime check; small footnote `different tools, different fit`; faint comparison index.

**Choreography:** columns reveal left-to-right; rows settle with 80ms offsets; Wake My Mac row receives a 2px lime rule; the headline replaces itself with `Know when to keep going.`

### 6. Low-power handoff — 0:21.0–0:26.0

**Concept:** Wake My Mac preserves the useful part of the session while respecting the machine: display can sleep, SSH remains reachable, battery rules apply, and the Mac returns to normal sleep when the work ends.

**Mood:** quiet technical confidence, release of tension.

**Depth layers:** split screen; closed-lid silhouette; `SSH REACHABLE` chip; dark display panel; `PLUGGED IN ONLY` rule; battery cutoff gauge; `DONE` state; final small checkmark; a slow lime line.

**Choreography:** split opens from center; display darkens while SSH chip remains; battery gauge fills to its safe line; work line reaches `DONE`; checkmark draws; all motion slows before CTA.

### 7. CTA / resolved state — 0:26.0–0:30.0

**Concept:** End on a simple promise: keep the Mac awake only when it needs to keep going, then get out of the way.

**Mood:** warm editorial brand lockup, generous breathing room.

**Depth layers:** paper texture; small lime accent block; icon; Wake My Mac wordmark; `WORKING` → `SLEEPING NORMALLY` status; CTA; `Free · Local · macOS 14+`; two fine border rules.

**Choreography:** icon and wordmark settle; status changes; CTA fades in; hold the final frame for at least 1.2 seconds. End with a soft resolved chord, not a notification ping.

## Narration timing target

“Your Mac went to sleep. The download didn’t finish.

Meet Wake My Mac: the native utility that keeps your Mac working when you step away.

It watches the work that matters—agents, builds, renders, backups, downloads, and SSH.

Set the rule once. Let the display sleep. Respect the battery.

When the work is done, Wake My Mac lets your Mac sleep again.

Not a permanent keep-awake switch. A smarter handoff between work and sleep.

Wake My Mac. Keep going, on your terms.”

## Negative prompt

Avoid generic startup-template energy, blue-purple SaaS gradients, excessive glassmorphism, floating UI with no anchor, all-caps body copy, competitor logos, fake benchmark numbers, fake testimonials, unverified claims, rapid feature-list pacing, unreadable microcopy, and animation that keeps every element moving after the message has landed.
