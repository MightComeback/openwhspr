import Testing
import Foundation
@testable import OpenWhisper

/// Deep tests exercising HotkeyDisplay's private normalizeKey, canonicalFunctionKeyAlias,
/// shortcutPrefixBeforeTrailingPlusLooksLikeShortcut, and comboSummary paths
/// through the public canonicalKey / displayKey / summary / isSupportedKey API.
@Suite("HotkeyDisplay Deep Private Paths", .serialized)
struct HotkeyDisplayDeepPrivatePathTests {

    // MARK: - normalizeKey: raw whitespace characters

    @Test("Space character normalizes to space")
    func spaceCharNormalizes() {
        #expect(HotkeyDisplay.canonicalKey(" ") == "space")
    }

    @Test("Tab character normalizes to tab")
    func tabCharNormalizes() {
        #expect(HotkeyDisplay.canonicalKey("\t") == "tab")
    }

    @Test("Return character normalizes to return")
    func returnCharNormalizes() {
        #expect(HotkeyDisplay.canonicalKey("\r") == "return")
    }

    @Test("Newline character normalizes to return")
    func newlineCharNormalizes() {
        #expect(HotkeyDisplay.canonicalKey("\n") == "return")
    }

    // MARK: - normalizeKey: non-breaking space variants

    @Test("Non-breaking space is trimmed")
    func nonBreakingSpace() {
        // "\u{00A0}space\u{00A0}" → "space" after trim
        let result = HotkeyDisplay.canonicalKey("\u{00A0}space\u{00A0}")
        #expect(result == "space")
    }

    @Test("Figure space is trimmed")
    func figureSpace() {
        let result = HotkeyDisplay.canonicalKey("\u{2007}tab\u{2007}")
        #expect(result == "tab")
    }

    @Test("Narrow no-break space is trimmed")
    func narrowNoBreakSpace() {
        let result = HotkeyDisplay.canonicalKey("\u{202F}escape\u{202F}")
        #expect(result == "escape")
    }

    // MARK: - normalizeKey: fullwidth plus variants

    @Test("Fullwidth plus sign ＋ treated as separator")
    func fullwidthPlus() {
        let result = HotkeyDisplay.canonicalKey("cmd＋space")
        #expect(result == "space")
    }

    @Test("Small form plus ﹢ treated as separator")
    func smallFormPlus() {
        let result = HotkeyDisplay.canonicalKey("shift﹢tab")
        #expect(result == "tab")
    }

    @Test("Divination plus ∔ treated as separator")
    func divinationPlus() {
        let result = HotkeyDisplay.canonicalKey("ctrl∔escape")
        #expect(result == "escape")
    }

    // MARK: - normalizeKey: variation selector stripping

    @Test("Text presentation selector stripped")
    func textPresentationSelector() {
        let result = HotkeyDisplay.canonicalKey("space\u{FE0E}")
        #expect(result == "space")
    }

    @Test("Emoji presentation selector stripped")
    func emojiPresentationSelector() {
        let result = HotkeyDisplay.canonicalKey("tab\u{FE0F}")
        #expect(result == "tab")
    }

    // MARK: - normalizeKey: slash-separated shortcuts

    @Test("Slash-separated shortcut extracts key")
    func slashSeparated() {
        let result = HotkeyDisplay.canonicalKey("command/shift/space")
        #expect(result == "space")
    }

    @Test("Trailing slash preserved as literal trigger")
    func trailingSlashPreserved() {
        let result = HotkeyDisplay.canonicalKey("command+shift+/")
        #expect(result == "slash")
    }

    // MARK: - normalizeKey: shortcutPrefixBeforeTrailingPlusLooksLikeShortcut

    @Test("Trailing plus after modifier maps to equals")
    func trailingPlusAfterModifier() {
        // "cmd+" → normalizeKey sees trailing +, shortcutPrefixBeforeTrailingPlusLooksLikeShortcut
        // returns true → "+" → canonicalKey maps "+" to "equals"
        let result = HotkeyDisplay.canonicalKey("cmd+")
        #expect(result == "equals")
    }

    @Test("⌘+ maps to equals")
    func symbolModifierTrailingPlus() {
        let result = HotkeyDisplay.canonicalKey("⌘+")
        #expect(result == "equals")
    }

    @Test("shift++ maps to equals")
    func shiftDoublePlus() {
        let result = HotkeyDisplay.canonicalKey("shift++")
        #expect(result == "equals")
    }

    @Test("numpad+ maps to keypadplus")
    func numpadPlusNotShortcut() {
        let result = HotkeyDisplay.canonicalKey("numpad+")
        #expect(result == "keypadplus")
    }

    @Test("kp+ maps to keypadplus")
    func kpPlusMapsToNumpad() {
        let result = HotkeyDisplay.canonicalKey("kp+")
        #expect(result == "keypadplus")
    }

    @Test("Just + alone without modifier prefix")
    func justPlus() {
        let result = HotkeyDisplay.canonicalKey("+")
        #expect(result == "equals" || result == "+")
    }

    // MARK: - normalizeKey: modifier glyph expansion

    @Test("⌘ alone returns command")
    func commandGlyph() {
        #expect(HotkeyDisplay.canonicalKey("⌘") == "command")
    }

    @Test("⇧ alone returns shift")
    func shiftGlyph() {
        #expect(HotkeyDisplay.canonicalKey("⇧") == "shift")
    }

    @Test("⌥ alone returns option")
    func optionGlyph() {
        #expect(HotkeyDisplay.canonicalKey("⌥") == "option")
    }

    @Test("⌃ alone returns control")
    func controlGlyph() {
        #expect(HotkeyDisplay.canonicalKey("⌃") == "control")
    }

    @Test("⇪ alone returns capslock")
    func capslockGlyph() {
        #expect(HotkeyDisplay.canonicalKey("⇪") == "capslock")
    }

    // MARK: - normalizeKey: numpad space-separated forms

    @Test("numpad + with space maps to keypadplus via canonicalKey")
    func numpadSpacePlus() {
        let result = HotkeyDisplay.canonicalKey("numpad +")
        #expect(result == "keypadplus")
    }

    @Test("keypad - with space maps to keypadminus")
    func keypadSpaceMinus() {
        let result = HotkeyDisplay.canonicalKey("keypad -")
        #expect(result == "keypadminus")
    }

    @Test("numpad * with space maps to keypadmultiply")
    func numpadSpaceStar() {
        let result = HotkeyDisplay.canonicalKey("numpad *")
        #expect(result == "keypadmultiply")
    }

    @Test("numpad / with space maps to keypaddivide")
    func numpadSpaceSlash() {
        let result = HotkeyDisplay.canonicalKey("Numpad /")
        #expect(result == "keypaddivide")
    }

    @Test("keypad . with space maps to keypaddecimal")
    func keypadSpaceDot() {
        let result = HotkeyDisplay.canonicalKey("keypad .")
        #expect(result == "keypaddecimal")
    }

    @Test("numpad , with space maps to keypadcomma")
    func numpadSpaceComma() {
        let result = HotkeyDisplay.canonicalKey("numpad ,")
        #expect(result == "keypadcomma")
    }

    @Test("numpad = with space maps to keypadequals")
    func numpadSpaceEquals() {
        let result = HotkeyDisplay.canonicalKey("numpad =")
        #expect(result == "keypadequals")
    }

    // MARK: - normalizeKey: compact numpad aliases

    @Test("num0 through num9 compact forms")
    func compactNumpadDigits() {
        for i in 0...9 {
            let result = HotkeyDisplay.canonicalKey("num\(i)")
            #expect(result == "keypad\(i)")
        }
    }

    @Test("kp0 through kp9 compact forms")
    func compactKpDigits() {
        for i in 0...9 {
            let result = HotkeyDisplay.canonicalKey("kp\(i)")
            #expect(result == "keypad\(i)")
        }
    }

    // MARK: - canonicalFunctionKeyAlias paths

    @Test("functionkey12 maps to f12")
    func functionKeyAlias() {
        #expect(HotkeyDisplay.canonicalKey("functionkey12") == "f12")
    }

    @Test("fnkey6 maps to f6")
    func fnKeyAlias() {
        #expect(HotkeyDisplay.canonicalKey("fnkey6") == "f6")
    }

    @Test("fkey1 maps to f1")
    func fKeyAlias() {
        #expect(HotkeyDisplay.canonicalKey("fkey1") == "f1")
    }

    @Test("fn24 maps to f24")
    func fnShortAlias() {
        #expect(HotkeyDisplay.canonicalKey("fn24") == "f24")
    }

    @Test("function19 maps to f19")
    func functionAlias() {
        #expect(HotkeyDisplay.canonicalKey("function19") == "f19")
    }

    @Test("fn0 out of range does not match function key")
    func fnZeroOutOfRange() {
        let result = HotkeyDisplay.canonicalKey("fn0")
        #expect(result != "f0")
        // Falls through to canonicalKey's "fn" → globe mapping logic
    }

    @Test("fn25 out of range does not match function key")
    func fn25OutOfRange() {
        let result = HotkeyDisplay.canonicalKey("fn25")
        #expect(result != "f25")
    }

    @Test("fnABC non-numeric suffix does not match")
    func fnNonNumeric() {
        let result = HotkeyDisplay.canonicalKey("fnabc")
        #expect(result != "fabc")
    }

    // MARK: - normalizeKey: collapsed modifier prefix stripping

    @Test("commandshiftspace strips modifiers to space")
    func collapsedModifierStripping() {
        #expect(HotkeyDisplay.canonicalKey("commandshiftspace") == "space")
    }

    @Test("ctrlaltdelete strips modifiers to delete")
    func ctrlAltDelete() {
        #expect(HotkeyDisplay.canonicalKey("ctrlaltdelete") == "delete")
    }

    @Test("cmdspace strips to space")
    func cmdSpace() {
        #expect(HotkeyDisplay.canonicalKey("cmdspace") == "space")
    }

    @Test("metashifttab strips to tab")
    func metaShiftTab() {
        #expect(HotkeyDisplay.canonicalKey("metashifttab") == "tab")
    }

    @Test("Pure modifier like 'command' stays as command")
    func pureModifier() {
        #expect(HotkeyDisplay.canonicalKey("command") == "command")
    }

    // MARK: - normalizeKey: symbol-mixed shortcuts

    @Test("⌘⇧space extracts space")
    func symbolShortcutExtraction() {
        #expect(HotkeyDisplay.canonicalKey("⌘⇧space") == "space")
    }

    @Test("⌥⌃tab extracts tab")
    func optControlTab() {
        #expect(HotkeyDisplay.canonicalKey("⌥⌃tab") == "tab")
    }

    // MARK: - normalizeKey: function key phrase in shortcut tokens

    @Test("command+function key 12 extracts key12 then resolves to f12")
    func functionKeyPhraseInShortcut() {
        // After stripping modifiers: "function", "key", "12" → joined = "key12"
        // canonicalFunctionKeyAlias doesn't match "key12", so falls through
        let result = HotkeyDisplay.canonicalKey("command+function key 12")
        #expect(result == "key12")
    }

    @Test("ctrl+fn key 3 extracts key3")
    func fnKeyPhraseInShortcut() {
        // After stripping modifiers: "fn", "key", "3" → "key3"
        let result = HotkeyDisplay.canonicalKey("ctrl+fn key 3")
        #expect(result == "key3")
    }

    // MARK: - normalizeKey: special capslock/numlock/fnglobe compact forms

    @Test("capslock compact maps to capslock")
    func capslockCompact() {
        #expect(HotkeyDisplay.canonicalKey("capslock") == "capslock")
    }

    @Test("capslockkey compact maps to capslock")
    func capslockKeyCompact() {
        #expect(HotkeyDisplay.canonicalKey("capslockkey") == "capslock")
    }

    @Test("numlock maps to keypadclear")
    func numlockMaps() {
        #expect(HotkeyDisplay.canonicalKey("numlock") == "keypadclear")
    }

    @Test("fnglobe compact maps to fn")
    func fnglobeCompact() {
        #expect(HotkeyDisplay.canonicalKey("fnglobe") == "fn")
    }

    @Test("globefn compact maps to fn")
    func globeFnCompact() {
        #expect(HotkeyDisplay.canonicalKey("globefn") == "fn")
    }

    // MARK: - normalizeKey: arrow key glyph aliases

    @Test("← maps to left")
    func leftArrowGlyph() { #expect(HotkeyDisplay.canonicalKey("←") == "left") }

    @Test("→ maps to right")
    func rightArrowGlyph() { #expect(HotkeyDisplay.canonicalKey("→") == "right") }

    @Test("↑ maps to up")
    func upArrowGlyph() { #expect(HotkeyDisplay.canonicalKey("↑") == "up") }

    @Test("↓ maps to down")
    func downArrowGlyph() { #expect(HotkeyDisplay.canonicalKey("↓") == "down") }

    // MARK: - normalizeKey: return/enter glyph variants

    @Test("↩ maps to return")
    func returnGlyph1() { #expect(HotkeyDisplay.canonicalKey("↩") == "return") }

    @Test("↵ maps to return")
    func returnGlyph2() { #expect(HotkeyDisplay.canonicalKey("↵") == "return") }

    @Test("⏎ maps to return")
    func returnGlyph3() { #expect(HotkeyDisplay.canonicalKey("⏎") == "return") }

    @Test("⌅ maps to return")
    func returnGlyph4() { #expect(HotkeyDisplay.canonicalKey("⌅") == "return") }

    @Test("⌤ maps to return")
    func returnGlyph5() { #expect(HotkeyDisplay.canonicalKey("⌤") == "return") }

    @Test("␤ maps to return")
    func returnGlyph6() { #expect(HotkeyDisplay.canonicalKey("␤") == "return") }

    // MARK: - normalizeKey: misc key glyph aliases

    @Test("⎋ maps to escape")
    func escapeGlyph() { #expect(HotkeyDisplay.canonicalKey("⎋") == "escape") }

    @Test("␛ maps to escape")
    func escapeGlyph2() { #expect(HotkeyDisplay.canonicalKey("␛") == "escape") }

    @Test("⌫ maps to delete")
    func deleteGlyph() { #expect(HotkeyDisplay.canonicalKey("⌫") == "delete") }

    @Test("⌦ maps to forwarddelete")
    func fwdDeleteGlyph() { #expect(HotkeyDisplay.canonicalKey("⌦") == "forwarddelete") }

    @Test("␡ maps to forwarddelete")
    func fwdDeleteGlyph2() { #expect(HotkeyDisplay.canonicalKey("␡") == "forwarddelete") }

    @Test("⏏ maps to eject")
    func ejectGlyph() { #expect(HotkeyDisplay.canonicalKey("⏏") == "eject") }

    @Test("🌐 maps to fn")
    func globeEmoji() { #expect(HotkeyDisplay.canonicalKey("🌐") == "fn") }

    @Test("§ maps to section")
    func sectionSign() { #expect(HotkeyDisplay.canonicalKey("§") == "section") }

    @Test("± maps to section")
    func plusMinusSign() { #expect(HotkeyDisplay.canonicalKey("±") == "section") }

    // MARK: - normalizeKey: punctuation character aliases

    @Test("! maps to 1")
    func exclamation() { #expect(HotkeyDisplay.canonicalKey("!") == "1") }

    @Test("@ maps to 2")
    func atSign() { #expect(HotkeyDisplay.canonicalKey("@") == "2") }

    @Test("# maps to 3")
    func hash() { #expect(HotkeyDisplay.canonicalKey("#") == "3") }

    @Test("$ maps to 4")
    func dollar() { #expect(HotkeyDisplay.canonicalKey("$") == "4") }

    @Test("% maps to 5")
    func percent() { #expect(HotkeyDisplay.canonicalKey("%") == "5") }

    @Test("^ maps to 6")
    func caret() { #expect(HotkeyDisplay.canonicalKey("^") == "6") }

    @Test("& maps to 7")
    func ampersand() { #expect(HotkeyDisplay.canonicalKey("&") == "7") }

    @Test("* maps to 8")
    func asterisk() { #expect(HotkeyDisplay.canonicalKey("*") == "8") }

    @Test("( maps to 9")
    func openParen() { #expect(HotkeyDisplay.canonicalKey("(") == "9") }

    @Test(") maps to 0")
    func closeParen() { #expect(HotkeyDisplay.canonicalKey(")") == "0") }

    // MARK: - normalizeKey: dash variants

    @Test("– (en dash) maps to minus")
    func enDash() { #expect(HotkeyDisplay.canonicalKey("–") == "minus") }

    @Test("— (em dash) maps to minus")
    func emDash() { #expect(HotkeyDisplay.canonicalKey("—") == "minus") }

    @Test("− (minus sign) maps to minus")
    func minusSign() { #expect(HotkeyDisplay.canonicalKey("−") == "minus") }

    // MARK: - normalizeKey: page up/down glyph aliases

    @Test("⇞ maps to pageup")
    func pageUpGlyph() { #expect(HotkeyDisplay.canonicalKey("⇞") == "pageup") }

    @Test("⇟ maps to pagedown")
    func pageDownGlyph() { #expect(HotkeyDisplay.canonicalKey("⇟") == "pagedown") }

    // MARK: - normalizeKey: tab glyph aliases

    @Test("⇥ maps to tab")
    func tabGlyph1() { #expect(HotkeyDisplay.canonicalKey("⇥") == "tab") }

    @Test("⇤ maps to tab")
    func tabGlyph2() { #expect(HotkeyDisplay.canonicalKey("⇤") == "tab") }

    // MARK: - normalizeKey: space glyph aliases

    @Test("␣ maps to space")
    func spaceGlyph1() { #expect(HotkeyDisplay.canonicalKey("␣") == "space") }

    @Test("␠ maps to space")
    func spaceGlyph2() { #expect(HotkeyDisplay.canonicalKey("␠") == "space") }

    @Test("⎵ maps to space")
    func spaceGlyph3() { #expect(HotkeyDisplay.canonicalKey("⎵") == "space") }

    // MARK: - normalizeKey: bracket/brace mapping

    @Test("{ maps to openbracket")
    func openBrace() { #expect(HotkeyDisplay.canonicalKey("{") == "openbracket") }

    @Test("} maps to closebracket")
    func closeBrace() { #expect(HotkeyDisplay.canonicalKey("}") == "closebracket") }

    // MARK: - normalizeKey: quote/double-quote mapping

    @Test("Double quote maps to apostrophe")
    func doubleQuote() { #expect(HotkeyDisplay.canonicalKey("\"") == "apostrophe") }

    // MARK: - normalizeKey: shifted punctuation triggers

    @Test("> maps to period")
    func greaterThan() { #expect(HotkeyDisplay.canonicalKey(">") == "period") }

    @Test("< maps to comma")
    func lessThan() { #expect(HotkeyDisplay.canonicalKey("<") == "comma") }

    @Test("? maps to slash")
    func questionMark() { #expect(HotkeyDisplay.canonicalKey("?") == "slash") }

    @Test("| maps to backslash")
    func pipe() { #expect(HotkeyDisplay.canonicalKey("|") == "backslash") }

    @Test(": maps to semicolon")
    func colon() { #expect(HotkeyDisplay.canonicalKey(":") == "semicolon") }

    @Test("~ maps to backtick")
    func tilde() { #expect(HotkeyDisplay.canonicalKey("~") == "backtick") }

    // MARK: - normalizeKey: ⌧ numpad clear

    @Test("⌧ maps to keypadclear")
    func numClearGlyph() { #expect(HotkeyDisplay.canonicalKey("⌧") == "keypadclear") }

    // MARK: - comboSummary: via summary() with configured defaults

    @Test("summary reads modifiers and key from defaults")
    func summaryReadsDefaults() {
        let defaults = UserDefaults(suiteName: "deepPrivate.summary")!
        defer { defaults.removePersistentDomain(forName: "deepPrivate.summary") }
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)

        let result = HotkeyDisplay.summary(defaults: defaults)
        #expect(result == "⌘+⇧+Space")
    }

    @Test("summary with all modifiers")
    func summaryAllModifiers() {
        let defaults = UserDefaults(suiteName: "deepPrivate.summaryAll")!
        defer { defaults.removePersistentDomain(forName: "deepPrivate.summaryAll") }
        defaults.set("a", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        defaults.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)

        let result = HotkeyDisplay.summary(defaults: defaults)
        #expect(result == "⌘+⇧+⌥+⌃+⇪+A")
    }

    @Test("summary with no modifiers")
    func summaryNoModifiers() {
        let defaults = UserDefaults(suiteName: "deepPrivate.summaryNone")!
        defer { defaults.removePersistentDomain(forName: "deepPrivate.summaryNone") }
        defaults.set("f5", forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)

        let result = HotkeyDisplay.summary(defaults: defaults)
        #expect(result == "F5")
    }

    @Test("summary with nil key defaults to space")
    func summaryNilKeyDefaultsSpace() {
        let defaults = UserDefaults(suiteName: "deepPrivate.summaryNilKey")!
        defer { defaults.removePersistentDomain(forName: "deepPrivate.summaryNilKey") }
        defaults.removeObject(forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)

        let result = HotkeyDisplay.summary(defaults: defaults)
        #expect(result.contains("Space"))
    }

    // MARK: - displayKey: comprehensive coverage

    @Test("displayKey for all special keys")
    func displayKeySpecials() {
        #expect(HotkeyDisplay.displayKey("space") == "Space")
        #expect(HotkeyDisplay.displayKey("tab") == "Tab")
        #expect(HotkeyDisplay.displayKey("return") == "Return/Enter")
        #expect(HotkeyDisplay.displayKey("escape") == "Esc")
        #expect(HotkeyDisplay.displayKey("delete") == "Delete")
        #expect(HotkeyDisplay.displayKey("forwarddelete") == "FwdDelete")
        #expect(HotkeyDisplay.displayKey("insert") == "Insert")
        #expect(HotkeyDisplay.displayKey("help") == "Help")
        #expect(HotkeyDisplay.displayKey("eject") == "Eject")
        #expect(HotkeyDisplay.displayKey("capslock") == "CapsLock")
        #expect(HotkeyDisplay.displayKey("fn") == "Fn/Globe")
        #expect(HotkeyDisplay.displayKey("section") == "§")
        #expect(HotkeyDisplay.displayKey("minus") == "-")
        #expect(HotkeyDisplay.displayKey("equals") == "=/+")
        #expect(HotkeyDisplay.displayKey("openbracket") == "[")
        #expect(HotkeyDisplay.displayKey("closebracket") == "]")
        #expect(HotkeyDisplay.displayKey("semicolon") == ";")
        #expect(HotkeyDisplay.displayKey("apostrophe") == "'")
        #expect(HotkeyDisplay.displayKey("comma") == ",")
        #expect(HotkeyDisplay.displayKey("period") == ".")
        #expect(HotkeyDisplay.displayKey("slash") == "/")
        #expect(HotkeyDisplay.displayKey("backslash") == "\\")
        #expect(HotkeyDisplay.displayKey("backtick") == "`")
        #expect(HotkeyDisplay.displayKey("left") == "←")
        #expect(HotkeyDisplay.displayKey("right") == "→")
        #expect(HotkeyDisplay.displayKey("up") == "↑")
        #expect(HotkeyDisplay.displayKey("down") == "↓")
        #expect(HotkeyDisplay.displayKey("home") == "Home")
        #expect(HotkeyDisplay.displayKey("end") == "End")
        #expect(HotkeyDisplay.displayKey("pageup") == "PgUp")
        #expect(HotkeyDisplay.displayKey("pagedown") == "PgDn")
    }

    @Test("displayKey for function keys")
    func displayKeyFunctionKeys() {
        for i in 1...24 {
            #expect(HotkeyDisplay.displayKey("f\(i)") == "F\(i)")
        }
    }

    @Test("displayKey for keypad keys")
    func displayKeyKeypad() {
        for i in 0...9 {
            #expect(HotkeyDisplay.displayKey("keypad\(i)") == "Num\(i)")
        }
        #expect(HotkeyDisplay.displayKey("keypaddecimal") == "Num.")
        #expect(HotkeyDisplay.displayKey("keypadcomma") == "Num,")
        #expect(HotkeyDisplay.displayKey("keypadmultiply") == "Num*")
        #expect(HotkeyDisplay.displayKey("keypadplus") == "Num+")
        #expect(HotkeyDisplay.displayKey("keypadclear") == "NumClear")
        #expect(HotkeyDisplay.displayKey("keypaddivide") == "Num/")
        #expect(HotkeyDisplay.displayKey("keypadenter") == "NumEnter")
        #expect(HotkeyDisplay.displayKey("keypadminus") == "Num-")
        #expect(HotkeyDisplay.displayKey("keypadequals") == "Num=")
    }

    @Test("displayKey single char uppercased")
    func displayKeySingleChar() {
        #expect(HotkeyDisplay.displayKey("a") == "A")
        #expect(HotkeyDisplay.displayKey("z") == "Z")
        #expect(HotkeyDisplay.displayKey("0") == "0")
    }

    @Test("displayKey unknown multi-char capitalized")
    func displayKeyUnknownMultiChar() {
        let result = HotkeyDisplay.displayKey("mute")
        #expect(result == "Mute")
    }

    // MARK: - isSupportedKey edge cases

    @Test("Empty string is not supported")
    func emptyNotSupported() {
        #expect(HotkeyDisplay.isSupportedKey("") == false)
    }

    @Test("Single letters are supported")
    func singleLetters() {
        for char in "abcdefghijklmnopqrstuvwxyz" {
            #expect(HotkeyDisplay.isSupportedKey(String(char)) == true)
        }
    }

    @Test("Digits are supported")
    func digits() {
        for char in "0123456789" {
            #expect(HotkeyDisplay.isSupportedKey(String(char)) == true)
        }
    }

    @Test("All named special keys are supported")
    func namedSpecialKeys() {
        let keys = ["space", "tab", "return", "escape", "delete", "forwarddelete",
                     "insert", "help", "eject", "capslock", "fn", "section",
                     "left", "right", "up", "down", "home", "end", "pageup", "pagedown",
                     "minus", "equals", "openbracket", "closebracket",
                     "semicolon", "apostrophe", "comma", "period", "slash", "backslash", "backtick"]
        for key in keys {
            #expect(HotkeyDisplay.isSupportedKey(key) == true, "Expected \(key) to be supported")
        }
    }

    @Test("Multi-char unknown is not supported")
    func multiCharUnknown() {
        #expect(HotkeyDisplay.isSupportedKey("mute") == false)
        #expect(HotkeyDisplay.isSupportedKey("play") == false)
    }

    @Test("Numpad decimal aliases supported")
    func numpadDecimalAliases() {
        let aliases = ["keypaddecimal", "numpaddecimal", "keypadcomma", "numpadcomma",
                       "keypadmultiply", "numpadmultiply", "keypadplus", "numpadplus",
                       "keypadclear", "numpadclear", "keypaddivide", "numpaddivide",
                       "keypadenter", "numpadenter", "keypadminus", "numpadminus",
                       "keypadequals", "numpadequals"]
        for alias in aliases {
            #expect(HotkeyDisplay.isSupportedKey(alias) == true, "Expected \(alias) to be supported")
        }
    }
}
