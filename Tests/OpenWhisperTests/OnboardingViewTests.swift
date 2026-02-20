import Testing
@testable import OpenWhisper

@Suite("OnboardingView")
struct OnboardingViewTests {
    @Test
    func permissionsGrantedWhenAllTrue() {
        #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: true, inputMonitoring: true))
    }

    @Test
    func permissionsGrantedWhenAnyMissing() {
        #expect(!OnboardingView.permissionsGranted(microphone: false, accessibility: true, inputMonitoring: true))
        #expect(!OnboardingView.permissionsGranted(microphone: true, accessibility: false, inputMonitoring: true))
        #expect(!OnboardingView.permissionsGranted(microphone: true, accessibility: true, inputMonitoring: false))
    }
}
