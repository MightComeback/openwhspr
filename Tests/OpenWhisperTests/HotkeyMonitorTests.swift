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

    func testComboMismatchMessageIncludesForbiddenAndMissingRequiredModifiers() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenControl)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskControl], keyDown: true)
        XCTAssertFalse(monitor.handleForTesting(event, type: .keyDown))
        XCTAssertEqual(
            monitor.statusMessage,
            "Hotkey not triggered: forbidden modifier ⌃ is held and missing required modifier ⌘. Use Toggle • ⌘+Space"
        )
    }

    func testComboMismatchMessageIncludesOnlyMissingRequiredModifiers() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenControl)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskShift, .maskControl], keyDown: true)
        XCTAssertFalse(monitor.handleForTesting(event, type: .keyDown))
        XCTAssertEqual(
            monitor.statusMessage,
            "Hotkey not triggered: forbidden modifier ⌃ is held and missing required modifier ⌘. Use Toggle • ⌘+⇧+Space"
        )
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

    func testToggleModeIgnoresRepeatedKeyDownUntilKeyUp() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let firstDown = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(firstDown, type: .keyDown))

        let repeatedDownWithoutKeyUp = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(repeatedDownWithoutKeyUp, type: .keyDown))

        let upEvent = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: false)
        XCTAssertTrue(monitor.handleForTesting(upEvent, type: .keyUp))
    }

    func testToggleModeAllowsImmediateSecondPressAfterKeyUp() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let firstDown = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(firstDown, type: .keyDown))

        let upEvent = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: false)
        XCTAssertTrue(monitor.handleForTesting(upEvent, type: .keyUp))

        let secondDown = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(secondDown, type: .keyDown))
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

    func testLiteralSpaceCharacterMatchesSpaceKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set(" ", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testSpaceSymbolAliasMatchesSpaceKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("⎵", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testDeleteAliasMatchesDeleteKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("del", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Delete), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testCapsLockAliasMatchesCapsLockKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("caps", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_CapsLock), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testForwardDeleteAliasWithSpacingMatchesForwardDeleteKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("fwd delete", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ForwardDelete), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testForwardDeleteSymbolAliasMatchesForwardDeleteKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("␡", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ForwardDelete), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testInsertAliasMatchesHelpKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("ins", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Help), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testTabSymbolAliasMatchesTabKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("⇥", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Tab), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testBackTabAliasMatchesTabKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("back tab", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Tab), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testReturnSymbolAliasMatchesReturnKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("⏎", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Return), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testReturnArrowAliasMatchesReturnKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("↵", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Return), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testEnterSymbolAliasMatchesReturnKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("⌅", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Return), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testEscapeControlPictureAliasMatchesEscapeKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("␛", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Escape), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testEnterKeyAliasWithSpaceMatchesReturnKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("enter key", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Return), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testEnterAliasAlsoMatchesKeypadEnterKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("enter", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_KeypadEnter), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testReturnSlashEnterAliasMatchesReturnKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("return/enter", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Return), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testFunctionKeyAliasMatchesFnKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("function", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Function), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testGlobeAliasMatchesFnKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("globe", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Function), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testFnGlobeWithSpaceAliasMatchesFnKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("fn globe", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Function), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testFnSlashGlobeAliasMatchesFnKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("fn/globe", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Function), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testSectionKeyAliasMatchesISOSectionKeyCode() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("section", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ISO_Section), flags: [.maskCommand], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testSectionSymbolAliasMatchesISOSectionKeyCode() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("§", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ISO_Section), flags: [.maskCommand], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testShortcutPasteWithGlobeModifierUsesTrailingKey() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("command+globe+space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testCompactShortcutPasteWithGlobeSymbolUsesTrailingKey() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("⌘🌐space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testShortcutPasteWithCtlModifierUsesTrailingKey() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("ctl+space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testCompactShortcutPasteWithReturnSymbolUsesTrailingReturnKey() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("⌘↩", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Return), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testCompactShortcutPasteWithDeleteSymbolUsesTrailingDeleteKey() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("⌘⌫", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Delete), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testShortcutPasteWithSlashTriggerUsesSlashKey() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("command+shift+/", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_Slash), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testCompactShortcutPasteWithSlashTriggerUsesSlashKey() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("⌘⇧/", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_Slash), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testToggleModeKeyUpConsumedAfterHandledKeyDown() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let downEvent = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(downEvent, type: .keyDown))

        let upEvent = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: false)
        XCTAssertTrue(monitor.handleForTesting(upEvent, type: .keyUp))
    }

    func testToggleModeKeyUpWithoutHandledKeyDownNotHandled() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let upEvent = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: false)
        XCTAssertFalse(monitor.handleForTesting(upEvent, type: .keyUp))
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

    func testFunctionNumberAliasMatchesConfiguredFKey() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("fn6", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_F6), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testFunctionWordNumberAliasMatchesConfiguredExtendedFKey() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("function24", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(0x71), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testExtendedFunctionKeyHotkeyMatchesConfiguredF24() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("f24", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(0x71), flags: [], keyDown: true)
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

    func testNavigationKeyAliasWithSpacesMatchesPageDownKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("page down", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_PageDown), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testNavigationSymbolAliasesMatchPageKeys() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("⇞", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let pageUpEvent = makeEvent(keyCode: CGKeyCode(kVK_PageUp), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(pageUpEvent, type: .keyDown))

        defaults.set("⇟", forKey: AppDefaults.Keys.hotkeyKey)
        monitor.reloadConfig()

        let pageDownEvent = makeEvent(keyCode: CGKeyCode(kVK_PageDown), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(pageDownEvent, type: .keyDown))
    }

    func testArrowWordAliasMatchesLeftArrowKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("left arrow", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_LeftArrow), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testNavigationAbbreviatedAliasWithSpaceMatchesPageDownKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("pg down", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_PageDown), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testPunctuationAliasMatchesMinusKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("minus", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_Minus), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testPunctuationLiteralMatchesSlashKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("/", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_Slash), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testEmDashLiteralAliasMatchesMinusKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("—", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_Minus), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testShiftedPunctuationLiteralMatchesUnderlyingKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("?", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_Slash), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testShiftedDigitSymbolLiteralMatchesUnderlyingNumberKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("!", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_1), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testTildeWordAliasMatchesBacktickKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("tilde", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_Grave), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testGraveAccentWordAliasMatchesBacktickKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("grave accent", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_Grave), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testNumpadAliasMatchesKeypad0KeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("numpad0", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_Keypad0), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testNumpadAliasWithSpacingMatchesKeypadPlusKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("num pad plus", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_KeypadPlus), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testNumpadEnterSymbolAliasMatchesKeypadEnterKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("⌤", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_KeypadEnter), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testNumpadCommaAliasMatchesJISKeypadCommaKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("num,", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_JIS_KeypadComma), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testNumpadEnterAliasAlsoMatchesMainReturnKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("numpadenter", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Return), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testNumpadSymbolAliasMatchesKeypadPlusKeyCode() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("num+", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_KeypadPlus), flags: [], keyDown: true)
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

    func testHoldModeDisarmsWhenRequiredModifierIsReleased() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.hold.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let downEvent = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskCommand], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(downEvent, type: .keyDown))
        XCTAssertTrue(monitor.holdSessionArmedForTesting)

        let modifierRelease = makeEvent(keyCode: CGKeyCode(kVK_Command), flags: [], keyDown: false)
        XCTAssertFalse(monitor.handleForTesting(modifierRelease, type: .flagsChanged))
        XCTAssertFalse(monitor.holdSessionArmedForTesting)
        XCTAssertTrue(monitor.statusMessage.contains("hold to record"))
    }

    func testModifierMismatchShowsComboGuidance() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        XCTAssertFalse(monitor.handleForTesting(event, type: .keyDown))
        XCTAssertEqual(monitor.statusMessage, "Hotkey not triggered: missing required modifier ⌘. Use Toggle • ⌘+Space")
    }

    func testModifierMismatchShowsHeldModifiersInGuidance() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskShift], keyDown: true)
        XCTAssertFalse(monitor.handleForTesting(event, type: .keyDown))
        XCTAssertEqual(monitor.statusMessage, "Hotkey not triggered: missing required modifier ⌘; held ⇧. Use Toggle • ⌘+Space")
    }

    func testModifierMismatchShowsForbiddenModifierGuidance() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskCommand, .maskShift], keyDown: true)
        XCTAssertFalse(monitor.handleForTesting(event, type: .keyDown))
        XCTAssertEqual(monitor.statusMessage, "Hotkey not triggered: forbidden modifier ⇧ is held. Use Toggle • ⌘+Space")
    }

    func testModifierMismatchShowsMultipleForbiddenModifiersGuidance() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenOption)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskCommand, .maskShift, .maskAlternate], keyDown: true)
        XCTAssertFalse(monitor.handleForTesting(event, type: .keyDown))
        XCTAssertEqual(monitor.statusMessage, "Hotkey not triggered: forbidden modifiers ⇧+⌥ are held. Use Toggle • ⌘+Space")
    }

    func testHoldModeUpdatesStatusMessageWhilePressed() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.hold.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()

        let downEvent = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(downEvent, type: .keyDown))
        XCTAssertTrue(monitor.statusMessage.hasPrefix("Hold active:"))

        let upEvent = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: false)
        XCTAssertTrue(monitor.handleForTesting(upEvent, type: .keyUp))
        XCTAssertTrue(monitor.statusMessage.hasPrefix("Hotkey active"))
        XCTAssertTrue(monitor.statusMessage.contains("hold to record"))
    }

    func testInvalidTriggerKeyDisablesHotkeyWithStatusMessage() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.updateConfig(required: [], forbidden: [], key: "invalid key name", mode: .toggle)

        XCTAssertFalse(monitor.isHotkeyActive)
        XCTAssertEqual(monitor.statusMessage, "Hotkey disabled: unsupported trigger key ‘invalid key name’. Use one key like space, f6, or /.")

        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        XCTAssertFalse(monitor.handleForTesting(event, type: .keyDown))
    }

    func testShortcutComboLikeInputShowsKeyFieldGuidance() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.updateConfig(required: [], forbidden: [], key: "cmd shift potato", mode: .toggle)

        XCTAssertEqual(
            monitor.statusMessage,
            "Hotkey disabled: key field expects one trigger key (like space or f6), not a full shortcut ‘cmd shift potato’. Set modifiers with the toggles above."
        )
    }

    func testEmptyTriggerKeyShowsSpecificGuidance() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.updateConfig(required: [], forbidden: [], key: "   ", mode: .toggle)

        XCTAssertEqual(
            monitor.statusMessage,
            "Hotkey disabled: trigger key is empty. Enter one key like space, f6, or /."
        )
    }

    func testModifierGlyphOnlyInputShowsModifierOnlyGuidance() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.updateConfig(required: [], forbidden: [], key: "⌘⇧", mode: .toggle)

        XCTAssertEqual(
            monitor.statusMessage,
            "Hotkey disabled: trigger key cannot be only a modifier ‘⌘⇧’. Choose one key like space or f6, then set modifiers with the toggles above."
        )
    }

    func testModifierWordOnlyInputShowsModifierOnlyGuidance() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.updateConfig(required: [], forbidden: [], key: "command", mode: .toggle)

        XCTAssertEqual(
            monitor.statusMessage,
            "Hotkey disabled: trigger key cannot be only a modifier ‘command’. Choose one key like space or f6, then set modifiers with the toggles above."
        )
    }

    func testSingleModifierGlyphInputShowsModifierOnlyGuidance() {
        let defaults = makeDefaults()
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)

        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.updateConfig(required: [], forbidden: [], key: "⌥", mode: .toggle)

        XCTAssertEqual(
            monitor.statusMessage,
            "Hotkey disabled: trigger key cannot be only a modifier ‘⌥’. Choose one key like space or f6, then set modifiers with the toggles above."
        )
    }

    func testUnsafeTypingTriggerWithoutModifiersShowsGuidance() {
        let defaults = makeDefaults()
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)

        monitor.updateConfig(required: [], forbidden: [], key: "a", mode: .toggle)

        XCTAssertEqual(
            monitor.statusMessage,
            "Hotkey disabled: trigger key A without required modifiers is too easy to trigger while typing. Add at least one required modifier."
        )
    }

    func testFunctionKeyTriggerWithoutModifiersRemainsUsable() {
        let defaults = makeDefaults()
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)

        monitor.updateConfig(required: [], forbidden: [], key: "f6", mode: .toggle)

        let event = makeEvent(keyCode: CGKeyCode(kVK_F6), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testFnKeyTriggerWithoutModifiersRemainsUsable() {
        let defaults = makeDefaults()
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)

        monitor.updateConfig(required: [], forbidden: [], key: "fn", mode: .toggle)

        let event = makeEvent(keyCode: CGKeyCode(kVK_Function), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testInsertTriggerWithoutModifiersRemainsUsable() {
        let defaults = makeDefaults()
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)

        monitor.updateConfig(required: [], forbidden: [], key: "insert", mode: .toggle)

        let event = makeEvent(keyCode: CGKeyCode(kVK_Help), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testDeleteTriggerWithoutModifiersRemainsUsable() {
        let defaults = makeDefaults()
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)

        monitor.updateConfig(required: [], forbidden: [], key: "delete", mode: .toggle)

        let event = makeEvent(keyCode: CGKeyCode(kVK_Delete), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testCapsLockTriggerWithoutModifiersRemainsUsable() {
        let defaults = makeDefaults()
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)

        monitor.updateConfig(required: [], forbidden: [], key: "caps lock", mode: .toggle)

        let event = makeEvent(keyCode: CGKeyCode(kVK_CapsLock), flags: [], keyDown: true)
        XCTAssertTrue(monitor.handleForTesting(event, type: .keyDown))
    }

    func testMissingSinglePermissionMessageIncludesSettingsPath() {
        let monitor = HotkeyMonitor(defaults: makeDefaults(), startListening: false, observeDefaults: false)

        XCTAssertEqual(
            monitor.missingPermissionStatusMessage(["Accessibility"]),
            "Hotkey disabled: missing Accessibility permission. Open System Settings → Privacy & Security → Accessibility and enable OpenWhisper."
        )
    }

    func testMissingMultiplePermissionsMessageIncludesBothSectionsGuidance() {
        let monitor = HotkeyMonitor(defaults: makeDefaults(), startListening: false, observeDefaults: false)

        XCTAssertEqual(
            monitor.missingPermissionStatusMessage(["Accessibility", "Input Monitoring"]),
            "Hotkey disabled: missing Accessibility and Input Monitoring permission. Open System Settings → Privacy & Security and enable OpenWhisper in both sections."
        )
    }
}

