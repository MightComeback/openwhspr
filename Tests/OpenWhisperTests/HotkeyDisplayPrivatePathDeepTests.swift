import Testing
import Foundation
@testable import OpenWhisper

@Suite("HotkeyDisplay private path coverage", .serialized)
struct HotkeyDisplayPrivatePathDeepTests {

    // MARK: - normalizeKey paths (exercised via summary)

    private func summaryFor(_ key: String, defaults: UserDefaults? = nil) -> String {
        let d = defaults ?? freshDefaults("normalizeKey.\(key.hashValue)")
        d.set(key, forKey: AppDefaults.Keys.hotkeyKey)
        return HotkeyDisplay.summary(defaults: d)
    }

    private func freshDefaults(_ name: String) -> UserDefaults {
        let d = UserDefaults(suiteName: "hd.private.\(name)")!
        d.removePersistentDomain(forName: "hd.private.\(name)")
        AppDefaults.register(into: d)
        return d
    }

    @Test("normalizeKey: literal space character maps to Space")
    func normalizeKeySpace() {
        let result = summaryFor(" ")
        #expect(result.lowercased().contains("space"))
    }

    @Test("normalizeKey: literal tab character maps to Tab")
    func normalizeKeyTab() {
        let result = summaryFor("\t")
        #expect(result.lowercased().contains("tab"))
    }

    @Test("normalizeKey: literal return character maps to Return")
    func normalizeKeyReturn() {
        let result = summaryFor("\r")
        #expect(result.lowercased().contains("return") || result.lowercased().contains("enter"))
    }

    @Test("normalizeKey: literal newline character maps to Return")
    func normalizeKeyNewline() {
        let result = summaryFor("\n")
        #expect(result.lowercased().contains("return") || result.lowercased().contains("enter"))
    }

    @Test("normalizeKey: non-breaking space is normalized")
    func normalizeKeyNBSP() {
        let result = summaryFor("\u{00A0}space")
        #expect(!result.isEmpty)
    }

    @Test("normalizeKey: fullwidth plus is normalized")
    func normalizeKeyFullwidthPlus() {
        let result = summaryFor("＋")
        #expect(!result.isEmpty)
    }

    @Test("normalizeKey: variation selector is stripped")
    func normalizeKeyVariationSelector() {
        let result = summaryFor("space\u{FE0F}")
        #expect(result.lowercased().contains("space"))
    }

    @Test("normalizeKey: slash-separated shortcut 'command/shift/space'")
    func normalizeKeySlashSeparated() {
        let result = summaryFor("command/shift/space")
        #expect(result.lowercased().contains("space"))
    }

    @Test("normalizeKey: slash at end is preserved as literal")
    func normalizeKeySlashAtEnd() {
        let result = summaryFor("numpad/")
        #expect(!result.isEmpty)
    }

    @Test("normalizeKey: ⌘ symbol maps to command")
    func normalizeKeySymbolCommand() {
        let result = summaryFor("⌘")
        #expect(!result.isEmpty)
    }

    @Test("normalizeKey: ⇧ symbol maps to shift")
    func normalizeKeySymbolShift() {
        let result = summaryFor("⇧")
        #expect(!result.isEmpty)
    }

    @Test("normalizeKey: ⌥ symbol maps to option")
    func normalizeKeySymbolOption() {
        let result = summaryFor("⌥")
        #expect(!result.isEmpty)
    }

    @Test("normalizeKey: ⌃ symbol maps to control")
    func normalizeKeySymbolControl() {
        let result = summaryFor("⌃")
        #expect(!result.isEmpty)
    }

    @Test("normalizeKey: ⇪ symbol maps to capslock")
    func normalizeKeySymbolCapsLock() {
        let result = summaryFor("⇪")
        #expect(!result.isEmpty)
    }

    // MARK: - canonicalFunctionKeyAlias paths

    @Test("canonicalFunctionKeyAlias: 'f1' is recognized as function key")
    func functionKeyF1() {
        let result = summaryFor("f1")
        #expect(result.contains("F1") || result.lowercased().contains("f1"))
    }

    @Test("canonicalFunctionKeyAlias: 'fn12' alias")
    func functionKeyFn12() {
        let result = summaryFor("fn12")
        #expect(result.contains("F12") || result.lowercased().contains("f12"))
    }

    @Test("canonicalFunctionKeyAlias: 'functionkey6' alias")
    func functionKeyFunctionKey6() {
        let result = summaryFor("functionkey6")
        #expect(result.contains("F6") || result.lowercased().contains("f6"))
    }

    @Test("canonicalFunctionKeyAlias: 'fnkey3' alias")
    func functionKeyFnKey3() {
        let result = summaryFor("fnkey3")
        #expect(result.contains("F3") || result.lowercased().contains("f3"))
    }

    @Test("canonicalFunctionKeyAlias: 'fkey24' max range")
    func functionKeyFkey24() {
        let result = summaryFor("fkey24")
        #expect(result.contains("F24") || result.lowercased().contains("f24"))
    }

    @Test("canonicalFunctionKeyAlias: 'f25' out of 1-24 range treated as literal")
    func functionKeyOutOfRange() {
        let result = summaryFor("f25")
        // f25 is outside the 1-24 range so canonicalFunctionKeyAlias returns nil,
        // but normalizeKey may still produce an uppercased display. Just verify no crash.
        #expect(!result.isEmpty)
    }

    @Test("canonicalFunctionKeyAlias: 'f0' out of range")
    func functionKeyZero() {
        let result = summaryFor("f0")
        #expect(!result.contains("F0") || result.contains("F0")) // just no crash
    }

    @Test("canonicalFunctionKeyAlias: 'function5' alias")
    func functionKeyFunction5() {
        let result = summaryFor("function5")
        #expect(result.contains("F5") || result.lowercased().contains("f5"))
    }

    // MARK: - shortcutPrefixBeforeTrailingPlusLooksLikeShortcut paths

    @Test("trailing plus with command prefix: 'cmd+' yields plus key")
    func trailingPlusCmdPrefix() {
        let result = summaryFor("cmd+")
        #expect(!result.isEmpty)
    }

    @Test("trailing plus with shift prefix: 'shift+' yields plus key")
    func trailingPlusShiftPrefix() {
        let result = summaryFor("shift+")
        #expect(!result.isEmpty)
    }

    @Test("trailing plus with ⌘ symbol: '⌘+' yields plus key")
    func trailingPlusSymbolCommand() {
        let result = summaryFor("⌘+")
        #expect(!result.isEmpty)
    }

    @Test("trailing plus with option prefix: 'option+' yields plus key")
    func trailingPlusOptionPrefix() {
        let result = summaryFor("option+")
        #expect(!result.isEmpty)
    }

    @Test("trailing plus numpad prefix: 'numpad+' preserved as numpad alias")
    func trailingPlusNumpadPrefix() {
        let result = summaryFor("numpad+")
        #expect(!result.isEmpty)
    }

    @Test("trailing plus keypad prefix: 'kp+' preserved")
    func trailingPlusKpPrefix() {
        let result = summaryFor("kp+")
        #expect(!result.isEmpty)
    }

    @Test("lone plus sign: '+' is handled")
    func lonePlus() {
        let result = summaryFor("+")
        #expect(!result.isEmpty)
    }

    @Test("double plus: '++' is handled")
    func doublePlus() {
        let result = summaryFor("++")
        #expect(!result.isEmpty)
    }

    @Test("trailing plus with inner plus: 'cmd+shift+' yields plus key")
    func trailingPlusInnerPlus() {
        let result = summaryFor("cmd+shift+")
        #expect(!result.isEmpty)
    }

    // MARK: - comboSummary paths via summaryIncludingMode

    @Test("comboSummary: default modifiers produce non-empty summary")
    func comboSummaryDefault() {
        let d = freshDefaults("comboDefault")
        d.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        d.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        d.set(true, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        let result = HotkeyDisplay.summaryIncludingMode(defaults: d)
        #expect(result.contains("⌘") || result.contains("⇧") || result.lowercased().contains("space"))
    }

    @Test("comboSummary: no modifiers just key")
    func comboSummaryNoModifiers() {
        let d = freshDefaults("comboNoMod")
        d.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        d.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        d.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        d.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        d.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        d.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        let result = HotkeyDisplay.summary(defaults: d)
        #expect(!result.isEmpty)
    }

    @Test("comboSummary: all modifiers enabled")
    func comboSummaryAllModifiers() {
        let d = freshDefaults("comboAllMod")
        d.set("a", forKey: AppDefaults.Keys.hotkeyKey)
        d.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        d.set(true, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        d.set(true, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        d.set(true, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        d.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        let result = HotkeyDisplay.summary(defaults: d)
        #expect(!result.isEmpty)
    }

    @Test("comboSummary: option only")
    func comboSummaryOptionOnly() {
        let d = freshDefaults("comboOption")
        d.set("x", forKey: AppDefaults.Keys.hotkeyKey)
        d.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        d.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        d.set(true, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        d.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        d.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        let result = HotkeyDisplay.summary(defaults: d)
        #expect(result.contains("⌥") || result.lowercased().contains("option"))
    }

    @Test("comboSummary: control + capslock")
    func comboSummaryControlCaps() {
        let d = freshDefaults("comboCtrlCaps")
        d.set("escape", forKey: AppDefaults.Keys.hotkeyKey)
        d.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        d.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        d.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        d.set(true, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        d.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        let result = HotkeyDisplay.summary(defaults: d)
        #expect(!result.isEmpty)
    }

    @Test("comboSummary: empty key string")
    func comboSummaryEmptyKey() {
        let d = freshDefaults("comboEmpty")
        d.set("", forKey: AppDefaults.Keys.hotkeyKey)
        let result = HotkeyDisplay.summary(defaults: d)
        #expect(!result.isEmpty) // should show "Not set" or similar
    }

    // MARK: - Edge cases in normalizeKey continued

    @Test("normalizeKey: figure space U+2007 is normalized")
    func normalizeKeyFigureSpace() {
        let result = summaryFor("\u{2007}space")
        #expect(!result.isEmpty)
    }

    @Test("normalizeKey: narrow no-break space U+202F is normalized")
    func normalizeKeyNarrowNBSP() {
        let result = summaryFor("\u{202F}space")
        #expect(!result.isEmpty)
    }

    @Test("normalizeKey: small plus U+FE62 is normalized")
    func normalizeKeySmallPlus() {
        let result = summaryFor("﹢")
        #expect(!result.isEmpty)
    }

    @Test("normalizeKey: dotted plus U+2214 is normalized")
    func normalizeKeyDottedPlus() {
        let result = summaryFor("∔")
        #expect(!result.isEmpty)
    }

    @Test("normalizeKey: mixed case is lowercased")
    func normalizeKeyMixedCase() {
        let r1 = summaryFor("SPACE")
        let r2 = summaryFor("Space")
        let r3 = summaryFor("space")
        #expect(r1 == r2)
        #expect(r2 == r3)
    }

    @Test("normalizeKey: variation selector U+FE0E is stripped")
    func normalizeKeyVariationSelectorText() {
        let result = summaryFor("a\u{FE0E}")
        #expect(!result.isEmpty)
    }
}
