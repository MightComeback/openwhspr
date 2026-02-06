//
//  OpenWhisperApp.swift
//  OpenWhisper
//
//  Menu bar app with hotkey monitoring.
//

import SwiftUI

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
            Label("OpenWhisper", systemImage: transcriber.isRecording ? "waveform.circle.fill" : "mic")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(transcriber: transcriber, hotkeyMonitor: hotkeyMonitor)
        }
    }
}
