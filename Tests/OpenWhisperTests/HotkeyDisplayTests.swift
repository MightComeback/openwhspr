import Testing
import Foundation
@testable import OpenWhisper

@Suite("HotkeyDisplay")
struct HotkeyDisplayTests {

    // MARK: - canonicalKey

    @Test("canonicalKey: single character keys pass through")
    func canonicalKeySingleChar() {
        #expect(HotkeyDisplay.canonicalKey("a") == "a")
        #expect(HotkeyDisplay.canonicalKey("Z") == "z")
        #expect(HotkeyDisplay.canonicalKey("5") == "5")
    }

    @Test("canonicalKey: space aliases")
    func canonicalKeySpace() {
        #expect(HotkeyDisplay.canonicalKey("spacebar") == "space")
        #expect(HotkeyDisplay.canonicalKey("Spacebar") == "space")
        #expect(HotkeyDisplay.canonicalKey("SPACEKEY") == "space")
        #expect(HotkeyDisplay.canonicalKey("␣") == "space")
        #expect(HotkeyDisplay.canonicalKey("⎵") == "space")
        #expect(HotkeyDisplay.canonicalKey(" ") == "space")
    }

    @Test("canonicalKey: tab aliases")
    func canonicalKeyTab() {
        #expect(HotkeyDisplay.canonicalKey("tab") == "tab")
        #expect(HotkeyDisplay.canonicalKey("tabkey") == "tab")
        #expect(HotkeyDisplay.canonicalKey("⇥") == "tab")
        #expect(HotkeyDisplay.canonicalKey("\t") == "tab")
    }

    @Test("canonicalKey: return/enter aliases")
    func canonicalKeyReturn() {
        #expect(HotkeyDisplay.canonicalKey("enter") == "return")
        #expect(HotkeyDisplay.canonicalKey("Return") == "return")
        #expect(HotkeyDisplay.canonicalKey("↩") == "return")
        #expect(HotkeyDisplay.canonicalKey("⏎") == "return")
        #expect(HotkeyDisplay.canonicalKey("\r") == "return")
        #expect(HotkeyDisplay.canonicalKey("\n") == "return")
        #expect(HotkeyDisplay.canonicalKey("return/enter") == "return")
        #expect(HotkeyDisplay.canonicalKey("enter/return") == "return")
    }

    @Test("canonicalKey: escape aliases")
    func canonicalKeyEscape() {
        #expect(HotkeyDisplay.canonicalKey("esc") == "escape")
        #expect(HotkeyDisplay.canonicalKey("Escape") == "escape")
        #expect(HotkeyDisplay.canonicalKey("⎋") == "escape")
    }

    @Test("canonicalKey: delete aliases")
    func canonicalKeyDelete() {
        #expect(HotkeyDisplay.canonicalKey("del") == "delete")
        #expect(HotkeyDisplay.canonicalKey("backspace") == "delete")
        #expect(HotkeyDisplay.canonicalKey("⌫") == "delete")
        #expect(HotkeyDisplay.canonicalKey("bksp") == "delete")
    }

    @Test("canonicalKey: forward delete")
    func canonicalKeyForwardDelete() {
        #expect(HotkeyDisplay.canonicalKey("⌦") == "forwarddelete")
        #expect(HotkeyDisplay.canonicalKey("fwddelete") == "forwarddelete")
    }

    @Test("canonicalKey: arrow keys")
    func canonicalKeyArrows() {
        #expect(HotkeyDisplay.canonicalKey("←") == "left")
        #expect(HotkeyDisplay.canonicalKey("→") == "right")
        #expect(HotkeyDisplay.canonicalKey("↑") == "up")
        #expect(HotkeyDisplay.canonicalKey("↓") == "down")
        #expect(HotkeyDisplay.canonicalKey("leftarrow") == "left")
        #expect(HotkeyDisplay.canonicalKey("arrowright") == "right")
    }

    @Test("canonicalKey: function keys")
    func canonicalKeyFunctionKeys() {
        #expect(HotkeyDisplay.canonicalKey("f1") == "f1")
        #expect(HotkeyDisplay.canonicalKey("F12") == "f12")
        #expect(HotkeyDisplay.canonicalKey("f24") == "f24")
        #expect(HotkeyDisplay.canonicalKey("fn key 6") == "f6")
        #expect(HotkeyDisplay.canonicalKey("function key 12") == "f12")
    }

    @Test("canonicalKey: fn/globe")
    func canonicalKeyFnGlobe() {
        #expect(HotkeyDisplay.canonicalKey("fn") == "fn")
        #expect(HotkeyDisplay.canonicalKey("globe") == "fn")
        #expect(HotkeyDisplay.canonicalKey("🌐") == "fn")
        #expect(HotkeyDisplay.canonicalKey("function") == "fn")
    }

    @Test("canonicalKey: punctuation")
    func canonicalKeyPunctuation() {
        #expect(HotkeyDisplay.canonicalKey("-") == "minus")
        #expect(HotkeyDisplay.canonicalKey("hyphen") == "minus")
        #expect(HotkeyDisplay.canonicalKey("=") == "equals")
        #expect(HotkeyDisplay.canonicalKey("[") == "openbracket")
        #expect(HotkeyDisplay.canonicalKey("]") == "closebracket")
        #expect(HotkeyDisplay.canonicalKey(";") == "semicolon")
        #expect(HotkeyDisplay.canonicalKey("'") == "apostrophe")
        #expect(HotkeyDisplay.canonicalKey(",") == "comma")
        #expect(HotkeyDisplay.canonicalKey(".") == "period")
        #expect(HotkeyDisplay.canonicalKey("/") == "slash")
        #expect(HotkeyDisplay.canonicalKey("\\") == "backslash")
        #expect(HotkeyDisplay.canonicalKey("`") == "backtick")
    }

    @Test("canonicalKey: shifted number keys")
    func canonicalKeyShiftedNumbers() {
        #expect(HotkeyDisplay.canonicalKey("!") == "1")
        #expect(HotkeyDisplay.canonicalKey("@") == "2")
        #expect(HotkeyDisplay.canonicalKey("#") == "3")
        #expect(HotkeyDisplay.canonicalKey("$") == "4")
        #expect(HotkeyDisplay.canonicalKey("^") == "6")
        #expect(HotkeyDisplay.canonicalKey("&") == "7")
        #expect(HotkeyDisplay.canonicalKey("*") == "8")
    }

    @Test("canonicalKey: numpad keys")
    func canonicalKeyNumpad() {
        #expect(HotkeyDisplay.canonicalKey("numpad0") == "keypad0")
        #expect(HotkeyDisplay.canonicalKey("num5") == "keypad5")
        #expect(HotkeyDisplay.canonicalKey("kp9") == "keypad9")
        #expect(HotkeyDisplay.canonicalKey("numpadplus") == "keypadplus")
        #expect(HotkeyDisplay.canonicalKey("numpadminus") == "keypadminus")
        #expect(HotkeyDisplay.canonicalKey("numpaddivide") == "keypaddivide")
        #expect(HotkeyDisplay.canonicalKey("numpadmultiply") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("numpaddecimal") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("numpadenter") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("numpadequals") == "keypadequals")
        #expect(HotkeyDisplay.canonicalKey("numpadcomma") == "keypadcomma")
        #expect(HotkeyDisplay.canonicalKey("keypadclear") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("numlock") == "keypadclear")
    }

    @Test("canonicalKey: page navigation")
    func canonicalKeyPageNav() {
        #expect(HotkeyDisplay.canonicalKey("home") == "home")
        #expect(HotkeyDisplay.canonicalKey("end") == "end")
        #expect(HotkeyDisplay.canonicalKey("pgup") == "pageup")
        #expect(HotkeyDisplay.canonicalKey("pgdn") == "pagedown")
        #expect(HotkeyDisplay.canonicalKey("⇞") == "pageup")
        #expect(HotkeyDisplay.canonicalKey("⇟") == "pagedown")
    }

    @Test("canonicalKey: capslock and section")
    func canonicalKeyMisc() {
        #expect(HotkeyDisplay.canonicalKey("caps") == "capslock")
        #expect(HotkeyDisplay.canonicalKey("section") == "section")
        #expect(HotkeyDisplay.canonicalKey("§") == "section")
        #expect(HotkeyDisplay.canonicalKey("eject") == "eject")
        #expect(HotkeyDisplay.canonicalKey("⏏") == "eject")
        #expect(HotkeyDisplay.canonicalKey("insert") == "insert")
        #expect(HotkeyDisplay.canonicalKey("ins") == "insert")
        #expect(HotkeyDisplay.canonicalKey("help") == "help")
    }

    @Test("canonicalKey: strips modifier prefixes from pasted shortcuts")
    func canonicalKeyStripsModifiers() {
        #expect(HotkeyDisplay.canonicalKey("cmd+shift+space") == "space")
        #expect(HotkeyDisplay.canonicalKey("command-shift-page-down") == "pagedown")
        #expect(HotkeyDisplay.canonicalKey("⌘⇧Space") == "space")
        #expect(HotkeyDisplay.canonicalKey("ctrl+alt+delete") == "delete")
    }

    @Test("canonicalKey: trailing plus in shortcut resolves to equals")
    func canonicalKeyTrailingPlus() {
        // "+" as a key maps to "equals" via the canonicalKey punctuation table
        #expect(HotkeyDisplay.canonicalKey("cmd+") == "equals")
        #expect(HotkeyDisplay.canonicalKey("⌘+") == "equals")
    }

    @Test("canonicalKey: unicode normalization")
    func canonicalKeyUnicode() {
        // Non-breaking space
        #expect(HotkeyDisplay.canonicalKey("\u{00A0}space\u{00A0}") == "space")
        // Fullwidth plus
        #expect(HotkeyDisplay.canonicalKey("cmd＋space") == "space")
    }

    @Test("canonicalKey: empty string")
    func canonicalKeyEmpty() {
        #expect(HotkeyDisplay.canonicalKey("") == "")
        #expect(HotkeyDisplay.canonicalKey("   ") == "")
    }

    @Test("canonicalKey: compact modifier+key without separators")
    func canonicalKeyCompactModifiers() {
        #expect(HotkeyDisplay.canonicalKey("commandshiftspace") == "space")
        #expect(HotkeyDisplay.canonicalKey("ctrlaltdelete") == "delete")
    }

    // MARK: - displayKey

    @Test("displayKey: special keys")
    func displayKeySpecial() {
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
    }

    @Test("displayKey: punctuation symbols")
    func displayKeyPunctuation() {
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
    }

    @Test("displayKey: arrows")
    func displayKeyArrows() {
        #expect(HotkeyDisplay.displayKey("left") == "←")
        #expect(HotkeyDisplay.displayKey("right") == "→")
        #expect(HotkeyDisplay.displayKey("up") == "↑")
        #expect(HotkeyDisplay.displayKey("down") == "↓")
    }

    @Test("displayKey: page navigation")
    func displayKeyPageNav() {
        #expect(HotkeyDisplay.displayKey("home") == "Home")
        #expect(HotkeyDisplay.displayKey("end") == "End")
        #expect(HotkeyDisplay.displayKey("pageup") == "PgUp")
        #expect(HotkeyDisplay.displayKey("pagedown") == "PgDn")
    }

    @Test("displayKey: function keys uppercase")
    func displayKeyFunctionKeys() {
        #expect(HotkeyDisplay.displayKey("f1") == "F1")
        #expect(HotkeyDisplay.displayKey("f12") == "F12")
        #expect(HotkeyDisplay.displayKey("f24") == "F24")
    }

    @Test("displayKey: numpad keys")
    func displayKeyNumpad() {
        #expect(HotkeyDisplay.displayKey("keypad0") == "Num0")
        #expect(HotkeyDisplay.displayKey("keypad9") == "Num9")
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

    @Test("displayKey: single character uppercased")
    func displayKeySingleChar() {
        #expect(HotkeyDisplay.displayKey("a") == "A")
        #expect(HotkeyDisplay.displayKey("z") == "Z")
        #expect(HotkeyDisplay.displayKey("5") == "5")
    }

    @Test("displayKey: aliases resolve through canonicalKey first")
    func displayKeyAliasResolution() {
        #expect(HotkeyDisplay.displayKey("spacebar") == "Space")
        #expect(HotkeyDisplay.displayKey("esc") == "Esc")
        #expect(HotkeyDisplay.displayKey("pgup") == "PgUp")
        #expect(HotkeyDisplay.displayKey("numpad5") == "Num5")
    }

    // MARK: - isSupportedKey

    @Test("isSupportedKey: named keys supported")
    func isSupportedKeyNamed() {
        #expect(HotkeyDisplay.isSupportedKey("space") == true)
        #expect(HotkeyDisplay.isSupportedKey("tab") == true)
        #expect(HotkeyDisplay.isSupportedKey("return") == true)
        #expect(HotkeyDisplay.isSupportedKey("escape") == true)
        #expect(HotkeyDisplay.isSupportedKey("delete") == true)
        #expect(HotkeyDisplay.isSupportedKey("forwarddelete") == true)
        #expect(HotkeyDisplay.isSupportedKey("insert") == true)
        #expect(HotkeyDisplay.isSupportedKey("help") == true)
        #expect(HotkeyDisplay.isSupportedKey("eject") == true)
        #expect(HotkeyDisplay.isSupportedKey("capslock") == true)
        #expect(HotkeyDisplay.isSupportedKey("fn") == true)
        #expect(HotkeyDisplay.isSupportedKey("section") == true)
    }

    @Test("isSupportedKey: arrows supported")
    func isSupportedKeyArrows() {
        #expect(HotkeyDisplay.isSupportedKey("left") == true)
        #expect(HotkeyDisplay.isSupportedKey("right") == true)
        #expect(HotkeyDisplay.isSupportedKey("up") == true)
        #expect(HotkeyDisplay.isSupportedKey("down") == true)
    }

    @Test("isSupportedKey: function keys supported")
    func isSupportedKeyFunctionKeys() {
        for i in 1...24 {
            #expect(HotkeyDisplay.isSupportedKey("f\(i)") == true)
        }
    }

    @Test("isSupportedKey: numpad keys supported")
    func isSupportedKeyNumpad() {
        for i in 0...9 {
            #expect(HotkeyDisplay.isSupportedKey("keypad\(i)") == true)
        }
        #expect(HotkeyDisplay.isSupportedKey("keypaddecimal") == true)
        #expect(HotkeyDisplay.isSupportedKey("keypadplus") == true)
        #expect(HotkeyDisplay.isSupportedKey("keypadclear") == true)
        #expect(HotkeyDisplay.isSupportedKey("keypadenter") == true)
    }

    @Test("isSupportedKey: single characters supported")
    func isSupportedKeySingleChar() {
        #expect(HotkeyDisplay.isSupportedKey("a") == true)
        #expect(HotkeyDisplay.isSupportedKey("Z") == true)
        #expect(HotkeyDisplay.isSupportedKey("9") == true)
    }

    @Test("isSupportedKey: aliases resolve and are supported")
    func isSupportedKeyAliases() {
        #expect(HotkeyDisplay.isSupportedKey("spacebar") == true)
        #expect(HotkeyDisplay.isSupportedKey("esc") == true)
        #expect(HotkeyDisplay.isSupportedKey("pgup") == true)
        #expect(HotkeyDisplay.isSupportedKey("numpad0") == true)
        #expect(HotkeyDisplay.isSupportedKey("⌫") == true)
        #expect(HotkeyDisplay.isSupportedKey("←") == true)
    }

    @Test("isSupportedKey: empty/whitespace not supported")
    func isSupportedKeyEmpty() {
        #expect(HotkeyDisplay.isSupportedKey("") == false)
        #expect(HotkeyDisplay.isSupportedKey("   ") == false)
    }

    @Test("isSupportedKey: multi-char nonsense not supported")
    func isSupportedKeyNonsense() {
        #expect(HotkeyDisplay.isSupportedKey("nonexistent") == false)
        #expect(HotkeyDisplay.isSupportedKey("xyz") == false)
    }

    // MARK: - summary / summaryIncludingMode

    private static func makeDefaults(_ name: String) -> UserDefaults {
        UserDefaults(suiteName: "HotkeyDisplayTests.\(name)")!
    }

    private static func configureDefaults(
        _ defaults: UserDefaults,
        key: String = "space",
        cmd: Bool = false, shift: Bool = false, opt: Bool = false,
        ctrl: Bool = false, caps: Bool = false,
        mode: String? = nil
    ) {
        defaults.set(key, forKey: AppDefaults.Keys.hotkeyKey)
        defaults.set(cmd, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        defaults.set(shift, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        defaults.set(opt, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        defaults.set(ctrl, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        defaults.set(caps, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        if let mode { defaults.set(mode, forKey: AppDefaults.Keys.hotkeyMode) }
    }

    @Test("summary reads hotkey combo from UserDefaults")
    func summaryFromDefaults() {
        let d = Self.makeDefaults("summaryBasic")
        Self.configureDefaults(d, key: "space", cmd: true, shift: true)
        #expect(HotkeyDisplay.summary(defaults: d) == "⌘+⇧+Space")
    }

    @Test("summary with all modifiers")
    func summaryAllModifiers() {
        let d = Self.makeDefaults("summaryAll")
        Self.configureDefaults(d, key: "f5", cmd: true, shift: true, opt: true, ctrl: true, caps: true)
        #expect(HotkeyDisplay.summary(defaults: d) == "⌘+⇧+⌥+⌃+⇪+F5")
    }

    @Test("summary with no modifiers")
    func summaryNoModifiers() {
        let d = Self.makeDefaults("summaryNone")
        Self.configureDefaults(d, key: "a")
        #expect(HotkeyDisplay.summary(defaults: d) == "A")
    }

    @Test("summaryIncludingMode with toggle")
    func summaryIncludingModeToggle() {
        let d = Self.makeDefaults("modeToggle")
        Self.configureDefaults(d, key: "space", cmd: true, mode: HotkeyMode.toggle.rawValue)
        #expect(HotkeyDisplay.summaryIncludingMode(defaults: d) == "Toggle • ⌘+Space")
    }

    @Test("summaryIncludingMode with hold")
    func summaryIncludingModeHold() {
        let d = Self.makeDefaults("modeHold")
        Self.configureDefaults(d, key: "space", cmd: true, shift: true, mode: HotkeyMode.hold.rawValue)
        #expect(HotkeyDisplay.summaryIncludingMode(defaults: d) == "Hold to talk • ⌘+⇧+Space")
    }

    @Test("summaryIncludingMode defaults to toggle for invalid mode")
    func summaryIncludingModeInvalid() {
        let d = Self.makeDefaults("modeInvalid")
        Self.configureDefaults(d, key: "space", mode: "invalid")
        #expect(HotkeyDisplay.summaryIncludingMode(defaults: d).hasPrefix("Toggle"))
    }

    // MARK: - Edge cases

    @Test("canonicalKey: modifier symbols as standalone keys")
    func canonicalKeyModifierSymbols() {
        #expect(HotkeyDisplay.canonicalKey("⌘") == "command")
        #expect(HotkeyDisplay.canonicalKey("⇧") == "shift")
        #expect(HotkeyDisplay.canonicalKey("⌥") == "option")
        #expect(HotkeyDisplay.canonicalKey("⌃") == "control")
        #expect(HotkeyDisplay.canonicalKey("⇪") == "capslock")
    }

    @Test("canonicalKey: tilde alias for backtick")
    func canonicalKeyTilde() {
        #expect(HotkeyDisplay.canonicalKey("tilde") == "backtick")
        #expect(HotkeyDisplay.canonicalKey("~") == "backtick")
        #expect(HotkeyDisplay.canonicalKey("grave") == "backtick")
    }

    @Test("canonicalKey: variation selectors stripped")
    func canonicalKeyVariationSelectors() {
        #expect(HotkeyDisplay.canonicalKey("⌫\u{FE0F}") == "delete")
        #expect(HotkeyDisplay.canonicalKey("⏏\u{FE0E}") == "eject")
    }

    @Test("canonicalKey: numpad compact forms with special chars")
    func canonicalKeyNumpadCompact() {
        #expect(HotkeyDisplay.canonicalKey("num+") == "keypadplus")
        #expect(HotkeyDisplay.canonicalKey("kp*") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("num/") == "keypaddivide")
        #expect(HotkeyDisplay.canonicalKey("kp.") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("num=") == "keypadequals")
        #expect(HotkeyDisplay.canonicalKey("kp,") == "keypadcomma")
    }

    @Test("canonicalKey: clear/numlock maps to keypadclear")
    func canonicalKeyClear() {
        #expect(HotkeyDisplay.canonicalKey("clear") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("numlock") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("⌧") == "keypadclear")
    }

    @Test("canonicalKey: fn+globe combos")
    func canonicalKeyFnGlobeCombos() {
        #expect(HotkeyDisplay.canonicalKey("fnglobe") == "fn")
        #expect(HotkeyDisplay.canonicalKey("globefn") == "fn")
    }
}
