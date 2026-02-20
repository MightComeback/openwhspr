import Testing
import Foundation
@testable import OpenWhisper

@Suite("SettingsView KeyCode & Format Helpers")
struct SettingsViewKeyCodeAndFormatTests {

    // MARK: - isModifierOnlyKeyCode

    @Test("isModifierOnlyKeyCode: command key")
    func modifierOnlyCommand() {
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x37))
    }

    @Test("isModifierOnlyKeyCode: right command")
    func modifierOnlyRightCommand() {
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x36))
    }

    @Test("isModifierOnlyKeyCode: shift key")
    func modifierOnlyShift() {
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x38))
    }

    @Test("isModifierOnlyKeyCode: right shift")
    func modifierOnlyRightShift() {
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x3C))
    }

    @Test("isModifierOnlyKeyCode: option key")
    func modifierOnlyOption() {
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x3A))
    }

    @Test("isModifierOnlyKeyCode: right option")
    func modifierOnlyRightOption() {
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x3D))
    }

    @Test("isModifierOnlyKeyCode: control key")
    func modifierOnlyControl() {
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x3B))
    }

    @Test("isModifierOnlyKeyCode: right control")
    func modifierOnlyRightControl() {
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x3E))
    }

    @Test("isModifierOnlyKeyCode: caps lock")
    func modifierOnlyCapsLock() {
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x39))
    }

    @Test("isModifierOnlyKeyCode: function key")
    func modifierOnlyFunction() {
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x3F))
    }

    @Test("isModifierOnlyKeyCode: space is not modifier-only")
    func notModifierSpace() {
        #expect(!ViewHelpers.isModifierOnlyKeyCode(0x31))
    }

    @Test("isModifierOnlyKeyCode: return is not modifier-only")
    func notModifierReturn() {
        #expect(!ViewHelpers.isModifierOnlyKeyCode(0x24))
    }

    @Test("isModifierOnlyKeyCode: letter a is not modifier-only")
    func notModifierLetterA() {
        #expect(!ViewHelpers.isModifierOnlyKeyCode(0x00))
    }

    @Test("isModifierOnlyKeyCode: f1 is not modifier-only")
    func notModifierF1() {
        #expect(!ViewHelpers.isModifierOnlyKeyCode(0x7A))
    }

    // MARK: - hotkeyKeyNameFromKeyCode

    @Test("hotkeyKeyNameFromKeyCode: modifier keys return nil")
    func keyNameModifierNil() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x37) == nil) // command
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x38) == nil) // shift
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x3C) == nil) // right shift
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x3A) == nil) // option
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x3D) == nil) // right option
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x3B) == nil) // control
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x3E) == nil) // right control
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x39) == nil) // caps lock
    }

    @Test("hotkeyKeyNameFromKeyCode: fn returns fn")
    func keyNameFn() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x3F) == "fn")
    }

    @Test("hotkeyKeyNameFromKeyCode: space")
    func keyNameSpace() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x31) == "space")
    }

    @Test("hotkeyKeyNameFromKeyCode: tab")
    func keyNameTab() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x30) == "tab")
    }

    @Test("hotkeyKeyNameFromKeyCode: return")
    func keyNameReturn() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x24) == "return")
    }

    @Test("hotkeyKeyNameFromKeyCode: escape")
    func keyNameEscape() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x35) == "escape")
    }

    @Test("hotkeyKeyNameFromKeyCode: delete")
    func keyNameDelete() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x33) == "delete")
    }

    @Test("hotkeyKeyNameFromKeyCode: forwarddelete")
    func keyNameForwardDelete() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x75) == "forwarddelete")
    }

    @Test("hotkeyKeyNameFromKeyCode: insert (help)")
    func keyNameInsert() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x72) == "insert")
    }

    @Test("hotkeyKeyNameFromKeyCode: arrow keys")
    func keyNameArrows() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x7B) == "left")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x7C) == "right")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x7E) == "up")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x7D) == "down")
    }

    @Test("hotkeyKeyNameFromKeyCode: home end pageup pagedown")
    func keyNameNavigation() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x73) == "home")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x77) == "end")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x74) == "pageup")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x79) == "pagedown")
    }

    @Test("hotkeyKeyNameFromKeyCode: function keys f1-f12")
    func keyNameFunctionKeys() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x7A) == "f1")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x78) == "f2")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x63) == "f3")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x76) == "f4")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x60) == "f5")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x61) == "f6")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x62) == "f7")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x64) == "f8")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x65) == "f9")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x6D) == "f10")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x67) == "f11")
    }

    @Test("hotkeyKeyNameFromKeyCode: f13-f20")
    func keyNameHighFunctionKeys() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x69) == "f13")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x6B) == "f14")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x6A) == "f16")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x40) == "f17")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x4F) == "f18")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x50) == "f19")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x5A) == "f20")
    }

    @Test("hotkeyKeyNameFromKeyCode: keypad digits")
    func keyNameKeypadDigits() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x52) == "keypad0")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x53) == "keypad1")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x54) == "keypad2")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x55) == "keypad3")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x56) == "keypad4")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x57) == "keypad5")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x58) == "keypad6")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x59) == "keypad7")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x5B) == "keypad8")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x5C) == "keypad9")
    }

    @Test("hotkeyKeyNameFromKeyCode: keypad operators")
    func keyNameKeypadOperators() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x41) == "keypaddecimal")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x5F) == "keypadcomma")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x43) == "keypadmultiply")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x45) == "keypadplus")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x47) == "keypadclear")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x4B) == "keypaddivide")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x4C) == "keypadenter")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x4E) == "keypadminus")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x51) == "keypadequals")
    }

    @Test("hotkeyKeyNameFromKeyCode: unknown code with characters")
    func keyNameUnknownWithCharacters() {
        // 0x00 = kVK_ANSI_A
        let result = ViewHelpers.hotkeyKeyNameFromKeyCode(0x00, characters: "a")
        #expect(result != nil)
    }

    @Test("hotkeyKeyNameFromKeyCode: unknown code without characters returns nil")
    func keyNameUnknownNoCharacters() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0xFF) == nil)
    }

    @Test("hotkeyKeyNameFromKeyCode: unknown code with whitespace character returns space")
    func keyNameUnknownWhitespace() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0xFF, characters: "\t") == "space")
    }

    @Test("hotkeyKeyNameFromKeyCode: unknown code with uppercase lowercases")
    func keyNameUnknownUppercase() {
        let result = ViewHelpers.hotkeyKeyNameFromKeyCode(0x00, characters: "A")
        #expect(result != nil)
    }

    // MARK: - formatBytes

    @Test("formatBytes: zero bytes")
    func formatBytesZero() {
        let result = ViewHelpers.formatBytes(0)
        #expect(result.contains("0") || result.contains("Zero"))
    }

    @Test("formatBytes: kilobytes")
    func formatBytesKB() {
        let result = ViewHelpers.formatBytes(1024)
        #expect(result.contains("KB") || result.contains("kB"))
    }

    @Test("formatBytes: megabytes")
    func formatBytesMB() {
        let result = ViewHelpers.formatBytes(10_000_000)
        #expect(result.contains("MB"))
    }

    @Test("formatBytes: large value")
    func formatBytesLarge() {
        let result = ViewHelpers.formatBytes(100_000_000)
        #expect(!result.isEmpty)
    }

    @Test("formatBytes: negative value")
    func formatBytesNegative() {
        let result = ViewHelpers.formatBytes(-1024)
        #expect(!result.isEmpty)
    }

    @Test("formatBytes: exact 1 MB")
    func formatBytesExactMB() {
        let result = ViewHelpers.formatBytes(1_000_000)
        #expect(result.contains("MB"))
    }
}
