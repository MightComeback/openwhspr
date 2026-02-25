import Testing
import Foundation
@testable import OpenWhisper

@Suite("Deep edge-case integration tests")
struct DeepEdgeCaseIntegrationTests {

    // MARK: - menuBarDurationLabel comprehensive branches

    @Test("menuBarDurationLabel: insertion flash overrides everything")
    func menuBarInsertionFlashOverrides() {
        let result = ViewHelpers.menuBarDurationLabel(
            isRecording: true,
            pendingChunkCount: 5,
            recordingElapsedSeconds: 120,
            isStartAfterFinalizeQueued: true,
            averageChunkLatency: 2.0,
            lastChunkLatency: 1.5,
            transcriptionWordCount: 42,
            isShowingInsertionFlash: true
        )
        #expect(result == "Inserted")
    }

    @Test("menuBarDurationLabel: recording with zero elapsed")
    func menuBarRecordingZeroElapsed() {
        let result = ViewHelpers.menuBarDurationLabel(
            isRecording: true,
            pendingChunkCount: 0,
            recordingElapsedSeconds: 0,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0,
            lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(result == "0:00")
    }

    @Test("menuBarDurationLabel: recording nil elapsed returns nil")
    func menuBarRecordingNilElapsed() {
        let result = ViewHelpers.menuBarDurationLabel(
            isRecording: true,
            pendingChunkCount: 0,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0,
            lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(result == nil)
    }

    @Test("menuBarDurationLabel: finalizing with queued start and latency")
    func menuBarFinalizingQueuedStart() {
        let result = ViewHelpers.menuBarDurationLabel(
            isRecording: false,
            pendingChunkCount: 3,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: true,
            averageChunkLatency: 2.0,
            lastChunkLatency: 1.0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(result == "3⏳6s→●")
    }

    @Test("menuBarDurationLabel: finalizing without queued start uses lastChunkLatency")
    func menuBarFinalizingLastChunkLatency() {
        let result = ViewHelpers.menuBarDurationLabel(
            isRecording: false,
            pendingChunkCount: 2,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0,
            lastChunkLatency: 3.0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(result == "2⏳6s")
    }

    @Test("menuBarDurationLabel: finalizing no latency shows count left")
    func menuBarFinalizingNoLatency() {
        let result = ViewHelpers.menuBarDurationLabel(
            isRecording: false,
            pendingChunkCount: 4,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0,
            lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(result == "4 left")
    }

    @Test("menuBarDurationLabel: finalizing no latency with queued start")
    func menuBarFinalizingNoLatencyQueued() {
        let result = ViewHelpers.menuBarDurationLabel(
            isRecording: false,
            pendingChunkCount: 1,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: true,
            averageChunkLatency: 0,
            lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(result == "1 left→●")
    }

    @Test("menuBarDurationLabel: idle with word count")
    func menuBarIdleWordCount() {
        let result = ViewHelpers.menuBarDurationLabel(
            isRecording: false,
            pendingChunkCount: 0,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0,
            lastChunkLatency: 0,
            transcriptionWordCount: 17,
            isShowingInsertionFlash: false
        )
        #expect(result == "17w")
    }

    @Test("menuBarDurationLabel: idle zero words returns nil")
    func menuBarIdleNoWords() {
        let result = ViewHelpers.menuBarDurationLabel(
            isRecording: false,
            pendingChunkCount: 0,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0,
            lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(result == nil)
    }

    // MARK: - menuBarIconName all branches

    @Test("menuBarIconName: insertion flash")
    func iconFlash() {
        #expect(ViewHelpers.menuBarIconName(isRecording: false, pendingChunkCount: 0, hasTranscriptionText: false, isShowingInsertionFlash: true) == "checkmark.circle.fill")
    }

    @Test("menuBarIconName: recording overrides pending")
    func iconRecording() {
        #expect(ViewHelpers.menuBarIconName(isRecording: true, pendingChunkCount: 3, hasTranscriptionText: true, isShowingInsertionFlash: false) == "waveform.circle.fill")
    }

    @Test("menuBarIconName: pending chunks")
    func iconPending() {
        #expect(ViewHelpers.menuBarIconName(isRecording: false, pendingChunkCount: 1, hasTranscriptionText: false, isShowingInsertionFlash: false) == "ellipsis.circle")
    }

    @Test("menuBarIconName: has text")
    func iconHasText() {
        #expect(ViewHelpers.menuBarIconName(isRecording: false, pendingChunkCount: 0, hasTranscriptionText: true, isShowingInsertionFlash: false) == "doc.text")
    }

    @Test("menuBarIconName: idle")
    func iconIdle() {
        #expect(ViewHelpers.menuBarIconName(isRecording: false, pendingChunkCount: 0, hasTranscriptionText: false, isShowingInsertionFlash: false) == "mic")
    }

    // MARK: - liveWordsPerMinute edge cases

    @Test("liveWordsPerMinute: exactly 5 seconds")
    func wpmExactly5Seconds() {
        let result = ViewHelpers.liveWordsPerMinute(transcription: "hello world", durationSeconds: 5.0)
        #expect(result == 24) // 2 words * 60 / 5 = 24
    }

    @Test("liveWordsPerMinute: under 5 seconds returns nil")
    func wpmUnder5Seconds() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello world", durationSeconds: 4.99) == nil)
    }

    @Test("liveWordsPerMinute: empty text returns nil")
    func wpmEmptyText() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "", durationSeconds: 60) == nil)
    }

    @Test("liveWordsPerMinute: whitespace only returns nil")
    func wpmWhitespaceOnly() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "   \n\t  ", durationSeconds: 60) == nil)
    }

    @Test("liveWordsPerMinute: minimum 1 wpm")
    func wpmMinimumOne() {
        // 1 word over 3600 seconds = 0.0167 wpm → rounds to 0, but min is 1
        let result = ViewHelpers.liveWordsPerMinute(transcription: "hello", durationSeconds: 3600)
        #expect(result == 1)
    }

    // MARK: - transcriptionWordCount edge cases

    @Test("transcriptionWordCount: punctuation-only text")
    func wordCountPunctuationOnly() {
        #expect(ViewHelpers.transcriptionWordCount("... --- ???") == 0)
    }

    @Test("transcriptionWordCount: mixed content")
    func wordCountMixed() {
        #expect(ViewHelpers.transcriptionWordCount("hello, world! 123") == 3)
    }

    @Test("transcriptionWordCount: unicode")
    func wordCountUnicode() {
        #expect(ViewHelpers.transcriptionWordCount("日本語 テスト") > 0)
    }

    // MARK: - transcriptionStats

    @Test("transcriptionStats: empty string")
    func statsEmpty() {
        #expect(ViewHelpers.transcriptionStats("") == "0w · 0c")
    }

    @Test("transcriptionStats: single word")
    func statsSingleWord() {
        #expect(ViewHelpers.transcriptionStats("hello") == "1w · 5c")
    }

    // MARK: - liveLoopLagNotice branches

    @Test("liveLoopLagNotice: estimated time >= 6s triggers warning")
    func lagNoticeEstimatedTime() {
        let result = ViewHelpers.liveLoopLagNotice(pendingChunkCount: 2, estimatedFinalizationSeconds: 6.0)
        #expect(result != nil)
        #expect(result!.contains("falling behind"))
    }

    @Test("liveLoopLagNotice: estimated time < 6s but >= 3 chunks triggers chunk warning")
    func lagNoticeChunkCount() {
        let result = ViewHelpers.liveLoopLagNotice(pendingChunkCount: 3, estimatedFinalizationSeconds: 4.0)
        #expect(result != nil)
        #expect(result!.contains("3 chunks"))
    }

    @Test("liveLoopLagNotice: under threshold returns nil")
    func lagNoticeUnderThreshold() {
        #expect(ViewHelpers.liveLoopLagNotice(pendingChunkCount: 2, estimatedFinalizationSeconds: 5.0) == nil)
    }

    @Test("liveLoopLagNotice: nil estimated with 3+ chunks")
    func lagNoticeNilEstimated() {
        let result = ViewHelpers.liveLoopLagNotice(pendingChunkCount: 4, estimatedFinalizationSeconds: nil)
        #expect(result != nil)
        #expect(result!.contains("4 chunks"))
    }

    @Test("liveLoopLagNotice: nil estimated with <3 chunks returns nil")
    func lagNoticeNilEstimatedLow() {
        #expect(ViewHelpers.liveLoopLagNotice(pendingChunkCount: 2, estimatedFinalizationSeconds: nil) == nil)
    }

    // MARK: - estimatedFinalizationSeconds

    @Test("estimatedFinalizationSeconds: zero chunks returns nil")
    func estFinNone() {
        #expect(ViewHelpers.estimatedFinalizationSeconds(pendingChunkCount: 0, averageChunkLatency: 2.0, lastChunkLatency: 1.0) == nil)
    }

    @Test("estimatedFinalizationSeconds: prefers average over last")
    func estFinPrefersAverage() {
        let result = ViewHelpers.estimatedFinalizationSeconds(pendingChunkCount: 3, averageChunkLatency: 2.0, lastChunkLatency: 5.0)
        #expect(result == 6.0)
    }

    @Test("estimatedFinalizationSeconds: falls back to last when average is 0")
    func estFinFallsBackToLast() {
        let result = ViewHelpers.estimatedFinalizationSeconds(pendingChunkCount: 4, averageChunkLatency: 0, lastChunkLatency: 3.0)
        #expect(result == 12.0)
    }

    @Test("estimatedFinalizationSeconds: both zero returns nil")
    func estFinBothZero() {
        #expect(ViewHelpers.estimatedFinalizationSeconds(pendingChunkCount: 2, averageChunkLatency: 0, lastChunkLatency: 0) == nil)
    }

    // MARK: - finalizationProgress

    @Test("finalizationProgress: recording returns nil")
    func finProgressRecording() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 3, initialPendingChunks: 5, isRecording: true) == nil)
    }

    @Test("finalizationProgress: zero pending returns nil")
    func finProgressZeroPending() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 0, initialPendingChunks: 5, isRecording: false) == nil)
    }

    @Test("finalizationProgress: nil initial returns nil")
    func finProgressNilInitial() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 2, initialPendingChunks: nil, isRecording: false) == nil)
    }

    @Test("finalizationProgress: zero initial returns nil")
    func finProgressZeroInitial() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 2, initialPendingChunks: 0, isRecording: false) == nil)
    }

    @Test("finalizationProgress: halfway")
    func finProgressHalfway() {
        let result = ViewHelpers.finalizationProgress(pendingChunkCount: 5, initialPendingChunks: 10, isRecording: false)
        #expect(result == 0.5)
    }

    @Test("finalizationProgress: complete except last chunk")
    func finProgressAlmostDone() {
        let result = ViewHelpers.finalizationProgress(pendingChunkCount: 1, initialPendingChunks: 10, isRecording: false)
        #expect(result == 0.9)
    }

    // MARK: - isInsertionFlashVisible

    @Test("isInsertionFlashVisible: nil date")
    func flashNil() {
        #expect(ViewHelpers.isInsertionFlashVisible(insertedAt: nil, now: Date()) == false)
    }

    @Test("isInsertionFlashVisible: within duration")
    func flashWithin() {
        let now = Date()
        #expect(ViewHelpers.isInsertionFlashVisible(insertedAt: now.addingTimeInterval(-2), now: now, flashDuration: 3) == true)
    }

    @Test("isInsertionFlashVisible: exactly at duration boundary")
    func flashAtBoundary() {
        let now = Date()
        #expect(ViewHelpers.isInsertionFlashVisible(insertedAt: now.addingTimeInterval(-3), now: now, flashDuration: 3) == false)
    }

    @Test("isInsertionFlashVisible: past duration")
    func flashPast() {
        let now = Date()
        #expect(ViewHelpers.isInsertionFlashVisible(insertedAt: now.addingTimeInterval(-10), now: now) == false)
    }

    // MARK: - insertTargetAgeDescription branches

    @Test("insertTargetAgeDescription: nil capturedAt")
    func targetAgeNil() {
        #expect(ViewHelpers.insertTargetAgeDescription(capturedAt: nil, now: Date(), staleAfterSeconds: 60, isStale: false) == nil)
    }

    @Test("insertTargetAgeDescription: just now, not stale")
    func targetAgeJustNow() {
        let now = Date()
        let result = ViewHelpers.insertTargetAgeDescription(capturedAt: now, now: now, staleAfterSeconds: 60, isStale: false)
        #expect(result == "Target captured just now")
    }

    @Test("insertTargetAgeDescription: stale")
    func targetAgeStale() {
        let now = Date()
        let result = ViewHelpers.insertTargetAgeDescription(capturedAt: now.addingTimeInterval(-120), now: now, staleAfterSeconds: 60, isStale: true)
        #expect(result != nil)
        #expect(result!.contains("stale"))
    }

    @Test("insertTargetAgeDescription: about to go stale (remaining <= 10)")
    func targetAgeAboutToStale() {
        let now = Date()
        let captured = now.addingTimeInterval(-55) // 55s elapsed, 5s remaining for 60s stale
        let result = ViewHelpers.insertTargetAgeDescription(capturedAt: captured, now: now, staleAfterSeconds: 60, isStale: false)
        #expect(result != nil)
        #expect(result!.contains("stale in"))
    }

    // MARK: - lastSuccessfulInsertDescription

    @Test("lastSuccessfulInsertDescription: nil")
    func lastInsertNil() {
        #expect(ViewHelpers.lastSuccessfulInsertDescription(insertedAt: nil, now: Date()) == nil)
    }

    @Test("lastSuccessfulInsertDescription: just now")
    func lastInsertJustNow() {
        let now = Date()
        let result = ViewHelpers.lastSuccessfulInsertDescription(insertedAt: now, now: now)
        #expect(result == "Last insert succeeded just now")
    }

    @Test("lastSuccessfulInsertDescription: some time ago")
    func lastInsertAgo() {
        let now = Date()
        let result = ViewHelpers.lastSuccessfulInsertDescription(insertedAt: now.addingTimeInterval(-30), now: now)
        #expect(result != nil)
        #expect(result!.contains("ago"))
    }

    // MARK: - insertionTestDisabledReason all branches

    @Test("insertionTestDisabledReason: recording")
    func disabledRecording() {
        let r = ViewHelpers.insertionTestDisabledReason(isRecording: true, isFinalizingTranscription: false, isRunningInsertionProbe: false, hasInsertionProbeSampleText: true, hasInsertionTarget: true)
        #expect(r.contains("Stop recording"))
    }

    @Test("insertionTestDisabledReason: finalizing")
    func disabledFinalizing() {
        let r = ViewHelpers.insertionTestDisabledReason(isRecording: false, isFinalizingTranscription: true, isRunningInsertionProbe: false, hasInsertionProbeSampleText: true, hasInsertionTarget: true)
        #expect(r.contains("finalizing"))
    }

    @Test("insertionTestDisabledReason: already running")
    func disabledRunning() {
        let r = ViewHelpers.insertionTestDisabledReason(isRecording: false, isFinalizingTranscription: false, isRunningInsertionProbe: true, hasInsertionProbeSampleText: true, hasInsertionTarget: true)
        #expect(r.contains("already running"))
    }

    @Test("insertionTestDisabledReason: empty text")
    func disabledEmptyText() {
        let r = ViewHelpers.insertionTestDisabledReason(isRecording: false, isFinalizingTranscription: false, isRunningInsertionProbe: false, hasInsertionProbeSampleText: false, hasInsertionTarget: true)
        #expect(r.contains("empty"))
    }

    @Test("insertionTestDisabledReason: no target")
    func disabledNoTarget() {
        let r = ViewHelpers.insertionTestDisabledReason(isRecording: false, isFinalizingTranscription: false, isRunningInsertionProbe: false, hasInsertionProbeSampleText: true, hasInsertionTarget: false)
        #expect(r.contains("destination"))
    }

    // MARK: - insertionProbeStatus

    @Test("insertionProbeStatus: true → success")
    func probeSuccess() {
        #expect(ViewHelpers.insertionProbeStatus(succeeded: true) == .success)
    }

    @Test("insertionProbeStatus: false → failure")
    func probeFailure() {
        #expect(ViewHelpers.insertionProbeStatus(succeeded: false) == .failure)
    }

    @Test("insertionProbeStatus: nil → unknown")
    func probeUnknown() {
        #expect(ViewHelpers.insertionProbeStatus(succeeded: nil) == .unknown)
    }

    // MARK: - shouldCopyBecauseTargetUnknown

    @Test("shouldCopyBecauseTargetUnknown: canInsertDirectly false returns false")
    func copyUnknownCantInsert() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(canInsertDirectly: false, hasResolvableInsertTarget: false, hasExternalFrontApp: false) == false)
    }

    // MARK: - hotkeySystemConflictWarning: every known conflict

    @Test("conflict: ⌘+Space → Spotlight")
    func conflictCmdSpace() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "space")
        #expect(w != nil)
        #expect(w!.contains("Spotlight"))
    }

    @Test("conflict: ⌃+Space → input source")
    func conflictCtrlSpace() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.control], key: "space")
        #expect(w != nil)
        #expect(w!.contains("input source"))
    }

    @Test("conflict: ⌃+⌥+Space → previous input source")
    func conflictCtrlOptSpace() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.control, .option], key: "space")
        #expect(w != nil)
    }

    @Test("conflict: ⌃+⌘+Space → emoji picker")
    func conflictCtrlCmdSpace() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .control], key: "space")
        #expect(w != nil)
        #expect(w!.contains("emoji"))
    }

    @Test("conflict: ⌥+⌘+Space → Finder search")
    func conflictOptCmdSpace() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .option], key: "space")
        #expect(w != nil)
        #expect(w!.contains("Finder"))
    }

    @Test("conflict: ⌃+⌥+⌘+Space → launchers")
    func conflictTripleSpace() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .option, .control], key: "space")
        #expect(w != nil)
    }

    @Test("conflict: ⌃+⌘+F → fullscreen")
    func conflictCtrlCmdF() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .control], key: "f")
        #expect(w != nil)
        #expect(w!.contains("full-screen"))
    }

    @Test("conflict: ⌘+Tab → app switching")
    func conflictCmdTab() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "tab")
        #expect(w != nil)
    }

    @Test("conflict: Fn alone → system reserved")
    func conflictFnAlone() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [], key: "fn")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+⇧+Tab → reverse app switching")
    func conflictCmdShiftTab() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "tab")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+⇧+3 → screenshot")
    func conflictScreenshot3() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "3")
        #expect(w != nil)
        #expect(w!.contains("screenshot"))
    }

    @Test("conflict: ⌘+⇧+4 → screenshot selection")
    func conflictScreenshot4() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "4")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+⇧+5 → screenshot panel")
    func conflictScreenshot5() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "5")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+⇧+6 → screenshot thumbnail")
    func conflictScreenshot6() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "6")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+` → window cycling")
    func conflictCmdBacktick() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "backtick")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+§ → ISO window cycling")
    func conflictCmdSection() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "section")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+⇧+§ → reverse ISO cycling")
    func conflictCmdShiftSection() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "section")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+, → settings")
    func conflictCmdComma() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "comma")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+. → cancel/stop")
    func conflictCmdPeriod() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "period")
        #expect(w != nil)
    }

    @Test("conflict: ⌥+⌘+Esc → Force Quit")
    func conflictForceQuit() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .option], key: "escape")
        #expect(w != nil)
        #expect(w!.contains("Force Quit"))
    }

    @Test("conflict: ⌘+H → hide")
    func conflictCmdH() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "h")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+C → copy")
    func conflictCmdC() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "c")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+V → paste")
    func conflictCmdV() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "v")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+X → cut")
    func conflictCmdX() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "x")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+A → select all")
    func conflictCmdA() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "a")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+Z → undo")
    func conflictCmdZ() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "z")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+M → minimize")
    func conflictCmdM() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "m")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+Return → send")
    func conflictCmdReturn() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "return")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+Q → quit")
    func conflictCmdQ() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "q")
        #expect(w != nil)
    }

    @Test("conflict: ⌃+⌘+Q → lock")
    func conflictCtrlCmdQ() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .control], key: "q")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+W → close")
    func conflictCmdW() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "w")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+S → save")
    func conflictCmdS() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "s")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+F → find")
    func conflictCmdF() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "f")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+N → new")
    func conflictCmdN() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "n")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+T → new tab")
    func conflictCmdT() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "t")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+P → print")
    func conflictCmdP() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "p")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+R → refresh")
    func conflictCmdR() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "r")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+O → open")
    func conflictCmdO() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "o")
        #expect(w != nil)
    }

    @Test("conflict: ⌘+L → location bar")
    func conflictCmdL() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "l")
        #expect(w != nil)
    }

    @Test("no conflict: ⌘+⇧+Space (safe combo)")
    func noConflictSafe() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "space") == nil)
    }

    @Test("no conflict: ⌘+⇧+K (safe combo)")
    func noConflictCmdShiftK() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "k") == nil)
    }

    // MARK: - isHighRiskHotkey

    @Test("isHighRiskHotkey: single char no modifiers")
    func highRiskSingleChar() {
        #expect(ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "a") == true)
    }

    @Test("isHighRiskHotkey: space no modifiers")
    func highRiskSpace() {
        #expect(ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "space") == true)
    }

    @Test("isHighRiskHotkey: with modifier not high risk")
    func notHighRiskWithModifier() {
        #expect(ViewHelpers.isHighRiskHotkey(requiredModifiers: [.command], key: "a") == false)
    }

    @Test("isHighRiskHotkey: f1 without modifiers not high risk")
    func notHighRiskF1() {
        #expect(ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "f1") == false)
    }

    @Test("isHighRiskHotkey: escape without modifiers")
    func highRiskEscape() {
        #expect(ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "escape") == true)
    }

    // MARK: - hotkeyEscapeCancelConflictWarning

    @Test("escape conflict warning present")
    func escapeConflict() {
        #expect(ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "escape") != nil)
    }

    @Test("non-escape no warning")
    func nonEscapeNoConflict() {
        #expect(ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "space") == nil)
    }

    // MARK: - shouldAutoApplySafeCaptureModifiers

    @Test("single character needs safe modifiers")
    func safeModsSingleChar() {
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "k") == true)
    }

    @Test("function key doesn't need safe modifiers")
    func safeModsFKey() {
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "f5") == false)
    }

    @Test("escape doesn't need safe modifiers")
    func safeModsEscape() {
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "escape") == false)
    }

    @Test("space doesn't need safe modifiers")
    func safeModsSpace() {
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "space") == false)
    }

    @Test("capslock doesn't need safe modifiers")
    func safeModsCapsLock() {
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "capslock") == false)
    }

    @Test("multi-char unknown key needs safe modifiers")
    func safeModsUnknownMultiChar() {
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "xyzzy") == true)
    }

    // MARK: - formatDuration / formatShortDuration

    @Test("formatDuration: zero seconds")
    func formatDurationZero() {
        #expect(ViewHelpers.formatDuration(0) == "0:00")
    }

    @Test("formatDuration: 90 seconds")
    func formatDuration90() {
        #expect(ViewHelpers.formatDuration(90) == "1:30")
    }

    @Test("formatShortDuration: under 60s")
    func shortDurationUnder60() {
        #expect(ViewHelpers.formatShortDuration(45) == "45s")
    }

    @Test("formatShortDuration: 60s exactly")
    func shortDuration60() {
        let result = ViewHelpers.formatShortDuration(60)
        #expect(result.contains("1"))
    }

    @Test("formatShortDuration: over 60s")
    func shortDurationOver60() {
        let result = ViewHelpers.formatShortDuration(90)
        #expect(result.contains("m"))
    }

    // MARK: - formatBytes

    @Test("formatBytes: zero")
    func formatBytesZero() {
        #expect(ViewHelpers.formatBytes(0) == "Zero KB")
    }

    @Test("formatBytes: kilobytes")
    func formatBytesKB() {
        let result = ViewHelpers.formatBytes(1024)
        #expect(result.contains("KB") || result.contains("kB") || result.contains("1"))
    }

    @Test("formatBytes: megabytes")
    func formatBytesMB() {
        let result = ViewHelpers.formatBytes(1_048_576)
        #expect(result.contains("MB") || result.contains("1"))
    }

    // MARK: - historyEntryStats

    @Test("historyEntryStats: no duration")
    func entryStatsNoDuration() {
        let result = ViewHelpers.historyEntryStats(text: "hello world", durationSeconds: nil)
        #expect(result.contains("2w"))
    }

    @Test("historyEntryStats: with duration")
    func entryStatsWithDuration() {
        let result = ViewHelpers.historyEntryStats(text: "hello", durationSeconds: 30)
        #expect(result.contains("1w"))
    }

    // MARK: - hotkeyKeyNameForKeyCode comprehensive

    @Test("keyCode: space (0x31)")
    func keyCodeSpace() {
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x31) == "space")
    }

    @Test("keyCode: modifier keys return nil")
    func keyCodeModifiers() {
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x37) == nil) // Cmd
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x38) == nil) // Shift
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x3A) == nil) // Option
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x3B) == nil) // Control
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x39) == nil) // CapsLock
    }

    @Test("keyCode: fn (0x3F)")
    func keyCodeFn() {
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x3F) == "fn")
    }

    @Test("keyCode: tab")
    func keyCodeTab() {
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x30) == "tab")
    }

    @Test("keyCode: return")
    func keyCodeReturn() {
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x24) == "return")
    }

    @Test("keyCode: escape")
    func keyCodeEscape() {
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x35) == "escape")
    }

    @Test("keyCode: arrows")
    func keyCodeArrows() {
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x7B) == "left")
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x7C) == "right")
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x7E) == "up")
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x7D) == "down")
    }

    @Test("keyCode: F-keys")
    func keyCodeFKeys() {
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x7A) == "f1")
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x78) == "f2")
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x6F) == "f12")
    }

    @Test("keyCode: unknown returns nil")
    func keyCodeUnknown() {
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0xFF) == nil)
    }

    @Test("isModifierOnlyKeyCode: modifier codes")
    func isModifierOnly() {
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x37) == true) // Cmd
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x38) == true) // Shift
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x3A) == true) // Option
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x3B) == true) // Control
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x39) == true) // CapsLock
    }

    @Test("isModifierOnlyKeyCode: non-modifier codes")
    func isNotModifierOnly() {
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x31) == false) // Space
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x24) == false) // Return
    }
}
