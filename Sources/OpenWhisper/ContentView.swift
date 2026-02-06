//
//  ContentView.swift
//  OpenWhisper
//
//  Main menu bar view with transcription controls.
//

@preconcurrency import AVFoundation
import SwiftUI

struct ContentView: View {
    @ObservedObject var transcriber: AudioTranscriber
    @ObservedObject var hotkeyMonitor: HotkeyMonitor

    @AppStorage(AppDefaults.Keys.onboardingCompleted) private var onboardingCompleted: Bool = false

    @State private var microphoneAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    @State private var accessibilityAuthorized = HotkeyMonitor.hasAccessibilityPermission()
    @State private var inputMonitoringAuthorized = HotkeyMonitor.hasInputMonitoringPermission()
    @State private var showingOnboarding = false

    private let permissionTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: transcriber.isRecording ? "waveform.circle.fill" : "mic.circle")
                    .font(.title2)
                    .foregroundStyle(transcriber.isRecording ? .red : .primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(transcriber.isRecording ? "Recording" : "Ready")
                        .font(.headline)
                    Text("Hotkey: \(hotkeySummary())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(transcriber.isRecording ? "Stop" : "Start") {
                    Task { @MainActor in
                        transcriber.toggleRecording()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if transcriber.isRecording {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Input level")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ProgressView(value: Double(transcriber.inputLevel))
                        .progressViewStyle(.linear)
                }
            }

            if !microphoneAuthorized || !accessibilityAuthorized || !inputMonitoringAuthorized {
                VStack(alignment: .leading, spacing: 4) {
                    if !microphoneAuthorized {
                        Text("Microphone access is required for dictation.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if !accessibilityAuthorized {
                        Text("Accessibility access is required for global hotkeys and auto-paste.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if !inputMonitoringAuthorized {
                        Text("Input Monitoring is required for reliable global hotkeys.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(8)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }

            Text(transcriber.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let error = transcriber.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if !transcriber.transcription.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current transcription")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ScrollView {
                        Text(transcriber.transcription)
                            .font(.system(.body, design: .rounded))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 110)
                    .padding(8)
                    .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))

                    HStack {
                        Button("Copy") {
                            Task { @MainActor in
                                _ = transcriber.copyTranscriptionToClipboard()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button("Insert") {
                            Task { @MainActor in
                                _ = transcriber.insertTranscriptionIntoFocusedApp()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button("Clear") {
                            Task { @MainActor in
                                transcriber.clearTranscription()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            if !transcriber.recentEntries.isEmpty {
                Divider()

                HStack {
                    Text("Recent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Clear history") {
                        Task { @MainActor in
                            transcriber.clearHistory()
                        }
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }

                VStack(spacing: 6) {
                    ForEach(Array(transcriber.recentEntries.prefix(3))) { entry in
                        HStack(alignment: .top, spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.text)
                                    .lineLimit(2)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(entry.createdAt.formatted(date: .omitted, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Button {
                                Task { @MainActor in
                                    transcriber.transcription = entry.text
                                }
                            } label: {
                                Image(systemName: "arrow.uturn.backward.circle")
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(6)
                        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }

            Divider()

            HStack {
                Button("Settings…") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .buttonStyle(.borderless)

                Button("Onboarding…") {
                    showingOnboarding = true
                }
                .buttonStyle(.borderless)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(14)
        .frame(width: 360)
        .onAppear {
            hotkeyMonitor.setTranscriber(transcriber)
            refreshPermissionState()
            if !onboardingCompleted {
                showingOnboarding = true
            }
        }
        .onReceive(permissionTimer) { _ in
            refreshPermissionState()
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView(transcriber: transcriber)
        }
    }

    private func refreshPermissionState() {
        microphoneAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        accessibilityAuthorized = HotkeyMonitor.hasAccessibilityPermission()
        inputMonitoringAuthorized = HotkeyMonitor.hasInputMonitoringPermission()
    }

    private func hotkeySummary() -> String {
        let defaults = UserDefaults.standard
        var parts: [String] = []

        if defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredCommand) { parts.append("⌘") }
        if defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredShift) { parts.append("⇧") }
        if defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredOption) { parts.append("⌥") }
        if defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredControl) { parts.append("⌃") }
        if defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredCapsLock) { parts.append("⇪") }

        let key = defaults.string(forKey: AppDefaults.Keys.hotkeyKey) ?? "space"
        let displayKey = displayKeyName(key)
        parts.append(displayKey)
        return parts.joined(separator: "+")
    }

    private func displayKeyName(_ raw: String) -> String {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "space": return "Space"
        case "tab": return "Tab"
        case "return", "enter": return "Return"
        case "escape", "esc": return "Esc"
        default:
            if normalized.count == 1 {
                return normalized.uppercased()
            }
            return normalized.capitalized
        }
    }
}
