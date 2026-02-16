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
        return ViewHelpers.isInsertionFlashVisible(
            insertedAt: transcriber.lastSuccessfulInsertionAt,
            now: Date(),
            flashDuration: insertionFlashDuration
        )
    }

    private var iconName: String {
        ViewHelpers.menuBarIconName(
            isRecording: transcriber.isRecording,
            pendingChunkCount: transcriber.pendingChunkCount,
            hasTranscriptionText: !transcriber.transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            isShowingInsertionFlash: isShowingInsertionFlash
        )
    }

    private var durationLabel: String? {
        _ = tick

        let elapsed: Int? = {
            guard transcriber.isRecording, let startedAt = transcriber.recordingStartedAt else { return nil }
            return max(0, Int(Date().timeIntervalSince(startedAt).rounded(.down)))
        }()

        return ViewHelpers.menuBarDurationLabel(
            isRecording: transcriber.isRecording,
            pendingChunkCount: transcriber.pendingChunkCount,
            recordingElapsedSeconds: elapsed,
            isStartAfterFinalizeQueued: transcriber.isStartAfterFinalizeQueued,
            averageChunkLatency: transcriber.averageChunkLatencySeconds,
            lastChunkLatency: transcriber.lastChunkLatencySeconds,
            transcriptionWordCount: ViewHelpers.transcriptionWordCount(transcriber.transcription),
            isShowingInsertionFlash: isShowingInsertionFlash
        )
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
