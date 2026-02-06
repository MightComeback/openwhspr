//
//  ContentView.swift
//  OpenWhisper
//
//  Main menu bar view with transcription status.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var transcriber: AudioTranscriber
    @ObservedObject var hotkeyMonitor: HotkeyMonitor
    
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: transcriber.isRecording ? "mic.circle.fill" : "mic")
                .foregroundStyle(transcriber.isRecording ? .red : .primary)
                .font(.title2)
            
            Text(transcriber.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if !transcriber.transcription.isEmpty {
                Text(transcriber.transcription)
                    .font(.system(.body, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal)
            }
        }
        .padding()
        .frame(width: 220, maxHeight: 140)
        .onAppear {
            hotkeyMonitor.setTranscriber(transcriber)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(transcriber: transcriber)
        }
    }
}
