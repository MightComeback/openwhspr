import Testing
import Foundation
@testable import OpenWhisper

@Suite("ViewHelpers")
struct ViewHelpersTests {

    // MARK: - formatDuration

    @Test("formatDuration: zero")
    func formatDurationZero() {
        #expect(ViewHelpers.formatDuration(0) == "0:00")
    }

    @Test("formatDuration: negative clamps to zero")
    func formatDurationNegative() {
        #expect(ViewHelpers.formatDuration(-5) == "0:00")
    }

    @Test("formatDuration: seconds only")
    func formatDurationSeconds() {
        #expect(ViewHelpers.formatDuration(5) == "0:05")
        #expect(ViewHelpers.formatDuration(59) == "0:59")
    }

    @Test("formatDuration: minutes and seconds")
    func formatDurationMinutes() {
        #expect(ViewHelpers.formatDuration(60) == "1:00")
        #expect(ViewHelpers.formatDuration(125) == "2:05")
        #expect(ViewHelpers.formatDuration(3599) == "59:59")
    }

    @Test("formatDuration: hours")
    func formatDurationHours() {
        #expect(ViewHelpers.formatDuration(3600) == "1:00:00")
        #expect(ViewHelpers.formatDuration(3661) == "1:01:01")
        #expect(ViewHelpers.formatDuration(7384) == "2:03:04")
    }

    @Test("formatDuration: rounds to nearest second")
    func formatDurationRounding() {
        #expect(ViewHelpers.formatDuration(1.4) == "0:01")
        #expect(ViewHelpers.formatDuration(1.5) == "0:02")
        #expect(ViewHelpers.formatDuration(59.6) == "1:00")
    }

    // MARK: - formatShortDuration

    @Test("formatShortDuration: under a minute")
    func formatShortUnder60() {
        #expect(ViewHelpers.formatShortDuration(0) == "0s")
        #expect(ViewHelpers.formatShortDuration(30) == "30s")
        #expect(ViewHelpers.formatShortDuration(59) == "59s")
    }

    @Test("formatShortDuration: minutes")
    func formatShortMinutes() {
        #expect(ViewHelpers.formatShortDuration(60) == "1m 0s")
        #expect(ViewHelpers.formatShortDuration(90) == "1m 30s")
        #expect(ViewHelpers.formatShortDuration(125) == "2m 5s")
    }

    @Test("formatShortDuration: negative clamps")
    func formatShortNegative() {
        #expect(ViewHelpers.formatShortDuration(-10) == "0s")
    }

    // MARK: - abbreviatedAppName

    @Test("abbreviatedAppName: short names unchanged")
    func abbreviatedShort() {
        #expect(ViewHelpers.abbreviatedAppName("Safari") == "Safari")
        #expect(ViewHelpers.abbreviatedAppName("Notes") == "Notes")
    }

    @Test("abbreviatedAppName: exact length unchanged")
    func abbreviatedExact() {
        let name = String(repeating: "x", count: 18)
        #expect(ViewHelpers.abbreviatedAppName(name) == name)
    }

    @Test("abbreviatedAppName: long names truncated with ellipsis")
    func abbreviatedLong() {
        let name = "Visual Studio Code Extension Host"
        let result = ViewHelpers.abbreviatedAppName(name)
        #expect(result.count == 18)
        #expect(result.hasSuffix("…"))
    }

    @Test("abbreviatedAppName: custom max length")
    func abbreviatedCustomMax() {
        let result = ViewHelpers.abbreviatedAppName("Hello World", maxCharacters: 5)
        #expect(result == "Hell…")
    }

    @Test("abbreviatedAppName: whitespace trimmed before check")
    func abbreviatedWhitespace() {
        #expect(ViewHelpers.abbreviatedAppName("  Hi  ") == "Hi")
    }

    // MARK: - formatBytes

    @Test("formatBytes: various sizes")
    func formatBytesVariousSizes() {
        let small = ViewHelpers.formatBytes(1024)
        #expect(small.contains("KB"))

        let medium = ViewHelpers.formatBytes(1_048_576)
        #expect(medium.contains("MB"))

        let zero = ViewHelpers.formatBytes(0)
        #expect(zero == "Zero KB" || zero.contains("0"))
    }

    // MARK: - historyEntryStats

    @Test("historyEntryStats: words only")
    func historyStatsWordsOnly() {
        #expect(ViewHelpers.historyEntryStats(text: "hello world", durationSeconds: nil) == "2w")
    }

    @Test("historyEntryStats: words with short duration")
    func historyStatsWithShortDuration() {
        #expect(ViewHelpers.historyEntryStats(text: "one two three", durationSeconds: 45) == "3w · 45s")
    }

    @Test("historyEntryStats: words with long duration")
    func historyStatsWithLongDuration() {
        #expect(ViewHelpers.historyEntryStats(text: "one two three", durationSeconds: 125) == "3w · 2:05")
    }

    @Test("historyEntryStats: empty text")
    func historyStatsEmpty() {
        #expect(ViewHelpers.historyEntryStats(text: "", durationSeconds: nil) == "0w")
    }

    @Test("historyEntryStats: zero duration ignored")
    func historyStatsZeroDuration() {
        #expect(ViewHelpers.historyEntryStats(text: "word", durationSeconds: 0) == "1w")
    }

    // MARK: - statusTitle

    @Test("statusTitle: ready state")
    func statusTitleReady() {
        #expect(ViewHelpers.statusTitle(isRecording: false, recordingDuration: 0, pendingChunkCount: 0) == "Ready")
    }

    @Test("statusTitle: recording with duration")
    func statusTitleRecording() {
        #expect(ViewHelpers.statusTitle(isRecording: true, recordingDuration: 5, pendingChunkCount: 0) == "Recording • 0:05")
    }

    @Test("statusTitle: recording under 1s")
    func statusTitleRecordingShort() {
        #expect(ViewHelpers.statusTitle(isRecording: true, recordingDuration: 0.5, pendingChunkCount: 0) == "Recording")
    }

    @Test("statusTitle: finalizing singular")
    func statusTitleFinalizingSingular() {
        #expect(ViewHelpers.statusTitle(isRecording: false, recordingDuration: 0, pendingChunkCount: 1) == "Finalizing • 1 chunk")
    }

    @Test("statusTitle: finalizing plural")
    func statusTitleFinalizingPlural() {
        #expect(ViewHelpers.statusTitle(isRecording: false, recordingDuration: 0, pendingChunkCount: 3) == "Finalizing • 3 chunks")
    }

    // MARK: - finalizationProgress

    @Test("finalizationProgress: nil when recording")
    func finalizationProgressRecording() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 3, initialPendingChunks: 5, isRecording: true) == nil)
    }

    @Test("finalizationProgress: nil when no pending")
    func finalizationProgressNoPending() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 0, initialPendingChunks: 5, isRecording: false) == nil)
    }

    @Test("finalizationProgress: nil when no initial")
    func finalizationProgressNoInitial() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 3, initialPendingChunks: nil, isRecording: false) == nil)
    }

    @Test("finalizationProgress: 50%")
    func finalizationProgressHalf() {
        let progress = ViewHelpers.finalizationProgress(pendingChunkCount: 5, initialPendingChunks: 10, isRecording: false)
        #expect(progress == 0.5)
    }

    @Test("finalizationProgress: clamps to 1")
    func finalizationProgressClamp() {
        let progress = ViewHelpers.finalizationProgress(pendingChunkCount: 1, initialPendingChunks: 2, isRecording: false)
        #expect(progress == 0.5)
    }

    // MARK: - parseModifierToken

    @Test("parseModifierToken: command aliases")
    func parseModCommand() {
        #expect(ViewHelpers.parseModifierToken("cmd") == .command)
        #expect(ViewHelpers.parseModifierToken("command") == .command)
        #expect(ViewHelpers.parseModifierToken("meta") == .command)
        #expect(ViewHelpers.parseModifierToken("super") == .command)
        #expect(ViewHelpers.parseModifierToken("⌘") == .command)
        #expect(ViewHelpers.parseModifierToken("cmdorctrl") == .command)
    }

    @Test("parseModifierToken: shift aliases")
    func parseModShift() {
        #expect(ViewHelpers.parseModifierToken("shift") == .shift)
        #expect(ViewHelpers.parseModifierToken("⇧") == .shift)
    }

    @Test("parseModifierToken: option aliases")
    func parseModOption() {
        #expect(ViewHelpers.parseModifierToken("opt") == .option)
        #expect(ViewHelpers.parseModifierToken("option") == .option)
        #expect(ViewHelpers.parseModifierToken("alt") == .option)
        #expect(ViewHelpers.parseModifierToken("⌥") == .option)
    }

    @Test("parseModifierToken: control aliases")
    func parseModControl() {
        #expect(ViewHelpers.parseModifierToken("ctrl") == .control)
        #expect(ViewHelpers.parseModifierToken("control") == .control)
        #expect(ViewHelpers.parseModifierToken("⌃") == .control)
    }

    @Test("parseModifierToken: capslock")
    func parseModCaps() {
        #expect(ViewHelpers.parseModifierToken("caps") == .capsLock)
        #expect(ViewHelpers.parseModifierToken("capslock") == .capsLock)
        #expect(ViewHelpers.parseModifierToken("⇪") == .capsLock)
    }

    @Test("parseModifierToken: non-modifier returns nil")
    func parseModNonModifier() {
        #expect(ViewHelpers.parseModifierToken("space") == nil)
        #expect(ViewHelpers.parseModifierToken("a") == nil)
        #expect(ViewHelpers.parseModifierToken("f1") == nil)
    }

    // MARK: - isNonConfigurableModifierToken

    @Test("isNonConfigurableModifierToken: fn/globe")
    func nonConfigModFn() {
        #expect(ViewHelpers.isNonConfigurableModifierToken("fn") == true)
        #expect(ViewHelpers.isNonConfigurableModifierToken("globe") == true)
        #expect(ViewHelpers.isNonConfigurableModifierToken("🌐") == true)
        #expect(ViewHelpers.isNonConfigurableModifierToken("function") == true)
    }

    @Test("isNonConfigurableModifierToken: regular keys return false")
    func nonConfigModRegular() {
        #expect(ViewHelpers.isNonConfigurableModifierToken("cmd") == false)
        #expect(ViewHelpers.isNonConfigurableModifierToken("space") == false)
    }

    // MARK: - expandCompactModifierToken

    @Test("expandCompactModifierToken: symbol prefixes")
    func expandCompact() {
        #expect(ViewHelpers.expandCompactModifierToken("⌘⇧space") == ["cmd", "shift", "space"])
        #expect(ViewHelpers.expandCompactModifierToken("⌃⌥return") == ["ctrl", "opt", "return"])
    }

    @Test("expandCompactModifierToken: no modifiers")
    func expandCompactNoMod() {
        #expect(ViewHelpers.expandCompactModifierToken("space") == ["space"])
        #expect(ViewHelpers.expandCompactModifierToken("a") == ["a"])
    }

    @Test("expandCompactModifierToken: empty")
    func expandCompactEmpty() {
        #expect(ViewHelpers.expandCompactModifierToken("") == [])
    }

    // MARK: - splitPlusCommaHotkeyTokens

    @Test("splitPlusCommaHotkeyTokens: plus-separated")
    func splitPlus() {
        #expect(ViewHelpers.splitPlusCommaHotkeyTokens("cmd+shift+space") == ["cmd", "shift", "space"])
    }

    @Test("splitPlusCommaHotkeyTokens: trailing plus becomes 'plus'")
    func splitTrailingPlus() {
        let result = ViewHelpers.splitPlusCommaHotkeyTokens("cmd+")
        #expect(result == ["cmd", "plus"])
    }

    @Test("splitPlusCommaHotkeyTokens: trailing comma becomes 'comma'")
    func splitTrailingComma() {
        let result = ViewHelpers.splitPlusCommaHotkeyTokens("cmd,")
        #expect(result == ["cmd", "comma"])
    }

    // MARK: - mergeSpaceSeparatedKeyTokens

    @Test("mergeSpaceSeparatedKeyTokens: merges trailing key tokens")
    func mergeSpaceTokens() {
        let result = ViewHelpers.mergeSpaceSeparatedKeyTokens(["cmd", "page", "down"])
        #expect(result == ["cmd", "page down"])
    }

    @Test("mergeSpaceSeparatedKeyTokens: no merge when trailing has modifiers")
    func mergeSpaceNoMerge() {
        let tokens = ["cmd", "space", "shift"]
        #expect(ViewHelpers.mergeSpaceSeparatedKeyTokens(tokens) == tokens)
    }

    @Test("mergeSpaceSeparatedKeyTokens: single key untouched")
    func mergeSpaceSingle() {
        let tokens = ["cmd", "space"]
        #expect(ViewHelpers.mergeSpaceSeparatedKeyTokens(tokens) == tokens)
    }

    // MARK: - parseHotkeyDraft

    @Test("parseHotkeyDraft: single space character")
    func parseDraftSpace() {
        let result = ViewHelpers.parseHotkeyDraft(" ")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == nil)
    }

    @Test("parseHotkeyDraft: empty returns nil")
    func parseDraftEmpty() {
        #expect(ViewHelpers.parseHotkeyDraft("") == nil)
        #expect(ViewHelpers.parseHotkeyDraft("   ") == nil)
    }

    @Test("parseHotkeyDraft: simple key")
    func parseDraftSimple() {
        let result = ViewHelpers.parseHotkeyDraft("F5")
        #expect(result?.key == "f5")
        #expect(result?.requiredModifiers == nil)
    }

    @Test("parseHotkeyDraft: plus-separated combo")
    func parseDraftPlusCombo() {
        let result = ViewHelpers.parseHotkeyDraft("cmd+shift+space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == Set([.command, .shift]))
    }

    @Test("parseHotkeyDraft: space-separated combo")
    func parseDraftSpaceCombo() {
        let result = ViewHelpers.parseHotkeyDraft("cmd shift space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == Set([.command, .shift]))
    }

    @Test("parseHotkeyDraft: hyphen-separated combo")
    func parseDraftHyphenCombo() {
        let result = ViewHelpers.parseHotkeyDraft("ctrl-alt-delete")
        #expect(result?.key == "delete")
        #expect(result?.requiredModifiers == Set([.control, .option]))
    }

    @Test("parseHotkeyDraft: slash-separated combo")
    func parseDraftSlashCombo() {
        let result = ViewHelpers.parseHotkeyDraft("command/shift/space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == Set([.command, .shift]))
    }

    @Test("parseHotkeyDraft: compact symbol combo")
    func parseDraftCompactSymbol() {
        let result = ViewHelpers.parseHotkeyDraft("⌘⇧space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == Set([.command, .shift]))
    }

    @Test("parseHotkeyDraft: fn/globe flagged as non-configurable")
    func parseDraftFnGlobe() {
        let result = ViewHelpers.parseHotkeyDraft("fn+cmd+space")
        #expect(result?.key == "space")
        #expect(result?.containsNonConfigurableModifiers == true)
        #expect(result?.requiredModifiers == Set([.command]))
    }

    @Test("parseHotkeyDraft: ambiguous multi-key returns nil")
    func parseDraftAmbiguous() {
        let result = ViewHelpers.parseHotkeyDraft("cmd+a+b")
        #expect(result == nil)
    }

    @Test("parseHotkeyDraft: space-separated with multi-word key")
    func parseDraftMultiWordKey() {
        let result = ViewHelpers.parseHotkeyDraft("cmd page down")
        #expect(result?.key == "page down")
        #expect(result?.requiredModifiers == Set([.command]))
    }

    // MARK: - parseHotkeyTokens

    @Test("parseHotkeyTokens: empty returns nil")
    func parseTokensEmpty() {
        #expect(ViewHelpers.parseHotkeyTokens([]) == nil)
    }

    @Test("parseHotkeyTokens: modifiers only returns nil")
    func parseTokensModifiersOnly() {
        #expect(ViewHelpers.parseHotkeyTokens(["cmd", "shift"]) == nil)
    }

    @Test("parseHotkeyTokens: key only")
    func parseTokensKeyOnly() {
        let result = ViewHelpers.parseHotkeyTokens(["space"])
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == Set())
    }

    // MARK: - sanitizeKeyValue

    @Test("sanitizeKeyValue: empty becomes space")
    func sanitizeEmpty() {
        #expect(ViewHelpers.sanitizeKeyValue("") == "space")
    }

    @Test("sanitizeKeyValue: whitespace becomes space")
    func sanitizeWhitespace() {
        #expect(ViewHelpers.sanitizeKeyValue(" ") == "space")
    }

    @Test("sanitizeKeyValue: normalizes via canonicalKey")
    func sanitizeNormal() {
        #expect(ViewHelpers.sanitizeKeyValue("Enter") == "return")
        #expect(ViewHelpers.sanitizeKeyValue("ESC") == "escape")
    }

    // MARK: - looksLikeModifierComboInput

    @Test("looksLikeModifierComboInput: symbol modifiers detected")
    func looksLikeComboSymbols() {
        #expect(ViewHelpers.looksLikeModifierComboInput("⌘space") == true)
        #expect(ViewHelpers.looksLikeModifierComboInput("⇧f5") == true)
    }

    @Test("looksLikeModifierComboInput: text modifiers detected")
    func looksLikeComboText() {
        #expect(ViewHelpers.looksLikeModifierComboInput("cmd+space") == true)
        #expect(ViewHelpers.looksLikeModifierComboInput("shift space") == true)
    }

    @Test("looksLikeModifierComboInput: plain key not detected")
    func looksLikeComboPlain() {
        #expect(ViewHelpers.looksLikeModifierComboInput("space") == false)
        #expect(ViewHelpers.looksLikeModifierComboInput("f12") == false)
    }
}
