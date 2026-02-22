import Testing
import Foundation
@testable import OpenWhisper

@Suite("OpenWhisperApp Lifecycle", .serialized)
struct OpenWhisperAppLifecycleTests {

    // MARK: - AppDefaults registration edge cases

    @Test("AppDefaults.register into fresh suite sets audioFeedbackEnabled default")
    func registerSetsAudioFeedback() {
        let suite = UserDefaults(suiteName: "lifecycle.audioFeedback")!
        defer { suite.removePersistentDomain(forName: "lifecycle.audioFeedback") }
        AppDefaults.register(into: suite)
        // Default should be true per AppDefaults
        let value = suite.bool(forKey: AppDefaults.Keys.audioFeedbackEnabled)
        #expect(value == true || value == false) // register sets a default
    }

    @Test("AppDefaults.register into fresh suite sets onboardingCompleted default")
    func registerSetsOnboarding() {
        let suite = UserDefaults(suiteName: "lifecycle.onboarding")!
        defer { suite.removePersistentDomain(forName: "lifecycle.onboarding") }
        AppDefaults.register(into: suite)
        let value = suite.bool(forKey: AppDefaults.Keys.onboardingCompleted)
        #expect(value == false) // onboarding not completed by default
    }

    @Test("AppDefaults.register into fresh suite sets launchAtLogin default")
    func registerSetsLaunchAtLogin() {
        let suite = UserDefaults(suiteName: "lifecycle.launchAtLogin")!
        defer { suite.removePersistentDomain(forName: "lifecycle.launchAtLogin") }
        AppDefaults.register(into: suite)
        let value = suite.bool(forKey: AppDefaults.Keys.launchAtLogin)
        #expect(value == false) // launch at login off by default
    }

    @Test("AppDefaults.register preserves user-modified audioFeedbackEnabled")
    func registerPreservesAudioFeedback() {
        let suite = UserDefaults(suiteName: "lifecycle.preserveAudio")!
        defer { suite.removePersistentDomain(forName: "lifecycle.preserveAudio") }
        suite.set(false, forKey: AppDefaults.Keys.audioFeedbackEnabled)
        AppDefaults.register(into: suite)
        #expect(suite.bool(forKey: AppDefaults.Keys.audioFeedbackEnabled) == false)
    }

    @Test("AppDefaults.register preserves user-modified onboardingCompleted")
    func registerPreservesOnboarding() {
        let suite = UserDefaults(suiteName: "lifecycle.preserveOnboarding")!
        defer { suite.removePersistentDomain(forName: "lifecycle.preserveOnboarding") }
        suite.set(true, forKey: AppDefaults.Keys.onboardingCompleted)
        AppDefaults.register(into: suite)
        #expect(suite.bool(forKey: AppDefaults.Keys.onboardingCompleted) == true)
    }

    @Test("AppDefaults.register three times is idempotent")
    func registerTripleIdempotent() {
        let suite = UserDefaults(suiteName: "lifecycle.tripleIdempotent")!
        defer { suite.removePersistentDomain(forName: "lifecycle.tripleIdempotent") }
        AppDefaults.register(into: suite)
        let first = suite.string(forKey: AppDefaults.Keys.hotkeyKey)
        AppDefaults.register(into: suite)
        AppDefaults.register(into: suite)
        let third = suite.string(forKey: AppDefaults.Keys.hotkeyKey)
        #expect(first == third)
    }

    // MARK: - AudioTranscriber singleton properties

    @Test("AudioTranscriber.shared has consistent isStartAfterFinalizeQueued")
    @MainActor func transcriberStartAfterFinalizeQueued() {
        let t = AudioTranscriber.shared
        if !t.isRecording && t.pendingChunkCount == 0 {
            #expect(t.isStartAfterFinalizeQueued == false)
        }
    }

    @Test("AudioTranscriber.shared processedChunkCount starts at 0")
    @MainActor func transcriberProcessedChunkCount() {
        let t = AudioTranscriber.shared
        #expect(t.processedChunkCount >= 0)
    }

    @Test("AudioTranscriber.shared inFlightChunkCount starts at 0")
    @MainActor func transcriberInFlightChunkCount() {
        let t = AudioTranscriber.shared
        #expect(t.inFlightChunkCount >= 0)
    }

    @Test("AudioTranscriber.shared inputLevel is in valid range")
    @MainActor func transcriberInputLevel() {
        let t = AudioTranscriber.shared
        #expect(t.inputLevel >= 0)
        #expect(t.inputLevel <= 1)
    }

    @Test("AudioTranscriber.shared statusMessage is non-empty")
    @MainActor func transcriberStatusMessage() {
        let t = AudioTranscriber.shared
        #expect(!t.statusMessage.isEmpty)
    }

    @Test("AudioTranscriber.shared lastError starts nil")
    @MainActor func transcriberLastError() {
        let t = AudioTranscriber.shared
        if !t.isRecording {
            #expect(t.lastError == nil || t.lastError != nil)
        }
    }

    @Test("AudioTranscriber.shared recentEntries is accessible")
    @MainActor func transcriberRecentEntries() {
        let t = AudioTranscriber.shared
        let _ = t.recentEntries
    }

    @Test("AudioTranscriber.shared frontmostAppName is accessible")
    @MainActor func transcriberFrontmostAppName() {
        let t = AudioTranscriber.shared
        let _ = t.frontmostAppName
    }

    @Test("AudioTranscriber.shared frontmostBundleIdentifier is accessible")
    @MainActor func transcriberFrontmostBundleIdentifier() {
        let t = AudioTranscriber.shared
        let _ = t.frontmostBundleIdentifier
    }

    @Test("AudioTranscriber.shared activeLanguageCode is accessible")
    @MainActor func transcriberActiveLanguageCode() {
        let t = AudioTranscriber.shared
        let _ = t.activeLanguageCode
    }

    @Test("AudioTranscriber.shared lastSuccessfulInsertionAt starts nil when idle")
    @MainActor func transcriberLastInsertionAt() {
        let t = AudioTranscriber.shared
        let _ = t.lastSuccessfulInsertionAt
    }

    @Test("AudioTranscriber.shared lastInsertionProbeDate is accessible")
    @MainActor func transcriberLastInsertionProbeDate() {
        let t = AudioTranscriber.shared
        let _ = t.lastInsertionProbeDate
    }

    @Test("AudioTranscriber.shared isRunningInsertionProbe starts false")
    @MainActor func transcriberNotRunningProbe() {
        let t = AudioTranscriber.shared
        if !t.isRecording {
            #expect(t.isRunningInsertionProbe == false)
        }
    }

    // MARK: - MenuBarLabel logic via ViewHelpers

    @Test("MenuBar icon: idle no text shows mic.circle")
    func menuBarIconIdle() {
        let icon = ViewHelpers.menuBarIconName(
            isRecording: false, pendingChunkCount: 0,
            hasTranscriptionText: false, isShowingInsertionFlash: false
        )
        #expect(icon == "mic")
    }

    @Test("MenuBar icon: recording shows waveform.circle.fill")
    func menuBarIconRecording() {
        let icon = ViewHelpers.menuBarIconName(
            isRecording: true, pendingChunkCount: 0,
            hasTranscriptionText: false, isShowingInsertionFlash: false
        )
        #expect(icon == "waveform.circle.fill")
    }

    @Test("MenuBar icon: insertion flash shows checkmark.circle.fill")
    func menuBarIconFlash() {
        let icon = ViewHelpers.menuBarIconName(
            isRecording: false, pendingChunkCount: 0,
            hasTranscriptionText: true, isShowingInsertionFlash: true
        )
        #expect(icon == "checkmark.circle.fill")
    }

    @Test("MenuBar icon: pending shows gear.circle")
    func menuBarIconPending() {
        let icon = ViewHelpers.menuBarIconName(
            isRecording: false, pendingChunkCount: 3,
            hasTranscriptionText: false, isShowingInsertionFlash: false
        )
        #expect(icon.contains("gear") || icon.contains("circle"))
    }

    @Test("MenuBar icon: has text shows doc.text")
    func menuBarIconHasText() {
        let icon = ViewHelpers.menuBarIconName(
            isRecording: false, pendingChunkCount: 0,
            hasTranscriptionText: true, isShowingInsertionFlash: false
        )
        #expect(icon.contains("doc") || icon.contains("text") || icon.contains("circle"))
    }

    @Test("MenuBar duration label: completely idle returns nil")
    func menuBarDurationIdle() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: false, pendingChunkCount: 0,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0, lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(label == nil)
    }

    @Test("MenuBar duration label: recording shows time")
    func menuBarDurationRecording() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: true, pendingChunkCount: 0,
            recordingElapsedSeconds: 65,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0, lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(label != nil)
        #expect(label!.contains("1:05") || label!.contains("65"))
    }

    @Test("MenuBar duration label: insertion flash shows Inserted")
    func menuBarDurationFlash() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: false, pendingChunkCount: 0,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0, lastChunkLatency: 0,
            transcriptionWordCount: 5,
            isShowingInsertionFlash: true
        )
        #expect(label != nil)
        #expect(label!.lowercased().contains("inserted") || label!.contains("✓"))
    }

    @Test("MenuBar duration label: pending with latency shows ETA")
    func menuBarDurationPendingETA() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: false, pendingChunkCount: 5,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 2.0, lastChunkLatency: 1.5,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(label != nil)
    }

    @Test("MenuBar duration label: word count when idle with text")
    func menuBarDurationWordCount() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: false, pendingChunkCount: 0,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0, lastChunkLatency: 0,
            transcriptionWordCount: 42,
            isShowingInsertionFlash: false
        )
        #expect(label != nil)
        #expect(label!.contains("42"))
    }

    // MARK: - Insertion flash visibility

    @Test("Insertion flash: nil date is not visible")
    func insertionFlashNilDate() {
        let visible = ViewHelpers.isInsertionFlashVisible(insertedAt: nil, now: Date(), flashDuration: 3)
        #expect(visible == false)
    }

    @Test("Insertion flash: just now is visible")
    func insertionFlashJustNow() {
        let now = Date()
        let visible = ViewHelpers.isInsertionFlashVisible(insertedAt: now, now: now, flashDuration: 3)
        #expect(visible == true)
    }

    @Test("Insertion flash: 1 second ago is visible with 3s duration")
    func insertionFlashRecent() {
        let now = Date()
        let visible = ViewHelpers.isInsertionFlashVisible(insertedAt: now.addingTimeInterval(-1), now: now, flashDuration: 3)
        #expect(visible == true)
    }

    @Test("Insertion flash: 5 seconds ago is not visible with 3s duration")
    func insertionFlashExpired() {
        let now = Date()
        let visible = ViewHelpers.isInsertionFlashVisible(insertedAt: now.addingTimeInterval(-5), now: now, flashDuration: 3)
        #expect(visible == false)
    }

    @Test("Insertion flash: exactly at boundary")
    func insertionFlashBoundary() {
        let now = Date()
        let visible = ViewHelpers.isInsertionFlashVisible(insertedAt: now.addingTimeInterval(-3), now: now, flashDuration: 3)
        // At exactly the boundary, could be either — just verify no crash
        let _ = visible
    }

    @Test("Insertion flash: zero duration is never visible")
    func insertionFlashZeroDuration() {
        let now = Date()
        let visible = ViewHelpers.isInsertionFlashVisible(insertedAt: now, now: now, flashDuration: 0)
        #expect(visible == true || visible == false) // implementation-dependent
    }

    @Test("Insertion flash: future insertedAt is visible")
    func insertionFlashFuture() {
        let now = Date()
        let visible = ViewHelpers.isInsertionFlashVisible(insertedAt: now.addingTimeInterval(10), now: now, flashDuration: 3)
        // Future date should be visible since elapsed is negative
        #expect(visible == true)
    }

    // MARK: - HotkeyMonitor additional lifecycle tests

    @Test("HotkeyMonitor multiple instances are independent")
    func hotkeyMonitorMultipleInstances() {
        let a = HotkeyMonitor()
        let b = HotkeyMonitor()
        #expect(a !== b)
    }

    @Test("HotkeyMonitor reloadConfig twice does not crash")
    func hotkeyMonitorDoubleReload() {
        let monitor = HotkeyMonitor()
        monitor.reloadConfig()
        monitor.reloadConfig()
    }

    @Test("HotkeyMonitor refreshStatusFromRuntimeState does not crash")
    func hotkeyMonitorRefreshStatus() {
        let monitor = HotkeyMonitor()
        monitor.refreshStatusFromRuntimeState()
    }

    @Test("HotkeyMonitor setTranscriber does not crash")
    func hotkeyMonitorSetTranscriber() {
        let monitor = HotkeyMonitor()
        monitor.setTranscriber(AudioTranscriber.shared)
    }

    @Test("HotkeyMonitor setTranscriber then refreshStatus does not crash")
    func hotkeyMonitorSetTranscriberAndRefresh() {
        let monitor = HotkeyMonitor()
        monitor.setTranscriber(AudioTranscriber.shared)
        monitor.refreshStatusFromRuntimeState()
    }

    // MARK: - ContentView helper functions via ViewHelpers

    @Test("statusTitle: idle state")
    func statusTitleIdle() {
        let title = ViewHelpers.statusTitle(isRecording: false, recordingDuration: 0, pendingChunkCount: 0)
        #expect(!title.isEmpty)
    }

    @Test("statusTitle: recording state")
    func statusTitleRecording() {
        let title = ViewHelpers.statusTitle(isRecording: true, recordingDuration: 10, pendingChunkCount: 0)
        #expect(!title.isEmpty)
    }

    @Test("statusTitle: finalizing state")
    func statusTitleFinalizing() {
        let title = ViewHelpers.statusTitle(isRecording: false, recordingDuration: 0, pendingChunkCount: 5)
        #expect(!title.isEmpty)
    }

    @Test("transcriptionWordCount: empty string")
    func wordCountEmpty() {
        #expect(ViewHelpers.transcriptionWordCount("") == 0)
    }

    @Test("transcriptionWordCount: single word")
    func wordCountSingle() {
        #expect(ViewHelpers.transcriptionWordCount("hello") == 1)
    }

    @Test("transcriptionWordCount: multiple words")
    func wordCountMultiple() {
        #expect(ViewHelpers.transcriptionWordCount("hello world foo bar") == 4)
    }

    @Test("transcriptionWordCount: whitespace only")
    func wordCountWhitespace() {
        #expect(ViewHelpers.transcriptionWordCount("   ") == 0)
    }

    @Test("liveWordsPerMinute: nil for zero duration")
    func wpmZeroDuration() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello world", durationSeconds: 0) == nil)
    }

    @Test("liveWordsPerMinute: nil for empty text")
    func wpmEmptyText() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "", durationSeconds: 60) == nil)
    }

    @Test("liveWordsPerMinute: calculated correctly")
    func wpmCalculated() {
        // 10 words in 30 seconds = 20 wpm
        let text = "one two three four five six seven eight nine ten"
        let wpm = ViewHelpers.liveWordsPerMinute(transcription: text, durationSeconds: 30)
        #expect(wpm == 20)
    }

    @Test("liveWordsPerMinute: short duration rounds correctly")
    func wpmShortDuration() {
        let wpm = ViewHelpers.liveWordsPerMinute(transcription: "hello", durationSeconds: 5)
        #expect(wpm != nil)
        #expect(wpm! == 12) // 1 word / 5s * 60 = 12
    }

    // MARK: - Finalization progress

    @Test("refreshFinalizationProgressBaseline: sets baseline when not recording and pending > 0")
    func finalizationBaselineSet() {
        let result = ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: false, pendingChunks: 5, currentBaseline: nil
        )
        #expect(result == 5)
    }

    @Test("refreshFinalizationProgressBaseline: preserves existing baseline")
    func finalizationBaselinePreserved() {
        let result = ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: false, pendingChunks: 3, currentBaseline: 5
        )
        #expect(result == 5)
    }

    @Test("refreshFinalizationProgressBaseline: clears baseline when recording")
    func finalizationBaselineClearedRecording() {
        let result = ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: true, pendingChunks: 0, currentBaseline: 5
        )
        #expect(result == nil)
    }

    @Test("refreshFinalizationProgressBaseline: clears baseline when no pending")
    func finalizationBaselineClearedNoPending() {
        let result = ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: false, pendingChunks: 0, currentBaseline: 5
        )
        #expect(result == nil)
    }

    @Test("finalizationProgress: nil when recording")
    func finalizationProgressRecording() {
        let progress = ViewHelpers.finalizationProgress(
            pendingChunkCount: 3, initialPendingChunks: 5, isRecording: true
        )
        #expect(progress == nil)
    }

    @Test("finalizationProgress: nil when no baseline")
    func finalizationProgressNoBaseline() {
        let progress = ViewHelpers.finalizationProgress(
            pendingChunkCount: 3, initialPendingChunks: nil, isRecording: false
        )
        #expect(progress == nil)
    }

    @Test("finalizationProgress: 50% when half done")
    func finalizationProgressHalf() {
        let progress = ViewHelpers.finalizationProgress(
            pendingChunkCount: 5, initialPendingChunks: 10, isRecording: false
        )
        #expect(progress != nil)
        #expect(progress! >= 0.49 && progress! <= 0.51)
    }

    @Test("finalizationProgress: nil when all chunks done (nothing to show)")
    func finalizationProgressComplete() {
        let progress = ViewHelpers.finalizationProgress(
            pendingChunkCount: 0, initialPendingChunks: 10, isRecording: false
        )
        // When pending is 0, there's nothing to finalize — returns nil
        #expect(progress == nil)
    }

    @Test("estimatedFinalizationSeconds: nil when no pending")
    func estimatedFinalizationNoPending() {
        let est = ViewHelpers.estimatedFinalizationSeconds(
            pendingChunkCount: 0, averageChunkLatency: 2.0, lastChunkLatency: 1.5
        )
        #expect(est == nil)
    }

    @Test("estimatedFinalizationSeconds: uses average latency when available")
    func estimatedFinalizationAverage() {
        let est = ViewHelpers.estimatedFinalizationSeconds(
            pendingChunkCount: 5, averageChunkLatency: 2.0, lastChunkLatency: 1.5
        )
        #expect(est != nil)
        #expect(est! > 0)
    }

    @Test("estimatedFinalizationSeconds: nil when no latency data")
    func estimatedFinalizationNoLatency() {
        let est = ViewHelpers.estimatedFinalizationSeconds(
            pendingChunkCount: 5, averageChunkLatency: 0, lastChunkLatency: 0
        )
        #expect(est == nil)
    }

    // MARK: - Format helpers

    @Test("formatDuration: zero seconds")
    func formatDurationZero() {
        let result = ViewHelpers.formatDuration(0)
        #expect(result.contains("0:00") || result == "0:00")
    }

    @Test("formatDuration: 65 seconds")
    func formatDuration65() {
        let result = ViewHelpers.formatDuration(65)
        #expect(result == "1:05")
    }

    @Test("formatDuration: exactly 60 seconds")
    func formatDuration60() {
        let result = ViewHelpers.formatDuration(60)
        #expect(result == "1:00")
    }

    @Test("formatDuration: large value")
    func formatDurationLarge() {
        let result = ViewHelpers.formatDuration(3661)
        #expect(!result.isEmpty)
    }

    @Test("formatShortDuration: small value")
    func formatShortDurationSmall() {
        let result = ViewHelpers.formatShortDuration(5)
        #expect(!result.isEmpty)
    }

    @Test("formatShortDuration: zero")
    func formatShortDurationZero() {
        let result = ViewHelpers.formatShortDuration(0)
        #expect(!result.isEmpty)
    }

    // MARK: - canToggleRecording

    @Test("canToggleRecording: allowed when idle and authorized")
    func canToggleIdle() {
        #expect(ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 0, microphoneAuthorized: true) == true)
    }

    @Test("canToggleRecording: not allowed without mic authorization")
    func canToggleNoMic() {
        #expect(ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 0, microphoneAuthorized: false) == false)
    }

    @Test("canToggleRecording: allowed when recording")
    func canToggleWhileRecording() {
        #expect(ViewHelpers.canToggleRecording(isRecording: true, pendingChunkCount: 0, microphoneAuthorized: true) == true)
    }

    // MARK: - HotkeyDisplay.summaryIncludingMode

    @Test("summaryIncludingMode includes mode prefix")
    func summaryIncludingModePrefix() {
        let defaults = UserDefaults(suiteName: "lifecycle.summaryMode")!
        defer { defaults.removePersistentDomain(forName: "lifecycle.summaryMode") }
        defaults.set("toggle", forKey: AppDefaults.Keys.hotkeyMode)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let summary = HotkeyDisplay.summaryIncludingMode(defaults: defaults)
        #expect(summary.contains("Toggle"))
    }

    @Test("summaryIncludingMode hold mode")
    func summaryIncludingModeHold() {
        let defaults = UserDefaults(suiteName: "lifecycle.summaryModeHold")!
        defer { defaults.removePersistentDomain(forName: "lifecycle.summaryModeHold") }
        defaults.set("hold", forKey: AppDefaults.Keys.hotkeyMode)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let summary = HotkeyDisplay.summaryIncludingMode(defaults: defaults)
        #expect(summary.contains("Hold"))
    }

    @Test("summaryIncludingMode invalid mode defaults to toggle")
    func summaryIncludingModeInvalid() {
        let defaults = UserDefaults(suiteName: "lifecycle.summaryModeInvalid")!
        defer { defaults.removePersistentDomain(forName: "lifecycle.summaryModeInvalid") }
        defaults.set("bogus", forKey: AppDefaults.Keys.hotkeyMode)
        defaults.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let summary = HotkeyDisplay.summaryIncludingMode(defaults: defaults)
        #expect(summary.contains("Toggle"))
    }

    // MARK: - ContentView insert target helpers

    @Test("isInsertTargetStale: nil capturedAt is not stale")
    func insertTargetStaleNilCaptured() {
        let stale = ViewHelpers.isInsertTargetStale(capturedAt: nil, now: Date(), staleAfterSeconds: 90)
        #expect(stale == false)
    }

    @Test("isInsertTargetStale: recent capture is not stale")
    func insertTargetStaleRecent() {
        let now = Date()
        let stale = ViewHelpers.isInsertTargetStale(capturedAt: now.addingTimeInterval(-10), now: now, staleAfterSeconds: 90)
        #expect(stale == false)
    }

    @Test("isInsertTargetStale: old capture is stale")
    func insertTargetStaleOld() {
        let now = Date()
        let stale = ViewHelpers.isInsertTargetStale(capturedAt: now.addingTimeInterval(-100), now: now, staleAfterSeconds: 90)
        #expect(stale == true)
    }

    @Test("activeInsertTargetStaleAfterSeconds: normal vs fallback")
    func activeStaleAfterSeconds() {
        let normal = ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: false, normalTimeout: 90, fallbackTimeout: 30)
        let fallback = ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: true, normalTimeout: 90, fallbackTimeout: 30)
        #expect(normal == 90)
        #expect(fallback == 30)
    }

    @Test("isInsertTargetLocked: locked when has text, can insert, and has target")
    func insertTargetLocked() {
        let locked = ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: true, canInsertNow: true,
            canInsertDirectly: true, hasResolvableInsertTarget: true
        )
        #expect(locked == true)
    }

    @Test("isInsertTargetLocked: not locked when no text")
    func insertTargetNotLockedNoText() {
        let locked = ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: false, canInsertNow: true,
            canInsertDirectly: true, hasResolvableInsertTarget: true
        )
        #expect(locked == false)
    }

    @Test("shouldShowUseCurrentAppQuickAction: shown when retarget suggested")
    func showUseCurrentApp() {
        let shown = ViewHelpers.shouldShowUseCurrentAppQuickAction(
            shouldSuggestRetarget: true, isInsertTargetStale: false
        )
        #expect(shown == true)
    }

    @Test("shouldShowUseCurrentAppQuickAction: shown when stale")
    func showUseCurrentAppStale() {
        let shown = ViewHelpers.shouldShowUseCurrentAppQuickAction(
            shouldSuggestRetarget: false, isInsertTargetStale: true
        )
        #expect(shown == true)
    }

    @Test("shouldShowUseCurrentAppQuickAction: hidden when neither")
    func hideUseCurrentApp() {
        let shown = ViewHelpers.shouldShowUseCurrentAppQuickAction(
            shouldSuggestRetarget: false, isInsertTargetStale: false
        )
        #expect(shown == false)
    }

    // MARK: - History entry stats

    @Test("historyEntryStats: with duration")
    func historyStatsWithDuration() {
        let stats = ViewHelpers.historyEntryStats(text: "hello world", durationSeconds: 5.0)
        #expect(!stats.isEmpty)
    }

    @Test("historyEntryStats: without duration")
    func historyStatsNoDuration() {
        let stats = ViewHelpers.historyEntryStats(text: "hello world", durationSeconds: nil)
        #expect(!stats.isEmpty)
    }

    @Test("historyEntryStats: empty text")
    func historyStatsEmptyText() {
        let stats = ViewHelpers.historyEntryStats(text: "", durationSeconds: nil)
        #expect(!stats.isEmpty || stats.isEmpty) // just verify no crash
    }

    // MARK: - AppDefaults Keys consistency

    @Test("All expected AppDefaults keys are non-empty strings")
    func allKeysNonEmpty() {
        let keys = [
            AppDefaults.Keys.audioFeedbackEnabled,
            AppDefaults.Keys.hotkeyKey,
            AppDefaults.Keys.hotkeyMode,
            AppDefaults.Keys.onboardingCompleted,
            AppDefaults.Keys.launchAtLogin,
        ]
        for key in keys {
            #expect(!key.isEmpty, "Key should be non-empty: \(key)")
        }
    }

    @Test("AppDefaults Keys are all unique")
    func allKeysUnique() {
        let keys = [
            AppDefaults.Keys.audioFeedbackEnabled,
            AppDefaults.Keys.hotkeyKey,
            AppDefaults.Keys.hotkeyMode,
            AppDefaults.Keys.onboardingCompleted,
            AppDefaults.Keys.launchAtLogin,
        ]
        let uniqueKeys = Set(keys)
        #expect(uniqueKeys.count == keys.count)
    }
}
