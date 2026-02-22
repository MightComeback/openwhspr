import Testing
import Foundation
@testable import OpenWhisper

@Suite("OnboardingView – permissionsGranted logic")
struct OnboardingViewPermissionsTests {

    @Test("all true returns true")
    func allTrue() {
        #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: true, inputMonitoring: true) == true)
    }

    @Test("all false returns false")
    func allFalse() {
        #expect(OnboardingView.permissionsGranted(microphone: false, accessibility: false, inputMonitoring: false) == false)
    }

    @Test("microphone false returns false")
    func micFalse() {
        #expect(OnboardingView.permissionsGranted(microphone: false, accessibility: true, inputMonitoring: true) == false)
    }

    @Test("accessibility false returns false")
    func accessFalse() {
        #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: false, inputMonitoring: true) == false)
    }

    @Test("inputMonitoring false returns false")
    func inputFalse() {
        #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: true, inputMonitoring: false) == false)
    }

    @Test("two false returns false")
    func twoFalse() {
        #expect(OnboardingView.permissionsGranted(microphone: false, accessibility: false, inputMonitoring: true) == false)
        #expect(OnboardingView.permissionsGranted(microphone: false, accessibility: true, inputMonitoring: false) == false)
        #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: false, inputMonitoring: false) == false)
    }

    @Test("exhaustive truth table has exactly 1 true combination")
    func exhaustive() {
        var trueCount = 0
        for m in [true, false] {
            for a in [true, false] {
                for i in [true, false] {
                    if OnboardingView.permissionsGranted(microphone: m, accessibility: a, inputMonitoring: i) {
                        trueCount += 1
                    }
                }
            }
        }
        #expect(trueCount == 1)
    }
}
