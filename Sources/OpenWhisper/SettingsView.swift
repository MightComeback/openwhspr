// SettingsView.swift
// OpenWhisper
//
// Full configuration window for hotkeys, output behavior, and permissions.
//

@preconcurrency import AVFoundation
@preconcurrency import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var transcriber: AudioTranscriber
    @ObservedObject var hotkeyMonitor: HotkeyMonitor

    @AppStorage(AppDefaults.Keys.onboardingCompleted) private var onboardingCompleted: Bool = false
    @AppStorage(AppDefaults.Keys.hotkeyMode) private var hotkeyModeRaw: String = HotkeyMode.toggle.rawValue
    @AppStorage(AppDefaults.Keys.hotkeyKey) private var hotkeyKey: String = "space"

    @State private var hotkeyKeyDraft: String = ""

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

    @AppStorage(AppDefaults.Keys.modelSource) private var modelSourceRaw: String = ModelSource.bundledTiny.rawValue
    @AppStorage(AppDefaults.Keys.modelCustomPath) private var customModelPath: String = ""

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
                        }

                        if showsHighRiskHotkeyWarning {
                            Label("This combo has no required modifiers, so it can trigger accidentally while typing.", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }

                        HStack(spacing: 10) {
                            Button("Preset: Toggle") {
                                applyHotkeyPreset(.toggle)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Button("Preset: Push to talk") {
                                applyHotkeyPreset(.hold)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

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
                            Spacer()
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
                                }
                                .onSubmit {
                                    applyHotkeyKeyDraft()
                                }

                            Button("Apply") {
                                applyHotkeyKeyDraft()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(!isHotkeyKeyDraftSupported)

                            Menu("Common keys") {
                                ForEach(commonHotkeyKeyOptions, id: \.self) { key in
                                    Button(HotkeyDisplay.displayKey(key)) {
                                        hotkeyKeyDraft = key
                                        applyHotkeyKeyDraft()
                                    }
                                }
                            }
                            .controlSize(.small)

                            Text("Examples: space/spacebar, tab, return/enter, esc, delete/backspace, forwarddelete, left/right/up/down, f1-f20, a, 1, minus, slash")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if !isHotkeyKeyDraftSupported {
                            Text("Unsupported key. Use a single character, named key, arrow, or F1-F20.")
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

                        Text("Tip: in hold-to-talk mode, recording starts on key down and ends on key up.")
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

                        Text("Profiles override global output behavior when that app is frontmost during finalization/copy/insert.")
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

                        Text("Current model: \(transcriber.activeModelDisplayName) (\(formatBytes(sizeOfModel(path: transcriber.activeModelPath))))")
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
            refreshPermissionState()
            Task { @MainActor in
                transcriber.refreshFrontmostAppContext()
            }
        }
        .onReceive(permissionTimer) { _ in
            refreshPermissionState()
            Task { @MainActor in
                transcriber.refreshFrontmostAppContext()
            }
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

    private var isHotkeyKeyDraftSupported: Bool {
        guard let key = normalizedHotkeyDraftForApply else {
            return false
        }
        return HotkeyDisplay.isSupportedKey(key)
    }

    private var commonHotkeyKeyOptions: [String] {
        [
            "space", "tab", "return", "esc", "delete",
            "left", "right", "up", "down",
            "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12"
        ]
    }

    private var showsAutoPastePermissionWarning: Bool {
        autoPaste && !accessibilityAuthorized
    }

    private var hasAnyRequiredModifier: Bool {
        requiredCommand || requiredShift || requiredOption || requiredControl || requiredCapsLock
    }

    private var showsHighRiskHotkeyWarning: Bool {
        guard !hasAnyRequiredModifier else {
            return false
        }

        let normalizedKey = sanitizeKeyValue(hotkeyKey)
        if normalizedKey.count == 1 {
            return true
        }

        switch normalizedKey {
        case "space", "tab", "return", "delete", "forwarddelete", "escape", "left", "right", "up", "down", "home", "end", "pageup", "pagedown":
            return true
        default:
            return false
        }
    }

    private func refreshPermissionState() {
        microphoneAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        accessibilityAuthorized = HotkeyMonitor.hasAccessibilityPermission()
        inputMonitoringAuthorized = HotkeyMonitor.hasInputMonitoringPermission()
    }

    private func applyHotkeyKeyDraft() {
        guard let normalized = normalizedHotkeyDraftForApply else {
            return
        }

        let sanitized = sanitizeKeyValue(normalized)
        hotkeyKeyDraft = sanitized
        guard HotkeyDisplay.isSupportedKey(sanitized) else {
            return
        }
        hotkeyKey = sanitized
    }

    private func resetHotkeyDefaults() {
        applyHotkeyPreset(.toggle)
    }

    private func applyHotkeyPreset(_ mode: HotkeyMode) {
        hotkeyModeRaw = mode.rawValue
        hotkeyKey = "space"
        hotkeyKeyDraft = "space"

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

    private var normalizedHotkeyDraftForApply: String? {
        let normalized = hotkeyKeyDraft
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !normalized.isEmpty else {
            return nil
        }

        if normalized == " " {
            return "space"
        }

        return normalized
    }

    private func sanitizeHotkeyDraftValue(_ raw: String) -> String {
        raw.lowercased()
    }

    private func sanitizeKeyValue(_ raw: String) -> String {
        let normalized = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if normalized.isEmpty { return "space" }
        if normalized == " " { return "space" }
        return HotkeyDisplay.canonicalKey(normalized)
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
