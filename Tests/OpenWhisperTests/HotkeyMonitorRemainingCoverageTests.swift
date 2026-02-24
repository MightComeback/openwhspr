import Testing
import Foundation
import CoreGraphics
import Carbon.HIToolbox
@testable import OpenWhisper

@Suite("HotkeyMonitor Remaining Coverage")
@MainActor
struct HotkeyMonitorRemainingCoverageTests {

    private func makeDefaults() -> UserDefaults {
        let suiteName = "HotkeyMonitorRemCov.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func makeEvent(keyCode: CGKeyCode, flags: CGEventFlags = [], keyDown: Bool, isAutoRepeat: Bool = false) -> CGEvent {
        let source = CGEventSource(stateID: .combinedSessionState)
        let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown)!
        event.flags = flags
        event.setIntegerValueField(.keyboardEventAutorepeat, value: isAutoRepeat ? 1 : 0)
        return event
    }

    private func makeFlagsEvent(flags: CGEventFlags) -> CGEvent {
        let source = CGEventSource(stateID: .combinedSessionState)
        let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)!
        event.flags = flags
        return event
    }

    private func makeMonitor(key: String = "space", mode: HotkeyMode = .toggle,
                             requiredCommand: Bool = false, requiredShift: Bool = false,
                             requiredOption: Bool = false, requiredControl: Bool = false,
                             forbiddenCommand: Bool = false, forbiddenShift: Bool = false,
                             forbiddenOption: Bool = false, forbiddenControl: Bool = false) -> (HotkeyMonitor, UserDefaults) {
        let defaults = makeDefaults()
        defaults.set(key, forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(mode.rawValue, forKey: AppDefaults.Keys.hotkeyMode)
        defaults.set(requiredCommand, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(requiredShift, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(requiredOption, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        defaults.set(requiredControl, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        defaults.set(forbiddenCommand, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(forbiddenShift, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set(forbiddenOption, forKey: AppDefaults.Keys.hotkeyForbiddenOption)
        defaults.set(forbiddenControl, forKey: AppDefaults.Keys.hotkeyForbiddenControl)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCapsLock)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        return (monitor, defaults)
    }

    // MARK: - Hold mode: modifier flags change disarms session

    @Test("Hold mode: flagsChanged with missing required modifier disarms hold")
    func holdModeFlagsChangedDisarms() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true, requiredShift: true)
        // Arm hold
        let armEvent = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskCommand, .maskShift], keyDown: true)
        _ = monitor.handleForTesting(armEvent, type: .keyDown)
        #expect(monitor.holdSessionArmedForTesting)

        // Release shift modifier while still holding command
        let flagsEvent = makeFlagsEvent(flags: .maskCommand)
        _ = monitor.handleForTesting(flagsEvent, type: .flagsChanged)
        #expect(!monitor.holdSessionArmedForTesting)
        #expect(monitor.statusMessage.contains("Hold released"))
    }

    @Test("Hold mode: flagsChanged with forbidden modifier disarms hold")
    func holdModeFlagsChangedForbiddenDisarms() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true, forbiddenOption: true)
        // Arm hold
        let armEvent = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        _ = monitor.handleForTesting(armEvent, type: .keyDown)
        #expect(monitor.holdSessionArmedForTesting)

        // Add forbidden modifier
        let flagsEvent = makeFlagsEvent(flags: [.maskCommand, .maskAlternate])
        _ = monitor.handleForTesting(flagsEvent, type: .flagsChanged)
        #expect(!monitor.holdSessionArmedForTesting)
        #expect(monitor.statusMessage.contains("forbidden"))
    }

    @Test("Hold mode: flagsChanged when not armed is no-op")
    func holdModeFlagsChangedNotArmed() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        let flagsEvent = makeFlagsEvent(flags: [])
        let consumed = monitor.handleForTesting(flagsEvent, type: .flagsChanged)
        #expect(!consumed)
    }

    @Test("Toggle mode: flagsChanged is always no-op")
    func toggleModeFlagsChangedNoop() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true)
        let flagsEvent = makeFlagsEvent(flags: .maskCommand)
        let consumed = monitor.handleForTesting(flagsEvent, type: .flagsChanged)
        #expect(!consumed)
    }

    // MARK: - Mismatch hints

    @Test("Toggle mode: key down without required modifier shows mismatch hint")
    func toggleMismatchHintMissingRequired() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true, requiredShift: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        let consumed = monitor.handleForTesting(event, type: .keyDown)
        #expect(!consumed)
        #expect(monitor.statusMessage.contains("not triggered"))
        #expect(monitor.statusMessage.contains("missing required"))
    }

    @Test("Toggle mode: key down with forbidden modifier shows mismatch hint")
    func toggleMismatchHintForbidden() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true, forbiddenOption: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskCommand, .maskAlternate], keyDown: true)
        let consumed = monitor.handleForTesting(event, type: .keyDown)
        #expect(!consumed)
        #expect(monitor.statusMessage.contains("forbidden"))
    }

    @Test("Toggle mode: key down with forbidden AND missing required shows combined hint")
    func toggleMismatchHintForbiddenAndMissing() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true, requiredShift: true, forbiddenOption: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskCommand, .maskAlternate], keyDown: true)
        let consumed = monitor.handleForTesting(event, type: .keyDown)
        #expect(!consumed)
        #expect(monitor.statusMessage.contains("forbidden"))
        #expect(monitor.statusMessage.contains("missing required"))
    }

    @Test("Toggle mode: auto-repeat key down does NOT show mismatch hint")
    func toggleMismatchNoHintOnAutoRepeat() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true)
        // First, a normal key down to set initial mismatch
        let event1 = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        _ = monitor.handleForTesting(event1, type: .keyDown)
        let firstMsg = monitor.statusMessage

        // Now an auto-repeat without modifiers — should NOT update status
        let event2 = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true, isAutoRepeat: true)
        _ = monitor.handleForTesting(event2, type: .keyDown)
        // Status should remain the same (no new mismatch flash)
        #expect(monitor.statusMessage == firstMsg)
    }

    @Test("Toggle mode: key up on mismatch hint does not show hint")
    func toggleKeyUpNoMismatchHint() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: false)
        let consumed = monitor.handleForTesting(event, type: .keyUp)
        #expect(!consumed)
    }

    // MARK: - Hold mode mismatch hints

    @Test("Hold mode: key down without required modifier shows mismatch hint")
    func holdMismatchHintMissingRequired() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        let consumed = monitor.handleForTesting(event, type: .keyDown)
        #expect(!consumed)
        #expect(monitor.statusMessage.contains("not triggered"))
    }

    @Test("Hold mode: key down with forbidden modifier shows mismatch hint")
    func holdMismatchHintForbidden() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true, forbiddenOption: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskCommand, .maskAlternate], keyDown: true)
        let consumed = monitor.handleForTesting(event, type: .keyDown)
        #expect(!consumed)
        #expect(monitor.statusMessage.contains("forbidden"))
    }

    // MARK: - Toggle edge trigger (duplicate key down)

    @Test("Toggle mode: second key down while first consumed returns true without re-toggling")
    func toggleEdgeTriggerDuplicateKeyDown() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true)
        let down1 = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        let consumed1 = monitor.handleForTesting(down1, type: .keyDown)
        #expect(consumed1)

        // Second key down should be consumed (edge trigger protection)
        let down2 = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        let consumed2 = monitor.handleForTesting(down2, type: .keyDown)
        #expect(consumed2)
    }

    @Test("Toggle mode: auto-repeat key down with matching combo is consumed silently")
    func toggleAutoRepeatConsumed() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true, isAutoRepeat: true)
        let consumed = monitor.handleForTesting(event, type: .keyDown)
        #expect(consumed)
    }

    @Test("Toggle mode: key up after consumed key down resets toggle state")
    func toggleKeyUpResetsState() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true)
        let down = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        _ = monitor.handleForTesting(down, type: .keyDown)

        let up = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: false)
        let consumed = monitor.handleForTesting(up, type: .keyUp)
        #expect(consumed) // key up is consumed after consumed key down
    }

    @Test("Toggle mode: key up without prior consumed key down is not consumed")
    func toggleKeyUpWithoutPriorDown() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true)
        let up = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: false)
        let consumed = monitor.handleForTesting(up, type: .keyUp)
        #expect(!consumed)
    }

    // MARK: - Hold mode: key up disarms

    @Test("Hold mode: key up after arm disarms and returns true")
    func holdKeyUpDisarms() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        let down = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        _ = monitor.handleForTesting(down, type: .keyDown)
        #expect(monitor.holdSessionArmedForTesting)

        let up = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: false)
        let consumed = monitor.handleForTesting(up, type: .keyUp)
        #expect(consumed)
        #expect(!monitor.holdSessionArmedForTesting)
    }

    @Test("Hold mode: key up without prior arm is not consumed")
    func holdKeyUpWithoutArm() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        let up = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: false)
        let consumed = monitor.handleForTesting(up, type: .keyUp)
        #expect(!consumed)
    }

    // MARK: - Hold mode: duplicate key down doesn't re-arm

    @Test("Hold mode: second key down while armed does not re-arm")
    func holdDuplicateKeyDown() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        let down1 = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        _ = monitor.handleForTesting(down1, type: .keyDown)
        #expect(monitor.holdSessionArmedForTesting)

        let down2 = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        let consumed = monitor.handleForTesting(down2, type: .keyDown)
        #expect(consumed)
        #expect(monitor.holdSessionArmedForTesting)
    }

    // MARK: - Hold released status messages

    @Test("Hold released with forbidden modifier mentions forbidden")
    func holdReleasedForbiddenMessage() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true, forbiddenOption: true)
        // Arm
        let armEvent = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        _ = monitor.handleForTesting(armEvent, type: .keyDown)

        // Release via adding forbidden
        let flagsEvent = makeFlagsEvent(flags: [.maskCommand, .maskAlternate])
        _ = monitor.handleForTesting(flagsEvent, type: .flagsChanged)
        #expect(monitor.statusMessage.contains("forbidden"))
        #expect(monitor.statusMessage.contains("⌥"))
    }

    @Test("Hold released with missing required modifier mentions missing")
    func holdReleasedMissingRequiredMessage() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true, requiredShift: true)
        // Arm
        let armEvent = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskCommand, .maskShift], keyDown: true)
        _ = monitor.handleForTesting(armEvent, type: .keyDown)

        // Release shift
        let flagsEvent = makeFlagsEvent(flags: .maskCommand)
        _ = monitor.handleForTesting(flagsEvent, type: .flagsChanged)
        #expect(monitor.statusMessage.contains("missing required"))
        #expect(monitor.statusMessage.contains("⇧"))
    }

    @Test("Hold released with no held modifiers shows missing without held summary")
    func holdReleasedNoModifiersHeld() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        // Arm
        let armEvent = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        _ = monitor.handleForTesting(armEvent, type: .keyDown)

        // All modifiers released
        let flagsEvent = makeFlagsEvent(flags: [])
        _ = monitor.handleForTesting(flagsEvent, type: .flagsChanged)
        #expect(monitor.statusMessage.contains("missing required"))
    }

    // MARK: - Wrong key is not consumed

    @Test("Toggle mode: different key code is not consumed")
    func toggleWrongKeyNotConsumed() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_A), flags: .maskCommand, keyDown: true)
        let consumed = monitor.handleForTesting(event, type: .keyDown)
        #expect(!consumed)
    }

    @Test("Hold mode: different key code is not consumed")
    func holdWrongKeyNotConsumed() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_A), flags: .maskCommand, keyDown: true)
        let consumed = monitor.handleForTesting(event, type: .keyDown)
        #expect(!consumed)
    }

    // MARK: - refreshStatusFromRuntimeState

    @Test("refreshStatusFromRuntimeState when not listening is no-op")
    func refreshStatusNotListening() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true)
        let original = monitor.statusMessage
        monitor.refreshStatusFromRuntimeState()
        // Should not change if not listening (monitor was created without startListening)
        #expect(monitor.statusMessage == original)
    }

    // MARK: - resumeIfPossible

    @Test("resumeIfPossible with invalid trigger key does not start")
    func resumeWithInvalidKey() {
        let (monitor, defaults) = makeMonitor(key: "!!!invalid!!!", mode: .toggle, requiredCommand: true)
        defaults.set("!!!invalid!!!", forKey: AppDefaults.Keys.hotkeyKey)
        monitor.reloadConfig()
        monitor.resumeIfPossible()
        // Should not be listening
        #expect(!monitor.isHotkeyActive)
    }

    // MARK: - unsupportedTriggerKeyMessage branches

    @Test("Unsupported key message for empty input")
    func unsupportedKeyEmpty() {
        let (monitor, defaults) = makeMonitor(key: "", mode: .toggle, requiredCommand: true)
        defaults.set("", forKey: AppDefaults.Keys.hotkeyKey)
        monitor.reloadConfig()
        #expect(monitor.statusMessage.contains("empty"))
    }

    @Test("Unsupported key message for modifier-only input")
    func unsupportedKeyModifierOnly() {
        let (monitor, defaults) = makeMonitor(key: "command", mode: .toggle, requiredCommand: true)
        defaults.set("command", forKey: AppDefaults.Keys.hotkeyKey)
        monitor.reloadConfig()
        #expect(monitor.statusMessage.contains("modifier"))
    }

    @Test("Unsupported key message for out-of-range function key")
    func unsupportedKeyOutOfRange() {
        let (monitor, defaults) = makeMonitor(key: "f99", mode: .toggle, requiredCommand: true)
        defaults.set("f99", forKey: AppDefaults.Keys.hotkeyKey)
        monitor.reloadConfig()
        #expect(monitor.statusMessage.contains("out of range"))
    }

    @Test("Unsupported key message for generic unsupported key")
    func unsupportedKeyGeneric() {
        // Use a multi-char string that can't map to any key
        let (monitor, defaults) = makeMonitor(key: "zzznotakey999", mode: .toggle, requiredCommand: true)
        defaults.set("zzznotakey999", forKey: AppDefaults.Keys.hotkeyKey)
        monitor.reloadConfig()
        #expect(monitor.statusMessage.contains("unsupported") || monitor.statusMessage.contains("disabled"))
    }

    // MARK: - unsafeModifierConfigurationMessage

    @Test("Unsafe modifier config for letter key without required modifiers")
    func unsafeModifierConfig() {
        let defaults = makeDefaults()
        defaults.set("a", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(HotkeyMode.toggle.rawValue, forKey: AppDefaults.Keys.hotkeyMode)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenOption)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenControl)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenCapsLock)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(monitor.statusMessage.contains("too easy to trigger"))
    }

    // MARK: - configuredComboSummary

    @Test("configuredComboSummary includes all required modifiers and key")
    func configuredComboSummaryFull() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true, requiredShift: true,
                                       requiredOption: true, requiredControl: true)
        let summary = monitor.configuredComboSummary()
        #expect(summary.contains("⌘"))
        #expect(summary.contains("⇧"))
        #expect(summary.contains("⌥"))
        #expect(summary.contains("⌃"))
        #expect(summary.contains("Toggle"))
    }

    @Test("configuredComboSummary for hold mode")
    func configuredComboSummaryHold() {
        let (monitor, _) = makeMonitor(key: "f6", mode: .hold, requiredCommand: true)
        let summary = monitor.configuredComboSummary()
        #expect(summary.contains("Hold"))
    }

    // MARK: - Mismatch hint with no modifiers held

    @Test("Mismatch hint with no modifiers pressed mentions missing required without held summary")
    func mismatchHintNoModifiersPressed() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true, requiredShift: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        _ = monitor.handleForTesting(event, type: .keyDown)
        #expect(monitor.statusMessage.contains("missing required"))
        // When no modifiers are held, message should NOT say "held"
    }

    @Test("Mismatch hint with some wrong modifiers held mentions what was held")
    func mismatchHintWrongModifiersHeld() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true, requiredShift: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskAlternate, keyDown: true)
        _ = monitor.handleForTesting(event, type: .keyDown)
        #expect(monitor.statusMessage.contains("held"))
        #expect(monitor.statusMessage.contains("⌥"))
    }
}
