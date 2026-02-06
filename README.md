# OpenWhisper (`openwhspr`)

OpenWhisper is an open-source, local-first macOS dictation app.

It is designed to become a world-class replacement for SuperWhisper, Aqua Voice, and WhisperFlow while keeping strict local defaults: no account requirement, no mandatory cloud dependency, no telemetry lock-in.

## Status (February 6, 2026)

OpenWhisper is a strong alpha and **not yet full SuperWhisper parity**.

It now includes:
- first-run onboarding and permission center
- configurable global hotkeys (toggle + hold-to-talk)
- local model source management (bundled + custom local model file)
- configurable output polish pipeline (spoken command replacements, capitalization, punctuation)

## Product principles

- Local first: core dictation works on-device by default.
- Open source: architecture and behavior are transparent and modifiable.
- Practical speed: global hotkey workflow and fast insertion path.
- Privacy by default: no forced cloud endpoint for primary use.

## Replacement parity snapshot

| Capability | Status | Notes |
|---|---|---|
| Local on-device dictation | ✅ Implemented | SwiftWhisper + local model |
| Global hotkey dictation | ✅ Implemented | Toggle and hold-to-talk modes |
| Permission onboarding | ✅ Implemented | Microphone, Accessibility, Input Monitoring |
| Runtime model switching | ✅ Implemented | Bundled tiny model + custom local `.bin` path |
| Output insertion workflow | ✅ Implemented | Auto-copy, optional auto-paste, manual insert |
| Output cleanup controls | ✅ Implemented | Spoken command replacements + custom rules + smart formatting |
| Per-app profiles | ❌ Missing | No app-specific behavior presets yet |
| Streaming partial UX polish | ⚠️ Partial | Live chunk updates exist; advanced token streaming UX still missing |
| Advanced command/macro engine | ⚠️ Partial | Basic command replacements only |
| Packaged release quality | ❌ Missing | No signed/notarized distribution pipeline yet |
| Test coverage depth | ⚠️ Partial | Build-verified; stronger automated behavioral tests still needed |

## Core features

- Native macOS menu bar app (`SwiftUI`, `AVAudioEngine`).
- Local transcription pipeline with chunk queueing (prevents dropped chunks while processing).
- Dictation controls:
- start/stop in app UI
- global hotkey (toggle or hold)
- Customizable hotkey config:
- required/forbidden modifiers
- trigger key
- mode selection
- Output controls:
- auto-copy
- optional auto-paste into focused app
- optional clear-after-insert
- Text polish controls:
- built-in spoken command replacements (`new line`, `comma`, `period`, etc.)
- custom replacement rules (`from => to`)
- smart capitalization toggle
- terminal punctuation toggle
- History:
- recent transcription entries
- quick restore into active draft
- Onboarding + permissions center with deep links to System Settings panes.
- Model management:
- choose bundled tiny model
- choose custom local GGML `.bin` model path
- reload model at runtime

## Requirements

- macOS 14+
- Xcode 15.4+ or Swift 6 toolchain

## Quick start

```bash
git clone git@github.com:MightComeback/openwhspr.git
cd openwhspr
swift build
swift run OpenWhisper
```

## Permissions

OpenWhisper requires:
- Microphone (audio capture)
- Accessibility (global hotkey handling and auto-paste)
- Input Monitoring (reliable event tap key capture)

Location:
`System Settings -> Privacy & Security`

## Hotkey behavior

Hotkey match uses:
- required modifiers (must be present)
- forbidden modifiers (must be absent)
- trigger key

Modes:
- Toggle: combo press starts/stops dictation.
- Hold to talk: key down starts dictation, key up finalizes dictation.

## Model management

In Settings -> Model:
- select bundled tiny model, or
- select custom local `.bin` model
- reload model after changes

If a configured custom path is missing, OpenWhisper falls back to the bundled model and shows a warning.

## Text cleanup and command replacements

In Settings -> Text cleanup:
- enable/disable spoken command replacements
- enable/disable smart capitalization
- enable/disable terminal punctuation
- add custom replacement lines

Custom replacement syntax:
- `from => to`
- `from = to`
- `# comment`

Example:

```text
teh => the
open ai = OpenAI
```

## Architecture (current)

- `AudioTranscriber`: audio capture, queueing, inference, model loading, output polish/finalization.
- `HotkeyMonitor`: global event tap, combo matching, hold/toggle state machine.
- `OnboardingView`: first-run setup and permission guidance.
- `ContentView`: runtime controls, status, and recent history.
- `SettingsView`: hotkey/output/model/permissions configuration.
- `AppDefaults`: centralized defaults and settings keys.

## Immediate roadmap to replacement grade

1. Add robust runtime verification and automated tests for hotkey and transcription/output state machines.
2. Improve streaming UX and latency perception (partial token rendering and better intermediate feedback).
3. Add per-app profiles and richer command/macro actions.
4. Improve model UX (download/manage multiple local models by name, not only file path).
5. Ship signed/notarized releases with a consistent update path.

## Development workflow

```bash
swift build
swift run OpenWhisper
```

Recommended verification during feature work:
- run `swift build` on every milestone commit
- test both hotkey modes
- test onboarding/permission re-entry paths
- test model source switching with valid and invalid custom paths

## Contributing

PRs and issues are welcome.

When opening a PR, include:
- what changed
- why it changed
- how you validated it (minimum: `swift build` and runtime notes)
