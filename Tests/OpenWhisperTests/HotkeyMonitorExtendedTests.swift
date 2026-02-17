import XCTest
@testable import OpenWhisper

final class HotkeyMonitorExtendedTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "HotkeyMonitorExtendedTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        addTeardownBlock {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
        return defaults
    }

    // MARK: - setTranscriber

    @MainActor
    func testSetTranscriberAssignsWeakReference() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        let transcriber = AudioTranscriber.shared
        monitor.setTranscriber(transcriber)
        XCTAssertTrue(monitor.transcriber === transcriber)
    }

    @MainActor
    func testSetTranscriberCanBeCalledMultipleTimes() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        let transcriber = AudioTranscriber.shared
        monitor.setTranscriber(transcriber)
        monitor.setTranscriber(transcriber)
        XCTAssertTrue(monitor.transcriber === transcriber)
    }

    // MARK: - holdSessionArmedForTesting

    func testHoldSessionArmedStartsFalse() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        XCTAssertFalse(monitor.holdSessionArmedForTesting)
    }

    // MARK: - refreshStatusFromRuntimeState

    func testRefreshStatusDoesNothingWhenNotListening() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        let originalMessage = monitor.statusMessage
        monitor.refreshStatusFromRuntimeState()
        // Status should not change when not listening
        XCTAssertEqual(monitor.statusMessage, originalMessage)
    }

    // MARK: - resumeIfPossible

    func testResumeIfPossibleDoesNotCrashWhenNotListening() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        // Should not crash — may or may not actually start depending on permissions
        monitor.resumeIfPossible()
    }

    // MARK: - init with various configs

    func testInitWithoutListeningDoesNotActivate() {
        let defaults = makeDefaults()
        defaults.set("f5", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.hold.rawValue, forKey: AppDefaults.Keys.hotkeyMode)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        // Not listening, so not active
        XCTAssertFalse(monitor.isHotkeyActive)
    }

    func testInitWithHoldMode() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.hold.rawValue, forKey: AppDefaults.Keys.hotkeyMode)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        XCTAssertNotNil(monitor)
    }

    func testInitWithToggleMode() {
        let defaults = makeDefaults()
        defaults.set("return", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        XCTAssertNotNil(monitor)
    }

    // MARK: - reloadConfig with various keys

    func testReloadConfigWithFunctionKey() {
        let defaults = makeDefaults()
        defaults.set("f12", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        // Should not crash and status should contain something
        XCTAssertFalse(monitor.statusMessage.isEmpty)
    }

    func testReloadConfigWithArrowKey() {
        let defaults = makeDefaults()
        defaults.set("up", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        XCTAssertFalse(monitor.statusMessage.isEmpty)
    }

    func testReloadConfigWithKeypadKey() {
        let defaults = makeDefaults()
        defaults.set("keypad5", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        XCTAssertFalse(monitor.statusMessage.isEmpty)
    }

    func testReloadConfigWithInvalidKey() {
        let defaults = makeDefaults()
        defaults.set("notavalidkeyname123", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        // Should gracefully handle invalid key
        XCTAssertFalse(monitor.statusMessage.isEmpty)
    }

    func testReloadConfigWithEmptyKey() {
        let defaults = makeDefaults()
        defaults.set("", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        XCTAssertFalse(monitor.statusMessage.isEmpty)
    }

    // MARK: - stop when not started

    func testStopWhenNotListeningDoesNotCrash() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.stop()
        // Should not crash
        XCTAssertFalse(monitor.isHotkeyActive)
    }

    func testDoubleStopDoesNotCrash() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.stop()
        monitor.stop()
        XCTAssertFalse(monitor.isHotkeyActive)
    }

    // MARK: - updateConfig

    func testUpdateConfigChangesMode() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.updateConfig(required: .maskCommand, forbidden: [], key: "tab", mode: .hold)
        // Should not crash
        XCTAssertFalse(monitor.statusMessage.isEmpty)
    }

    func testUpdateConfigWithAllModifiers() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        let required: CGEventFlags = [.maskCommand, .maskShift, .maskAlternate, .maskControl]
        monitor.updateConfig(required: required, forbidden: [], key: "a", mode: .toggle)
        XCTAssertFalse(monitor.statusMessage.isEmpty)
    }

    func testUpdateConfigWithForbiddenModifiers() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.updateConfig(required: .maskCommand, forbidden: [.maskAlternate, .maskControl], key: "space", mode: .toggle)
        XCTAssertFalse(monitor.statusMessage.isEmpty)
    }

    // MARK: - hasAccessibilityPermission / hasInputMonitoringPermission

    func testHasAccessibilityPermissionReturnsBool() {
        // Just verify it doesn't crash and returns a Bool
        let _ = HotkeyMonitor.hasAccessibilityPermission()
    }

    func testHasInputMonitoringPermissionReturnsBool() {
        let _ = HotkeyMonitor.hasInputMonitoringPermission()
    }

    // MARK: - temporaryStatusResetDelayNanosecondsForTesting

    func testTemporaryResetDelayIsPositive() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        let delay = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: "Recording started")
        XCTAssertGreaterThan(delay, 0, "All messages should have a positive reset delay")
    }

    func testTemporaryResetDelayScalesWithMessageLength() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        let shortDelay = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: "Hi")
        let longDelay = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: "Recording discarded via Escape — press hotkey to start again")
        XCTAssertGreaterThanOrEqual(longDelay, shortDelay)
    }

    func testTemporaryResetDelayHasCap() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        let delay = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: String(repeating: "x", count: 500))
        // Max is 3.4 seconds = 3_400_000_000 nanoseconds
        XCTAssertLessThanOrEqual(delay, 3_400_000_000)
    }

    // MARK: - Modifier configuration edge cases

    func testReloadConfigWithAllForbiddenModifiers() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenOption)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenControl)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenCapsLock)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        XCTAssertFalse(monitor.statusMessage.isEmpty)
    }

    func testReloadConfigWithNoModifiers() {
        let defaults = makeDefaults()
        defaults.set("f5", forKey: AppDefaults.Keys.hotkeyKey)
        // No required or forbidden modifiers
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        XCTAssertFalse(monitor.statusMessage.isEmpty)
    }

    func testReloadConfigWithCapsLockRequired() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        XCTAssertFalse(monitor.statusMessage.isEmpty)
    }
}
