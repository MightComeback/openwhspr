import XCTest
import Carbon.HIToolbox
@testable import OpenWhisper

final class HotkeyMonitorTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "HotkeyMonitorTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        addTeardownBlock {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
        return defaults
    }

    private func makeEvent(keyCode: CGKeyCode, flags: CGEventFlags, keyDown: Bool, isAutoRepeat: Bool = false) -> CGEvent {
        let source = CGEventSource(stateID: .combinedSessionState)
        let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown)!
        event.flags = flags
        event.setIntegerValueField(.keyboardEventAutorepeat, value: isAutoRepeat ? 1 : 0)
        return event
    }

    func testConfigLoadsRequiredAndForbiddenModifiers() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskCommand], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testModifierMatchingBlocksForbidden() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenControl)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskCommand, .maskControl], keyDown: true)
        XCTAssertFalse(monitor.handleForTesting(event, type: .keyDown))
    }

    func testToggleModeKeyDownHandled() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testToggleModeConsumesAutoRepeatWithoutRetoggling() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let repeatEvent = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true, isAutoRepeat: true)
        XCTAssertTrue(monitor.handleForTesting(repeatEvent, type: .keyDown))
    }

    func testSpacebarAliasMatchesSpaceKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("spacebar", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testToggleModeKeyUpNotHandled() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: false)
        XCTAssertFalse(monitor.handleForTesting(event, type: .keyUp))
    }

    func testFunctionKeyHotkeyMatchesConfiguredFKey() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("f6", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_F6), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testNavigationKeyAliasMatchesPageDownKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("pgdn", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_PageDown), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testHoldModeArmsAndDisarms() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.hold.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let downEvent = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(downEvent, type: .keyDown))
        XCTAssertTrue(monitor.holdSessionArmedForTesting)

        let upEvent = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: false)
        XCTAssertTrue(monitor.handleForTesting(upEvent, type: .keyUp))
        XCTAssertFalse(monitor.holdSessionArmedForTesting)
    }

    func testHoldModeIgnoresNonMatchingKey() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.hold.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_A), flags: [], keyDown: true)
        XCTAssertFalse(monitor.handleForTesting(event, type: .keyDown))
        XCTAssertFalse(monitor.holdSessionArmedForTesting)
    }
}
