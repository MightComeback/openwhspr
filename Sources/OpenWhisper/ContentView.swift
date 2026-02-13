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
    @State private var insertTargetBundleIdentifier: String? = nil
    @State private var insertTargetDisplay: String? = nil
    @State private var insertTargetUsesFallback = false
    @State private var insertTargetCapturedAt: Date? = nil
    @State private var showingOnboarding = false
    @State private var uiNow = Date()
    @State private var finalizationInitialPendingChunks: Int? = nil
    @State private var lastClearedTranscription: String? = nil

    private let insertTargetStaleAfterSeconds: TimeInterval = 90

    private let permissionTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    private let recordingMetricsTimer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    private let insertTargetStatusTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
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
                .help(startStopButtonHelpText())
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

                    if let wordsPerMinute = liveWordsPerMinute {
                        HStack {
                            Text("Live speed")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(wordsPerMinute) wpm")
                                .font(.caption2)
                        }
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

                    if let progress = finalizationProgress {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Finalize progress")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(Int((progress * 100).rounded()))%")
                                    .font(.caption2)
                            }

                            ProgressView(value: progress)
                                .progressViewStyle(.linear)
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
                    HStack {
                        Text("Current transcription")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(transcriptionStats)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    ScrollView {
                        Text(transcriber.transcription)
                            .font(.system(.body, design: .rounded))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 110)
                    .padding(8)
                    .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))

                    // Primary actions
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
                                if insertTargetAppName == nil {
                                    refreshInsertTargetSnapshot()
                                }

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

                        Spacer()

                        if lastClearedTranscription != nil {
                            Button("Undo") {
                                Task { @MainActor in
                                    if let restored = lastClearedTranscription {
                                        transcriber.transcription = restored
                                        lastClearedTranscription = nil
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .keyboardShortcut("z", modifiers: [.command])
                            .disabled(transcriber.isRecording || transcriber.pendingChunkCount > 0)
                        }

                        Button("Clear") {
                            Task { @MainActor in
                                lastClearedTranscription = transcriber.transcription
                                transcriber.clearTranscription()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .keyboardShortcut(.delete, modifiers: [.command])
                        .disabled(!hasTranscriptionText)
                    }

                    // Secondary insertion actions (collapsed by default)
                    DisclosureGroup("More actions") {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Button(retargetAndInsertButtonTitle()) {
                                    Task { @MainActor in
                                        refreshInsertTargetSnapshot()
                                        if canInsertDirectly {
                                            _ = transcriber.insertTranscriptionIntoFocusedApp()
                                        } else {
                                            _ = transcriber.copyTranscriptionToClipboard()
                                        }
                                        refreshInsertTargetSnapshot()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .help(retargetAndInsertHelpText())
                                .controlSize(.small)
                                .keyboardShortcut(.return, modifiers: [.command, .shift])
                                .disabled(!canInsertNow)

                                Button(useCurrentAppButtonTitle()) {
                                    Task { @MainActor in
                                        refreshInsertTargetSnapshot()
                                        if canInsertDirectly {
                                            _ = transcriber.insertTranscriptionIntoFocusedApp()
                                        } else {
                                            _ = transcriber.copyTranscriptionToClipboard()
                                        }
                                        refreshInsertTargetSnapshot()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .keyboardShortcut(.return, modifiers: [.command, .option])
                                .help(useCurrentAppButtonHelpText())
                                .disabled(!canInsertNow)
                            }

                            HStack {
                                Button(retargetButtonTitle()) {
                                    Task { @MainActor in
                                        refreshInsertTargetSnapshot()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .keyboardShortcut("r", modifiers: [.command, .shift])
                                .help(retargetButtonHelpText())
                                .disabled(!canRetargetInsertTarget)

                                Button(focusTargetButtonTitle()) {
                                    Task { @MainActor in
                                        _ = transcriber.focusManualInsertTargetApp()
                                        refreshInsertTargetSnapshot()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .keyboardShortcut("f", modifiers: [.command, .shift])
                                .help(focusTargetButtonHelpText())
                                .disabled(!hasResolvableInsertTarget || transcriber.isRecording || transcriber.pendingChunkCount > 0)

                                Button(focusAndInsertButtonTitle()) {
                                    Task { @MainActor in
                                        let focused = transcriber.focusManualInsertTargetApp()
                                        guard focused || !canInsertDirectly else {
                                            refreshInsertTargetSnapshot()
                                            return
                                        }

                                        if canInsertDirectly {
                                            _ = transcriber.insertTranscriptionIntoFocusedApp()
                                        } else {
                                            _ = transcriber.copyTranscriptionToClipboard()
                                        }
                                        refreshInsertTargetSnapshot()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .keyboardShortcut("f", modifiers: [.command, .option])
                                .help(focusAndInsertButtonHelpText())
                                .disabled(!canInsertNow || !hasResolvableInsertTarget)
                            }

                            HStack {
                                Button(transcriber.isRunningInsertionProbe ? "Probing…" : "Probe Insert") {
                                    Task { @MainActor in
                                        _ = transcriber.runInsertionProbe()
                                        refreshInsertTargetSnapshot()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(transcriber.isRecording || transcriber.pendingChunkCount > 0 || transcriber.isRunningInsertionProbe)
                            }
                        }
                    }
                    .font(.caption)

                    if let insertActionDisabledReason {
                        Text(insertActionDisabledReason)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
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

                        if let targetAge = insertTargetAgeDescription() {
                            Text("Target captured \(targetAge)")
                                .font(.caption2)
                                .foregroundStyle(isInsertTargetStale ? .orange : .secondary)
                        }

                        if isInsertTargetLocked {
                            Text("Target is locked to avoid accidental app switches. Use Retarget if you changed destination.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        if shouldSuggestRetarget,
                           let currentFrontAppName = currentExternalFrontAppName() {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("Current front app is \(currentFrontAppName).")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)

                                Button("Retarget now") {
                                    Task { @MainActor in
                                        refreshInsertTargetSnapshot()
                                    }
                                }
                                .buttonStyle(.borderless)
                                .font(.caption2)
                                .keyboardShortcut("r", modifiers: [.command, .option])
                                .help("Update Insert target to the current front app (⌘⌥R)")

                                Text("⌘⌥↩ inserts into current app")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else if isInsertTargetStale {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("Insert target snapshot is getting stale.")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)

                                Button("Retarget now") {
                                    Task { @MainActor in
                                        refreshInsertTargetSnapshot()
                                    }
                                }
                                .buttonStyle(.borderless)
                                .font(.caption2)
                                .keyboardShortcut("r", modifiers: [.command, .option])
                                .help("Refresh insertion target from your current front app (⌘⌥R)")
                            }
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
                                HStack(spacing: 6) {
                                    Text(entry.createdAt.formatted(date: .omitted, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text("·")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    Text(historyEntryStats(entry))
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
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
            refreshFinalizationProgressBaseline(pendingChunks: transcriber.pendingChunkCount)
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
        .onReceive(insertTargetStatusTimer) { now in
            guard hasTranscriptionText, insertTargetCapturedAt != nil else {
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
        .onReceive(transcriber.$isRecording.removeDuplicates()) { isRecording in
            hotkeyMonitor.refreshStatusFromRuntimeState()
            refreshFinalizationProgressBaseline(pendingChunks: transcriber.pendingChunkCount)

            // Front-app insertion UX: lock/refresh the manual insert target
            // as soon as recording starts, before any transcript text appears.
            // This preserves the user's intended destination app even if they
            // switch windows while speaking.
            if isRecording {
                lastClearedTranscription = nil
                Task { @MainActor in
                    refreshInsertTargetSnapshot()
                }
            }
        }
        .onReceive(transcriber.$pendingChunkCount.removeDuplicates()) { pending in
            hotkeyMonitor.refreshStatusFromRuntimeState()
            refreshFinalizationProgressBaseline(pendingChunks: pending)
        }
        .onReceive(transcriber.$transcription.removeDuplicates()) { transcription in
            let hasText = !transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            guard hasText else { return }

            let currentTarget = insertTargetAppName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard currentTarget.isEmpty else { return }

            Task { @MainActor in
                refreshInsertTargetSnapshot()
            }
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
        // In clipboard-only mode (Accessibility missing), keep tracking the
        // front app live because no direct insertion target is locked.
        let shouldFreezeTarget = hasTranscriptionText && canInsertNow && canInsertDirectly && insertTargetAppName != nil
        guard !shouldFreezeTarget else { return }

        Task { @MainActor in
            refreshInsertTargetSnapshot()
        }
    }

    @MainActor
    private func refreshInsertTargetSnapshot() {
        let snapshot = transcriber.manualInsertTargetSnapshot()
        insertTargetAppName = snapshot.appName
        insertTargetBundleIdentifier = snapshot.bundleIdentifier
        insertTargetDisplay = snapshot.display
        insertTargetUsesFallback = snapshot.usesFallbackApp

        if let appName = insertTargetAppName?.trimmingCharacters(in: .whitespacesAndNewlines), !appName.isEmpty {
            insertTargetCapturedAt = Date()
        } else {
            insertTargetCapturedAt = nil
        }
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

    private var liveWordsPerMinute: Int? {
        let duration = recordingDuration()
        guard duration >= 5 else {
            return nil
        }

        let words = transcriber.transcription
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .count

        guard words > 0 else {
            return nil
        }

        let perMinute = Double(words) * 60 / duration
        return max(1, Int(perMinute.rounded()))
    }

    private func refreshFinalizationProgressBaseline(pendingChunks: Int) {
        if transcriber.isRecording {
            finalizationInitialPendingChunks = nil
            return
        }

        guard pendingChunks > 0 else {
            finalizationInitialPendingChunks = nil
            return
        }

        if let currentBaseline = finalizationInitialPendingChunks {
            finalizationInitialPendingChunks = max(currentBaseline, pendingChunks)
        } else {
            finalizationInitialPendingChunks = pendingChunks
        }
    }

    private var finalizationProgress: Double? {
        let pending = transcriber.pendingChunkCount

        guard !transcriber.isRecording,
              pending > 0,
              let initialPending = finalizationInitialPendingChunks,
              initialPending > 0 else {
            return nil
        }

        let completed = max(0, initialPending - pending)
        let rawProgress = Double(completed) / Double(initialPending)
        return min(max(rawProgress, 0), 1)
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
        if transcriber.isRecording || transcriber.pendingChunkCount > 0 {
            return true
        }
        return microphoneAuthorized
    }

    private func startStopButtonHelpText() -> String {
        guard !microphoneAuthorized,
              !transcriber.isRecording,
              transcriber.pendingChunkCount == 0 else {
            return transcriber.isRecording
                ? "Stop recording"
                : "Start recording"
        }

        return "Microphone permission is required before recording can start"
    }

    private func startStopButtonTitle() -> String {
        if transcriber.isRecording {
            return "Stop"
        }
        if transcriber.pendingChunkCount > 0 {
            return transcriber.isStartAfterFinalizeQueued ? "Cancel queued start" : "Queue start"
        }
        return "Start"
    }

    private var canInsertDirectly: Bool {
        accessibilityAuthorized
    }

    private var transcriptionStats: String {
        let text = transcriber.transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = text.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).count
        let chars = text.count
        return "\(words)w · \(chars)c"
    }

    private var hasTranscriptionText: Bool {
        !transcriber.transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canInsertNow: Bool {
        insertActionDisabledReason == nil
    }

    private var insertActionDisabledReason: String? {
        if !hasTranscriptionText {
            return "No transcription to insert yet"
        }

        if transcriber.isRunningInsertionProbe {
            return "Wait for the insertion probe to finish"
        }

        if transcriber.isRecording || transcriber.pendingChunkCount > 0 {
            return "Stop recording and wait for pending chunks"
        }

        return nil
    }

    private func insertButtonTitle() -> String {
        if canInsertDirectly {
            guard let target = insertTargetAppName, !target.isEmpty else {
                return "Insert → Last App"
            }

            let targetLabel = insertTargetUsesFallback
                ? "\(abbreviatedAppName(target)) (recent)"
                : abbreviatedAppName(target)

            if shouldSuggestRetarget {
                return "Insert → \(targetLabel) ⚠︎"
            }

            return "Insert → \(targetLabel)"
        }

        return "Copy → Clipboard"
    }

    private func insertButtonHelpText() -> String {
        if let insertActionDisabledReason {
            return "\(insertActionDisabledReason) before inserting"
        }

        guard canInsertDirectly else {
            if let target = insertTargetAppName, !target.isEmpty {
                return "Accessibility permission is missing, so this will copy text for \(target)"
            }
            return "Accessibility permission is missing, so this will copy transcription to clipboard"
        }

        if shouldSuggestRetarget,
           let currentFrontAppName = currentExternalFrontAppName(),
           let frozenTarget = insertTargetAppName,
           !frozenTarget.isEmpty {
            return "Current front app is \(currentFrontAppName), but Insert is still targeting \(frozenTarget). Use Retarget + Insert if you switched apps after transcription finished."
        }

        if isInsertTargetStale,
           let frozenTarget = insertTargetAppName,
           !frozenTarget.isEmpty {
            return "Insert target \(frozenTarget) was captured a while ago. Retarget before inserting if you changed context."
        }

        guard let target = insertTargetAppName, !target.isEmpty else {
            return "Insert into the last active app"
        }

        if insertTargetUsesFallback {
            return "Insert into \(target) captured from recent app context"
        }

        return "Insert into \(target)"
    }

    private func retargetButtonTitle() -> String {
        guard let target = insertTargetAppName, !target.isEmpty else {
            return "Retarget"
        }

        if insertTargetUsesFallback {
            return "Retarget → \(abbreviatedAppName(target)) (recent)"
        }

        return "Retarget → \(abbreviatedAppName(target))"
    }

    private var canRetargetInsertTarget: Bool {
        !transcriber.isRecording && transcriber.pendingChunkCount == 0
    }

    private func retargetButtonHelpText() -> String {
        if transcriber.isRecording {
            return "Finish recording before retargeting insertion"
        }

        if transcriber.pendingChunkCount > 0 {
            return "Wait for finalization before retargeting insertion"
        }

        return "Refresh insertion target from your current front app"
    }

    private func useCurrentAppButtonTitle() -> String {
        if canInsertDirectly {
            if let currentFront = currentExternalFrontAppName(), !currentFront.isEmpty {
                return "Use Current → \(abbreviatedAppName(currentFront))"
            }
            return "Use Current App"
        }

        return "Use Current + Copy"
    }

    private func useCurrentAppButtonHelpText() -> String {
        if let insertActionDisabledReason {
            return "\(insertActionDisabledReason) before using current app"
        }

        if canInsertDirectly {
            return "Retarget to the current front app and insert immediately"
        }

        return "Retarget to the current front app and copy to clipboard"
    }

    private func retargetAndInsertButtonTitle() -> String {
        if canInsertDirectly {
            if let currentFront = currentExternalFrontAppName(), !currentFront.isEmpty {
                return "Retarget + Insert → \(abbreviatedAppName(currentFront))"
            }
            return "Retarget + Insert → Current App"
        }

        return "Retarget + Copy → Clipboard"
    }

    private func retargetAndInsertHelpText() -> String {
        if let insertActionDisabledReason {
            return "\(insertActionDisabledReason) before retargeting and inserting"
        }

        guard canInsertDirectly else {
            return "Refresh target app, then copy transcription to clipboard"
        }

        return "Refresh target app from the current front app, then insert"
    }

    private func focusTargetButtonTitle() -> String {
        guard let target = insertTargetAppName, !target.isEmpty else {
            return "Focus Target"
        }

        return "Focus → \(abbreviatedAppName(target))"
    }

    private var hasResolvableInsertTarget: Bool {
        guard let target = insertTargetAppName?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        return !target.isEmpty
    }

    private func focusTargetButtonHelpText() -> String {
        if transcriber.isRecording || transcriber.pendingChunkCount > 0 {
            return "Wait for recording/finalization to finish before focusing the target app"
        }

        if let target = insertTargetAppName, !target.isEmpty {
            return "Bring \(target) to the front before inserting"
        }

        return "No insertion target yet. Switch to your destination app, then click Retarget."
    }

    private func focusAndInsertButtonTitle() -> String {
        if canInsertDirectly {
            if let target = insertTargetAppName, !target.isEmpty {
                return "Focus + Insert → \(abbreviatedAppName(target))"
            }
            return "Focus + Insert"
        }

        return "Focus + Copy"
    }

    private func focusAndInsertButtonHelpText() -> String {
        if let insertActionDisabledReason {
            return "\(insertActionDisabledReason) before focusing and inserting"
        }

        guard hasResolvableInsertTarget else {
            return "No insertion target yet. Switch to your destination app, then click Retarget."
        }

        if canInsertDirectly {
            return "Focus the saved insert target and insert immediately"
        }

        return "Focus the saved insert target and copy to clipboard"
    }

    private var isInsertTargetLocked: Bool {
        hasTranscriptionText && canInsertNow && canInsertDirectly && hasResolvableInsertTarget
    }

    private var shouldSuggestRetarget: Bool {
        guard isInsertTargetLocked else {
            return false
        }

        guard let target = insertTargetAppName?.trimmingCharacters(in: .whitespacesAndNewlines), !target.isEmpty else {
            return false
        }

        if let targetBundle = insertTargetBundleIdentifier,
           let frontBundle = currentExternalFrontBundleIdentifier() {
            return targetBundle.caseInsensitiveCompare(frontBundle) != .orderedSame
        }

        if let front = currentExternalFrontAppName() {
            return target.caseInsensitiveCompare(front) != .orderedSame
        }

        return isInsertTargetStale
    }

    private var isInsertTargetStale: Bool {
        guard let capturedAt = insertTargetCapturedAt else {
            return false
        }

        return uiNow.timeIntervalSince(capturedAt) >= insertTargetStaleAfterSeconds
    }

    private func currentExternalFrontBundleIdentifier() -> String? {
        let candidate = transcriber.frontmostBundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty else { return nil }
        guard candidate.caseInsensitiveCompare(Bundle.main.bundleIdentifier ?? "") != .orderedSame else { return nil }
        return candidate
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

    private func insertTargetAgeDescription() -> String? {
        guard let capturedAt = insertTargetCapturedAt else {
            return nil
        }

        let elapsed = max(0, uiNow.timeIntervalSince(capturedAt))

        if elapsed < 1 {
            return "just now"
        }

        return "\(formatShortDuration(elapsed)) ago"
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

    private func historyEntryStats(_ entry: TranscriptionEntry) -> String {
        let text = entry.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = text.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).count
        return "\(words)w"
    }

    private func openSystemSettingsPane(_ paneURL: String) {
        guard let url = URL(string: paneURL) else { return }
        NSWorkspace.shared.open(url)
    }
}
