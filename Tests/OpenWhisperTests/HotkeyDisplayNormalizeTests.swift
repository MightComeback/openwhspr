import Testing
import Foundation
@testable import OpenWhisper

/// Tests exercising the `normalizeKey` and `canonicalFunctionKeyAlias` paths
/// reachable through the public `canonicalKey` / `isSupportedKey` API.
@Suite("HotkeyDisplay normalizeKey paths")
struct HotkeyDisplayNormalizeTests {

    // MARK: - Literal control-character inputs

    @Test("literal space character normalizes to space")
    func literalSpace() {
        #expect(HotkeyDisplay.canonicalKey(" ") == "space")
    }

    @Test("literal tab character normalizes to tab")
    func literalTab() {
        #expect(HotkeyDisplay.canonicalKey("\t") == "tab")
    }

    @Test("literal return character normalizes to return")
    func literalReturn() {
        #expect(HotkeyDisplay.canonicalKey("\r") == "return")
    }

    @Test("literal newline character normalizes to return")
    func literalNewline() {
        #expect(HotkeyDisplay.canonicalKey("\n") == "return")
    }

    // MARK: - Unicode whitespace and plus variants

    @Test("non-breaking space is trimmed")
    func nonBreakingSpace() {
        // "\u{00A0}space\u{00A0}" → trimmed to "space"
        #expect(HotkeyDisplay.canonicalKey("\u{00A0}space\u{00A0}") == "space")
    }

    @Test("fullwidth plus is normalized")
    func fullwidthPlus() {
        // "cmd＋space" → "＋" becomes "+", then modifier stripping → "space"
        #expect(HotkeyDisplay.canonicalKey("cmd＋space") == "space")
    }

    @Test("small plus is normalized")
    func smallPlus() {
        #expect(HotkeyDisplay.canonicalKey("cmd﹢space") == "space")
    }

    @Test("dotplus is normalized")
    func dotPlus() {
        #expect(HotkeyDisplay.canonicalKey("cmd∔space") == "space")
    }

    // MARK: - Slash-separated combo pastes

    @Test("command/shift/space extracts space")
    func slashSeparatedCombo() {
        #expect(HotkeyDisplay.canonicalKey("command/shift/space") == "space")
    }

    @Test("trailing slash is preserved as literal slash")
    func trailingSlash() {
        // "command+shift/" → the last token is "/", which is slash
        #expect(HotkeyDisplay.canonicalKey("command+shift+/") == "slash")
    }

    // MARK: - Modifier symbol expansion

    @Test("⌘⇧space extracts space")
    func symbolModifierCombo() {
        #expect(HotkeyDisplay.canonicalKey("⌘⇧space") == "space")
    }

    @Test("⌘ alone returns command")
    func commandSymbolAlone() {
        #expect(HotkeyDisplay.canonicalKey("⌘") == "command")
    }

    @Test("⇧ alone returns shift")
    func shiftSymbolAlone() {
        #expect(HotkeyDisplay.canonicalKey("⇧") == "shift")
    }

    @Test("⌥ alone returns option")
    func optionSymbolAlone() {
        #expect(HotkeyDisplay.canonicalKey("⌥") == "option")
    }

    @Test("⌃ alone returns control")
    func controlSymbolAlone() {
        #expect(HotkeyDisplay.canonicalKey("⌃") == "control")
    }

    @Test("⇪ alone returns capslock")
    func capsLockSymbolAlone() {
        #expect(HotkeyDisplay.canonicalKey("⇪") == "capslock")
    }

    // MARK: - Arrow/special symbol expansion

    @Test("↩ returns return")
    func returnArrow() {
        #expect(HotkeyDisplay.canonicalKey("↩") == "return")
    }

    @Test("⎋ returns escape")
    func escapeSymbol() {
        #expect(HotkeyDisplay.canonicalKey("⎋") == "escape")
    }

    @Test("⌫ returns delete")
    func deleteSymbol() {
        #expect(HotkeyDisplay.canonicalKey("⌫") == "delete")
    }

    @Test("⌦ returns forwarddelete")
    func forwardDeleteSymbol() {
        #expect(HotkeyDisplay.canonicalKey("⌦") == "forwarddelete")
    }

    @Test("← returns left")
    func leftArrowSymbol() {
        #expect(HotkeyDisplay.canonicalKey("←") == "left")
    }

    @Test("→ returns right")
    func rightArrowSymbol() {
        #expect(HotkeyDisplay.canonicalKey("→") == "right")
    }

    @Test("↑ returns up")
    func upArrowSymbol() {
        #expect(HotkeyDisplay.canonicalKey("↑") == "up")
    }

    @Test("↓ returns down")
    func downArrowSymbol() {
        #expect(HotkeyDisplay.canonicalKey("↓") == "down")
    }

    // MARK: - Numpad shorthand via normalizeKey

    @Test("num0 normalizes to keypad0")
    func num0() {
        #expect(HotkeyDisplay.canonicalKey("num0") == "keypad0")
    }

    @Test("kp5 normalizes to keypad5")
    func kp5() {
        #expect(HotkeyDisplay.canonicalKey("kp5") == "keypad5")
    }

    @Test("num+ normalizes to keypadplus")
    func numPlus() {
        #expect(HotkeyDisplay.canonicalKey("num+") == "keypadplus")
    }

    @Test("kp* normalizes to keypadmultiply")
    func kpMultiply() {
        #expect(HotkeyDisplay.canonicalKey("kp*") == "keypadmultiply")
    }

    @Test("numpad/ normalizes to keypaddivide")
    func numpadDivide() {
        #expect(HotkeyDisplay.canonicalKey("numpad/") == "keypaddivide")
    }

    @Test("numpad. normalizes to keypaddecimal")
    func numpadDecimal() {
        #expect(HotkeyDisplay.canonicalKey("numpad.") == "keypaddecimal")
    }

    @Test("numpad, normalizes to keypadcomma")
    func numpadComma() {
        #expect(HotkeyDisplay.canonicalKey("numpad,") == "keypadcomma")
    }

    @Test("numpad= normalizes to keypadequals")
    func numpadEquals() {
        #expect(HotkeyDisplay.canonicalKey("numpad=") == "keypadequals")
    }

    @Test("keypad + with space normalizes to keypadplus")
    func keypadSpacePlus() {
        #expect(HotkeyDisplay.canonicalKey("keypad +") == "keypadplus")
    }

    @Test("keypad - with space normalizes to keypadminus")
    func keypadSpaceMinus() {
        #expect(HotkeyDisplay.canonicalKey("keypad -") == "keypadminus")
    }

    @Test("keypad * with space normalizes to keypadmultiply")
    func keypadSpaceMultiply() {
        #expect(HotkeyDisplay.canonicalKey("keypad *") == "keypadmultiply")
    }

    @Test("numpad x normalizes to keypadmultiply")
    func numpadX() {
        #expect(HotkeyDisplay.canonicalKey("numpad x") == "keypadmultiply")
    }

    @Test("capslock alias")
    func capsLockAlias() {
        #expect(HotkeyDisplay.canonicalKey("capslockkey") == "capslock")
    }

    @Test("fnglobe normalizes to fn")
    func fnGlobe() {
        #expect(HotkeyDisplay.canonicalKey("fnglobe") == "fn")
    }

    @Test("globefn normalizes to fn")
    func globeFn() {
        #expect(HotkeyDisplay.canonicalKey("globefn") == "fn")
    }

    // MARK: - Compact modifier stripping (e.g. "commandshiftspace")

    @Test("commandshiftspace extracts space")
    func compactModifierStrip() {
        #expect(HotkeyDisplay.canonicalKey("commandshiftspace") == "space")
    }

    @Test("ctrlaltdelete extracts delete")
    func ctrlAltDelete() {
        #expect(HotkeyDisplay.canonicalKey("ctrlaltdelete") == "delete")
    }

    @Test("cmdspace extracts space")
    func cmdSpace() {
        #expect(HotkeyDisplay.canonicalKey("cmdspace") == "space")
    }

    // MARK: - Trailing-plus shortcut detection

    @Test("cmd++ normalizes to equals (trailing plus as key)")
    func cmdPlusPlus() {
        // "cmd++" → trailing plus is the trigger key → "+"
        // canonicalKey maps "+" to "equals"
        #expect(HotkeyDisplay.canonicalKey("cmd++") == "equals")
    }

    @Test("⌘+ normalizes to equals")
    func commandSymbolPlus() {
        #expect(HotkeyDisplay.canonicalKey("⌘+") == "equals")
    }

    @Test("numpad+ at end is NOT treated as trailing-plus shortcut")
    func numpadPlusNotTrailingShortcut() {
        // "numpad+" should map to keypadplus, not be confused with trailing-plus
        #expect(HotkeyDisplay.canonicalKey("numpad+") == "keypadplus")
    }

    @Test("kp+ is not trailing-plus shortcut")
    func kpPlusNotTrailingShortcut() {
        #expect(HotkeyDisplay.canonicalKey("kp+") == "keypadplus")
    }

    // MARK: - Function key aliases via canonicalFunctionKeyAlias

    @Test("functionkey12 normalizes to f12")
    func functionKey12() {
        #expect(HotkeyDisplay.canonicalKey("functionkey12") == "f12")
    }

    @Test("fnkey6 normalizes to f6")
    func fnKey6() {
        #expect(HotkeyDisplay.canonicalKey("fnkey6") == "f6")
    }

    @Test("fkey1 normalizes to f1")
    func fKey1() {
        #expect(HotkeyDisplay.canonicalKey("fkey1") == "f1")
    }

    @Test("fn24 normalizes to f24")
    func fn24() {
        #expect(HotkeyDisplay.canonicalKey("fn24") == "f24")
    }

    @Test("function1 normalizes to f1")
    func function1() {
        #expect(HotkeyDisplay.canonicalKey("function1") == "f1")
    }

    @Test("fn0 is out of range, not treated as function key")
    func fn0OutOfRange() {
        // fn0 is not f0 (1..24 only); should fall through
        #expect(HotkeyDisplay.canonicalKey("fn0") != "f0")
    }

    @Test("fn25 is out of range")
    func fn25OutOfRange() {
        #expect(HotkeyDisplay.canonicalKey("fn25") != "f25")
    }

    // MARK: - Variation selector stripping

    @Test("variation selectors are stripped")
    func variationSelectors() {
        #expect(HotkeyDisplay.canonicalKey("space\u{FE0F}") == "space")
        #expect(HotkeyDisplay.canonicalKey("space\u{FE0E}") == "space")
    }

    // MARK: - Comma-separated fallback

    @Test("comma-separated last token extracted")
    func commaSeparated() {
        #expect(HotkeyDisplay.canonicalKey("command,shift,f5") == "f5")
    }

    // MARK: - Misc canonicalKey aliases

    @Test("spacebar maps to space")
    func spacebar() {
        #expect(HotkeyDisplay.canonicalKey("spacebar") == "space")
    }

    @Test("spacekey maps to space")
    func spacekey() {
        #expect(HotkeyDisplay.canonicalKey("spacekey") == "space")
    }

    @Test("enter maps to return")
    func enter() {
        #expect(HotkeyDisplay.canonicalKey("enter") == "return")
    }

    @Test("bksp maps to delete")
    func bksp() {
        #expect(HotkeyDisplay.canonicalKey("bksp") == "delete")
    }

    @Test("pgup maps to pageup")
    func pgup() {
        #expect(HotkeyDisplay.canonicalKey("pgup") == "pageup")
    }

    @Test("pgdn maps to pagedown")
    func pgdn() {
        #expect(HotkeyDisplay.canonicalKey("pgdn") == "pagedown")
    }

    @Test("⇞ maps to pageup")
    func pageUpSymbol() {
        #expect(HotkeyDisplay.canonicalKey("⇞") == "pageup")
    }

    @Test("⇟ maps to pagedown")
    func pageDownSymbol() {
        #expect(HotkeyDisplay.canonicalKey("⇟") == "pagedown")
    }

    @Test("tilde maps to backtick")
    func tilde() {
        #expect(HotkeyDisplay.canonicalKey("~") == "backtick")
    }

    @Test("grave maps to backtick")
    func grave() {
        #expect(HotkeyDisplay.canonicalKey("grave") == "backtick")
    }

    @Test("⌧ maps to keypadclear")
    func clearSymbol() {
        #expect(HotkeyDisplay.canonicalKey("⌧") == "keypadclear")
    }

    @Test("numlock maps to keypadclear")
    func numlock() {
        #expect(HotkeyDisplay.canonicalKey("numlock") == "keypadclear")
    }

    @Test("shifted number symbols map to digits")
    func shiftedNumberSymbols() {
        #expect(HotkeyDisplay.canonicalKey("!") == "1")
        #expect(HotkeyDisplay.canonicalKey("@") == "2")
        #expect(HotkeyDisplay.canonicalKey("#") == "3")
        #expect(HotkeyDisplay.canonicalKey("$") == "4")
        #expect(HotkeyDisplay.canonicalKey("%") == "5")
        #expect(HotkeyDisplay.canonicalKey("^") == "6")
        #expect(HotkeyDisplay.canonicalKey("&") == "7")
        #expect(HotkeyDisplay.canonicalKey("*") == "8")
        #expect(HotkeyDisplay.canonicalKey("(") == "9")
        #expect(HotkeyDisplay.canonicalKey(")") == "0")
    }

    @Test("bracket aliases")
    func bracketAliases() {
        #expect(HotkeyDisplay.canonicalKey("[") == "openbracket")
        #expect(HotkeyDisplay.canonicalKey("]") == "closebracket")
        #expect(HotkeyDisplay.canonicalKey("{") == "openbracket")
        #expect(HotkeyDisplay.canonicalKey("}") == "closebracket")
        #expect(HotkeyDisplay.canonicalKey("leftbracket") == "openbracket")
        #expect(HotkeyDisplay.canonicalKey("rightbracket") == "closebracket")
    }

    @Test("punctuation aliases")
    func punctuationAliases() {
        #expect(HotkeyDisplay.canonicalKey("'") == "apostrophe")
        #expect(HotkeyDisplay.canonicalKey("\"") == "apostrophe")
        #expect(HotkeyDisplay.canonicalKey(".") == "period")
        #expect(HotkeyDisplay.canonicalKey(">") == "period")
        #expect(HotkeyDisplay.canonicalKey("/") == "slash")
        #expect(HotkeyDisplay.canonicalKey("?") == "slash")
        #expect(HotkeyDisplay.canonicalKey("\\") == "backslash")
        #expect(HotkeyDisplay.canonicalKey("|") == "backslash")
        #expect(HotkeyDisplay.canonicalKey(";") == "semicolon")
        #expect(HotkeyDisplay.canonicalKey(":") == "semicolon")
        #expect(HotkeyDisplay.canonicalKey(",") == "comma")
        #expect(HotkeyDisplay.canonicalKey("<") == "comma")
    }

    @Test("dash aliases map to minus")
    func dashAliases() {
        #expect(HotkeyDisplay.canonicalKey("-") == "minus")
        #expect(HotkeyDisplay.canonicalKey("hyphen") == "minus")
        #expect(HotkeyDisplay.canonicalKey("_") == "minus")
        #expect(HotkeyDisplay.canonicalKey("–") == "minus")
        #expect(HotkeyDisplay.canonicalKey("—") == "minus")
        #expect(HotkeyDisplay.canonicalKey("−") == "minus")
    }

    @Test("eject symbol")
    func ejectSymbol() {
        #expect(HotkeyDisplay.canonicalKey("⏏") == "eject")
    }

    @Test("🌐 maps to fn")
    func globeEmoji() {
        #expect(HotkeyDisplay.canonicalKey("🌐") == "fn")
    }

    @Test("§ maps to section")
    func sectionSymbol() {
        #expect(HotkeyDisplay.canonicalKey("§") == "section")
    }

    @Test("± maps to section")
    func plusMinusSymbol() {
        #expect(HotkeyDisplay.canonicalKey("±") == "section")
    }

    // MARK: - isSupportedKey edge cases

    @Test("empty string is not supported")
    func emptyNotSupported() {
        #expect(HotkeyDisplay.isSupportedKey("") == false)
    }

    @Test("single letter is supported")
    func singleLetterSupported() {
        #expect(HotkeyDisplay.isSupportedKey("a") == true)
        #expect(HotkeyDisplay.isSupportedKey("z") == true)
    }

    @Test("single digit is supported")
    func singleDigitSupported() {
        #expect(HotkeyDisplay.isSupportedKey("0") == true)
        #expect(HotkeyDisplay.isSupportedKey("9") == true)
    }

    @Test("numpad aliases are supported")
    func numpadSupported() {
        #expect(HotkeyDisplay.isSupportedKey("numpad0") == true)
        #expect(HotkeyDisplay.isSupportedKey("numpadplus") == true)
        #expect(HotkeyDisplay.isSupportedKey("numpaddecimal") == true)
    }

    @Test("all function keys are supported")
    func allFunctionKeysSupported() {
        for i in 1...24 {
            #expect(HotkeyDisplay.isSupportedKey("f\(i)") == true)
        }
    }

    // MARK: - comboSummary / summary / summaryIncludingMode

    @Test("summary reads from provided defaults")
    func summaryFromDefaults() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayNormalizeTests.summary")!
        suite.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        let result = HotkeyDisplay.summary(defaults: suite)
        #expect(result.contains("Space") || result.contains("space"))
        suite.removePersistentDomain(forName: "HotkeyDisplayNormalizeTests.summary")
    }

    @Test("summaryIncludingMode includes mode prefix")
    func summaryIncludingModePrefix() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayNormalizeTests.modePrefix")!
        suite.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        suite.set("toggle", forKey: AppDefaults.Keys.hotkeyMode)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        let result = HotkeyDisplay.summaryIncludingMode(defaults: suite)
        #expect(result.hasPrefix("Toggle"))
        suite.removePersistentDomain(forName: "HotkeyDisplayNormalizeTests.modePrefix")
    }

    @Test("summaryIncludingMode hold mode")
    func summaryHoldMode() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayNormalizeTests.hold")!
        suite.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        suite.set("hold", forKey: AppDefaults.Keys.hotkeyMode)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        let result = HotkeyDisplay.summaryIncludingMode(defaults: suite)
        #expect(result.hasPrefix("Hold"))
        suite.removePersistentDomain(forName: "HotkeyDisplayNormalizeTests.hold")
    }

    @Test("summaryIncludingMode invalid mode falls back to toggle")
    func summaryInvalidMode() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayNormalizeTests.invalidMode")!
        suite.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        suite.set("invalid_mode", forKey: AppDefaults.Keys.hotkeyMode)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        let result = HotkeyDisplay.summaryIncludingMode(defaults: suite)
        #expect(result.hasPrefix("Toggle"))
        suite.removePersistentDomain(forName: "HotkeyDisplayNormalizeTests.invalidMode")
    }

    // MARK: - displayKey coverage for special keys

    @Test("displayKey for named keys returns symbols")
    func displayKeySymbols() {
        #expect(HotkeyDisplay.displayKey("space") == "Space")
        #expect(HotkeyDisplay.displayKey("tab") == "Tab")
        #expect(HotkeyDisplay.displayKey("return") == "Return/Enter")
        #expect(HotkeyDisplay.displayKey("escape") == "Esc")
        #expect(HotkeyDisplay.displayKey("delete") == "Delete")
    }

    @Test("displayKey for single character uppercases")
    func displayKeySingleChar() {
        #expect(HotkeyDisplay.displayKey("a") == "A")
        #expect(HotkeyDisplay.displayKey("z") == "Z")
    }

    @Test("displayKey for function keys")
    func displayKeyFunctionKeys() {
        #expect(HotkeyDisplay.displayKey("f1") == "F1")
        #expect(HotkeyDisplay.displayKey("f24") == "F24")
    }
}
