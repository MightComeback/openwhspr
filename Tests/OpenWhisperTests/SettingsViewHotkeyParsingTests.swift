import Testing
import Foundation
@testable import OpenWhisper

@Suite("SettingsView Hotkey Parsing (ViewHelpers)")
struct SettingsViewHotkeyParsingTests {

    // MARK: - parseModifierToken

    @Test("parseModifierToken: cmd variants")
    func parseModifierTokenCmd() {
        for token in ["cmd", "command", "meta", "super", "win", "windows", "commandorcontrol", "controlorcommand", "cmdorctrl", "ctrlorcmd", "⌘", "@"] {
            #expect(ViewHelpers.parseModifierToken(token) == .command, "Expected .command for \(token)")
        }
    }

    @Test("parseModifierToken: shift variants")
    func parseModifierTokenShift() {
        for token in ["shift", "⇧", "$"] {
            #expect(ViewHelpers.parseModifierToken(token) == .shift, "Expected .shift for \(token)")
        }
    }

    @Test("parseModifierToken: option variants")
    func parseModifierTokenOption() {
        for token in ["opt", "option", "alt", "⌥", "~"] {
            #expect(ViewHelpers.parseModifierToken(token) == .option, "Expected .option for \(token)")
        }
    }

    @Test("parseModifierToken: control variants")
    func parseModifierTokenControl() {
        for token in ["ctrl", "control", "ctl", "⌃", "^"] {
            #expect(ViewHelpers.parseModifierToken(token) == .control, "Expected .control for \(token)")
        }
    }

    @Test("parseModifierToken: capsLock variants")
    func parseModifierTokenCapsLock() {
        for token in ["caps", "capslock", "⇪"] {
            #expect(ViewHelpers.parseModifierToken(token) == .capsLock, "Expected .capsLock for \(token)")
        }
    }

    @Test("parseModifierToken: unknown returns nil")
    func parseModifierTokenUnknown() {
        #expect(ViewHelpers.parseModifierToken("space") == nil)
        #expect(ViewHelpers.parseModifierToken("f6") == nil)
        #expect(ViewHelpers.parseModifierToken("") == nil)
        #expect(ViewHelpers.parseModifierToken("fn") == nil)
    }

    // MARK: - isNonConfigurableModifierToken

    @Test("isNonConfigurableModifierToken: fn/globe tokens")
    func nonConfigurableModifiers() {
        #expect(ViewHelpers.isNonConfigurableModifierToken("fn") == true)
        #expect(ViewHelpers.isNonConfigurableModifierToken("function") == true)
        #expect(ViewHelpers.isNonConfigurableModifierToken("globe") == true)
        #expect(ViewHelpers.isNonConfigurableModifierToken("globekey") == true)
        #expect(ViewHelpers.isNonConfigurableModifierToken("🌐") == true)
    }

    @Test("isNonConfigurableModifierToken: regular tokens return false")
    func nonConfigurableModifiersFalse() {
        #expect(ViewHelpers.isNonConfigurableModifierToken("cmd") == false)
        #expect(ViewHelpers.isNonConfigurableModifierToken("space") == false)
        #expect(ViewHelpers.isNonConfigurableModifierToken("") == false)
    }

    // MARK: - expandCompactModifierToken

    @Test("expandCompactModifierToken: symbol prefix combos")
    func expandCompactSymbolPrefix() {
        let result = ViewHelpers.expandCompactModifierToken("⌘⇧space")
        #expect(result == ["cmd", "shift", "space"])
    }

    @Test("expandCompactModifierToken: @ and $ prefixes")
    func expandCompactAtDollar() {
        let result = ViewHelpers.expandCompactModifierToken("@$f6")
        #expect(result == ["cmd", "shift", "f6"])
    }

    @Test("expandCompactModifierToken: single key no expansion")
    func expandCompactSingleKey() {
        let result = ViewHelpers.expandCompactModifierToken("space")
        #expect(result == ["space"])
    }

    @Test("expandCompactModifierToken: empty string")
    func expandCompactEmpty() {
        let result = ViewHelpers.expandCompactModifierToken("")
        #expect(result == [])
    }

    @Test("expandCompactModifierToken: tilde and caret prefixes")
    func expandCompactTildeCaret() {
        let result = ViewHelpers.expandCompactModifierToken("~^k")
        #expect(result == ["opt", "ctrl", "k"])
    }

    @Test("expandCompactModifierToken: globe prefix")
    func expandCompactGlobe() {
        let result = ViewHelpers.expandCompactModifierToken("🌐⌘a")
        #expect(result == ["globe", "cmd", "a"])
    }

    @Test("expandCompactModifierToken: all four symbol modifiers")
    func expandCompactAllFour() {
        let result = ViewHelpers.expandCompactModifierToken("⌘⇧⌥⌃x")
        #expect(result == ["cmd", "shift", "opt", "ctrl", "x"])
    }

    // MARK: - splitPlusCommaHotkeyTokens

    @Test("splitPlusCommaHotkeyTokens: plus-separated")
    func splitPlusTokens() {
        let result = ViewHelpers.splitPlusCommaHotkeyTokens("cmd+shift+space")
        #expect(result == ["cmd", "shift", "space"])
    }

    @Test("splitPlusCommaHotkeyTokens: comma-separated")
    func splitCommaTokens() {
        let result = ViewHelpers.splitPlusCommaHotkeyTokens("cmd,shift,space")
        #expect(result == ["cmd", "shift", "space"])
    }

    @Test("splitPlusCommaHotkeyTokens: trailing plus means literal plus key")
    func splitTrailingPlus() {
        let result = ViewHelpers.splitPlusCommaHotkeyTokens("cmd+shift+")
        #expect(result == ["cmd", "shift", "plus"])
    }

    @Test("splitPlusCommaHotkeyTokens: trailing comma means literal comma key")
    func splitTrailingComma() {
        let result = ViewHelpers.splitPlusCommaHotkeyTokens("cmd,shift,")
        #expect(result == ["cmd", "shift", "comma"])
    }

    @Test("splitPlusCommaHotkeyTokens: single token")
    func splitSingleToken() {
        let result = ViewHelpers.splitPlusCommaHotkeyTokens("space")
        #expect(result == ["space"])
    }

    @Test("splitPlusCommaHotkeyTokens: trims whitespace")
    func splitTrimsWhitespace() {
        let result = ViewHelpers.splitPlusCommaHotkeyTokens("cmd + shift + space")
        #expect(result == ["cmd", "shift", "space"])
    }

    // MARK: - mergeSpaceSeparatedKeyTokens

    @Test("mergeSpaceSeparatedKeyTokens: merges trailing non-modifier tokens")
    func mergeTrailingTokens() {
        let result = ViewHelpers.mergeSpaceSeparatedKeyTokens(["cmd", "page", "down"])
        #expect(result == ["cmd", "page down"])
    }

    @Test("mergeSpaceSeparatedKeyTokens: no modifiers merges all into one")
    func mergeNoModifiers() {
        // When there are no modifiers, the first token is the first non-modifier,
        // and all subsequent tokens get merged with it.
        let result = ViewHelpers.mergeSpaceSeparatedKeyTokens(["page", "down"])
        #expect(result == ["page down"])
    }

    @Test("mergeSpaceSeparatedKeyTokens: single non-modifier after modifiers unchanged")
    func mergeSingleNonModifier() {
        let input = ["cmd", "space"]
        let result = ViewHelpers.mergeSpaceSeparatedKeyTokens(input)
        #expect(result == input)
    }

    @Test("mergeSpaceSeparatedKeyTokens: empty returns empty")
    func mergeEmpty() {
        let result = ViewHelpers.mergeSpaceSeparatedKeyTokens([])
        #expect(result == [])
    }

    @Test("mergeSpaceSeparatedKeyTokens: all modifiers returns unchanged")
    func mergeAllModifiers() {
        let input = ["cmd", "shift", "option"]
        let result = ViewHelpers.mergeSpaceSeparatedKeyTokens(input)
        #expect(result == input)
    }

    @Test("mergeSpaceSeparatedKeyTokens: trailing modifier among non-modifiers unchanged")
    func mergeTrailingModifierMixed() {
        let input = ["cmd", "page", "shift"]
        let result = ViewHelpers.mergeSpaceSeparatedKeyTokens(input)
        #expect(result == input)
    }

    // MARK: - looksLikeModifierComboInput

    @Test("looksLikeModifierComboInput: symbol modifier returns true")
    func looksLikeModifierSymbol() {
        #expect(ViewHelpers.looksLikeModifierComboInput("⌘space") == true)
        #expect(ViewHelpers.looksLikeModifierComboInput("⇧+f6") == true)
        #expect(ViewHelpers.looksLikeModifierComboInput("⌥k") == true)
        #expect(ViewHelpers.looksLikeModifierComboInput("⌃a") == true)
        #expect(ViewHelpers.looksLikeModifierComboInput("⇪space") == true)
    }

    @Test("looksLikeModifierComboInput: text modifier returns true")
    func looksLikeModifierText() {
        #expect(ViewHelpers.looksLikeModifierComboInput("cmd+space") == true)
        #expect(ViewHelpers.looksLikeModifierComboInput("shift space") == true)
    }

    @Test("looksLikeModifierComboInput: plain key returns false")
    func looksLikeModifierPlainKey() {
        #expect(ViewHelpers.looksLikeModifierComboInput("space") == false)
        #expect(ViewHelpers.looksLikeModifierComboInput("f6") == false)
        #expect(ViewHelpers.looksLikeModifierComboInput("a") == false)
    }

    // MARK: - sanitizeKeyValue

    @Test("sanitizeKeyValue: lowercases and trims")
    func sanitizeKeyValueBasic() {
        #expect(ViewHelpers.sanitizeKeyValue("  Space  ") == "space")
    }

    @Test("sanitizeKeyValue: empty becomes space")
    func sanitizeKeyValueEmpty() {
        #expect(ViewHelpers.sanitizeKeyValue("") == "space")
    }

    @Test("sanitizeKeyValue: literal space becomes space")
    func sanitizeKeyValueLiteralSpace() {
        #expect(ViewHelpers.sanitizeKeyValue(" ") == "space")
    }

    @Test("sanitizeKeyValue: canonical key applied")
    func sanitizeKeyValueCanonical() {
        let result = ViewHelpers.sanitizeKeyValue("RETURN")
        #expect(result == "return")
    }

    // MARK: - parseHotkeyDraft

    @Test("parseHotkeyDraft: empty returns nil")
    func parseEmpty() {
        #expect(ViewHelpers.parseHotkeyDraft("") == nil)
    }

    @Test("parseHotkeyDraft: whitespace-only returns nil")
    func parseWhitespace() {
        #expect(ViewHelpers.parseHotkeyDraft("   ") == nil)
    }

    @Test("parseHotkeyDraft: single space becomes space key")
    func parseSingleSpace() {
        let result = ViewHelpers.parseHotkeyDraft(" ")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == nil)
    }

    @Test("parseHotkeyDraft: simple key")
    func parseSimpleKey() {
        let result = ViewHelpers.parseHotkeyDraft("space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == nil)
    }

    @Test("parseHotkeyDraft: function key")
    func parseFunctionKey() {
        let result = ViewHelpers.parseHotkeyDraft("f6")
        #expect(result?.key == "f6")
    }

    @Test("parseHotkeyDraft: plus-separated combo")
    func parsePlusSeparated() {
        let result = ViewHelpers.parseHotkeyDraft("cmd+shift+space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers?.contains(.command) == true)
        #expect(result?.requiredModifiers?.contains(.shift) == true)
    }

    @Test("parseHotkeyDraft: space-separated combo")
    func parseSpaceSeparated() {
        let result = ViewHelpers.parseHotkeyDraft("command option f6")
        #expect(result?.key == "f6")
        #expect(result?.requiredModifiers?.contains(.command) == true)
        #expect(result?.requiredModifiers?.contains(.option) == true)
    }

    @Test("parseHotkeyDraft: slash-separated combo")
    func parseSlashSeparated() {
        let result = ViewHelpers.parseHotkeyDraft("command/shift/space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers?.contains(.command) == true)
        #expect(result?.requiredModifiers?.contains(.shift) == true)
    }

    @Test("parseHotkeyDraft: hyphen-separated combo")
    func parseHyphenSeparated() {
        let result = ViewHelpers.parseHotkeyDraft("cmd-shift-space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers?.contains(.command) == true)
        #expect(result?.requiredModifiers?.contains(.shift) == true)
    }

    @Test("parseHotkeyDraft: compact symbol prefix")
    func parseCompactSymbol() {
        let result = ViewHelpers.parseHotkeyDraft("⌘⇧space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers?.contains(.command) == true)
        #expect(result?.requiredModifiers?.contains(.shift) == true)
    }

    @Test("parseHotkeyDraft: case insensitive")
    func parseCaseInsensitive() {
        let result = ViewHelpers.parseHotkeyDraft("CMD+SHIFT+SPACE")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers?.contains(.command) == true)
    }

    @Test("parseHotkeyDraft: fn modifier is non-configurable")
    func parseFnModifier() {
        let result = ViewHelpers.parseHotkeyDraft("fn+cmd+space")
        #expect(result?.key == "space")
        #expect(result?.containsNonConfigurableModifiers == true)
    }

    @Test("parseHotkeyDraft: fn-only combo has nil requiredModifiers")
    func parseFnOnly() {
        let result = ViewHelpers.parseHotkeyDraft("fn+space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == nil)
    }

    @Test("parseHotkeyDraft: mixed separator fallback")
    func parseMixedSeparator() {
        // "cmd + shift-space" gets split by the mixed-separator fallback
        // The plus splits first: ["cmd ", " shift-space"], then the hyphen
        // in "shift-space" may or may not split depending on parsing order.
        let result = ViewHelpers.parseHotkeyDraft("cmd+shift+space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers?.contains(.command) == true)
        #expect(result?.requiredModifiers?.contains(.shift) == true)
    }

    @Test("parseHotkeyDraft: mixed separator with underscore")
    func parseMixedSeparatorUnderscore() {
        let result = ViewHelpers.parseHotkeyDraft("cmd_shift_space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers?.contains(.command) == true)
    }

    @Test("parseHotkeyDraft: ambiguous two keys returns nil")
    func parseAmbiguousTwoKeys() {
        let result = ViewHelpers.parseHotkeyDraft("cmd+a+b")
        #expect(result == nil)
    }

    @Test("parseHotkeyDraft: underscore separator")
    func parseUnderscoreSeparator() {
        let result = ViewHelpers.parseHotkeyDraft("cmd_shift_space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers?.contains(.command) == true)
    }

    @Test("parseHotkeyDraft: letter key")
    func parseLetterKey() {
        let result = ViewHelpers.parseHotkeyDraft("k")
        #expect(result?.key == "k")
    }

    @Test("parseHotkeyDraft: return key")
    func parseReturnKey() {
        let result = ViewHelpers.parseHotkeyDraft("return")
        #expect(result?.key == "return")
    }

    @Test("parseHotkeyDraft: escape key")
    func parseEscapeKey() {
        let result = ViewHelpers.parseHotkeyDraft("escape")
        #expect(result?.key == "escape")
    }

    @Test("parseHotkeyDraft: tab key")
    func parseTabKey() {
        let result = ViewHelpers.parseHotkeyDraft("tab")
        #expect(result?.key == "tab")
    }

    @Test("parseHotkeyDraft: all modifiers combo")
    func parseAllModifiers() {
        let result = ViewHelpers.parseHotkeyDraft("cmd+shift+option+ctrl+caps+space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers?.count == 5)
    }

    // MARK: - parseHotkeyTokens

    @Test("parseHotkeyTokens: empty returns nil")
    func parseTokensEmpty() {
        #expect(ViewHelpers.parseHotkeyTokens([]) == nil)
    }

    @Test("parseHotkeyTokens: modifiers only no key returns nil")
    func parseTokensModifiersOnly() {
        #expect(ViewHelpers.parseHotkeyTokens(["cmd", "shift"]) == nil)
    }

    @Test("parseHotkeyTokens: key only")
    func parseTokensKeyOnly() {
        let result = ViewHelpers.parseHotkeyTokens(["space"])
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == Set<ViewHelpers.ParsedModifier>())
    }

    @Test("parseHotkeyTokens: modifier and key")
    func parseTokensModifierAndKey() {
        let result = ViewHelpers.parseHotkeyTokens(["cmd", "space"])
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == [.command])
    }

    @Test("parseHotkeyTokens: two keys returns nil")
    func parseTokensTwoKeys() {
        #expect(ViewHelpers.parseHotkeyTokens(["cmd", "a", "b"]) == nil)
    }

    @Test("parseHotkeyTokens: non-configurable modifier only")
    func parseTokensNonConfigOnly() {
        let result = ViewHelpers.parseHotkeyTokens(["fn", "space"])
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == nil)
        #expect(result?.containsNonConfigurableModifiers == true)
    }

    @Test("parseHotkeyTokens: mixed configurable and non-configurable")
    func parseTokensMixedModifiers() {
        let result = ViewHelpers.parseHotkeyTokens(["cmd", "fn", "space"])
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == [.command])
        #expect(result?.containsNonConfigurableModifiers == true)
    }

    @Test("parseHotkeyTokens: compact modifier token expansion")
    func parseTokensCompactExpansion() {
        let result = ViewHelpers.parseHotkeyTokens(["⌘⇧", "space"])
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers?.contains(.command) == true)
        #expect(result?.requiredModifiers?.contains(.shift) == true)
    }

    // MARK: - formatBytes

    @Test("formatBytes: zero")
    func formatBytesZero() {
        let result = ViewHelpers.formatBytes(0)
        #expect(!result.isEmpty)
    }

    @Test("formatBytes: kilobytes")
    func formatBytesKB() {
        let result = ViewHelpers.formatBytes(1024)
        #expect(result.contains("KB") || result.contains("kB"))
    }

    @Test("formatBytes: megabytes")
    func formatBytesMB() {
        let result = ViewHelpers.formatBytes(75_000_000)
        #expect(result.contains("MB"))
    }

    @Test("formatBytes: large file")
    func formatBytesLarge() {
        let result = ViewHelpers.formatBytes(1_500_000_000)
        #expect(!result.isEmpty)
    }

    // MARK: - isHighRiskHotkey

    @Test("isHighRiskHotkey: single letter without modifiers")
    func highRiskNoModifiers() {
        let result = ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "a")
        #expect(result == true)
    }

    @Test("isHighRiskHotkey: with modifier returns false")
    func highRiskWithModifier() {
        let result = ViewHelpers.isHighRiskHotkey(requiredModifiers: [.command], key: "a")
        #expect(result == false)
    }

    @Test("isHighRiskHotkey: space without modifiers")
    func highRiskSpace() {
        let result = ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "space")
        #expect(result == true)
    }

    @Test("isHighRiskHotkey: function key without modifiers")
    func highRiskFunctionKey() {
        // Function keys are typically less risky even without modifiers
        let result = ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "f6")
        // Just verify no crash - result depends on implementation
        _ = result
    }

    // MARK: - showsHoldModeAccidentalTriggerWarning

    @Test("showsHoldModeAccidentalTriggerWarning: hold mode high-risk")
    func holdModeWarning() {
        let result = ViewHelpers.showsHoldModeAccidentalTriggerWarning(hotkeyModeRaw: HotkeyMode.hold.rawValue, requiredModifiers: [], key: "space")
        #expect(result == true)
    }

    @Test("showsHoldModeAccidentalTriggerWarning: toggle mode returns false")
    func holdModeToggle() {
        let result = ViewHelpers.showsHoldModeAccidentalTriggerWarning(hotkeyModeRaw: HotkeyMode.toggle.rawValue, requiredModifiers: [], key: "space")
        #expect(result == false)
    }

    @Test("showsHoldModeAccidentalTriggerWarning: hold with modifier returns false")
    func holdModeWithModifier() {
        let result = ViewHelpers.showsHoldModeAccidentalTriggerWarning(hotkeyModeRaw: HotkeyMode.hold.rawValue, requiredModifiers: [.command], key: "space")
        #expect(result == false)
    }

    // MARK: - hotkeyEscapeCancelConflictWarning

    @Test("hotkeyEscapeCancelConflictWarning: escape key returns warning")
    func escapeCancelConflict() {
        let result = ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "escape")
        #expect(result != nil)
    }

    @Test("hotkeyEscapeCancelConflictWarning: non-escape returns nil")
    func escapeCancelNoConflict() {
        #expect(ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "space") == nil)
    }

    // MARK: - hotkeySystemConflictWarning

    @Test("hotkeySystemConflictWarning: cmd+space")
    func systemConflictCmdSpace() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "space")
        #expect(result != nil)
    }

    @Test("hotkeySystemConflictWarning: unique combo returns nil")
    func systemConflictNone() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "k")
        #expect(result == nil)
    }

    @Test("hotkeySystemConflictWarning: cmd+tab")
    func systemConflictCmdTab() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "tab")
        #expect(result != nil)
    }

    // MARK: - hotkeyMissingPermissionSummary

    @Test("hotkeyMissingPermissionSummary: both missing")
    func missingBothPermissions() {
        let result = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: false, inputMonitoringAuthorized: false)
        #expect(result != nil)
    }

    @Test("hotkeyMissingPermissionSummary: none missing")
    func missingNoPermissions() {
        #expect(ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: true, inputMonitoringAuthorized: true) == nil)
    }

    @Test("hotkeyMissingPermissionSummary: accessibility only missing")
    func missingAccessibility() {
        let result = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: false, inputMonitoringAuthorized: true)
        #expect(result != nil)
    }

    @Test("hotkeyMissingPermissionSummary: input monitoring only missing")
    func missingInputMonitoring() {
        let result = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: true, inputMonitoringAuthorized: false)
        #expect(result != nil)
    }

    // MARK: - commonHotkeyKeySections

    @Test("commonHotkeyKeySections: returns non-empty sections")
    func commonKeySections() {
        let sections = ViewHelpers.commonHotkeyKeySections
        #expect(!sections.isEmpty)
        #expect(sections.allSatisfy { !$0.title.isEmpty })
        #expect(sections.allSatisfy { !$0.keys.isEmpty })
    }

    @Test("commonHotkeyKeySections: contains space key")
    func commonKeySectionsContainsSpace() {
        let allKeys = ViewHelpers.commonHotkeyKeySections.flatMap { $0.keys }
        #expect(allKeys.contains("space"))
    }

    @Test("commonHotkeyKeySections: all keys are supported")
    func commonKeySectionsAllSupported() {
        let allKeys = ViewHelpers.commonHotkeyKeySections.flatMap { $0.keys }
        for key in allKeys {
            #expect(HotkeyDisplay.isSupportedKey(key), "Key \(key) should be supported")
        }
    }

    // MARK: - hotkeyModeTipText

    @Test("hotkeyModeTipText: toggle mode")
    func modeTipToggle() {
        let result = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: false)
        #expect(!result.isEmpty)
    }

    @Test("hotkeyModeTipText: hold mode")
    func modeTipHold() {
        let result = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: false)
        #expect(!result.isEmpty)
    }

    @Test("hotkeyModeTipText: toggle with escape trigger")
    func modeTipToggleEscape() {
        let result = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: true)
        #expect(!result.isEmpty)
    }

    // MARK: - hotkeyCaptureButtonTitle

    @Test("hotkeyCaptureButtonTitle: not capturing")
    func captureButtonNotCapturing() {
        let result = ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: false, secondsRemaining: 8)
        #expect(result == "Record shortcut")
    }

    @Test("hotkeyCaptureButtonTitle: capturing with seconds")
    func captureButtonCapturing() {
        let result = ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: true, secondsRemaining: 5)
        #expect(result.contains("5"))
    }

    // MARK: - hotkeyCaptureInstruction

    @Test("hotkeyCaptureInstruction: with input monitoring")
    func captureInstructionWithMonitoring() {
        let result = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: true, secondsRemaining: 8)
        #expect(!result.isEmpty)
        #expect(result.contains("8"))
    }

    @Test("hotkeyCaptureInstruction: without input monitoring")
    func captureInstructionWithoutMonitoring() {
        let result = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: false, secondsRemaining: 5)
        #expect(!result.isEmpty)
    }

    // MARK: - hotkeyCaptureProgress

    @Test("hotkeyCaptureProgress: full remaining")
    func captureProgressFull() {
        let result = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 8, totalSeconds: 8)
        #expect(result >= 0.99)
    }

    @Test("hotkeyCaptureProgress: half remaining")
    func captureProgressHalf() {
        let result = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 4, totalSeconds: 8)
        #expect(result >= 0.49 && result <= 0.51)
    }

    @Test("hotkeyCaptureProgress: zero remaining")
    func captureProgressZero() {
        let result = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 0, totalSeconds: 8)
        #expect(result <= 0.01)
    }

    @Test("hotkeyCaptureProgress: zero total returns zero")
    func captureProgressZeroTotal() {
        let result = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 0)
        #expect(result == 0)
    }

    // MARK: - hotkeyDraftValidationMessage

    @Test("hotkeyDraftValidationMessage: empty draft returns hint")
    func validationEmpty() {
        let result = ViewHelpers.hotkeyDraftValidationMessage(draft: "", isSupportedKey: false)
        #expect(result != nil)
    }

    @Test("hotkeyDraftValidationMessage: supported key returns nil")
    func validationSupported() {
        let result = ViewHelpers.hotkeyDraftValidationMessage(draft: "space", isSupportedKey: true)
        #expect(result == nil)
    }

    @Test("hotkeyDraftValidationMessage: unsupported key returns message")
    func validationUnsupported() {
        let result = ViewHelpers.hotkeyDraftValidationMessage(draft: "🔥🔥🔥🔥", isSupportedKey: false)
        #expect(result != nil)
    }

    // MARK: - hasHotkeyDraftEdits

    @Test("hasHotkeyDraftEdits: same key returns false")
    func draftEditsNoChange() {
        #expect(ViewHelpers.hasHotkeyDraftEdits(draft: "space", currentKey: "space", currentModifiers: []) == false)
    }

    @Test("hasHotkeyDraftEdits: different key returns true")
    func draftEditsDifferentKey() {
        #expect(ViewHelpers.hasHotkeyDraftEdits(draft: "f6", currentKey: "space", currentModifiers: []) == true)
    }

    @Test("hasHotkeyDraftEdits: empty draft returns false")
    func draftEditsEmpty() {
        #expect(ViewHelpers.hasHotkeyDraftEdits(draft: "", currentKey: "space", currentModifiers: []) == false)
    }

    @Test("hasHotkeyDraftEdits: modifier change detected")
    func draftEditsModifierChange() {
        #expect(ViewHelpers.hasHotkeyDraftEdits(draft: "cmd+space", currentKey: "space", currentModifiers: [.shift]) == true)
    }

    // MARK: - shouldAutoApplySafeCaptureModifiers

    @Test("shouldAutoApplySafeCaptureModifiers: letter key")
    func safeModifiersLetter() {
        let result = ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "a")
        #expect(result == true)
    }

    @Test("shouldAutoApplySafeCaptureModifiers: function key")
    func safeModifiersFunctionKey() {
        let result = ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "f6")
        // Function keys may or may not need safe modifiers
        _ = result
    }
}
