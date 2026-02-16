import Testing
@testable import OpenWhisper

@Suite("OnboardingView – extended coverage")
struct OnboardingViewExtendedTests {

    @Test("all permissions granted returns true")
    func allGranted() {
        #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: true, inputMonitoring: true) == true)
    }

    @Test("microphone missing returns false")
    func microphoneMissing() {
        #expect(OnboardingView.permissionsGranted(microphone: false, accessibility: true, inputMonitoring: true) == false)
    }

    @Test("accessibility missing returns false")
    func accessibilityMissing() {
        #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: false, inputMonitoring: true) == false)
    }

    @Test("input monitoring missing returns false")
    func inputMonitoringMissing() {
        #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: true, inputMonitoring: false) == false)
    }

    @Test("all permissions missing returns false")
    func allMissing() {
        #expect(OnboardingView.permissionsGranted(microphone: false, accessibility: false, inputMonitoring: false) == false)
    }

    @Test("two of three missing returns false")
    func twoMissing() {
        #expect(OnboardingView.permissionsGranted(microphone: false, accessibility: false, inputMonitoring: true) == false)
        #expect(OnboardingView.permissionsGranted(microphone: false, accessibility: true, inputMonitoring: false) == false)
        #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: false, inputMonitoring: false) == false)
    }

    @Test("all 8 boolean combinations")
    func allCombinations() {
        for mic in [false, true] {
            for acc in [false, true] {
                for inp in [false, true] {
                    let expected = mic && acc && inp
                    #expect(
                        OnboardingView.permissionsGranted(microphone: mic, accessibility: acc, inputMonitoring: inp) == expected,
                        "mic=\(mic) acc=\(acc) inp=\(inp) should be \(expected)"
                    )
                }
            }
        }
    }
}
