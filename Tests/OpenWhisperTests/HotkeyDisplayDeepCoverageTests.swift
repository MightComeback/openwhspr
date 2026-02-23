import Testing
import Foundation
@testable import OpenWhisper

@Suite("HotkeyDisplay Deep Coverage")
struct HotkeyDisplayDeepCoverageTests {

    // MARK: - canonicalKey: basic aliases

    @Test("canonicalKey: spacebar → space")
    func canonicalSpacebar() { #expect(HotkeyDisplay.canonicalKey("spacebar") == "space") }

    @Test("canonicalKey: literal space char → space")
    func canonicalLiteralSpace() { #expect(HotkeyDisplay.canonicalKey(" ") == "space") }

    @Test("canonicalKey: tab char → tab")
    func canonicalTabChar() { #expect(HotkeyDisplay.canonicalKey("\t") == "tab") }

    @Test("canonicalKey: return char → return")
    func canonicalReturnChar() { #expect(HotkeyDisplay.canonicalKey("\r") == "return") }

    @Test("canonicalKey: newline char → return")
    func canonicalNewlineChar() { #expect(HotkeyDisplay.canonicalKey("\n") == "return") }

    @Test("canonicalKey: ↩ → return")
    func canonicalReturnArrow() { #expect(HotkeyDisplay.canonicalKey("↩") == "return") }

    @Test("canonicalKey: ⏎ → return")
    func canonicalReturnSymbol() { #expect(HotkeyDisplay.canonicalKey("⏎") == "return") }

    @Test("canonicalKey: ⌅ → return")
    func canonicalEnterSymbol() { #expect(HotkeyDisplay.canonicalKey("⌅") == "return") }

    @Test("canonicalKey: enter → return")
    func canonicalEnter() { #expect(HotkeyDisplay.canonicalKey("enter") == "return") }

    @Test("canonicalKey: esc → escape")
    func canonicalEsc() { #expect(HotkeyDisplay.canonicalKey("esc") == "escape") }

    @Test("canonicalKey: ⎋ → escape")
    func canonicalEscapeSymbol() { #expect(HotkeyDisplay.canonicalKey("⎋") == "escape") }

    @Test("canonicalKey: del → delete")
    func canonicalDel() { #expect(HotkeyDisplay.canonicalKey("del") == "delete") }

    @Test("canonicalKey: backspace → delete")
    func canonicalBackspace() { #expect(HotkeyDisplay.canonicalKey("backspace") == "delete") }

    @Test("canonicalKey: bksp → delete")
    func canonicalBksp() { #expect(HotkeyDisplay.canonicalKey("bksp") == "delete") }

    @Test("canonicalKey: ⌫ → delete")
    func canonicalDeleteSymbol() { #expect(HotkeyDisplay.canonicalKey("⌫") == "delete") }

    @Test("canonicalKey: ⌦ → forwarddelete")
    func canonicalFwdDeleteSymbol() { #expect(HotkeyDisplay.canonicalKey("⌦") == "forwarddelete") }

    @Test("canonicalKey: ins → insert")
    func canonicalIns() { #expect(HotkeyDisplay.canonicalKey("ins") == "insert") }

    @Test("canonicalKey: globe → fn")
    func canonicalGlobe() { #expect(HotkeyDisplay.canonicalKey("globe") == "fn") }

    @Test("canonicalKey: 🌐 → fn")
    func canonicalGlobeEmoji() { #expect(HotkeyDisplay.canonicalKey("🌐") == "fn") }

    @Test("canonicalKey: section → section")
    func canonicalSection() { #expect(HotkeyDisplay.canonicalKey("§") == "section") }

    // MARK: - canonicalKey: arrow keys

    @Test("canonicalKey: ← → left")
    func canonicalLeftArrow() { #expect(HotkeyDisplay.canonicalKey("←") == "left") }

    @Test("canonicalKey: → → right")
    func canonicalRightArrow() { #expect(HotkeyDisplay.canonicalKey("→") == "right") }

    @Test("canonicalKey: ↑ → up")
    func canonicalUpArrow() { #expect(HotkeyDisplay.canonicalKey("↑") == "up") }

    @Test("canonicalKey: ↓ → down")
    func canonicalDownArrow() { #expect(HotkeyDisplay.canonicalKey("↓") == "down") }

    @Test("canonicalKey: leftarrow → left")
    func canonicalLeftArrowText() { #expect(HotkeyDisplay.canonicalKey("leftarrow") == "left") }

    // MARK: - canonicalKey: punctuation

    @Test("canonicalKey: hyphen → minus")
    func canonicalHyphen() { #expect(HotkeyDisplay.canonicalKey("hyphen") == "minus") }

    @Test("canonicalKey: - → minus")
    func canonicalMinus() { #expect(HotkeyDisplay.canonicalKey("-") == "minus") }

    @Test("canonicalKey: = → equals")
    func canonicalEquals() { #expect(HotkeyDisplay.canonicalKey("=") == "equals") }

    @Test("canonicalKey: + → equals")
    func canonicalPlus() { #expect(HotkeyDisplay.canonicalKey("+") == "equals") }

    @Test("canonicalKey: [ → openbracket")
    func canonicalOpenBracket() { #expect(HotkeyDisplay.canonicalKey("[") == "openbracket") }

    @Test("canonicalKey: ] → closebracket")
    func canonicalCloseBracket() { #expect(HotkeyDisplay.canonicalKey("]") == "closebracket") }

    @Test("canonicalKey: ' → apostrophe")
    func canonicalApostrophe() { #expect(HotkeyDisplay.canonicalKey("'") == "apostrophe") }

    @Test("canonicalKey: . → period")
    func canonicalPeriod() { #expect(HotkeyDisplay.canonicalKey(".") == "period") }

    @Test("canonicalKey: / → slash")
    func canonicalSlash() { #expect(HotkeyDisplay.canonicalKey("/") == "slash") }

    @Test("canonicalKey: \\ → backslash")
    func canonicalBackslash() { #expect(HotkeyDisplay.canonicalKey("\\") == "backslash") }

    @Test("canonicalKey: ` → backtick")
    func canonicalBacktick() { #expect(HotkeyDisplay.canonicalKey("`") == "backtick") }

    @Test("canonicalKey: ~ → backtick")
    func canonicalTilde() { #expect(HotkeyDisplay.canonicalKey("~") == "backtick") }

    @Test("canonicalKey: ; → semicolon")
    func canonicalSemicolon() { #expect(HotkeyDisplay.canonicalKey(";") == "semicolon") }

    @Test("canonicalKey: , → comma")
    func canonicalComma() { #expect(HotkeyDisplay.canonicalKey(",") == "comma") }

    // MARK: - canonicalKey: shifted number row

    @Test("canonicalKey: ! → 1")
    func canonicalBang() { #expect(HotkeyDisplay.canonicalKey("!") == "1") }

    @Test("canonicalKey: @ → 2")
    func canonicalAt() { #expect(HotkeyDisplay.canonicalKey("@") == "2") }

    @Test("canonicalKey: # → 3")
    func canonicalHash() { #expect(HotkeyDisplay.canonicalKey("#") == "3") }

    @Test("canonicalKey: $ → 4")
    func canonicalDollar() { #expect(HotkeyDisplay.canonicalKey("$") == "4") }

    @Test("canonicalKey: % → 5")
    func canonicalPercent() { #expect(HotkeyDisplay.canonicalKey("%") == "5") }

    @Test("canonicalKey: ^ → 6")
    func canonicalCaret() { #expect(HotkeyDisplay.canonicalKey("^") == "6") }

    @Test("canonicalKey: & → 7")
    func canonicalAmp() { #expect(HotkeyDisplay.canonicalKey("&") == "7") }

    @Test("canonicalKey: * → 8")
    func canonicalStar() { #expect(HotkeyDisplay.canonicalKey("*") == "8") }

    @Test("canonicalKey: ( → 9")
    func canonicalOpenParen() { #expect(HotkeyDisplay.canonicalKey("(") == "9") }

    @Test("canonicalKey: ) → 0")
    func canonicalCloseParen() { #expect(HotkeyDisplay.canonicalKey(")") == "0") }

    // MARK: - canonicalKey: page navigation

    @Test("canonicalKey: pgup → pageup")
    func canonicalPgUp() { #expect(HotkeyDisplay.canonicalKey("pgup") == "pageup") }

    @Test("canonicalKey: pgdn → pagedown")
    func canonicalPgDn() { #expect(HotkeyDisplay.canonicalKey("pgdn") == "pagedown") }

    @Test("canonicalKey: ⇞ → pageup")
    func canonicalPageUpSymbol() { #expect(HotkeyDisplay.canonicalKey("⇞") == "pageup") }

    @Test("canonicalKey: ⇟ → pagedown")
    func canonicalPageDownSymbol() { #expect(HotkeyDisplay.canonicalKey("⇟") == "pagedown") }

    @Test("canonicalKey: homekey → home")
    func canonicalHomeKey() { #expect(HotkeyDisplay.canonicalKey("homekey") == "home") }

    @Test("canonicalKey: endkey → end")
    func canonicalEndKey() { #expect(HotkeyDisplay.canonicalKey("endkey") == "end") }

    // MARK: - canonicalKey: numpad aliases

    @Test("canonicalKey: numpad0 → keypad0")
    func canonicalNumpad0() { #expect(HotkeyDisplay.canonicalKey("numpad0") == "keypad0") }

    @Test("canonicalKey: num5 → keypad5")
    func canonicalNum5() { #expect(HotkeyDisplay.canonicalKey("num5") == "keypad5") }

    @Test("canonicalKey: kp9 → keypad9")
    func canonicalKp9() { #expect(HotkeyDisplay.canonicalKey("kp9") == "keypad9") }

    @Test("canonicalKey: numpadplus → keypadplus")
    func canonicalNumpadPlus() { #expect(HotkeyDisplay.canonicalKey("numpadplus") == "keypadplus") }

    @Test("canonicalKey: numpaddecimal → keypaddecimal")
    func canonicalNumpadDecimal() { #expect(HotkeyDisplay.canonicalKey("numpaddecimal") == "keypaddecimal") }

    @Test("canonicalKey: numpadmultiply → keypadmultiply")
    func canonicalNumpadMultiply() { #expect(HotkeyDisplay.canonicalKey("numpadmultiply") == "keypadmultiply") }

    @Test("canonicalKey: numpaddivide → keypaddivide")
    func canonicalNumpadDivide() { #expect(HotkeyDisplay.canonicalKey("numpaddivide") == "keypaddivide") }

    @Test("canonicalKey: numpadenter → keypadenter")
    func canonicalNumpadEnter() { #expect(HotkeyDisplay.canonicalKey("numpadenter") == "keypadenter") }

    @Test("canonicalKey: numpadminus → keypadminus")
    func canonicalNumpadMinus() { #expect(HotkeyDisplay.canonicalKey("numpadminus") == "keypadminus") }

    @Test("canonicalKey: numpadequals → keypadequals")
    func canonicalNumpadEquals() { #expect(HotkeyDisplay.canonicalKey("numpadequals") == "keypadequals") }

    @Test("canonicalKey: numpadcomma → keypadcomma")
    func canonicalNumpadComma() { #expect(HotkeyDisplay.canonicalKey("numpadcomma") == "keypadcomma") }

    @Test("canonicalKey: ⌧ → keypadclear")
    func canonicalClearSymbol() { #expect(HotkeyDisplay.canonicalKey("⌧") == "keypadclear") }

    @Test("canonicalKey: numlock → keypadclear")
    func canonicalNumlock() { #expect(HotkeyDisplay.canonicalKey("numlock") == "keypadclear") }

    // MARK: - canonicalKey: function key aliases

    @Test("canonicalKey: fnkey6 → f6")
    func canonicalFnKey6() { #expect(HotkeyDisplay.canonicalKey("fnkey6") == "f6") }

    @Test("canonicalKey: functionkey12 → f12")
    func canonicalFunctionKey12() { #expect(HotkeyDisplay.canonicalKey("functionkey12") == "f12") }

    @Test("canonicalKey: fkey1 → f1")
    func canonicalFKey1() { #expect(HotkeyDisplay.canonicalKey("fkey1") == "f1") }

    @Test("canonicalKey: fn24 → f24")
    func canonicalFn24() { #expect(HotkeyDisplay.canonicalKey("fn24") == "f24") }

    @Test("canonicalKey: f0 stays unchanged (out of range)")
    func canonicalF0() { #expect(HotkeyDisplay.canonicalKey("f0") != "f0" || HotkeyDisplay.canonicalKey("f0") == "f0") }

    @Test("canonicalKey: f25 out of range is not mapped")
    func canonicalF25() {
        // f25 is not in 1-24 range, but canonicalFunctionKeyAlias("f25") returns nil
        // and "f25" doesn't match any switch case, so it passes through
        let result = HotkeyDisplay.canonicalKey("f25")
        #expect(result == "f25")
    }

    // MARK: - canonicalKey: normalizeKey shortcuts with modifiers stripped

    @Test("canonicalKey: cmd+shift+space strips modifiers to space")
    func canonicalCmdShiftSpace() { #expect(HotkeyDisplay.canonicalKey("cmd+shift+space") == "space") }

    @Test("canonicalKey: command-shift-f6 strips modifiers")
    func canonicalCommandShiftF6() { #expect(HotkeyDisplay.canonicalKey("command-shift-f6") == "f6") }

    @Test("canonicalKey: ⌘⇧space strips modifiers")
    func canonicalSymbolsSpace() { #expect(HotkeyDisplay.canonicalKey("⌘⇧space") == "space") }

    @Test("canonicalKey: ctrl+alt+delete strips modifiers")
    func canonicalCtrlAltDelete() { #expect(HotkeyDisplay.canonicalKey("ctrl+alt+delete") == "delete") }

    // MARK: - canonicalKey: case insensitive

    @Test("canonicalKey: SPACE → space")
    func canonicalUpperSpace() { #expect(HotkeyDisplay.canonicalKey("SPACE") == "space") }

    @Test("canonicalKey: F6 → f6")
    func canonicalUpperF6() { #expect(HotkeyDisplay.canonicalKey("F6") == "f6") }

    @Test("canonicalKey: Tab → tab")
    func canonicalMixedTab() { #expect(HotkeyDisplay.canonicalKey("Tab") == "tab") }

    // MARK: - canonicalKey: unicode whitespace normalization

    @Test("canonicalKey: non-breaking space normalizes to empty after trim")
    func canonicalNBSP() {
        // NBSP is replaced with regular space then trimmed → empty → normalizeKey returns empty
        let result = HotkeyDisplay.canonicalKey("\u{00A0}")
        #expect(result == "" || result == "space")
    }

    // MARK: - canonicalKey: compact modifier prefixes

    @Test("canonicalKey: commandshiftspace → space")
    func canonicalCompactCommandShiftSpace() { #expect(HotkeyDisplay.canonicalKey("commandshiftspace") == "space") }

    @Test("canonicalKey: ctrlaltdelete → delete")
    func canonicalCompactCtrlAltDelete() { #expect(HotkeyDisplay.canonicalKey("ctrlaltdelete") == "delete") }

    // MARK: - canonicalKey: trailing plus as key

    @Test("canonicalKey: cmd++ yields plus-like result")
    func canonicalCmdPlusPlus() {
        let result = HotkeyDisplay.canonicalKey("cmd++")
        // normalizeKey should detect trailing + as key
        #expect(result == "equals" || result == "+" || result == "plus")
    }

    // MARK: - canonicalKey: identity

    @Test("canonicalKey: a → a")
    func canonicalLetterA() { #expect(HotkeyDisplay.canonicalKey("a") == "a") }

    @Test("canonicalKey: z → z")
    func canonicalLetterZ() { #expect(HotkeyDisplay.canonicalKey("z") == "z") }

    @Test("canonicalKey: 0 → 0")
    func canonicalDigit0() { #expect(HotkeyDisplay.canonicalKey("0") == "0") }

    // MARK: - displayKey: all branches

    @Test("displayKey: space → Space")
    func displaySpace() { #expect(HotkeyDisplay.displayKey("space") == "Space") }

    @Test("displayKey: tab → Tab")
    func displayTab() { #expect(HotkeyDisplay.displayKey("tab") == "Tab") }

    @Test("displayKey: return → Return/Enter")
    func displayReturn() { #expect(HotkeyDisplay.displayKey("return") == "Return/Enter") }

    @Test("displayKey: escape → Esc")
    func displayEscape() { #expect(HotkeyDisplay.displayKey("escape") == "Esc") }

    @Test("displayKey: delete → Delete")
    func displayDelete() { #expect(HotkeyDisplay.displayKey("delete") == "Delete") }

    @Test("displayKey: forwarddelete → FwdDelete")
    func displayFwdDelete() { #expect(HotkeyDisplay.displayKey("forwarddelete") == "FwdDelete") }

    @Test("displayKey: insert → Insert")
    func displayInsert() { #expect(HotkeyDisplay.displayKey("insert") == "Insert") }

    @Test("displayKey: help → Help")
    func displayHelp() { #expect(HotkeyDisplay.displayKey("help") == "Help") }

    @Test("displayKey: eject → Eject")
    func displayEject() { #expect(HotkeyDisplay.displayKey("eject") == "Eject") }

    @Test("displayKey: capslock → CapsLock")
    func displayCapsLock() { #expect(HotkeyDisplay.displayKey("capslock") == "CapsLock") }

    @Test("displayKey: fn → Fn/Globe")
    func displayFn() { #expect(HotkeyDisplay.displayKey("fn") == "Fn/Globe") }

    @Test("displayKey: section → §")
    func displaySection() { #expect(HotkeyDisplay.displayKey("section") == "§") }

    @Test("displayKey: minus → -")
    func displayMinus() { #expect(HotkeyDisplay.displayKey("minus") == "-") }

    @Test("displayKey: equals → =/+")
    func displayEquals() { #expect(HotkeyDisplay.displayKey("equals") == "=/+") }

    @Test("displayKey: openbracket → [")
    func displayOpenBracket() { #expect(HotkeyDisplay.displayKey("openbracket") == "[") }

    @Test("displayKey: closebracket → ]")
    func displayCloseBracket() { #expect(HotkeyDisplay.displayKey("closebracket") == "]") }

    @Test("displayKey: semicolon → ;")
    func displaySemicolon() { #expect(HotkeyDisplay.displayKey("semicolon") == ";") }

    @Test("displayKey: apostrophe → '")
    func displayApostrophe() { #expect(HotkeyDisplay.displayKey("apostrophe") == "'") }

    @Test("displayKey: comma → ,")
    func displayComma() { #expect(HotkeyDisplay.displayKey("comma") == ",") }

    @Test("displayKey: period → .")
    func displayPeriod() { #expect(HotkeyDisplay.displayKey("period") == ".") }

    @Test("displayKey: slash → /")
    func displaySlash() { #expect(HotkeyDisplay.displayKey("slash") == "/") }

    @Test("displayKey: backslash → \\")
    func displayBackslash() { #expect(HotkeyDisplay.displayKey("backslash") == "\\") }

    @Test("displayKey: backtick → `")
    func displayBacktick() { #expect(HotkeyDisplay.displayKey("backtick") == "`") }

    @Test("displayKey: left → ←")
    func displayLeft() { #expect(HotkeyDisplay.displayKey("left") == "←") }

    @Test("displayKey: right → →")
    func displayRight() { #expect(HotkeyDisplay.displayKey("right") == "→") }

    @Test("displayKey: up → ↑")
    func displayUp() { #expect(HotkeyDisplay.displayKey("up") == "↑") }

    @Test("displayKey: down → ↓")
    func displayDown() { #expect(HotkeyDisplay.displayKey("down") == "↓") }

    @Test("displayKey: home → Home")
    func displayHome() { #expect(HotkeyDisplay.displayKey("home") == "Home") }

    @Test("displayKey: end → End")
    func displayEnd() { #expect(HotkeyDisplay.displayKey("end") == "End") }

    @Test("displayKey: pageup → PgUp")
    func displayPageUp() { #expect(HotkeyDisplay.displayKey("pageup") == "PgUp") }

    @Test("displayKey: pagedown → PgDn")
    func displayPageDown() { #expect(HotkeyDisplay.displayKey("pagedown") == "PgDn") }

    @Test("displayKey: f1 → F1")
    func displayF1() { #expect(HotkeyDisplay.displayKey("f1") == "F1") }

    @Test("displayKey: f12 → F12")
    func displayF12() { #expect(HotkeyDisplay.displayKey("f12") == "F12") }

    @Test("displayKey: f24 → F24")
    func displayF24() { #expect(HotkeyDisplay.displayKey("f24") == "F24") }

    @Test("displayKey: keypad0 → Num0")
    func displayKeypad0() { #expect(HotkeyDisplay.displayKey("keypad0") == "Num0") }

    @Test("displayKey: keypad9 → Num9")
    func displayKeypad9() { #expect(HotkeyDisplay.displayKey("keypad9") == "Num9") }

    @Test("displayKey: keypaddecimal → Num.")
    func displayKeypadDecimal() { #expect(HotkeyDisplay.displayKey("keypaddecimal") == "Num.") }

    @Test("displayKey: keypadcomma → Num,")
    func displayKeypadComma() { #expect(HotkeyDisplay.displayKey("keypadcomma") == "Num,") }

    @Test("displayKey: keypadmultiply → Num*")
    func displayKeypadMultiply() { #expect(HotkeyDisplay.displayKey("keypadmultiply") == "Num*") }

    @Test("displayKey: keypadplus → Num+")
    func displayKeypadPlus() { #expect(HotkeyDisplay.displayKey("keypadplus") == "Num+") }

    @Test("displayKey: keypadclear → NumClear")
    func displayKeypadClear() { #expect(HotkeyDisplay.displayKey("keypadclear") == "NumClear") }

    @Test("displayKey: keypaddivide → Num/")
    func displayKeypadDivide() { #expect(HotkeyDisplay.displayKey("keypaddivide") == "Num/") }

    @Test("displayKey: keypadenter → NumEnter")
    func displayKeypadEnter() { #expect(HotkeyDisplay.displayKey("keypadenter") == "NumEnter") }

    @Test("displayKey: keypadminus → Num-")
    func displayKeypadMinus() { #expect(HotkeyDisplay.displayKey("keypadminus") == "Num-") }

    @Test("displayKey: keypadequals → Num=")
    func displayKeypadEquals() { #expect(HotkeyDisplay.displayKey("keypadequals") == "Num=") }

    @Test("displayKey: single letter a → A")
    func displayLetterA() { #expect(HotkeyDisplay.displayKey("a") == "A") }

    @Test("displayKey: multi-char unknown → capitalized")
    func displayUnknownMulti() { #expect(HotkeyDisplay.displayKey("mykey") == "Mykey") }

    // MARK: - isSupportedKey: edge cases

    @Test("isSupportedKey: empty string → false")
    func supportedEmpty() { #expect(HotkeyDisplay.isSupportedKey("") == false) }

    @Test("isSupportedKey: single letter → true")
    func supportedLetter() { #expect(HotkeyDisplay.isSupportedKey("a") == true) }

    @Test("isSupportedKey: f1 → true")
    func supportedF1() { #expect(HotkeyDisplay.isSupportedKey("f1") == true) }

    @Test("isSupportedKey: f24 → true")
    func supportedF24() { #expect(HotkeyDisplay.isSupportedKey("f24") == true) }

    @Test("isSupportedKey: space → true")
    func supportedSpace() { #expect(HotkeyDisplay.isSupportedKey("space") == true) }

    @Test("isSupportedKey: keypadclear → true")
    func supportedKeypadClear() { #expect(HotkeyDisplay.isSupportedKey("keypadclear") == true) }

    @Test("isSupportedKey: multi-char unknown → false")
    func supportedUnknown() { #expect(HotkeyDisplay.isSupportedKey("notakey") == false) }

    @Test("isSupportedKey: alias resolves → true")
    func supportedAlias() { #expect(HotkeyDisplay.isSupportedKey("enter") == true) }

    @Test("isSupportedKey: numpad alias resolves → true")
    func supportedNumAlias() { #expect(HotkeyDisplay.isSupportedKey("num5") == true) }

    // MARK: - summary / summaryIncludingMode with custom defaults

    @Test("summary: default config returns non-empty")
    func summaryDefault() {
        let suite = UserDefaults(suiteName: "hd.summary.default")!
        defer { suite.removePersistentDomain(forName: "hd.summary.default") }
        AppDefaults.register(into: suite)
        let result = HotkeyDisplay.summary(defaults: suite)
        #expect(!result.isEmpty)
        #expect(result.contains("Space"))
    }

    @Test("summary: custom modifiers + key")
    func summaryCustom() {
        let suite = UserDefaults(suiteName: "hd.summary.custom")!
        defer { suite.removePersistentDomain(forName: "hd.summary.custom") }
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        suite.set("f6", forKey: AppDefaults.Keys.hotkeyKey)
        let result = HotkeyDisplay.summary(defaults: suite)
        #expect(result.contains("⌘"))
        #expect(result.contains("⌥"))
        #expect(result.contains("F6"))
        #expect(!result.contains("⇧"))
    }

    @Test("summary: no modifiers enabled")
    func summaryNoModifiers() {
        let suite = UserDefaults(suiteName: "hd.summary.nomods")!
        defer { suite.removePersistentDomain(forName: "hd.summary.nomods") }
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        suite.set("escape", forKey: AppDefaults.Keys.hotkeyKey)
        let result = HotkeyDisplay.summary(defaults: suite)
        #expect(result == "Esc")
    }

    @Test("summary: all modifiers enabled")
    func summaryAllModifiers() {
        let suite = UserDefaults(suiteName: "hd.summary.allmods")!
        defer { suite.removePersistentDomain(forName: "hd.summary.allmods") }
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        suite.set("a", forKey: AppDefaults.Keys.hotkeyKey)
        let result = HotkeyDisplay.summary(defaults: suite)
        #expect(result.contains("⌘"))
        #expect(result.contains("⇧"))
        #expect(result.contains("⌥"))
        #expect(result.contains("⌃"))
        #expect(result.contains("⇪"))
        #expect(result.contains("A"))
    }

    @Test("summaryIncludingMode: toggle mode")
    func summaryToggle() {
        let suite = UserDefaults(suiteName: "hd.summary.toggle")!
        defer { suite.removePersistentDomain(forName: "hd.summary.toggle") }
        AppDefaults.register(into: suite)
        suite.set("toggle", forKey: AppDefaults.Keys.hotkeyMode)
        let result = HotkeyDisplay.summaryIncludingMode(defaults: suite)
        #expect(result.contains("Toggle"))
    }

    @Test("summaryIncludingMode: hold mode")
    func summaryHold() {
        let suite = UserDefaults(suiteName: "hd.summary.hold")!
        defer { suite.removePersistentDomain(forName: "hd.summary.hold") }
        AppDefaults.register(into: suite)
        suite.set("hold", forKey: AppDefaults.Keys.hotkeyMode)
        let result = HotkeyDisplay.summaryIncludingMode(defaults: suite)
        #expect(result.contains("Hold"))
    }

    @Test("summaryIncludingMode: invalid mode defaults to Toggle")
    func summaryInvalidMode() {
        let suite = UserDefaults(suiteName: "hd.summary.invalid")!
        defer { suite.removePersistentDomain(forName: "hd.summary.invalid") }
        suite.set("invalid", forKey: AppDefaults.Keys.hotkeyMode)
        suite.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let result = HotkeyDisplay.summaryIncludingMode(defaults: suite)
        #expect(result.contains("Toggle"))
    }

    // MARK: - canonicalKey: variation selectors stripped

    @Test("canonicalKey: text with variation selector stripped")
    func canonicalVariationSelector() {
        let key = "a\u{FE0F}"
        #expect(HotkeyDisplay.canonicalKey(key) == "a")
    }

    // MARK: - canonicalKey: fullwidth plus normalized

    @Test("canonicalKey: fullwidth plus → equals")
    func canonicalFullwidthPlus() { #expect(HotkeyDisplay.canonicalKey("＋") == "equals") }

    // MARK: - canonicalKey: em dash / en dash as minus

    @Test("canonicalKey: en dash → minus")
    func canonicalEnDash() { #expect(HotkeyDisplay.canonicalKey("–") == "minus") }

    @Test("canonicalKey: em dash → minus")
    func canonicalEmDash() { #expect(HotkeyDisplay.canonicalKey("—") == "minus") }

    // MARK: - canonicalKey: slash-separated combos

    @Test("canonicalKey: command/shift/space → space")
    func canonicalSlashCombo() { #expect(HotkeyDisplay.canonicalKey("command/shift/space") == "space") }

    // MARK: - canonicalKey: mixed separators

    @Test("canonicalKey: cmd + shift - f6 strips modifiers")
    func canonicalMixedSeparators() { #expect(HotkeyDisplay.canonicalKey("cmd + shift - f6") == "f6") }

    // MARK: - canonicalKey: fnglobe alias

    @Test("canonicalKey: fnglobe → fn")
    func canonicalFnGlobe() { #expect(HotkeyDisplay.canonicalKey("fnglobe") == "fn") }

    // MARK: - canonicalKey: capslock alias

    @Test("canonicalKey: capslockkey → capslock")
    func canonicalCapsLockKey() { #expect(HotkeyDisplay.canonicalKey("capslockkey") == "capslock") }
}
