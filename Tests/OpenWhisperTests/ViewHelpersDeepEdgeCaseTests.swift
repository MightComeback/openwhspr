import Testing
import Foundation
@testable import OpenWhisper

@Suite("ViewHelpers Deep Edge Cases")
struct ViewHelpersDeepEdgeCaseTests {

    // MARK: - showsInsertionTestAutoCaptureHintResolved

    @Test("autoCaptureHintResolved: all false returns false")
    func autoCaptureHintAllFalse() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(
            isRunningProbe: false, canRunTest: false, canCaptureAndRun: false
        ) == false)
    }

    @Test("autoCaptureHintResolved: only canCaptureAndRun true returns true")
    func autoCaptureHintOnlyCapture() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(
            isRunningProbe: false, canRunTest: false, canCaptureAndRun: true
        ) == true)
    }

    @Test("autoCaptureHintResolved: running probe hides hint")
    func autoCaptureHintRunningProbe() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(
            isRunningProbe: true, canRunTest: false, canCaptureAndRun: true
        ) == false)
    }

    @Test("autoCaptureHintResolved: canRunTest hides hint")
    func autoCaptureHintCanRun() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(
            isRunningProbe: false, canRunTest: true, canCaptureAndRun: true
        ) == false)
    }

    @Test("autoCaptureHintResolved: all true returns false")
    func autoCaptureHintAllTrue() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(
            isRunningProbe: true, canRunTest: true, canCaptureAndRun: true
        ) == false)
    }

    // MARK: - insertionProbeStatusLabel

    @Test("probeStatusLabel: true returns Passed")
    func probeStatusPassed() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: true) == "Passed")
    }

    @Test("probeStatusLabel: false returns Failed")
    func probeStatusFailed() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: false) == "Failed")
    }

    @Test("probeStatusLabel: nil returns Not tested")
    func probeStatusNil() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: nil) == "Not tested")
    }

    // MARK: - historyEntryStats

    @Test("historyEntryStats: empty text returns 0w")
    func historyStatsEmpty() {
        #expect(ViewHelpers.historyEntryStats(text: "", durationSeconds: nil) == "0w")
    }

    @Test("historyEntryStats: single word no duration")
    func historyStatsSingleWord() {
        #expect(ViewHelpers.historyEntryStats(text: "Hello", durationSeconds: nil) == "1w")
    }

    @Test("historyEntryStats: multiple words with short duration")
    func historyStatsMultiWordShort() {
        #expect(ViewHelpers.historyEntryStats(text: "Hello world test", durationSeconds: 45) == "3w · 45s")
    }

    @Test("historyEntryStats: duration over 60s formats as minutes")
    func historyStatsMinutes() {
        let result = ViewHelpers.historyEntryStats(text: "word", durationSeconds: 125)
        #expect(result == "1w · 2:05")
    }

    @Test("historyEntryStats: zero duration omits duration")
    func historyStatsZeroDuration() {
        #expect(ViewHelpers.historyEntryStats(text: "word", durationSeconds: 0) == "1w")
    }

    @Test("historyEntryStats: negative duration omits duration")
    func historyStatsNegativeDuration() {
        #expect(ViewHelpers.historyEntryStats(text: "word", durationSeconds: -5) == "1w")
    }

    @Test("historyEntryStats: exactly 60s formats as 1:00")
    func historyStatsExactly60() {
        let result = ViewHelpers.historyEntryStats(text: "a b", durationSeconds: 60)
        #expect(result == "2w · 1:00")
    }

    @Test("historyEntryStats: whitespace-only text returns 0w")
    func historyStatsWhitespace() {
        #expect(ViewHelpers.historyEntryStats(text: "   \n  ", durationSeconds: nil) == "0w")
    }

    @Test("historyEntryStats: punctuation-only text returns 0w")
    func historyStatsPunctuation() {
        #expect(ViewHelpers.historyEntryStats(text: "...", durationSeconds: nil) == "0w")
    }

    @Test("historyEntryStats: text with leading/trailing whitespace")
    func historyStatsTrimsWhitespace() {
        #expect(ViewHelpers.historyEntryStats(text: "  hello world  ", durationSeconds: nil) == "2w")
    }

    @Test("historyEntryStats: fractional seconds rounds")
    func historyStatsFractional() {
        let result = ViewHelpers.historyEntryStats(text: "a", durationSeconds: 59.7)
        #expect(result == "1w · 1:00")
    }

    @Test("historyEntryStats: very large duration")
    func historyStatsLargeDuration() {
        let result = ViewHelpers.historyEntryStats(text: "a", durationSeconds: 3661)
        #expect(result == "1w · 61:01")
    }

    // MARK: - startStopButtonTitle

    @Test("startStopButtonTitle: recording returns Stop")
    func startStopRecording() {
        #expect(ViewHelpers.startStopButtonTitle(isRecording: true, pendingChunkCount: 0, isStartAfterFinalizeQueued: false) == "Stop")
    }

    @Test("startStopButtonTitle: not recording no pending returns Start")
    func startStopIdle() {
        #expect(ViewHelpers.startStopButtonTitle(isRecording: false, pendingChunkCount: 0, isStartAfterFinalizeQueued: false) == "Start")
    }

    @Test("startStopButtonTitle: pending chunks not queued returns Queue start")
    func startStopPendingNotQueued() {
        #expect(ViewHelpers.startStopButtonTitle(isRecording: false, pendingChunkCount: 2, isStartAfterFinalizeQueued: false) == "Queue start")
    }

    @Test("startStopButtonTitle: pending chunks queued returns Cancel queued start")
    func startStopPendingQueued() {
        #expect(ViewHelpers.startStopButtonTitle(isRecording: false, pendingChunkCount: 1, isStartAfterFinalizeQueued: true) == "Cancel queued start")
    }

    @Test("startStopButtonTitle: recording overrides pending state")
    func startStopRecordingOverrides() {
        #expect(ViewHelpers.startStopButtonTitle(isRecording: true, pendingChunkCount: 5, isStartAfterFinalizeQueued: true) == "Stop")
    }

    // MARK: - startStopButtonHelpText

    @Test("startStopButtonHelpText: recording returns stop message")
    func startStopHelpRecording() {
        let result = ViewHelpers.startStopButtonHelpText(isRecording: true, pendingChunkCount: 0, isStartAfterFinalizeQueued: false, microphoneAuthorized: true)
        #expect(result.contains("Stop"))
    }

    @Test("startStopButtonHelpText: no mic permission warns")
    func startStopHelpNoMic() {
        let result = ViewHelpers.startStopButtonHelpText(isRecording: false, pendingChunkCount: 0, isStartAfterFinalizeQueued: false, microphoneAuthorized: false)
        #expect(result.lowercased().contains("microphone") || result.lowercased().contains("permission"))
    }

    // MARK: - formatShortDuration

    @Test("formatShortDuration: zero seconds")
    func formatShortZero() {
        #expect(ViewHelpers.formatShortDuration(0) == "0s")
    }

    @Test("formatShortDuration: under a minute")
    func formatShortUnderMinute() {
        #expect(ViewHelpers.formatShortDuration(45) == "45s")
    }

    @Test("formatShortDuration: exactly 60 seconds")
    func formatShort60() {
        #expect(ViewHelpers.formatShortDuration(60) == "1m 0s")
    }

    @Test("formatShortDuration: over a minute")
    func formatShortOver() {
        #expect(ViewHelpers.formatShortDuration(125) == "2m 5s")
    }

    @Test("formatShortDuration: large value")
    func formatShortLarge() {
        #expect(ViewHelpers.formatShortDuration(3661) == "61m 1s")
    }

    @Test("formatShortDuration: fractional seconds rounds")
    func formatShortFractional() {
        #expect(ViewHelpers.formatShortDuration(59.9) == "1m 0s")
    }

    // MARK: - streamingElapsedStatusSegment

    @Test("streamingElapsed: negative returns nil")
    func streamingNegative() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: -1) == nil)
    }

    @Test("streamingElapsed: zero returns 0:00")
    func streamingZero() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 0) == "0:00")
    }

    @Test("streamingElapsed: 59 seconds returns 0:59")
    func streaming59s() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 59) == "0:59")
    }

    @Test("streamingElapsed: 60 seconds returns 1:00")
    func streaming60s() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 60) == "1:00")
    }

    @Test("streamingElapsed: 3599 returns 59:59")
    func streaming3599() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 3599) == "59:59")
    }

    @Test("streamingElapsed: 3600 returns 1:00:00")
    func streaming3600() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 3600) == "1:00:00")
    }

    @Test("streamingElapsed: 3661 returns 1:01:01")
    func streaming3661() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 3661) == "1:01:01")
    }

    @Test("streamingElapsed: 86399 returns 23:59:59")
    func streamingFullDay() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 86399) == "23:59:59")
    }

    // MARK: - sizeOfModelFile

    @Test("sizeOfModelFile: empty path returns 0")
    func sizeOfModelEmpty() {
        #expect(ViewHelpers.sizeOfModelFile(atPath: "") == 0)
    }

    @Test("sizeOfModelFile: nonexistent path returns 0")
    func sizeOfModelNonexistent() {
        #expect(ViewHelpers.sizeOfModelFile(atPath: "/nonexistent/path/model.bin") == 0)
    }

    @Test("sizeOfModelFile: valid file returns positive size")
    func sizeOfModelValid() throws {
        let tmp = NSTemporaryDirectory() + "test_model_\(UUID().uuidString).bin"
        try Data(repeating: 0xAB, count: 1024).write(to: URL(fileURLWithPath: tmp))
        defer { try? FileManager.default.removeItem(atPath: tmp) }
        #expect(ViewHelpers.sizeOfModelFile(atPath: tmp) == 1024)
    }

    // MARK: - isSentencePunctuation

    @Test("isSentencePunctuation: period")
    func sentencePuncPeriod() { #expect(ViewHelpers.isSentencePunctuation(".") == true) }

    @Test("isSentencePunctuation: comma")
    func sentencePuncComma() { #expect(ViewHelpers.isSentencePunctuation(",") == true) }

    @Test("isSentencePunctuation: exclamation")
    func sentencePuncExcl() { #expect(ViewHelpers.isSentencePunctuation("!") == true) }

    @Test("isSentencePunctuation: question")
    func sentencePuncQuestion() { #expect(ViewHelpers.isSentencePunctuation("?") == true) }

    @Test("isSentencePunctuation: semicolon")
    func sentencePuncSemicolon() { #expect(ViewHelpers.isSentencePunctuation(";") == true) }

    @Test("isSentencePunctuation: colon")
    func sentencePuncColon() { #expect(ViewHelpers.isSentencePunctuation(":") == true) }

    @Test("isSentencePunctuation: ellipsis")
    func sentencePuncEllipsis() { #expect(ViewHelpers.isSentencePunctuation("…") == true) }

    @Test("isSentencePunctuation: letter returns false")
    func sentencePuncLetter() { #expect(ViewHelpers.isSentencePunctuation("a") == false) }

    @Test("isSentencePunctuation: space returns false")
    func sentencePuncSpace() { #expect(ViewHelpers.isSentencePunctuation(" ") == false) }

    @Test("isSentencePunctuation: dash returns false")
    func sentencePuncDash() { #expect(ViewHelpers.isSentencePunctuation("-") == false) }

    // MARK: - trailingSentencePunctuation

    @Test("trailingSentencePunctuation: empty string returns nil")
    func trailingPuncEmpty() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "") == nil)
    }

    @Test("trailingSentencePunctuation: no punctuation returns nil")
    func trailingPuncNone() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "Hello world") == nil)
    }

    @Test("trailingSentencePunctuation: single period")
    func trailingPuncPeriod() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "Hello.") == ".")
    }

    @Test("trailingSentencePunctuation: multiple dots")
    func trailingPuncDots() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "Wait...") == "...")
    }

    @Test("trailingSentencePunctuation: mixed punctuation")
    func trailingPuncMixed() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "Really?!") == "?!")
    }

    @Test("trailingSentencePunctuation: trailing whitespace ignored")
    func trailingPuncWhitespace() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "Hello.  ") == ".")
    }

    @Test("trailingSentencePunctuation: only whitespace returns nil")
    func trailingPuncOnlyWhitespace() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "   ") == nil)
    }

    @Test("trailingSentencePunctuation: ellipsis character")
    func trailingPuncEllipsisChar() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "Hmm…") == "…")
    }

    // MARK: - statusTitle

    @Test("statusTitle: recording under 1s")
    func statusTitleRecordingShort() {
        #expect(ViewHelpers.statusTitle(isRecording: true, recordingDuration: 0.5, pendingChunkCount: 0) == "Recording")
    }

    @Test("statusTitle: recording over 1s includes duration")
    func statusTitleRecordingLong() {
        let result = ViewHelpers.statusTitle(isRecording: true, recordingDuration: 65, pendingChunkCount: 0)
        #expect(result.contains("Recording"))
        #expect(result.contains("•"))
    }

    @Test("statusTitle: not recording with 1 chunk singular")
    func statusTitleOneChunk() {
        #expect(ViewHelpers.statusTitle(isRecording: false, recordingDuration: 0, pendingChunkCount: 1) == "Finalizing • 1 chunk")
    }

    @Test("statusTitle: not recording with multiple chunks plural")
    func statusTitleMultiChunk() {
        #expect(ViewHelpers.statusTitle(isRecording: false, recordingDuration: 0, pendingChunkCount: 3) == "Finalizing • 3 chunks")
    }

    @Test("statusTitle: idle returns Ready")
    func statusTitleIdle() {
        #expect(ViewHelpers.statusTitle(isRecording: false, recordingDuration: 0, pendingChunkCount: 0) == "Ready")
    }

    // MARK: - finalizationProgress

    @Test("finalizationProgress: recording returns nil")
    func finProgressRecording() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 2, initialPendingChunks: 4, isRecording: true) == nil)
    }

    @Test("finalizationProgress: no pending returns nil")
    func finProgressNoPending() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 0, initialPendingChunks: 4, isRecording: false) == nil)
    }

    @Test("finalizationProgress: nil initial returns nil")
    func finProgressNilInitial() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 2, initialPendingChunks: nil, isRecording: false) == nil)
    }

    @Test("finalizationProgress: zero initial returns nil")
    func finProgressZeroInitial() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 2, initialPendingChunks: 0, isRecording: false) == nil)
    }

    @Test("finalizationProgress: half done returns 0.5")
    func finProgressHalf() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 2, initialPendingChunks: 4, isRecording: false) == 0.5)
    }

    @Test("finalizationProgress: all done returns 0 (still pending=initial)")
    func finProgressNoneCompleted() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 4, initialPendingChunks: 4, isRecording: false) == 0.0)
    }

    @Test("finalizationProgress: one left of four returns 0.75")
    func finProgressThreeQuarters() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 1, initialPendingChunks: 4, isRecording: false) == 0.75)
    }

    // MARK: - canToggleRecording

    @Test("canToggleRecording: mic authorized and not finalizing")
    func canToggleYes() {
        #expect(ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 0, microphoneAuthorized: true) == true)
    }

    @Test("canToggleRecording: no mic returns false")
    func canToggleNoMic() {
        #expect(ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 0, microphoneAuthorized: false) == false)
    }

    @Test("canToggleRecording: recording always returns true")
    func canToggleRecording() {
        #expect(ViewHelpers.canToggleRecording(isRecording: true, pendingChunkCount: 0, microphoneAuthorized: false) == true)
    }

    @Test("canToggleRecording: pending chunks returns true")
    func canTogglePending() {
        #expect(ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 2, microphoneAuthorized: false) == true)
    }

    // MARK: - liveWordsPerMinute

    @Test("liveWordsPerMinute: short duration returns nil")
    func wpmShortDuration() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello world test words more", durationSeconds: 3) == nil)
    }

    @Test("liveWordsPerMinute: empty text returns nil")
    func wpmEmptyText() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "", durationSeconds: 60) == nil)
    }

    @Test("liveWordsPerMinute: 60 words in 60 seconds")
    func wpmExact() {
        let words = (1...60).map { "word\($0)" }.joined(separator: " ")
        #expect(ViewHelpers.liveWordsPerMinute(transcription: words, durationSeconds: 60) == 60)
    }

    @Test("liveWordsPerMinute: 10 words in 30 seconds is 20 wpm")
    func wpmHalfMinute() {
        let words = (1...10).map { "word\($0)" }.joined(separator: " ")
        #expect(ViewHelpers.liveWordsPerMinute(transcription: words, durationSeconds: 30) == 20)
    }

    @Test("liveWordsPerMinute: negative elapsed returns nil")
    func wpmNegative() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello world", durationSeconds: -5) == nil)
    }

    // MARK: - transcriptionWordCount

    @Test("transcriptionWordCount: empty string")
    func wordCountEmpty() {
        #expect(ViewHelpers.transcriptionWordCount("") == 0)
    }

    @Test("transcriptionWordCount: whitespace only")
    func wordCountWhitespace() {
        #expect(ViewHelpers.transcriptionWordCount("   \n  ") == 0)
    }

    @Test("transcriptionWordCount: single word")
    func wordCountSingle() {
        #expect(ViewHelpers.transcriptionWordCount("hello") == 1)
    }

    @Test("transcriptionWordCount: multiple words")
    func wordCountMultiple() {
        #expect(ViewHelpers.transcriptionWordCount("hello world test") == 3)
    }

    @Test("transcriptionWordCount: words with punctuation")
    func wordCountPunctuation() {
        let count = ViewHelpers.transcriptionWordCount("Hello, world! How are you?")
        #expect(count >= 4) // at least the main words
    }

    // MARK: - abbreviatedAppName

    @Test("abbreviatedAppName: short name unchanged")
    func abbreviateShort() {
        #expect(ViewHelpers.abbreviatedAppName("Notes", maxCharacters: 18) == "Notes")
    }

    @Test("abbreviatedAppName: long name truncated with ellipsis")
    func abbreviateLong() {
        let result = ViewHelpers.abbreviatedAppName("Very Long Application Name Here", maxCharacters: 10)
        #expect(result.count <= 11) // 10 + ellipsis
        #expect(result.hasSuffix("…"))
    }

    @Test("abbreviatedAppName: exactly at limit unchanged")
    func abbreviateExact() {
        let name = String(repeating: "x", count: 18)
        #expect(ViewHelpers.abbreviatedAppName(name, maxCharacters: 18) == name)
    }

    @Test("abbreviatedAppName: one over limit truncated")
    func abbreviateOneOver() {
        let name = String(repeating: "x", count: 19)
        let result = ViewHelpers.abbreviatedAppName(name, maxCharacters: 18)
        #expect(result.hasSuffix("…"))
    }
}
