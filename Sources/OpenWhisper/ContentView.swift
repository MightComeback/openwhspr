// ContentView.swift
// Placeholder UI for dictation status

import SwiftUI

struct ContentView: View {
    @ObservedObject private var transcriber = AudioTranscriber.shared

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: transcriber.isRecording ? "mic.circle.fill" : "mic.circle")
                .font(.system(size: 60))
                .foregroundStyle(transcriber.isRecording ? .red : .primary)
                .animation(.easeInOut(duration: 0.2), value: transcriber.isRecording)

            Text("OpenWhisper")
                .font(.title)
                .fontWeight(.bold)

            Text(transcriber.statusMessage)
                .font(.headline)

            ScrollView {
                Text(transcriber.transcription)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 200)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 12) {
                Button(transcriber.isRecording ? "Stop Listening" : "Start Listening") {
                    transcriber.toggleRecording()
                }
                .buttonStyle(.borderedProminent)

                Button("Clear") {
                    transcriber.clearTranscription()
                }

                Button("Copy") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(transcriber.transcription, forType: .string)
                }
            }

            if let error = transcriber.lastError {
                Text("Error: \(error)")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .frame(width: 420, height: 480)
        .padding()
    }
}

#Preview {
    ContentView()
}