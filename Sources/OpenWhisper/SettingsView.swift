// SettingsView.swift
// OpenWhisper
//
// Full configuration window for hotkeys, output behavior, and permissions.
//

@preconcurrency import AVFoundation
@preconcurrency import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var transcriber: AudioTranscriber
    @ObservedObject var hotkeyMonitor: HotkeyMonitor

    @AppStorage(AppDefaults.Keys.hotkeyMode) private var hotkeyModeRaw: String = HotkeyMode.toggle.rawValue
    @AppStorage(AppDefaults.Keys.hotkeyKey) private var hotkeyKey: String = "space"

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

    @AppStorage(AppDefaults.Keys.transcriptionReplacements) private var replacementsRaw: String = ""
    @AppStorage(AppDefaults.Keys.transcriptionHistoryLimit) private var historyLimit: Int = 25

    @State private var microphoneAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    @State private var accessibilityAuthorized = HotkeyMonitor.hasAccessibilityPermission()

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

                        HStack {
                            Text("Trigger key")
                                .frame(width: 110, alignment: .leading)
                            TextField("space", text: $hotkeyKey)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                                .onChange(of: hotkeyKey) { _, newValue in
                                    hotkeyKey = sanitizeKeyValue(newValue)
                                }
                            Text("Examples: space, tab, return, a, 1")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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

                GroupBox("Text cleanup") {
                    VStack(alignment: .leading, spacing: 8) {
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

                        Text("Format: `from => to` or `from = to`. Lines starting with `#` are ignored.")
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

                        HStack(spacing: 12) {
                            Button("Open Microphone Privacy") {
                                openSystemSettingsPane("x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
                            }
                            Button("Open Accessibility Privacy") {
                                openSystemSettingsPane("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
                            }
                        }
                        .buttonStyle(.link)
                        .font(.caption)
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

                        Text("Bundled model: ggml-tiny.bin (\(formatBytes(sizeOfModel())))")
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
            refreshPermissionState()
        }
        .onReceive(permissionTimer) { _ in
            refreshPermissionState()
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

    private func refreshPermissionState() {
        microphoneAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        accessibilityAuthorized = HotkeyMonitor.hasAccessibilityPermission()
    }

    private func sanitizeKeyValue(_ raw: String) -> String {
        let normalized = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return normalized.isEmpty ? "space" : normalized
    }

    private func hotkeySummary() -> String {
        var parts: [String] = []
        if requiredCommand { parts.append("⌘") }
        if requiredShift { parts.append("⇧") }
        if requiredOption { parts.append("⌥") }
        if requiredControl { parts.append("⌃") }
        if requiredCapsLock { parts.append("⇪") }
        parts.append(displayKey(hotkeyKey))
        return parts.joined(separator: "+")
    }

    private func displayKey(_ raw: String) -> String {
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

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func sizeOfModel() -> Int64 {
        guard let url = Bundle.module.url(forResource: "ggml-tiny", withExtension: "bin"),
              let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else {
            return 0
        }
        return size
    }

    private func openSystemSettingsPane(_ paneURL: String) {
        guard let url = URL(string: paneURL) else { return }
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    SettingsView(transcriber: AudioTranscriber.shared, hotkeyMonitor: HotkeyMonitor())
}
