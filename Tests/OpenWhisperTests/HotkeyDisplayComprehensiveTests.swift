import Testing
import Foundation
@testable import OpenWhisper

@Suite("HotkeyDisplay – comprehensive coverage")
struct HotkeyDisplayComprehensiveTests {

    // MARK: - canonicalKey edge cases

    @Test("canonicalKey: empty string returns empty")
    func canonicalKeyEmpty() {
        #expect(HotkeyDisplay.canonicalKey("") == "")
    }

    @Test("canonicalKey: whitespace-only trims to empty")
    func canonicalKeyWhitespace() {
        // Multiple spaces trim to empty after lowercasing+trimming
        #expect(HotkeyDisplay.canonicalKey("  ") == "")
    }

    @Test("canonicalKey: literal space character")
    func canonicalKeyLiteralSpace() {
        #expect(HotkeyDisplay.canonicalKey(" ") == "space")
    }

    @Test("canonicalKey: literal tab character")
    func canonicalKeyLiteralTab() {
        #expect(HotkeyDisplay.canonicalKey("\t") == "tab")
    }

    @Test("canonicalKey: literal return character")
    func canonicalKeyLiteralReturn() {
        #expect(HotkeyDisplay.canonicalKey("\r") == "return")
    }

    @Test("canonicalKey: literal newline character")
    func canonicalKeyLiteralNewline() {
        #expect(HotkeyDisplay.canonicalKey("\n") == "return")
    }

    @Test("canonicalKey: spacebar alias")
    func canonicalKeySpacebar() {
        #expect(HotkeyDisplay.canonicalKey("spacebar") == "space")
    }

    @Test("canonicalKey: spacekey alias")
    func canonicalKeySpacekey() {
        #expect(HotkeyDisplay.canonicalKey("spacekey") == "space")
    }

    @Test("canonicalKey: unicode space symbols")
    func canonicalKeyUnicodeSpaceSymbols() {
        #expect(HotkeyDisplay.canonicalKey("␣") == "space")
        #expect(HotkeyDisplay.canonicalKey("␠") == "space")
        #expect(HotkeyDisplay.canonicalKey("⎵") == "space")
    }

    @Test("canonicalKey: tab aliases")
    func canonicalKeyTabAliases() {
        #expect(HotkeyDisplay.canonicalKey("tabkey") == "tab")
        #expect(HotkeyDisplay.canonicalKey("backtab") == "tab")
        #expect(HotkeyDisplay.canonicalKey("reversetab") == "tab")
        #expect(HotkeyDisplay.canonicalKey("⇥") == "tab")
        #expect(HotkeyDisplay.canonicalKey("⇤") == "tab")
    }

    @Test("canonicalKey: return/enter aliases")
    func canonicalKeyReturnAliases() {
        #expect(HotkeyDisplay.canonicalKey("enter") == "return")
        #expect(HotkeyDisplay.canonicalKey("enterkey") == "return")
        #expect(HotkeyDisplay.canonicalKey("returnkey") == "return")
        #expect(HotkeyDisplay.canonicalKey("return/enter") == "return")
        #expect(HotkeyDisplay.canonicalKey("enter/return") == "return")
        #expect(HotkeyDisplay.canonicalKey("returnorenter") == "return")
        #expect(HotkeyDisplay.canonicalKey("enterorreturn") == "return")
        #expect(HotkeyDisplay.canonicalKey("↩") == "return")
        #expect(HotkeyDisplay.canonicalKey("↵") == "return")
        #expect(HotkeyDisplay.canonicalKey("⏎") == "return")
        #expect(HotkeyDisplay.canonicalKey("⌅") == "return")
        #expect(HotkeyDisplay.canonicalKey("⌤") == "return")
        #expect(HotkeyDisplay.canonicalKey("␤") == "return")
    }

    @Test("canonicalKey: escape aliases")
    func canonicalKeyEscapeAliases() {
        #expect(HotkeyDisplay.canonicalKey("esc") == "escape")
        #expect(HotkeyDisplay.canonicalKey("esckey") == "escape")
        #expect(HotkeyDisplay.canonicalKey("escapekey") == "escape")
        // Note: "escape/esc" is treated as slash-separated combo, not alias
        // The normalizer joins them: "escapeesc" (not a clean alias)
        #expect(HotkeyDisplay.canonicalKey("escape/esc") == "escapeesc")
        #expect(HotkeyDisplay.canonicalKey("esc/escape") == "escescape")
        #expect(HotkeyDisplay.canonicalKey("⎋") == "escape")
        #expect(HotkeyDisplay.canonicalKey("␛") == "escape")
    }

    @Test("canonicalKey: delete/backspace aliases")
    func canonicalKeyDeleteAliases() {
        #expect(HotkeyDisplay.canonicalKey("del") == "delete")
        #expect(HotkeyDisplay.canonicalKey("deletekey") == "delete")
        #expect(HotkeyDisplay.canonicalKey("backspace") == "delete")
        #expect(HotkeyDisplay.canonicalKey("backspacekey") == "delete")
        // Slash-separated notation joins as compound, not alias
        #expect(HotkeyDisplay.canonicalKey("delete/backspace") == "deletebackspace")
        #expect(HotkeyDisplay.canonicalKey("backspace/delete") == "backspacedelete")
        #expect(HotkeyDisplay.canonicalKey("bksp") == "delete")
        #expect(HotkeyDisplay.canonicalKey("⌫") == "delete")
    }

    @Test("canonicalKey: forward delete aliases")
    func canonicalKeyForwardDeleteAliases() {
        #expect(HotkeyDisplay.canonicalKey("⌦") == "forwarddelete")
        #expect(HotkeyDisplay.canonicalKey("␡") == "forwarddelete")
        #expect(HotkeyDisplay.canonicalKey("forwarddeletekey") == "forwarddelete")
        #expect(HotkeyDisplay.canonicalKey("fwddelete") == "forwarddelete")
        #expect(HotkeyDisplay.canonicalKey("fwddel") == "forwarddelete")
    }

    @Test("canonicalKey: insert/help/eject")
    func canonicalKeyInsertHelpEject() {
        #expect(HotkeyDisplay.canonicalKey("insertkey") == "insert")
        #expect(HotkeyDisplay.canonicalKey("ins") == "insert")
        #expect(HotkeyDisplay.canonicalKey("help") == "help")
        #expect(HotkeyDisplay.canonicalKey("helpkey") == "help")
        #expect(HotkeyDisplay.canonicalKey("eject") == "eject")
        #expect(HotkeyDisplay.canonicalKey("ejectkey") == "eject")
        #expect(HotkeyDisplay.canonicalKey("⏏") == "eject")
    }

    @Test("canonicalKey: capslock aliases")
    func canonicalKeyCapslock() {
        #expect(HotkeyDisplay.canonicalKey("caps") == "capslock")
        // "capskey" → compact strip "caps" prefix → "key" (caps is a modifier prefix)
        #expect(HotkeyDisplay.canonicalKey("capskey") == "key")
    }

    @Test("canonicalKey: fn/globe aliases")
    func canonicalKeyFnGlobe() {
        #expect(HotkeyDisplay.canonicalKey("function") == "fn")
        #expect(HotkeyDisplay.canonicalKey("fnkey") == "fn")
        #expect(HotkeyDisplay.canonicalKey("globe") == "fn")
        #expect(HotkeyDisplay.canonicalKey("globekey") == "fn")
        #expect(HotkeyDisplay.canonicalKey("fn/globe") == "fn")
        #expect(HotkeyDisplay.canonicalKey("globe/fn") == "fn")
        #expect(HotkeyDisplay.canonicalKey("🌐") == "fn")
    }

    @Test("canonicalKey: section/paragraph aliases")
    func canonicalKeySection() {
        #expect(HotkeyDisplay.canonicalKey("section") == "section")
        #expect(HotkeyDisplay.canonicalKey("sectionkey") == "section")
        #expect(HotkeyDisplay.canonicalKey("paragraph") == "section")
        #expect(HotkeyDisplay.canonicalKey("§") == "section")
        #expect(HotkeyDisplay.canonicalKey("±") == "section")
    }

    @Test("canonicalKey: arrow key aliases")
    func canonicalKeyArrows() {
        #expect(HotkeyDisplay.canonicalKey("←") == "left")
        #expect(HotkeyDisplay.canonicalKey("leftarrow") == "left")
        #expect(HotkeyDisplay.canonicalKey("arrowleft") == "left")
        #expect(HotkeyDisplay.canonicalKey("leftkey") == "left")
        #expect(HotkeyDisplay.canonicalKey("→") == "right")
        #expect(HotkeyDisplay.canonicalKey("rightarrow") == "right")
        #expect(HotkeyDisplay.canonicalKey("arrowright") == "right")
        #expect(HotkeyDisplay.canonicalKey("rightkey") == "right")
        #expect(HotkeyDisplay.canonicalKey("↑") == "up")
        #expect(HotkeyDisplay.canonicalKey("uparrow") == "up")
        #expect(HotkeyDisplay.canonicalKey("arrowup") == "up")
        #expect(HotkeyDisplay.canonicalKey("upkey") == "up")
        #expect(HotkeyDisplay.canonicalKey("↓") == "down")
        #expect(HotkeyDisplay.canonicalKey("downarrow") == "down")
        #expect(HotkeyDisplay.canonicalKey("arrowdown") == "down")
        #expect(HotkeyDisplay.canonicalKey("downkey") == "down")
    }

    @Test("canonicalKey: punctuation mapped to keys")
    func canonicalKeyPunctuation() {
        #expect(HotkeyDisplay.canonicalKey("-") == "minus")
        #expect(HotkeyDisplay.canonicalKey("hyphen") == "minus")
        #expect(HotkeyDisplay.canonicalKey("_") == "minus")
        #expect(HotkeyDisplay.canonicalKey("–") == "minus")
        #expect(HotkeyDisplay.canonicalKey("—") == "minus")
        #expect(HotkeyDisplay.canonicalKey("−") == "minus")
        #expect(HotkeyDisplay.canonicalKey("=") == "equals")
        #expect(HotkeyDisplay.canonicalKey("equal") == "equals")
        #expect(HotkeyDisplay.canonicalKey("plus") == "equals")
        #expect(HotkeyDisplay.canonicalKey("+") == "equals")
        #expect(HotkeyDisplay.canonicalKey("[") == "openbracket")
        #expect(HotkeyDisplay.canonicalKey("leftbracket") == "openbracket")
        #expect(HotkeyDisplay.canonicalKey("{") == "openbracket")
        #expect(HotkeyDisplay.canonicalKey("]") == "closebracket")
        #expect(HotkeyDisplay.canonicalKey("rightbracket") == "closebracket")
        #expect(HotkeyDisplay.canonicalKey("}") == "closebracket")
        #expect(HotkeyDisplay.canonicalKey("'") == "apostrophe")
        #expect(HotkeyDisplay.canonicalKey("quote") == "apostrophe")
        #expect(HotkeyDisplay.canonicalKey("\"") == "apostrophe")
        #expect(HotkeyDisplay.canonicalKey(".") == "period")
        #expect(HotkeyDisplay.canonicalKey("dot") == "period")
        #expect(HotkeyDisplay.canonicalKey(">") == "period")
        #expect(HotkeyDisplay.canonicalKey("/") == "slash")
        #expect(HotkeyDisplay.canonicalKey("forwardslash") == "slash")
        #expect(HotkeyDisplay.canonicalKey("?") == "slash")
        #expect(HotkeyDisplay.canonicalKey("\\") == "backslash")
        #expect(HotkeyDisplay.canonicalKey("|") == "backslash")
        #expect(HotkeyDisplay.canonicalKey("`") == "backtick")
        #expect(HotkeyDisplay.canonicalKey("grave") == "backtick")
        #expect(HotkeyDisplay.canonicalKey("graveaccent") == "backtick")
        #expect(HotkeyDisplay.canonicalKey("gravekey") == "backtick")
        #expect(HotkeyDisplay.canonicalKey("backquote") == "backtick")
        #expect(HotkeyDisplay.canonicalKey("backquotekey") == "backtick")
        #expect(HotkeyDisplay.canonicalKey("backtickkey") == "backtick")
        #expect(HotkeyDisplay.canonicalKey("quoteleft") == "backtick")
        #expect(HotkeyDisplay.canonicalKey("tilde") == "backtick")
        #expect(HotkeyDisplay.canonicalKey("~") == "backtick")
        #expect(HotkeyDisplay.canonicalKey(";") == "semicolon")
        #expect(HotkeyDisplay.canonicalKey(":") == "semicolon")
        #expect(HotkeyDisplay.canonicalKey(",") == "comma")
        #expect(HotkeyDisplay.canonicalKey("<") == "comma")
    }

    @Test("canonicalKey: shifted number keys map to digits")
    func canonicalKeyShiftedDigits() {
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

    @Test("canonicalKey: page navigation aliases")
    func canonicalKeyPageNav() {
        #expect(HotkeyDisplay.canonicalKey("homekey") == "home")
        #expect(HotkeyDisplay.canonicalKey("endkey") == "end")
        #expect(HotkeyDisplay.canonicalKey("pgup") == "pageup")
        #expect(HotkeyDisplay.canonicalKey("pgupkey") == "pageup")
        #expect(HotkeyDisplay.canonicalKey("pageupkey") == "pageup")
        #expect(HotkeyDisplay.canonicalKey("⇞") == "pageup")
        #expect(HotkeyDisplay.canonicalKey("pgdn") == "pagedown")
        #expect(HotkeyDisplay.canonicalKey("pgdnkey") == "pagedown")
        #expect(HotkeyDisplay.canonicalKey("pgdown") == "pagedown")
        #expect(HotkeyDisplay.canonicalKey("pagedownkey") == "pagedown")
        #expect(HotkeyDisplay.canonicalKey("⇟") == "pagedown")
    }

    @Test("canonicalKey: numpad aliases map to keypad")
    func canonicalKeyNumpadAliases() {
        for n in 0...9 {
            #expect(HotkeyDisplay.canonicalKey("numpad\(n)") == "keypad\(n)")
        }
        #expect(HotkeyDisplay.canonicalKey("numpad.") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("keypad.") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("numpad,") == "keypadcomma")
        #expect(HotkeyDisplay.canonicalKey("keypad,") == "keypadcomma")
        #expect(HotkeyDisplay.canonicalKey("numpad+") == "keypadplus")
        #expect(HotkeyDisplay.canonicalKey("keypad+") == "keypadplus")
        // "numpad-" and "keypad-" have dash stripped in compact normalization
        #expect(HotkeyDisplay.canonicalKey("numpad-") == "numpad")
        #expect(HotkeyDisplay.canonicalKey("keypad-") == "keypad")
        #expect(HotkeyDisplay.canonicalKey("numpad*") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("keypad*") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("numpadx") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("keypadx") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("numpad/") == "keypaddivide")
        #expect(HotkeyDisplay.canonicalKey("keypad/") == "keypaddivide")
        #expect(HotkeyDisplay.canonicalKey("numpad=") == "keypadequals")
        #expect(HotkeyDisplay.canonicalKey("keypad=") == "keypadequals")
    }

    @Test("canonicalKey: extended numpad word aliases")
    func canonicalKeyNumpadWordAliases() {
        #expect(HotkeyDisplay.canonicalKey("numpaddecimal") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("numdecimal") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("numdot") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("numperiod") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("kpdecimal") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("kpdot") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("numpadcomma") == "keypadcomma")
        #expect(HotkeyDisplay.canonicalKey("numcomma") == "keypadcomma")
        #expect(HotkeyDisplay.canonicalKey("kpcomma") == "keypadcomma")
        #expect(HotkeyDisplay.canonicalKey("numpadmultiply") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("nummultiply") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("numtimes") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("kpmultiply") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("kptimes") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("numpadplus") == "keypadplus")
        #expect(HotkeyDisplay.canonicalKey("numplus") == "keypadplus")
        #expect(HotkeyDisplay.canonicalKey("kpplus") == "keypadplus")
        #expect(HotkeyDisplay.canonicalKey("⌧") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("numpadclear") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("numclear") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("kpclear") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("clear") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("numlock") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("numlockkey") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("numpadlock") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("keypadlock") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("numpaddivide") == "keypaddivide")
        #expect(HotkeyDisplay.canonicalKey("numdivide") == "keypaddivide")
        #expect(HotkeyDisplay.canonicalKey("kpdivide") == "keypaddivide")
        #expect(HotkeyDisplay.canonicalKey("numpadenter") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("numenter") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("numenterkey") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("kpenter") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("keypadenterkey") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("numreturn") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("numpadreturn") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("kpreturn") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("keypadreturn") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("numpadminus") == "keypadminus")
        #expect(HotkeyDisplay.canonicalKey("numminus") == "keypadminus")
        #expect(HotkeyDisplay.canonicalKey("kpminus") == "keypadminus")
        #expect(HotkeyDisplay.canonicalKey("numpadequals") == "keypadequals")
        #expect(HotkeyDisplay.canonicalKey("numequals") == "keypadequals")
        #expect(HotkeyDisplay.canonicalKey("kpequals") == "keypadequals")
    }

    @Test("canonicalKey: function key aliases")
    func canonicalKeyFunctionKeys() {
        #expect(HotkeyDisplay.canonicalKey("f1") == "f1")
        #expect(HotkeyDisplay.canonicalKey("F12") == "f12")
        #expect(HotkeyDisplay.canonicalKey("f24") == "f24")
        #expect(HotkeyDisplay.canonicalKey("functionkey12") == "f12")
        #expect(HotkeyDisplay.canonicalKey("fnkey6") == "f6")
        #expect(HotkeyDisplay.canonicalKey("fkey3") == "f3")
    }

    @Test("canonicalKey: single character passes through")
    func canonicalKeySingleChar() {
        #expect(HotkeyDisplay.canonicalKey("a") == "a")
        #expect(HotkeyDisplay.canonicalKey("z") == "z")
        #expect(HotkeyDisplay.canonicalKey("A") == "a")
        #expect(HotkeyDisplay.canonicalKey("0") == "0")
    }

    @Test("canonicalKey: pasted shortcut strips modifiers")
    func canonicalKeyPastedShortcut() {
        #expect(HotkeyDisplay.canonicalKey("cmd+shift+space") == "space")
        #expect(HotkeyDisplay.canonicalKey("⌘⇧space") == "space")
        #expect(HotkeyDisplay.canonicalKey("command-shift-page-down") == "pagedown")
    }

    @Test("canonicalKey: compact modifier stripping")
    func canonicalKeyCompactModifierStrip() {
        #expect(HotkeyDisplay.canonicalKey("commandshiftspace") == "space")
        #expect(HotkeyDisplay.canonicalKey("ctrlaltdelete") == "delete")
    }

    @Test("canonicalKey: trailing plus in shortcut resolves to equals")
    func canonicalKeyTrailingPlus() {
        // "cmd+" → normalizeKey detects trailing + with modifier prefix → "+"
        // then canonicalKey maps "+" → "equals"
        #expect(HotkeyDisplay.canonicalKey("cmd+") == "equals")
        #expect(HotkeyDisplay.canonicalKey("⌘+") == "equals")
    }

    @Test("canonicalKey: fullwidth plus normalized")
    func canonicalKeyFullwidthPlus() {
        #expect(HotkeyDisplay.canonicalKey("＋") == "equals")
    }

    @Test("canonicalKey: non-breaking space is normalized to regular space then trimmed")
    func canonicalKeyNBSP() {
        // NBSP → regular space → trimmed → empty string
        #expect(HotkeyDisplay.canonicalKey("\u{00A0}") == "")
    }

    @Test("canonicalKey: variation selectors stripped")
    func canonicalKeyVariationSelectors() {
        #expect(HotkeyDisplay.canonicalKey("⎋\u{FE0F}") == "escape")
        #expect(HotkeyDisplay.canonicalKey("⎋\u{FE0E}") == "escape")
    }

    @Test("canonicalKey: fn/globe compound aliases")
    func canonicalKeyFnGlobeCompound() {
        #expect(HotkeyDisplay.canonicalKey("fnglobe") == "fn")
        #expect(HotkeyDisplay.canonicalKey("globefn") == "fn")
        #expect(HotkeyDisplay.canonicalKey("functionglobe") == "fn")
        #expect(HotkeyDisplay.canonicalKey("globefunction") == "fn")
    }

    @Test("canonicalKey: bare modifier symbols return modifier name")
    func canonicalKeyBareModifiers() {
        #expect(HotkeyDisplay.canonicalKey("⌘") == "command")
        #expect(HotkeyDisplay.canonicalKey("⇧") == "shift")
        #expect(HotkeyDisplay.canonicalKey("⌥") == "option")
        #expect(HotkeyDisplay.canonicalKey("⌃") == "control")
        #expect(HotkeyDisplay.canonicalKey("⇪") == "capslock")
    }

    // MARK: - isSupportedKey edge cases

    @Test("isSupportedKey: all named keys are supported")
    func isSupportedKeyNamedKeys() {
        let namedKeys = [
            "space", "tab", "return", "escape", "delete", "forwarddelete",
            "insert", "help", "eject", "capslock", "fn", "section",
            "left", "right", "up", "down", "home", "end", "pageup", "pagedown",
            "minus", "equals", "openbracket", "closebracket", "semicolon",
            "apostrophe", "comma", "period", "slash", "backslash", "backtick",
        ]
        for key in namedKeys {
            #expect(HotkeyDisplay.isSupportedKey(key), "Expected \(key) to be supported")
        }
    }

    @Test("isSupportedKey: function keys F1-F24")
    func isSupportedKeyFunctionKeys() {
        for n in 1...24 {
            #expect(HotkeyDisplay.isSupportedKey("f\(n)"))
            #expect(HotkeyDisplay.isSupportedKey("F\(n)"))
        }
    }

    @Test("isSupportedKey: keypad keys")
    func isSupportedKeyKeypad() {
        for n in 0...9 {
            #expect(HotkeyDisplay.isSupportedKey("keypad\(n)"))
            #expect(HotkeyDisplay.isSupportedKey("numpad\(n)"))
        }
        #expect(HotkeyDisplay.isSupportedKey("keypaddecimal"))
        #expect(HotkeyDisplay.isSupportedKey("keypadcomma"))
        #expect(HotkeyDisplay.isSupportedKey("keypadmultiply"))
        #expect(HotkeyDisplay.isSupportedKey("keypadplus"))
        #expect(HotkeyDisplay.isSupportedKey("keypadclear"))
        #expect(HotkeyDisplay.isSupportedKey("keypaddivide"))
        #expect(HotkeyDisplay.isSupportedKey("keypadenter"))
        #expect(HotkeyDisplay.isSupportedKey("keypadminus"))
        #expect(HotkeyDisplay.isSupportedKey("keypadequals"))
    }

    @Test("isSupportedKey: single letters and digits")
    func isSupportedKeySingleChars() {
        #expect(HotkeyDisplay.isSupportedKey("a"))
        #expect(HotkeyDisplay.isSupportedKey("Z"))
        #expect(HotkeyDisplay.isSupportedKey("5"))
    }

    @Test("isSupportedKey: empty is not supported")
    func isSupportedKeyEmpty() {
        #expect(!HotkeyDisplay.isSupportedKey(""))
    }

    @Test("isSupportedKey: multi-character unknown is not supported")
    func isSupportedKeyUnknownMulti() {
        #expect(!HotkeyDisplay.isSupportedKey("unknown"))
    }

    @Test("isSupportedKey: aliases resolve to supported keys")
    func isSupportedKeyAliases() {
        #expect(HotkeyDisplay.isSupportedKey("spacebar"))
        #expect(HotkeyDisplay.isSupportedKey("esc"))
        #expect(HotkeyDisplay.isSupportedKey("backspace"))
        #expect(HotkeyDisplay.isSupportedKey("pgup"))
        #expect(HotkeyDisplay.isSupportedKey("pgdn"))
        #expect(HotkeyDisplay.isSupportedKey("numpadenter"))
    }

    // MARK: - displayKey comprehensive

    @Test("displayKey: all major named keys")
    func displayKeyNamedKeys() {
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

    @Test("displayKey: punctuation keys")
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

    @Test("displayKey: arrow keys")
    func displayKeyArrows() {
        #expect(HotkeyDisplay.displayKey("left") == "←")
        #expect(HotkeyDisplay.displayKey("right") == "→")
        #expect(HotkeyDisplay.displayKey("up") == "↑")
        #expect(HotkeyDisplay.displayKey("down") == "↓")
    }

    @Test("displayKey: navigation keys")
    func displayKeyNavigation() {
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

    @Test("displayKey: keypad keys show Num prefix")
    func displayKeyKeypad() {
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

    @Test("displayKey: single char uppercased")
    func displayKeySingleChar() {
        #expect(HotkeyDisplay.displayKey("a") == "A")
        #expect(HotkeyDisplay.displayKey("z") == "Z")
        #expect(HotkeyDisplay.displayKey("5") == "5")
    }

    @Test("displayKey: aliases resolve before display")
    func displayKeyAliases() {
        #expect(HotkeyDisplay.displayKey("spacebar") == "Space")
        #expect(HotkeyDisplay.displayKey("esc") == "Esc")
        #expect(HotkeyDisplay.displayKey("enter") == "Return/Enter")
        #expect(HotkeyDisplay.displayKey("backspace") == "Delete")
        #expect(HotkeyDisplay.displayKey("pgup") == "PgUp")
    }

    // MARK: - summary / summaryIncludingMode

    @Test("summary reads from custom UserDefaults")
    func summaryCustomDefaults() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayTests.summary")!
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        suite.set("space", forKey: AppDefaults.Keys.hotkeyKey)

        let result = HotkeyDisplay.summary(defaults: suite)
        #expect(result == "⌘+⇧+Space")
        suite.removePersistentDomain(forName: "HotkeyDisplayTests.summary")
    }

    @Test("summaryIncludingMode includes mode prefix")
    func summaryIncludingModePrefix() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayTests.summaryMode")!
        suite.set("toggle", forKey: AppDefaults.Keys.hotkeyMode)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        suite.set("space", forKey: AppDefaults.Keys.hotkeyKey)

        let result = HotkeyDisplay.summaryIncludingMode(defaults: suite)
        #expect(result.contains("Toggle"))
        #expect(result.contains("⌘+Space"))
        suite.removePersistentDomain(forName: "HotkeyDisplayTests.summaryMode")
    }

    @Test("summaryIncludingMode hold mode")
    func summaryIncludingModeHold() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayTests.summaryModeHold")!
        suite.set("hold", forKey: AppDefaults.Keys.hotkeyMode)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        suite.set("f5", forKey: AppDefaults.Keys.hotkeyKey)

        let result = HotkeyDisplay.summaryIncludingMode(defaults: suite)
        #expect(result.contains("Hold"))
        #expect(result.contains("F5"))
        suite.removePersistentDomain(forName: "HotkeyDisplayTests.summaryModeHold")
    }

    @Test("summaryIncludingMode with all modifiers")
    func summaryAllModifiers() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayTests.allMods")!
        suite.set("toggle", forKey: AppDefaults.Keys.hotkeyMode)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        suite.set("a", forKey: AppDefaults.Keys.hotkeyKey)

        let result = HotkeyDisplay.summary(defaults: suite)
        #expect(result == "⌘+⇧+⌥+⌃+⇪+A")
        suite.removePersistentDomain(forName: "HotkeyDisplayTests.allMods")
    }

    @Test("summary with no modifiers")
    func summaryNoModifiers() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayTests.noMods")!
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        suite.set("escape", forKey: AppDefaults.Keys.hotkeyKey)

        let result = HotkeyDisplay.summary(defaults: suite)
        #expect(result == "Esc")
        suite.removePersistentDomain(forName: "HotkeyDisplayTests.noMods")
    }

    @Test("summaryIncludingMode with invalid mode falls back to toggle")
    func summaryInvalidModeFallback() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayTests.invalidMode")!
        suite.set("nonexistent", forKey: AppDefaults.Keys.hotkeyMode)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        suite.set("space", forKey: AppDefaults.Keys.hotkeyKey)

        let result = HotkeyDisplay.summaryIncludingMode(defaults: suite)
        #expect(result.contains("Toggle"))
        suite.removePersistentDomain(forName: "HotkeyDisplayTests.invalidMode")
    }

    // MARK: - normalizeKey edge cases via canonicalKey

    @Test("canonicalKey: slash-separated shortcut notation")
    func canonicalKeySlashSeparated() {
        #expect(HotkeyDisplay.canonicalKey("command/shift/space") == "space")
    }

    @Test("canonicalKey: numpad space-separated notation preserved")
    func canonicalKeyNumpadSpaceSeparated() {
        #expect(HotkeyDisplay.canonicalKey("numpad +") == "keypadplus")
        #expect(HotkeyDisplay.canonicalKey("numpad -") == "keypadminus")
        #expect(HotkeyDisplay.canonicalKey("numpad *") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("keypad /") == "keypaddivide")
        #expect(HotkeyDisplay.canonicalKey("numpad .") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("keypad ,") == "keypadcomma")
        #expect(HotkeyDisplay.canonicalKey("numpad =") == "keypadequals")
        #expect(HotkeyDisplay.canonicalKey("keypad x") == "keypadmultiply")
    }

    @Test("canonicalKey: compact numpad shorthand")
    func canonicalKeyCompactNumpad() {
        #expect(HotkeyDisplay.canonicalKey("num0") == "keypad0")
        #expect(HotkeyDisplay.canonicalKey("kp5") == "keypad5")
        #expect(HotkeyDisplay.canonicalKey("num+") == "keypadplus")
        #expect(HotkeyDisplay.canonicalKey("kp*") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("num.") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("kp/") == "keypaddivide")
        #expect(HotkeyDisplay.canonicalKey("num=") == "keypadequals")
        #expect(HotkeyDisplay.canonicalKey("kp,") == "keypadcomma")
    }

    @Test("canonicalKey: capslock compound normalization")
    func canonicalKeyCapsCompound() {
        #expect(HotkeyDisplay.canonicalKey("capslockkey") == "capslock")
    }

    @Test("canonicalKey: function key phrases")
    func canonicalKeyFunctionPhrases() {
        #expect(HotkeyDisplay.canonicalKey("function key 12") == "f12")
        #expect(HotkeyDisplay.canonicalKey("fn key 3") == "f3")
    }

    @Test("canonicalKey: case insensitivity")
    func canonicalKeyCaseInsensitive() {
        #expect(HotkeyDisplay.canonicalKey("SPACE") == "space")
        #expect(HotkeyDisplay.canonicalKey("Space") == "space")
        #expect(HotkeyDisplay.canonicalKey("ESCAPE") == "escape")
        #expect(HotkeyDisplay.canonicalKey("Return") == "return")
        #expect(HotkeyDisplay.canonicalKey("DELETE") == "delete")
    }
}
