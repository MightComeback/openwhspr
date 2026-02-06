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
- per-app output profiles
- live streaming metrics in the runtime menu

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
| Output cleanup controls | ✅ Implemented | Built-in and custom command rules + smart formatting |
| Per-app profiles | ✅ Implemented | App-specific output and command behavior overrides |
| Streaming partial UX polish | ⚠️ Partial | Queue/latency metrics implemented; token-level partial UX still pending |
| Advanced command/macro engine | ⚠️ Partial | Structured command maps implemented; full macro actions still pending |
| Packaged release quality | ⚠️ Partial | Signing/notarization workflow and release script added |
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
- Per-app profiles:
- capture frontmost app profile
- override output behavior per target app
- add app-specific custom command rules
- Text polish controls:
- built-in spoken command replacements (punctuation, symbols, formatting phrases)
- global custom command map (`phrase => replacement`)
- custom replacement rules (`from => to`)
- smart capitalization toggle
- terminal punctuation toggle
- Streaming UX:
- processed/pending chunk counters
- per-chunk latency display
- recording duration display while dictating
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
- define global custom commands (`phrase => replacement`)
- add custom replacement lines

Custom replacement syntax:
- `from => to`
- `from = to`
- `# comment`

Example:

```text
new ticket => TODO:
teh => the
open ai = OpenAI
```

## Per-app profiles

In Settings -> Per-App Profiles:
- capture the current frontmost app as a profile
- override auto-copy/auto-paste/clear-after-insert per app
- override command toggles per app
- add app-specific custom commands that merge with global commands

Profiles are resolved by frontmost app bundle identifier at finalization/copy/insert time.

## Streaming metrics

While recording/finalizing, the menu runtime UI shows:
- recording duration
- processed chunk count
- pending chunk queue depth
- latest chunk latency

## Architecture (current)

- `AudioTranscriber`: audio capture, queueing, inference, model loading, output polish/finalization.
- `AppProfile`: per-app output/command profile model.
- `CommandRule`: structured built-in and custom command map representation.
- `HotkeyMonitor`: global event tap, combo matching, hold/toggle state machine.
- `OnboardingView`: first-run setup and permission guidance.
- `ContentView`: runtime controls, status, and recent history.
- `SettingsView`: hotkey/output/model/permissions configuration.
- `AppDefaults`: centralized defaults and settings keys.

## Immediate roadmap to replacement grade

1. Add robust runtime verification and automated tests for hotkey and transcription/output state machines.
2. Improve streaming UX and latency perception further (partial token rendering and smoother intermediate text updates).
3. Expand command/macro actions beyond text replacements (editor/app actions, snippets, chained macros).
4. Improve model UX (download/manage multiple local models by name, not only file path).
5. Complete production packaging/release hardening (versioning, release notes, smoke checks, notarized artifacts).

## Development workflow

```bash
swift build
swift run OpenWhisper
```

## Release and notarization

This repo now includes:
- local release script: `scripts/release_macos.sh`
- GitHub Actions workflow: `.github/workflows/release-macos.yml`

### Local release script (unsigned by default)

```bash
scripts/release_macos.sh
```

Output artifact:
- `.artifacts/release/OpenWhisper.zip`

### Sign + notarize (local CI-style invocation)

Set these environment variables:
- `CODESIGN_IDENTITY` (Developer ID Application identity)
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`
- `SIGN_AND_NOTARIZE=1`

Then run:

```bash
SIGN_AND_NOTARIZE=1 scripts/release_macos.sh
```

### GitHub Actions secrets required

- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`
- `APPLE_DEVELOPER_ID_APPLICATION_CERT_BASE64`
- `APPLE_DEVELOPER_ID_APPLICATION_CERT_PASSWORD`

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
