//
//  OpenWhisperApp.swift
//  OpenWhisper
//
//  Menu bar app with hotkey monitoring.
//

import SwiftUI

@main
struct OpenWhisperApp: App {
    @StateObject private var transcriber = AudioTranscriber.shared
    @StateObject private var hotkeyMonitor = HotkeyMonitor()
    
    var body: some Scene {
        MenuBarExtra("OpenWhisper", systemImage: "mic") {
            ContentView(transcriber: transcriber, hotkeyMonitor: hotkeyMonitor)
            Divider()
            Button("Settings") {
                // Settings opened via sheet in ContentView
            }
            .disabled(true) // Placeholder
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
