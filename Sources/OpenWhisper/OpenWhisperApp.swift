import SwiftUI

@main
struct OpenWhisperApp: App {
    @StateObject private var transcriber = AudioTranscriber()
    @StateObject private var hotkeyMonitor = HotkeyMonitor()
    @State private var isMenuBarExtraInserted = true
    
    var body: some Scene {
        WindowGroup {
            SettingsView(transcriber: transcriber)
                .task {
                    hotkeyMonitor.setHandler { [weak transcriber] in
                        transcriber?.toggleRecording()
                    }
                    hotkeyMonitor.start()
                    transcriber.requestPermissions()
                }
        }
        
        MenuBarExtra("🎤", isInserted: $isMenuBarExtraInserted) {
            VStack(alignment: .leading, spacing: 8) {
                if transcriber.isRecording {
                    Text("🔴 Listening…")
                        .font(.headline)
                        .foregroundStyle(.red)
                } else {
                    Text("Ready")
                        .font(.headline)
                        .foregroundStyle(.green)
                }
                
                Text(transcriber.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let error = transcriber.lastError {
                    Text("❌ \(error)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                Divider()
                
                Button(transcriber.isRecording ? "🛑 Stop" : "🎤 Start") {
                    transcriber.toggleRecording()
                }
                .keyboardShortcut(.space, modifiers: [])
                
                Button("Clear") {
                    transcriber.clearTranscription()
                }
                
                Button("Copy") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(transcriber.transcription, forType: .string)
                }
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: [.command])
            }
            .padding()
            .frame(minWidth: 200)
        }
        .menuBarExtraStyle(.window)
    }
}
