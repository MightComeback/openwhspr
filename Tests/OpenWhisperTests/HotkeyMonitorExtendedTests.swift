import Testing
import Foundation
import CoreGraphics
@testable import OpenWhisper

@Suite("HotkeyMonitor Extended")
struct HotkeyMonitorExtendedTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "HotkeyMonitorExtendedTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    // MARK: - setTranscriber

    @Test @MainActor
    func setTranscriberAssignsWeakReference() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        let transcriber = AudioTranscriber.shared
        monitor.setTranscriber(transcriber)
        #expect(monitor.transcriber === transcriber)
    }

    @Test @MainActor
    func setTranscriberCanBeCalledMultipleTimes() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        let transcriber = AudioTranscriber.shared
        monitor.setTranscriber(transcriber)
        monitor.setTranscriber(transcriber)
        #expect(monitor.transcriber === transcriber)
    }

    // MARK: - holdSessionArmedForTesting

    @Test
    func holdSessionArmedStartsFalse() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        #expect(!monitor.holdSessionArmedForTesting)
    }

    // MARK: - refreshStatusFromRuntimeState

    @Test
    func refreshStatusDoesNothingWhenNotListening() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        let originalMessage = monitor.statusMessage
        monitor.refreshStatusFromRuntimeState()
        #expect(monitor.statusMessage == originalMessage)
    }

    // MARK: - resumeIfPossible

    @Test
    func resumeIfPossibleDoesNotCrashWhenNotListening() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.resumeIfPossible()
    }

    // MARK: - init with various configs

    @Test
    func initWithoutListeningDoesNotActivate() {
        let defaults = makeDefaults()
        defaults.set("f5", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.hold.rawValue, forKey: AppDefaults.Keys.hotkeyMode)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        #expect(!monitor.isHotkeyActive)
    }

    @Test
    func initWithHoldMode() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.hold.rawValue, forKey: AppDefaults.Keys.hotkeyMode)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        #expect(monitor != nil)
    }

    @Test
    func initWithToggleMode() {
        let defaults = makeDefaults()
        defaults.set("return", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        #expect(monitor != nil)
    }

    // MARK: - reloadConfig with various keys

    @Test
    func reloadConfigWithFunctionKey() {
        let defaults = makeDefaults()
        defaults.set("f12", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(!monitor.statusMessage.isEmpty)
    }

    @Test
    func reloadConfigWithArrowKey() {
        let defaults = makeDefaults()
        defaults.set("up", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(!monitor.statusMessage.isEmpty)
    }

    @Test
    func reloadConfigWithKeypadKey() {
        let defaults = makeDefaults()
        defaults.set("keypad5", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(!monitor.statusMessage.isEmpty)
    }

    @Test
    func reloadConfigWithInvalidKey() {
        let defaults = makeDefaults()
        defaults.set("notavalidkeyname123", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(!monitor.statusMessage.isEmpty)
    }

    @Test
    func reloadConfigWithEmptyKey() {
        let defaults = makeDefaults()
        defaults.set("", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(!monitor.statusMessage.isEmpty)
    }

    // MARK: - stop when not started

    @Test
    func stopWhenNotListeningDoesNotCrash() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.stop()
        #expect(!monitor.isHotkeyActive)
    }

    @Test
    func doubleStopDoesNotCrash() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.stop()
        monitor.stop()
        #expect(!monitor.isHotkeyActive)
    }

    // MARK: - updateConfig

    @Test
    func updateConfigChangesMode() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.updateConfig(required: CGEventFlags.maskCommand, forbidden: [], key: "tab", mode: HotkeyMode.hold)
        #expect(!monitor.statusMessage.isEmpty)
    }

    @Test
    func updateConfigWithAllModifiers() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        let required: CGEventFlags = [.maskCommand, .maskShift, .maskAlternate, .maskControl]
        monitor.updateConfig(required: required, forbidden: [], key: "a", mode: HotkeyMode.toggle)
        #expect(!monitor.statusMessage.isEmpty)
    }

    @Test
    func updateConfigWithForbiddenModifiers() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.updateConfig(required: CGEventFlags.maskCommand, forbidden: [CGEventFlags.maskAlternate, CGEventFlags.maskControl], key: "space", mode: HotkeyMode.toggle)
        #expect(!monitor.statusMessage.isEmpty)
    }

    // MARK: - hasAccessibilityPermission / hasInputMonitoringPermission

    @Test
    func hasAccessibilityPermissionReturnsBool() {
        let _ = HotkeyMonitor.hasAccessibilityPermission()
    }

    @Test
    func hasInputMonitoringPermissionReturnsBool() {
        let _ = HotkeyMonitor.hasInputMonitoringPermission()
    }

    // MARK: - temporaryStatusResetDelayNanosecondsForTesting

    @Test
    func temporaryResetDelayIsPositive() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        let delay = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: "Recording started")
        #expect(delay > 0, "All messages should have a positive reset delay")
    }

    @Test
    func temporaryResetDelayScalesWithMessageLength() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        let shortDelay = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: "Hi")
        let longDelay = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: "Recording discarded via Escape — press hotkey to start again")
        #expect(longDelay >= shortDelay)
    }

    @Test
    func temporaryResetDelayHasCap() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        let delay = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: String(repeating: "x", count: 500))
        #expect(delay <= 3_400_000_000)
    }

    // MARK: - Modifier configuration edge cases

    @Test
    func reloadConfigWithAllForbiddenModifiers() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenOption)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenControl)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenCapsLock)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        #expect(!monitor.statusMessage.isEmpty)
    }

    @Test
    func reloadConfigWithNoModifiers() {
        let defaults = makeDefaults()
        defaults.set("f5", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        #expect(!monitor.statusMessage.isEmpty)
    }

    @Test
    func reloadConfigWithCapsLockRequired() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        #expect(!monitor.statusMessage.isEmpty)
    }
}
