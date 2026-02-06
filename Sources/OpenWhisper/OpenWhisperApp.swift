import SwiftUI

@main
struct OpenWhisperApp: App {
    @StateObject private var transcriber = AudioTranscriber()
    @StateObject private var hotkeyMonitor = HotkeyMonitor()
    
    @AppStorage("hotkey.required") private var requiredRaw: String = "command,shift"
    @AppStorage("hotkey.forbidden") private var forbiddenRaw: String = "option,control"
    @AppStorage("hotkey.key") private var hotkeyKey: String = "d"
    
    @State private var isMenuBarExtraInserted = true
    
    private func parseModifiers(_ raw: String) -> NSEvent.ModifierFlags {
        let names = raw.components(separatedBy: ",").compactMap { part -> String? in
            let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return trimmed.isEmpty ? nil : trimmed
        }
        var flags: NSEvent.ModifierFlags = []
        for name in names {
            switch name {
            case "command", "cmd": flags.formUnion(.command)
            case "shift": flags.formUnion(.shift)
            case "option", "alt": flags.formUnion(.option)
            case "control", "ctrl": flags.formUnion(.control)
            case "capslock": flags.formUnion(.capsLock)
            default: break
            }
        }
        return flags
    }
    
    private func updateHotkeyConfig() {
        let req = parseModifiers(requiredRaw)
        let forb = parseModifiers(forbiddenRaw)
        hotkeyMonitor.updateConfig(required: req, forbidden: forb, key: hotkeyKey)
    }
    
    var body: some Scene {
        WindowGroup {
            SettingsView(transcriber: transcriber)
                .task {
                    hotkeyMonitor.setHandler { [weak transcriber] in
                        transcriber?.toggleRecording()
                    }
                    hotkeyMonitor.start()
                    updateHotkeyConfig()
                }
                .onChange(of: requiredRaw) { _ in
                    updateHotkeyConfig()
                }
                .onChange(of: forbiddenRaw) { _ in
                    updateHotkeyConfig()
                }
                .onChange(of: hotkeyKey) { _ in
                    updateHotkeyConfig()
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