import Testing
import Foundation
import CoreGraphics
@testable import OpenWhisper

@Suite("HotkeyMonitor combo summary and glyph helpers", .serialized)
struct HotkeyMonitorComboSummaryTests {

    // MARK: - modifierGlyphSummary

    @Test("modifierGlyphSummary: empty flags returns empty string")
    func glyphSummaryEmpty() {
        let monitor = HotkeyMonitor()
        #expect(monitor.modifierGlyphSummary(from: CGEventFlags(rawValue: 0)) == "")
    }

    @Test("modifierGlyphSummary: command only")
    func glyphSummaryCommand() {
        let monitor = HotkeyMonitor()
        #expect(monitor.modifierGlyphSummary(from: .maskCommand) == "⌘")
    }

    @Test("modifierGlyphSummary: shift only")
    func glyphSummaryShift() {
        let monitor = HotkeyMonitor()
        #expect(monitor.modifierGlyphSummary(from: .maskShift) == "⇧")
    }

    @Test("modifierGlyphSummary: option only")
    func glyphSummaryOption() {
        let monitor = HotkeyMonitor()
        #expect(monitor.modifierGlyphSummary(from: .maskAlternate) == "⌥")
    }

    @Test("modifierGlyphSummary: control only")
    func glyphSummaryControl() {
        let monitor = HotkeyMonitor()
        #expect(monitor.modifierGlyphSummary(from: .maskControl) == "⌃")
    }

    @Test("modifierGlyphSummary: capsLock only")
    func glyphSummaryCapsLock() {
        let monitor = HotkeyMonitor()
        #expect(monitor.modifierGlyphSummary(from: .maskAlphaShift) == "⇪")
    }

    @Test("modifierGlyphSummary: command+shift")
    func glyphSummaryCommandShift() {
        let monitor = HotkeyMonitor()
        let flags = CGEventFlags(rawValue: CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue)
        #expect(monitor.modifierGlyphSummary(from: flags) == "⌘+⇧")
    }

    @Test("modifierGlyphSummary: all five modifiers ordered correctly")
    func glyphSummaryAllModifiers() {
        let monitor = HotkeyMonitor()
        let flags = CGEventFlags(rawValue:
            CGEventFlags.maskCommand.rawValue |
            CGEventFlags.maskShift.rawValue |
            CGEventFlags.maskAlternate.rawValue |
            CGEventFlags.maskControl.rawValue |
            CGEventFlags.maskAlphaShift.rawValue
        )
        let result = monitor.modifierGlyphSummary(from: flags)
        #expect(result == "⌘+⇧+⌥+⌃+⇪")
    }

    @Test("modifierGlyphSummary: option+control without command/shift")
    func glyphSummaryOptionControl() {
        let monitor = HotkeyMonitor()
        let flags = CGEventFlags(rawValue: CGEventFlags.maskAlternate.rawValue | CGEventFlags.maskControl.rawValue)
        #expect(monitor.modifierGlyphSummary(from: flags) == "⌥+⌃")
    }

    @Test("modifierGlyphSummary: command+option+capsLock")
    func glyphSummaryCommandOptionCapsLock() {
        let monitor = HotkeyMonitor()
        let flags = CGEventFlags(rawValue:
            CGEventFlags.maskCommand.rawValue |
            CGEventFlags.maskAlternate.rawValue |
            CGEventFlags.maskAlphaShift.rawValue
        )
        #expect(monitor.modifierGlyphSummary(from: flags) == "⌘+⌥+⇪")
    }

    // MARK: - configuredComboSummary

    @Test("configuredComboSummary: default config produces toggle mode with space")
    func configuredComboDefault() {
        let suite = UserDefaults(suiteName: "test.comboSummary.default")!
        defer { suite.removePersistentDomain(forName: "test.comboSummary.default") }
        AppDefaults.register(into: suite)
        let monitor = HotkeyMonitor(defaults: suite)
        let summary = monitor.configuredComboSummary()
        #expect(summary.contains("Toggle"))
        #expect(summary.contains("Space") || summary.contains("space") || summary.contains("␣"))
    }

    @Test("configuredComboSummary: hold mode with space")
    func configuredComboHoldMode() {
        let suite = UserDefaults(suiteName: "test.comboSummary.hold")!
        defer { suite.removePersistentDomain(forName: "test.comboSummary.hold") }
        AppDefaults.register(into: suite)
        suite.set(HotkeyMode.hold.rawValue, forKey: AppDefaults.Keys.hotkeyMode)
        let monitor = HotkeyMonitor(defaults: suite)
        let summary = monitor.configuredComboSummary()
        #expect(summary.contains("Hold"))
    }

    @Test("configuredComboSummary: includes command glyph when command required")
    func configuredComboIncludesCommand() {
        let suite = UserDefaults(suiteName: "test.comboSummary.cmd")!
        defer { suite.removePersistentDomain(forName: "test.comboSummary.cmd") }
        AppDefaults.register(into: suite)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        let monitor = HotkeyMonitor(defaults: suite)
        let summary = monitor.configuredComboSummary()
        #expect(summary.contains("⌘"))
    }

    @Test("configuredComboSummary: includes shift glyph when shift required")
    func configuredComboIncludesShift() {
        let suite = UserDefaults(suiteName: "test.comboSummary.shift")!
        defer { suite.removePersistentDomain(forName: "test.comboSummary.shift") }
        AppDefaults.register(into: suite)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        let monitor = HotkeyMonitor(defaults: suite)
        let summary = monitor.configuredComboSummary()
        #expect(summary.contains("⇧"))
    }

    @Test("configuredComboSummary: no modifier glyphs when none required")
    func configuredComboNoModifiers() {
        let suite = UserDefaults(suiteName: "test.comboSummary.nomod")!
        defer { suite.removePersistentDomain(forName: "test.comboSummary.nomod") }
        AppDefaults.register(into: suite)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)
        suite.set("f6", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: suite)
        let summary = monitor.configuredComboSummary()
        #expect(!summary.contains("⌘"))
        #expect(!summary.contains("⇧"))
        #expect(!summary.contains("⌥"))
        #expect(!summary.contains("⌃"))
    }

    @Test("configuredComboSummary: custom trigger key f6")
    func configuredComboCustomKey() {
        let suite = UserDefaults(suiteName: "test.comboSummary.f6")!
        defer { suite.removePersistentDomain(forName: "test.comboSummary.f6") }
        AppDefaults.register(into: suite)
        suite.set("f6", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: suite)
        let summary = monitor.configuredComboSummary()
        #expect(summary.contains("F6"))
    }

    @Test("configuredComboSummary: all four modifiers shows all glyphs")
    func configuredComboAllModifiers() {
        let suite = UserDefaults(suiteName: "test.comboSummary.allmod")!
        defer { suite.removePersistentDomain(forName: "test.comboSummary.allmod") }
        AppDefaults.register(into: suite)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        let monitor = HotkeyMonitor(defaults: suite)
        let summary = monitor.configuredComboSummary()
        #expect(summary.contains("⌘"))
        #expect(summary.contains("⇧"))
        #expect(summary.contains("⌥"))
        #expect(summary.contains("⌃"))
    }

    // MARK: - currentComboSummary

    @Test("currentComboSummary: returns non-empty string")
    func currentComboNonEmpty() {
        let suite = UserDefaults(suiteName: "test.currentCombo.nonempty")!
        defer { suite.removePersistentDomain(forName: "test.currentCombo.nonempty") }
        AppDefaults.register(into: suite)
        let monitor = HotkeyMonitor(defaults: suite)
        let summary = monitor.currentComboSummary()
        #expect(!summary.isEmpty)
    }

    @Test("currentComboSummary: reflects configured mode")
    func currentComboReflectsMode() {
        let suite = UserDefaults(suiteName: "test.currentCombo.mode")!
        defer { suite.removePersistentDomain(forName: "test.currentCombo.mode") }
        AppDefaults.register(into: suite)
        suite.set(HotkeyMode.hold.rawValue, forKey: AppDefaults.Keys.hotkeyMode)
        let monitor = HotkeyMonitor(defaults: suite)
        let summary = monitor.currentComboSummary()
        #expect(summary.contains("Hold"))
    }

    @Test("currentComboSummary: reflects configured key")
    func currentComboReflectsKey() {
        let suite = UserDefaults(suiteName: "test.currentCombo.key")!
        defer { suite.removePersistentDomain(forName: "test.currentCombo.key") }
        AppDefaults.register(into: suite)
        suite.set("escape", forKey: AppDefaults.Keys.hotkeyKey)
        let monitor = HotkeyMonitor(defaults: suite)
        let summary = monitor.currentComboSummary()
        #expect(summary.contains("Esc") || summary.contains("escape") || summary.contains("⎋"))
    }

    // MARK: - shortcutModifierWords

    @Test("shortcutModifierWords: contains standard modifier names")
    func modifierWordsContainsStandard() {
        let monitor = HotkeyMonitor()
        let words = monitor.shortcutModifierWords()
        #expect(words.contains("cmd"))
        #expect(words.contains("command"))
        #expect(words.contains("shift"))
        #expect(words.contains("ctrl"))
        #expect(words.contains("control"))
        #expect(words.contains("opt"))
        #expect(words.contains("option"))
        #expect(words.contains("alt"))
    }

    @Test("shortcutModifierWords: contains platform-specific aliases")
    func modifierWordsContainsPlatformAliases() {
        let monitor = HotkeyMonitor()
        let words = monitor.shortcutModifierWords()
        #expect(words.contains("meta"))
        #expect(words.contains("super"))
        #expect(words.contains("win"))
        #expect(words.contains("windows"))
        #expect(words.contains("ctl"))
    }

    @Test("shortcutModifierWords: contains fn/function/globe")
    func modifierWordsContainsFn() {
        let monitor = HotkeyMonitor()
        let words = monitor.shortcutModifierWords()
        #expect(words.contains("fn"))
        #expect(words.contains("function"))
        #expect(words.contains("globe"))
    }

    @Test("shortcutModifierWords: does not contain non-modifier keys")
    func modifierWordsExcludesKeys() {
        let monitor = HotkeyMonitor()
        let words = monitor.shortcutModifierWords()
        #expect(!words.contains("space"))
        #expect(!words.contains("return"))
        #expect(!words.contains("escape"))
        #expect(!words.contains("f6"))
        #expect(!words.contains("a"))
    }

    @Test("shortcutModifierWords: count is reasonable")
    func modifierWordsCount() {
        let monitor = HotkeyMonitor()
        let words = monitor.shortcutModifierWords()
        #expect(words.count >= 12)
        #expect(words.count <= 25)
    }

    // MARK: - expandedShortcutTokens

    @Test("expandedShortcutTokens: plain word")
    func expandedTokensPlainWord() {
        let monitor = HotkeyMonitor()
        #expect(monitor.expandedShortcutTokens(from: "space") == ["space"])
    }

    @Test("expandedShortcutTokens: glyph symbols expanded")
    func expandedTokensGlyphs() {
        let monitor = HotkeyMonitor()
        let tokens = monitor.expandedShortcutTokens(from: "⌘⇧space")
        #expect(tokens.contains("command"))
        #expect(tokens.contains("shift"))
        #expect(tokens.contains("space"))
    }

    @Test("expandedShortcutTokens: plus-separated combo")
    func expandedTokensPlusSeparated() {
        let monitor = HotkeyMonitor()
        let tokens = monitor.expandedShortcutTokens(from: "cmd+shift+f6")
        #expect(tokens.contains("cmd"))
        #expect(tokens.contains("shift"))
        #expect(tokens.contains("f6"))
    }

    @Test("expandedShortcutTokens: hyphen-separated combo")
    func expandedTokensHyphenSeparated() {
        let monitor = HotkeyMonitor()
        let tokens = monitor.expandedShortcutTokens(from: "ctrl-alt-delete")
        #expect(tokens.contains("ctrl"))
        #expect(tokens.contains("alt"))
        #expect(tokens.contains("delete"))
    }

    @Test("expandedShortcutTokens: mixed glyph and text")
    func expandedTokensMixed() {
        let monitor = HotkeyMonitor()
        let tokens = monitor.expandedShortcutTokens(from: "⌘+shift+space")
        #expect(tokens.contains("command"))
        #expect(tokens.contains("shift"))
        #expect(tokens.contains("space"))
    }

    @Test("expandedShortcutTokens: empty input")
    func expandedTokensEmpty() {
        let monitor = HotkeyMonitor()
        #expect(monitor.expandedShortcutTokens(from: "").isEmpty)
    }

    @Test("expandedShortcutTokens: comma-separated")
    func expandedTokensCommaSeparated() {
        let monitor = HotkeyMonitor()
        let tokens = monitor.expandedShortcutTokens(from: "cmd,shift,space")
        #expect(tokens.contains("cmd"))
        #expect(tokens.contains("shift"))
        #expect(tokens.contains("space"))
    }

    @Test("expandedShortcutTokens: option glyph ⌥")
    func expandedTokensOptionGlyph() {
        let monitor = HotkeyMonitor()
        let tokens = monitor.expandedShortcutTokens(from: "⌥f6")
        #expect(tokens.contains("option"))
        #expect(tokens.contains("f6"))
    }

    @Test("expandedShortcutTokens: control glyph ⌃")
    func expandedTokensControlGlyph() {
        let monitor = HotkeyMonitor()
        let tokens = monitor.expandedShortcutTokens(from: "⌃a")
        #expect(tokens.contains("control"))
        #expect(tokens.contains("a"))
    }

    @Test("expandedShortcutTokens: globe emoji 🌐")
    func expandedTokensGlobeEmoji() {
        let monitor = HotkeyMonitor()
        let tokens = monitor.expandedShortcutTokens(from: "🌐space")
        #expect(tokens.contains("globe"))
        #expect(tokens.contains("space"))
    }

    // MARK: - looksLikeShortcutCombo

    @Test("looksLikeShortcutCombo: single key is not a combo")
    func shortcutComboSingleKey() {
        let monitor = HotkeyMonitor()
        #expect(!monitor.looksLikeShortcutCombo("space"))
    }

    @Test("looksLikeShortcutCombo: plus sign makes it a combo")
    func shortcutComboPlusSign() {
        let monitor = HotkeyMonitor()
        #expect(monitor.looksLikeShortcutCombo("cmd+space"))
    }

    @Test("looksLikeShortcutCombo: modifier word + key is a combo")
    func shortcutComboModifierAndKey() {
        let monitor = HotkeyMonitor()
        #expect(monitor.looksLikeShortcutCombo("command space"))
    }

    @Test("looksLikeShortcutCombo: two non-modifier words is not a combo")
    func shortcutComboTwoNonModifiers() {
        let monitor = HotkeyMonitor()
        #expect(!monitor.looksLikeShortcutCombo("space return"))
    }

    @Test("looksLikeShortcutCombo: glyph combo")
    func shortcutComboGlyphs() {
        let monitor = HotkeyMonitor()
        #expect(monitor.looksLikeShortcutCombo("⌘⇧space"))
    }

    @Test("looksLikeShortcutCombo: single modifier word alone is not a combo")
    func shortcutComboSingleModifier() {
        let monitor = HotkeyMonitor()
        #expect(!monitor.looksLikeShortcutCombo("command"))
    }

    // MARK: - looksLikeModifierOnlyInput

    @Test("looksLikeModifierOnlyInput: single modifier word")
    func modifierOnlySingleWord() {
        let monitor = HotkeyMonitor()
        #expect(monitor.looksLikeModifierOnlyInput("command"))
    }

    @Test("looksLikeModifierOnlyInput: multiple modifier words")
    func modifierOnlyMultipleWords() {
        let monitor = HotkeyMonitor()
        #expect(monitor.looksLikeModifierOnlyInput("cmd shift"))
    }

    @Test("looksLikeModifierOnlyInput: modifier + key is not modifier-only")
    func modifierOnlyWithKey() {
        let monitor = HotkeyMonitor()
        #expect(!monitor.looksLikeModifierOnlyInput("cmd space"))
    }

    @Test("looksLikeModifierOnlyInput: plain key is not modifier-only")
    func modifierOnlyPlainKey() {
        let monitor = HotkeyMonitor()
        #expect(!monitor.looksLikeModifierOnlyInput("space"))
    }

    @Test("looksLikeModifierOnlyInput: empty input is not modifier-only")
    func modifierOnlyEmptyInput() {
        let monitor = HotkeyMonitor()
        #expect(!monitor.looksLikeModifierOnlyInput(""))
    }

    @Test("looksLikeModifierOnlyInput: glyph modifier symbols")
    func modifierOnlyGlyphs() {
        let monitor = HotkeyMonitor()
        #expect(monitor.looksLikeModifierOnlyInput("⌘⇧"))
    }

    // MARK: - normalizedOutOfRangeFunctionKeyInput

    @Test("normalizedOutOfRangeFunctionKeyInput: F1 is in range")
    func outOfRangeF1() {
        let monitor = HotkeyMonitor()
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("f1") == nil)
    }

    @Test("normalizedOutOfRangeFunctionKeyInput: F24 is in range")
    func outOfRangeF24() {
        let monitor = HotkeyMonitor()
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("f24") == nil)
    }

    @Test("normalizedOutOfRangeFunctionKeyInput: F25 is out of range")
    func outOfRangeF25() {
        let monitor = HotkeyMonitor()
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("f25") == "F25")
    }

    @Test("normalizedOutOfRangeFunctionKeyInput: F0 is out of range")
    func outOfRangeF0() {
        let monitor = HotkeyMonitor()
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("f0") == "F0")
    }

    @Test("normalizedOutOfRangeFunctionKeyInput: F99 is out of range")
    func outOfRangeF99() {
        let monitor = HotkeyMonitor()
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("f99") == "F99")
    }

    @Test("normalizedOutOfRangeFunctionKeyInput: non-function key returns nil")
    func outOfRangeNonFunctionKey() {
        let monitor = HotkeyMonitor()
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("space") == nil)
    }

    @Test("normalizedOutOfRangeFunctionKeyInput: plain letter returns nil")
    func outOfRangePlainLetter() {
        let monitor = HotkeyMonitor()
        #expect(monitor.normalizedOutOfRangeFunctionKeyInput("a") == nil)
    }

    // MARK: - parseFunctionKeyNumber

    @Test("parseFunctionKeyNumber: f1 returns 1")
    func parseFnF1() {
        let monitor = HotkeyMonitor()
        #expect(monitor.parseFunctionKeyNumber("f1") == 1)
    }

    @Test("parseFunctionKeyNumber: f24 returns 24")
    func parseFnF24() {
        let monitor = HotkeyMonitor()
        #expect(monitor.parseFunctionKeyNumber("f24") == 24)
    }

    @Test("parseFunctionKeyNumber: fn12 returns 12")
    func parseFnFn12() {
        let monitor = HotkeyMonitor()
        #expect(monitor.parseFunctionKeyNumber("fn12") == 12)
    }

    @Test("parseFunctionKeyNumber: function5 returns 5")
    func parseFnFunction5() {
        let monitor = HotkeyMonitor()
        #expect(monitor.parseFunctionKeyNumber("function5") == 5)
    }

    @Test("parseFunctionKeyNumber: fkey3 returns 3")
    func parseFnFkey3() {
        let monitor = HotkeyMonitor()
        #expect(monitor.parseFunctionKeyNumber("fkey3") == 3)
    }

    @Test("parseFunctionKeyNumber: fnkey8 returns 8")
    func parseFnFnkey8() {
        let monitor = HotkeyMonitor()
        #expect(monitor.parseFunctionKeyNumber("fnkey8") == 8)
    }

    @Test("parseFunctionKeyNumber: functionkey2 returns 2")
    func parseFnFunctionKey2() {
        let monitor = HotkeyMonitor()
        #expect(monitor.parseFunctionKeyNumber("functionkey2") == 2)
    }

    @Test("parseFunctionKeyNumber: space returns nil")
    func parseFnSpace() {
        let monitor = HotkeyMonitor()
        #expect(monitor.parseFunctionKeyNumber("space") == nil)
    }

    @Test("parseFunctionKeyNumber: empty returns nil")
    func parseFnEmpty() {
        let monitor = HotkeyMonitor()
        #expect(monitor.parseFunctionKeyNumber("") == nil)
    }

    @Test("parseFunctionKeyNumber: f returns nil (no digits)")
    func parseFnFAlone() {
        let monitor = HotkeyMonitor()
        #expect(monitor.parseFunctionKeyNumber("f") == nil)
    }

    @Test("parseFunctionKeyNumber: fabc returns nil (non-numeric)")
    func parseFnFabc() {
        let monitor = HotkeyMonitor()
        #expect(monitor.parseFunctionKeyNumber("fabc") == nil)
    }

    // MARK: - allowsNoModifierTrigger

    @Test("allowsNoModifierTrigger: function keys F1-F24 allowed")
    func noModF1() {
        let monitor = HotkeyMonitor()
        #expect(monitor.allowsNoModifierTrigger("f1"))
        #expect(monitor.allowsNoModifierTrigger("f12"))
        #expect(monitor.allowsNoModifierTrigger("f24"))
    }

    @Test("allowsNoModifierTrigger: F0 and F25 not allowed")
    func noModOutOfRangeF() {
        let monitor = HotkeyMonitor()
        #expect(!monitor.allowsNoModifierTrigger("f0"))
        #expect(!monitor.allowsNoModifierTrigger("f25"))
    }

    @Test("allowsNoModifierTrigger: special keys allowed")
    func noModSpecialKeys() {
        let monitor = HotkeyMonitor()
        #expect(monitor.allowsNoModifierTrigger("escape"))
        #expect(monitor.allowsNoModifierTrigger("tab"))
        #expect(monitor.allowsNoModifierTrigger("return"))
        #expect(monitor.allowsNoModifierTrigger("space"))
        #expect(monitor.allowsNoModifierTrigger("delete"))
        #expect(monitor.allowsNoModifierTrigger("backspace"))
        #expect(monitor.allowsNoModifierTrigger("insert"))
        #expect(monitor.allowsNoModifierTrigger("home"))
        #expect(monitor.allowsNoModifierTrigger("end"))
        #expect(monitor.allowsNoModifierTrigger("pageup"))
        #expect(monitor.allowsNoModifierTrigger("pagedown"))
    }

    @Test("allowsNoModifierTrigger: arrow keys allowed")
    func noModArrowKeys() {
        let monitor = HotkeyMonitor()
        #expect(monitor.allowsNoModifierTrigger("left"))
        #expect(monitor.allowsNoModifierTrigger("right"))
        #expect(monitor.allowsNoModifierTrigger("up"))
        #expect(monitor.allowsNoModifierTrigger("down"))
    }

    @Test("allowsNoModifierTrigger: keypad keys allowed")
    func noModKeypadKeys() {
        let monitor = HotkeyMonitor()
        #expect(monitor.allowsNoModifierTrigger("keypad0"))
        #expect(monitor.allowsNoModifierTrigger("numpad9"))
        #expect(monitor.allowsNoModifierTrigger("keypaddecimal"))
        #expect(monitor.allowsNoModifierTrigger("keypadplus"))
        #expect(monitor.allowsNoModifierTrigger("keypadclear"))
    }

    @Test("allowsNoModifierTrigger: regular letter key not allowed")
    func noModLetterKey() {
        let monitor = HotkeyMonitor()
        #expect(!monitor.allowsNoModifierTrigger("a"))
        #expect(!monitor.allowsNoModifierTrigger("z"))
    }

    @Test("allowsNoModifierTrigger: number key not allowed")
    func noModNumberKey() {
        let monitor = HotkeyMonitor()
        #expect(!monitor.allowsNoModifierTrigger("1"))
        #expect(!monitor.allowsNoModifierTrigger("0"))
    }

    @Test("allowsNoModifierTrigger: slash not allowed")
    func noModSlash() {
        let monitor = HotkeyMonitor()
        #expect(!monitor.allowsNoModifierTrigger("/"))
    }

    @Test("allowsNoModifierTrigger: case insensitive")
    func noModCaseInsensitive() {
        let monitor = HotkeyMonitor()
        #expect(monitor.allowsNoModifierTrigger("Escape"))
        #expect(monitor.allowsNoModifierTrigger("SPACE"))
        #expect(monitor.allowsNoModifierTrigger("F12"))
    }

    @Test("allowsNoModifierTrigger: alternate names for delete")
    func noModDeleteAliases() {
        let monitor = HotkeyMonitor()
        #expect(monitor.allowsNoModifierTrigger("del"))
        #expect(monitor.allowsNoModifierTrigger("bksp"))
        #expect(monitor.allowsNoModifierTrigger("forwarddelete"))
        #expect(monitor.allowsNoModifierTrigger("fwddelete"))
        #expect(monitor.allowsNoModifierTrigger("fwddel"))
    }

    @Test("allowsNoModifierTrigger: enter aliases")
    func noModEnterAliases() {
        let monitor = HotkeyMonitor()
        #expect(monitor.allowsNoModifierTrigger("enter"))
        #expect(monitor.allowsNoModifierTrigger("keypadenter"))
        #expect(monitor.allowsNoModifierTrigger("numpadenter"))
    }

    @Test("allowsNoModifierTrigger: globe/fn/capslock aliases")
    func noModGlobeFnCaps() {
        let monitor = HotkeyMonitor()
        #expect(monitor.allowsNoModifierTrigger("fn"))
        #expect(monitor.allowsNoModifierTrigger("function"))
        #expect(monitor.allowsNoModifierTrigger("globe"))
        #expect(monitor.allowsNoModifierTrigger("globekey"))
        #expect(monitor.allowsNoModifierTrigger("caps"))
        #expect(monitor.allowsNoModifierTrigger("capslock"))
    }

    // MARK: - temporaryStatusResetDelayNanosecondsForTesting

    @Test("temporaryStatusResetDelay: returns non-zero value")
    func statusResetDelayNonZero() {
        let monitor = HotkeyMonitor()
        let delay = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: "test")
        #expect(delay > 0)
    }

    @Test("temporaryStatusResetDelay: longer message may have longer delay")
    func statusResetDelayLongerMessage() {
        let monitor = HotkeyMonitor()
        let short = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: "ok")
        let long = monitor.temporaryStatusResetDelayNanosecondsForTesting(message: String(repeating: "word ", count: 50))
        #expect(long >= short)
    }

    // MARK: - holdSessionArmedForTesting

    @Test("holdSessionArmed: starts as false")
    func holdSessionArmedDefault() {
        let monitor = HotkeyMonitor()
        #expect(!monitor.holdSessionArmedForTesting)
    }
}
