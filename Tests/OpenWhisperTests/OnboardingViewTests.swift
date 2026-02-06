import XCTest
@testable import OpenWhisper

final class OnboardingViewTests: XCTestCase {
    func testPermissionsGrantedWhenAllTrue() {
        XCTAssertTrue(OnboardingView.permissionsGranted(microphone: true, accessibility: true, inputMonitoring: true))
    }

    func testPermissionsGrantedWhenAnyMissing() {
        XCTAssertFalse(OnboardingView.permissionsGranted(microphone: false, accessibility: true, inputMonitoring: true))
        XCTAssertFalse(OnboardingView.permissionsGranted(microphone: true, accessibility: false, inputMonitoring: true))
        XCTAssertFalse(OnboardingView.permissionsGranted(microphone: true, accessibility: true, inputMonitoring: false))
    }
}
