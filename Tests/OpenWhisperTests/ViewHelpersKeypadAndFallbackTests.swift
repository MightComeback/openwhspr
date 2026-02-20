import Testing
@testable import OpenWhisper

/// Tests for hotkeyKeyNameFromKeyCode keypad mappings and the characters-fallback path,
/// plus hotkeyKeyNameForKeyCode parity and edge cases.
@Suite("ViewHelpers Keypad & Fallback Key Mapping")
struct ViewHelpersKeypadAndFallbackTests {

    // MARK: - hotkeyKeyNameFromKeyCode: keypad keys

    @Test("keypad0 through keypad9")
    func keypadDigits() {
        let expected: [(Int, String)] = [
            (0x52, "keypad0"), (0x53, "keypad1"), (0x54, "keypad2"), (0x55, "keypad3"),
            (0x56, "keypad4"), (0x57, "keypad5"), (0x58, "keypad6"), (0x59, "keypad7"),
            (0x5B, "keypad8"), (0x5C, "keypad9"),
        ]
        for (code, name) in expected {
            #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(code) == name, "keyCode \(code) → \(name)")
        }
    }

    @Test("keypad operators and special")
    func keypadOperators() {
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

    // MARK: - hotkeyKeyNameFromKeyCode: characters fallback

    @Test("Unknown key code with characters falls back to lowercased character")
    func unknownKeyCodeWithCharacters() {
        // key code 0x00 is 'a'
        let result = ViewHelpers.hotkeyKeyNameFromKeyCode(0x00, characters: "A")
        #expect(result != nil)
        // Should be lowercase canonical key
        #expect(result == HotkeyDisplay.canonicalKey("a"))
    }

    @Test("Unknown key code with nil characters returns nil")
    func unknownKeyCodeNilChars() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0xFF, characters: nil) == nil)
    }

    @Test("Unknown key code with empty characters returns nil")
    func unknownKeyCodeEmptyChars() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0xFF, characters: "") == nil)
    }

    @Test("Unknown key code with whitespace character returns space")
    func unknownKeyCodeWhitespace() {
        let result = ViewHelpers.hotkeyKeyNameFromKeyCode(0xFF, characters: " ")
        #expect(result == "space")
    }

    @Test("Unknown key code with tab character returns space")
    func unknownKeyCodeTabChar() {
        let result = ViewHelpers.hotkeyKeyNameFromKeyCode(0xFF, characters: "\t")
        #expect(result == "space")
    }

    @Test("Unknown key code with multi-character string uses first scalar")
    func unknownKeyCodeMultiChar() {
        let result = ViewHelpers.hotkeyKeyNameFromKeyCode(0xFF, characters: "AB")
        #expect(result == HotkeyDisplay.canonicalKey("a"))
    }

    // MARK: - hotkeyKeyNameForKeyCode vs hotkeyKeyNameFromKeyCode parity

    @Test("Known special keys match between both functions")
    func paritySpecialKeys() {
        let sharedCodes = [
            0x3F, 0x31, 0x30, 0x24, 0x35, 0x33, 0x75, 0x72,
            0x7B, 0x7C, 0x7E, 0x7D, 0x73, 0x77, 0x74, 0x79,
        ]
        for code in sharedCodes {
            let a = ViewHelpers.hotkeyKeyNameForKeyCode(code)
            let b = ViewHelpers.hotkeyKeyNameFromKeyCode(code)
            #expect(a == b, "key code \(String(format: "0x%02X", code)) should match between both functions")
        }
    }

    @Test("F-keys match between both functions")
    func parityFKeys() {
        let fKeyCodes = [
            0x7A, 0x78, 0x63, 0x76, 0x60, 0x61, 0x62, 0x64, 0x65,
            0x6D, 0x67, 0x6F, 0x69, 0x6B, 0x71, 0x6A, 0x40, 0x4F, 0x50, 0x5A,
        ]
        for code in fKeyCodes {
            let a = ViewHelpers.hotkeyKeyNameForKeyCode(code)
            let b = ViewHelpers.hotkeyKeyNameFromKeyCode(code)
            #expect(a == b, "F-key code \(String(format: "0x%02X", code))")
        }
    }

    @Test("Modifier key codes return nil from both functions")
    func parityModifiers() {
        let modifierCodes = [0x37, 0x38, 0x3C, 0x3A, 0x3D, 0x3B, 0x3E, 0x39]
        for code in modifierCodes {
            #expect(ViewHelpers.hotkeyKeyNameForKeyCode(code) == nil)
            #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(code) == nil)
        }
    }

    // MARK: - hotkeyKeyNameForKeyCode returns nil for keypad (different from FromKeyCode)

    @Test("hotkeyKeyNameForKeyCode returns nil for keypad codes (only FromKeyCode handles them)")
    func forKeyCodeMissingKeypad() {
        let keypadCodes = [0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5B, 0x5C,
                           0x41, 0x5F, 0x43, 0x45, 0x47, 0x4B, 0x4C, 0x4E, 0x51]
        for code in keypadCodes {
            // hotkeyKeyNameForKeyCode doesn't handle keypad → returns nil
            #expect(ViewHelpers.hotkeyKeyNameForKeyCode(code) == nil,
                    "ForKeyCode should return nil for keypad code \(String(format: "0x%02X", code))")
            // hotkeyKeyNameFromKeyCode DOES handle keypad
            #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(code) != nil,
                    "FromKeyCode should handle keypad code \(String(format: "0x%02X", code))")
        }
    }

    // MARK: - isModifierOnlyKeyCode coverage

    @Test("Right command (0x36) is modifier-only")
    func rightCommandIsModifier() {
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x36) == true)
    }

    @Test("Function key (0x3F) is modifier-only")
    func fnIsModifier() {
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x3F) == true)
    }

    @Test("Space (0x31) is not modifier-only")
    func spaceNotModifier() {
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x31) == false)
    }

    @Test("Arbitrary unknown code is not modifier-only")
    func unknownNotModifier() {
        #expect(ViewHelpers.isModifierOnlyKeyCode(0xFF) == false)
    }
}
