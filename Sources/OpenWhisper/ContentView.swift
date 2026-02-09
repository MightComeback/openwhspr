//
//  ContentView.swift
//  OpenWhisper
//
//  Main menu bar view with transcription controls.
//

@preconcurrency import AVFoundation
@preconcurrency import AppKit
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
                    Text(statusTitle())
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

            if transcriber.isRecording || transcriber.pendingChunkCount > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Streaming metrics")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("Duration")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatDuration(recordingDuration()))
                            .font(.caption2)
                    }

                    HStack {
                        Text("Chunks")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(transcriber.processedChunkCount) processed • \(transcriber.pendingChunkCount) pending")
                            .font(.caption2)
                    }

                    if transcriber.lastChunkLatencySeconds > 0 {
                        HStack {
                            Text("Last chunk latency")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.2fs", transcriber.lastChunkLatencySeconds))
                                .font(.caption2)
                        }
                    }
                }
                .padding(8)
                .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
            }

            if !microphoneAuthorized || !accessibilityAuthorized || !inputMonitoringAuthorized {
                VStack(alignment: .leading, spacing: 8) {
                    if !microphoneAuthorized {
                        permissionRow(
                            title: "Microphone",
                            detail: "Required for dictation audio.",
                            requestTitle: "Request",
                            request: {
                                Task { @MainActor in
                                    transcriber.requestMicrophonePermission()
                                }
                            },
                            settingsPane: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
                        )
                    }

                    if !accessibilityAuthorized {
                        permissionRow(
                            title: "Accessibility",
                            detail: "Required for global hotkeys and auto-paste.",
                            requestTitle: "Request",
                            request: {
                                HotkeyMonitor.requestAccessibilityPermissionPrompt()
                            },
                            settingsPane: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                        )
                    }

                    if !inputMonitoringAuthorized {
                        permissionRow(
                            title: "Input Monitoring",
                            detail: "Required for reliable global key capture.",
                            requestTitle: "Request",
                            request: {
                                HotkeyMonitor.requestInputMonitoringPermissionPrompt()
                            },
                            settingsPane: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
                        )
                    }
                }
                .padding(10)
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

    private func statusTitle() -> String {
        if transcriber.isRecording {
            return "Recording"
        }
        if transcriber.pendingChunkCount > 0 {
            return "Finalizing"
        }
        return "Ready"
    }

    private func recordingDuration() -> TimeInterval {
        guard let startedAt = transcriber.recordingStartedAt else { return 0 }
        return max(0, Date().timeIntervalSince(startedAt))
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds.rounded()))
        let minutes = total / 60
        let remainder = total % 60
        return String(format: "%d:%02d", minutes, remainder)
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

    @ViewBuilder
    private func permissionRow(
        title: String,
        detail: String,
        requestTitle: String,
        request: @escaping () -> Void,
        settingsPane: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                Button(requestTitle, action: request)
                    .buttonStyle(.bordered)
                    .controlSize(.mini)

                Button("Open Settings") {
                    openSystemSettingsPane(settingsPane)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
        }
    }

    private func openSystemSettingsPane(_ paneURL: String) {
        guard let url = URL(string: paneURL) else { return }
        NSWorkspace.shared.open(url)
    }
}
