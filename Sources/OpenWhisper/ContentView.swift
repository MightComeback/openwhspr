// ContentView.swift
// OpenWhisper
//
//  Created by Continuous Shipping Loop on 2026-02-05.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var transcriber: AudioTranscriber

    var body: some View {
        VStack(spacing: 20) {
            Text("OpenWhisper")
                .font(.largeTitle)
                .fontWeight(.bold)

            if transcriber.isRecording {
                Text("🔴 Listening…")
                    .font(.title2)
                    .foregroundStyle(.green)
            } else {
                Text("Ready for dictation")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                Text(transcriber.transcription)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(minHeight: 100)

            Button(transcriber.isRecording ? "🛑 Stop Dictation" : "🎤 Start Dictation") {
                transcriber.toggleRecording()
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(transcriber.isRecording ? Color.red.opacity(0.8) : Color.blue.opacity(0.8))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(transcriber.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let error = transcriber.lastError {
                Text("❌ \(error)")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .frame(minWidth: 450, minHeight: 400)
        .padding()
        .onAppear {
            transcriber.requestPermissions()
            
            // Global hotkey: Cmd + Shift + D
            let monitor = HotkeyMonitor { [weak transcriber] in
                transcriber?.toggleRecording()
            }
            monitor.start()
        }
    }
}

#Preview {
    ContentView(transcriber: AudioTranscriber())
}
