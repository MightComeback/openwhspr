// SettingsView.swift
// OpenWhisper
//
// Settings window for configuration.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var transcriber: AudioTranscriber
    
    @AppStorage("hotkey.required") private var requiredRaw: String = "command,shift"
    @AppStorage("hotkey.forbidden") private var forbiddenRaw: String = "option,control"
    @AppStorage("hotkey.key") private var hotkeyKey: String = "space"
    
    private func formatHotkey() -> String {
        let reqNames = requiredRaw.components(separatedBy: ",").compactMap { part -> String? in
            let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            switch trimmed {
            case "command", "cmd": return "⌘"
            case "shift": return "⇧"
            case "option", "alt": return "⌥"
            case "control", "ctrl": return "⌃"
            case "capslock": return "⇪"
            default: return nil
            }
        }
        let key = displayKey(hotkeyKey)
        return reqNames.joined() + "+" + key
    }

    private func displayKey(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch trimmed {
        case "space": return "Space"
        case "tab": return "Tab"
        case "return", "enter": return "Return"
        case "escape", "esc": return "Esc"
        default:
            if trimmed.count == 1 {
                return trimmed.uppercased()
            }
            return trimmed
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("OpenWhisper Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Hotkey: \(formatHotkey())")
                    .font(.headline)
                
                Text("Configure your global hotkey below (comma-separated modifiers):")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text("Required:")
                    TextField("e.g. command,shift", text: $requiredRaw)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Text("Forbidden:")
                    TextField("e.g. option,control", text: $forbiddenRaw)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Text("Key:")
                    TextField("e.g. space", text: $hotkeyKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }

                Text("Global hotkeys use an event tap. Allow Input Monitoring (and Accessibility if prompted) in System Settings → Privacy & Security.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(transcriber.statusMessage)
                    .foregroundStyle(.secondary)
                
                if let error = transcriber.lastError {
                    Text("Error: \(error)")
                        .foregroundStyle(.red)
                }
                
                Text("Model: ggml-tiny.bin (\(formatBytes(sizeOfModel())))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 12) {
                Button("Copy Transcription") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(transcriber.transcription, forType: .string)
                }
                
                Button("Clear Transcription") {
                    transcriber.clearTranscription()
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 450, minHeight: 400)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func sizeOfModel() -> Int64 {
        guard let url = Bundle.module.url(forResource: "ggml-tiny", withExtension: "bin"),
              let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else {
            return 0
        }
        return size
    }
}

#Preview {
    SettingsView(transcriber: AudioTranscriber.shared)
}
