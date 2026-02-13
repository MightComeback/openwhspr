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

    private var iconName: String {
        if transcriber.isRecording {
            return "waveform.circle.fill"
        }
        if transcriber.pendingChunkCount > 0 {
            return "ellipsis.circle"
        }
        return "mic"
    }

    private var durationLabel: String? {
        _ = tick

        if transcriber.isRecording,
           let startedAt = transcriber.recordingStartedAt {
            let elapsed = max(0, Int(Date().timeIntervalSince(startedAt).rounded(.down)))
            let minutes = elapsed / 60
            let seconds = elapsed % 60
            return String(format: "%d:%02d", minutes, seconds)
        }

        if !transcriber.isRecording, transcriber.pendingChunkCount > 0 {
            let pending = transcriber.pendingChunkCount
            return "\(pending) left"
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
            guard transcriber.isRecording || transcriber.pendingChunkCount > 0 else { return }
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
            Divider()
            Button("Settings…") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            MenuBarLabel(transcriber: transcriber)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(transcriber: transcriber, hotkeyMonitor: hotkeyMonitor)
        }
    }
}
