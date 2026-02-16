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

    // MARK: - insertActionDisabledReason

    @Test("insertActionDisabledReason: no text")
    func insertDisabledNoText() {
        #expect(ViewHelpers.insertActionDisabledReason(hasTranscriptionText: false, isRunningInsertionProbe: false, isRecording: false, pendingChunkCount: 0) == "No transcription to insert yet")
    }

    @Test("insertActionDisabledReason: probe running")
    func insertDisabledProbe() {
        #expect(ViewHelpers.insertActionDisabledReason(hasTranscriptionText: true, isRunningInsertionProbe: true, isRecording: false, pendingChunkCount: 0) == "Wait for the insertion probe to finish")
    }

    @Test("insertActionDisabledReason: recording")
    func insertDisabledRecording() {
        #expect(ViewHelpers.insertActionDisabledReason(hasTranscriptionText: true, isRunningInsertionProbe: false, isRecording: true, pendingChunkCount: 0) == "Stop recording and wait for pending chunks")
    }

    @Test("insertActionDisabledReason: pending chunks")
    func insertDisabledPending() {
        #expect(ViewHelpers.insertActionDisabledReason(hasTranscriptionText: true, isRunningInsertionProbe: false, isRecording: false, pendingChunkCount: 3) == "Stop recording and wait for pending chunks")
    }

    @Test("insertActionDisabledReason: ready")
    func insertReady() {
        #expect(ViewHelpers.insertActionDisabledReason(hasTranscriptionText: true, isRunningInsertionProbe: false, isRecording: false, pendingChunkCount: 0) == nil)
    }

    // MARK: - startStopButtonTitle

    @Test("startStopButtonTitle: recording")
    func startStopRecording() {
        #expect(ViewHelpers.startStopButtonTitle(isRecording: true, pendingChunkCount: 0, isStartAfterFinalizeQueued: false) == "Stop")
    }

    @Test("startStopButtonTitle: pending not queued")
    func startStopPending() {
        #expect(ViewHelpers.startStopButtonTitle(isRecording: false, pendingChunkCount: 3, isStartAfterFinalizeQueued: false) == "Queue start")
    }

    @Test("startStopButtonTitle: pending queued")
    func startStopQueued() {
        #expect(ViewHelpers.startStopButtonTitle(isRecording: false, pendingChunkCount: 3, isStartAfterFinalizeQueued: true) == "Cancel queued start")
    }

    @Test("startStopButtonTitle: idle")
    func startStopIdle() {
        #expect(ViewHelpers.startStopButtonTitle(isRecording: false, pendingChunkCount: 0, isStartAfterFinalizeQueued: false) == "Start")
    }

    // MARK: - startStopButtonHelpText

    @Test("startStopButtonHelpText: recording")
    func startStopHelpRecording() {
        #expect(ViewHelpers.startStopButtonHelpText(isRecording: true, pendingChunkCount: 0, isStartAfterFinalizeQueued: false, microphoneAuthorized: true) == "Stop recording")
    }

    @Test("startStopButtonHelpText: pending queued")
    func startStopHelpQueued() {
        #expect(ViewHelpers.startStopButtonHelpText(isRecording: false, pendingChunkCount: 2, isStartAfterFinalizeQueued: true, microphoneAuthorized: true) == "Cancel queued recording start while finalization finishes")
    }

    @Test("startStopButtonHelpText: pending not queued")
    func startStopHelpPending() {
        #expect(ViewHelpers.startStopButtonHelpText(isRecording: false, pendingChunkCount: 2, isStartAfterFinalizeQueued: false, microphoneAuthorized: true) == "Queue the next recording to start after finalization")
    }

    @Test("startStopButtonHelpText: no mic")
    func startStopHelpNoMic() {
        #expect(ViewHelpers.startStopButtonHelpText(isRecording: false, pendingChunkCount: 0, isStartAfterFinalizeQueued: false, microphoneAuthorized: false) == "Microphone permission is required before recording can start")
    }

    @Test("startStopButtonHelpText: ready")
    func startStopHelpReady() {
        #expect(ViewHelpers.startStopButtonHelpText(isRecording: false, pendingChunkCount: 0, isStartAfterFinalizeQueued: false, microphoneAuthorized: true) == "Start recording")
    }

    // MARK: - estimatedFinalizationSeconds

    @Test("estimatedFinalizationSeconds: no pending")
    func estFinNoPending() {
        #expect(ViewHelpers.estimatedFinalizationSeconds(pendingChunkCount: 0, averageChunkLatency: 1.0, lastChunkLatency: 1.0) == nil)
    }

    @Test("estimatedFinalizationSeconds: uses average latency")
    func estFinAvgLatency() {
        #expect(ViewHelpers.estimatedFinalizationSeconds(pendingChunkCount: 5, averageChunkLatency: 2.0, lastChunkLatency: 1.0) == 10.0)
    }

    @Test("estimatedFinalizationSeconds: falls back to last latency")
    func estFinLastLatency() {
        #expect(ViewHelpers.estimatedFinalizationSeconds(pendingChunkCount: 3, averageChunkLatency: 0, lastChunkLatency: 1.5) == 4.5)
    }

    @Test("estimatedFinalizationSeconds: no latency data")
    func estFinNoLatency() {
        #expect(ViewHelpers.estimatedFinalizationSeconds(pendingChunkCount: 3, averageChunkLatency: 0, lastChunkLatency: 0) == nil)
    }

    // MARK: - liveLoopLagNotice

    @Test("liveLoopLagNotice: no lag")
    func lagNoticeNone() {
        #expect(ViewHelpers.liveLoopLagNotice(pendingChunkCount: 1, estimatedFinalizationSeconds: 2.0) == nil)
    }

    @Test("liveLoopLagNotice: high estimated time")
    func lagNoticeHighEst() {
        let notice = ViewHelpers.liveLoopLagNotice(pendingChunkCount: 5, estimatedFinalizationSeconds: 10.0)
        #expect(notice?.contains("falling behind") == true)
        #expect(notice?.contains("10s") == true)
    }

    @Test("liveLoopLagNotice: many chunks no estimate")
    func lagNoticeManyChunks() {
        let notice = ViewHelpers.liveLoopLagNotice(pendingChunkCount: 5, estimatedFinalizationSeconds: nil)
        #expect(notice?.contains("5 chunks queued") == true)
    }

    @Test("liveLoopLagNotice: few chunks no estimate")
    func lagNoticeFewChunks() {
        #expect(ViewHelpers.liveLoopLagNotice(pendingChunkCount: 2, estimatedFinalizationSeconds: nil) == nil)
    }

    // MARK: - insertTargetAgeDescription

    @Test("insertTargetAgeDescription: nil capturedAt")
    func targetAgeNil() {
        #expect(ViewHelpers.insertTargetAgeDescription(capturedAt: nil, now: Date(), staleAfterSeconds: 90, isStale: false) == nil)
    }

    @Test("insertTargetAgeDescription: just now")
    func targetAgeJustNow() {
        let now = Date()
        let result = ViewHelpers.insertTargetAgeDescription(capturedAt: now, now: now, staleAfterSeconds: 90, isStale: false)
        #expect(result == "Target captured just now")
    }

    @Test("insertTargetAgeDescription: stale")
    func targetAgeStale() {
        let now = Date()
        let capturedAt = now.addingTimeInterval(-100)
        let result = ViewHelpers.insertTargetAgeDescription(capturedAt: capturedAt, now: now, staleAfterSeconds: 90, isStale: true)
        #expect(result?.contains("stale") == true)
        #expect(result?.contains("ago") == true)
    }

    @Test("insertTargetAgeDescription: near stale threshold")
    func targetAgeNearStale() {
        let now = Date()
        let capturedAt = now.addingTimeInterval(-85)
        let result = ViewHelpers.insertTargetAgeDescription(capturedAt: capturedAt, now: now, staleAfterSeconds: 90, isStale: false)
        #expect(result?.contains("stale in") == true)
    }

    @Test("insertTargetAgeDescription: fresh")
    func targetAgeFresh() {
        let now = Date()
        let capturedAt = now.addingTimeInterval(-10)
        let result = ViewHelpers.insertTargetAgeDescription(capturedAt: capturedAt, now: now, staleAfterSeconds: 90, isStale: false)
        #expect(result == "Target captured 10s ago")
    }

    // MARK: - lastSuccessfulInsertDescription

    @Test("lastSuccessfulInsertDescription: nil")
    func lastInsertNil() {
        #expect(ViewHelpers.lastSuccessfulInsertDescription(insertedAt: nil, now: Date()) == nil)
    }

    @Test("lastSuccessfulInsertDescription: just now")
    func lastInsertJustNow() {
        let now = Date()
        #expect(ViewHelpers.lastSuccessfulInsertDescription(insertedAt: now, now: now) == "Last insert succeeded just now")
    }

    @Test("lastSuccessfulInsertDescription: ago")
    func lastInsertAgo() {
        let now = Date()
        let result = ViewHelpers.lastSuccessfulInsertDescription(insertedAt: now.addingTimeInterval(-30), now: now)
        #expect(result == "Last insert succeeded 30s ago")
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

    // MARK: - menuBarIconName

    @Test("menuBarIconName: insertion flash")
    func iconNameFlash() {
        #expect(ViewHelpers.menuBarIconName(isRecording: false, pendingChunkCount: 0, hasTranscriptionText: false, isShowingInsertionFlash: true) == "checkmark.circle.fill")
    }

    @Test("menuBarIconName: recording")
    func iconNameRecording() {
        #expect(ViewHelpers.menuBarIconName(isRecording: true, pendingChunkCount: 0, hasTranscriptionText: false, isShowingInsertionFlash: false) == "waveform.circle.fill")
    }

    @Test("menuBarIconName: pending chunks")
    func iconNamePending() {
        #expect(ViewHelpers.menuBarIconName(isRecording: false, pendingChunkCount: 3, hasTranscriptionText: false, isShowingInsertionFlash: false) == "ellipsis.circle")
    }

    @Test("menuBarIconName: has transcription")
    func iconNameTranscription() {
        #expect(ViewHelpers.menuBarIconName(isRecording: false, pendingChunkCount: 0, hasTranscriptionText: true, isShowingInsertionFlash: false) == "doc.text")
    }

    @Test("menuBarIconName: idle")
    func iconNameIdle() {
        #expect(ViewHelpers.menuBarIconName(isRecording: false, pendingChunkCount: 0, hasTranscriptionText: false, isShowingInsertionFlash: false) == "mic")
    }

    @Test("menuBarIconName: flash takes priority over recording")
    func iconNameFlashPriority() {
        #expect(ViewHelpers.menuBarIconName(isRecording: true, pendingChunkCount: 5, hasTranscriptionText: true, isShowingInsertionFlash: true) == "checkmark.circle.fill")
    }

    // MARK: - menuBarDurationLabel

    @Test("menuBarDurationLabel: insertion flash")
    func durationLabelFlash() {
        #expect(ViewHelpers.menuBarDurationLabel(isRecording: false, pendingChunkCount: 0, recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: false, averageChunkLatency: 0, lastChunkLatency: 0, transcriptionWordCount: 0, isShowingInsertionFlash: true) == "Inserted")
    }

    @Test("menuBarDurationLabel: recording with elapsed time")
    func durationLabelRecording() {
        #expect(ViewHelpers.menuBarDurationLabel(isRecording: true, pendingChunkCount: 0, recordingElapsedSeconds: 125, isStartAfterFinalizeQueued: false, averageChunkLatency: 0, lastChunkLatency: 0, transcriptionWordCount: 0, isShowingInsertionFlash: false) == "2:05")
    }

    @Test("menuBarDurationLabel: recording zero seconds")
    func durationLabelRecordingZero() {
        #expect(ViewHelpers.menuBarDurationLabel(isRecording: true, pendingChunkCount: 0, recordingElapsedSeconds: 0, isStartAfterFinalizeQueued: false, averageChunkLatency: 0, lastChunkLatency: 0, transcriptionWordCount: 0, isShowingInsertionFlash: false) == "0:00")
    }

    @Test("menuBarDurationLabel: pending with average latency")
    func durationLabelPendingAvgLatency() {
        let result = ViewHelpers.menuBarDurationLabel(isRecording: false, pendingChunkCount: 5, recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: false, averageChunkLatency: 2.0, lastChunkLatency: 1.0, transcriptionWordCount: 0, isShowingInsertionFlash: false)
        #expect(result == "5⏳10s")
    }

    @Test("menuBarDurationLabel: pending with last latency fallback")
    func durationLabelPendingLastLatency() {
        let result = ViewHelpers.menuBarDurationLabel(isRecording: false, pendingChunkCount: 3, recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: false, averageChunkLatency: 0, lastChunkLatency: 1.5, transcriptionWordCount: 0, isShowingInsertionFlash: false)
        #expect(result == "3⏳5s")
    }

    @Test("menuBarDurationLabel: pending no latency")
    func durationLabelPendingNoLatency() {
        #expect(ViewHelpers.menuBarDurationLabel(isRecording: false, pendingChunkCount: 2, recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: false, averageChunkLatency: 0, lastChunkLatency: 0, transcriptionWordCount: 0, isShowingInsertionFlash: false) == "2 left")
    }

    @Test("menuBarDurationLabel: pending with queued start suffix")
    func durationLabelPendingQueued() {
        #expect(ViewHelpers.menuBarDurationLabel(isRecording: false, pendingChunkCount: 2, recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: true, averageChunkLatency: 0, lastChunkLatency: 0, transcriptionWordCount: 0, isShowingInsertionFlash: false) == "2 left→●")
    }

    @Test("menuBarDurationLabel: word count when idle with text")
    func durationLabelWordCount() {
        #expect(ViewHelpers.menuBarDurationLabel(isRecording: false, pendingChunkCount: 0, recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: false, averageChunkLatency: 0, lastChunkLatency: 0, transcriptionWordCount: 5, isShowingInsertionFlash: false) == "5w")
    }

    @Test("menuBarDurationLabel: nil when idle no text")
    func durationLabelNil() {
        #expect(ViewHelpers.menuBarDurationLabel(isRecording: false, pendingChunkCount: 0, recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: false, averageChunkLatency: 0, lastChunkLatency: 0, transcriptionWordCount: 0, isShowingInsertionFlash: false) == nil)
    }

    // MARK: - isInsertionFlashVisible

    @Test("isInsertionFlashVisible: nil insertedAt")
    func flashVisibleNil() {
        #expect(ViewHelpers.isInsertionFlashVisible(insertedAt: nil, now: Date()) == false)
    }

    @Test("isInsertionFlashVisible: within duration")
    func flashVisibleWithin() {
        let now = Date()
        #expect(ViewHelpers.isInsertionFlashVisible(insertedAt: now.addingTimeInterval(-1), now: now) == true)
    }

    @Test("isInsertionFlashVisible: expired")
    func flashVisibleExpired() {
        let now = Date()
        #expect(ViewHelpers.isInsertionFlashVisible(insertedAt: now.addingTimeInterval(-5), now: now) == false)
    }

    @Test("isInsertionFlashVisible: custom duration")
    func flashVisibleCustom() {
        let now = Date()
        #expect(ViewHelpers.isInsertionFlashVisible(insertedAt: now.addingTimeInterval(-4), now: now, flashDuration: 5) == true)
        #expect(ViewHelpers.isInsertionFlashVisible(insertedAt: now.addingTimeInterval(-6), now: now, flashDuration: 5) == false)
    }

    // MARK: - transcriptionWordCount

    @Test("transcriptionWordCount: empty")
    func wordCountEmpty() {
        #expect(ViewHelpers.transcriptionWordCount("") == 0)
        #expect(ViewHelpers.transcriptionWordCount("   ") == 0)
    }

    @Test("transcriptionWordCount: basic")
    func wordCountBasic() {
        #expect(ViewHelpers.transcriptionWordCount("hello world") == 2)
        #expect(ViewHelpers.transcriptionWordCount("one two three four") == 4)
    }

    @Test("transcriptionWordCount: with punctuation")
    func wordCountPunctuation() {
        #expect(ViewHelpers.transcriptionWordCount("hello, world!") == 2)
    }

    // MARK: - transcriptionStats

    @Test("transcriptionStats: basic")
    func statsBasic() {
        #expect(ViewHelpers.transcriptionStats("hello world") == "2w · 11c")
    }

    @Test("transcriptionStats: empty")
    func statsEmpty() {
        #expect(ViewHelpers.transcriptionStats("") == "0w · 0c")
    }

    @Test("transcriptionStats: with whitespace padding")
    func statsWhitespace() {
        #expect(ViewHelpers.transcriptionStats("  hi  ") == "1w · 2c")
    }

    // MARK: - shouldAutoApplySafeCaptureModifiers

    @Test("shouldAutoApplySafeCaptureModifiers: single character keys need modifiers")
    func safeModifiersSingleChar() {
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "a") == true)
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "z") == true)
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "1") == true)
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "/") == true)
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: ".") == true)
    }

    @Test("shouldAutoApplySafeCaptureModifiers: function keys do not need modifiers")
    func safeModifiersFunctionKeys() {
        for i in 1...24 {
            #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "f\(i)") == false)
        }
    }

    @Test("shouldAutoApplySafeCaptureModifiers: navigation keys do not need modifiers")
    func safeModifiersNavKeys() {
        let navKeys = ["escape", "tab", "return", "enter", "space", "delete", "forwarddelete",
                       "left", "right", "up", "down", "home", "end", "pageup", "pagedown"]
        for key in navKeys {
            #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: key) == false)
        }
    }

    @Test("shouldAutoApplySafeCaptureModifiers: special keys do not need modifiers")
    func safeModifiersSpecialKeys() {
        let specialKeys = ["keypadenter", "numpadenter", "insert", "ins", "help",
                           "del", "backspace", "bksp", "fwddelete", "fwddel",
                           "fn", "function", "globe", "globekey", "caps", "capslock"]
        for key in specialKeys {
            #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: key) == false)
        }
    }

    @Test("shouldAutoApplySafeCaptureModifiers: multi-char unknown keys need modifiers")
    func safeModifiersUnknownMultiChar() {
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "plus") == true)
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "minus") == true)
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "comma") == true)
    }

    // MARK: - isHighRiskHotkey

    @Test("isHighRiskHotkey: with modifiers is never high risk")
    func highRiskWithModifiers() {
        #expect(!ViewHelpers.isHighRiskHotkey(requiredModifiers: [.command], key: "a"))
        #expect(!ViewHelpers.isHighRiskHotkey(requiredModifiers: [.shift], key: "space"))
    }

    @Test("isHighRiskHotkey: single char without modifiers is high risk")
    func highRiskSingleChar() {
        #expect(ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "a"))
        #expect(ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "z"))
        #expect(ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "5"))
    }

    @Test("isHighRiskHotkey: named dangerous keys without modifiers")
    func highRiskNamedKeys() {
        for key in ["space", "tab", "return", "delete", "forwarddelete", "escape",
                     "fn", "left", "right", "up", "down", "home", "end", "pageup", "pagedown"] {
            #expect(ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: key), "Expected \(key) to be high risk")
        }
    }

    @Test("isHighRiskHotkey: function keys without modifiers are not high risk")
    func highRiskFunctionKeys() {
        #expect(!ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "f1"))
        #expect(!ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "f12"))
    }

    // MARK: - showsHoldModeAccidentalTriggerWarning

    @Test("holdModeWarning: shows for hold mode with high risk key")
    func holdModeWarningShown() {
        #expect(ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: HotkeyMode.hold.rawValue, requiredModifiers: [], key: "space"))
    }

    @Test("holdModeWarning: hidden for toggle mode")
    func holdModeWarningToggle() {
        #expect(!ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: HotkeyMode.toggle.rawValue, requiredModifiers: [], key: "space"))
    }

    @Test("holdModeWarning: hidden when not high risk")
    func holdModeWarningNotHighRisk() {
        #expect(!ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: HotkeyMode.hold.rawValue, requiredModifiers: [.command], key: "space"))
    }

    // MARK: - hotkeyEscapeCancelConflictWarning

    @Test("escapeConflict: returns warning for escape key")
    func escapeConflictWarning() {
        let result = ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "escape")
        #expect(result != nil)
        #expect(result!.contains("discard"))
    }

    @Test("escapeConflict: nil for other keys")
    func escapeConflictNil() {
        #expect(ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "space") == nil)
        #expect(ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "f1") == nil)
    }

    // MARK: - hotkeySystemConflictWarning

    @Test("systemConflict: cmd+space warns about Spotlight")
    func systemConflictCmdSpace() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "space")
        #expect(result != nil)
        #expect(result!.contains("Spotlight"))
    }

    @Test("systemConflict: ctrl+space warns about input source")
    func systemConflictCtrlSpace() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.control], key: "space")
        #expect(result != nil)
        #expect(result!.contains("input source"))
    }

    @Test("systemConflict: cmd+q warns about quitting")
    func systemConflictCmdQ() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "q")
        #expect(result != nil)
        #expect(result!.contains("quits"))
    }

    @Test("systemConflict: cmd+tab warns about app switching")
    func systemConflictCmdTab() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "tab")
        #expect(result != nil)
        #expect(result!.contains("app switching"))
    }

    @Test("systemConflict: cmd+shift+3 warns about screenshot")
    func systemConflictCmdShift3() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "3")
        #expect(result != nil)
        #expect(result!.contains("screenshot"))
    }

    @Test("systemConflict: safe combo returns nil")
    func systemConflictSafe() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "space") == nil)
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "d") == nil)
    }

    @Test("systemConflict: cmd+c warns about copy")
    func systemConflictCmdC() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "c")
        #expect(result != nil)
        #expect(result!.contains("copies"))
    }

    @Test("systemConflict: fn alone warns")
    func systemConflictFnAlone() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [], key: "fn")
        #expect(result != nil)
        #expect(result!.contains("Fn/Globe"))
    }

    @Test("systemConflict: cmd+option+esc warns about force quit")
    func systemConflictForceQuit() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .option], key: "escape")
        #expect(result != nil)
        #expect(result!.contains("Force Quit"))
    }

    // MARK: - insertionTestDisabledReason

    @Test("insertionTestDisabled: recording")
    func insertionTestRecording() {
        let r = ViewHelpers.insertionTestDisabledReason(
            isRecording: true, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true, hasInsertionTarget: true)
        #expect(r.contains("Stop recording"))
    }

    @Test("insertionTestDisabled: finalizing")
    func insertionTestFinalizing() {
        let r = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: true,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true, hasInsertionTarget: true)
        #expect(r.contains("finalizing"))
    }

    @Test("insertionTestDisabled: already running")
    func insertionTestAlreadyRunning() {
        let r = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: true, hasInsertionProbeSampleText: true, hasInsertionTarget: true)
        #expect(r.contains("already running"))
    }

    @Test("insertionTestDisabled: empty sample text")
    func insertionTestEmptyText() {
        let r = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: false, hasInsertionTarget: true)
        #expect(r.contains("empty"))
    }

    @Test("insertionTestDisabled: no target")
    func insertionTestNoTarget() {
        let r = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true, hasInsertionTarget: false)
        #expect(r.contains("No destination"))
    }

    // MARK: - hotkeyModeTipText

    @Test("modeTip: toggle without escape")
    func modeTipToggle() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: false)
        #expect(tip.contains("toggle"))
        #expect(tip.contains("Esc"))
    }

    @Test("modeTip: toggle with escape trigger")
    func modeTipToggleEscape() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: true)
        #expect(tip.contains("unavailable"))
    }

    @Test("modeTip: hold without escape")
    func modeTipHold() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: false)
        #expect(tip.contains("hold"))
        #expect(tip.contains("release"))
    }

    @Test("modeTip: hold with escape trigger")
    func modeTipHoldEscape() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: true)
        #expect(tip.contains("unavailable"))
    }

    // MARK: - hotkeyCaptureButtonTitle

    @Test("captureButtonTitle: not capturing")
    func captureButtonNotCapturing() {
        #expect(ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: false, secondsRemaining: 5) == "Record shortcut")
    }

    @Test("captureButtonTitle: capturing")
    func captureButtonCapturing() {
        let title = ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: true, secondsRemaining: 3)
        #expect(title == "Listening… 3s")
    }

    // MARK: - hotkeyCaptureInstruction

    @Test("captureInstruction: with input monitoring")
    func captureInstructionWithMonitoring() {
        let text = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: true, secondsRemaining: 5)
        #expect(text.contains("even if another app"))
        #expect(text.contains("5s left"))
    }

    @Test("captureInstruction: without input monitoring")
    func captureInstructionNoMonitoring() {
        let text = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: false, secondsRemaining: 8)
        #expect(text.contains("Input Monitoring is missing"))
        #expect(text.contains("8s left"))
    }

    // MARK: - hotkeyCaptureProgress

    @Test("captureProgress: normal")
    func captureProgressNormal() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 10) == 0.5)
    }

    @Test("captureProgress: zero total")
    func captureProgressZeroTotal() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 0) == 0)
    }

    @Test("captureProgress: clamps to 0-1")
    func captureProgressClamps() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 15, totalSeconds: 10) == 1)
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: -1, totalSeconds: 10) == 0)
    }

    // MARK: - hotkeyDraftValidationMessage

    @Test("draftValidation: empty draft")
    func draftValidationEmpty() {
        let msg = ViewHelpers.hotkeyDraftValidationMessage(draft: "", isSupportedKey: false)
        #expect(msg != nil)
        #expect(msg!.contains("Enter one trigger key"))
    }

    @Test("draftValidation: supported key returns nil")
    func draftValidationSupported() {
        #expect(ViewHelpers.hotkeyDraftValidationMessage(draft: "space", isSupportedKey: true) == nil)
    }

    @Test("draftValidation: unsupported key")
    func draftValidationUnsupported() {
        let msg = ViewHelpers.hotkeyDraftValidationMessage(draft: "xyz", isSupportedKey: false)
        #expect(msg != nil)
        #expect(msg!.contains("Unsupported key"))
    }

    // MARK: - hasHotkeyDraftChangesToApply

    @Test("draftChanges: same key no changes")
    func draftChangesNoChange() {
        #expect(!ViewHelpers.hasHotkeyDraftChangesToApply(draft: "space", currentKey: "space", currentModifiers: [.command]))
    }

    @Test("draftChanges: different key has changes")
    func draftChangesDifferentKey() {
        #expect(ViewHelpers.hasHotkeyDraftChangesToApply(draft: "f6", currentKey: "space", currentModifiers: [.command]))
    }

    @Test("draftChanges: unparseable draft returns false")
    func draftChangesUnparseable() {
        #expect(!ViewHelpers.hasHotkeyDraftChangesToApply(draft: "", currentKey: "space", currentModifiers: []))
    }

    @Test("draftChanges: different modifiers detected")
    func draftChangesDifferentModifiers() {
        #expect(ViewHelpers.hasHotkeyDraftChangesToApply(draft: "cmd+shift+space", currentKey: "space", currentModifiers: [.command]))
    }

    // MARK: - canonicalHotkeyDraftPreview

    @Test("draftPreview: valid draft shows preview")
    func draftPreviewValid() {
        let preview = ViewHelpers.canonicalHotkeyDraftPreview(draft: "space", currentModifiers: [.command, .shift])
        #expect(preview != nil)
        #expect(preview!.contains("⌘"))
        #expect(preview!.contains("⇧"))
    }

    @Test("draftPreview: unparseable draft returns nil")
    func draftPreviewNil() {
        #expect(ViewHelpers.canonicalHotkeyDraftPreview(draft: "", currentModifiers: []) == nil)
    }

    // MARK: - hotkeyDraftModifierOverrideSummary

    @Test("modifierOverride: no override returns nil")
    func modifierOverrideNone() {
        #expect(ViewHelpers.hotkeyDraftModifierOverrideSummary(draft: "space", currentModifiers: [.command]) == nil)
    }

    @Test("modifierOverride: with override shows new modifiers")
    func modifierOverridePresent() {
        let summary = ViewHelpers.hotkeyDraftModifierOverrideSummary(draft: "cmd+shift+space", currentModifiers: [.command])
        #expect(summary != nil)
        #expect(summary!.contains("⇧ Shift"))
    }

    // MARK: - hotkeyDraftNonConfigurableModifierNotice

    @Test("nonConfigurableNotice: nil for normal draft")
    func nonConfigurableNil() {
        #expect(ViewHelpers.hotkeyDraftNonConfigurableModifierNotice(draft: "space") == nil)
    }

    @Test("nonConfigurableNotice: shows for fn/globe with modifier")
    func nonConfigurableShown() {
        let notice = ViewHelpers.hotkeyDraftNonConfigurableModifierNotice(draft: "fn+cmd+space")
        #expect(notice != nil)
        #expect(notice!.contains("Fn/Globe"))
    }

    @Test("nonConfigurableNotice: fn alone without configurable modifier returns nil")
    func nonConfigurableFnAlone() {
        // fn+space doesn't look like a modifier combo (fn isn't a configurable modifier),
        // so parseHotkeyDraft takes the whole-key path and doesn't set the flag
        #expect(ViewHelpers.hotkeyDraftNonConfigurableModifierNotice(draft: "fn+space") == nil)
    }

    // MARK: - hotkeyMissingPermissionSummary

    @Test("missingPermissions: none missing returns nil")
    func missingPermissionsNone() {
        #expect(ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: true, inputMonitoringAuthorized: true) == nil)
    }

    @Test("missingPermissions: accessibility missing")
    func missingPermissionsAccessibility() {
        let result = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: false, inputMonitoringAuthorized: true)
        #expect(result == "Accessibility")
    }

    @Test("missingPermissions: input monitoring missing")
    func missingPermissionsInput() {
        let result = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: true, inputMonitoringAuthorized: false)
        #expect(result == "Input Monitoring")
    }

    @Test("missingPermissions: both missing")
    func missingPermissionsBoth() {
        let result = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: false, inputMonitoringAuthorized: false)
        #expect(result == "Accessibility + Input Monitoring")
    }

    // MARK: - liveWordsPerMinute

    @Test("liveWPM: returns nil when duration < 5s")
    func liveWPMShortDuration() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello world", durationSeconds: 4.9) == nil)
    }

    @Test("liveWPM: returns nil for empty transcription")
    func liveWPMEmpty() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "", durationSeconds: 60) == nil)
    }

    @Test("liveWPM: returns nil for whitespace-only transcription")
    func liveWPMWhitespace() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "   ", durationSeconds: 60) == nil)
    }

    @Test("liveWPM: calculates correctly for 60 words in 60 seconds")
    func liveWPM60Words() {
        let words = (1...60).map { "word\($0)" }.joined(separator: " ")
        let result = ViewHelpers.liveWordsPerMinute(transcription: words, durationSeconds: 60)
        #expect(result == 60)
    }

    @Test("liveWPM: minimum is 1")
    func liveWPMMinimum() {
        let result = ViewHelpers.liveWordsPerMinute(transcription: "hello", durationSeconds: 3600)
        #expect(result == 1)
    }

    @Test("liveWPM: works at exactly 5 seconds")
    func liveWPMAtBoundary() {
        let result = ViewHelpers.liveWordsPerMinute(transcription: "one two three", durationSeconds: 5)
        #expect(result != nil)
        #expect(result! > 0)
    }

    // MARK: - recordingDuration

    @Test("recordingDuration: nil startedAt returns 0")
    func recordingDurationNil() {
        #expect(ViewHelpers.recordingDuration(startedAt: nil, now: Date()) == 0)
    }

    @Test("recordingDuration: positive interval")
    func recordingDurationPositive() {
        let start = Date(timeIntervalSinceReferenceDate: 100)
        let now = Date(timeIntervalSinceReferenceDate: 110)
        #expect(ViewHelpers.recordingDuration(startedAt: start, now: now) == 10)
    }

    @Test("recordingDuration: future startedAt clamps to 0")
    func recordingDurationFutureStart() {
        let start = Date(timeIntervalSinceReferenceDate: 200)
        let now = Date(timeIntervalSinceReferenceDate: 100)
        #expect(ViewHelpers.recordingDuration(startedAt: start, now: now) == 0)
    }

    // MARK: - shouldCopyBecauseTargetUnknown

    @Test("shouldCopy: false when cannot insert directly")
    func shouldCopyNoInsert() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(canInsertDirectly: false, hasResolvableInsertTarget: false, hasExternalFrontApp: false) == false)
    }

    @Test("shouldCopy: false when has resolvable target")
    func shouldCopyHasTarget() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(canInsertDirectly: true, hasResolvableInsertTarget: true, hasExternalFrontApp: false) == false)
    }

    @Test("shouldCopy: false when has external front app")
    func shouldCopyHasFrontApp() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(canInsertDirectly: true, hasResolvableInsertTarget: false, hasExternalFrontApp: true) == false)
    }

    @Test("shouldCopy: true when can insert, no target, no front app")
    func shouldCopyTrue() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(canInsertDirectly: true, hasResolvableInsertTarget: false, hasExternalFrontApp: false) == true)
    }

    // MARK: - shouldSuggestRetarget

    @Test("shouldSuggestRetarget: false when not locked")
    func suggestRetargetNotLocked() {
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: false, insertTargetAppName: "Safari", insertTargetBundleIdentifier: "com.apple.Safari", currentFrontBundleIdentifier: "com.apple.Notes", currentFrontAppName: "Notes", isInsertTargetStale: false) == false)
    }

    @Test("shouldSuggestRetarget: false when target name empty")
    func suggestRetargetEmptyName() {
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: true, insertTargetAppName: "", insertTargetBundleIdentifier: nil, currentFrontBundleIdentifier: nil, currentFrontAppName: nil, isInsertTargetStale: false) == false)
    }

    @Test("shouldSuggestRetarget: false when target name nil")
    func suggestRetargetNilName() {
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: true, insertTargetAppName: nil, insertTargetBundleIdentifier: nil, currentFrontBundleIdentifier: nil, currentFrontAppName: nil, isInsertTargetStale: false) == false)
    }

    @Test("shouldSuggestRetarget: true when bundles differ")
    func suggestRetargetDifferentBundles() {
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: true, insertTargetAppName: "Safari", insertTargetBundleIdentifier: "com.apple.Safari", currentFrontBundleIdentifier: "com.apple.Notes", currentFrontAppName: "Notes", isInsertTargetStale: false) == true)
    }

    @Test("shouldSuggestRetarget: false when same bundle")
    func suggestRetargetSameBundle() {
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: true, insertTargetAppName: "Safari", insertTargetBundleIdentifier: "com.apple.Safari", currentFrontBundleIdentifier: "com.apple.Safari", currentFrontAppName: "Safari", isInsertTargetStale: false) == false)
    }

    @Test("shouldSuggestRetarget: falls back to app name comparison")
    func suggestRetargetNameFallback() {
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: true, insertTargetAppName: "Safari", insertTargetBundleIdentifier: nil, currentFrontBundleIdentifier: nil, currentFrontAppName: "Notes", isInsertTargetStale: false) == true)
    }

    @Test("shouldSuggestRetarget: same name case-insensitive")
    func suggestRetargetSameNameCaseInsensitive() {
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: true, insertTargetAppName: "safari", insertTargetBundleIdentifier: nil, currentFrontBundleIdentifier: nil, currentFrontAppName: "Safari", isInsertTargetStale: false) == false)
    }

    @Test("shouldSuggestRetarget: falls back to stale when no front app")
    func suggestRetargetStaleFallback() {
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: true, insertTargetAppName: "Safari", insertTargetBundleIdentifier: nil, currentFrontBundleIdentifier: nil, currentFrontAppName: nil, isInsertTargetStale: true) == true)
    }

    @Test("shouldSuggestRetarget: not stale, no front app → false")
    func suggestRetargetNotStaleNoFront() {
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: true, insertTargetAppName: "Safari", insertTargetBundleIdentifier: nil, currentFrontBundleIdentifier: nil, currentFrontAppName: nil, isInsertTargetStale: false) == false)
    }

    // MARK: - shouldAutoRefreshInsertTargetBeforePrimaryInsert

    @Test("autoRefresh: false when cannot insert directly")
    func autoRefreshNoInsert() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(canInsertDirectly: false, canRetargetInsertTarget: true, shouldSuggestRetarget: false, isInsertTargetStale: true) == false)
    }

    @Test("autoRefresh: false when cannot retarget")
    func autoRefreshNoRetarget() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(canInsertDirectly: true, canRetargetInsertTarget: false, shouldSuggestRetarget: false, isInsertTargetStale: true) == false)
    }

    @Test("autoRefresh: false when suggest retarget is true")
    func autoRefreshSuggestRetarget() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(canInsertDirectly: true, canRetargetInsertTarget: true, shouldSuggestRetarget: true, isInsertTargetStale: true) == false)
    }

    @Test("autoRefresh: true when stale and all conditions met")
    func autoRefreshStale() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(canInsertDirectly: true, canRetargetInsertTarget: true, shouldSuggestRetarget: false, isInsertTargetStale: true) == true)
    }

    @Test("autoRefresh: false when not stale")
    func autoRefreshNotStale() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(canInsertDirectly: true, canRetargetInsertTarget: true, shouldSuggestRetarget: false, isInsertTargetStale: false) == false)
    }

    // MARK: - insertButtonTitle

    @Test("insertButtonTitle: copy when cannot insert directly")
    func insertTitleCopy() {
        #expect(ViewHelpers.insertButtonTitle(canInsertDirectly: false, insertTargetAppName: "Safari", insertTargetUsesFallback: false, shouldSuggestRetarget: false, isInsertTargetStale: false, liveFrontAppName: nil) == "Copy → Clipboard")
    }

    @Test("insertButtonTitle: insert with target name")
    func insertTitleWithTarget() {
        let result = ViewHelpers.insertButtonTitle(canInsertDirectly: true, insertTargetAppName: "Safari", insertTargetUsesFallback: false, shouldSuggestRetarget: false, isInsertTargetStale: false, liveFrontAppName: nil)
        #expect(result == "Insert → Safari")
    }

    @Test("insertButtonTitle: fallback target shows (recent)")
    func insertTitleFallback() {
        let result = ViewHelpers.insertButtonTitle(canInsertDirectly: true, insertTargetAppName: "Safari", insertTargetUsesFallback: true, shouldSuggestRetarget: false, isInsertTargetStale: false, liveFrontAppName: nil)
        #expect(result == "Insert → Safari (recent)")
    }

    @Test("insertButtonTitle: suggest retarget shows warning")
    func insertTitleRetargetWarning() {
        let result = ViewHelpers.insertButtonTitle(canInsertDirectly: true, insertTargetAppName: "Safari", insertTargetUsesFallback: false, shouldSuggestRetarget: true, isInsertTargetStale: false, liveFrontAppName: nil)
        #expect(result.contains("⚠︎"))
    }

    @Test("insertButtonTitle: stale shows warning")
    func insertTitleStaleWarning() {
        let result = ViewHelpers.insertButtonTitle(canInsertDirectly: true, insertTargetAppName: "Safari", insertTargetUsesFallback: false, shouldSuggestRetarget: false, isInsertTargetStale: true, liveFrontAppName: nil)
        #expect(result.contains("⚠︎"))
    }

    @Test("insertButtonTitle: no target uses live front app")
    func insertTitleLiveFront() {
        let result = ViewHelpers.insertButtonTitle(canInsertDirectly: true, insertTargetAppName: nil, insertTargetUsesFallback: false, shouldSuggestRetarget: false, isInsertTargetStale: false, liveFrontAppName: "Notes")
        #expect(result == "Insert → Notes")
    }

    @Test("insertButtonTitle: no target no live front copies")
    func insertTitleNoTargetNoFront() {
        let result = ViewHelpers.insertButtonTitle(canInsertDirectly: true, insertTargetAppName: nil, insertTargetUsesFallback: false, shouldSuggestRetarget: false, isInsertTargetStale: false, liveFrontAppName: nil)
        #expect(result == "Copy → Clipboard")
    }

    @Test("insertButtonTitle: empty target name uses live front")
    func insertTitleEmptyTarget() {
        let result = ViewHelpers.insertButtonTitle(canInsertDirectly: true, insertTargetAppName: "", insertTargetUsesFallback: false, shouldSuggestRetarget: false, isInsertTargetStale: false, liveFrontAppName: "Notes")
        #expect(result == "Insert → Notes")
    }

    // MARK: - insertButtonHelpText

    @Test("insertHelpText: shows disabled reason")
    func insertHelpDisabledReason() {
        let result = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: "Record something", canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false, isInsertTargetStale: false, insertTargetAppName: nil, insertTargetUsesFallback: false, currentFrontAppName: nil)
        #expect(result == "Record something before inserting")
    }

    @Test("insertHelpText: no accessibility with target")
    func insertHelpNoAccessibilityWithTarget() {
        let result = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: false, shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false, isInsertTargetStale: false, insertTargetAppName: "Safari", insertTargetUsesFallback: false, currentFrontAppName: nil)
        #expect(result.contains("Accessibility permission is missing"))
        #expect(result.contains("Safari"))
    }

    @Test("insertHelpText: no accessibility no target")
    func insertHelpNoAccessibilityNoTarget() {
        let result = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: false, shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false, isInsertTargetStale: false, insertTargetAppName: nil, insertTargetUsesFallback: false, currentFrontAppName: nil)
        #expect(result.contains("clipboard"))
    }

    @Test("insertHelpText: copy because target unknown")
    func insertHelpCopyUnknown() {
        let result = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true, shouldCopyBecauseTargetUnknown: true, shouldSuggestRetarget: false, isInsertTargetStale: false, insertTargetAppName: nil, insertTargetUsesFallback: false, currentFrontAppName: nil)
        #expect(result.contains("No destination app"))
    }

    @Test("insertHelpText: suggest retarget with both app names")
    func insertHelpSuggestRetarget() {
        let result = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: true, isInsertTargetStale: false, insertTargetAppName: "Safari", insertTargetUsesFallback: false, currentFrontAppName: "Notes")
        #expect(result.contains("Notes"))
        #expect(result.contains("Safari"))
    }

    @Test("insertHelpText: stale target")
    func insertHelpStale() {
        let result = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false, isInsertTargetStale: true, insertTargetAppName: "Safari", insertTargetUsesFallback: false, currentFrontAppName: nil)
        #expect(result.contains("captured a while ago"))
    }

    @Test("insertHelpText: fallback target")
    func insertHelpFallback() {
        let result = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false, isInsertTargetStale: false, insertTargetAppName: "Safari", insertTargetUsesFallback: true, currentFrontAppName: nil)
        #expect(result.contains("recent app context"))
    }

    @Test("insertHelpText: normal insert with target")
    func insertHelpNormal() {
        let result = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false, isInsertTargetStale: false, insertTargetAppName: "Safari", insertTargetUsesFallback: false, currentFrontAppName: nil)
        #expect(result == "Insert into Safari")
    }

    @Test("insertHelpText: no target uses live front")
    func insertHelpLiveFront() {
        let result = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false, isInsertTargetStale: false, insertTargetAppName: nil, insertTargetUsesFallback: false, currentFrontAppName: "Notes")
        #expect(result == "Insert into Notes")
    }

    @Test("insertHelpText: no target no front app")
    func insertHelpNoFront() {
        let result = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false, isInsertTargetStale: false, insertTargetAppName: nil, insertTargetUsesFallback: false, currentFrontAppName: nil)
        #expect(result == "Insert into the last active app")
    }

    // MARK: - canRetargetInsertTarget

    @Test("canRetarget: true when idle")
    func canRetargetIdle() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: false, pendingChunkCount: 0))
    }

    @Test("canRetarget: false when recording")
    func canRetargetRecording() {
        #expect(!ViewHelpers.canRetargetInsertTarget(isRecording: true, pendingChunkCount: 0))
    }

    @Test("canRetarget: false when pending chunks")
    func canRetargetPending() {
        #expect(!ViewHelpers.canRetargetInsertTarget(isRecording: false, pendingChunkCount: 2))
    }

    @Test("canRetarget: false when both recording and pending")
    func canRetargetBoth() {
        #expect(!ViewHelpers.canRetargetInsertTarget(isRecording: true, pendingChunkCount: 1))
    }

    // MARK: - hasResolvableInsertTarget

    @Test("hasResolvable: true for non-empty name")
    func hasResolvableTrue() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "Safari"))
    }

    @Test("hasResolvable: false for nil")
    func hasResolvableNil() {
        #expect(!ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: nil))
    }

    @Test("hasResolvable: false for empty string")
    func hasResolvableEmpty() {
        #expect(!ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: ""))
    }

    @Test("hasResolvable: false for whitespace-only")
    func hasResolvableWhitespace() {
        #expect(!ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "   "))
    }

    // MARK: - retargetButtonTitle

    @Test("retargetTitle: nil target")
    func retargetTitleNil() {
        #expect(ViewHelpers.retargetButtonTitle(insertTargetAppName: nil, insertTargetUsesFallback: false) == "Retarget")
    }

    @Test("retargetTitle: empty target")
    func retargetTitleEmpty() {
        #expect(ViewHelpers.retargetButtonTitle(insertTargetAppName: "", insertTargetUsesFallback: false) == "Retarget")
    }

    @Test("retargetTitle: named target")
    func retargetTitleNamed() {
        let result = ViewHelpers.retargetButtonTitle(insertTargetAppName: "Safari", insertTargetUsesFallback: false)
        #expect(result == "Retarget → Safari")
    }

    @Test("retargetTitle: fallback target")
    func retargetTitleFallback() {
        let result = ViewHelpers.retargetButtonTitle(insertTargetAppName: "Safari", insertTargetUsesFallback: true)
        #expect(result == "Retarget → Safari (recent)")
    }

    // MARK: - retargetButtonHelpText

    @Test("retargetHelp: recording")
    func retargetHelpRecording() {
        #expect(ViewHelpers.retargetButtonHelpText(isRecording: true, pendingChunkCount: 0) == "Finish recording before retargeting insertion")
    }

    @Test("retargetHelp: pending chunks")
    func retargetHelpPending() {
        #expect(ViewHelpers.retargetButtonHelpText(isRecording: false, pendingChunkCount: 1) == "Wait for finalization before retargeting insertion")
    }

    @Test("retargetHelp: idle")
    func retargetHelpIdle() {
        #expect(ViewHelpers.retargetButtonHelpText(isRecording: false, pendingChunkCount: 0) == "Refresh insertion target from your current front app")
    }

    // MARK: - useCurrentAppButtonTitle

    @Test("useCurrentTitle: can insert with front app")
    func useCurrentTitleInsertFront() {
        #expect(ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: "Notes") == "Use Current → Notes")
    }

    @Test("useCurrentTitle: can insert no front app")
    func useCurrentTitleInsertNoFront() {
        #expect(ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: nil) == "Use Current App")
    }

    @Test("useCurrentTitle: cannot insert")
    func useCurrentTitleCopy() {
        #expect(ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: false, currentFrontAppName: "Notes") == "Use Current + Copy")
    }

    // MARK: - useCurrentAppButtonHelpText

    @Test("useCurrentHelp: disabled reason")
    func useCurrentHelpDisabled() {
        #expect(ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: "Record first", canInsertDirectly: true) == "Record first before using current app")
    }

    @Test("useCurrentHelp: can insert")
    func useCurrentHelpInsert() {
        #expect(ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true) == "Retarget to the current front app and insert immediately")
    }

    @Test("useCurrentHelp: copy fallback")
    func useCurrentHelpCopy() {
        #expect(ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: false) == "Retarget to the current front app and copy to clipboard")
    }

    // MARK: - retargetAndInsertButtonTitle

    @Test("retargetInsertTitle: can insert with front app")
    func retargetInsertTitleFront() {
        #expect(ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: true, currentFrontAppName: "Notes") == "Retarget + Insert → Notes")
    }

    @Test("retargetInsertTitle: can insert no front app")
    func retargetInsertTitleNoFront() {
        #expect(ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: true, currentFrontAppName: nil) == "Retarget + Insert → Current App")
    }

    @Test("retargetInsertTitle: cannot insert")
    func retargetInsertTitleCopy() {
        #expect(ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: false, currentFrontAppName: nil) == "Retarget + Copy → Clipboard")
    }

    // MARK: - retargetAndInsertHelpText

    @Test("retargetInsertHelp: disabled reason")
    func retargetInsertHelpDisabled() {
        #expect(ViewHelpers.retargetAndInsertHelpText(insertActionDisabledReason: "Wait", canInsertDirectly: true) == "Wait before retargeting and inserting")
    }

    @Test("retargetInsertHelp: cannot insert")
    func retargetInsertHelpCopy() {
        #expect(ViewHelpers.retargetAndInsertHelpText(insertActionDisabledReason: nil, canInsertDirectly: false) == "Refresh target app, then copy transcription to clipboard")
    }

    @Test("retargetInsertHelp: can insert")
    func retargetInsertHelpInsert() {
        #expect(ViewHelpers.retargetAndInsertHelpText(insertActionDisabledReason: nil, canInsertDirectly: true) == "Refresh target app from the current front app, then insert")
    }

    // MARK: - focusTargetButtonTitle

    @Test("focusTargetTitle: nil target")
    func focusTargetTitleNil() {
        #expect(ViewHelpers.focusTargetButtonTitle(insertTargetAppName: nil) == "Focus Target")
    }

    @Test("focusTargetTitle: empty target")
    func focusTargetTitleEmpty() {
        #expect(ViewHelpers.focusTargetButtonTitle(insertTargetAppName: "") == "Focus Target")
    }

    @Test("focusTargetTitle: named target")
    func focusTargetTitleNamed() {
        #expect(ViewHelpers.focusTargetButtonTitle(insertTargetAppName: "Safari") == "Focus → Safari")
    }

    // MARK: - focusTargetButtonHelpText

    @Test("focusTargetHelp: recording")
    func focusTargetHelpRecording() {
        #expect(ViewHelpers.focusTargetButtonHelpText(isRecording: true, pendingChunkCount: 0, insertTargetAppName: "Safari") == "Wait for recording/finalization to finish before focusing the target app")
    }

    @Test("focusTargetHelp: pending")
    func focusTargetHelpPending() {
        #expect(ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 1, insertTargetAppName: "Safari") == "Wait for recording/finalization to finish before focusing the target app")
    }

    @Test("focusTargetHelp: idle with target")
    func focusTargetHelpIdleTarget() {
        #expect(ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 0, insertTargetAppName: "Safari") == "Bring Safari to the front before inserting")
    }

    @Test("focusTargetHelp: idle no target")
    func focusTargetHelpIdleNoTarget() {
        #expect(ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 0, insertTargetAppName: nil) == "No insertion target yet. Switch to your destination app, then click Retarget.")
    }

    // MARK: - focusAndInsertButtonTitle

    @Test("focusInsertTitle: can insert with target")
    func focusInsertTitleTarget() {
        #expect(ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: true, insertTargetAppName: "Notes") == "Focus + Insert → Notes")
    }

    @Test("focusInsertTitle: can insert no target")
    func focusInsertTitleNoTarget() {
        #expect(ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: true, insertTargetAppName: nil) == "Focus + Insert")
    }

    @Test("focusInsertTitle: cannot insert")
    func focusInsertTitleCopy() {
        #expect(ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: false, insertTargetAppName: "Notes") == "Focus + Copy")
    }

    // MARK: - focusAndInsertButtonHelpText

    @Test("focusInsertHelp: disabled reason")
    func focusInsertHelpDisabled() {
        #expect(ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: "Wait", hasResolvableInsertTarget: true, canInsertDirectly: true) == "Wait before focusing and inserting")
    }

    @Test("focusInsertHelp: no resolvable target")
    func focusInsertHelpNoTarget() {
        #expect(ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: nil, hasResolvableInsertTarget: false, canInsertDirectly: true) == "No insertion target yet. Switch to your destination app, then click Retarget.")
    }

    @Test("focusInsertHelp: can insert")
    func focusInsertHelpInsert() {
        #expect(ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: nil, hasResolvableInsertTarget: true, canInsertDirectly: true) == "Focus the saved insert target and insert immediately")
    }

    @Test("focusInsertHelp: copy fallback")
    func focusInsertHelpCopy() {
        #expect(ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: nil, hasResolvableInsertTarget: true, canInsertDirectly: false) == "Focus the saved insert target and copy to clipboard")
    }
}
