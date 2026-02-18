import Testing
import Foundation
@testable import OpenWhisper

@Suite("ViewHelpers – Key-code & capture helpers")
struct ViewHelpersKeyCodeTests {

    // MARK: - isModifierOnlyKeyCode

    @Test("Modifier-only key codes return true")
    func modifierOnlyTrue() {
        let modifierCodes: [Int] = [0x37, 0x36, 0x38, 0x3C, 0x3A, 0x3D, 0x3B, 0x3E, 0x39, 0x3F]
        for code in modifierCodes {
            #expect(ViewHelpers.isModifierOnlyKeyCode(code) == true, "keyCode \(code) should be modifier-only")
        }
    }

    @Test("Non-modifier key codes return false")
    func modifierOnlyFalse() {
        let nonModifier: [Int] = [0x31, 0x30, 0x24, 0x35, 0x00, 0x01, 0x7A, 0x7B]
        for code in nonModifier {
            #expect(ViewHelpers.isModifierOnlyKeyCode(code) == false, "keyCode \(code) should not be modifier-only")
        }
    }

    // MARK: - hotkeyKeyNameForKeyCode

    @Test("Known special keys map correctly")
    func knownSpecialKeys() {
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x31) == "space")
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x30) == "tab")
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x24) == "return")
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x35) == "escape")
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x33) == "delete")
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x75) == "forwarddelete")
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x72) == "insert")
    }

    @Test("Arrow keys map correctly")
    func arrowKeys() {
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x7B) == "left")
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x7C) == "right")
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x7E) == "up")
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x7D) == "down")
    }

    @Test("Navigation keys map correctly")
    func navigationKeys() {
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x73) == "home")
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x77) == "end")
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x74) == "pageup")
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x79) == "pagedown")
    }

    @Test("Function keys F1-F12 map correctly")
    func functionKeysF1toF12() {
        let expected: [(Int, String)] = [
            (0x7A, "f1"), (0x78, "f2"), (0x63, "f3"), (0x76, "f4"),
            (0x60, "f5"), (0x61, "f6"), (0x62, "f7"), (0x64, "f8"),
            (0x65, "f9"), (0x6D, "f10"), (0x67, "f11"), (0x6F, "f12"),
        ]
        for (code, name) in expected {
            #expect(ViewHelpers.hotkeyKeyNameForKeyCode(code) == name, "keyCode \(code) should be \(name)")
        }
    }

    @Test("Function keys F13-F20 map correctly")
    func functionKeysF13toF20() {
        let expected: [(Int, String)] = [
            (0x69, "f13"), (0x6B, "f14"), (0x71, "f15"), (0x6A, "f16"),
            (0x40, "f17"), (0x4F, "f18"), (0x50, "f19"), (0x5A, "f20"),
        ]
        for (code, name) in expected {
            #expect(ViewHelpers.hotkeyKeyNameForKeyCode(code) == name, "keyCode \(code) should be \(name)")
        }
    }

    @Test("Function key returns fn")
    func functionKey() {
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x3F) == "fn")
    }

    @Test("Modifier keys return nil")
    func modifierKeysReturnNil() {
        let modifiers: [Int] = [0x37, 0x38, 0x3C, 0x3A, 0x3D, 0x3B, 0x3E, 0x39]
        for code in modifiers {
            #expect(ViewHelpers.hotkeyKeyNameForKeyCode(code) == nil, "modifier keyCode \(code) should return nil")
        }
    }

    @Test("Unknown key code returns nil")
    func unknownKeyCodeReturnsNil() {
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0xFF) == nil)
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x00) == nil)
    }

    // MARK: - hotkeySummaryFromModifiers

    @Test("Summary with command+shift and space")
    func summaryCommandShiftSpace() {
        let result = ViewHelpers.hotkeySummaryFromModifiers(
            command: true, shift: true, option: false, control: false, capsLock: false,
            key: "space"
        )
        #expect(result == "⌘+⇧+Space")
    }

    @Test("Summary with all modifiers")
    func summaryAllModifiers() {
        let result = ViewHelpers.hotkeySummaryFromModifiers(
            command: true, shift: true, option: true, control: true, capsLock: true,
            key: "f5"
        )
        #expect(result == "⌘+⇧+⌥+⌃+⇪+F5")
    }

    @Test("Summary with no modifiers")
    func summaryNoModifiers() {
        let result = ViewHelpers.hotkeySummaryFromModifiers(
            command: false, shift: false, option: false, control: false, capsLock: false,
            key: "escape"
        )
        #expect(result == "Esc")
    }

    @Test("Summary with single option modifier")
    func summarySingleOption() {
        let result = ViewHelpers.hotkeySummaryFromModifiers(
            command: false, shift: false, option: true, control: false, capsLock: false,
            key: "tab"
        )
        #expect(result == "⌥+Tab")
    }

    @Test("Summary with control only")
    func summaryControlOnly() {
        let result = ViewHelpers.hotkeySummaryFromModifiers(
            command: false, shift: false, option: false, control: true, capsLock: false,
            key: "return"
        )
        #expect(result == "⌃+Return/Enter")
    }

    @Test("Summary modifier order is always ⌘⇧⌥⌃⇪")
    func summaryModifierOrder() {
        let result = ViewHelpers.hotkeySummaryFromModifiers(
            command: true, shift: true, option: true, control: true, capsLock: true,
            key: "a"
        )
        #expect(result.hasPrefix("⌘+⇧+⌥+⌃+⇪"))
    }

    // MARK: - shouldIgnoreCaptureActivation

    @Test("Ignores Cmd+Shift+K within debounce window")
    func ignoresCmdShiftKWithinWindow() {
        let result = ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        )
        #expect(result == true)
    }

    @Test("Does not ignore after debounce window")
    func doesNotIgnoreAfterWindow() {
        let result = ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.5,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        )
        #expect(result == false)
    }

    @Test("Does not ignore different key")
    func doesNotIgnoreDifferentKey() {
        let result = ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "j",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        )
        #expect(result == false)
    }

    @Test("Does not ignore nil key")
    func doesNotIgnoreNilKey() {
        let result = ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: nil,
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        )
        #expect(result == false)
    }

    @Test("Does not ignore without command modifier")
    func doesNotIgnoreWithoutCommand() {
        let result = ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "k",
            hasCommandModifier: false,
            hasShiftModifier: true,
            hasExtraModifiers: false
        )
        #expect(result == false)
    }

    @Test("Does not ignore without shift modifier")
    func doesNotIgnoreWithoutShift() {
        let result = ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: false,
            hasExtraModifiers: false
        )
        #expect(result == false)
    }

    @Test("Does not ignore with extra modifiers")
    func doesNotIgnoreWithExtraModifiers() {
        let result = ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: true
        )
        #expect(result == false)
    }

    @Test("Exactly at debounce threshold still ignores")
    func exactlyAtThreshold() {
        let result = ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.35,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        )
        #expect(result == true)
    }

    @Test("Custom debounce threshold is respected")
    func customThreshold() {
        let result = ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.8,
            debounceThreshold: 1.0,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        )
        #expect(result == true)
    }

    @Test("Zero elapsed time ignores")
    func zeroElapsed() {
        let result = ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.0,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        )
        #expect(result == true)
    }
}
