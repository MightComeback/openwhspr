// SettingsView.swift
// OpenWhisper
//
// Settings window for configuration.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var transcriber: AudioTranscriber
    
    var body: some View {
        VStack(spacing: 20) {
            Text("OpenWhisper Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Hotkey: Cmd + Shift + D")
                    .font(.headline)
                
                Text("Status: \(transcriber.statusMessage)")
                    .foregroundStyle(.secondary)
                
                if let error = transcriber.lastError {
                    Text("Error: \(error)")
                        .foregroundStyle(.red)
                }
                
                Text("Model: ggml-tiny.bin (\(formatBytes(sizeOfModel())))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button("Copy Transcription") {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(transcriber.transcription, forType: .string)
            }
            
            Button("Clear Transcription") {
                transcriber.clearTranscription()
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
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
    SettingsView(transcriber: AudioTranscriber())
}
