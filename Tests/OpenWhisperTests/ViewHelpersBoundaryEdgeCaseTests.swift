import Testing
import Foundation
@testable import OpenWhisper

@Suite("ViewHelpers – boundary & edge-case coverage")
struct ViewHelpersBoundaryEdgeCaseTests {

    // MARK: - transcriptionWordCount

    @Test("transcriptionWordCount: empty string")
    func wordCountEmpty() {
        #expect(ViewHelpers.transcriptionWordCount("") == 0)
    }

    @Test("transcriptionWordCount: whitespace only")
    func wordCountWhitespaceOnly() {
        #expect(ViewHelpers.transcriptionWordCount("   \n\t  ") == 0)
    }

    @Test("transcriptionWordCount: single word")
    func wordCountSingleWord() {
        #expect(ViewHelpers.transcriptionWordCount("hello") == 1)
    }

    @Test("transcriptionWordCount: punctuation-only is zero")
    func wordCountPunctuationOnly() {
        #expect(ViewHelpers.transcriptionWordCount("...!!!???") == 0)
    }

    @Test("transcriptionWordCount: mixed punctuation and words")
    func wordCountMixed() {
        #expect(ViewHelpers.transcriptionWordCount("hello, world! how's it?") == 5)
    }

    @Test("transcriptionWordCount: numbers count as words")
    func wordCountNumbers() {
        #expect(ViewHelpers.transcriptionWordCount("42 is the answer") == 4)
    }

    @Test("transcriptionWordCount: emoji-only is zero")
    func wordCountEmojiOnly() {
        #expect(ViewHelpers.transcriptionWordCount("🎉🎊") == 0)
    }

    @Test("transcriptionWordCount: leading/trailing whitespace trimmed")
    func wordCountTrimmed() {
        #expect(ViewHelpers.transcriptionWordCount("  hello world  ") == 2)
    }

    @Test("transcriptionWordCount: newlines separate words")
    func wordCountNewlines() {
        #expect(ViewHelpers.transcriptionWordCount("hello\nworld\nfoo") == 3)
    }

    // MARK: - transcriptionStats

    @Test("transcriptionStats: empty text gives 0w · 0c")
    func statsEmpty() {
        #expect(ViewHelpers.transcriptionStats("") == "0w · 0c")
    }

    @Test("transcriptionStats: single word with chars")
    func statsSingleWord() {
        let result = ViewHelpers.transcriptionStats("hello")
        #expect(result == "1w · 5c")
    }

    @Test("transcriptionStats: counts characters including punctuation")
    func statsWithPunctuation() {
        let result = ViewHelpers.transcriptionStats("hi!")
        #expect(result == "1w · 3c")
    }

    // MARK: - liveWordsPerMinute

    @Test("liveWordsPerMinute: nil when duration under 5 seconds")
    func wpmUnder5Seconds() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello world foo bar", durationSeconds: 4.9) == nil)
    }

    @Test("liveWordsPerMinute: nil at exactly 0 seconds")
    func wpmZeroDuration() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello", durationSeconds: 0) == nil)
    }

    @Test("liveWordsPerMinute: nil when text has no words")
    func wpmNoWords() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "...", durationSeconds: 60) == nil)
    }

    @Test("liveWordsPerMinute: nil when text is empty")
    func wpmEmpty() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "", durationSeconds: 60) == nil)
    }

    @Test("liveWordsPerMinute: correct at exactly 5 seconds")
    func wpmAt5Seconds() {
        // 1 word in 5 seconds = 12 WPM
        let result = ViewHelpers.liveWordsPerMinute(transcription: "hello", durationSeconds: 5)
        #expect(result == 12)
    }

    @Test("liveWordsPerMinute: minimum 1 WPM")
    func wpmMinimum() {
        // 1 word in 3600 seconds = 0.0167 → rounds to 0 → max(1, 0) = 1
        let result = ViewHelpers.liveWordsPerMinute(transcription: "hello", durationSeconds: 3600)
        #expect(result == 1)
    }

    @Test("liveWordsPerMinute: 60 words in 60 seconds = 60 WPM")
    func wpm60() {
        let words = (0..<60).map { "word\($0)" }.joined(separator: " ")
        let result = ViewHelpers.liveWordsPerMinute(transcription: words, durationSeconds: 60)
        #expect(result == 60)
    }

    // MARK: - recordingDuration

    @Test("recordingDuration: nil startedAt returns 0")
    func recordingDurationNilStart() {
        #expect(ViewHelpers.recordingDuration(startedAt: nil, now: Date()) == 0)
    }

    @Test("recordingDuration: negative interval clamped to 0")
    func recordingDurationNegative() {
        let now = Date()
        let future = now.addingTimeInterval(10)
        #expect(ViewHelpers.recordingDuration(startedAt: future, now: now) == 0)
    }

    @Test("recordingDuration: positive interval")
    func recordingDurationPositive() {
        let now = Date()
        let past = now.addingTimeInterval(-42)
        let result = ViewHelpers.recordingDuration(startedAt: past, now: now)
        #expect(abs(result - 42) < 0.01)
    }

    // MARK: - shouldCopyBecauseTargetUnknown

    @Test("shouldCopyBecauseTargetUnknown: false when canInsertDirectly is false")
    func copyUnknownNotDirect() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: false,
            hasResolvableInsertTarget: false,
            hasExternalFrontApp: false
        ) == false)
    }

    @Test("shouldCopyBecauseTargetUnknown: false when has resolvable target")
    func copyUnknownHasTarget() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true,
            hasResolvableInsertTarget: true,
            hasExternalFrontApp: false
        ) == false)
    }

    @Test("shouldCopyBecauseTargetUnknown: false when has external front app")
    func copyUnknownHasFrontApp() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true,
            hasResolvableInsertTarget: false,
            hasExternalFrontApp: true
        ) == false)
    }

    @Test("shouldCopyBecauseTargetUnknown: true when no target and no front app")
    func copyUnknownTrue() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true,
            hasResolvableInsertTarget: false,
            hasExternalFrontApp: false
        ) == true)
    }

    // MARK: - refreshFinalizationProgressBaseline

    @Test("refreshFinalizationProgressBaseline: nil when recording")
    func baselineRecording() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: true, pendingChunks: 5, currentBaseline: nil
        ) == nil)
    }

    @Test("refreshFinalizationProgressBaseline: nil when no pending chunks")
    func baselineNoPending() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: false, pendingChunks: 0, currentBaseline: nil
        ) == nil)
    }

    @Test("refreshFinalizationProgressBaseline: sets baseline when nil")
    func baselineSetsNew() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: false, pendingChunks: 3, currentBaseline: nil
        ) == 3)
    }

    @Test("refreshFinalizationProgressBaseline: keeps max of current and new")
    func baselineKeepsMax() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: false, pendingChunks: 2, currentBaseline: 5
        ) == 5)
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: false, pendingChunks: 8, currentBaseline: 5
        ) == 8)
    }

    // MARK: - finalizationProgress

    @Test("finalizationProgress: nil when no baseline")
    func finalizationProgressNilBaseline() {
        #expect(ViewHelpers.finalizationProgress(
            pendingChunkCount: 3, initialPendingChunks: nil, isRecording: false
        ) == nil)
    }

    @Test("finalizationProgress: nil when initial is 0")
    func finalizationProgressZeroInitial() {
        #expect(ViewHelpers.finalizationProgress(
            pendingChunkCount: 0, initialPendingChunks: 0, isRecording: false
        ) == nil)
    }

    @Test("finalizationProgress: 0.0 when all pending remain")
    func finalizationProgressAllPending() {
        let result = ViewHelpers.finalizationProgress(
            pendingChunkCount: 10, initialPendingChunks: 10, isRecording: false
        )
        #expect(result == 0.0)
    }

    @Test("finalizationProgress: nil when no pending chunks (completed)")
    func finalizationProgressComplete() {
        let result = ViewHelpers.finalizationProgress(
            pendingChunkCount: 0, initialPendingChunks: 10, isRecording: false
        )
        #expect(result == nil)
    }

    @Test("finalizationProgress: 0.5 when half done")
    func finalizationProgressHalf() {
        let result = ViewHelpers.finalizationProgress(
            pendingChunkCount: 5, initialPendingChunks: 10, isRecording: false
        )
        #expect(result == 0.5)
    }

    // MARK: - estimatedFinalizationSeconds

    @Test("estimatedFinalizationSeconds: nil when no pending")
    func estFinNoPending() {
        #expect(ViewHelpers.estimatedFinalizationSeconds(
            pendingChunkCount: 0, averageChunkLatency: 1.0, lastChunkLatency: 1.0
        ) == nil)
    }

    @Test("estimatedFinalizationSeconds: nil when both latencies are 0")
    func estFinZeroLatency() {
        #expect(ViewHelpers.estimatedFinalizationSeconds(
            pendingChunkCount: 3, averageChunkLatency: 0, lastChunkLatency: 0
        ) == nil)
    }

    @Test("estimatedFinalizationSeconds: uses average when positive")
    func estFinUsesAverage() {
        let result = ViewHelpers.estimatedFinalizationSeconds(
            pendingChunkCount: 4, averageChunkLatency: 2.0, lastChunkLatency: 5.0
        )
        #expect(result == 8.0)
    }

    @Test("estimatedFinalizationSeconds: falls back to last when average is 0")
    func estFinFallsBackToLast() {
        let result = ViewHelpers.estimatedFinalizationSeconds(
            pendingChunkCount: 3, averageChunkLatency: 0, lastChunkLatency: 4.0
        )
        #expect(result == 12.0)
    }

    // MARK: - insertTargetAgeDescription

    @Test("insertTargetAgeDescription: nil when capturedAt is nil")
    func ageDescNil() {
        #expect(ViewHelpers.insertTargetAgeDescription(
            capturedAt: nil, now: Date(), staleAfterSeconds: 90, isStale: false
        ) == nil)
    }

    @Test("insertTargetAgeDescription: just now when under 1 second")
    func ageDescJustNow() {
        let now = Date()
        let result = ViewHelpers.insertTargetAgeDescription(
            capturedAt: now, now: now, staleAfterSeconds: 90, isStale: false
        )
        #expect(result?.contains("just now") == true)
    }

    @Test("insertTargetAgeDescription: stale suffix when isStale")
    func ageDescStale() {
        let now = Date()
        let result = ViewHelpers.insertTargetAgeDescription(
            capturedAt: now.addingTimeInterval(-100), now: now, staleAfterSeconds: 90, isStale: true
        )
        #expect(result?.contains("stale") == true)
        #expect(result?.contains("stale in") == false)
    }

    @Test("insertTargetAgeDescription: stale in ~Xs when close to stale threshold")
    func ageDescStaleIn() {
        let now = Date()
        let result = ViewHelpers.insertTargetAgeDescription(
            capturedAt: now.addingTimeInterval(-85), now: now, staleAfterSeconds: 90, isStale: false
        )
        #expect(result?.contains("stale in") == true)
    }

    @Test("insertTargetAgeDescription: no stale notice when far from threshold")
    func ageDescFresh() {
        let now = Date()
        let result = ViewHelpers.insertTargetAgeDescription(
            capturedAt: now.addingTimeInterval(-10), now: now, staleAfterSeconds: 90, isStale: false
        )
        #expect(result?.contains("stale") == false)
        #expect(result?.contains("ago") == true)
    }

    // MARK: - lastSuccessfulInsertDescription

    @Test("lastSuccessfulInsertDescription: nil when insertedAt is nil")
    func lastInsertNil() {
        #expect(ViewHelpers.lastSuccessfulInsertDescription(insertedAt: nil, now: Date()) == nil)
    }

    @Test("lastSuccessfulInsertDescription: just now when under 1 second")
    func lastInsertJustNow() {
        let now = Date()
        let result = ViewHelpers.lastSuccessfulInsertDescription(insertedAt: now, now: now)
        #expect(result?.contains("just now") == true)
    }

    @Test("lastSuccessfulInsertDescription: includes ago for older")
    func lastInsertAgo() {
        let now = Date()
        let result = ViewHelpers.lastSuccessfulInsertDescription(
            insertedAt: now.addingTimeInterval(-30), now: now
        )
        #expect(result?.contains("ago") == true)
    }

    // MARK: - isInsertTargetStale

    @Test("isInsertTargetStale: false when capturedAt is nil")
    func staleNilCaptured() {
        #expect(ViewHelpers.isInsertTargetStale(capturedAt: nil, now: Date(), staleAfterSeconds: 90) == false)
    }

    @Test("isInsertTargetStale: false when within threshold")
    func staleWithinThreshold() {
        let now = Date()
        #expect(ViewHelpers.isInsertTargetStale(
            capturedAt: now.addingTimeInterval(-89), now: now, staleAfterSeconds: 90
        ) == false)
    }

    @Test("isInsertTargetStale: true at exactly threshold")
    func staleAtThreshold() {
        let now = Date()
        #expect(ViewHelpers.isInsertTargetStale(
            capturedAt: now.addingTimeInterval(-90), now: now, staleAfterSeconds: 90
        ) == true)
    }

    @Test("isInsertTargetStale: true beyond threshold")
    func staleBeyondThreshold() {
        let now = Date()
        #expect(ViewHelpers.isInsertTargetStale(
            capturedAt: now.addingTimeInterval(-200), now: now, staleAfterSeconds: 90
        ) == true)
    }

    // MARK: - activeInsertTargetStaleAfterSeconds

    @Test("activeInsertTargetStaleAfterSeconds: normal timeout")
    func staleTimeoutNormal() {
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: false) == 90)
    }

    @Test("activeInsertTargetStaleAfterSeconds: fallback timeout")
    func staleTimeoutFallback() {
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: true) == 30)
    }

    @Test("activeInsertTargetStaleAfterSeconds: custom values")
    func staleTimeoutCustom() {
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(
            usesFallback: false, normalTimeout: 120, fallbackTimeout: 15
        ) == 120)
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(
            usesFallback: true, normalTimeout: 120, fallbackTimeout: 15
        ) == 15)
    }

    // MARK: - isInsertTargetLocked

    @Test("isInsertTargetLocked: all true")
    func lockedAllTrue() {
        #expect(ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: true, canInsertNow: true,
            canInsertDirectly: true, hasResolvableInsertTarget: true
        ) == true)
    }

    @Test("isInsertTargetLocked: any false returns false")
    func lockedAnyFalse() {
        #expect(ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: false, canInsertNow: true,
            canInsertDirectly: true, hasResolvableInsertTarget: true
        ) == false)
        #expect(ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: true, canInsertNow: false,
            canInsertDirectly: true, hasResolvableInsertTarget: true
        ) == false)
        #expect(ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: true, canInsertNow: true,
            canInsertDirectly: false, hasResolvableInsertTarget: true
        ) == false)
        #expect(ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: true, canInsertNow: true,
            canInsertDirectly: true, hasResolvableInsertTarget: false
        ) == false)
    }

    // MARK: - shouldShowUseCurrentAppQuickAction

    @Test("shouldShowUseCurrentAppQuickAction: both false returns false")
    func useCurrentAppBothFalse() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(
            shouldSuggestRetarget: false, isInsertTargetStale: false
        ) == false)
    }

    @Test("shouldShowUseCurrentAppQuickAction: either true returns true")
    func useCurrentAppEitherTrue() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(
            shouldSuggestRetarget: true, isInsertTargetStale: false
        ) == true)
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(
            shouldSuggestRetarget: false, isInsertTargetStale: true
        ) == true)
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(
            shouldSuggestRetarget: true, isInsertTargetStale: true
        ) == true)
    }

    // MARK: - currentExternalFrontBundleIdentifier

    @Test("currentExternalFrontBundleIdentifier: empty returns nil")
    func frontBundleEmpty() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("", ownBundleIdentifier: nil) == nil)
    }

    @Test("currentExternalFrontBundleIdentifier: whitespace returns nil")
    func frontBundleWhitespace() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("  \n  ", ownBundleIdentifier: nil) == nil)
    }

    @Test("currentExternalFrontBundleIdentifier: own bundle returns nil")
    func frontBundleOwnApp() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier(
            "com.openwhisper.app", ownBundleIdentifier: "com.openwhisper.app"
        ) == nil)
    }

    @Test("currentExternalFrontBundleIdentifier: own bundle case insensitive")
    func frontBundleOwnCaseInsensitive() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier(
            "COM.OPENWHISPER.APP", ownBundleIdentifier: "com.openwhisper.app"
        ) == nil)
    }

    @Test("currentExternalFrontBundleIdentifier: different bundle returns it")
    func frontBundleDifferent() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier(
            "com.apple.Safari", ownBundleIdentifier: "com.openwhisper.app"
        ) == "com.apple.Safari")
    }

    @Test("currentExternalFrontBundleIdentifier: nil own bundle accepts anything")
    func frontBundleNilOwn() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier(
            "com.apple.Safari", ownBundleIdentifier: nil
        ) == "com.apple.Safari")
    }

    // MARK: - currentExternalFrontAppName

    @Test("currentExternalFrontAppName: empty returns nil")
    func frontNameEmpty() {
        #expect(ViewHelpers.currentExternalFrontAppName("") == nil)
    }

    @Test("currentExternalFrontAppName: Unknown App returns nil")
    func frontNameUnknown() {
        #expect(ViewHelpers.currentExternalFrontAppName("Unknown App") == nil)
        #expect(ViewHelpers.currentExternalFrontAppName("unknown app") == nil)
        #expect(ViewHelpers.currentExternalFrontAppName("UNKNOWN APP") == nil)
    }

    @Test("currentExternalFrontAppName: OpenWhisper returns nil")
    func frontNameSelf() {
        #expect(ViewHelpers.currentExternalFrontAppName("OpenWhisper") == nil)
        #expect(ViewHelpers.currentExternalFrontAppName("openwhisper") == nil)
    }

    @Test("currentExternalFrontAppName: valid name passes through")
    func frontNameValid() {
        #expect(ViewHelpers.currentExternalFrontAppName("Safari") == "Safari")
        #expect(ViewHelpers.currentExternalFrontAppName("Xcode") == "Xcode")
    }

    // MARK: - canToggleRecording

    @Test("canToggleRecording: true when recording")
    func toggleRecordingWhileRecording() {
        #expect(ViewHelpers.canToggleRecording(
            isRecording: true, pendingChunkCount: 0, microphoneAuthorized: false
        ) == true)
    }

    @Test("canToggleRecording: true when pending chunks")
    func toggleRecordingPending() {
        #expect(ViewHelpers.canToggleRecording(
            isRecording: false, pendingChunkCount: 1, microphoneAuthorized: false
        ) == true)
    }

    @Test("canToggleRecording: requires mic when idle")
    func toggleRecordingIdle() {
        #expect(ViewHelpers.canToggleRecording(
            isRecording: false, pendingChunkCount: 0, microphoneAuthorized: false
        ) == false)
        #expect(ViewHelpers.canToggleRecording(
            isRecording: false, pendingChunkCount: 0, microphoneAuthorized: true
        ) == true)
    }

    // MARK: - isInsertionFlashVisible

    @Test("isInsertionFlashVisible: false when insertedAt is nil")
    func flashNil() {
        #expect(ViewHelpers.isInsertionFlashVisible(insertedAt: nil, now: Date()) == false)
    }

    @Test("isInsertionFlashVisible: true within flash duration")
    func flashVisible() {
        let now = Date()
        #expect(ViewHelpers.isInsertionFlashVisible(
            insertedAt: now.addingTimeInterval(-1), now: now, flashDuration: 3
        ) == true)
    }

    @Test("isInsertionFlashVisible: false at exactly flash duration")
    func flashAtBoundary() {
        let now = Date()
        #expect(ViewHelpers.isInsertionFlashVisible(
            insertedAt: now.addingTimeInterval(-3), now: now, flashDuration: 3
        ) == false)
    }

    @Test("isInsertionFlashVisible: false beyond flash duration")
    func flashExpired() {
        let now = Date()
        #expect(ViewHelpers.isInsertionFlashVisible(
            insertedAt: now.addingTimeInterval(-10), now: now, flashDuration: 3
        ) == false)
    }

    // MARK: - hotkeyCaptureProgress

    @Test("hotkeyCaptureProgress: 0 when totalSeconds is 0")
    func captureProgressZeroTotal() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 0) == 0)
    }

    @Test("hotkeyCaptureProgress: clamped to 0-1 range")
    func captureProgressClamped() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: -1, totalSeconds: 10) == 0)
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 15, totalSeconds: 10) == 1)
    }

    @Test("hotkeyCaptureProgress: correct fraction")
    func captureProgressFraction() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 10) == 0.5)
    }

    // MARK: - hotkeyMissingPermissionSummary

    @Test("hotkeyMissingPermissionSummary: nil when all granted")
    func missingPermNone() {
        #expect(ViewHelpers.hotkeyMissingPermissionSummary(
            accessibilityAuthorized: true, inputMonitoringAuthorized: true
        ) == nil)
    }

    @Test("hotkeyMissingPermissionSummary: one missing")
    func missingPermOne() {
        #expect(ViewHelpers.hotkeyMissingPermissionSummary(
            accessibilityAuthorized: false, inputMonitoringAuthorized: true
        ) == "Accessibility")
        #expect(ViewHelpers.hotkeyMissingPermissionSummary(
            accessibilityAuthorized: true, inputMonitoringAuthorized: false
        ) == "Input Monitoring")
    }

    @Test("hotkeyMissingPermissionSummary: both missing")
    func missingPermBoth() {
        #expect(ViewHelpers.hotkeyMissingPermissionSummary(
            accessibilityAuthorized: false, inputMonitoringAuthorized: false
        ) == "Accessibility + Input Monitoring")
    }

    // MARK: - sanitizeKeyValue

    @Test("sanitizeKeyValue: empty string becomes space")
    func sanitizeEmpty() {
        #expect(ViewHelpers.sanitizeKeyValue("") == "space")
    }

    @Test("sanitizeKeyValue: literal space becomes space")
    func sanitizeSpace() {
        #expect(ViewHelpers.sanitizeKeyValue(" ") == "space")
    }

    @Test("sanitizeKeyValue: trims and lowercases")
    func sanitizeTrimsAndLowercases() {
        let result = ViewHelpers.sanitizeKeyValue("  F6  ")
        #expect(result == "f6")
    }

    // MARK: - isHighRiskHotkey

    @Test("isHighRiskHotkey: false with modifiers")
    func highRiskWithModifiers() {
        #expect(ViewHelpers.isHighRiskHotkey(
            requiredModifiers: [.command], key: "space"
        ) == false)
    }

    @Test("isHighRiskHotkey: true for single char with no modifiers")
    func highRiskSingleChar() {
        #expect(ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "a") == true)
    }

    @Test("isHighRiskHotkey: true for space with no modifiers")
    func highRiskSpace() {
        #expect(ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "space") == true)
    }

    @Test("isHighRiskHotkey: false for f-key with no modifiers")
    func highRiskFKey() {
        #expect(ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "f6") == false)
    }

    // MARK: - shouldAutoApplySafeCaptureModifiers

    @Test("shouldAutoApplySafeCaptureModifiers: true for single char")
    func safeCaptureChar() {
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "a") == true)
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "/") == true)
    }

    @Test("shouldAutoApplySafeCaptureModifiers: false for function keys")
    func safeCaptureFKeys() {
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "f1") == false)
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "f24") == false)
    }

    @Test("shouldAutoApplySafeCaptureModifiers: false for navigation keys")
    func safeCaptureNav() {
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "escape") == false)
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "space") == false)
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "return") == false)
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "left") == false)
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "delete") == false)
    }

    @Test("shouldAutoApplySafeCaptureModifiers: false for globe/fn")
    func safeCaptureGlobe() {
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "fn") == false)
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "globe") == false)
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "capslock") == false)
    }

    // MARK: - abbreviatedAppName

    @Test("abbreviatedAppName: short name passes through")
    func abbrevShort() {
        #expect(ViewHelpers.abbreviatedAppName("Safari") == "Safari")
    }

    @Test("abbreviatedAppName: long name truncated with ellipsis")
    func abbrevLong() {
        let result = ViewHelpers.abbreviatedAppName("A Very Long Application Name That Exceeds The Limit")
        #expect(result.count <= 21) // 18 + "..."
        #expect(result.hasSuffix("…") || result.count <= 18)
    }

    @Test("abbreviatedAppName: custom max characters")
    func abbrevCustomMax() {
        let result = ViewHelpers.abbreviatedAppName("Hello World", maxCharacters: 5)
        #expect(result.count <= 8) // 5 + "..."
    }

    // MARK: - insertionProbeStatus

    @Test("insertionProbeStatus: maps correctly")
    func probeStatus() {
        #expect(ViewHelpers.insertionProbeStatus(succeeded: true) == .success)
        #expect(ViewHelpers.insertionProbeStatus(succeeded: false) == .failure)
        #expect(ViewHelpers.insertionProbeStatus(succeeded: nil) == .unknown)
    }

    // MARK: - hasResolvableInsertTarget

    @Test("hasResolvableInsertTarget: false for nil")
    func resolvableNil() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: nil) == false)
    }

    @Test("hasResolvableInsertTarget: false for empty string")
    func resolvableEmpty() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "") == false)
    }

    @Test("hasResolvableInsertTarget: true for valid name")
    func resolvableValid() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "Safari") == true)
    }

    // MARK: - canRetargetInsertTarget

    @Test("canRetargetInsertTarget: false when recording")
    func retargetRecording() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: true, pendingChunkCount: 0) == false)
    }

    @Test("canRetargetInsertTarget: false when pending")
    func retargetPending() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: false, pendingChunkCount: 1) == false)
    }

    @Test("canRetargetInsertTarget: true when idle")
    func retargetIdle() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: false, pendingChunkCount: 0) == true)
    }

    // MARK: - menuBarIconName

    @Test("menuBarIconName: insertion flash takes priority")
    func iconFlash() {
        #expect(ViewHelpers.menuBarIconName(
            isRecording: true, pendingChunkCount: 5,
            hasTranscriptionText: true, isShowingInsertionFlash: true
        ) == "checkmark.circle.fill")
    }

    @Test("menuBarIconName: recording")
    func iconRecording() {
        #expect(ViewHelpers.menuBarIconName(
            isRecording: true, pendingChunkCount: 0,
            hasTranscriptionText: false, isShowingInsertionFlash: false
        ) == "waveform.circle.fill")
    }

    @Test("menuBarIconName: pending chunks")
    func iconPending() {
        #expect(ViewHelpers.menuBarIconName(
            isRecording: false, pendingChunkCount: 2,
            hasTranscriptionText: false, isShowingInsertionFlash: false
        ) == "ellipsis.circle")
    }

    @Test("menuBarIconName: has transcription")
    func iconTranscription() {
        #expect(ViewHelpers.menuBarIconName(
            isRecording: false, pendingChunkCount: 0,
            hasTranscriptionText: true, isShowingInsertionFlash: false
        ) == "doc.text")
    }

    @Test("menuBarIconName: idle default")
    func iconIdle() {
        #expect(ViewHelpers.menuBarIconName(
            isRecording: false, pendingChunkCount: 0,
            hasTranscriptionText: false, isShowingInsertionFlash: false
        ) == "mic")
    }

    // MARK: - menuBarDurationLabel

    @Test("menuBarDurationLabel: insertion flash returns Inserted")
    func durationLabelFlash() {
        #expect(ViewHelpers.menuBarDurationLabel(
            isRecording: false, pendingChunkCount: 0,
            recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0, lastChunkLatency: 0,
            transcriptionWordCount: 0, isShowingInsertionFlash: true
        ) == "Inserted")
    }

    @Test("menuBarDurationLabel: recording shows time")
    func durationLabelRecording() {
        let result = ViewHelpers.menuBarDurationLabel(
            isRecording: true, pendingChunkCount: 0,
            recordingElapsedSeconds: 65, isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0, lastChunkLatency: 0,
            transcriptionWordCount: 0, isShowingInsertionFlash: false
        )
        #expect(result == "1:05")
    }

    @Test("menuBarDurationLabel: pending with latency shows estimate")
    func durationLabelPendingWithLatency() {
        let result = ViewHelpers.menuBarDurationLabel(
            isRecording: false, pendingChunkCount: 3,
            recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: false,
            averageChunkLatency: 2.0, lastChunkLatency: 0,
            transcriptionWordCount: 0, isShowingInsertionFlash: false
        )
        #expect(result?.contains("⏳") == true)
        #expect(result?.contains("6s") == true)
    }

    @Test("menuBarDurationLabel: pending without latency shows count")
    func durationLabelPendingNoLatency() {
        let result = ViewHelpers.menuBarDurationLabel(
            isRecording: false, pendingChunkCount: 4,
            recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0, lastChunkLatency: 0,
            transcriptionWordCount: 0, isShowingInsertionFlash: false
        )
        #expect(result == "4 left")
    }

    @Test("menuBarDurationLabel: pending with queued start suffix")
    func durationLabelQueuedStart() {
        let result = ViewHelpers.menuBarDurationLabel(
            isRecording: false, pendingChunkCount: 2,
            recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: true,
            averageChunkLatency: 0, lastChunkLatency: 0,
            transcriptionWordCount: 0, isShowingInsertionFlash: false
        )
        #expect(result?.contains("→●") == true)
    }

    @Test("menuBarDurationLabel: word count when idle with text")
    func durationLabelWordCount() {
        let result = ViewHelpers.menuBarDurationLabel(
            isRecording: false, pendingChunkCount: 0,
            recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0, lastChunkLatency: 0,
            transcriptionWordCount: 42, isShowingInsertionFlash: false
        )
        #expect(result == "42w")
    }

    @Test("menuBarDurationLabel: nil when fully idle")
    func durationLabelIdle() {
        #expect(ViewHelpers.menuBarDurationLabel(
            isRecording: false, pendingChunkCount: 0,
            recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0, lastChunkLatency: 0,
            transcriptionWordCount: 0, isShowingInsertionFlash: false
        ) == nil)
    }

    // MARK: - hotkeyModeTipText

    @Test("hotkeyModeTipText: toggle mode without escape")
    func modeTipToggle() {
        let result = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: false)
        #expect(result.contains("toggle"))
        #expect(result.contains("Esc"))
    }

    @Test("hotkeyModeTipText: toggle mode with escape trigger")
    func modeTipToggleEscape() {
        let result = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: true)
        #expect(result.contains("unavailable"))
    }

    @Test("hotkeyModeTipText: hold mode")
    func modeTipHold() {
        let result = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: false)
        #expect(result.contains("hold"))
    }

    // MARK: - showsHoldModeAccidentalTriggerWarning

    @Test("showsHoldModeAccidentalTriggerWarning: false for toggle mode")
    func holdWarningToggle() {
        #expect(ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: HotkeyMode.toggle.rawValue,
            requiredModifiers: [], key: "space"
        ) == false)
    }

    @Test("showsHoldModeAccidentalTriggerWarning: true for hold mode with high-risk key")
    func holdWarningHighRisk() {
        #expect(ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: HotkeyMode.hold.rawValue,
            requiredModifiers: [], key: "space"
        ) == true)
    }

    @Test("showsHoldModeAccidentalTriggerWarning: false for hold mode with modifiers")
    func holdWarningWithModifiers() {
        #expect(ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: HotkeyMode.hold.rawValue,
            requiredModifiers: [.command], key: "space"
        ) == false)
    }

    // MARK: - hotkeyEscapeCancelConflictWarning

    @Test("hotkeyEscapeCancelConflictWarning: nil for non-escape")
    func escWarningNonEscape() {
        #expect(ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "space") == nil)
    }

    @Test("hotkeyEscapeCancelConflictWarning: warning for escape")
    func escWarningEscape() {
        let result = ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "escape")
        #expect(result?.contains("Esc") == true)
    }

    // MARK: - showsAutoPastePermissionWarning

    @Test("showsAutoPastePermissionWarning: false when autoPaste off")
    func autoPasteOff() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(
            autoPaste: false, accessibilityAuthorized: false
        ) == false)
    }

    @Test("showsAutoPastePermissionWarning: false when authorized")
    func autoPasteAuthorized() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(
            autoPaste: true, accessibilityAuthorized: true
        ) == false)
    }

    @Test("showsAutoPastePermissionWarning: true when on and not authorized")
    func autoPasteWarning() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(
            autoPaste: true, accessibilityAuthorized: false
        ) == true)
    }

    // MARK: - insertionProbeSampleTextWillTruncate

    @Test("insertionProbeSampleTextWillTruncate: false for short text")
    func truncateShort() {
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate("hello") == false)
    }

    // MARK: - hasInsertionProbeSampleText

    @Test("hasInsertionProbeSampleText: false for empty/whitespace")
    func hasSampleEmpty() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("") == false)
        #expect(ViewHelpers.hasInsertionProbeSampleText("   ") == false)
    }

    @Test("hasInsertionProbeSampleText: true for non-empty")
    func hasSampleNonEmpty() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("hello") == true)
    }
}
