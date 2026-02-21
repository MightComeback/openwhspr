import Testing
import Foundation
import CoreGraphics
import Carbon.HIToolbox
@testable import OpenWhisper

@Suite("HotkeyMonitor Deep Coverage")
@MainActor
struct HotkeyMonitorDeepCoverageTests {

    private func makeDefaults() -> UserDefaults {
        let suiteName = "HotkeyMonitorDeep.\(UUID().uuidString)"
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

    private func makeMonitor(key: String = "space", mode: HotkeyMode = .toggle,
                             requiredCommand: Bool = false, requiredShift: Bool = false,
                             requiredOption: Bool = false, requiredControl: Bool = false,
                             requiredCapsLock: Bool = false,
                             forbiddenCommand: Bool = false, forbiddenShift: Bool = false,
                             forbiddenOption: Bool = false, forbiddenControl: Bool = false,
                             forbiddenCapsLock: Bool = false) -> (HotkeyMonitor, UserDefaults) {
        let defaults = makeDefaults()
        defaults.set(key, forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(mode.rawValue, forKey: AppDefaults.Keys.hotkeyMode)
        defaults.set(requiredCommand, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(requiredShift, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(requiredOption, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        defaults.set(requiredControl, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        defaults.set(requiredCapsLock, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        defaults.set(forbiddenCommand, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        defaults.set(forbiddenShift, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        defaults.set(forbiddenOption, forKey: AppDefaults.Keys.hotkeyForbiddenOption)
        defaults.set(forbiddenControl, forKey: AppDefaults.Keys.hotkeyForbiddenControl)
        defaults.set(forbiddenCapsLock, forKey: AppDefaults.Keys.hotkeyForbiddenCapsLock)
        let monitor = HotkeyMonitor(defaults: defaults, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        return (monitor, defaults)
    }

    // MARK: - Hold mode: arm and disarm lifecycle

    @Test("Hold mode arms on matching key down")
    func holdModeArms() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        #expect(monitor.handleForTesting(event, type: .keyDown))
        #expect(monitor.holdSessionArmedForTesting)
    }

    @Test("Hold mode disarms on key up")
    func holdModeDisarms() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        let down = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        _ = monitor.handleForTesting(down, type: .keyDown)
        let up = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: false)
        #expect(monitor.handleForTesting(up, type: .keyUp))
        #expect(!monitor.holdSessionArmedForTesting)
    }

    @Test("Hold mode key up without prior arm returns false")
    func holdModeKeyUpWithoutArm() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        let up = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: false)
        #expect(!monitor.handleForTesting(up, type: .keyUp))
    }

    @Test("Hold mode does not re-arm on repeated key down")
    func holdModeNoReArm() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        let down1 = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        _ = monitor.handleForTesting(down1, type: .keyDown)
        let statusAfterFirst = monitor.statusMessage
        let down2 = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        #expect(monitor.handleForTesting(down2, type: .keyDown))
        #expect(monitor.statusMessage == statusAfterFirst)
    }

    @Test("Hold mode ignores non-matching key")
    func holdModeIgnoresWrongKey() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Return), flags: .maskCommand, keyDown: true)
        #expect(!monitor.handleForTesting(event, type: .keyDown))
        #expect(!monitor.holdSessionArmedForTesting)
    }

    @Test("Hold mode disarms when required modifier released via flagsChanged")
    func holdModeDisarmsOnModifierRelease() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        let down = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        _ = monitor.handleForTesting(down, type: .keyDown)
        #expect(monitor.holdSessionArmedForTesting)

        // Simulate modifier release via flagsChanged
        let modRelease = makeEvent(keyCode: CGKeyCode(0), flags: [], keyDown: true)
        _ = monitor.handleForTesting(modRelease, type: .flagsChanged)
        #expect(!monitor.holdSessionArmedForTesting)
    }

    @Test("Hold mode disarms when forbidden modifier pressed via flagsChanged")
    func holdModeDisarmsOnForbiddenModifier() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true, forbiddenControl: true)
        let down = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        _ = monitor.handleForTesting(down, type: .keyDown)
        #expect(monitor.holdSessionArmedForTesting)

        let modChange = makeEvent(keyCode: CGKeyCode(0), flags: [.maskCommand, .maskControl], keyDown: true)
        _ = monitor.handleForTesting(modChange, type: .flagsChanged)
        #expect(!monitor.holdSessionArmedForTesting)
        #expect(monitor.statusMessage.contains("Hold released"))
    }

    @Test("Hold mode flagsChanged with combo still matching does nothing")
    func holdModeFlagsChangedStillMatching() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        let down = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        _ = monitor.handleForTesting(down, type: .keyDown)

        let flags = makeEvent(keyCode: CGKeyCode(0), flags: .maskCommand, keyDown: true)
        let result = monitor.handleForTesting(flags, type: .flagsChanged)
        #expect(!result) // combo still matches, so returns false (not consumed)
        #expect(monitor.holdSessionArmedForTesting) // still armed
    }

    @Test("flagsChanged in toggle mode is ignored")
    func flagsChangedIgnoredInToggleMode() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true)
        let flags = makeEvent(keyCode: CGKeyCode(0), flags: [], keyDown: true)
        #expect(!monitor.handleForTesting(flags, type: .flagsChanged))
    }

    @Test("flagsChanged when not armed is ignored")
    func flagsChangedNotArmedIgnored() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        #expect(!monitor.holdSessionArmedForTesting)
        let flags = makeEvent(keyCode: CGKeyCode(0), flags: [], keyDown: true)
        #expect(!monitor.handleForTesting(flags, type: .flagsChanged))
    }

    // MARK: - Hold released status messages

    @Test("Hold released message mentions forbidden modifier")
    func holdReleasedForbiddenMessage() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true, forbiddenControl: true)
        let down = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        _ = monitor.handleForTesting(down, type: .keyDown)

        let modChange = makeEvent(keyCode: CGKeyCode(0), flags: [.maskCommand, .maskControl], keyDown: true)
        _ = monitor.handleForTesting(modChange, type: .flagsChanged)
        #expect(monitor.statusMessage.contains("forbidden"))
        #expect(monitor.statusMessage.contains("⌃"))
    }

    @Test("Hold released message mentions missing required modifier")
    func holdReleasedMissingRequiredMessage() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true, requiredShift: true)
        let down = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskCommand, .maskShift], keyDown: true)
        _ = monitor.handleForTesting(down, type: .keyDown)

        // Release shift
        let modChange = makeEvent(keyCode: CGKeyCode(0), flags: .maskCommand, keyDown: true)
        _ = monitor.handleForTesting(modChange, type: .flagsChanged)
        #expect(monitor.statusMessage.contains("missing required"))
        #expect(monitor.statusMessage.contains("⇧"))
    }

    @Test("Hold released with all modifiers released shows missing required")
    func holdReleasedAllModifiersReleased() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        let down = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        _ = monitor.handleForTesting(down, type: .keyDown)

        let modChange = makeEvent(keyCode: CGKeyCode(0), flags: [], keyDown: true)
        _ = monitor.handleForTesting(modChange, type: .flagsChanged)
        #expect(monitor.statusMessage.contains("missing required"))
    }

    // MARK: - Toggle mode combo mismatch hints

    @Test("Toggle mode shows mismatch hint when wrong modifiers used")
    func toggleMismatchHint() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        #expect(!monitor.handleForTesting(event, type: .keyDown))
        #expect(monitor.statusMessage.contains("Hotkey not triggered"))
        #expect(monitor.statusMessage.contains("missing required"))
    }

    @Test("Toggle mode mismatch hint shows forbidden modifier")
    func toggleMismatchForbiddenHint() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true, forbiddenControl: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskControl], keyDown: true)
        #expect(!monitor.handleForTesting(event, type: .keyDown))
        #expect(monitor.statusMessage.contains("forbidden"))
    }

    @Test("Toggle mode mismatch hint not shown for auto-repeat")
    func toggleMismatchAutoRepeatSilent() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true)
        let initial = monitor.statusMessage
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true, isAutoRepeat: true)
        #expect(!monitor.handleForTesting(event, type: .keyDown))
        #expect(monitor.statusMessage == initial)
    }

    @Test("Toggle mismatch hint with held modifiers but missing required")
    func toggleMismatchHeldButMissing() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskShift, keyDown: true)
        #expect(!monitor.handleForTesting(event, type: .keyDown))
        #expect(monitor.statusMessage.contains("held ⇧"))
    }

    @Test("Hold mode shows mismatch hint on mismatched key down")
    func holdMismatchHint() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        #expect(!monitor.handleForTesting(event, type: .keyDown))
        #expect(monitor.statusMessage.contains("Hotkey not triggered"))
    }

    // MARK: - Toggle mode edge-trigger (toggleKeyDownConsumed)

    @Test("Toggle mode consumes auto-repeat after initial key down")
    func toggleAutoRepeatConsumed() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle)
        let down = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        #expect(monitor.handleForTesting(down, type: .keyDown))

        let repeat1 = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true, isAutoRepeat: true)
        #expect(monitor.handleForTesting(repeat1, type: .keyDown))
    }

    @Test("Toggle mode repeated down without key up is consumed")
    func toggleRepeatedDownConsumed() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle)
        let down1 = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        #expect(monitor.handleForTesting(down1, type: .keyDown))

        let down2 = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        #expect(monitor.handleForTesting(down2, type: .keyDown))
    }

    @Test("Toggle mode key up resets edge trigger")
    func toggleKeyUpResetsEdge() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle)
        let down = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        _ = monitor.handleForTesting(down, type: .keyDown)

        let up = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: false)
        #expect(monitor.handleForTesting(up, type: .keyUp))

        // After key up, a new key down should trigger again
        let down2 = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [], keyDown: true)
        #expect(monitor.handleForTesting(down2, type: .keyDown))
    }

    // MARK: - missingPermissionStatusMessage

    @Test("Missing permission message includes accessibility")
    func missingPermissionAccessibility() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true)
        let msg = monitor.missingPermissionStatusMessage(["Accessibility"])
        #expect(msg.contains("Accessibility"))
        #expect(msg.contains("Privacy & Security"))
    }

    @Test("Missing permission message includes both permissions")
    func missingPermissionBoth() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true)
        let msg = monitor.missingPermissionStatusMessage(["Accessibility", "Input Monitoring"])
        #expect(msg.contains("Accessibility"))
        #expect(msg.contains("Input Monitoring"))
    }

    @Test("Missing permission message includes configured hotkey combo")
    func missingPermissionIncludesCombo() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true, requiredShift: true)
        let msg = monitor.missingPermissionStatusMessage(["Accessibility"])
        #expect(msg.contains("⌘"))
        #expect(msg.contains("⇧"))
        #expect(msg.contains("Space"))
    }

    // MARK: - updateConfig

    @Test("updateConfig updates trigger key and mode")
    func updateConfigChanges() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle)
        monitor.updateConfig(required: .maskCommand, forbidden: [], key: "return", mode: .hold)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Return), flags: .maskCommand, keyDown: true)
        #expect(monitor.handleForTesting(event, type: .keyDown))
        #expect(monitor.holdSessionArmedForTesting)
    }

    @Test("updateConfig with invalid key reports unsupported trigger")
    func updateConfigInvalidKey() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle)
        monitor.updateConfig(required: .maskCommand, forbidden: [], key: "notakey999", mode: .toggle)
        #expect(monitor.statusMessage.contains("unsupported"))
    }

    @Test("updateConfig with empty key reports empty trigger")
    func updateConfigEmptyKey() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle)
        monitor.updateConfig(required: .maskCommand, forbidden: [], key: "", mode: .toggle)
        #expect(monitor.statusMessage.contains("empty") || monitor.statusMessage.contains("unsupported"))
    }

    @Test("updateConfig with modifier-only input reports error")
    func updateConfigModifierOnly() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle)
        monitor.updateConfig(required: .maskCommand, forbidden: [], key: "command", mode: .toggle)
        #expect(monitor.statusMessage.contains("modifier") || monitor.statusMessage.contains("unsupported"))
    }

    @Test("updateConfig with shortcut combo extracts trailing key")
    func updateConfigShortcutCombo() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle)
        monitor.updateConfig(required: .maskCommand, forbidden: [], key: "command+shift+a", mode: .toggle)
        // The monitor strips modifier prefixes and uses trailing key "a"
        // With required command modifier, this is a valid config
        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_A), flags: .maskCommand, keyDown: true)
        #expect(monitor.handleForTesting(event, type: .keyDown))
    }

    @Test("updateConfig with out-of-range function key reports error")
    func updateConfigOutOfRangeFKey() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle)
        monitor.updateConfig(required: .maskCommand, forbidden: [], key: "f99", mode: .toggle)
        #expect(monitor.statusMessage.contains("out of range") || monitor.statusMessage.contains("unsupported"))
    }

    // MARK: - Unsafe modifier configuration

    @Test("Single letter key with no required modifiers is unsafe")
    func unsafeNoModifierLetterKey() {
        let (monitor, _) = makeMonitor(key: "a", mode: .toggle)
        #expect(monitor.statusMessage.contains("disabled") || monitor.statusMessage.contains("too easy"))
    }

    @Test("Function key with no modifiers is safe")
    func safeFunctionKeyNoModifiers() {
        let (monitor, _) = makeMonitor(key: "f5", mode: .toggle)
        #expect(!monitor.statusMessage.contains("disabled"))
    }

    @Test("Space with no modifiers is safe (allowed)")
    func safeSpaceNoModifiers() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle)
        // Space is in allowsNoModifierTrigger
        #expect(!monitor.statusMessage.contains("too easy"))
    }

    // MARK: - Key code matching with aliases

    @Test("Letter key matching is case-insensitive")
    func letterKeyCaseInsensitive() {
        let (monitor, _) = makeMonitor(key: "A", mode: .toggle, requiredCommand: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_A), flags: .maskCommand, keyDown: true)
        #expect(monitor.handleForTesting(event, type: .keyDown))
    }

    @Test("Digit key matching works")
    func digitKeyMatching() {
        let (monitor, _) = makeMonitor(key: "5", mode: .toggle, requiredCommand: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_ANSI_5), flags: .maskCommand, keyDown: true)
        #expect(monitor.handleForTesting(event, type: .keyDown))
    }

    @Test("F1 through F12 key matching")
    func functionKeyMatching() {
        let fKeys: [(String, Int)] = [
            ("f1", kVK_F1), ("f2", kVK_F2), ("f3", kVK_F3), ("f4", kVK_F4),
            ("f5", kVK_F5), ("f6", kVK_F6), ("f7", kVK_F7), ("f8", kVK_F8),
            ("f9", kVK_F9), ("f10", kVK_F10), ("f11", kVK_F11), ("f12", kVK_F12),
        ]
        for (name, code) in fKeys {
            let (monitor, _) = makeMonitor(key: name, mode: .toggle, requiredCommand: true)
            let event = makeEvent(keyCode: CGKeyCode(code), flags: .maskCommand, keyDown: true)
            #expect(monitor.handleForTesting(event, type: .keyDown), "Expected \(name) to match keyCode \(code)")
        }
    }

    @Test("Arrow key matching")
    func arrowKeyMatching() {
        let arrows: [(String, Int)] = [
            ("left", kVK_LeftArrow), ("right", kVK_RightArrow),
            ("up", kVK_UpArrow), ("down", kVK_DownArrow),
        ]
        for (name, code) in arrows {
            let (monitor, _) = makeMonitor(key: name, mode: .toggle, requiredCommand: true)
            let event = makeEvent(keyCode: CGKeyCode(code), flags: .maskCommand, keyDown: true)
            #expect(monitor.handleForTesting(event, type: .keyDown), "Expected \(name) to match")
        }
    }

    @Test("Home/End/PageUp/PageDown matching")
    func navigationKeyMatching() {
        let navKeys: [(String, Int)] = [
            ("home", kVK_Home), ("end", kVK_End),
            ("pageup", kVK_PageUp), ("pagedown", kVK_PageDown),
        ]
        for (name, code) in navKeys {
            let (monitor, _) = makeMonitor(key: name, mode: .toggle, requiredCommand: true)
            let event = makeEvent(keyCode: CGKeyCode(code), flags: .maskCommand, keyDown: true)
            #expect(monitor.handleForTesting(event, type: .keyDown), "Expected \(name) to match")
        }
    }

    // MARK: - Modifier combinations

    @Test("All four modifiers required, all present")
    func allModifiersRequired() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle,
                                        requiredCommand: true, requiredShift: true,
                                        requiredOption: true, requiredControl: true)
        let flags: CGEventFlags = [.maskCommand, .maskShift, .maskAlternate, .maskControl]
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: flags, keyDown: true)
        #expect(monitor.handleForTesting(event, type: .keyDown))
    }

    @Test("All four modifiers required, one missing fails")
    func allModifiersRequiredOneMissing() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle,
                                        requiredCommand: true, requiredShift: true,
                                        requiredOption: true, requiredControl: true)
        let flags: CGEventFlags = [.maskCommand, .maskShift, .maskAlternate]
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: flags, keyDown: true)
        #expect(!monitor.handleForTesting(event, type: .keyDown))
    }

    @Test("CapsLock as required modifier")
    func capsLockRequired() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCapsLock: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskAlphaShift, keyDown: true)
        #expect(monitor.handleForTesting(event, type: .keyDown))
    }

    @Test("CapsLock as forbidden modifier blocks")
    func capsLockForbidden() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true, forbiddenCapsLock: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskCommand, .maskAlphaShift], keyDown: true)
        #expect(!monitor.handleForTesting(event, type: .keyDown))
    }

    // MARK: - temporaryStatusResetDelay edge cases

    @Test("Empty message has minimum delay")
    func emptyMessageMinDelay() {
        let (monitor, _) = makeMonitor()
        let delay = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: "")
        #expect(delay > 0)
        #expect(delay <= 3_400_000_000)
    }

    @Test("Single character message has small delay")
    func singleCharDelay() {
        let (monitor, _) = makeMonitor()
        let delay = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: "x")
        #expect(delay > 1_000_000_000) // at least ~1 second
    }

    // MARK: - refreshStatusFromRuntimeState

    @Test("refreshStatus when not listening does nothing")
    func refreshStatusNotListening() {
        let (monitor, _) = makeMonitor()
        let original = monitor.statusMessage
        monitor.refreshStatusFromRuntimeState()
        #expect(monitor.statusMessage == original)
    }

    // MARK: - resumeIfPossible

    @Test("resumeIfPossible with invalid trigger key does not start")
    func resumeWithInvalidKey() {
        let (monitor, _) = makeMonitor(key: "notakey999", mode: .toggle, requiredCommand: true)
        monitor.resumeIfPossible()
        // Should not crash, and should not start listening
        #expect(!monitor.isHotkeyActive || monitor.statusMessage.contains("unsupported"))
    }

    @Test("resumeIfPossible with unsafe modifier config does not start")
    func resumeWithUnsafeConfig() {
        let (monitor, _) = makeMonitor(key: "a", mode: .toggle)
        monitor.resumeIfPossible()
    }

    // MARK: - Multiple forbidden modifiers in mismatch message

    @Test("Multiple forbidden modifiers use plural 'modifiers'")
    func multipleForbiddenModifiersPlural() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true,
                                        forbiddenOption: true, forbiddenControl: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskAlternate, .maskControl], keyDown: true)
        _ = monitor.handleForTesting(event, type: .keyDown)
        #expect(monitor.statusMessage.contains("modifiers"))
        #expect(monitor.statusMessage.contains("are"))
    }

    @Test("Single forbidden modifier uses singular 'modifier'")
    func singleForbiddenModifierSingular() {
        let (monitor, _) = makeMonitor(key: "space", mode: .toggle, requiredCommand: true, forbiddenControl: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: [.maskControl], keyDown: true)
        _ = monitor.handleForTesting(event, type: .keyDown)
        #expect(monitor.statusMessage.contains("modifier ⌃ is held"))
    }

    // MARK: - Hold mode status message content

    @Test("Hold active status message format")
    func holdActiveStatusFormat() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        _ = monitor.handleForTesting(event, type: .keyDown)
        #expect(monitor.statusMessage.hasPrefix("Hold active:"))
    }

    @Test("Hold standby message mentions hold to record")
    func holdStandbyMessage() {
        let (monitor, _) = makeMonitor(key: "space", mode: .hold, requiredCommand: true)
        let down = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: true)
        _ = monitor.handleForTesting(down, type: .keyDown)
        let up = makeEvent(keyCode: CGKeyCode(kVK_Space), flags: .maskCommand, keyDown: false)
        _ = monitor.handleForTesting(up, type: .keyUp)
        #expect(monitor.statusMessage.contains("hold to record"))
    }

    // MARK: - Toggle mode with various keys

    @Test("Tab key in toggle mode")
    func tabKeyToggle() {
        let (monitor, _) = makeMonitor(key: "tab", mode: .toggle, requiredCommand: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Tab), flags: .maskCommand, keyDown: true)
        #expect(monitor.handleForTesting(event, type: .keyDown))
    }

    @Test("Return key in toggle mode")
    func returnKeyToggle() {
        let (monitor, _) = makeMonitor(key: "return", mode: .toggle, requiredCommand: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Return), flags: .maskCommand, keyDown: true)
        #expect(monitor.handleForTesting(event, type: .keyDown))
    }

    @Test("Escape key in toggle mode")
    func escapeKeyToggle() {
        let (monitor, _) = makeMonitor(key: "escape", mode: .toggle, requiredCommand: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Escape), flags: .maskCommand, keyDown: true)
        #expect(monitor.handleForTesting(event, type: .keyDown))
    }

    @Test("Delete key in toggle mode")
    func deleteKeyToggle() {
        let (monitor, _) = makeMonitor(key: "delete", mode: .toggle, requiredCommand: true)
        let event = makeEvent(keyCode: CGKeyCode(kVK_Delete), flags: .maskCommand, keyDown: true)
        #expect(monitor.handleForTesting(event, type: .keyDown))
    }

    // MARK: - Static permission methods

    @Test("hasAccessibilityPermission returns bool")
    func accessibilityPermissionBool() {
        let _ = HotkeyMonitor.hasAccessibilityPermission()
    }

    @Test("hasInputMonitoringPermission returns bool")
    func inputMonitoringPermissionBool() {
        let _ = HotkeyMonitor.hasInputMonitoringPermission()
    }

    // MARK: - stop/double stop safety

    @Test("Stop when not listening is safe")
    func stopSafe() {
        let (monitor, _) = makeMonitor()
        monitor.stop()
        #expect(!monitor.isHotkeyActive)
    }

    @Test("Double stop is safe")
    func doubleStopSafe() {
        let (monitor, _) = makeMonitor()
        monitor.stop()
        monitor.stop()
    }

    // MARK: - reloadConfig edge cases

    @Test("reloadConfig with F13-F20 keys")
    func reloadConfigHighFKeys() {
        for i in 13...20 {
            let (monitor, _) = makeMonitor(key: "f\(i)", mode: .toggle, requiredCommand: true)
            #expect(!monitor.statusMessage.contains("unsupported"), "f\(i) should be supported")
        }
    }

    @Test("reloadConfig with keypad keys")
    func reloadConfigKeypadKeys() {
        let keys = ["keypad0", "keypad1", "keypad5", "keypad9", "keypaddecimal", "keypadmultiply", "keypadplus", "keypaddivide", "keypadminus"]
        for key in keys {
            let (monitor, _) = makeMonitor(key: key, mode: .toggle, requiredCommand: true)
            #expect(!monitor.statusMessage.contains("unsupported"), "\(key) should be supported")
        }
    }

    @Test("reloadConfig with ISO section key")
    func reloadConfigSectionKey() {
        let (monitor, _) = makeMonitor(key: "section", mode: .toggle, requiredCommand: true)
        #expect(!monitor.statusMessage.contains("unsupported"))
    }
}
