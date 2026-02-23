import Testing
import Foundation
import Carbon.HIToolbox
@testable import OpenWhisper

@Suite("HotkeyMonitor Package API", .serialized)
struct HotkeyMonitorPackageAPITests {

    private func makeMonitor() -> HotkeyMonitor {
        HotkeyMonitor()
    }

    // MARK: - humanList

    @Test("humanList with empty array returns empty string")
    func humanListEmpty() {
        #expect(HotkeyMonitor.humanList([]) == "")
    }

    @Test("humanList with single item returns that item")
    func humanListSingle() {
        #expect(HotkeyMonitor.humanList(["Accessibility"]) == "Accessibility")
    }

    @Test("humanList with two items uses 'and'")
    func humanListTwo() {
        #expect(HotkeyMonitor.humanList(["Accessibility", "Input Monitoring"]) == "Accessibility and Input Monitoring")
    }

    @Test("humanList with three items uses Oxford comma")
    func humanListThree() {
        #expect(HotkeyMonitor.humanList(["A", "B", "C"]) == "A, B, and C")
    }

    @Test("humanList with four items")
    func humanListFour() {
        #expect(HotkeyMonitor.humanList(["A", "B", "C", "D"]) == "A, B, C, and D")
    }

    // MARK: - parseFunctionKeyNumber

    @Test("parseFunctionKeyNumber parses f1 through f24")
    func parseFunctionKeyNumbers() {
        let monitor = makeMonitor()
        #expect(monitor.parseFunctionKeyNumber("f1") == 1)
        #expect(monitor.parseFunctionKeyNumber("f12") == 12)
        #expect(monitor.parseFunctionKeyNumber("f24") == 24)
    }

    @Test("parseFunctionKeyNumber parses various prefixes")
    func parseFunctionKeyPrefixes() {
        let monitor = makeMonitor()
        #expect(monitor.parseFunctionKeyNumber("fn5") == 5)
        #expect(monitor.parseFunctionKeyNumber("fkey3") == 3)
        #expect(monitor.parseFunctionKeyNumber("fnkey7") == 7)
        #expect(monitor.parseFunctionKeyNumber("function10") == 10)
        #expect(monitor.parseFunctionKeyNumber("functionkey2") == 2)
    }

    @Test("parseFunctionKeyNumber returns nil for non-function keys")
    func parseFunctionKeyNil() {
        let monitor = makeMonitor()
        #expect(monitor.parseFunctionKeyNumber("space") == nil)
        #expect(monitor.parseFunctionKeyNumber("f") == nil)
        #expect(monitor.parseFunctionKeyNumber("") == nil)
        #expect(monitor.parseFunctionKeyNumber("abc") == nil)
    }

    @Test("parseFunctionKeyNumber handles out-of-range values")
    func parseFunctionKeyOutOfRange() {
        let monitor = makeMonitor()
        #expect(monitor.parseFunctionKeyNumber("f0") == 0)
        #expect(monitor.parseFunctionKeyNumber("f99") == 99)
        #expect(monitor.parseFunctionKeyNumber("f100") == 100)
    }

    // MARK: - looksLikeShortcutCombo

    @Test("looksLikeShortcutCombo detects plus sign")
    func shortcutComboPlus() {
        let monitor = makeMonitor()
        #expect(monitor.looksLikeShortcutCombo("cmd+space") == true)
        #expect(monitor.looksLikeShortcutCombo("⌘+f") == true)
    }

    @Test("looksLikeShortcutCombo detects modifier + key")
    func shortcutComboModifierKey() {
        let monitor = makeMonitor()
        #expect(monitor.looksLikeShortcutCombo("command space") == true)
        #expect(monitor.looksLikeShortcutCombo("shift a") == true)
        #expect(monitor.looksLikeShortcutCombo("ctrl option x") == true)
    }

    @Test("looksLikeShortcutCombo returns false for single key")
    func shortcutComboSingleKey() {
        let monitor = makeMonitor()
        #expect(monitor.looksLikeShortcutCombo("space") == false)
        #expect(monitor.looksLikeShortcutCombo("f6") == false)
        #expect(monitor.looksLikeShortcutCombo("a") == false)
    }

    @Test("looksLikeShortcutCombo with emoji modifiers")
    func shortcutComboEmoji() {
        let monitor = makeMonitor()
        #expect(monitor.looksLikeShortcutCombo("⌘space") == true)
        #expect(monitor.looksLikeShortcutCombo("⌃⌥a") == true)
    }

    // MARK: - looksLikeModifierOnlyInput

    @Test("looksLikeModifierOnlyInput returns true for modifier-only strings")
    func modifierOnlyTrue() {
        let monitor = makeMonitor()
        #expect(monitor.looksLikeModifierOnlyInput("command") == true)
        #expect(monitor.looksLikeModifierOnlyInput("shift") == true)
        #expect(monitor.looksLikeModifierOnlyInput("ctrl") == true)
        #expect(monitor.looksLikeModifierOnlyInput("option") == true)
        #expect(monitor.looksLikeModifierOnlyInput("cmd shift") == true)
    }

    @Test("looksLikeModifierOnlyInput returns false for keys")
    func modifierOnlyFalse() {
        let monitor = makeMonitor()
        #expect(monitor.looksLikeModifierOnlyInput("space") == false)
        #expect(monitor.looksLikeModifierOnlyInput("a") == false)
        #expect(monitor.looksLikeModifierOnlyInput("f6") == false)
        #expect(monitor.looksLikeModifierOnlyInput("command space") == false)
    }

    @Test("looksLikeModifierOnlyInput returns false for empty")
    func modifierOnlyEmpty() {
        let monitor = makeMonitor()
        #expect(monitor.looksLikeModifierOnlyInput("") == false)
    }

    // MARK: - expandedShortcutTokens

    @Test("expandedShortcutTokens splits on whitespace and plus")
    func expandedTokensSplit() {
        let monitor = makeMonitor()
        let tokens = monitor.expandedShortcutTokens(from: "cmd+space")
        #expect(tokens == ["cmd", "space"])
    }

    @Test("expandedShortcutTokens expands emoji glyphs")
    func expandedTokensEmoji() {
        let monitor = makeMonitor()
        let tokens = monitor.expandedShortcutTokens(from: "⌘space")
        #expect(tokens.contains("command"))
        #expect(tokens.contains("space"))
    }

    @Test("expandedShortcutTokens expands all modifier emojis")
    func expandedTokensAllEmoji() {
        let monitor = makeMonitor()
        let tokens = monitor.expandedShortcutTokens(from: "⌘⇧⌃⌥🌐")
        #expect(tokens.contains("command"))
        #expect(tokens.contains("shift"))
        #expect(tokens.contains("control"))
        #expect(tokens.contains("option"))
        #expect(tokens.contains("globe"))
    }

    @Test("expandedShortcutTokens splits on dash")
    func expandedTokensDash() {
        let monitor = makeMonitor()
        let tokens = monitor.expandedShortcutTokens(from: "cmd-shift-a")
        #expect(tokens == ["cmd", "shift", "a"])
    }

    @Test("expandedShortcutTokens splits on comma")
    func expandedTokensComma() {
        let monitor = makeMonitor()
        let tokens = monitor.expandedShortcutTokens(from: "cmd,shift")
        #expect(tokens == ["cmd", "shift"])
    }

    // MARK: - shortcutModifierWords

    @Test("shortcutModifierWords contains expected modifiers")
    func modifierWords() {
        let monitor = makeMonitor()
        let words = monitor.shortcutModifierWords()
        #expect(words.contains("cmd"))
        #expect(words.contains("command"))
        #expect(words.contains("shift"))
        #expect(words.contains("ctrl"))
        #expect(words.contains("control"))
        #expect(words.contains("opt"))
        #expect(words.contains("option"))
        #expect(words.contains("alt"))
        #expect(words.contains("fn"))
        #expect(words.contains("globe"))
        #expect(words.contains("meta"))
        #expect(words.contains("super"))
    }

    @Test("shortcutModifierWords does not contain regular keys")
    func modifierWordsExcludes() {
        let monitor = makeMonitor()
        let words = monitor.shortcutModifierWords()
        #expect(!words.contains("space"))
        #expect(!words.contains("a"))
        #expect(!words.contains("f6"))
    }

    // MARK: - keyCodeForKeyString

    @Test("keyCodeForKeyString maps space")
    func keyCodeSpace() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("space") == CGKeyCode(kVK_Space))
        #expect(monitor.keyCodeForKeyString("spacebar") == CGKeyCode(kVK_Space))
    }

    @Test("keyCodeForKeyString maps return/enter")
    func keyCodeReturn() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("return") == CGKeyCode(kVK_Return))
        #expect(monitor.keyCodeForKeyString("enter") == CGKeyCode(kVK_Return))
    }

    @Test("keyCodeForKeyString maps escape")
    func keyCodeEscape() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("escape") == CGKeyCode(kVK_Escape))
        #expect(monitor.keyCodeForKeyString("esc") == CGKeyCode(kVK_Escape))
    }

    @Test("keyCodeForKeyString maps tab")
    func keyCodeTab() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("tab") == CGKeyCode(kVK_Tab))
    }

    @Test("keyCodeForKeyString maps delete variants")
    func keyCodeDelete() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("delete") == CGKeyCode(kVK_Delete))
        #expect(monitor.keyCodeForKeyString("del") == CGKeyCode(kVK_Delete))
        #expect(monitor.keyCodeForKeyString("backspace") == CGKeyCode(kVK_Delete))
        #expect(monitor.keyCodeForKeyString("bksp") == CGKeyCode(kVK_Delete))
    }

    @Test("keyCodeForKeyString maps forward delete")
    func keyCodeForwardDelete() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("forwarddelete") == CGKeyCode(kVK_ForwardDelete))
        #expect(monitor.keyCodeForKeyString("fwddelete") == CGKeyCode(kVK_ForwardDelete))
        #expect(monitor.keyCodeForKeyString("fwddel") == CGKeyCode(kVK_ForwardDelete))
    }

    @Test("keyCodeForKeyString maps function keys")
    func keyCodeFunctionKeys() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("f1") == CGKeyCode(kVK_F1))
        #expect(monitor.keyCodeForKeyString("f12") == CGKeyCode(kVK_F12))
        #expect(monitor.keyCodeForKeyString("f13") == CGKeyCode(kVK_F13))
        #expect(monitor.keyCodeForKeyString("f20") == CGKeyCode(kVK_F20))
    }

    @Test("keyCodeForKeyString maps arrow keys")
    func keyCodeArrows() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("left") == CGKeyCode(kVK_LeftArrow))
        #expect(monitor.keyCodeForKeyString("right") == CGKeyCode(kVK_RightArrow))
        #expect(monitor.keyCodeForKeyString("up") == CGKeyCode(kVK_UpArrow))
        #expect(monitor.keyCodeForKeyString("down") == CGKeyCode(kVK_DownArrow))
    }

    @Test("keyCodeForKeyString maps navigation keys")
    func keyCodeNavigation() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("home") == CGKeyCode(kVK_Home))
        #expect(monitor.keyCodeForKeyString("end") == CGKeyCode(kVK_End))
        #expect(monitor.keyCodeForKeyString("pageup") == CGKeyCode(kVK_PageUp))
        #expect(monitor.keyCodeForKeyString("pagedown") == CGKeyCode(kVK_PageDown))
    }

    @Test("keyCodeForKeyString maps punctuation")
    func keyCodePunctuation() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("-") == CGKeyCode(kVK_ANSI_Minus))
        #expect(monitor.keyCodeForKeyString("=") == CGKeyCode(kVK_ANSI_Equal))
        #expect(monitor.keyCodeForKeyString("[") == CGKeyCode(kVK_ANSI_LeftBracket))
        #expect(monitor.keyCodeForKeyString("]") == CGKeyCode(kVK_ANSI_RightBracket))
        #expect(monitor.keyCodeForKeyString(";") == CGKeyCode(kVK_ANSI_Semicolon))
        #expect(monitor.keyCodeForKeyString(",") == CGKeyCode(kVK_ANSI_Comma))
        #expect(monitor.keyCodeForKeyString(".") == CGKeyCode(kVK_ANSI_Period))
        #expect(monitor.keyCodeForKeyString("/") == CGKeyCode(kVK_ANSI_Slash))
        #expect(monitor.keyCodeForKeyString("\\") == CGKeyCode(kVK_ANSI_Backslash))
        #expect(monitor.keyCodeForKeyString("`") == CGKeyCode(kVK_ANSI_Grave))
    }

    @Test("keyCodeForKeyString maps keypad keys")
    func keyCodeKeypad() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("keypad0") == CGKeyCode(kVK_ANSI_Keypad0))
        #expect(monitor.keyCodeForKeyString("numpad5") == CGKeyCode(kVK_ANSI_Keypad5))
        #expect(monitor.keyCodeForKeyString("keypadenter") == CGKeyCode(kVK_ANSI_KeypadEnter))
        #expect(monitor.keyCodeForKeyString("keypadplus") == CGKeyCode(kVK_ANSI_KeypadPlus))
        #expect(monitor.keyCodeForKeyString("keypadminus") == CGKeyCode(kVK_ANSI_KeypadMinus))
    }

    @Test("keyCodeForKeyString maps special keys")
    func keyCodeSpecial() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("caps") == CGKeyCode(kVK_CapsLock))
        #expect(monitor.keyCodeForKeyString("fn") == CGKeyCode(kVK_Function))
        #expect(monitor.keyCodeForKeyString("globe") == CGKeyCode(kVK_Function))
        #expect(monitor.keyCodeForKeyString("insert") == CGKeyCode(kVK_Help))
        #expect(monitor.keyCodeForKeyString("eject") == CGKeyCode(0x92))
        #expect(monitor.keyCodeForKeyString("section") == CGKeyCode(kVK_ISO_Section))
    }

    @Test("keyCodeForKeyString returns nil for unknown")
    func keyCodeUnknown() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("xyz") == nil)
        #expect(monitor.keyCodeForKeyString("") == nil)
    }

    // MARK: - letterKeyCode

    @Test("letterKeyCode maps all letters")
    func letterKeyCodes() {
        let monitor = makeMonitor()
        #expect(monitor.letterKeyCode(for: "a") == CGKeyCode(kVK_ANSI_A))
        #expect(monitor.letterKeyCode(for: "z") == CGKeyCode(kVK_ANSI_Z))
        #expect(monitor.letterKeyCode(for: "m") == CGKeyCode(kVK_ANSI_M))
    }

    @Test("letterKeyCode returns nil for non-letters")
    func letterKeyCodeNil() {
        let monitor = makeMonitor()
        #expect(monitor.letterKeyCode(for: "1") == nil)
        #expect(monitor.letterKeyCode(for: " ") == nil)
        #expect(monitor.letterKeyCode(for: "A") == nil)
    }

    // MARK: - digitKeyCode

    @Test("digitKeyCode maps all digits")
    func digitKeyCodes() {
        let monitor = makeMonitor()
        #expect(monitor.digitKeyCode(for: "0") == CGKeyCode(kVK_ANSI_0))
        #expect(monitor.digitKeyCode(for: "5") == CGKeyCode(kVK_ANSI_5))
        #expect(monitor.digitKeyCode(for: "9") == CGKeyCode(kVK_ANSI_9))
    }

    @Test("digitKeyCode returns nil for non-digits")
    func digitKeyCodeNil() {
        let monitor = makeMonitor()
        #expect(monitor.digitKeyCode(for: "a") == nil)
        #expect(monitor.digitKeyCode(for: " ") == nil)
    }

    // MARK: - keyCodeForKeyString with single characters

    @Test("keyCodeForKeyString maps single lowercase letters via letterKeyCode")
    func keyCodeSingleLetter() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("a") == CGKeyCode(kVK_ANSI_A))
        #expect(monitor.keyCodeForKeyString("z") == CGKeyCode(kVK_ANSI_Z))
    }

    @Test("keyCodeForKeyString maps single digits via digitKeyCode")
    func keyCodeSingleDigit() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("0") == CGKeyCode(kVK_ANSI_0))
        #expect(monitor.keyCodeForKeyString("9") == CGKeyCode(kVK_ANSI_9))
    }

    // MARK: - normalizedOutOfRangeFunctionKeyInput

    @Test("normalizedOutOfRangeFunctionKeyInput returns label for out-of-range function keys")
    func outOfRangeFunctionKey() {
        let monitor = makeMonitor()
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("f0") == "F0")
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("f25") == "F25")
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("f99") == "F99")
    }

    @Test("normalizedOutOfRangeFunctionKeyInput returns nil for in-range function keys")
    func inRangeFunctionKey() {
        let monitor = makeMonitor()
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("f1") == nil)
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("f12") == nil)
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("f24") == nil)
    }

    @Test("normalizedOutOfRangeFunctionKeyInput returns nil for non-function keys")
    func nonFunctionKey() {
        let monitor = makeMonitor()
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("space") == nil)
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("a") == nil)
    }

    // MARK: - modifierGlyphSummary

    @Test("modifierGlyphSummary shows command glyph")
    func glyphCommand() {
        let monitor = makeMonitor()
        #expect(monitor.modifierGlyphSummary(from: .maskCommand) == "⌘")
    }

    @Test("modifierGlyphSummary shows multiple glyphs joined by plus")
    func glyphMultiple() {
        let monitor = makeMonitor()
        let flags: CGEventFlags = [.maskCommand, .maskShift]
        let result = monitor.modifierGlyphSummary(from: flags)
        #expect(result.contains("⌘"))
        #expect(result.contains("⇧"))
        #expect(result.contains("+"))
    }

    @Test("modifierGlyphSummary returns empty for no flags")
    func glyphEmpty() {
        let monitor = makeMonitor()
        #expect(monitor.modifierGlyphSummary(from: CGEventFlags(rawValue: 0)) == "")
    }

    // MARK: - allowsNoModifierTrigger

    @Test("allowsNoModifierTrigger returns true for function keys")
    func allowsNoModFunctionKeys() {
        let monitor = makeMonitor()
        #expect(monitor.allowsNoModifierTrigger("f1") == true)
        #expect(monitor.allowsNoModifierTrigger("f24") == true)
    }

    @Test("allowsNoModifierTrigger returns true for special keys")
    func allowsNoModSpecial() {
        let monitor = makeMonitor()
        #expect(monitor.allowsNoModifierTrigger("escape") == true)
        #expect(monitor.allowsNoModifierTrigger("space") == true)
        #expect(monitor.allowsNoModifierTrigger("tab") == true)
        #expect(monitor.allowsNoModifierTrigger("fn") == true)
        #expect(monitor.allowsNoModifierTrigger("globe") == true)
    }

    @Test("allowsNoModifierTrigger returns false for letter keys")
    func allowsNoModLetters() {
        let monitor = makeMonitor()
        #expect(monitor.allowsNoModifierTrigger("a") == false)
        #expect(monitor.allowsNoModifierTrigger("z") == false)
    }

    @Test("allowsNoModifierTrigger returns false for out-of-range function keys")
    func allowsNoModOutOfRange() {
        let monitor = makeMonitor()
        #expect(monitor.allowsNoModifierTrigger("f0") == false)
        #expect(monitor.allowsNoModifierTrigger("f25") == false)
    }

    @Test("allowsNoModifierTrigger returns true for keypad keys")
    func allowsNoModKeypad() {
        let monitor = makeMonitor()
        #expect(monitor.allowsNoModifierTrigger("keypad0") == true)
        #expect(monitor.allowsNoModifierTrigger("numpad5") == true)
        #expect(monitor.allowsNoModifierTrigger("keypadenter") == true)
    }

    // MARK: - configuredComboSummary and currentComboSummary

    @Test("configuredComboSummary returns mode and trigger key")
    func configuredCombo() {
        let monitor = makeMonitor()
        let summary = monitor.configuredComboSummary()
        // Default mode is toggle, trigger key is space
        #expect(!summary.isEmpty)
    }

    @Test("currentComboSummary returns non-empty")
    func currentCombo() {
        let monitor = makeMonitor()
        let summary = monitor.currentComboSummary()
        #expect(!summary.isEmpty)
    }

    // MARK: - keyCodeMatchesConfiguredTrigger

    @Test("keyCodeMatchesConfiguredTrigger exact match")
    func keyCodeMatchExact() {
        let monitor = makeMonitor()
        let code = CGKeyCode(kVK_Space)
        #expect(monitor.keyCodeMatchesConfiguredTrigger(eventKeyCode: code, configuredKeyCode: code) == true)
    }

    @Test("keyCodeMatchesConfiguredTrigger mismatch")
    func keyCodeMatchMismatch() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeMatchesConfiguredTrigger(eventKeyCode: CGKeyCode(kVK_ANSI_A), configuredKeyCode: CGKeyCode(kVK_Space)) == false)
    }

    // MARK: - keyCodeForKeyString punctuation aliases

    @Test("keyCodeForKeyString maps punctuation aliases")
    func keyCodePunctuationAliases() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("minus") == CGKeyCode(kVK_ANSI_Minus))
        #expect(monitor.keyCodeForKeyString("hyphen") == CGKeyCode(kVK_ANSI_Minus))
        #expect(monitor.keyCodeForKeyString("_") == CGKeyCode(kVK_ANSI_Minus))
        #expect(monitor.keyCodeForKeyString("equals") == CGKeyCode(kVK_ANSI_Equal))
        #expect(monitor.keyCodeForKeyString("plus") == CGKeyCode(kVK_ANSI_Equal))
        #expect(monitor.keyCodeForKeyString("openbracket") == CGKeyCode(kVK_ANSI_LeftBracket))
        #expect(monitor.keyCodeForKeyString("closebracket") == CGKeyCode(kVK_ANSI_RightBracket))
        #expect(monitor.keyCodeForKeyString("semicolon") == CGKeyCode(kVK_ANSI_Semicolon))
        #expect(monitor.keyCodeForKeyString("apostrophe") == CGKeyCode(kVK_ANSI_Quote))
        #expect(monitor.keyCodeForKeyString("comma") == CGKeyCode(kVK_ANSI_Comma))
        #expect(monitor.keyCodeForKeyString("period") == CGKeyCode(kVK_ANSI_Period))
        #expect(monitor.keyCodeForKeyString("dot") == CGKeyCode(kVK_ANSI_Period))
        #expect(monitor.keyCodeForKeyString("slash") == CGKeyCode(kVK_ANSI_Slash))
        #expect(monitor.keyCodeForKeyString("backslash") == CGKeyCode(kVK_ANSI_Backslash))
        #expect(monitor.keyCodeForKeyString("grave") == CGKeyCode(kVK_ANSI_Grave))
        #expect(monitor.keyCodeForKeyString("backtick") == CGKeyCode(kVK_ANSI_Grave))
    }

    // MARK: - keyCodeForKeyString extended function keys

    @Test("keyCodeForKeyString maps f21 through f24")
    func keyCodeExtendedFunctionKeys() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("f21") == CGKeyCode(0x6E))
        #expect(monitor.keyCodeForKeyString("f22") == CGKeyCode(0x6F))
        #expect(monitor.keyCodeForKeyString("f23") == CGKeyCode(0x70))
        #expect(monitor.keyCodeForKeyString("f24") == CGKeyCode(0x71))
    }

    // MARK: - keyCodeForKeyString all keypad variants

    @Test("keyCodeForKeyString maps all keypad variants")
    func keyCodeAllKeypad() {
        let monitor = makeMonitor()
        for i in 0...9 {
            #expect(monitor.keyCodeForKeyString("keypad\(i)") != nil)
            #expect(monitor.keyCodeForKeyString("numpad\(i)") != nil)
        }
        #expect(monitor.keyCodeForKeyString("keypaddecimal") == CGKeyCode(kVK_ANSI_KeypadDecimal))
        #expect(monitor.keyCodeForKeyString("keypadmultiply") == CGKeyCode(kVK_ANSI_KeypadMultiply))
        #expect(monitor.keyCodeForKeyString("keypadclear") == CGKeyCode(kVK_ANSI_KeypadClear))
        #expect(monitor.keyCodeForKeyString("keypaddivide") == CGKeyCode(kVK_ANSI_KeypadDivide))
        #expect(monitor.keyCodeForKeyString("keypadequals") == CGKeyCode(kVK_ANSI_KeypadEquals))
    }

    // MARK: - letterKeyCode all 26 letters

    @Test("letterKeyCode maps all 26 lowercase letters")
    func allLetterKeyCodes() {
        let monitor = makeMonitor()
        for char in "abcdefghijklmnopqrstuvwxyz" {
            #expect(monitor.letterKeyCode(for: char) != nil, "Expected key code for '\(char)'")
        }
    }

    // MARK: - digitKeyCode all 10 digits

    @Test("digitKeyCode maps all 10 digits")
    func allDigitKeyCodes() {
        let monitor = makeMonitor()
        for char in "0123456789" {
            #expect(monitor.digitKeyCode(for: char) != nil, "Expected key code for '\(char)'")
        }
    }

    // MARK: - allowsNoModifierTrigger comprehensive

    @Test("allowsNoModifierTrigger for all navigational keys")
    func allowsNoModNav() {
        let monitor = makeMonitor()
        for key in ["left", "right", "up", "down", "home", "end", "pageup", "pagedown"] {
            #expect(monitor.allowsNoModifierTrigger(key) == true, "Expected \(key) to allow no modifier")
        }
    }

    @Test("allowsNoModifierTrigger for delete variants")
    func allowsNoModDelete() {
        let monitor = makeMonitor()
        for key in ["delete", "del", "backspace", "bksp", "forwarddelete", "fwddelete", "fwddel"] {
            #expect(monitor.allowsNoModifierTrigger(key) == true, "Expected \(key) to allow no modifier")
        }
    }
}
