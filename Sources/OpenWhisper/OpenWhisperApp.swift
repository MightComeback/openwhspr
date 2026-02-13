//
//  OpenWhisperApp.swift
//  OpenWhisper
//
//  Menu bar app with hotkey monitoring.
//

import SwiftUI

/// Tiny helper view so we can use `.onReceive` inside the menu bar label
/// (Scene doesn't support view modifiers like onReceive, but a View does).
private struct MenuBarLabel: View {
    @ObservedObject var transcriber: AudioTranscriber
    @State private var tick = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    /// How long the "✓ Inserted" flash stays visible in the menu bar.
    private let insertionFlashDuration: TimeInterval = 3

    private var isShowingInsertionFlash: Bool {
        _ = tick
        guard let insertedAt = transcriber.lastSuccessfulInsertionAt else { return false }
        return Date().timeIntervalSince(insertedAt) < insertionFlashDuration
    }

    private var iconName: String {
        if isShowingInsertionFlash {
            return "checkmark.circle.fill"
        }
        if transcriber.isRecording {
            return "waveform.circle.fill"
        }
        if transcriber.pendingChunkCount > 0 {
            return "ellipsis.circle"
        }
        if !transcriber.transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "doc.text"
        }
        return "mic"
    }

    private var durationLabel: String? {
        _ = tick

        if isShowingInsertionFlash {
            return "Inserted"
        }

        if transcriber.isRecording,
           let startedAt = transcriber.recordingStartedAt {
            let elapsed = max(0, Int(Date().timeIntervalSince(startedAt).rounded(.down)))
            let minutes = elapsed / 60
            let seconds = elapsed % 60
            return String(format: "%d:%02d", minutes, seconds)
        }

        if !transcriber.isRecording, transcriber.pendingChunkCount > 0 {
            let pending = transcriber.pendingChunkCount
            let queuedStartSuffix = transcriber.isStartAfterFinalizeQueued ? "→●" : ""
            let latency = transcriber.averageChunkLatencySeconds > 0
                ? transcriber.averageChunkLatencySeconds
                : transcriber.lastChunkLatencySeconds
            if latency > 0 {
                let remaining = Int((Double(pending) * latency).rounded())
                return "\(pending)⏳\(remaining)s\(queuedStartSuffix)"
            }
            return "\(pending) left\(queuedStartSuffix)"
        }

        // Show word count when transcription text is ready to insert/copy,
        // so users can confirm at a glance that text is waiting.
        let text = transcriber.transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            let words = text.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).count
            return "\(words)w"
        }

        return nil
    }

    var body: some View {
        Group {
            if let duration = durationLabel {
                Label {
                    Text(duration)
                } icon: {
                    Image(systemName: iconName)
                }
            } else {
                Label("OpenWhisper", systemImage: iconName)
            }
        }
        .onReceive(timer) { now in
            guard transcriber.isRecording || transcriber.pendingChunkCount > 0 || isShowingInsertionFlash else { return }
            tick = now
        }
    }
}

@main
struct OpenWhisperApp: App {
    @StateObject private var transcriber: AudioTranscriber
    @StateObject private var hotkeyMonitor: HotkeyMonitor

    init() {
        AppDefaults.register()
        let sharedTranscriber = AudioTranscriber.shared
        _transcriber = StateObject(wrappedValue: sharedTranscriber)
        _hotkeyMonitor = StateObject(wrappedValue: HotkeyMonitor())
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(transcriber: transcriber, hotkeyMonitor: hotkeyMonitor)
        } label: {
            MenuBarLabel(transcriber: transcriber)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(transcriber: transcriber, hotkeyMonitor: hotkeyMonitor)
        }
    }
}
