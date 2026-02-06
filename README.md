# OpenWhisper (`openwhspr`)

A native, open-source, local-first macOS dictation app.

OpenWhisper is built to be a serious alternative to tools like SuperWhisper, Aqua Voice, and WhisperFlow, while keeping a strict local-first default: no account, no required cloud, no telemetry dependency.

## Project status

OpenWhisper is currently an alpha-quality app with a working local transcription pipeline and a production-oriented macOS UX foundation.

## Principles

- Local first: all core dictation runs on-device by default.
- Open source: transparent architecture and configurable behavior.
- Fast interaction loop: global hotkey, low-friction start/stop, instant output actions.
- Privacy by default: no mandatory cloud service for primary functionality.

## What works today

- Native macOS menu bar app (`SwiftUI`, `AVAudioEngine`).
- On-device transcription via `SwiftWhisper` + bundled local model.
- Global hotkey capture with configurable:
- Required/forbidden modifiers
- Trigger key
- Dictation mode (`toggle` or `hold-to-talk`)
- Real-time status UI with input level meter.
- Session finalization pipeline:
- Chunked transcription queue (no dropped chunks while transcribing)
- Optional auto-copy to clipboard
- Optional auto-paste to active app
- Optional clear-after-insert
- Text replacement rules (`from => to`) for cleanup.
- Recent transcription history in the menu UI.

## Next milestones

- Better model management (download/swap tiny/base/small/large models).
- Streaming/partial token rendering for lower perceived latency.
- Rich post-processing pipeline (punctuation, capitalization, command macros).
- Optional provider abstraction for cloud fallback (opt-in only).
- Stronger test coverage around hotkey state machine and transcription queueing.
- Signed release pipeline and notarized distributables.

## Requirements

- macOS 14+
- Xcode 15.4+ (or Swift 6 toolchain)

## Quick start

```bash
git clone git@github.com:MightComeback/openwhspr.git
cd openwhspr
swift build
swift run OpenWhisper
```

## Permissions (required)

OpenWhisper needs these permissions for full functionality:

- Microphone: capture dictation audio.
- Accessibility: global hotkeys and auto-paste to other apps.
- Input Monitoring: required by event-tap based global key monitoring on many macOS setups.

Grant in:
`System Settings -> Privacy & Security`

## Hotkey behavior

Hotkeys are evaluated against:

- Required modifiers (must all be pressed)
- Forbidden modifiers (must not be pressed)
- Trigger key

Modes:

- Toggle: pressing the combo starts/stops recording.
- Hold to talk: recording starts on key down and stops on key up.

## Replacement rules

In Settings -> Text cleanup:

- Add one rule per line.
- Supported formats:
- `from => to`
- `from = to`
- `#` prefix comments are ignored.

Examples:

```text
teh => the
open ai = OpenAI
```

## Local-first and privacy model

- Core dictation path is fully local by default.
- No required remote inference endpoint.
- No mandatory account/login.
- Output is written only to local process memory + system clipboard when enabled.

## Architecture (current)

- `AudioTranscriber`: audio capture, chunking, Whisper inference, session finalization.
- `HotkeyMonitor`: global event tap, combo matching, toggle/hold state machine.
- `ContentView`: menu bar runtime controls and history.
- `SettingsView`: hotkey/output/replacement/permission configuration.
- `AppDefaults`: centralized default settings keys.

## Developer workflow

```bash
swift build
swift run OpenWhisper
```

Useful during iteration:

- Keep `swift build` passing after each feature commit.
- Validate permission prompts after hotkey/auto-paste changes.
- Test both hotkey modes (`toggle` and `hold-to-talk`).

## Contributing

Issues and PRs are welcome. High-impact contribution areas:

- transcription quality/latency improvements
- model management UX
- deterministic tests for hotkey and audio chunk state machines
- packaging/release automation

If you submit a PR, include:

- what changed
- why it changed
- how you validated it (`swift build` + behavior notes)
