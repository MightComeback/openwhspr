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
    @State private var lastHotkeyPermissionsReady: Bool = HotkeyMonitor.hasAccessibilityPermission() && HotkeyMonitor.hasInputMonitoringPermission()
    @State private var insertTargetAppName: String? = nil
    @State private var insertTargetDisplay: String? = nil
    @State private var showingOnboarding = false
    @State private var uiNow = Date()

    private let permissionTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    private let recordingMetricsTimer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    private let appActivationPublisher = NotificationCenter.default.publisher(
        for: NSWorkspace.didActivateApplicationNotification,
        object: NSWorkspace.shared
    )

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

                    Text(hotkeyMonitor.statusMessage)
                        .font(.caption2)
                        .foregroundColor(hotkeyMonitor.isHotkeyActive ? .secondary : .orange)
                }

                Spacer()

                Button(startStopButtonTitle()) {
                    Task { @MainActor in
                        transcriber.toggleRecording()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!canToggleRecording)
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

                    if transcriber.processedChunkCount > 1,
                       transcriber.averageChunkLatencySeconds > 0 {
                        HStack {
                            Text("Avg chunk latency")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.2fs", transcriber.averageChunkLatencySeconds))
                                .font(.caption2)
                        }
                    }

                    if let remaining = estimatedFinalizationSeconds {
                        HStack {
                            Text("Estimated finalize")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("~\(formatShortDuration(remaining))")
                                .font(.caption2)
                        }
                    }

                    if transcriber.isStartAfterFinalizeQueued {
                        Text("Next recording is queued. Press hotkey again to cancel.")
                            .font(.caption2)
                            .foregroundStyle(.orange)
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
                        .keyboardShortcut("c", modifiers: [.command])
                        .disabled(!hasTranscriptionText)

                        Button(insertButtonTitle()) {
                            Task { @MainActor in
                                if canInsertDirectly {
                                    _ = transcriber.insertTranscriptionIntoFocusedApp()
                                } else {
                                    _ = transcriber.copyTranscriptionToClipboard()
                                }
                                refreshInsertTargetSnapshot()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .help(insertButtonHelpText())
                        .controlSize(.small)
                        .keyboardShortcut(.return, modifiers: [.command])
                        .disabled(!canInsertNow)

                        Button(retargetButtonTitle()) {
                            Task { @MainActor in
                                refreshInsertTargetSnapshot()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .keyboardShortcut("r", modifiers: [.command, .shift])
                        .help("Refresh insertion target from your current front app")

                        Button(transcriber.isRunningInsertionProbe ? "Probing…" : "Probe Insert") {
                            Task { @MainActor in
                                _ = transcriber.runInsertionProbe()
                                refreshInsertTargetSnapshot()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(transcriber.isRecording || transcriber.pendingChunkCount > 0 || transcriber.isRunningInsertionProbe)

                        Button("Clear") {
                            Task { @MainActor in
                                transcriber.clearTranscription()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(!hasTranscriptionText)
                    }

                    if !accessibilityAuthorized {
                        HStack(spacing: 6) {
                            Text("Insert needs Accessibility permission. Command+Return copies to clipboard until enabled.")
                                .font(.caption2)
                                .foregroundStyle(.orange)

                            Button("Enable Insert") {
                                openSystemSettingsPane("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
                            }
                            .buttonStyle(.borderless)
                            .font(.caption2)
                        }
                    }

                    if let insertTargetAppName, !insertTargetAppName.isEmpty {
                        if let insertTargetDisplay, !insertTargetDisplay.isEmpty {
                            Text("Insert target: \(insertTargetDisplay)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Insert target: \(insertTargetAppName)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        if shouldSuggestRetarget,
                           let currentFrontAppName = currentExternalFrontAppName() {
                            Text("Current front app is \(currentFrontAppName). Click Retarget if you want Insert to follow it.")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Text("If target is unknown, Insert will use your last active app. Target stays fixed once text is ready; click Retarget to refresh.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if let probeDate = transcriber.lastInsertionProbeDate {
                        Text("\(transcriber.lastInsertionProbeSucceeded == true ? "✅" : "⚠️") \(transcriber.lastInsertionProbeMessage) · \(probeDate.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(transcriber.lastInsertionProbeSucceeded == true ? Color.secondary : Color.orange)
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
            uiNow = Date()
            refreshPermissionState()
            if !onboardingCompleted {
                showingOnboarding = true
            }
        }
        .onReceive(permissionTimer) { _ in
            refreshPermissionState()
        }
        .onReceive(recordingMetricsTimer) { now in
            guard transcriber.isRecording || transcriber.pendingChunkCount > 0 else {
                return
            }
            uiNow = now
        }
        .onReceive(appActivationPublisher) { notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }
            guard app.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
                return
            }
            refreshInsertTargetAppName()
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView(transcriber: transcriber)
        }
    }

    private func refreshPermissionState() {
        microphoneAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        accessibilityAuthorized = HotkeyMonitor.hasAccessibilityPermission()
        inputMonitoringAuthorized = HotkeyMonitor.hasInputMonitoringPermission()

        refreshInsertTargetAppName()

        let hotkeyReady = accessibilityAuthorized && inputMonitoringAuthorized
        if hotkeyReady && !lastHotkeyPermissionsReady {
            hotkeyMonitor.start()
        } else if !hotkeyReady && lastHotkeyPermissionsReady {
            hotkeyMonitor.stop()
        }
        lastHotkeyPermissionsReady = hotkeyReady
    }

    private func refreshInsertTargetAppName() {
        // Keep the insertion target stable once text is ready to insert.
        // Without this guard, passive app-switch events can retarget insertion
        // away from the intended destination right before Command+Return.
        let shouldFreezeTarget = hasTranscriptionText && canInsertNow && insertTargetAppName != nil
        guard !shouldFreezeTarget else { return }

        Task { @MainActor in
            refreshInsertTargetSnapshot()
        }
    }

    @MainActor
    private func refreshInsertTargetSnapshot() {
        insertTargetAppName = transcriber.manualInsertTargetAppName()
        insertTargetDisplay = transcriber.manualInsertTargetDisplay()
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
        return max(0, uiNow.timeIntervalSince(startedAt))
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds.rounded()))
        let minutes = total / 60
        let remainder = total % 60
        return String(format: "%d:%02d", minutes, remainder)
    }

    private func formatShortDuration(_ seconds: TimeInterval) -> String {
        let rounded = Int(max(0, seconds.rounded()))
        if rounded < 60 {
            return "\(rounded)s"
        }

        let minutes = rounded / 60
        let remainder = rounded % 60
        return "\(minutes)m \(remainder)s"
    }

    private var estimatedFinalizationSeconds: TimeInterval? {
        guard transcriber.pendingChunkCount > 0 else {
            return nil
        }

        let latency = transcriber.averageChunkLatencySeconds > 0
            ? transcriber.averageChunkLatencySeconds
            : transcriber.lastChunkLatencySeconds

        guard latency > 0 else {
            return nil
        }

        return Double(transcriber.pendingChunkCount) * latency
    }

    private func hotkeySummary() -> String {
        HotkeyDisplay.summaryIncludingMode()
    }

    private var canToggleRecording: Bool {
        transcriber.isRecording || transcriber.pendingChunkCount == 0
    }

    private func startStopButtonTitle() -> String {
        if transcriber.isRecording {
            return "Stop"
        }
        if transcriber.pendingChunkCount > 0 {
            return "Finalizing…"
        }
        return "Start"
    }

    private var canInsertDirectly: Bool {
        accessibilityAuthorized
    }

    private var hasTranscriptionText: Bool {
        !transcriber.transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canInsertNow: Bool {
        hasTranscriptionText && !transcriber.isRecording && transcriber.pendingChunkCount == 0
    }

    private func insertButtonTitle() -> String {
        if canInsertDirectly {
            guard let target = insertTargetAppName, !target.isEmpty else {
                return "Insert → Last App"
            }
            return "Insert → \(abbreviatedAppName(target))"
        }

        guard let target = insertTargetAppName, !target.isEmpty else {
            return "Copy → Clipboard"
        }
        return "Copy → \(abbreviatedAppName(target))"
    }

    private func insertButtonHelpText() -> String {
        guard hasTranscriptionText else {
            return "No transcription to insert yet"
        }

        guard canInsertNow else {
            return "Stop recording and wait for pending chunks to finish before inserting"
        }

        guard canInsertDirectly else {
            if let target = insertTargetAppName, !target.isEmpty {
                return "Accessibility permission is missing, so this will copy text for \(target)"
            }
            return "Accessibility permission is missing, so this will copy transcription to clipboard"
        }

        guard let target = insertTargetAppName, !target.isEmpty else {
            return "Insert into the last active app"
        }

        return "Insert into \(target)"
    }

    private func retargetButtonTitle() -> String {
        guard let target = insertTargetAppName, !target.isEmpty else {
            return "Retarget"
        }
        return "Retarget → \(abbreviatedAppName(target))"
    }

    private var shouldSuggestRetarget: Bool {
        guard hasTranscriptionText, canInsertNow else {
            return false
        }

        guard let target = insertTargetAppName?.trimmingCharacters(in: .whitespacesAndNewlines), !target.isEmpty else {
            return false
        }

        guard let front = currentExternalFrontAppName() else {
            return false
        }

        return target.caseInsensitiveCompare(front) != .orderedSame
    }

    private func currentExternalFrontAppName() -> String? {
        let candidate = transcriber.frontmostAppName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty else { return nil }
        guard candidate.caseInsensitiveCompare("Unknown App") != .orderedSame else { return nil }
        guard candidate.caseInsensitiveCompare("OpenWhisper") != .orderedSame else { return nil }
        return candidate
    }

    private func abbreviatedAppName(_ name: String, maxCharacters: Int = 18) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxCharacters else { return trimmed }

        let prefixLength = max(1, maxCharacters - 1)
        let endIndex = trimmed.index(trimmed.startIndex, offsetBy: prefixLength)
        return String(trimmed[..<endIndex]) + "…"
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
