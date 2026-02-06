@preconcurrency import AVFoundation
@preconcurrency import AppKit
import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var transcriber: AudioTranscriber

    @AppStorage(AppDefaults.Keys.onboardingCompleted) private var onboardingCompleted: Bool = false

    @State private var microphoneAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    @State private var accessibilityAuthorized = HotkeyMonitor.hasAccessibilityPermission()
    @State private var inputMonitoringAuthorized = HotkeyMonitor.hasInputMonitoringPermission()

    private let permissionTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    private var allPermissionsGranted: Bool {
        Self.permissionsGranted(
            microphone: microphoneAuthorized,
            accessibility: accessibilityAuthorized,
            inputMonitoring: inputMonitoringAuthorized
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome to OpenWhisper")
                        .font(.title)
                        .fontWeight(.semibold)
                    Text("Local-first dictation for macOS.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.red)
            }

            GroupBox("Setup checklist") {
                VStack(alignment: .leading, spacing: 12) {
                    permissionRow(
                        title: "Microphone",
                        detail: "Required to capture dictation audio.",
                        granted: microphoneAuthorized,
                        actionTitle: "Request",
                        action: {
                            Task { @MainActor in
                                transcriber.requestMicrophonePermission()
                            }
                        },
                        settingsPane: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
                    )

                    Divider()

                    permissionRow(
                        title: "Accessibility",
                        detail: "Required for global hotkeys and auto-paste.",
                        granted: accessibilityAuthorized,
                        actionTitle: "Request",
                        action: {
                            HotkeyMonitor.requestAccessibilityPermissionPrompt()
                        },
                        settingsPane: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                    )

                    Divider()

                    permissionRow(
                        title: "Input Monitoring",
                        detail: "Required for reliable global key event capture.",
                        granted: inputMonitoringAuthorized,
                        actionTitle: "Request",
                        action: {
                            HotkeyMonitor.requestInputMonitoringPermissionPrompt()
                        },
                        settingsPane: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
                    )
                }
                .padding(.top, 4)
            }

            GroupBox("Quick start") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("1. Press your global hotkey (default: ⌘+⇧+Space).")
                    Text("2. Speak naturally; OpenWhisper transcribes locally.")
                    Text("3. Release/stop and insert or copy the text.")
                }
                .font(.subheadline)
                .padding(.top, 4)
            }

            HStack {
                if allPermissionsGranted {
                    Label("All required permissions are granted.", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                } else {
                    Label("Complete permissions for best reliability.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                }

                Spacer()

                Button("Request Missing") {
                    requestMissingPermissions()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Divider()

            HStack {
                Button("Remind Me Later") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(allPermissionsGranted ? "Finish Setup" : "Finish Anyway") {
                    onboardingCompleted = true
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
        .frame(width: 620)
        .onAppear {
            refreshPermissionState()
        }
        .onReceive(permissionTimer) { _ in
            refreshPermissionState()
        }
    }

    @ViewBuilder
    private func permissionRow(
        title: String,
        detail: String,
        granted: Bool,
        actionTitle: String,
        action: @escaping () -> Void,
        settingsPane: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: granted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(granted ? .green : .secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(granted ? "Granted" : "Missing")
                    .font(.caption)
                    .foregroundStyle(granted ? .green : .orange)
                HStack(spacing: 8) {
                    Button(actionTitle, action: action)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(granted)
                    Button("Open Settings") {
                        openSystemSettingsPane(settingsPane)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    private func requestMissingPermissions() {
        if !microphoneAuthorized {
            Task { @MainActor in
                transcriber.requestMicrophonePermission()
            }
        }
        if !accessibilityAuthorized {
            HotkeyMonitor.requestAccessibilityPermissionPrompt()
        }
        if !inputMonitoringAuthorized {
            HotkeyMonitor.requestInputMonitoringPermissionPrompt()
        }
    }

    private func refreshPermissionState() {
        microphoneAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        accessibilityAuthorized = HotkeyMonitor.hasAccessibilityPermission()
        inputMonitoringAuthorized = HotkeyMonitor.hasInputMonitoringPermission()
    }

    private func openSystemSettingsPane(_ paneURL: String) {
        guard let url = URL(string: paneURL) else { return }
        NSWorkspace.shared.open(url)
    }

    nonisolated static func permissionsGranted(microphone: Bool, accessibility: Bool, inputMonitoring: Bool) -> Bool {
        microphone && accessibility && inputMonitoring
    }
}

#Preview {
    OnboardingView(transcriber: AudioTranscriber.shared)
}
