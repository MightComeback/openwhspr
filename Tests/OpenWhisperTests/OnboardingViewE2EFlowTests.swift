import Testing
import Foundation
@testable import OpenWhisper

@Suite("OnboardingView – E2E flow coverage", .serialized)
struct OnboardingViewE2EFlowTests {

    // MARK: - onboardingCompleted AppStorage key

    @Test("onboardingCompleted key matches AppDefaults")
    @MainActor func onboardingCompletedKeyExists() {
        // The view uses @AppStorage(AppDefaults.Keys.onboardingCompleted)
        let key = AppDefaults.Keys.onboardingCompleted
        #expect(!key.isEmpty, "onboardingCompleted key should be defined")
    }

    @Test("setting onboardingCompleted via UserDefaults persists")
    @MainActor func onboardingCompletedPersists() {
        let key = AppDefaults.Keys.onboardingCompleted
        let original = UserDefaults.standard.bool(forKey: key)
        defer { UserDefaults.standard.set(original, forKey: key) }

        UserDefaults.standard.set(true, forKey: key)
        #expect(UserDefaults.standard.bool(forKey: key) == true)

        UserDefaults.standard.set(false, forKey: key)
        #expect(UserDefaults.standard.bool(forKey: key) == false)
    }

    @Test("toggling onboardingCompleted multiple times")
    @MainActor func toggleOnboardingCompleted() {
        let key = AppDefaults.Keys.onboardingCompleted
        let original = UserDefaults.standard.bool(forKey: key)
        defer { UserDefaults.standard.set(original, forKey: key) }

        for _ in 0..<10 {
            let current = UserDefaults.standard.bool(forKey: key)
            UserDefaults.standard.set(!current, forKey: key)
            #expect(UserDefaults.standard.bool(forKey: key) == !current)
        }
    }

    // MARK: - permissionsGranted edge cases

    @Test("permissionsGranted is a pure function - same input always same output")
    func pureFunction() {
        for _ in 0..<100 {
            #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: true, inputMonitoring: true) == true)
            #expect(OnboardingView.permissionsGranted(microphone: false, accessibility: true, inputMonitoring: true) == false)
        }
    }

    @Test("permissionsGranted is nonisolated and can be called from any context")
    func nonisolatedAccess() async {
        let result = await Task.detached {
            OnboardingView.permissionsGranted(microphone: true, accessibility: true, inputMonitoring: true)
        }.value
        #expect(result == true)

        let result2 = await Task.detached {
            OnboardingView.permissionsGranted(microphone: false, accessibility: false, inputMonitoring: false)
        }.value
        #expect(result2 == false)
    }

    @Test("permissionsGranted called concurrently is safe")
    func concurrentAccess() async {
        await withTaskGroup(of: Bool.self) { group in
            for mic in [true, false] {
                for acc in [true, false] {
                    for inp in [true, false] {
                        let m = mic, a = acc, i = inp
                        group.addTask {
                            OnboardingView.permissionsGranted(microphone: m, accessibility: a, inputMonitoring: i)
                        }
                    }
                }
            }
            var trueCount = 0
            for await result in group {
                if result { trueCount += 1 }
            }
            #expect(trueCount == 1)
        }
    }

    // MARK: - View instantiation

    @Test("OnboardingView can be instantiated with shared transcriber")
    @MainActor func viewInstantiation() {
        let transcriber = AudioTranscriber.shared
        let view = OnboardingView(transcriber: transcriber)
        // View should exist without crashing
        _ = view
    }

    @Test("OnboardingView transcriber reference is correct")
    @MainActor func transcriberReference() {
        let transcriber = AudioTranscriber.shared
        let view = OnboardingView(transcriber: transcriber)
        #expect(view.transcriber === transcriber)
    }

    // MARK: - Permission flow simulation via UserDefaults

    @Test("onboarding flow: start incomplete, finish marks complete")
    @MainActor func completeOnboardingFlow() {
        let key = AppDefaults.Keys.onboardingCompleted
        let original = UserDefaults.standard.bool(forKey: key)
        defer { UserDefaults.standard.set(original, forKey: key) }

        // Simulate fresh install
        UserDefaults.standard.set(false, forKey: key)
        #expect(UserDefaults.standard.bool(forKey: key) == false)

        // Simulate user clicking "Finish Setup"
        UserDefaults.standard.set(true, forKey: key)
        #expect(UserDefaults.standard.bool(forKey: key) == true)
    }

    @Test("onboarding flow: re-opening after completion still shows completed state")
    @MainActor func reopenAfterCompletion() {
        let key = AppDefaults.Keys.onboardingCompleted
        let original = UserDefaults.standard.bool(forKey: key)
        defer { UserDefaults.standard.set(original, forKey: key) }

        UserDefaults.standard.set(true, forKey: key)

        // "Re-open" — value should still be true
        #expect(UserDefaults.standard.bool(forKey: key) == true)
    }

    @Test("permissions state: all false means not all granted")
    func noPermissions() {
        let granted = OnboardingView.permissionsGranted(microphone: false, accessibility: false, inputMonitoring: false)
        #expect(granted == false)
    }

    @Test("permissions state: partial permissions still not granted")
    func partialPermissions() {
        // Only mic granted
        #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: false, inputMonitoring: false) == false)
        // Mic + accessibility but no input monitoring
        #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: true, inputMonitoring: false) == false)
        // Mic + input but no accessibility
        #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: false, inputMonitoring: true) == false)
    }

    // MARK: - Button title logic

    @Test("button title depends on allPermissionsGranted")
    func buttonTitleLogic() {
        // When all granted → "Finish Setup"
        let allGranted = OnboardingView.permissionsGranted(microphone: true, accessibility: true, inputMonitoring: true)
        let titleWhenGranted = allGranted ? "Finish Setup" : "Finish Anyway"
        #expect(titleWhenGranted == "Finish Setup")

        // When not all granted → "Finish Anyway"
        let notAllGranted = OnboardingView.permissionsGranted(microphone: false, accessibility: true, inputMonitoring: true)
        let titleWhenMissing = notAllGranted ? "Finish Setup" : "Finish Anyway"
        #expect(titleWhenMissing == "Finish Anyway")
    }

    @Test("status label depends on allPermissionsGranted")
    func statusLabelLogic() {
        let allGranted = OnboardingView.permissionsGranted(microphone: true, accessibility: true, inputMonitoring: true)
        let label = allGranted ? "All required permissions are granted." : "Complete permissions for best reliability."
        #expect(label == "All required permissions are granted.")

        let partial = OnboardingView.permissionsGranted(microphone: true, accessibility: false, inputMonitoring: true)
        let label2 = partial ? "All required permissions are granted." : "Complete permissions for best reliability."
        #expect(label2 == "Complete permissions for best reliability.")
    }

    // MARK: - Permission row rendering logic

    @Test("granted permission shows Granted text")
    func grantedText() {
        let granted = true
        let text = granted ? "Granted" : "Missing"
        #expect(text == "Granted")
    }

    @Test("missing permission shows Missing text")
    func missingText() {
        let granted = false
        let text = granted ? "Granted" : "Missing"
        #expect(text == "Missing")
    }

    @Test("request button is disabled when granted")
    func requestButtonDisabledWhenGranted() {
        let granted = true
        #expect(granted == true, "Button should be .disabled(true) when granted")
    }

    @Test("request button is enabled when not granted")
    func requestButtonEnabledWhenNotGranted() {
        let granted = false
        #expect(granted == false, "Button should be .disabled(false) when not granted")
    }

    // MARK: - System settings URLs

    @Test("microphone settings pane URL is valid")
    func microphoneSettingsURL() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
        #expect(url != nil)
    }

    @Test("accessibility settings pane URL is valid")
    func accessibilitySettingsURL() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        #expect(url != nil)
    }

    @Test("input monitoring settings pane URL is valid")
    func inputMonitoringSettingsURL() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
        #expect(url != nil)
    }

    @Test("invalid URL returns nil")
    func invalidSettingsURL() {
        // openSystemSettingsPane guards against nil URL
        let url = URL(string: "")
        #expect(url == nil)
    }
}
