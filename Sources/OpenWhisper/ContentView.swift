//
//  ContentView.swift
//  OpenWhisper
//
//  Main menu bar view with transcription controls.
//

@preconcurrency import AVFoundation
@preconcurrency import AppKit
import SwiftUI
import SwiftWhisper

struct ContentView: View {
    @ObservedObject var transcriber: AudioTranscriber
    @ObservedObject var hotkeyMonitor: HotkeyMonitor

    @AppStorage(AppDefaults.Keys.onboardingCompleted) private var onboardingCompleted: Bool = false
    @AppStorage(AppDefaults.Keys.hotkeyMode) private var hotkeyModeRaw: String = HotkeyMode.toggle.rawValue

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
    @State private var recordingPulse: Bool = false

    private let insertTargetStaleAfterSeconds: TimeInterval = 90
    private let fallbackInsertTargetStaleAfterSeconds: TimeInterval = 30

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
                    .opacity(transcriber.isRecording ? (recordingPulse ? 0.4 : 1.0) : 1.0)
                    .animation(
                        transcriber.isRecording
                            ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                            : .default,
                        value: recordingPulse
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle())
                        .font(.headline)
                    HStack(spacing: 6) {
                        Text("Hotkey: \(hotkeySummary())")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Text(activeLanguageLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Picker("", selection: $hotkeyModeRaw) {
                            Text("Toggle").tag(HotkeyMode.toggle.rawValue)
                            Text("Hold").tag(HotkeyMode.hold.rawValue)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 110)
                        .controlSize(.mini)
                        .onChange(of: hotkeyModeRaw) { _, _ in
                            // Make the hotkey UX feel immediate even if AppStorage writes
                            // propagate asynchronously to UserDefaults observers.
                            hotkeyMonitor.reloadConfig()
                            hotkeyMonitor.refreshStatusFromRuntimeState()
                        }
                    }

                    Text(hotkeyMonitor.statusMessage)
                        .font(.caption2)
                        .foregroundColor(hotkeyMonitor.isHotkeyActive ? .secondary : .orange)
                }

                Spacer()

                if transcriber.isRecording || transcriber.pendingChunkCount > 0 {
                    Button("Discard") {
                        Task { @MainActor in
                            transcriber.cancelRecording()
                            hotkeyMonitor.refreshStatusFromRuntimeState()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .keyboardShortcut("d", modifiers: [.command])
                    .help("Discard this recording without saving the transcription")
                }

                Button(startStopButtonTitle()) {
                    Task { @MainActor in
                        transcriber.toggleRecording()
                        hotkeyMonitor.refreshStatusFromRuntimeState()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .keyboardShortcut("r", modifiers: [.command])
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
                        Text("\(transcriber.processedChunkCount) processed • \(transcriber.pendingChunkCount) pending • \(transcriber.inFlightChunkCount) in flight")
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

                    if let lagNotice = liveLoopLagNotice {
                        Text(lagNotice)
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }

                    if transcriber.isStartAfterFinalizeQueued {
                        Text("Next recording is queued. Press hotkey again to cancel.")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }

                    if transcriber.isRecording || transcriber.pendingChunkCount > 0 {
                        Text("Tip: press Esc anytime to discard this recording.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
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
                                if insertTargetAppName == nil || shouldAutoRefreshInsertTargetBeforePrimaryInsert {
                                    refreshInsertTargetSnapshot()
                                }

                                if shouldCopyBecauseTargetUnknown {
                                    _ = transcriber.copyTranscriptionToClipboard()
                                } else if canInsertDirectly {
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

                        if canInsertDirectly, shouldShowUseCurrentAppQuickAction {
                            Button(useCurrentAppButtonTitle()) {
                                Task { @MainActor in
                                    refreshInsertTargetSnapshot(forceRetarget: true)
                                    _ = transcriber.insertTranscriptionIntoFocusedApp()
                                    refreshInsertTargetSnapshot()
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help("Insert into the current front app instead of the locked target")
                            .disabled(!canInsertNow)
                        }

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
                                        refreshInsertTargetSnapshot(forceRetarget: true)
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
                                        refreshInsertTargetSnapshot(forceRetarget: true)
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
                                        refreshInsertTargetSnapshot(forceRetarget: true)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .keyboardShortcut("r", modifiers: [.command, .option])
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
                                        guard focused else {
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
                            Text(targetAge)
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
                                        refreshInsertTargetSnapshot(forceRetarget: true)
                                    }
                                }
                                .buttonStyle(.borderless)
                                .font(.caption2)
                                .keyboardShortcut("r", modifiers: [.command, .option])
                                .help("Update Insert target to the current front app (⌘⌥R)")

                                Button("Retarget + Insert") {
                                    Task { @MainActor in
                                        refreshInsertTargetSnapshot(forceRetarget: true)
                                        if canInsertDirectly {
                                            _ = transcriber.insertTranscriptionIntoFocusedApp()
                                        } else {
                                            _ = transcriber.copyTranscriptionToClipboard()
                                        }
                                        refreshInsertTargetSnapshot()
                                    }
                                }
                                .buttonStyle(.borderless)
                                .font(.caption2)
                                .disabled(!canInsertNow)
                                .help("Retarget to the current front app, then insert immediately")

                                Text("⌘⌥↩ inserts into current app")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else if isInsertTargetStale {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(insertTargetUsesFallback ? "Recent-app insert target is getting stale quickly." : "Insert target snapshot is getting stale.")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)

                                Button("Retarget now") {
                                    Task { @MainActor in
                                        refreshInsertTargetSnapshot(forceRetarget: true)
                                    }
                                }
                                .buttonStyle(.borderless)
                                .font(.caption2)
                                .keyboardShortcut("r", modifiers: [.command, .option])
                                .help("Refresh insertion target from your current front app (⌘⌥R)")

                                Button("Retarget + Insert") {
                                    Task { @MainActor in
                                        refreshInsertTargetSnapshot(forceRetarget: true)
                                        if canInsertDirectly {
                                            _ = transcriber.insertTranscriptionIntoFocusedApp()
                                        } else {
                                            _ = transcriber.copyTranscriptionToClipboard()
                                        }
                                        refreshInsertTargetSnapshot()
                                    }
                                }
                                .buttonStyle(.borderless)
                                .font(.caption2)
                                .disabled(!canInsertNow)
                                .help("Refresh insertion target, then insert immediately")
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

                    if let successfulInsertDescription = lastSuccessfulInsertDescription() {
                        Text(successfulInsertDescription)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
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
                                    if let appName = entry.targetAppName, !appName.isEmpty {
                                        Text("·")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                        Text("→ \(appName)")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
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
                            .help("Restore this transcript into the editor")
                            .disabled(transcriber.isRecording || transcriber.pendingChunkCount > 0)
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

                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("v\(version)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

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
            let shouldRefreshInsertTargetClock = hasTranscriptionText && insertTargetCapturedAt != nil
            let shouldRefreshLastInsertClock = transcriber.lastSuccessfulInsertionAt != nil
            guard shouldRefreshInsertTargetClock || shouldRefreshLastInsertClock else {
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

            // Drive the pulsing recording indicator animation.
            recordingPulse = isRecording

            // Front-app insertion UX: lock/refresh the manual insert target
            // as soon as recording starts, before any transcript text appears.
            // This preserves the user's intended destination app even if they
            // switch windows while speaking.
            if isRecording {
                lastClearedTranscription = nil
                Task { @MainActor in
                    refreshInsertTargetSnapshot(forceRetarget: true)
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
    private func refreshInsertTargetSnapshot(forceRetarget: Bool = false) {
        let snapshot = transcriber.manualInsertTargetSnapshot(forceRefresh: forceRetarget)
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
        ViewHelpers.statusTitle(isRecording: transcriber.isRecording, recordingDuration: recordingDuration(), pendingChunkCount: transcriber.pendingChunkCount)
    }

    private func recordingDuration() -> TimeInterval {
        guard let startedAt = transcriber.recordingStartedAt else { return 0 }
        return max(0, uiNow.timeIntervalSince(startedAt))
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        ViewHelpers.formatDuration(seconds)
    }

    private func formatShortDuration(_ seconds: TimeInterval) -> String {
        ViewHelpers.formatShortDuration(seconds)
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
        finalizationInitialPendingChunks = ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: transcriber.isRecording,
            pendingChunks: pendingChunks,
            currentBaseline: finalizationInitialPendingChunks
        )
    }

    private var finalizationProgress: Double? {
        ViewHelpers.finalizationProgress(
            pendingChunkCount: transcriber.pendingChunkCount,
            initialPendingChunks: finalizationInitialPendingChunks,
            isRecording: transcriber.isRecording
        )
    }

    private var estimatedFinalizationSeconds: TimeInterval? {
        ViewHelpers.estimatedFinalizationSeconds(
            pendingChunkCount: transcriber.pendingChunkCount,
            averageChunkLatency: transcriber.averageChunkLatencySeconds,
            lastChunkLatency: transcriber.lastChunkLatencySeconds
        )
    }

    private var liveLoopLagNotice: String? {
        ViewHelpers.liveLoopLagNotice(
            pendingChunkCount: transcriber.pendingChunkCount,
            estimatedFinalizationSeconds: estimatedFinalizationSeconds
        )
    }

    private func hotkeySummary() -> String {
        HotkeyDisplay.summaryIncludingMode()
    }

    private var activeLanguageLabel: String {
        let code = transcriber.activeLanguageCode
        let language = WhisperLanguage(rawValue: code) ?? .auto
        return language.displayName
    }

    private var canToggleRecording: Bool {
        ViewHelpers.canToggleRecording(isRecording: transcriber.isRecording, pendingChunkCount: transcriber.pendingChunkCount, microphoneAuthorized: microphoneAuthorized)
    }

    private func startStopButtonHelpText() -> String {
        ViewHelpers.startStopButtonHelpText(
            isRecording: transcriber.isRecording,
            pendingChunkCount: transcriber.pendingChunkCount,
            isStartAfterFinalizeQueued: transcriber.isStartAfterFinalizeQueued,
            microphoneAuthorized: microphoneAuthorized
        )
    }

    private func startStopButtonTitle() -> String {
        ViewHelpers.startStopButtonTitle(
            isRecording: transcriber.isRecording,
            pendingChunkCount: transcriber.pendingChunkCount,
            isStartAfterFinalizeQueued: transcriber.isStartAfterFinalizeQueued
        )
    }

    private var canInsertDirectly: Bool {
        accessibilityAuthorized
    }

    private var shouldCopyBecauseTargetUnknown: Bool {
        guard canInsertDirectly else {
            return false
        }

        if hasResolvableInsertTarget {
            return false
        }

        return currentExternalFrontAppName() == nil
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
        ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: hasTranscriptionText,
            isRunningInsertionProbe: transcriber.isRunningInsertionProbe,
            isRecording: transcriber.isRecording,
            pendingChunkCount: transcriber.pendingChunkCount
        )
    }

    private func insertButtonTitle() -> String {
        if canInsertDirectly {
            guard let target = insertTargetAppName, !target.isEmpty else {
                if let liveFrontApp = currentExternalFrontAppName(), !liveFrontApp.isEmpty {
                    return "Insert → \(abbreviatedAppName(liveFrontApp))"
                }
                return "Copy → Clipboard"
            }

            let targetLabel = insertTargetUsesFallback
                ? "\(abbreviatedAppName(target)) (recent)"
                : abbreviatedAppName(target)

            if shouldSuggestRetarget || isInsertTargetStale {
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

        if shouldCopyBecauseTargetUnknown {
            return "No destination app is currently available, so this will copy transcription to clipboard"
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
            if let liveFrontApp = currentExternalFrontAppName(), !liveFrontApp.isEmpty {
                return "Insert into \(liveFrontApp)"
            }
            return "Insert into the last active app"
        }

        if insertTargetUsesFallback {
            return "Insert into \(target) captured from recent app context"
        }

        return "Insert into \(target)"
    }

    private func retargetButtonTitle() -> String {
        ViewHelpers.retargetButtonTitle(insertTargetAppName: insertTargetAppName, insertTargetUsesFallback: insertTargetUsesFallback)
    }

    private var canRetargetInsertTarget: Bool {
        ViewHelpers.canRetargetInsertTarget(isRecording: transcriber.isRecording, pendingChunkCount: transcriber.pendingChunkCount)
    }

    private func retargetButtonHelpText() -> String {
        ViewHelpers.retargetButtonHelpText(isRecording: transcriber.isRecording, pendingChunkCount: transcriber.pendingChunkCount)
    }

    private func useCurrentAppButtonTitle() -> String {
        ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: canInsertDirectly, currentFrontAppName: currentExternalFrontAppName())
    }

    private func useCurrentAppButtonHelpText() -> String {
        ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: insertActionDisabledReason, canInsertDirectly: canInsertDirectly)
    }

    private func retargetAndInsertButtonTitle() -> String {
        ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: canInsertDirectly, currentFrontAppName: currentExternalFrontAppName())
    }

    private func retargetAndInsertHelpText() -> String {
        ViewHelpers.retargetAndInsertHelpText(insertActionDisabledReason: insertActionDisabledReason, canInsertDirectly: canInsertDirectly)
    }

    private func focusTargetButtonTitle() -> String {
        ViewHelpers.focusTargetButtonTitle(insertTargetAppName: insertTargetAppName)
    }

    private var hasResolvableInsertTarget: Bool {
        ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: insertTargetAppName)
    }

    private func focusTargetButtonHelpText() -> String {
        ViewHelpers.focusTargetButtonHelpText(isRecording: transcriber.isRecording, pendingChunkCount: transcriber.pendingChunkCount, insertTargetAppName: insertTargetAppName)
    }

    private func focusAndInsertButtonTitle() -> String {
        ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: canInsertDirectly, insertTargetAppName: insertTargetAppName)
    }

    private func focusAndInsertButtonHelpText() -> String {
        ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: insertActionDisabledReason, hasResolvableInsertTarget: hasResolvableInsertTarget, canInsertDirectly: canInsertDirectly)
    }

    private var isInsertTargetLocked: Bool {
        ViewHelpers.isInsertTargetLocked(hasTranscriptionText: hasTranscriptionText, canInsertNow: canInsertNow, canInsertDirectly: canInsertDirectly, hasResolvableInsertTarget: hasResolvableInsertTarget)
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

    private var shouldShowUseCurrentAppQuickAction: Bool {
        ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: shouldSuggestRetarget, isInsertTargetStale: isInsertTargetStale)
    }

    private var shouldAutoRefreshInsertTargetBeforePrimaryInsert: Bool {
        guard canInsertDirectly else {
            return false
        }

        guard canRetargetInsertTarget else {
            return false
        }

        // If we already know the user switched apps, keep the target locked and
        // force an explicit retarget choice. Auto-refresh only the stale-but-
        // likely-same-app path to improve reliability without surprising jumps.
        guard !shouldSuggestRetarget else {
            return false
        }

        return isInsertTargetStale
    }

    private var activeInsertTargetStaleAfterSeconds: TimeInterval {
        ViewHelpers.activeInsertTargetStaleAfterSeconds(
            usesFallback: insertTargetUsesFallback,
            normalTimeout: insertTargetStaleAfterSeconds,
            fallbackTimeout: fallbackInsertTargetStaleAfterSeconds
        )
    }

    private var isInsertTargetStale: Bool {
        ViewHelpers.isInsertTargetStale(capturedAt: insertTargetCapturedAt, now: uiNow, staleAfterSeconds: activeInsertTargetStaleAfterSeconds)
    }

    private func currentExternalFrontBundleIdentifier() -> String? {
        ViewHelpers.currentExternalFrontBundleIdentifier(transcriber.frontmostBundleIdentifier, ownBundleIdentifier: Bundle.main.bundleIdentifier)
    }

    private func currentExternalFrontAppName() -> String? {
        ViewHelpers.currentExternalFrontAppName(transcriber.frontmostAppName)
    }

    private func abbreviatedAppName(_ name: String, maxCharacters: Int = 18) -> String {
        ViewHelpers.abbreviatedAppName(name, maxCharacters: maxCharacters)
    }

    private func insertTargetAgeDescription() -> String? {
        ViewHelpers.insertTargetAgeDescription(
            capturedAt: insertTargetCapturedAt,
            now: uiNow,
            staleAfterSeconds: activeInsertTargetStaleAfterSeconds,
            isStale: isInsertTargetStale
        )
    }

    private func lastSuccessfulInsertDescription() -> String? {
        ViewHelpers.lastSuccessfulInsertDescription(insertedAt: transcriber.lastSuccessfulInsertionAt, now: uiNow)
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
        ViewHelpers.historyEntryStats(text: entry.text, durationSeconds: entry.durationSeconds)
    }

    private func openSystemSettingsPane(_ paneURL: String) {
        guard let url = URL(string: paneURL) else { return }
        NSWorkspace.shared.open(url)
    }
}
