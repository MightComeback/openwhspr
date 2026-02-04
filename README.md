# OpenWhisper (openwhspr)

Native macOS dictation app — replaces SuperWhisper, AquaVoice, WhisperFlow.

## Core Features
- **Global Shortcut**: User-configurable hotkey to trigger dictation
- **Local Whisper**: On-device transcription using Whisper models
- **Live Transcription**: Real-time text as you speak
- **Visual Indicator**: Subtle UI showing dictation status
- **Dictionary**: Custom vocabulary and replacements
- **Fast**: Minimal latency, instant start/stop
- **Privacy-First**: Local transcription by default, optional cloud providers

## Architecture
- Swift/SwiftUI native macOS app
- Whisper.cpp for local inference
- Global hotkey via Carbon/EventTap
- Floating indicator window
- Menu bar extra for settings

