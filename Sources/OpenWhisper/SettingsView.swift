// SettingsView.swift
// OpenWhisper
//
// Full configuration window for hotkeys, output behavior, and permissions.
//

@preconcurrency import AVFoundation
@preconcurrency import AppKit
import SwiftUI
import SwiftWhisper
import UniformTypeIdentifiers
import Carbon.HIToolbox

struct SettingsView: View {
    @ObservedObject var transcriber: AudioTranscriber
    @ObservedObject var hotkeyMonitor: HotkeyMonitor

    @AppStorage(AppDefaults.Keys.onboardingCompleted) private var onboardingCompleted: Bool = false
    @AppStorage(AppDefaults.Keys.hotkeyMode) private var hotkeyModeRaw: String = HotkeyMode.toggle.rawValue
    @AppStorage(AppDefaults.Keys.hotkeyKey) private var hotkeyKey: String = "space"

    @State private var hotkeyKeyDraft: String = ""
    @State private var isCapturingHotkey: Bool = false
    @State private var hotkeyCaptureLocalMonitor: Any?
    @State private var hotkeyCaptureGlobalMonitor: Any?
    @State private var hotkeyCaptureTimeoutTask: Task<Void, Never>?
    @State private var hotkeyCaptureSecondsRemaining: Int = 0
    @State private var hotkeyCaptureStartedAt: Date = .distantPast
    @State private var hotkeyCaptureError: String?
    @State private var hotkeyCaptureSuccessMessage: String?
    @State private var hotkeyCaptureSuccessResetTask: Task<Void, Never>?
    @State private var hotkeyApplyMessage: String?
    @State private var hotkeyApplyErrorMessage: String?
    @State private var hotkeyCopyMessage: String?
    @State private var hotkeyCopyMessageResetTask: Task<Void, Never>?
    @AppStorage(AppDefaults.Keys.insertionProbeSampleText) private var insertionProbeSampleText: String = "OpenWhisper insertion test"
    private let insertionProbeMaxCharacters: Int = AudioTranscriber.insertionProbeMaxCharacters
    private let hotkeyCaptureTimeoutSeconds: Int = 8

    @AppStorage(AppDefaults.Keys.hotkeyRequiredCommand) private var requiredCommand: Bool = true
    @AppStorage(AppDefaults.Keys.hotkeyRequiredShift) private var requiredShift: Bool = true
    @AppStorage(AppDefaults.Keys.hotkeyRequiredOption) private var requiredOption: Bool = false
    @AppStorage(AppDefaults.Keys.hotkeyRequiredControl) private var requiredControl: Bool = false
    @AppStorage(AppDefaults.Keys.hotkeyRequiredCapsLock) private var requiredCapsLock: Bool = false

    @AppStorage(AppDefaults.Keys.hotkeyForbiddenCommand) private var forbiddenCommand: Bool = false
    @AppStorage(AppDefaults.Keys.hotkeyForbiddenShift) private var forbiddenShift: Bool = false
    @AppStorage(AppDefaults.Keys.hotkeyForbiddenOption) private var forbiddenOption: Bool = true
    @AppStorage(AppDefaults.Keys.hotkeyForbiddenControl) private var forbiddenControl: Bool = true
    @AppStorage(AppDefaults.Keys.hotkeyForbiddenCapsLock) private var forbiddenCapsLock: Bool = false

    @AppStorage(AppDefaults.Keys.outputAutoCopy) private var autoCopy: Bool = true
    @AppStorage(AppDefaults.Keys.outputAutoPaste) private var autoPaste: Bool = false
    @AppStorage(AppDefaults.Keys.outputClearAfterInsert) private var clearAfterInsert: Bool = false
    @AppStorage(AppDefaults.Keys.outputCommandReplacements) private var outputCommandReplacements: Bool = true
    @AppStorage(AppDefaults.Keys.outputSmartCapitalization) private var outputSmartCapitalization: Bool = true
    @AppStorage(AppDefaults.Keys.outputTerminalPunctuation) private var outputTerminalPunctuation: Bool = true
    @AppStorage(AppDefaults.Keys.outputCustomCommands) private var outputCustomCommands: String = ""

    @AppStorage(AppDefaults.Keys.audioFeedbackEnabled) private var audioFeedbackEnabled: Bool = true
    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled
    @AppStorage(AppDefaults.Keys.modelSource) private var modelSourceRaw: String = ModelSource.bundledTiny.rawValue
    @AppStorage(AppDefaults.Keys.modelCustomPath) private var customModelPath: String = ""
    @AppStorage(AppDefaults.Keys.transcriptionLanguage) private var transcriptionLanguage: String = "auto"

    @AppStorage(AppDefaults.Keys.transcriptionReplacements) private var replacementsRaw: String = ""
    @AppStorage(AppDefaults.Keys.transcriptionHistoryLimit) private var historyLimit: Int = 25

    @State private var microphoneAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    @State private var accessibilityAuthorized = HotkeyMonitor.hasAccessibilityPermission()
    @State private var inputMonitoringAuthorized = HotkeyMonitor.hasInputMonitoringPermission()
    @State private var showingOnboarding = false

    private let permissionTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("OpenWhisper Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                GroupBox("Hotkey") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Mode", selection: $hotkeyModeRaw) {
                            ForEach(HotkeyMode.allCases) { mode in
                                Text(mode.title).tag(mode.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)

                        HStack(spacing: 8) {
                            Text("Active combo")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(hotkeySummary())
                                .font(.headline)

                            Button {
                                copyHotkeySummaryToClipboard()
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help("Copy hotkey mode and combo to clipboard")
                        }

                        if let hotkeyCopyMessage {
                            Text(hotkeyCopyMessage)
                                .font(.caption)
                                .foregroundStyle(.green)
                        }

                        if showsHighRiskHotkeyWarning {
                            HStack(alignment: .center, spacing: 10) {
                                Label("This combo has no required modifiers, so it can trigger accidentally while typing.", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)

                                Button("Make safer") {
                                    applySafeRequiredModifiers()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }

                        if showsHoldModeAccidentalTriggerWarning {
                            HStack(alignment: .center, spacing: 10) {
                                Label("Hold-to-talk without modifiers is especially risky: pressing this key in normal typing can start live recording.", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)

                                Button("Use safer hold combo") {
                                    applySafeRequiredModifiers()
                                    hotkeyModeRaw = HotkeyMode.hold.rawValue
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }

                        if let conflictWarning = hotkeySystemConflictWarning {
                            HStack(alignment: .center, spacing: 10) {
                                Label(conflictWarning, systemImage: "bolt.horizontal.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)

                                Button("Use safer default") {
                                    applySafeRequiredModifiers()
                                    hotkeyKey = "space"
                                    hotkeyKeyDraft = "space"
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }

                        if let escapeConflictWarning = hotkeyEscapeCancelConflictWarning {
                            HStack(alignment: .center, spacing: 10) {
                                Label(escapeConflictWarning, systemImage: "exclamationmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)

                                Button("Use Space key") {
                                    hotkeyKey = "space"
                                    hotkeyKeyDraft = "space"
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }

                        HStack(spacing: 10) {
                            Button(currentHotkeyMode == .toggle ? "Preset: Toggle ✓" : "Preset: Toggle") {
                                applyHotkeyPreset(.toggle)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(currentHotkeyMode == .toggle)

                            Button(currentHotkeyMode == .hold ? "Preset: Push to talk ✓" : "Preset: Push to talk") {
                                applyHotkeyPreset(.hold)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(currentHotkeyMode == .hold)

                            Spacer()

                            Text("One-click hotkey mode presets")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 10) {
                            Circle()
                                .fill(hotkeyMonitor.isHotkeyActive ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            Text(hotkeyMonitor.statusMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let missingSummary = hotkeyMissingPermissionSummary {
                                Text("Missing: \(missingSummary)")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }

                            Spacer()

                            if !accessibilityAuthorized {
                                Button("Grant Accessibility") {
                                    HotkeyMonitor.requestAccessibilityPermissionPrompt()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }

                            if !inputMonitoringAuthorized {
                                Button("Grant Input Monitoring") {
                                    HotkeyMonitor.requestInputMonitoringPermissionPrompt()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }

                            Button("Restart monitor") {
                                hotkeyMonitor.stop()
                                hotkeyMonitor.start()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("Trigger key")
                                .frame(width: 110, alignment: .leading)

                            TextField("space", text: $hotkeyKeyDraft)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                                .onChange(of: hotkeyKeyDraft) { _, newValue in
                                    hotkeyKeyDraft = sanitizeHotkeyDraftValue(newValue)
                                    hotkeyApplyMessage = nil
                                    hotkeyApplyErrorMessage = nil
                                }
                                .onSubmit {
                                    applyHotkeyKeyDraft()
                                }

                            Button("Apply") {
                                applyHotkeyKeyDraft()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(!isHotkeyKeyDraftSupported || !hasHotkeyDraftChangesToApply)

                            Button("Revert") {
                                hotkeyKeyDraft = hotkeyKey
                                hotkeyCaptureError = nil
                                hotkeyApplyErrorMessage = nil
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(!hasHotkeyDraftEdits)

                            Button("Paste combo") {
                                pasteHotkeyComboFromClipboard()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help("Paste a shortcut like ⌘⇧Space or cmd+shift+space")

                            Button(hotkeyCaptureButtonTitle) {
                                if isCapturingHotkey {
                                    stopHotkeyCapture()
                                } else {
                                    startHotkeyCapture()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .keyboardShortcut("k", modifiers: [.command, .shift])
                            .help("Record a shortcut by pressing the desired key combo (⌘⇧K)")

                            if isCapturingHotkey {
                                Button("Cancel") {
                                    stopHotkeyCapture()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }

                            Menu("Common keys") {
                                ForEach(commonHotkeyKeySections, id: \.title) { section in
                                    Section(section.title) {
                                        ForEach(section.keys, id: \.self) { key in
                                            Button(HotkeyDisplay.displayKey(key)) {
                                                hotkeyKeyDraft = key
                                                applyHotkeyKeyDraft()
                                            }
                                        }
                                    }
                                }
                            }
                            .controlSize(.small)

                            Text("Examples: space/spacebar, tab, return/enter, esc, del/delete/backspace, forwarddelete, insert/ins, fn/function/globe, section/§, left/right/up/down, f1-f24, keypad1/numpad1, keypadcomma, keypadclear/clear, keypadenter, a, 1, minus, slash. You can also paste combos like cmd+shift+space, cmd shift space, or cmd-shift-space.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if isCapturingHotkey {
                            Text(hotkeyCaptureInstruction)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ProgressView(value: hotkeyCaptureProgress)
                                .progressViewStyle(.linear)
                        }

                        if let hotkeyCaptureError {
                            Text(hotkeyCaptureError)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }

                        if let hotkeyCaptureSuccessMessage {
                            Text(hotkeyCaptureSuccessMessage)
                                .font(.caption)
                                .foregroundStyle(.green)
                        }

                        if let hotkeyDraftValidationMessage {
                            Text(hotkeyDraftValidationMessage)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        } else if let preview = canonicalHotkeyDraftPreview,
                                  preview != hotkeySummary() {
                            Text("Preview: \(preview)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let hotkeyApplyMessage {
                            Text(hotkeyApplyMessage)
                                .font(.caption)
                                .foregroundStyle(.green)
                        }

                        if let hotkeyApplyErrorMessage {
                            Text(hotkeyApplyErrorMessage)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }

                        if let modifierPreview = hotkeyDraftModifierOverrideSummary {
                            Text("Applying this input will set required modifiers to: \(modifierPreview).")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let nonConfigurableModifierNotice = hotkeyDraftNonConfigurableModifierNotice {
                            Text(nonConfigurableModifierNotice)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }

                        Divider()

                        Text("Required modifiers")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        modifierGrid(
                            command: $requiredCommand,
                            shift: $requiredShift,
                            option: $requiredOption,
                            control: $requiredControl,
                            capsLock: $requiredCapsLock
                        )

                        Text("Forbidden modifiers")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        modifierGrid(
                            command: $forbiddenCommand,
                            shift: $forbiddenShift,
                            option: $forbiddenOption,
                            control: $forbiddenControl,
                            capsLock: $forbiddenCapsLock
                        )

                        HStack(spacing: 10) {
                            Button("Reset hotkey defaults") {
                                resetHotkeyDefaults()
                            }
                            .buttonStyle(.bordered)

                            Text("Restores ⌘+⇧+Space (toggle mode) and safe forbidden modifiers.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(hotkeyModeTipText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }

                GroupBox("Output") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Auto-copy final transcript", isOn: $autoCopy)
                        Toggle("Auto-paste into focused app", isOn: $autoPaste)
                        Toggle("Clear transcript after insert", isOn: $clearAfterInsert)
                            .disabled(!autoPaste)
                        Toggle("Audio feedback on record start/stop", isOn: $audioFeedbackEnabled)
                        Toggle("Launch at login", isOn: $launchAtLogin)
                            .onChange(of: launchAtLogin) { _, newValue in
                                if !LaunchAtLogin.setEnabled(newValue) {
                                    launchAtLogin = LaunchAtLogin.isEnabled
                                }
                            }

                        if showsAutoPastePermissionWarning {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Auto-paste needs Accessibility permission.", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)

                                Button("Open Accessibility Privacy") {
                                    openSystemSettingsPane("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
                                }
                                .buttonStyle(.link)
                                .font(.caption)
                            }
                        }

                        HStack {
                            Text("History items")
                                .frame(width: 110, alignment: .leading)
                            Stepper(value: $historyLimit, in: 1...200) {
                                Text("\(historyLimit)")
                            }
                            .frame(width: 120)
                        }

                        Text("Auto-paste sends Cmd+V via Accessibility APIs. Keep it disabled if you only want clipboard updates.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }

                GroupBox("Per-App Profiles") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Frontmost app: \(transcriber.frontmostAppName)")
                            .font(.subheadline)

                        if !transcriber.frontmostBundleIdentifier.isEmpty {
                            Text(transcriber.frontmostBundleIdentifier)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }

                        HStack(spacing: 10) {
                            Button("Refresh frontmost app") {
                                Task { @MainActor in
                                    transcriber.refreshFrontmostAppContext()
                                }
                            }
                            .buttonStyle(.bordered)

                            Button("Capture profile from frontmost app") {
                                Task { @MainActor in
                                    transcriber.captureProfileForFrontmostApp()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!canCaptureFrontmostProfile)

                            Button(transcriber.isRunningInsertionProbe ? "Running insertion test…" : "Capture + insertion test") {
                                Task { @MainActor in
                                    let captured = transcriber.captureProfileForFrontmostApp()
                                    guard captured else { return }
                                    _ = transcriber.runInsertionProbe(sampleText: insertionProbeSampleTextForRun)
                                }
                            }
                            .buttonStyle(.bordered)
                            .keyboardShortcut(.return, modifiers: [.command, .shift])
                            .help("Capture target app and run insertion test with ⌘⇧↩")
                            .disabled(!canCaptureAndRunInsertionTest)

                            Button(runInsertionTestButtonTitle) {
                                runInsertionTestUsingAvailableTarget()
                            }
                            .buttonStyle(.bordered)
                            .keyboardShortcut(.return, modifiers: [.command])
                            .help("Run insertion test with ⌘↩")
                            .disabled(!canRunInsertionTestWithAutoCapture)

                            Button(transcriber.isRunningInsertionProbe ? "Running insertion test…" : "Focus target + test") {
                                Task { @MainActor in
                                    let focused = transcriber.focusManualInsertTargetApp()
                                    guard focused else { return }
                                    _ = transcriber.runInsertionProbe(sampleText: insertionProbeSampleTextForRun)
                                }
                            }
                            .buttonStyle(.bordered)
                            .keyboardShortcut(.return, modifiers: [.command, .option])
                            .help("Focus saved insertion target and run test with ⌘⌥↩")
                            .disabled(!canFocusAndRunInsertionTest)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("Insertion test text")
                                .frame(width: 125, alignment: .leading)

                            TextField("OpenWhisper insertion test", text: $insertionProbeSampleText)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: insertionProbeSampleText) { _, _ in
                                    enforceInsertionProbeSampleTextLimit()
                                }
                                .onSubmit {
                                    runInsertionTestFromTextFieldSubmission()
                                }

                            Button("Reset") {
                                insertionProbeSampleText = "OpenWhisper insertion test"
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(insertionProbeSampleText == "OpenWhisper insertion test")
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("Used by both insertion test buttons. Press Return in the field to run the insertion test instantly when available. Leave it short so you can quickly confirm the right destination app received it.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text("\(insertionProbeSampleTextForRun.count)/\(insertionProbeMaxCharacters)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        if insertionProbeSampleTextWillTruncate {
                            Text("Insertion test text will be trimmed to the first \(insertionProbeMaxCharacters) characters to avoid accidental long pastes.")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }

                        if !canCaptureFrontmostProfile {
                            Text(captureProfileDisabledReason)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        } else if captureProfileUsesRecentAppFallback,
                                  let fallbackName = captureProfileFallbackAppName {
                            Text("Using recent app context: \(fallbackName). This helps when Settings is frontmost.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if !canRunInsertionTestWithAutoCapture {
                            Text(insertionTestDisabledReason)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        } else if showsInsertionTestAutoCaptureHint {
                            if let targetName = insertionTestAutoCaptureTargetName, !targetName.isEmpty {
                                Text("No saved insertion target yet. Run insertion test will first capture \(targetName), then run the test.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("No saved insertion target yet. Run insertion test will first capture your current frontmost app, then run the test.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else if let target = insertionTestTargetDisplay {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("Insertion test target: \(target)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)

                                Button("Copy target") {
                                    let pasteboard = NSPasteboard.general
                                    pasteboard.clearContents()
                                    _ = pasteboard.setString(target, forType: .string)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                Button("Focus target app") {
                                    Task { @MainActor in
                                        _ = transcriber.focusManualInsertTargetApp()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(!canFocusInsertionTarget)

                                Button("Clear target") {
                                    Task { @MainActor in
                                        transcriber.clearManualInsertTarget()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(!canClearInsertionTarget)
                            }

                            if transcriber.manualInsertTargetUsesFallbackApp() {
                                Text("Using recent app fallback target. Before running the insertion test, switch to your real destination app and click Refresh frontmost app for precise targeting.")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }

                            if !accessibilityAuthorized {
                                Text("Accessibility permission is missing, so this test will validate target capture and copy the sample text to clipboard instead of auto-pasting.")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("Last insertion test:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(transcriber.lastInsertionProbeMessage)
                                .font(.caption)
                                .foregroundStyle(insertionProbeStatusColor)

                            if let date = transcriber.lastInsertionProbeDate {
                                Text("(\(date.formatted(date: .omitted, time: .shortened)))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let lastSuccessfulInsertionAt = transcriber.lastSuccessfulInsertionAt {
                            Text("Last successful insert: \(lastSuccessfulInsertionAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        if transcriber.isRunningInsertionProbe {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Running insertion test…")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if transcriber.appProfiles.isEmpty {
                            Text("No app-specific profiles yet. Capture the frontmost app to create one.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(transcriber.appProfiles) { profile in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(profile.appName)
                                                .font(.headline)
                                            Spacer()
                                            Button("Delete") {
                                                Task { @MainActor in
                                                    transcriber.removeProfile(bundleIdentifier: profile.bundleIdentifier)
                                                }
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)
                                        }

                                        Text(profile.bundleIdentifier)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .textSelection(.enabled)

                                        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                                            GridRow {
                                                Toggle("Auto-copy", isOn: profileBinding(profile.bundleIdentifier, \.autoCopy))
                                                Toggle("Auto-paste", isOn: profileBinding(profile.bundleIdentifier, \.autoPaste))
                                            }
                                            GridRow {
                                                Toggle("Clear after insert", isOn: profileBinding(profile.bundleIdentifier, \.clearAfterInsert))
                                                Toggle("Command replacements", isOn: profileBinding(profile.bundleIdentifier, \.commandReplacements))
                                            }
                                            GridRow {
                                                Toggle("Smart capitalization", isOn: profileBinding(profile.bundleIdentifier, \.smartCapitalization))
                                                Toggle("Terminal punctuation", isOn: profileBinding(profile.bundleIdentifier, \.terminalPunctuation))
                                            }
                                        }
                                        .toggleStyle(.checkbox)

                                        Text("App-specific custom commands (`phrase => replacement`):")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        TextEditor(text: profileStringBinding(profile.bundleIdentifier, \.customCommands))
                                            .font(.system(.caption, design: .monospaced))
                                            .frame(minHeight: 70)
                                            .padding(4)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(.quaternary, lineWidth: 1)
                                            )
                                    }
                                    .padding(10)
                                    .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }

                        Text("Profiles override global output behavior when that app is frontmost during finalization/copy/insert. Use “Run insertion test” to verify front-app paste targeting before recording.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }

                GroupBox("Model") {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Model source", selection: $modelSourceRaw) {
                            ForEach(ModelSource.allCases) { source in
                                Text(source.title).tag(source.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("Language")
                                .frame(width: 110, alignment: .leading)

                            Picker("", selection: $transcriptionLanguage) {
                                ForEach(WhisperLanguage.allCases) { lang in
                                    Text(lang.displayName).tag(lang.rawValue)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 200)
                            .onChange(of: transcriptionLanguage) { _, newValue in
                                Task { @MainActor in
                                    transcriber.setTranscriptionLanguage(newValue)
                                }
                            }

                            Text("Set to a specific language for better accuracy, or auto to detect.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if modelSourceRaw == ModelSource.customPath.rawValue {
                            HStack(alignment: .center, spacing: 8) {
                                TextField("/path/to/ggml-model.bin", text: $customModelPath)
                                    .textFieldStyle(.roundedBorder)

                                Button("Choose…") {
                                    chooseCustomModelFile()
                                }
                                .buttonStyle(.bordered)

                                Button("Apply") {
                                    Task { @MainActor in
                                        transcriber.setCustomModelPath(customModelPath)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }

                        HStack(spacing: 10) {
                            Button("Reload model") {
                                Task { @MainActor in
                                    transcriber.reloadConfiguredModel()
                                }
                            }
                            .buttonStyle(.bordered)

                            if modelSourceRaw == ModelSource.customPath.rawValue {
                                Button("Clear custom path") {
                                    customModelPath = ""
                                    Task { @MainActor in
                                        transcriber.clearCustomModelPath()
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Loaded: \(transcriber.activeModelDisplayName)")
                                .font(.subheadline)
                            Text(transcriber.modelStatusMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if !transcriber.activeModelPath.isEmpty {
                                Text(transcriber.activeModelPath)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }

                            if let warning = transcriber.modelWarning {
                                Text(warning)
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }

                GroupBox("Text cleanup") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Enable spoken command replacements", isOn: $outputCommandReplacements)
                        Toggle("Auto-capitalize sentences", isOn: $outputSmartCapitalization)
                        Toggle("Add final punctuation when missing", isOn: $outputTerminalPunctuation)

                        Text("Built-in commands include punctuation/symbol phrases such as new line, new paragraph, comma, period, question mark, open quote, and open parenthesis.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Global custom commands (`phrase => replacement`):")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $outputCustomCommands)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 90)
                            .padding(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.quaternary, lineWidth: 1)
                            )

                        Text("Use `\\\\n` for line breaks. Custom commands are merged with built-ins.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        Text("Replacement rules (one per line):")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $replacementsRaw)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 120)
                            .padding(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.quaternary, lineWidth: 1)
                            )

                        Text("Format: `from => to` or `from = to`. Lines starting with `#` are ignored. Custom rules apply after built-in command replacements.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }

                GroupBox("Permissions") {
                    VStack(alignment: .leading, spacing: 10) {
                        permissionRow(
                            title: "Microphone",
                            granted: microphoneAuthorized,
                            actionTitle: "Request",
                            action: {
                                Task { @MainActor in
                                    transcriber.requestMicrophonePermission()
                                }
                            }
                        )

                        permissionRow(
                            title: "Accessibility",
                            granted: accessibilityAuthorized,
                            actionTitle: "Request",
                            action: {
                                HotkeyMonitor.requestAccessibilityPermissionPrompt()
                            }
                        )

                        permissionRow(
                            title: "Input Monitoring",
                            granted: inputMonitoringAuthorized,
                            actionTitle: "Request",
                            action: {
                                HotkeyMonitor.requestInputMonitoringPermissionPrompt()
                            }
                        )

                        HStack(spacing: 12) {
                            Button("Open Microphone Privacy") {
                                openSystemSettingsPane("x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
                            }
                            Button("Open Accessibility Privacy") {
                                openSystemSettingsPane("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
                            }
                            Button("Open Input Monitoring Privacy") {
                                openSystemSettingsPane("x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
                            }
                        }
                        .buttonStyle(.link)
                        .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }

                GroupBox("Onboarding") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(onboardingCompleted ? "Onboarding has been completed." : "Onboarding is not completed.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            Button("Open onboarding guide") {
                                showingOnboarding = true
                            }
                            .buttonStyle(.bordered)

                            Button("Reset onboarding completion") {
                                onboardingCompleted = false
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }

                GroupBox("Diagnostics") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status: \(transcriber.statusMessage)")
                            .font(.subheadline)

                        if let error = transcriber.lastError {
                            Text("Last error: \(error)")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        Text("Current model: \(transcriber.activeModelDisplayName) (\(formatBytes(sizeOfModel(path: transcriber.activeModelPath)))) · Language: \(WhisperLanguage(rawValue: transcriber.activeLanguageCode)?.displayName ?? transcriber.activeLanguageCode)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 700, minHeight: 700)
        .onAppear {
            hotkeyKeyDraft = hotkeyKey
            launchAtLogin = LaunchAtLogin.isEnabled
            enforceInsertionProbeSampleTextLimit()
            refreshPermissionState()
            hotkeyMonitor.resumeIfPossible()
            Task { @MainActor in
                transcriber.refreshFrontmostAppContext()
            }
        }
        .onReceive(permissionTimer) { _ in
            refreshPermissionState()
            hotkeyMonitor.resumeIfPossible()
            Task { @MainActor in
                transcriber.refreshFrontmostAppContext()
            }
        }
        .onDisappear {
            stopHotkeyCapture()
            hotkeyCaptureSuccessResetTask?.cancel()
            hotkeyCaptureSuccessResetTask = nil
            hotkeyCopyMessageResetTask?.cancel()
            hotkeyCopyMessageResetTask = nil
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView(transcriber: transcriber)
        }
        .onChange(of: requiredCommand) { _, newValue in
            if newValue { forbiddenCommand = false }
        }
        .onChange(of: requiredShift) { _, newValue in
            if newValue { forbiddenShift = false }
        }
        .onChange(of: requiredOption) { _, newValue in
            if newValue { forbiddenOption = false }
        }
        .onChange(of: requiredControl) { _, newValue in
            if newValue { forbiddenControl = false }
        }
        .onChange(of: requiredCapsLock) { _, newValue in
            if newValue { forbiddenCapsLock = false }
        }
        .onChange(of: forbiddenCommand) { _, newValue in
            if newValue { requiredCommand = false }
        }
        .onChange(of: forbiddenShift) { _, newValue in
            if newValue { requiredShift = false }
        }
        .onChange(of: forbiddenOption) { _, newValue in
            if newValue { requiredOption = false }
        }
        .onChange(of: forbiddenControl) { _, newValue in
            if newValue { requiredControl = false }
        }
        .onChange(of: forbiddenCapsLock) { _, newValue in
            if newValue { requiredCapsLock = false }
        }
        .onChange(of: modelSourceRaw) { _, newValue in
            let parsed = ModelSource(rawValue: newValue) ?? .bundledTiny
            Task { @MainActor in
                transcriber.setModelSource(parsed)
            }
        }
    }

    @ViewBuilder
    private func modifierGrid(
        command: Binding<Bool>,
        shift: Binding<Bool>,
        option: Binding<Bool>,
        control: Binding<Bool>,
        capsLock: Binding<Bool>
    ) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 8) {
            GridRow {
                Toggle("Command", isOn: command)
                Toggle("Shift", isOn: shift)
            }
            GridRow {
                Toggle("Option", isOn: option)
                Toggle("Control", isOn: control)
            }
            GridRow {
                Toggle("Caps Lock", isOn: capsLock)
                Spacer()
            }
        }
        .toggleStyle(.checkbox)
    }

    @ViewBuilder
    private func permissionRow(title: String, granted: Bool, actionTitle: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .frame(width: 110, alignment: .leading)
            Text(granted ? "Granted" : "Missing")
                .foregroundStyle(granted ? .green : .orange)
                .frame(width: 80, alignment: .leading)
            Button(actionTitle, action: action)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }

    private func profileBinding(_ bundleIdentifier: String, _ keyPath: WritableKeyPath<AppProfile, Bool>) -> Binding<Bool> {
        Binding(
            get: {
                transcriber.appProfiles.first(where: { $0.bundleIdentifier == bundleIdentifier })?[keyPath: keyPath] ?? false
            },
            set: { newValue in
                guard var profile = transcriber.appProfiles.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
                    return
                }
                profile[keyPath: keyPath] = newValue
                Task { @MainActor in
                    transcriber.updateProfile(profile)
                }
            }
        )
    }

    private func profileStringBinding(_ bundleIdentifier: String, _ keyPath: WritableKeyPath<AppProfile, String>) -> Binding<String> {
        Binding(
            get: {
                transcriber.appProfiles.first(where: { $0.bundleIdentifier == bundleIdentifier })?[keyPath: keyPath] ?? ""
            },
            set: { newValue in
                guard var profile = transcriber.appProfiles.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
                    return
                }
                profile[keyPath: keyPath] = newValue
                Task { @MainActor in
                    transcriber.updateProfile(profile)
                }
            }
        )
    }

    private var currentHotkeyMode: HotkeyMode {
        HotkeyMode(rawValue: hotkeyModeRaw) ?? .toggle
    }

    private var hotkeyModeTipText: String {
        let usesEscapeTrigger = effectiveHotkeyRiskContext.key == "escape"

        switch currentHotkeyMode {
        case .toggle:
            if usesEscapeTrigger {
                return "Tip: toggle mode starts recording on the first press and stops on the next press. Escape quick-cancel is unavailable while Escape is the trigger key."
            }
            return "Tip: toggle mode starts recording on the first press and stops on the next press. Press Esc while recording to discard."
        case .hold:
            if usesEscapeTrigger {
                return "Tip: hold-to-talk records while the combo is pressed and stops on release. Escape quick-cancel is unavailable while Escape is the trigger key."
            }
            return "Tip: hold-to-talk records while the combo is pressed and stops on release. Press Esc while recording to discard."
        }
    }

    private var hotkeyCaptureButtonTitle: String {
        guard isCapturingHotkey else {
            return "Record shortcut"
        }

        return "Listening… \(hotkeyCaptureSecondsRemaining)s"
    }

    private var hotkeyCaptureInstruction: String {
        if inputMonitoringAuthorized {
            return "Listening for the next key press (works even if another app is focused). Hold modifiers and press your trigger key once. Press Esc to cancel. (\(hotkeyCaptureSecondsRemaining)s left)"
        }

        return "Listening for the next key press in OpenWhisper only. Input Monitoring is missing, so shortcut capture from other apps is unavailable until permission is granted. Press Esc to cancel. (\(hotkeyCaptureSecondsRemaining)s left)"
    }

    private var hotkeyCaptureProgress: Double {
        guard hotkeyCaptureTimeoutSeconds > 0 else {
            return 0
        }

        return min(max(Double(hotkeyCaptureSecondsRemaining) / Double(hotkeyCaptureTimeoutSeconds), 0), 1)
    }

    private var isHotkeyKeyDraftSupported: Bool {
        guard let key = normalizedHotkeyDraftForApply else {
            return false
        }
        return HotkeyDisplay.isSupportedKey(key)
    }

    private var hotkeyDraftValidationMessage: String? {
        let trimmedDraft = hotkeyKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedDraft.isEmpty {
            return "Enter one trigger key like space, f6, or /."
        }

        if !isHotkeyKeyDraftSupported {
            if looksLikeModifierComboInput(trimmedDraft),
               parseHotkeyDraft(trimmedDraft)?.requiredModifiers == nil {
                return "Trigger key expects one key (like space or f6), not modifiers only."
            }
            return "Unsupported key. Use a single character, named key, arrow, or F1-F24."
        }

        return nil
    }

    private var hasHotkeyDraftChangesToApply: Bool {
        guard let parsed = parseHotkeyDraft(hotkeyKeyDraft) else {
            return false
        }

        let sanitizedKey = sanitizeKeyValue(parsed.key)
        let keyChanged = sanitizedKey != sanitizeKeyValue(hotkeyKey)

        let modifiersChanged: Bool
        if let modifiers = parsed.requiredModifiers {
            modifiersChanged = modifiers != currentRequiredModifierSet
        } else {
            modifiersChanged = false
        }

        return keyChanged || modifiersChanged
    }

    private var hasHotkeyDraftEdits: Bool {
        let sanitizedDraft = sanitizeHotkeyDraftValue(hotkeyKeyDraft)
        if sanitizedDraft != sanitizeKeyValue(hotkeyKey) {
            return true
        }

        guard let parsed = parseHotkeyDraft(hotkeyKeyDraft),
              let modifiers = parsed.requiredModifiers else {
            return false
        }

        return modifiers != currentRequiredModifierSet
    }

    private var currentRequiredModifierSet: Set<ParsedModifier> {
        var result = Set<ParsedModifier>()
        if requiredCommand { result.insert(.command) }
        if requiredShift { result.insert(.shift) }
        if requiredOption { result.insert(.option) }
        if requiredControl { result.insert(.control) }
        if requiredCapsLock { result.insert(.capsLock) }
        return result
    }

    private var canonicalHotkeyDraftPreview: String? {
        guard let parsed = parseHotkeyDraft(hotkeyKeyDraft) else {
            return nil
        }

        let sanitized = sanitizeKeyValue(parsed.key)
        guard HotkeyDisplay.isSupportedKey(sanitized) else {
            return nil
        }

        let previewModifiers = parsed.requiredModifiers ?? currentRequiredModifierSet

        var parts: [String] = []
        if previewModifiers.contains(.command) { parts.append("⌘") }
        if previewModifiers.contains(.shift) { parts.append("⇧") }
        if previewModifiers.contains(.option) { parts.append("⌥") }
        if previewModifiers.contains(.control) { parts.append("⌃") }
        if previewModifiers.contains(.capsLock) { parts.append("⇪") }
        parts.append(HotkeyDisplay.displayKey(sanitized))
        return parts.joined(separator: "+")
    }

    private var hotkeyDraftModifierOverrideSummary: String? {
        guard let parsed = parseHotkeyDraft(hotkeyKeyDraft),
              let modifiers = parsed.requiredModifiers,
              modifiers != currentRequiredModifierSet else {
            return nil
        }

        let ordered: [(ParsedModifier, String)] = [
            (.command, "⌘ Command"),
            (.shift, "⇧ Shift"),
            (.option, "⌥ Option"),
            (.control, "⌃ Control"),
            (.capsLock, "⇪ Caps Lock")
        ]

        let active = ordered
            .filter { modifiers.contains($0.0) }
            .map(\.1)

        if active.isEmpty {
            return "none"
        }
        return active.joined(separator: " + ")
    }

    private var hotkeyDraftNonConfigurableModifierNotice: String? {
        guard let parsed = parseHotkeyDraft(hotkeyKeyDraft),
              parsed.containsNonConfigurableModifiers else {
            return nil
        }

        return "Fn/Globe modifiers aren't configurable yet. We'll apply the trigger key and keep your existing required modifiers."
    }

    private var commonHotkeyKeySections: [(title: String, keys: [String])] {
        [
            (
                title: "Basic",
                keys: ["space", "tab", "return", "escape", "delete", "forwarddelete", "insert", "fn", "globe"]
            ),
            (
                title: "Navigation",
                keys: ["left", "right", "up", "down", "home", "end", "pageup", "pagedown"]
            ),
            (
                title: "Function",
                keys: ["f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20", "f21", "f22", "f23", "f24"]
            ),
            (
                title: "Punctuation",
                keys: ["minus", "equals", "openbracket", "closebracket", "semicolon", "apostrophe", "comma", "period", "slash", "backslash", "backtick", "section"]
            ),
            (
                title: "Keypad",
                keys: ["keypad0", "keypad1", "keypad2", "keypad3", "keypad4", "keypad5", "keypad6", "keypad7", "keypad8", "keypad9", "keypaddecimal", "keypadcomma", "keypadclear", "keypadplus", "keypadminus", "keypadmultiply", "keypaddivide", "keypadenter", "keypadequals"]
            )
        ]
    }

    private var showsAutoPastePermissionWarning: Bool {
        autoPaste && !accessibilityAuthorized
    }

    private var hotkeyMissingPermissionSummary: String? {
        var missing: [String] = []
        if !accessibilityAuthorized {
            missing.append("Accessibility")
        }
        if !inputMonitoringAuthorized {
            missing.append("Input Monitoring")
        }
        guard !missing.isEmpty else {
            return nil
        }
        return missing.joined(separator: " + ")
    }

    private var canCaptureFrontmostProfile: Bool {
        transcriber.profileCaptureCandidate() != nil
    }

    private var captureProfileDisabledReason: String {
        "Couldn’t find a target app yet. Switch to the app where insertion should happen, then click Refresh frontmost app."
    }

    private var captureProfileUsesRecentAppFallback: Bool {
        transcriber.profileCaptureCandidate()?.isFallback == true
    }

    private var captureProfileFallbackAppName: String? {
        guard let candidate = transcriber.profileCaptureCandidate(), candidate.isFallback else {
            return nil
        }
        return candidate.appName
    }

    private var insertionTestTargetDisplay: String? {
        transcriber.manualInsertTargetDisplay()
    }

    private var insertionProbeSampleTextTrimmed: String {
        insertionProbeSampleText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func enforceInsertionProbeSampleTextLimit() {
        let limited = String(insertionProbeSampleText.prefix(insertionProbeMaxCharacters))
        if insertionProbeSampleText != limited {
            insertionProbeSampleText = limited
        }
    }

    private var insertionProbeSampleTextForRun: String {
        String(insertionProbeSampleTextTrimmed.prefix(insertionProbeMaxCharacters))
    }

    private var insertionProbeSampleTextWillTruncate: Bool {
        insertionProbeSampleTextTrimmed.count > insertionProbeMaxCharacters
    }

    private var hasInsertionProbeSampleText: Bool {
        !insertionProbeSampleTextForRun.isEmpty
    }

    private var isTranscriptionFinalizingForInsertion: Bool {
        transcriber.isFinalizingTranscription
    }

    private var canCaptureAndRunInsertionTest: Bool {
        canCaptureFrontmostProfile && !transcriber.isRecording && !isTranscriptionFinalizingForInsertion && !transcriber.isRunningInsertionProbe && hasInsertionProbeSampleText
    }

    private var canRunInsertionTest: Bool {
        guard !transcriber.isRecording else {
            return false
        }
        guard !isTranscriptionFinalizingForInsertion else {
            return false
        }
        guard !transcriber.isRunningInsertionProbe else {
            return false
        }
        guard insertionTestTargetDisplay != nil else {
            return false
        }
        return hasInsertionProbeSampleText
    }

    private var canRunInsertionTestWithAutoCapture: Bool {
        canRunInsertionTest || canCaptureAndRunInsertionTest
    }

    private var canFocusAndRunInsertionTest: Bool {
        canFocusInsertionTarget && canRunInsertionTest
    }

    private var insertionTestAutoCaptureTargetName: String? {
        guard !canRunInsertionTest,
              canCaptureAndRunInsertionTest,
              let candidate = transcriber.profileCaptureCandidate() else {
            return nil
        }
        return candidate.appName
    }

    private var runInsertionTestButtonTitle: String {
        if transcriber.isRunningInsertionProbe {
            return "Running insertion test…"
        }

        if canRunInsertionTest {
            return "Run insertion test"
        }

        if let targetName = insertionTestAutoCaptureTargetName, !targetName.isEmpty {
            return "Run insertion test (capture \(targetName))"
        }

        if canCaptureAndRunInsertionTest {
            return "Run insertion test (auto-capture)"
        }

        return "Run insertion test"
    }

    private var showsInsertionTestAutoCaptureHint: Bool {
        !transcriber.isRunningInsertionProbe && !canRunInsertionTest && canCaptureAndRunInsertionTest
    }

    private var canFocusInsertionTarget: Bool {
        guard !transcriber.isRecording else {
            return false
        }
        guard !isTranscriptionFinalizingForInsertion else {
            return false
        }
        return insertionTestTargetDisplay != nil
    }

    private var canClearInsertionTarget: Bool {
        guard !transcriber.isRunningInsertionProbe else {
            return false
        }
        return insertionTestTargetDisplay != nil
    }

    private func runInsertionTestFromTextFieldSubmission() {
        // Return in the sample-text field should be a fast-path action only when
        // a test can actually run. Avoid surfacing disabling errors while users
        // are still configuring target capture/permissions.
        guard canRunInsertionTestWithAutoCapture else {
            return
        }

        runInsertionTestUsingAvailableTarget()
    }

    private func runInsertionTestUsingAvailableTarget() {
        guard !transcriber.isRunningInsertionProbe else {
            return
        }

        Task { @MainActor in
            if canRunInsertionTest {
                _ = transcriber.runInsertionProbe(sampleText: insertionProbeSampleTextForRun)
                return
            }

            if canCaptureAndRunInsertionTest {
                // Auto-capture for insertion tests should only refresh the
                // runtime insertion target. Avoid creating/editing a profile
                // unless the user explicitly presses “Capture profile…”.
                transcriber.retargetManualInsertTarget()

                _ = transcriber.runInsertionProbe(sampleText: insertionProbeSampleTextForRun)
                return
            }

            let reason = insertionTestDisabledReason
            transcriber.statusMessage = reason
            transcriber.lastError = reason
            transcriber.lastInsertionProbeMessage = reason
        }
    }

    private var insertionTestDisabledReason: String {
        if transcriber.isRecording {
            return "Stop recording before running an insertion test."
        }
        if isTranscriptionFinalizingForInsertion {
            return "Wait for live transcription to finish finalizing before running an insertion test."
        }
        if transcriber.isRunningInsertionProbe {
            return "Insertion test is already running."
        }
        if !hasInsertionProbeSampleText {
            return "Insertion test text is empty. Enter a short phrase first."
        }
        return "No destination app is available for insertion yet. Switch to your target app, then refresh."
    }

    private var insertionProbeStatusColor: Color {
        switch transcriber.lastInsertionProbeSucceeded {
        case true:
            return .green
        case false:
            return .orange
        case nil:
            return .secondary
        }
    }

    private var effectiveHotkeyRiskContext: (requiredModifiers: Set<ParsedModifier>, key: String) {
        if let parsed = parseHotkeyDraft(hotkeyKeyDraft) {
            let parsedKey = sanitizeKeyValue(parsed.key)
            if HotkeyDisplay.isSupportedKey(parsedKey) {
                let modifiers = parsed.requiredModifiers ?? currentRequiredModifierSet
                return (modifiers, parsedKey)
            }
        }

        return (currentRequiredModifierSet, sanitizeKeyValue(hotkeyKey))
    }

    private var showsHighRiskHotkeyWarning: Bool {
        let context = effectiveHotkeyRiskContext
        guard context.requiredModifiers.isEmpty else {
            return false
        }

        if context.key.count == 1 {
            return true
        }

        switch context.key {
        case "space", "tab", "return", "delete", "forwarddelete", "escape", "fn", "left", "right", "up", "down", "home", "end", "pageup", "pagedown":
            return true
        default:
            return false
        }
    }

    private var showsHoldModeAccidentalTriggerWarning: Bool {
        guard hotkeyModeRaw == HotkeyMode.hold.rawValue else {
            return false
        }
        return showsHighRiskHotkeyWarning
    }

    private var hotkeyEscapeCancelConflictWarning: String? {
        let context = effectiveHotkeyRiskContext
        guard context.key == "escape" else {
            return nil
        }

        return "Esc is also used to discard an active recording. Using Esc as the trigger key disables that quick-cancel behavior."
    }

    private var hotkeySystemConflictWarning: String? {
        let context = effectiveHotkeyRiskContext
        let key = context.key
        let modifiers = context.requiredModifiers

        if key == "space" && modifiers == Set([.command]) {
            return "⌘+Space usually opens Spotlight and can block your hotkey."
        }

        if key == "space" && modifiers == Set([.control]) {
            return "⌃+Space is often used for input source switching on macOS."
        }

        if key == "space" && modifiers == Set([.control, .option]) {
            return "⌃+⌥+Space is commonly bound to previous input source on macOS and can steal your hotkey press."
        }

        if key == "space" && modifiers == Set([.command, .control]) {
            return "⌃+⌘+Space usually opens the emoji/symbol picker on macOS and can block dictation trigger behavior."
        }

        if key == "space" && modifiers == Set([.command, .option]) {
            return "⌥+⌘+Space usually opens Finder search on macOS, so it’s unreliable for dictation triggering."
        }

        if key == "space" && modifiers == Set([.command, .option, .control]) {
            return "⌃+⌥+⌘+Space is commonly used by app launchers/snippet tools and often gets intercepted before OpenWhisper."
        }

        if key == "f" && modifiers == Set([.command, .control]) {
            return "⌃+⌘+F toggles full-screen in many macOS apps and is a bad dictation hotkey."
        }

        if key == "tab" && modifiers == Set([.command]) {
            return "⌘+Tab is reserved for app switching and won't behave as a reliable dictation hotkey."
        }

        if key == "fn" && modifiers.isEmpty {
            return "Fn/Globe alone is usually reserved by macOS (emoji picker, dictation, or input switching) and is unreliable as a trigger key."
        }

        if key == "tab" && modifiers == Set([.command, .shift]) {
            return "⌘+⇧+Tab is reserved for reverse app switching on macOS."
        }

        if ["3", "4", "5", "6"].contains(key),
           modifiers.contains(.command),
           modifiers.contains(.shift),
           modifiers.isSubset(of: Set([.command, .shift, .control])) {
            switch key {
            case "3":
                return "⌘+⇧+3 is reserved for macOS screenshots (entire screen), so it will conflict with dictation trigger behavior."
            case "4":
                return "⌘+⇧+4 is reserved for macOS screenshots (selection/window), so it will conflict with dictation trigger behavior."
            case "5":
                return "⌘+⇧+5 opens the macOS screenshot/recording panel and is a bad dictation hotkey choice."
            default:
                return "⌘+⇧+6 toggles floating thumbnail behavior in the macOS screenshot tool and can conflict with dictation hotkeys."
            }
        }

        if key == "backtick" && modifiers == Set([.command]) {
            return "⌘+` is reserved for cycling windows in the front app on macOS."
        }

        if key == "section" && modifiers == Set([.command]) {
            return "⌘+§ usually cycles windows in the front app on ISO keyboards and can steal your dictation hotkey."
        }

        if key == "section" && modifiers == Set([.command, .shift]) {
            return "⌘+⇧+§ usually cycles windows in reverse on ISO keyboards and can steal your dictation hotkey."
        }

        if key == "comma" && modifiers == Set([.command]) {
            return "⌘+, usually opens app settings/preferences and is a frustrating dictation trigger."
        }

        if key == "period" && modifiers == Set([.command]) {
            return "⌘+. is commonly used as Cancel/Stop in macOS apps and is easy to trigger accidentally."
        }

        if key == "escape" && modifiers == Set([.command, .option]) {
            return "⌥+⌘+Esc opens Force Quit on macOS, so it’s a terrible hotkey choice."
        }

        if key == "h" && modifiers == Set([.command]) {
            return "⌘+H hides the current app on macOS and makes a poor dictation hotkey."
        }

        if key == "c" && modifiers == Set([.command]) {
            return "⌘+C copies selected text in most apps, so it collides with normal editing constantly."
        }

        if key == "v" && modifiers == Set([.command]) {
            return "⌘+V pastes in most apps and will fight your normal editing flow."
        }

        if key == "x" && modifiers == Set([.command]) {
            return "⌘+X cuts selected text in most apps and is a risky dictation trigger."
        }

        if key == "a" && modifiers == Set([.command]) {
            return "⌘+A selects all text in most apps and is too disruptive for dictation."
        }

        if key == "z" && modifiers == Set([.command]) {
            return "⌘+Z is undo in most apps and will cause accidental reversions while typing."
        }

        if key == "m" && modifiers == Set([.command]) {
            return "⌘+M minimizes the front window on macOS and can interrupt your flow."
        }

        if key == "return" && modifiers == Set([.command]) {
            return "⌘+Return often sends messages/submits forms in chat and email apps, so it’s risky for dictation."
        }

        if key == "q" && modifiers == Set([.command]) {
            return "⌘+Q quits the current app on macOS and is a brutal hotkey choice for dictation."
        }

        if key == "q" && modifiers == Set([.command, .control]) {
            return "⌃+⌘+Q locks your Mac on macOS and is an awful choice for a dictation hotkey."
        }

        if key == "w" && modifiers == Set([.command]) {
            return "⌘+W closes the current window/tab on macOS and can kill focus mid-dictation."
        }

        if key == "s" && modifiers == Set([.command]) {
            return "⌘+S saves in most apps and will trigger constantly during normal editing."
        }

        if key == "f" && modifiers == Set([.command]) {
            return "⌘+F opens Find in most apps and is a noisy dictation trigger."
        }

        if key == "n" && modifiers == Set([.command]) {
            return "⌘+N creates a new document/window in many apps and is too disruptive for dictation."
        }

        if key == "t" && modifiers == Set([.command]) {
            return "⌘+T opens a new tab in many apps and browsers, so it collides with normal workflow."
        }

        if key == "p" && modifiers == Set([.command]) {
            return "⌘+P opens Print in most apps and is a brutal accidental trigger."
        }

        if key == "r" && modifiers == Set([.command]) {
            return "⌘+R refreshes/reloads in browsers and many apps, so it’s a noisy dictation trigger."
        }

        if key == "o" && modifiers == Set([.command]) {
            return "⌘+O opens files/documents in many apps and will interrupt normal workflow."
        }

        if key == "l" && modifiers == Set([.command]) {
            return "⌘+L often focuses location/search fields (especially in browsers), making it a disruptive dictation hotkey."
        }

        return nil
    }

    private func refreshPermissionState() {
        let previouslyMissingHotkeyPermissions = !accessibilityAuthorized || !inputMonitoringAuthorized

        microphoneAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        accessibilityAuthorized = HotkeyMonitor.hasAccessibilityPermission()
        inputMonitoringAuthorized = HotkeyMonitor.hasInputMonitoringPermission()

        let missingHotkeyPermissions = !accessibilityAuthorized || !inputMonitoringAuthorized
        if previouslyMissingHotkeyPermissions && !missingHotkeyPermissions {
            // UX: as soon as both permissions are granted, recover hotkey capture
            // automatically instead of forcing the user to click "Restart monitor".
            hotkeyMonitor.start()
        } else if !previouslyMissingHotkeyPermissions && missingHotkeyPermissions {
            // Keep status truthful if permissions are revoked while Settings is open.
            // Without this, the UI may still look active until a manual restart.
            hotkeyMonitor.stop()
        }
    }

    private func applyHotkeyKeyDraft() {
        hotkeyCaptureSuccessMessage = nil
        hotkeyApplyMessage = nil
        hotkeyApplyErrorMessage = nil

        guard let parsed = parseHotkeyDraft(hotkeyKeyDraft) else {
            hotkeyApplyErrorMessage = "Enter one trigger key first (for example: space, f6, or /)."
            return
        }

        let sanitized = sanitizeKeyValue(parsed.key)
        hotkeyKeyDraft = sanitized
        guard HotkeyDisplay.isSupportedKey(sanitized) else {
            hotkeyApplyErrorMessage = "Unsupported trigger key. Use one key like Space, F6, /, or a letter/number."
            return
        }

        if let modifiers = parsed.requiredModifiers {
            requiredCommand = modifiers.contains(.command)
            requiredShift = modifiers.contains(.shift)
            requiredOption = modifiers.contains(.option)
            requiredControl = modifiers.contains(.control)
            requiredCapsLock = modifiers.contains(.capsLock)

            forbiddenCommand = !requiredCommand && forbiddenCommand
            forbiddenShift = !requiredShift && forbiddenShift
            forbiddenOption = !requiredOption && forbiddenOption
            forbiddenControl = !requiredControl && forbiddenControl
            forbiddenCapsLock = !requiredCapsLock && forbiddenCapsLock
        }

        hotkeyKey = sanitized
        hotkeyApplyMessage = "Applied: \(hotkeySummary())"
    }

    private func pasteHotkeyComboFromClipboard() {
        hotkeyApplyErrorMessage = nil

        guard let raw = NSPasteboard.general.string(forType: .string) else {
            hotkeyApplyErrorMessage = "Clipboard is empty. Copy a shortcut like ⌘⇧Space and try again."
            return
        }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            hotkeyApplyErrorMessage = "Clipboard is empty. Copy a shortcut like ⌘⇧Space and try again."
            return
        }

        hotkeyKeyDraft = sanitizeHotkeyDraftValue(trimmed)
        applyHotkeyKeyDraft()
    }

    private func resetHotkeyDefaults() {
        applyHotkeyPreset(.toggle)
    }

    private func applyHotkeyPreset(_ mode: HotkeyMode) {
        hotkeyModeRaw = mode.rawValue
        hotkeyKey = "space"
        hotkeyKeyDraft = "space"

        applySafeRequiredModifiers()
    }

    private func applySafeRequiredModifiers() {
        requiredCommand = true
        requiredShift = true
        requiredOption = false
        requiredControl = false
        requiredCapsLock = false

        forbiddenCommand = false
        forbiddenShift = false
        forbiddenOption = true
        forbiddenControl = true
        forbiddenCapsLock = false
    }

    private func shouldAutoApplySafeCaptureModifiers(for key: String) -> Bool {
        // Preserve no-modifier intent for keys that are typically safe to hit
        // directly (function row, arrows, etc.). For letter/number typing keys,
        // auto-add ⌘+⇧ so captured shortcuts stay usable immediately.
        if key.count == 1 {
            return true
        }

        switch key {
        case "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12",
             "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20", "f21", "f22", "f23", "f24",
             "escape", "tab", "return", "enter", "keypadenter", "numpadenter", "space", "insert", "ins", "help",
             "delete", "del", "backspace", "bksp", "forwarddelete", "fwddelete", "fwddel",
             "left", "right", "up", "down", "home", "end", "pageup", "pagedown",
             "fn", "function", "globe", "globekey", "caps", "capslock":
            return false
        default:
            return true
        }
    }

    private func startHotkeyCapture() {
        stopHotkeyCapture()
        hotkeyCaptureError = nil
        hotkeyCaptureSuccessMessage = nil
        hotkeyCaptureSuccessResetTask?.cancel()
        hotkeyCaptureSuccessResetTask = nil
        hotkeyApplyMessage = nil
        isCapturingHotkey = true
        hotkeyCaptureSecondsRemaining = hotkeyCaptureTimeoutSeconds
        hotkeyCaptureStartedAt = Date()

        if !inputMonitoringAuthorized {
            hotkeyCaptureError = "Input Monitoring permission is missing. Capture works only while OpenWhisper is focused."
        }

        hotkeyCaptureLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            captureHotkey(from: event)
            return nil
        }

        if inputMonitoringAuthorized {
            hotkeyCaptureGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
                captureHotkey(from: event)
            }
        }

        hotkeyCaptureTimeoutTask?.cancel()
        hotkeyCaptureTimeoutTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else {
                    return
                }

                await MainActor.run {
                    guard isCapturingHotkey else {
                        return
                    }

                    hotkeyCaptureSecondsRemaining -= 1

                    if hotkeyCaptureSecondsRemaining <= 0 {
                        if inputMonitoringAuthorized {
                            hotkeyCaptureError = "Hotkey capture timed out. Click Record shortcut and try again."
                        } else {
                            hotkeyCaptureError = "Hotkey capture timed out. Input Monitoring permission is still missing, so capture only works while OpenWhisper stays focused."
                        }
                        stopHotkeyCapture(clearError: false)
                    }
                }
            }
        }
    }

    private func stopHotkeyCapture(clearError: Bool = true) {
        if let hotkeyCaptureLocalMonitor {
            NSEvent.removeMonitor(hotkeyCaptureLocalMonitor)
            self.hotkeyCaptureLocalMonitor = nil
        }

        if let hotkeyCaptureGlobalMonitor {
            NSEvent.removeMonitor(hotkeyCaptureGlobalMonitor)
            self.hotkeyCaptureGlobalMonitor = nil
        }

        hotkeyCaptureTimeoutTask?.cancel()
        hotkeyCaptureTimeoutTask = nil

        if clearError {
            hotkeyCaptureError = nil
        }
        hotkeyCaptureSecondsRemaining = 0
        isCapturingHotkey = false
    }

    private func scheduleHotkeyCaptureSuccessReset() {
        hotkeyCaptureSuccessResetTask?.cancel()
        hotkeyCaptureSuccessResetTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else {
                return
            }
            hotkeyCaptureSuccessMessage = nil
            hotkeyCaptureSuccessResetTask = nil
        }
    }

    private func captureHotkey(from event: NSEvent) {
        guard isCapturingHotkey else {
            return
        }

        // Ignore key-repeat events while recording a shortcut so holding a key
        // doesn't accidentally re-capture or override the first intentional press.
        if event.isARepeat {
            return
        }

        if shouldIgnoreCaptureActivationEvent(event) {
            return
        }

        if isModifierOnlyHotkeyEvent(event) {
            hotkeyCaptureError = "Press one non-modifier key while holding modifiers (for example: ⌘+⇧+Space)."
            return
        }

        guard let key = hotkeyKeyName(from: event) else {
            hotkeyCaptureError = "Couldn't read that key. Try again with a different key."
            return
        }

        // Fn/Globe currently isn't configurable as a required modifier.
        // If users hold it while recording another key (common on laptops),
        // ignore Fn instead of rejecting the whole capture attempt.
        hotkeyCaptureError = nil

        // Ignore Caps Lock state during capture. If Caps Lock is currently on,
        // NSEvent reports `.capsLock` for every key press, which would
        // accidentally force Caps Lock as a required modifier.
        let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])

        // UX: plain Escape cancels capture. If modifiers are held, treat Escape
        // as a valid trigger key so users can record combos like ⌘+Esc.
        if key == "escape" && modifiers.isEmpty {
            hotkeyCaptureError = "Hotkey capture canceled."
            stopHotkeyCapture(clearError: false)
            return
        }

        let sanitized = sanitizeKeyValue(key)
        guard HotkeyDisplay.isSupportedKey(sanitized) else {
            hotkeyCaptureError = "Unsupported key for hotkey trigger. Use one key like Space, F6, /, or a letter/number."
            return
        }

        hotkeyKeyDraft = sanitized
        hotkeyKey = sanitized

        requiredCommand = modifiers.contains(.command)
        requiredShift = modifiers.contains(.shift)
        requiredOption = modifiers.contains(.option)
        requiredControl = modifiers.contains(.control)
        // Capture currently ignores Caps Lock state to avoid accidentally
        // recording it when the lock is simply active on the keyboard.
        // Reset required Caps Lock here so recording a new shortcut never
        // keeps a stale Caps Lock requirement from an older configuration.
        requiredCapsLock = false

        var autoAppliedSafeModifiers = false
        if modifiers.isEmpty,
           shouldAutoApplySafeCaptureModifiers(for: sanitized) {
            requiredCommand = true
            requiredShift = true
            autoAppliedSafeModifiers = true
        }

        forbiddenCommand = !requiredCommand && forbiddenCommand
        forbiddenShift = !requiredShift && forbiddenShift
        forbiddenOption = !requiredOption && forbiddenOption
        forbiddenControl = !requiredControl && forbiddenControl
        forbiddenCapsLock = !requiredCapsLock && forbiddenCapsLock

        if autoAppliedSafeModifiers {
            hotkeyCaptureSuccessMessage = "Captured: \(hotkeySummary()) (added ⌘+⇧ for safer typing)"
        } else {
            hotkeyCaptureSuccessMessage = "Captured: \(hotkeySummary())"
        }
        scheduleHotkeyCaptureSuccessReset()
        stopHotkeyCapture()
    }

    private func shouldIgnoreCaptureActivationEvent(_ event: NSEvent) -> Bool {
        // UX: avoid accidentally capturing the same shortcut used to start
        // recording (⌘+⇧+K) when users trigger capture from the keyboard.
        // Ignore only immediately after capture starts so intentional uses of
        // that combo can still be recorded by pressing it again.
        let elapsed = Date().timeIntervalSince(hotkeyCaptureStartedAt)
        guard elapsed <= 0.35 else {
            return false
        }

        guard let key = hotkeyKeyName(from: event), key == "k" else {
            return false
        }

        let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
        return modifiers == [.command, .shift]
    }

    private func isModifierOnlyHotkeyEvent(_ event: NSEvent) -> Bool {
        switch Int(event.keyCode) {
        case kVK_Command, kVK_RightCommand,
             kVK_Shift, kVK_RightShift,
             kVK_Option, kVK_RightOption,
             kVK_Control, kVK_RightControl,
             kVK_CapsLock,
             kVK_Function:
            return true
        default:
            return false
        }
    }

    private func hotkeyKeyName(from event: NSEvent) -> String? {
        switch Int(event.keyCode) {
        case kVK_Command, kVK_Shift, kVK_RightShift, kVK_Option, kVK_RightOption, kVK_Control, kVK_RightControl, kVK_CapsLock:
            return nil
        case kVK_Function:
            return "fn"
        case kVK_Space: return "space"
        case kVK_Tab: return "tab"
        case kVK_Return: return "return"
        case kVK_Escape: return "escape"
        case kVK_Delete: return "delete"
        case kVK_ForwardDelete: return "forwarddelete"
        case kVK_Help: return "insert"
        case kVK_LeftArrow: return "left"
        case kVK_RightArrow: return "right"
        case kVK_UpArrow: return "up"
        case kVK_DownArrow: return "down"
        case kVK_Home: return "home"
        case kVK_End: return "end"
        case kVK_PageUp: return "pageup"
        case kVK_PageDown: return "pagedown"
        case kVK_F1: return "f1"
        case kVK_F2: return "f2"
        case kVK_F3: return "f3"
        case kVK_F4: return "f4"
        case kVK_F5: return "f5"
        case kVK_F6: return "f6"
        case kVK_F7: return "f7"
        case kVK_F8: return "f8"
        case kVK_F9: return "f9"
        case kVK_F10: return "f10"
        case kVK_F11: return "f11"
        case kVK_F12: return "f12"
        case kVK_F13: return "f13"
        case kVK_F14: return "f14"
        case kVK_F15: return "f15"
        case kVK_F16: return "f16"
        case kVK_F17: return "f17"
        case kVK_F18: return "f18"
        case kVK_F19: return "f19"
        case kVK_F20: return "f20"
        case 0x6E: return "f21"
        case 0x6F: return "f22"
        case 0x70: return "f23"
        case 0x71: return "f24"
        case kVK_ANSI_Keypad0: return "keypad0"
        case kVK_ANSI_Keypad1: return "keypad1"
        case kVK_ANSI_Keypad2: return "keypad2"
        case kVK_ANSI_Keypad3: return "keypad3"
        case kVK_ANSI_Keypad4: return "keypad4"
        case kVK_ANSI_Keypad5: return "keypad5"
        case kVK_ANSI_Keypad6: return "keypad6"
        case kVK_ANSI_Keypad7: return "keypad7"
        case kVK_ANSI_Keypad8: return "keypad8"
        case kVK_ANSI_Keypad9: return "keypad9"
        case kVK_ANSI_KeypadDecimal: return "keypaddecimal"
        case kVK_JIS_KeypadComma: return "keypadcomma"
        case kVK_ANSI_KeypadMultiply: return "keypadmultiply"
        case kVK_ANSI_KeypadPlus: return "keypadplus"
        case kVK_ANSI_KeypadClear: return "keypadclear"
        case kVK_ANSI_KeypadDivide: return "keypaddivide"
        case kVK_ANSI_KeypadEnter: return "keypadenter"
        case kVK_ANSI_KeypadMinus: return "keypadminus"
        case kVK_ANSI_KeypadEquals: return "keypadequals"
        default:
            guard let characters = event.charactersIgnoringModifiers?.lowercased(),
                  let scalar = characters.unicodeScalars.first else {
                return nil
            }

            if scalar.properties.isWhitespace {
                return "space"
            }

            return HotkeyDisplay.canonicalKey(String(scalar))
        }
    }

    private var normalizedHotkeyDraftForApply: String? {
        guard let parsed = parseHotkeyDraft(hotkeyKeyDraft) else {
            return nil
        }
        return parsed.key
    }

    private func sanitizeHotkeyDraftValue(_ raw: String) -> String {
        raw.lowercased()
    }

    private struct ParsedHotkeyDraft {
        var key: String
        var requiredModifiers: Set<ParsedModifier>?
        var containsNonConfigurableModifiers: Bool
    }

    private enum ParsedModifier: Hashable {
        case command
        case shift
        case option
        case control
        case capsLock
    }

    private func parseHotkeyDraft(_ raw: String) -> ParsedHotkeyDraft? {
        // Preserve a literal single-space input so pressing Space in the key field
        // is treated as the Space key instead of being trimmed to empty.
        let loweredRaw = raw.lowercased()
        if loweredRaw == " " {
            return ParsedHotkeyDraft(key: "space", requiredModifiers: nil, containsNonConfigurableModifiers: false)
        }

        let normalized = loweredRaw
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else {
            return nil
        }

        let normalizedAsWholeKey = HotkeyDisplay.canonicalKey(normalized)
        if !looksLikeModifierComboInput(normalized),
           HotkeyDisplay.isSupportedKey(normalizedAsWholeKey) {
            return ParsedHotkeyDraft(key: normalizedAsWholeKey, requiredModifiers: nil, containsNonConfigurableModifiers: false)
        }

        if normalized.contains("+") || normalized.contains(",") {
            let tokens = splitPlusCommaHotkeyTokens(normalized)
            return parseHotkeyTokens(tokens)
        }

        // Also accept slash-separated combos copied from docs/chat,
        // e.g. "command/shift/space".
        // Keep literal trailing slash keys ("cmd+shift+/") untouched.
        if normalized.contains("/"), !normalized.hasSuffix("/") {
            let tokens = normalized
                .split(separator: "/")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            if tokens.contains(where: { parseModifierToken($0) != nil }) {
                return parseHotkeyTokens(tokens)
            }
        }

        // UX nicety: allow pasting combos without plus separators,
        // e.g. "cmd shift space" or "command option f6".
        if normalized.contains(" ") {
            let tokens = normalized
                .split(whereSeparator: { $0.isWhitespace })
                .map(String.init)
                .filter { !$0.isEmpty }

            if tokens.contains(where: { parseModifierToken($0) != nil }) {
                if let parsed = parseHotkeyTokens(tokens) {
                    return parsed
                }

                let mergedTokens = mergeSpaceSeparatedKeyTokens(tokens)
                if mergedTokens != tokens {
                    return parseHotkeyTokens(mergedTokens)
                }
            }
        }

        // Also accept hyphen-separated combos copied from docs/chat,
        // e.g. "cmd-shift-space".
        if normalized.contains("-") {
            let tokens = normalized
                .split(separator: "-")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            if tokens.contains(where: { parseModifierToken($0) != nil }) {
                return parseHotkeyTokens(tokens)
            }
        }

        // Robust fallback for mixed separators copied from chats/docs,
        // e.g. "cmd + shift-space", "command_shift+page down", or
        // "ctrl- alt + delete".
        if normalized.contains(where: { $0 == "+" || $0 == "-" || $0 == "_" || $0 == "," || $0 == "/" || $0.isWhitespace }) {
            let tokens = normalized
                .components(separatedBy: CharacterSet(charactersIn: "+-_,/ "))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            if tokens.contains(where: { parseModifierToken($0) != nil }) {
                if let parsed = parseHotkeyTokens(tokens) {
                    return parsed
                }

                let mergedTokens = mergeSpaceSeparatedKeyTokens(tokens)
                if mergedTokens != tokens {
                    return parseHotkeyTokens(mergedTokens)
                }
            }
        }

        // Accept compact symbol-prefix combos without separators,
        // e.g. "⌘⇧space", "@~f6", or "⌃⌥return".
        let expandedCompactTokens = expandCompactModifierToken(normalized)
        if expandedCompactTokens.count > 1,
           expandedCompactTokens.contains(where: { parseModifierToken($0) != nil }) {
            return parseHotkeyTokens(expandedCompactTokens)
        }

        return ParsedHotkeyDraft(key: normalized, requiredModifiers: nil, containsNonConfigurableModifiers: false)
    }

    private func looksLikeModifierComboInput(_ raw: String) -> Bool {
        if raw.contains("⌘") || raw.contains("⇧") || raw.contains("⌥") || raw.contains("⌃") || raw.contains("⇪") {
            return true
        }

        let tokens = raw
            .components(separatedBy: CharacterSet(charactersIn: "+-_,/ "))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return tokens.contains { parseModifierToken($0) != nil }
    }

    private func splitPlusCommaHotkeyTokens(_ raw: String) -> [String] {
        var tokens = raw
            .split(whereSeparator: { $0 == "+" || $0 == "," })
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Pasted shortcuts like "cmd++" or "cmd+shift++" mean the
        // trigger key is literal plus. Preserve that trailing key instead
        // of dropping it during split.
        if raw.hasSuffix("+") {
            tokens.append("plus")
        } else if raw.hasSuffix(",") {
            tokens.append("comma")
        }

        return tokens
    }

    private func mergeSpaceSeparatedKeyTokens(_ tokens: [String]) -> [String] {
        guard !tokens.isEmpty else {
            return tokens
        }

        guard let firstNonModifierIndex = tokens.firstIndex(where: { parseModifierToken($0) == nil }) else {
            return tokens
        }

        guard firstNonModifierIndex < tokens.count - 1 else {
            return tokens
        }

        let trailingTokens = Array(tokens[(firstNonModifierIndex + 1)...])
        if trailingTokens.contains(where: { parseModifierToken($0) != nil }) {
            return tokens
        }

        let mergedKey = tokens[firstNonModifierIndex...].joined(separator: " ")
        var merged = Array(tokens[..<firstNonModifierIndex])
        merged.append(mergedKey)
        return merged
    }

    private func parseHotkeyTokens(_ tokens: [String]) -> ParsedHotkeyDraft? {
        guard !tokens.isEmpty else {
            return nil
        }

        var modifiers = Set<ParsedModifier>()
        var keyToken: String?
        var sawConfigurableModifier = false
        var sawNonConfigurableModifier = false

        for token in tokens {
            let expandedTokens = expandCompactModifierToken(token)

            for expandedToken in expandedTokens {
                if let modifier = parseModifierToken(expandedToken) {
                    modifiers.insert(modifier)
                    sawConfigurableModifier = true
                    continue
                }

                if isNonConfigurableModifierToken(expandedToken) {
                    // Users frequently paste combos containing Globe/Fn from
                    // docs or macOS shortcuts. We don't expose these as
                    // configurable required modifiers yet, so ignore them
                    // instead of treating the paste as invalid.
                    sawNonConfigurableModifier = true
                    continue
                }

                if keyToken != nil {
                    // Reject ambiguous combos like "cmd+shift+a+b" instead of
                    // silently accepting only the last key token.
                    return nil
                }
                keyToken = expandedToken
            }
        }

        guard let keyToken else {
            return nil
        }

        // UX: if the pasted combo only included non-configurable modifiers
        // (like Fn/Globe), keep current required modifier toggles unchanged
        // instead of clearing them to none.
        let parsedRequiredModifiers: Set<ParsedModifier>? =
            (sawConfigurableModifier || !sawNonConfigurableModifier) ? modifiers : nil

        return ParsedHotkeyDraft(
            key: keyToken,
            requiredModifiers: parsedRequiredModifiers,
            containsNonConfigurableModifiers: sawNonConfigurableModifier
        )
    }

    private func expandCompactModifierToken(_ token: String) -> [String] {
        let normalized = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return []
        }

        var remainder = normalized
        var expanded: [String] = []

        let modifierPrefixes: [(symbol: String, token: String)] = [
            ("⌘", "cmd"),
            ("@", "cmd"),
            ("⇧", "shift"),
            ("$", "shift"),
            ("⌥", "opt"),
            ("~", "opt"),
            ("⌃", "ctrl"),
            ("^", "ctrl"),
            ("⇪", "caps"),
            ("🌐", "globe")
        ]

        while remainder.count > 1 {
            var matchedPrefix = false

            for prefix in modifierPrefixes {
                if remainder.hasPrefix(prefix.symbol) {
                    expanded.append(prefix.token)
                    remainder.removeFirst(prefix.symbol.count)
                    matchedPrefix = true
                    break
                }
            }

            if !matchedPrefix {
                break
            }
        }

        if !remainder.isEmpty {
            expanded.append(remainder)
        }

        return expanded
    }

    private func parseModifierToken(_ token: String) -> ParsedModifier? {
        switch token {
        // Common cross-platform docs often use "CommandOrControl"
        // (or compact aliases like "cmdorctrl"). On macOS this should map
        // to Command so pasted shortcuts apply without manual cleanup.
        case "cmd", "command", "meta", "super", "win", "windows", "commandorcontrol", "controlorcommand", "cmdorctrl", "ctrlorcmd", "⌘", "@": return .command
        case "shift", "⇧", "$": return .shift
        case "opt", "option", "alt", "⌥", "~": return .option
        case "ctrl", "control", "ctl", "⌃", "^": return .control
        case "caps", "capslock", "⇪": return .capsLock
        default: return nil
        }
    }

    private func isNonConfigurableModifierToken(_ token: String) -> Bool {
        switch token {
        case "fn", "function", "globe", "globekey", "🌐":
            return true
        default:
            return false
        }
    }

    private func sanitizeKeyValue(_ raw: String) -> String {
        let normalized = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if normalized.isEmpty { return "space" }
        if normalized == " " { return "space" }
        return HotkeyDisplay.canonicalKey(normalized)
    }

    private func copyHotkeySummaryToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let mode = HotkeyMode(rawValue: hotkeyModeRaw) ?? .toggle
        _ = pasteboard.setString("\(mode.title) • \(hotkeySummary())", forType: .string)

        hotkeyCopyMessage = "Copied hotkey summary."
        hotkeyCopyMessageResetTask?.cancel()
        hotkeyCopyMessageResetTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            hotkeyCopyMessage = nil
            hotkeyCopyMessageResetTask = nil
        }
    }

    private func hotkeySummary() -> String {
        var parts: [String] = []
        if requiredCommand { parts.append("⌘") }
        if requiredShift { parts.append("⇧") }
        if requiredOption { parts.append("⌥") }
        if requiredControl { parts.append("⌃") }
        if requiredCapsLock { parts.append("⇪") }
        parts.append(HotkeyDisplay.displayKey(hotkeyKey))
        return parts.joined(separator: "+")
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func sizeOfModel(path: String) -> Int64 {
        if path.isEmpty,
           let bundledURL = Bundle.module.url(forResource: "ggml-tiny", withExtension: "bin"),
           let attrs = try? FileManager.default.attributesOfItem(atPath: bundledURL.path),
           let size = attrs[.size] as? Int64 {
            return size
        }

        guard !path.isEmpty,
              let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attrs[.size] as? Int64 else {
            return 0
        }
        return size
    }

    private func chooseCustomModelFile() {
        let panel = NSOpenPanel()
        if let binType = UTType(filenameExtension: "bin") {
            panel.allowedContentTypes = [binType]
        }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Select a local Whisper GGML model file (.bin)"

        if panel.runModal() == .OK, let url = panel.url {
            customModelPath = url.path
            Task { @MainActor in
                transcriber.setCustomModelPath(url.path)
            }
        }
    }

    private func openSystemSettingsPane(_ paneURL: String) {
        guard let url = URL(string: paneURL) else { return }
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    SettingsView(transcriber: AudioTranscriber.shared, hotkeyMonitor: HotkeyMonitor())
}
