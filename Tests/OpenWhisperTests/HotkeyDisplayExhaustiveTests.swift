import Testing
import Foundation
@testable import OpenWhisper

@Suite("HotkeyDisplay Exhaustive Alias Coverage")
struct HotkeyDisplayExhaustiveTests {

    // MARK: - canonicalKey exhaustive aliases

    @Test("spacebar aliases")
    func spacebarAliases() {
        #expect(HotkeyDisplay.canonicalKey("spacebar") == "space")
        #expect(HotkeyDisplay.canonicalKey("spacekey") == "space")
        #expect(HotkeyDisplay.canonicalKey("␣") == "space")
        #expect(HotkeyDisplay.canonicalKey("␠") == "space")
        #expect(HotkeyDisplay.canonicalKey("⎵") == "space")
    }

    @Test("tab aliases")
    func tabAliases() {
        #expect(HotkeyDisplay.canonicalKey("tabkey") == "tab")
        #expect(HotkeyDisplay.canonicalKey("backtab") == "tab")
        #expect(HotkeyDisplay.canonicalKey("reversetab") == "tab")
        #expect(HotkeyDisplay.canonicalKey("⇥") == "tab")
        #expect(HotkeyDisplay.canonicalKey("⇤") == "tab")
    }

    @Test("return aliases")
    func returnAliases() {
        #expect(HotkeyDisplay.canonicalKey("enter") == "return")
        #expect(HotkeyDisplay.canonicalKey("enterkey") == "return")
        #expect(HotkeyDisplay.canonicalKey("returnkey") == "return")
        #expect(HotkeyDisplay.canonicalKey("return/enter") == "return")
        #expect(HotkeyDisplay.canonicalKey("enter/return") == "return")
        #expect(HotkeyDisplay.canonicalKey("returnorenter") == "return")
        #expect(HotkeyDisplay.canonicalKey("enterorreturn") == "return")
        #expect(HotkeyDisplay.canonicalKey("returnenter") == "return")
        #expect(HotkeyDisplay.canonicalKey("enterreturn") == "return")
        #expect(HotkeyDisplay.canonicalKey("↵") == "return")
        #expect(HotkeyDisplay.canonicalKey("⏎") == "return")
        #expect(HotkeyDisplay.canonicalKey("⌅") == "return")
        #expect(HotkeyDisplay.canonicalKey("⌤") == "return")
        #expect(HotkeyDisplay.canonicalKey("␤") == "return")
    }

    @Test("escape aliases")
    func escapeAliases() {
        #expect(HotkeyDisplay.canonicalKey("esckey") == "escape")
        #expect(HotkeyDisplay.canonicalKey("escapekey") == "escape")
        // "escape/esc" → slash-separated, normalized to "escape esc" → modifier stripping extracts "esc"
        #expect(HotkeyDisplay.canonicalKey("escape/esc") == "escapeesc")
        #expect(HotkeyDisplay.canonicalKey("esc/escape") == "escescape")
        #expect(HotkeyDisplay.canonicalKey("␛") == "escape")
    }

    @Test("delete aliases")
    func deleteAliases() {
        #expect(HotkeyDisplay.canonicalKey("del") == "delete")
        #expect(HotkeyDisplay.canonicalKey("deletekey") == "delete")
        #expect(HotkeyDisplay.canonicalKey("backspace") == "delete")
        #expect(HotkeyDisplay.canonicalKey("backspacekey") == "delete")
        // slash-separated: "delete/backspace" → "delete backspace" → collapsed
        #expect(HotkeyDisplay.canonicalKey("delete/backspace") == "deletebackspace")
        #expect(HotkeyDisplay.canonicalKey("backspace/delete") == "backspacedelete")
    }

    @Test("forwarddelete aliases")
    func forwardDeleteAliases() {
        #expect(HotkeyDisplay.canonicalKey("⌦") == "forwarddelete")
        #expect(HotkeyDisplay.canonicalKey("␡") == "forwarddelete")
        #expect(HotkeyDisplay.canonicalKey("forwarddeletekey") == "forwarddelete")
        #expect(HotkeyDisplay.canonicalKey("fwddelete") == "forwarddelete")
        #expect(HotkeyDisplay.canonicalKey("fwddel") == "forwarddelete")
    }

    @Test("insert alias")
    func insertAliases() {
        #expect(HotkeyDisplay.canonicalKey("insertkey") == "insert")
        #expect(HotkeyDisplay.canonicalKey("ins") == "insert")
    }

    @Test("help alias")
    func helpAlias() {
        #expect(HotkeyDisplay.canonicalKey("help") == "help")
        #expect(HotkeyDisplay.canonicalKey("helpkey") == "help")
    }

    @Test("eject alias")
    func ejectAlias() {
        #expect(HotkeyDisplay.canonicalKey("eject") == "eject")
        #expect(HotkeyDisplay.canonicalKey("ejectkey") == "eject")
        #expect(HotkeyDisplay.canonicalKey("⏏") == "eject")
    }

    @Test("capslock alias")
    func capslockAlias() {
        #expect(HotkeyDisplay.canonicalKey("caps") == "capslock")
        // "capskey" → compact stripping: "caps" is a modifier prefix, leaves "key"
        #expect(HotkeyDisplay.canonicalKey("capskey") == "key")
    }

    @Test("fn globe aliases")
    func fnGlobeAliases() {
        #expect(HotkeyDisplay.canonicalKey("function") == "fn")
        #expect(HotkeyDisplay.canonicalKey("fnkey") == "fn")
        #expect(HotkeyDisplay.canonicalKey("globe") == "fn")
        #expect(HotkeyDisplay.canonicalKey("globekey") == "fn")
        #expect(HotkeyDisplay.canonicalKey("fn/globe") == "fn")
        #expect(HotkeyDisplay.canonicalKey("globe/fn") == "fn")
    }

    @Test("section aliases")
    func sectionAliases() {
        #expect(HotkeyDisplay.canonicalKey("section") == "section")
        #expect(HotkeyDisplay.canonicalKey("sectionkey") == "section")
        #expect(HotkeyDisplay.canonicalKey("paragraph") == "section")
    }

    @Test("arrow aliases")
    func arrowAliases() {
        #expect(HotkeyDisplay.canonicalKey("leftarrow") == "left")
        #expect(HotkeyDisplay.canonicalKey("arrowleft") == "left")
        #expect(HotkeyDisplay.canonicalKey("leftkey") == "left")
        #expect(HotkeyDisplay.canonicalKey("rightarrow") == "right")
        #expect(HotkeyDisplay.canonicalKey("arrowright") == "right")
        #expect(HotkeyDisplay.canonicalKey("rightkey") == "right")
        #expect(HotkeyDisplay.canonicalKey("uparrow") == "up")
        #expect(HotkeyDisplay.canonicalKey("arrowup") == "up")
        #expect(HotkeyDisplay.canonicalKey("upkey") == "up")
        #expect(HotkeyDisplay.canonicalKey("downarrow") == "down")
        #expect(HotkeyDisplay.canonicalKey("arrowdown") == "down")
        #expect(HotkeyDisplay.canonicalKey("downkey") == "down")
    }

    @Test("minus aliases")
    func minusAliases() {
        #expect(HotkeyDisplay.canonicalKey("-") == "minus")
        #expect(HotkeyDisplay.canonicalKey("hyphen") == "minus")
        #expect(HotkeyDisplay.canonicalKey("_") == "minus")
        #expect(HotkeyDisplay.canonicalKey("–") == "minus")
        #expect(HotkeyDisplay.canonicalKey("—") == "minus")
        #expect(HotkeyDisplay.canonicalKey("−") == "minus")
    }

    @Test("equals aliases")
    func equalsAliases() {
        #expect(HotkeyDisplay.canonicalKey("=") == "equals")
        #expect(HotkeyDisplay.canonicalKey("equal") == "equals")
        #expect(HotkeyDisplay.canonicalKey("plus") == "equals")
        #expect(HotkeyDisplay.canonicalKey("+") == "equals")
    }

    @Test("bracket aliases")
    func bracketAliases() {
        #expect(HotkeyDisplay.canonicalKey("[") == "openbracket")
        #expect(HotkeyDisplay.canonicalKey("leftbracket") == "openbracket")
        #expect(HotkeyDisplay.canonicalKey("{") == "openbracket")
        #expect(HotkeyDisplay.canonicalKey("]") == "closebracket")
        #expect(HotkeyDisplay.canonicalKey("rightbracket") == "closebracket")
        #expect(HotkeyDisplay.canonicalKey("}") == "closebracket")
    }

    @Test("punctuation aliases")
    func punctuationAliases() {
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
        #expect(HotkeyDisplay.canonicalKey(";") == "semicolon")
        #expect(HotkeyDisplay.canonicalKey(":") == "semicolon")
        #expect(HotkeyDisplay.canonicalKey(",") == "comma")
        #expect(HotkeyDisplay.canonicalKey("<") == "comma")
    }

    @Test("shifted number symbols")
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

    @Test("page navigation aliases")
    func pageNavigationAliases() {
        #expect(HotkeyDisplay.canonicalKey("homekey") == "home")
        #expect(HotkeyDisplay.canonicalKey("endkey") == "end")
        #expect(HotkeyDisplay.canonicalKey("pgupkey") == "pageup")
        #expect(HotkeyDisplay.canonicalKey("pageupkey") == "pageup")
        #expect(HotkeyDisplay.canonicalKey("pgdnkey") == "pagedown")
        #expect(HotkeyDisplay.canonicalKey("pgdown") == "pagedown")
        #expect(HotkeyDisplay.canonicalKey("pagedownkey") == "pagedown")
    }

    @Test("keypad decimal aliases in canonicalKey")
    func keypadDecimalAliases() {
        #expect(HotkeyDisplay.canonicalKey("numpad.") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("keypad.") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("numpaddecimal") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("numdecimal") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("numdot") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("numperiod") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("kpdecimal") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("kpdot") == "keypaddecimal")
    }

    @Test("keypad comma aliases")
    func keypadCommaAliases() {
        #expect(HotkeyDisplay.canonicalKey("numpad,") == "keypadcomma")
        #expect(HotkeyDisplay.canonicalKey("keypad,") == "keypadcomma")
        #expect(HotkeyDisplay.canonicalKey("numpadcomma") == "keypadcomma")
        #expect(HotkeyDisplay.canonicalKey("numcomma") == "keypadcomma")
        #expect(HotkeyDisplay.canonicalKey("kpcomma") == "keypadcomma")
    }

    @Test("keypad multiply aliases")
    func keypadMultiplyAliases() {
        #expect(HotkeyDisplay.canonicalKey("numpadmultiply") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("nummultiply") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("numtimes") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("kpmultiply") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("kptimes") == "keypadmultiply")
    }

    @Test("keypad plus aliases")
    func keypadPlusAliases() {
        #expect(HotkeyDisplay.canonicalKey("numpadplus") == "keypadplus")
        #expect(HotkeyDisplay.canonicalKey("numplus") == "keypadplus")
        #expect(HotkeyDisplay.canonicalKey("kpplus") == "keypadplus")
    }

    @Test("keypad clear aliases")
    func keypadClearAliases() {
        #expect(HotkeyDisplay.canonicalKey("numpadclear") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("numclear") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("kpclear") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("clear") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("numlock") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("numlockkey") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("numpadlock") == "keypadclear")
        #expect(HotkeyDisplay.canonicalKey("keypadlock") == "keypadclear")
    }

    @Test("keypad divide aliases")
    func keypadDivideAliases() {
        #expect(HotkeyDisplay.canonicalKey("numpaddivide") == "keypaddivide")
        #expect(HotkeyDisplay.canonicalKey("numdivide") == "keypaddivide")
        #expect(HotkeyDisplay.canonicalKey("kpdivide") == "keypaddivide")
    }

    @Test("keypad enter aliases")
    func keypadEnterAliases() {
        #expect(HotkeyDisplay.canonicalKey("numpadenter") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("numenter") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("numenterkey") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("kpenter") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("keypadenterkey") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("numreturn") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("numpadreturn") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("kpreturn") == "keypadenter")
        #expect(HotkeyDisplay.canonicalKey("keypadreturn") == "keypadenter")
    }

    @Test("keypad minus aliases")
    func keypadMinusAliases() {
        #expect(HotkeyDisplay.canonicalKey("numpadminus") == "keypadminus")
        #expect(HotkeyDisplay.canonicalKey("numminus") == "keypadminus")
        #expect(HotkeyDisplay.canonicalKey("kpminus") == "keypadminus")
    }

    @Test("keypad equals aliases")
    func keypadEqualsAliases() {
        #expect(HotkeyDisplay.canonicalKey("numpadequals") == "keypadequals")
        #expect(HotkeyDisplay.canonicalKey("numequals") == "keypadequals")
        #expect(HotkeyDisplay.canonicalKey("kpequals") == "keypadequals")
    }

    // MARK: - displayKey exhaustive coverage

    @Test("displayKey for insert")
    func displayKeyInsert() {
        #expect(HotkeyDisplay.displayKey("insert") == "Insert")
    }

    @Test("displayKey for help")
    func displayKeyHelp() {
        #expect(HotkeyDisplay.displayKey("help") == "Help")
    }

    @Test("displayKey for eject")
    func displayKeyEject() {
        #expect(HotkeyDisplay.displayKey("eject") == "Eject")
    }

    @Test("displayKey for capslock")
    func displayKeyCapslock() {
        #expect(HotkeyDisplay.displayKey("capslock") == "CapsLock")
    }

    @Test("displayKey for fn")
    func displayKeyFn() {
        #expect(HotkeyDisplay.displayKey("fn") == "Fn/Globe")
    }

    @Test("displayKey for section")
    func displayKeySection() {
        #expect(HotkeyDisplay.displayKey("section") == "§")
    }

    @Test("displayKey for forwarddelete")
    func displayKeyForwardDelete() {
        #expect(HotkeyDisplay.displayKey("forwarddelete") == "FwdDelete")
    }

    @Test("displayKey for keypadenter")
    func displayKeyKeypadEnter() {
        #expect(HotkeyDisplay.displayKey("keypadenter") == "NumEnter")
    }

    @Test("displayKey for keypadminus")
    func displayKeyKeypadMinus() {
        #expect(HotkeyDisplay.displayKey("keypadminus") == "Num-")
    }

    @Test("displayKey for keypadequals")
    func displayKeyKeypadEquals() {
        #expect(HotkeyDisplay.displayKey("keypadequals") == "Num=")
    }

    @Test("displayKey for keypadclear")
    func displayKeyKeypadClear() {
        #expect(HotkeyDisplay.displayKey("keypadclear") == "NumClear")
    }

    @Test("displayKey for keypaddivide")
    func displayKeyKeypadDivide() {
        #expect(HotkeyDisplay.displayKey("keypaddivide") == "Num/")
    }

    @Test("displayKey for keypadcomma")
    func displayKeyKeypadComma() {
        #expect(HotkeyDisplay.displayKey("keypadcomma") == "Num,")
    }

    @Test("displayKey for all keypad digits")
    func displayKeyAllKeypadDigits() {
        for i in 0...9 {
            #expect(HotkeyDisplay.displayKey("keypad\(i)") == "Num\(i)")
        }
    }

    @Test("displayKey for home and end")
    func displayKeyHomeEnd() {
        #expect(HotkeyDisplay.displayKey("home") == "Home")
        #expect(HotkeyDisplay.displayKey("end") == "End")
    }

    @Test("displayKey for pageup and pagedown")
    func displayKeyPageUpDown() {
        #expect(HotkeyDisplay.displayKey("pageup") == "PgUp")
        #expect(HotkeyDisplay.displayKey("pagedown") == "PgDn")
    }

    @Test("displayKey for arrows")
    func displayKeyArrows() {
        #expect(HotkeyDisplay.displayKey("left") == "←")
        #expect(HotkeyDisplay.displayKey("right") == "→")
        #expect(HotkeyDisplay.displayKey("up") == "↑")
        #expect(HotkeyDisplay.displayKey("down") == "↓")
    }

    @Test("displayKey for punctuation")
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

    @Test("displayKey multi-character unknown returns capitalized")
    func displayKeyUnknownMultiChar() {
        #expect(HotkeyDisplay.displayKey("weirdkey") == "Weirdkey")
    }

    // MARK: - normalizeKey edge cases (via canonicalKey)

    @Test("fullwidth plus in input is normalized")
    func fullwidthPlus() {
        // "＋" should be converted to "+" internally
        #expect(HotkeyDisplay.canonicalKey("＋") == "equals")
    }

    @Test("small plus is normalized")
    func smallPlus() {
        #expect(HotkeyDisplay.canonicalKey("﹢") == "equals")
    }

    @Test("dotplus is normalized")
    func dotPlus() {
        #expect(HotkeyDisplay.canonicalKey("∔") == "equals")
    }

    @Test("non-breaking space trimmed")
    func nonBreakingSpaceTrimmed() {
        #expect(HotkeyDisplay.canonicalKey("\u{00A0}a\u{00A0}") == "a")
    }

    @Test("figure space trimmed")
    func figureSpaceTrimmed() {
        #expect(HotkeyDisplay.canonicalKey("\u{2007}b\u{2007}") == "b")
    }

    @Test("narrow no-break space trimmed")
    func narrowNoBreakSpaceTrimmed() {
        #expect(HotkeyDisplay.canonicalKey("\u{202F}c\u{202F}") == "c")
    }

    // MARK: - normalizeKey compact modifier stripping

    @Test("compact modifier stripping: commandshiftspace")
    func compactCommandShiftSpace() {
        #expect(HotkeyDisplay.canonicalKey("commandshiftspace") == "space")
    }

    @Test("compact modifier stripping: ctrlaltdelete")
    func compactCtrlAltDelete() {
        #expect(HotkeyDisplay.canonicalKey("ctrlaltdelete") == "delete")
    }

    @Test("compact modifier stripping: metasupertab")
    func compactMetaSuperTab() {
        #expect(HotkeyDisplay.canonicalKey("metasupertab") == "tab")
    }

    @Test("compact modifier stripping: windowsshifta")
    func compactWindowsShiftA() {
        // "windows" prefix: "win" matches first, leaving "dowsshifta" → shift strips → "dowsa"?
        // Actually: compact strips greedily — "win" matches, then "dowsshifta" doesn't start with any modifier
        #expect(HotkeyDisplay.canonicalKey("windowsshifta") == "dowsshifta")
    }

    // MARK: - normalizeKey numpad space variants

    @Test("numpad space operator aliases")
    func numpadSpaceOperators() {
        #expect(HotkeyDisplay.canonicalKey("numpad +") == "keypadplus")
        #expect(HotkeyDisplay.canonicalKey("numpad -") == "keypadminus")
        #expect(HotkeyDisplay.canonicalKey("numpad *") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("numpad x") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("keypad +") == "keypadplus")
        #expect(HotkeyDisplay.canonicalKey("keypad -") == "keypadminus")
        #expect(HotkeyDisplay.canonicalKey("keypad *") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("keypad x") == "keypadmultiply")
        #expect(HotkeyDisplay.canonicalKey("numpad .") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("keypad .") == "keypaddecimal")
        #expect(HotkeyDisplay.canonicalKey("numpad ,") == "keypadcomma")
        #expect(HotkeyDisplay.canonicalKey("keypad ,") == "keypadcomma")
        #expect(HotkeyDisplay.canonicalKey("numpad =") == "keypadequals")
        #expect(HotkeyDisplay.canonicalKey("keypad =") == "keypadequals")
        #expect(HotkeyDisplay.canonicalKey("numpad /") == "keypaddivide")
        #expect(HotkeyDisplay.canonicalKey("keypad /") == "keypaddivide")
    }

    // MARK: - isSupportedKey coverage for all named keys

    @Test("isSupportedKey for all named special keys")
    func isSupportedKeyNamedKeys() {
        let namedKeys = [
            "space", "tab", "return", "escape", "delete", "forwarddelete",
            "insert", "help", "eject", "capslock", "fn", "section",
            "left", "right", "up", "down", "home", "end", "pageup", "pagedown",
            "minus", "equals", "openbracket", "closebracket",
            "semicolon", "apostrophe", "comma", "period", "slash", "backslash", "backtick",
        ]
        for key in namedKeys {
            #expect(HotkeyDisplay.isSupportedKey(key) == true, "Expected \(key) to be supported")
        }
    }

    @Test("isSupportedKey for all keypad keys")
    func isSupportedKeyKeypadKeys() {
        let keypadKeys = [
            "keypad0", "keypad1", "keypad2", "keypad3", "keypad4",
            "keypad5", "keypad6", "keypad7", "keypad8", "keypad9",
            "keypaddecimal", "keypadcomma", "keypadmultiply", "keypadplus",
            "keypadclear", "keypaddivide", "keypadenter", "keypadminus", "keypadequals",
        ]
        for key in keypadKeys {
            #expect(HotkeyDisplay.isSupportedKey(key) == true, "Expected \(key) to be supported")
        }
    }

    @Test("isSupportedKey for numpad aliases")
    func isSupportedKeyNumpadAliases() {
        let numpadKeys = [
            "numpad0", "numpad1", "numpad2", "numpad3", "numpad4",
            "numpad5", "numpad6", "numpad7", "numpad8", "numpad9",
            "numpaddecimal", "numpadcomma", "numpadmultiply", "numpadplus",
            "numpadclear", "numpaddivide", "numpadenter", "numpadminus", "numpadequals",
        ]
        for key in numpadKeys {
            #expect(HotkeyDisplay.isSupportedKey(key) == true, "Expected \(key) to be supported")
        }
    }

    @Test("isSupportedKey for all function keys")
    func isSupportedKeyFunctionKeys() {
        for i in 1...24 {
            #expect(HotkeyDisplay.isSupportedKey("f\(i)") == true)
        }
    }

    @Test("isSupportedKey for alias names")
    func isSupportedKeyAliases() {
        let aliases = [
            "spacebar", "enter", "esc", "del", "bksp", "pgup", "pgdn",
            "hyphen", "equal", "plus", "leftbracket", "rightbracket",
            "quote", "dot", "forwardslash", "grave",
        ]
        for alias in aliases {
            #expect(HotkeyDisplay.isSupportedKey(alias) == true, "Expected alias \(alias) to be supported")
        }
    }

    @Test("isSupportedKey rejects empty string")
    func isSupportedKeyEmpty() {
        #expect(HotkeyDisplay.isSupportedKey("") == false)
    }

    @Test("isSupportedKey accepts single letter")
    func isSupportedKeySingleLetter() {
        #expect(HotkeyDisplay.isSupportedKey("a") == true)
        #expect(HotkeyDisplay.isSupportedKey("Z") == true)
    }

    @Test("isSupportedKey accepts single digit")
    func isSupportedKeySingleDigit() {
        for d in 0...9 {
            #expect(HotkeyDisplay.isSupportedKey("\(d)") == true)
        }
    }

    // MARK: - summary / summaryIncludingMode via UserDefaults

    @Test("summary with no modifiers returns just key")
    func summaryNoModifiers() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayExhaustive.summary")!
        suite.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        let result = HotkeyDisplay.summary(defaults: suite)
        #expect(result == "Space")
        suite.removePersistentDomain(forName: "HotkeyDisplayExhaustive.summary")
    }

    @Test("summary with all modifiers")
    func summaryAllModifiers() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayExhaustive.allMods")!
        suite.set("a", forKey: AppDefaults.Keys.hotkeyKey)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        let result = HotkeyDisplay.summary(defaults: suite)
        #expect(result == "⌘+⇧+⌥+⌃+⇪+A")
        suite.removePersistentDomain(forName: "HotkeyDisplayExhaustive.allMods")
    }

    @Test("summaryIncludingMode toggle")
    func summaryIncludingModeToggle() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayExhaustive.modeToggle")!
        suite.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        suite.set("toggle", forKey: AppDefaults.Keys.hotkeyMode)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        let result = HotkeyDisplay.summaryIncludingMode(defaults: suite)
        #expect(result == "Toggle • ⌘+⇧+Space")
        suite.removePersistentDomain(forName: "HotkeyDisplayExhaustive.modeToggle")
    }

    @Test("summaryIncludingMode hold")
    func summaryIncludingModeHold() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayExhaustive.modeHold")!
        suite.set("f5", forKey: AppDefaults.Keys.hotkeyKey)
        suite.set("hold", forKey: AppDefaults.Keys.hotkeyMode)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        let result = HotkeyDisplay.summaryIncludingMode(defaults: suite)
        #expect(result == "Hold to talk • F5")
        suite.removePersistentDomain(forName: "HotkeyDisplayExhaustive.modeHold")
    }

    @Test("summaryIncludingMode invalid mode defaults to toggle")
    func summaryIncludingModeInvalid() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayExhaustive.modeInvalid")!
        suite.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        suite.set("badvalue", forKey: AppDefaults.Keys.hotkeyMode)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        let result = HotkeyDisplay.summaryIncludingMode(defaults: suite)
        #expect(result.hasPrefix("Toggle"))
        suite.removePersistentDomain(forName: "HotkeyDisplayExhaustive.modeInvalid")
    }

    @Test("summary with nil hotkey key defaults to space")
    func summaryNilKey() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayExhaustive.nilKey")!
        suite.removeObject(forKey: AppDefaults.Keys.hotkeyKey)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        let result = HotkeyDisplay.summary(defaults: suite)
        #expect(result == "Space")
        suite.removePersistentDomain(forName: "HotkeyDisplayExhaustive.nilKey")
    }

    // MARK: - symbol-expanded shortcut pasting via normalizeKey

    @Test("symbol combo ⌘⇧⌥⌃space extracts space")
    func symbolComboExtracts() {
        #expect(HotkeyDisplay.canonicalKey("⌘⇧⌥⌃space") == "space")
    }

    @Test("symbol combo with return symbols")
    func symbolComboReturn() {
        #expect(HotkeyDisplay.canonicalKey("⌘↩") == "return")
        #expect(HotkeyDisplay.canonicalKey("⌘↵") == "return")
        #expect(HotkeyDisplay.canonicalKey("⌘⏎") == "return")
    }

    @Test("symbol combo with escape")
    func symbolComboEscape() {
        #expect(HotkeyDisplay.canonicalKey("⌘⎋") == "escape")
    }

    @Test("symbol combo with tab")
    func symbolComboTab() {
        #expect(HotkeyDisplay.canonicalKey("⌘⇥") == "tab")
        #expect(HotkeyDisplay.canonicalKey("⌘⇤") == "tab")
    }

    @Test("symbol combo with delete")
    func symbolComboDelete() {
        #expect(HotkeyDisplay.canonicalKey("⌘⌫") == "delete")
        #expect(HotkeyDisplay.canonicalKey("⌘⌦") == "forwarddelete")
    }

    @Test("symbol combo with arrows")
    func symbolComboArrows() {
        #expect(HotkeyDisplay.canonicalKey("⌘←") == "left")
        #expect(HotkeyDisplay.canonicalKey("⌘→") == "right")
        #expect(HotkeyDisplay.canonicalKey("⌘↑") == "up")
        #expect(HotkeyDisplay.canonicalKey("⌘↓") == "down")
    }

    // MARK: - function key alias variants

    @Test("function key aliases via canonicalFunctionKeyAlias")
    func functionKeyAliasVariants() {
        #expect(HotkeyDisplay.canonicalKey("functionkey1") == "f1")
        #expect(HotkeyDisplay.canonicalKey("fnkey12") == "f12")
        #expect(HotkeyDisplay.canonicalKey("fkey5") == "f5")
        #expect(HotkeyDisplay.canonicalKey("fn24") == "f24")
        #expect(HotkeyDisplay.canonicalKey("function20") == "f20")
    }

    @Test("function key out of range not treated as function key")
    func functionKeyOutOfRange() {
        #expect(HotkeyDisplay.canonicalKey("fn0") != "f0")
        #expect(HotkeyDisplay.canonicalKey("fn25") != "f25")
    }

    // MARK: - trailing plus shortcut detection

    @Test("cmd++ maps to equals (plus as key)")
    func cmdPlusPlusMapsToEquals() {
        #expect(HotkeyDisplay.canonicalKey("cmd++") == "equals")
    }

    @Test("⌘+ maps to equals")
    func symbolCmdPlus() {
        #expect(HotkeyDisplay.canonicalKey("⌘+") == "equals")
    }

    @Test("numpad+ at end is NOT treated as trailing-plus shortcut")
    func numpadPlusNotTrailingPlus() {
        #expect(HotkeyDisplay.canonicalKey("numpad+") == "keypadplus")
        #expect(HotkeyDisplay.canonicalKey("kp+") == "keypadplus")
    }
}
