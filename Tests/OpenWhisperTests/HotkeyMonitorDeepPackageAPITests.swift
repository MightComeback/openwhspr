import Testing
import Foundation
import Carbon.HIToolbox
@testable import OpenWhisper

@Suite("HotkeyMonitor Deep Package API Coverage", .serialized)
struct HotkeyMonitorDeepPackageAPITests {

    private func makeMonitor(defaults: UserDefaults? = nil) -> HotkeyMonitor {
        let ud = defaults ?? UserDefaults(suiteName: "HotkeyMonitorDeepTests.\(UUID().uuidString)")!
        return HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
    }

    // MARK: - keyCodeMatchesConfiguredTrigger: return ↔ keypadenter equivalence

    @Test("return trigger accepts main Return keycode")
    func returnTriggerAcceptsReturn() {
        let ud = UserDefaults(suiteName: "deepReturn1.\(UUID().uuidString)")!
        ud.set("return", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(monitor.keyCodeMatchesConfiguredTrigger(
            eventKeyCode: CGKeyCode(kVK_Return),
            configuredKeyCode: CGKeyCode(kVK_Return)
        ) == true)
    }

    @Test("return trigger also accepts keypad Enter")
    func returnTriggerAcceptsKeypadEnter() {
        let ud = UserDefaults(suiteName: "deepReturn2.\(UUID().uuidString)")!
        ud.set("return", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(monitor.keyCodeMatchesConfiguredTrigger(
            eventKeyCode: CGKeyCode(kVK_ANSI_KeypadEnter),
            configuredKeyCode: CGKeyCode(kVK_Return)
        ) == true)
    }

    @Test("enter trigger accepts keypad Enter")
    func enterTriggerAcceptsKeypadEnter() {
        let ud = UserDefaults(suiteName: "deepEnter1.\(UUID().uuidString)")!
        ud.set("enter", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(monitor.keyCodeMatchesConfiguredTrigger(
            eventKeyCode: CGKeyCode(kVK_ANSI_KeypadEnter),
            configuredKeyCode: CGKeyCode(kVK_Return)
        ) == true)
    }

    @Test("keypadenter trigger accepts main Return")
    func keypadEnterTriggerAcceptsReturn() {
        let ud = UserDefaults(suiteName: "deepKpEnter1.\(UUID().uuidString)")!
        ud.set("keypadenter", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(monitor.keyCodeMatchesConfiguredTrigger(
            eventKeyCode: CGKeyCode(kVK_Return),
            configuredKeyCode: CGKeyCode(kVK_ANSI_KeypadEnter)
        ) == true)
    }

    @Test("numpadenter trigger accepts main Return")
    func numpadEnterTriggerAcceptsReturn() {
        let ud = UserDefaults(suiteName: "deepNpEnter1.\(UUID().uuidString)")!
        ud.set("numpadenter", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(monitor.keyCodeMatchesConfiguredTrigger(
            eventKeyCode: CGKeyCode(kVK_Return),
            configuredKeyCode: CGKeyCode(kVK_ANSI_KeypadEnter)
        ) == true)
    }

    // MARK: - keyCodeMatchesConfiguredTrigger: delete ↔ forwarddelete equivalence

    @Test("delete trigger accepts ForwardDelete keycode")
    func deleteTriggerAcceptsForwardDelete() {
        let ud = UserDefaults(suiteName: "deepDel1.\(UUID().uuidString)")!
        ud.set("delete", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(monitor.keyCodeMatchesConfiguredTrigger(
            eventKeyCode: CGKeyCode(kVK_ForwardDelete),
            configuredKeyCode: CGKeyCode(kVK_Delete)
        ) == true)
    }

    @Test("del trigger accepts ForwardDelete keycode")
    func delTriggerAcceptsForwardDelete() {
        let ud = UserDefaults(suiteName: "deepDel2.\(UUID().uuidString)")!
        ud.set("del", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(monitor.keyCodeMatchesConfiguredTrigger(
            eventKeyCode: CGKeyCode(kVK_ForwardDelete),
            configuredKeyCode: CGKeyCode(kVK_Delete)
        ) == true)
    }

    @Test("backspace trigger accepts ForwardDelete keycode")
    func backspaceTriggerAcceptsForwardDelete() {
        let ud = UserDefaults(suiteName: "deepBksp1.\(UUID().uuidString)")!
        ud.set("backspace", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(monitor.keyCodeMatchesConfiguredTrigger(
            eventKeyCode: CGKeyCode(kVK_ForwardDelete),
            configuredKeyCode: CGKeyCode(kVK_Delete)
        ) == true)
    }

    @Test("bksp trigger accepts ForwardDelete keycode")
    func bkspTriggerAcceptsForwardDelete() {
        let ud = UserDefaults(suiteName: "deepBksp2.\(UUID().uuidString)")!
        ud.set("bksp", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(monitor.keyCodeMatchesConfiguredTrigger(
            eventKeyCode: CGKeyCode(kVK_ForwardDelete),
            configuredKeyCode: CGKeyCode(kVK_Delete)
        ) == true)
    }

    @Test("forwarddelete trigger accepts Delete keycode")
    func forwardDeleteTriggerAcceptsDelete() {
        let ud = UserDefaults(suiteName: "deepFwdDel1.\(UUID().uuidString)")!
        ud.set("forwarddelete", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(monitor.keyCodeMatchesConfiguredTrigger(
            eventKeyCode: CGKeyCode(kVK_Delete),
            configuredKeyCode: CGKeyCode(kVK_ForwardDelete)
        ) == true)
    }

    @Test("fwddelete trigger accepts Delete keycode")
    func fwdDeleteTriggerAcceptsDelete() {
        let ud = UserDefaults(suiteName: "deepFwdDel2.\(UUID().uuidString)")!
        ud.set("fwddelete", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(monitor.keyCodeMatchesConfiguredTrigger(
            eventKeyCode: CGKeyCode(kVK_Delete),
            configuredKeyCode: CGKeyCode(kVK_ForwardDelete)
        ) == true)
    }

    @Test("fwddel trigger accepts Delete keycode")
    func fwdDelTriggerAcceptsDelete() {
        let ud = UserDefaults(suiteName: "deepFwdDel3.\(UUID().uuidString)")!
        ud.set("fwddel", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(monitor.keyCodeMatchesConfiguredTrigger(
            eventKeyCode: CGKeyCode(kVK_Delete),
            configuredKeyCode: CGKeyCode(kVK_ForwardDelete)
        ) == true)
    }

    @Test("non-equivalent keys do not cross-match")
    func nonEquivalentKeysDoNotMatch() {
        let ud = UserDefaults(suiteName: "deepNoMatch.\(UUID().uuidString)")!
        ud.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        #expect(monitor.keyCodeMatchesConfiguredTrigger(
            eventKeyCode: CGKeyCode(kVK_Return),
            configuredKeyCode: CGKeyCode(kVK_Space)
        ) == false)
        #expect(monitor.keyCodeMatchesConfiguredTrigger(
            eventKeyCode: CGKeyCode(kVK_Delete),
            configuredKeyCode: CGKeyCode(kVK_Space)
        ) == false)
    }

    // MARK: - missingPermissionStatusMessage

    @Test("missingPermissionStatusMessage single permission")
    func missingPermissionSingle() {
        let monitor = makeMonitor()
        let msg = monitor.missingPermissionStatusMessage(["Accessibility"])
        #expect(msg.contains("Accessibility"))
        #expect(msg.contains("Privacy & Security"))
        #expect(msg.contains("Configured hotkey"))
    }

    @Test("missingPermissionStatusMessage two permissions")
    func missingPermissionTwo() {
        let monitor = makeMonitor()
        let msg = monitor.missingPermissionStatusMessage(["Accessibility", "Input Monitoring"])
        #expect(msg.contains("Accessibility and Input Monitoring"))
        #expect(msg.contains("both sections"))
        #expect(msg.contains("Configured hotkey"))
    }

    @Test("missingPermissionStatusMessage three permissions")
    func missingPermissionThree() {
        let monitor = makeMonitor()
        let msg = monitor.missingPermissionStatusMessage(["A", "B", "C"])
        #expect(msg.contains("A, B, and C"))
    }

    // MARK: - temporaryStatusResetDelayNanosecondsForTesting

    @Test("temporaryStatusResetDelay is positive")
    func resetDelayPositive() {
        let monitor = makeMonitor()
        let delay = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: "test")
        #expect(delay > 0)
    }

    @Test("temporaryStatusResetDelay increases with longer messages")
    func resetDelayScalesWithLength() {
        let monitor = makeMonitor()
        let short = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: "hi")
        let long = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: String(repeating: "x", count: 200))
        #expect(long > short)
    }

    @Test("temporaryStatusResetDelay is capped at 3.4 seconds")
    func resetDelayCapped() {
        let monitor = makeMonitor()
        let delay = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: String(repeating: "x", count: 10000))
        let maxNanos = UInt64(3.4 * 1_000_000_000)
        #expect(delay <= maxNanos)
    }

    @Test("temporaryStatusResetDelay base is at least 1.2 seconds")
    func resetDelayBase() {
        let monitor = makeMonitor()
        let delay = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: "")
        let baseNanos = UInt64(1.2 * 1_000_000_000)
        #expect(delay >= baseNanos)
    }

    // MARK: - keyCodeForKeyString remaining aliases

    @Test("keyCodeForKeyString maps quote alias")
    func keyCodeQuote() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("quote") == CGKeyCode(kVK_ANSI_Quote))
    }

    @Test("keyCodeForKeyString maps double-quote alias")
    func keyCodeDoubleQuote() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("\"") == CGKeyCode(kVK_ANSI_Quote))
    }

    @Test("keyCodeForKeyString maps colon alias")
    func keyCodeColon() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString(":") == CGKeyCode(kVK_ANSI_Semicolon))
    }

    @Test("keyCodeForKeyString maps angle bracket aliases")
    func keyCodeAngleBrackets() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("<") == CGKeyCode(kVK_ANSI_Comma))
        #expect(monitor.keyCodeForKeyString(">") == CGKeyCode(kVK_ANSI_Period))
    }

    @Test("keyCodeForKeyString maps question mark alias")
    func keyCodeQuestionMark() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("?") == CGKeyCode(kVK_ANSI_Slash))
    }

    @Test("keyCodeForKeyString maps pipe alias")
    func keyCodePipe() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("|") == CGKeyCode(kVK_ANSI_Backslash))
    }

    @Test("keyCodeForKeyString maps tilde alias")
    func keyCodeTilde() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("~") == CGKeyCode(kVK_ANSI_Grave))
    }

    @Test("keyCodeForKeyString maps curly brace aliases")
    func keyCodeCurlyBraces() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("{") == CGKeyCode(kVK_ANSI_LeftBracket))
        #expect(monitor.keyCodeForKeyString("}") == CGKeyCode(kVK_ANSI_RightBracket))
    }

    @Test("keyCodeForKeyString maps leftbracket alias")
    func keyCodeLeftBracket() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("leftbracket") == CGKeyCode(kVK_ANSI_LeftBracket))
    }

    @Test("keyCodeForKeyString maps rightbracket alias")
    func keyCodeRightBracket() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("rightbracket") == CGKeyCode(kVK_ANSI_RightBracket))
    }

    @Test("keyCodeForKeyString maps forwardslash alias")
    func keyCodeForwardSlash() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("forwardslash") == CGKeyCode(kVK_ANSI_Slash))
    }

    @Test("keyCodeForKeyString maps equal alias")
    func keyCodeEqual() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("equal") == CGKeyCode(kVK_ANSI_Equal))
    }

    @Test("keyCodeForKeyString maps section/paragraph/± aliases")
    func keyCodeSection() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("paragraph") == CGKeyCode(kVK_ISO_Section))
        #expect(monitor.keyCodeForKeyString("§") == CGKeyCode(kVK_ISO_Section))
        #expect(monitor.keyCodeForKeyString("±") == CGKeyCode(kVK_ISO_Section))
    }

    @Test("keyCodeForKeyString maps capslock alias")
    func keyCodeCapslock() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("capslock") == CGKeyCode(kVK_CapsLock))
    }

    @Test("keyCodeForKeyString maps function alias")
    func keyCodeFunction() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("function") == CGKeyCode(kVK_Function))
    }

    @Test("keyCodeForKeyString maps globekey alias")
    func keyCodeGlobeKey() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("globekey") == CGKeyCode(kVK_Function))
    }

    @Test("keyCodeForKeyString maps ins alias")
    func keyCodeIns() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("ins") == CGKeyCode(kVK_Help))
    }

    @Test("keyCodeForKeyString maps help alias")
    func keyCodeHelp() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("help") == CGKeyCode(kVK_Help))
    }

    @Test("keyCodeForKeyString maps pgup and pgdn aliases")
    func keyCodePgUpPgDn() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("pgup") == CGKeyCode(kVK_PageUp))
        #expect(monitor.keyCodeForKeyString("pgdn") == CGKeyCode(kVK_PageDown))
    }

    @Test("keyCodeForKeyString maps all numpad operator aliases")
    func keyCodeNumpadOperators() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("numpaddecimal") == CGKeyCode(kVK_ANSI_KeypadDecimal))
        #expect(monitor.keyCodeForKeyString("numpadcomma") == CGKeyCode(kVK_JIS_KeypadComma))
        #expect(monitor.keyCodeForKeyString("numpadmultiply") == CGKeyCode(kVK_ANSI_KeypadMultiply))
        #expect(monitor.keyCodeForKeyString("numpadplus") == CGKeyCode(kVK_ANSI_KeypadPlus))
        #expect(monitor.keyCodeForKeyString("numpadclear") == CGKeyCode(kVK_ANSI_KeypadClear))
        #expect(monitor.keyCodeForKeyString("numpaddivide") == CGKeyCode(kVK_ANSI_KeypadDivide))
        #expect(monitor.keyCodeForKeyString("numpadenter") == CGKeyCode(kVK_ANSI_KeypadEnter))
        #expect(monitor.keyCodeForKeyString("numpadminus") == CGKeyCode(kVK_ANSI_KeypadMinus))
        #expect(monitor.keyCodeForKeyString("numpadequals") == CGKeyCode(kVK_ANSI_KeypadEquals))
    }

    @Test("keyCodeForKeyString maps keypadcomma alias")
    func keyCodeKeypadComma() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("keypadcomma") == CGKeyCode(kVK_JIS_KeypadComma))
    }

    @Test("keyCodeForKeyString maps all F2-F11 keys")
    func keyCodeAllMiddleFKeys() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("f2") == CGKeyCode(kVK_F2))
        #expect(monitor.keyCodeForKeyString("f3") == CGKeyCode(kVK_F3))
        #expect(monitor.keyCodeForKeyString("f4") == CGKeyCode(kVK_F4))
        #expect(monitor.keyCodeForKeyString("f5") == CGKeyCode(kVK_F5))
        #expect(monitor.keyCodeForKeyString("f6") == CGKeyCode(kVK_F6))
        #expect(monitor.keyCodeForKeyString("f7") == CGKeyCode(kVK_F7))
        #expect(monitor.keyCodeForKeyString("f8") == CGKeyCode(kVK_F8))
        #expect(monitor.keyCodeForKeyString("f9") == CGKeyCode(kVK_F9))
        #expect(monitor.keyCodeForKeyString("f10") == CGKeyCode(kVK_F10))
        #expect(monitor.keyCodeForKeyString("f11") == CGKeyCode(kVK_F11))
    }

    @Test("keyCodeForKeyString maps F14-F19")
    func keyCodeF14toF19() {
        let monitor = makeMonitor()
        #expect(monitor.keyCodeForKeyString("f14") == CGKeyCode(kVK_F14))
        #expect(monitor.keyCodeForKeyString("f15") == CGKeyCode(kVK_F15))
        #expect(monitor.keyCodeForKeyString("f16") == CGKeyCode(kVK_F16))
        #expect(monitor.keyCodeForKeyString("f17") == CGKeyCode(kVK_F17))
        #expect(monitor.keyCodeForKeyString("f18") == CGKeyCode(kVK_F18))
        #expect(monitor.keyCodeForKeyString("f19") == CGKeyCode(kVK_F19))
    }

    // MARK: - letterKeyCode exhaustive

    @Test("letterKeyCode maps every letter distinctly")
    func letterKeyCodeDistinct() {
        let monitor = makeMonitor()
        var seen = Set<CGKeyCode>()
        for char in "abcdefghijklmnopqrstuvwxyz" {
            let code = monitor.letterKeyCode(for: char)
            #expect(code != nil, "letterKeyCode should map '\(char)'")
            if let code {
                #expect(!seen.contains(code), "letterKeyCode should give unique code for '\(char)'")
                seen.insert(code)
            }
        }
        #expect(seen.count == 26)
    }

    @Test("letterKeyCode specific mappings b through y")
    func letterKeyCodeSpecific() {
        let monitor = makeMonitor()
        #expect(monitor.letterKeyCode(for: "b") == CGKeyCode(kVK_ANSI_B))
        #expect(monitor.letterKeyCode(for: "c") == CGKeyCode(kVK_ANSI_C))
        #expect(monitor.letterKeyCode(for: "d") == CGKeyCode(kVK_ANSI_D))
        #expect(monitor.letterKeyCode(for: "e") == CGKeyCode(kVK_ANSI_E))
        #expect(monitor.letterKeyCode(for: "f") == CGKeyCode(kVK_ANSI_F))
        #expect(monitor.letterKeyCode(for: "g") == CGKeyCode(kVK_ANSI_G))
        #expect(monitor.letterKeyCode(for: "h") == CGKeyCode(kVK_ANSI_H))
        #expect(monitor.letterKeyCode(for: "i") == CGKeyCode(kVK_ANSI_I))
        #expect(monitor.letterKeyCode(for: "j") == CGKeyCode(kVK_ANSI_J))
        #expect(monitor.letterKeyCode(for: "k") == CGKeyCode(kVK_ANSI_K))
        #expect(monitor.letterKeyCode(for: "l") == CGKeyCode(kVK_ANSI_L))
        #expect(monitor.letterKeyCode(for: "n") == CGKeyCode(kVK_ANSI_N))
        #expect(monitor.letterKeyCode(for: "o") == CGKeyCode(kVK_ANSI_O))
        #expect(monitor.letterKeyCode(for: "p") == CGKeyCode(kVK_ANSI_P))
        #expect(monitor.letterKeyCode(for: "q") == CGKeyCode(kVK_ANSI_Q))
        #expect(monitor.letterKeyCode(for: "r") == CGKeyCode(kVK_ANSI_R))
        #expect(monitor.letterKeyCode(for: "s") == CGKeyCode(kVK_ANSI_S))
        #expect(monitor.letterKeyCode(for: "t") == CGKeyCode(kVK_ANSI_T))
        #expect(monitor.letterKeyCode(for: "u") == CGKeyCode(kVK_ANSI_U))
        #expect(monitor.letterKeyCode(for: "v") == CGKeyCode(kVK_ANSI_V))
        #expect(monitor.letterKeyCode(for: "w") == CGKeyCode(kVK_ANSI_W))
        #expect(monitor.letterKeyCode(for: "x") == CGKeyCode(kVK_ANSI_X))
        #expect(monitor.letterKeyCode(for: "y") == CGKeyCode(kVK_ANSI_Y))
    }

    // MARK: - digitKeyCode exhaustive

    @Test("digitKeyCode maps every digit distinctly")
    func digitKeyCodeDistinct() {
        let monitor = makeMonitor()
        var seen = Set<CGKeyCode>()
        for char in "0123456789" {
            let code = monitor.digitKeyCode(for: char)
            #expect(code != nil)
            if let code {
                #expect(!seen.contains(code))
                seen.insert(code)
            }
        }
        #expect(seen.count == 10)
    }

    @Test("digitKeyCode specific mappings 1-8")
    func digitKeyCodeSpecific() {
        let monitor = makeMonitor()
        #expect(monitor.digitKeyCode(for: "1") == CGKeyCode(kVK_ANSI_1))
        #expect(monitor.digitKeyCode(for: "2") == CGKeyCode(kVK_ANSI_2))
        #expect(monitor.digitKeyCode(for: "3") == CGKeyCode(kVK_ANSI_3))
        #expect(monitor.digitKeyCode(for: "4") == CGKeyCode(kVK_ANSI_4))
        #expect(monitor.digitKeyCode(for: "6") == CGKeyCode(kVK_ANSI_6))
        #expect(monitor.digitKeyCode(for: "7") == CGKeyCode(kVK_ANSI_7))
        #expect(monitor.digitKeyCode(for: "8") == CGKeyCode(kVK_ANSI_8))
    }

    // MARK: - modifierGlyphSummary exhaustive

    @Test("modifierGlyphSummary shows all five modifier glyphs")
    func glyphAllFive() {
        let monitor = makeMonitor()
        let flags: CGEventFlags = [.maskCommand, .maskShift, .maskAlternate, .maskControl, .maskAlphaShift]
        let result = monitor.modifierGlyphSummary(from: flags)
        #expect(result.contains("⌘"))
        #expect(result.contains("⇧"))
        #expect(result.contains("⌥"))
        #expect(result.contains("⌃"))
        #expect(result.contains("⇪"))
    }

    @Test("modifierGlyphSummary individual modifiers")
    func glyphIndividual() {
        let monitor = makeMonitor()
        #expect(monitor.modifierGlyphSummary(from: .maskShift) == "⇧")
        #expect(monitor.modifierGlyphSummary(from: .maskAlternate) == "⌥")
        #expect(monitor.modifierGlyphSummary(from: .maskControl) == "⌃")
        #expect(monitor.modifierGlyphSummary(from: .maskAlphaShift) == "⇪")
    }

    // MARK: - allowsNoModifierTrigger comprehensive

    @Test("allowsNoModifierTrigger for all return/enter variants")
    func allowsNoModReturnEnter() {
        let monitor = makeMonitor()
        for key in ["return", "enter", "keypadenter", "numpadenter"] {
            #expect(monitor.allowsNoModifierTrigger(key) == true, "\(key) should allow no modifier")
        }
    }

    @Test("allowsNoModifierTrigger for insert variants")
    func allowsNoModInsert() {
        let monitor = makeMonitor()
        for key in ["insert", "ins", "help"] {
            #expect(monitor.allowsNoModifierTrigger(key) == true, "\(key) should allow no modifier")
        }
    }

    @Test("allowsNoModifierTrigger for eject")
    func allowsNoModEject() {
        let monitor = makeMonitor()
        #expect(monitor.allowsNoModifierTrigger("eject") == true)
    }

    @Test("allowsNoModifierTrigger for caps/capslock/numlock/clear")
    func allowsNoModCapsNumlock() {
        let monitor = makeMonitor()
        #expect(monitor.allowsNoModifierTrigger("caps") == true)
        #expect(monitor.allowsNoModifierTrigger("capslock") == true)
        #expect(monitor.allowsNoModifierTrigger("numlock") == true)
        #expect(monitor.allowsNoModifierTrigger("clear") == true)
    }

    @Test("allowsNoModifierTrigger for globe/function variants")
    func allowsNoModGlobe() {
        let monitor = makeMonitor()
        for key in ["fn", "function", "globe", "globekey"] {
            #expect(monitor.allowsNoModifierTrigger(key) == true, "\(key) should allow no modifier")
        }
    }

    @Test("allowsNoModifierTrigger for all keypad operator keys")
    func allowsNoModKeypadOps() {
        let monitor = makeMonitor()
        let keys = ["keypaddecimal", "numpaddecimal", "keypadcomma", "numpadcomma",
                     "keypadmultiply", "numpadmultiply", "keypadplus", "numpadplus",
                     "keypadclear", "numpadclear", "keypaddivide", "numpaddivide",
                     "keypadminus", "numpadminus", "keypadequals", "numpadequals"]
        for key in keys {
            #expect(monitor.allowsNoModifierTrigger(key) == true, "\(key) should allow no modifier")
        }
    }

    @Test("allowsNoModifierTrigger returns false for digit keys")
    func allowsNoModDigits() {
        let monitor = makeMonitor()
        for d in "0123456789" {
            #expect(monitor.allowsNoModifierTrigger(String(d)) == false, "Digit \(d) should not allow no modifier")
        }
    }

    @Test("allowsNoModifierTrigger returns false for punctuation")
    func allowsNoModPunctuation() {
        let monitor = makeMonitor()
        for key in ["-", "=", "[", "]", ";", "'", ",", ".", "/", "\\", "`"] {
            #expect(monitor.allowsNoModifierTrigger(key) == false, "\(key) should not allow no modifier")
        }
    }

    // MARK: - humanList edge cases

    @Test("humanList with five items")
    func humanListFive() {
        #expect(HotkeyMonitor.humanList(["A", "B", "C", "D", "E"]) == "A, B, C, D, and E")
    }

    @Test("humanList preserves order")
    func humanListOrder() {
        #expect(HotkeyMonitor.humanList(["Z", "A"]) == "Z and A")
    }

    // MARK: - configuredComboSummary with various configs

    @Test("configuredComboSummary includes mode title")
    func configuredComboIncludesMode() {
        let ud = UserDefaults(suiteName: "deepCombo1.\(UUID().uuidString)")!
        ud.set(HotkeyMode.hold.rawValue, forKey: AppDefaults.Keys.hotkeyMode)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        let summary = monitor.configuredComboSummary()
        #expect(summary.contains(HotkeyMode.hold.title))
    }

    @Test("configuredComboSummary with option modifier")
    func configuredComboWithOption() {
        let ud = UserDefaults(suiteName: "deepCombo2.\(UUID().uuidString)")!
        ud.set(true, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        let summary = monitor.configuredComboSummary()
        #expect(summary.contains("⌥"))
    }

    @Test("configuredComboSummary with control modifier")
    func configuredComboWithControl() {
        let ud = UserDefaults(suiteName: "deepCombo3.\(UUID().uuidString)")!
        ud.set(true, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        let summary = monitor.configuredComboSummary()
        #expect(summary.contains("⌃"))
    }

    @Test("configuredComboSummary with capslock modifier")
    func configuredComboWithCapsLock() {
        let ud = UserDefaults(suiteName: "deepCombo4.\(UUID().uuidString)")!
        ud.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        let summary = monitor.configuredComboSummary()
        #expect(summary.contains("⇪"))
    }

    // MARK: - looksLikeShortcutCombo additional cases

    @Test("looksLikeShortcutCombo with various modifiers and keys")
    func shortcutComboVariants() {
        let monitor = makeMonitor()
        #expect(monitor.looksLikeShortcutCombo("alt f") == true)
        #expect(monitor.looksLikeShortcutCombo("meta space") == true)
        #expect(monitor.looksLikeShortcutCombo("super a") == true)
        #expect(monitor.looksLikeShortcutCombo("win f") == true)
        #expect(monitor.looksLikeShortcutCombo("windows x") == true)
    }

    @Test("looksLikeShortcutCombo with ctl alias")
    func shortcutComboCtl() {
        let monitor = makeMonitor()
        #expect(monitor.looksLikeShortcutCombo("ctl x") == true)
    }

    @Test("looksLikeShortcutCombo with opt alias")
    func shortcutComboOpt() {
        let monitor = makeMonitor()
        #expect(monitor.looksLikeShortcutCombo("opt f") == true)
    }

    // MARK: - looksLikeModifierOnlyInput additional

    @Test("looksLikeModifierOnlyInput with all aliases")
    func modifierOnlyAllAliases() {
        let monitor = makeMonitor()
        for mod in ["cmd", "command", "meta", "super", "win", "windows", "shift", "ctrl", "control", "ctl", "opt", "option", "alt"] {
            #expect(monitor.looksLikeModifierOnlyInput(mod) == true, "\(mod) should be modifier-only")
        }
    }

    @Test("looksLikeModifierOnlyInput with combined modifiers")
    func modifierOnlyCombined() {
        let monitor = makeMonitor()
        #expect(monitor.looksLikeModifierOnlyInput("cmd shift ctrl") == true)
        #expect(monitor.looksLikeModifierOnlyInput("⌘⇧") == true)
        #expect(monitor.looksLikeModifierOnlyInput("alt+ctrl") == true)
    }

    // MARK: - expandedShortcutTokens additional

    @Test("expandedShortcutTokens handles multiple separators")
    func expandedTokensMultipleSeparators() {
        let monitor = makeMonitor()
        let tokens = monitor.expandedShortcutTokens(from: "cmd shift+a")
        #expect(tokens.contains("cmd"))
        #expect(tokens.contains("shift"))
        #expect(tokens.contains("a"))
    }

    @Test("expandedShortcutTokens with 🌐 globe emoji")
    func expandedTokensGlobe() {
        let monitor = makeMonitor()
        let tokens = monitor.expandedShortcutTokens(from: "🌐f5")
        #expect(tokens.contains("globe"))
        #expect(tokens.contains("f5"))
    }

    @Test("expandedShortcutTokens empty string")
    func expandedTokensEmpty() {
        let monitor = makeMonitor()
        let tokens = monitor.expandedShortcutTokens(from: "")
        #expect(tokens.isEmpty)
    }

    // MARK: - parseFunctionKeyNumber edge cases

    @Test("parseFunctionKeyNumber with fkey prefix")
    func parseFKeyPrefix() {
        let monitor = makeMonitor()
        #expect(monitor.parseFunctionKeyNumber("fkey1") == 1)
        #expect(monitor.parseFunctionKeyNumber("fkey24") == 24)
    }

    @Test("parseFunctionKeyNumber with functionkey prefix")
    func parseFunctionKeyPrefix() {
        let monitor = makeMonitor()
        #expect(monitor.parseFunctionKeyNumber("functionkey1") == 1)
        #expect(monitor.parseFunctionKeyNumber("functionkey12") == 12)
    }

    @Test("parseFunctionKeyNumber returns nil for non-numeric suffix")
    func parseFunctionKeyNonNumeric() {
        let monitor = makeMonitor()
        #expect(monitor.parseFunctionKeyNumber("fabc") == nil)
        #expect(monitor.parseFunctionKeyNumber("fnx") == nil)
    }

    // MARK: - normalizedOutOfRangeFunctionKeyInput edge cases

    @Test("normalizedOutOfRangeFunctionKeyInput with zero")
    func outOfRangeZero() {
        let monitor = makeMonitor()
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("f0") == "F0")
    }

    @Test("normalizedOutOfRangeFunctionKeyInput with large number")
    func outOfRangeLarge() {
        let monitor = makeMonitor()
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("f100") == "F100")
    }

    @Test("normalizedOutOfRangeFunctionKeyInput returns nil for empty")
    func outOfRangeEmpty() {
        let monitor = makeMonitor()
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("") == nil)
    }

    // MARK: - updateConfig behavior

    @Test("updateConfig with invalid key stops and sets status")
    @MainActor func updateConfigInvalidKey() {
        let monitor = makeMonitor()
        monitor.updateConfig(required: .maskCommand, forbidden: [], key: "invalidxyz", mode: .toggle)
        #expect(monitor.statusMessage.contains("unsupported"))
    }

    @Test("updateConfig with valid key sets status")
    @MainActor func updateConfigValidKey() {
        let monitor = makeMonitor()
        monitor.updateConfig(required: .maskCommand, forbidden: [], key: "space", mode: .toggle)
        // Not listening so won't have active status, but should have message set
        #expect(!monitor.statusMessage.isEmpty)
    }

    @Test("updateConfig resets hold state")
    @MainActor func updateConfigResetsHold() {
        let monitor = makeMonitor()
        monitor.updateConfig(required: .maskCommand, forbidden: [], key: "space", mode: .hold)
        #expect(monitor.holdSessionArmedForTesting == false)
    }

    @Test("updateConfig with unsafe modifier config stops")
    @MainActor func updateConfigUnsafeModifiers() {
        let monitor = makeMonitor()
        // letter key with no modifiers = unsafe
        monitor.updateConfig(required: CGEventFlags(rawValue: 0), forbidden: [], key: "a", mode: .toggle)
        #expect(monitor.statusMessage.contains("too easy to trigger"))
    }

    // MARK: - reloadConfig

    @Test("reloadConfig reads mode from defaults")
    func reloadConfigMode() {
        let ud = UserDefaults(suiteName: "deepReload1.\(UUID().uuidString)")!
        ud.set(HotkeyMode.hold.rawValue, forKey: AppDefaults.Keys.hotkeyMode)
        ud.set("f5", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        monitor.reloadConfig()
        let summary = monitor.configuredComboSummary()
        #expect(summary.contains(HotkeyMode.hold.title))
    }

    @Test("reloadConfig with nil key defaults to space")
    func reloadConfigNilKey() {
        let ud = UserDefaults(suiteName: "deepReload2.\(UUID().uuidString)")!
        // Don't set hotkeyKey — should default to space
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        let summary = monitor.configuredComboSummary()
        #expect(summary.lowercased().contains("space") || summary.contains("␣"))
    }

    @Test("reloadConfig with nil mode defaults to toggle")
    func reloadConfigNilMode() {
        let ud = UserDefaults(suiteName: "deepReload3.\(UUID().uuidString)")!
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        let summary = monitor.configuredComboSummary()
        #expect(summary.contains(HotkeyMode.toggle.title))
    }

    @Test("reloadConfig subtracts required from forbidden")
    func reloadConfigSubtractsRequiredFromForbidden() {
        let ud = UserDefaults(suiteName: "deepReload4.\(UUID().uuidString)")!
        // Set command as both required and forbidden
        ud.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        ud.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        ud.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: ud, startListening: false, observeDefaults: false)
        // Should not crash and should have a valid state
        let summary = monitor.configuredComboSummary()
        #expect(summary.contains("⌘"))
    }
}
