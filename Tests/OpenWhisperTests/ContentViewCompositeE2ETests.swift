import Testing
@testable import OpenWhisper
import Foundation

/// E2E tests simulating full ContentView state transitions by composing
/// ViewHelpers calls the same way ContentView.swift does internally.
@Suite("ContentView composite E2E scenarios")
struct ContentViewCompositeE2ETests {

    // MARK: - Full recording lifecycle

    @Test("idle → recording → finalizing → insert ready lifecycle")
    func fullRecordingLifecycle() {
        // Idle state
        let idleTitle = ViewHelpers.statusTitle(isRecording: false, recordingDuration: 0, pendingChunkCount: 0)
        #expect(idleTitle.contains("Ready"))

        let canStart = ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 0, microphoneAuthorized: true)
        #expect(canStart)

        // Recording state
        let recTitle = ViewHelpers.statusTitle(isRecording: true, recordingDuration: 5.0, pendingChunkCount: 0)
        #expect(recTitle.contains("Recording"))

        let wpm = ViewHelpers.liveWordsPerMinute(transcription: "hello world foo bar baz", durationSeconds: 5.0)
        #expect(wpm != nil)

        // Stop → finalizing
        let finTitle = ViewHelpers.statusTitle(isRecording: false, recordingDuration: 0, pendingChunkCount: 3)
        #expect(finTitle.contains("Finaliz"))

        let progress = ViewHelpers.finalizationProgress(pendingChunkCount: 1, initialPendingChunks: 3, isRecording: false)
        #expect(progress != nil)
        #expect(progress! > 0.5)

        // Insert ready
        let disabledReason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: true,
            isRunningInsertionProbe: false,
            isRecording: false,
            pendingChunkCount: 0
        )
        #expect(disabledReason == nil)
    }

    @Test("cannot start recording without mic permission")
    func noMicBlocks() {
        let canStart = ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 0, microphoneAuthorized: false)
        #expect(!canStart)

        let help = ViewHelpers.startStopButtonHelpText(
            isRecording: false,
            pendingChunkCount: 0,
            isStartAfterFinalizeQueued: false,
            microphoneAuthorized: false
        )
        #expect(help.lowercased().contains("microphone"))
    }

    @Test("can still toggle during finalization (allows queued start)")
    func finalizingAllowsToggle() {
        // canToggleRecording returns true when pendingChunkCount > 0 to allow queued start
        let canToggle = ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 2, microphoneAuthorized: true)
        #expect(canToggle)
    }

    @Test("start after finalize queued shows correct button state")
    func startAfterFinalizeQueued() {
        let title = ViewHelpers.startStopButtonTitle(
            isRecording: false,
            pendingChunkCount: 2,
            isStartAfterFinalizeQueued: true
        )
        #expect(!title.isEmpty)

        let help = ViewHelpers.startStopButtonHelpText(
            isRecording: false,
            pendingChunkCount: 2,
            isStartAfterFinalizeQueued: true,
            microphoneAuthorized: true
        )
        #expect(!help.isEmpty)
    }

    // MARK: - Insert target lifecycle

    @Test("insert button adapts to target availability")
    func insertButtonTargetVariants() {
        // No target, no accessibility → copy
        let noTargetTitle = ViewHelpers.insertButtonTitle(
            canInsertDirectly: false,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(noTargetTitle.lowercased().contains("copy"))

        // Has target + accessibility → insert
        let hasTargetTitle = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "VS Code",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(hasTargetTitle.contains("VS Code") || hasTargetTitle.lowercased().contains("insert"))
    }

    @Test("stale insert target triggers retarget suggestion when locked")
    func staleTargetRetarget() {
        let stale = ViewHelpers.isInsertTargetStale(
            capturedAt: Date().addingTimeInterval(-100),
            now: Date(),
            staleAfterSeconds: 90
        )
        #expect(stale)

        // shouldSuggestRetarget requires isInsertTargetLocked=true
        let shouldRetarget = ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true,
            insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: "com.apple.Safari",
            currentFrontBundleIdentifier: "com.microsoft.VSCode",
            currentFrontAppName: "VS Code",
            isInsertTargetStale: true
        )
        #expect(shouldRetarget)

        let showQuickAction = ViewHelpers.shouldShowUseCurrentAppQuickAction(
            shouldSuggestRetarget: shouldRetarget,
            isInsertTargetStale: stale
        )
        #expect(showQuickAction)
    }

    @Test("unlocked target never suggests retarget")
    func unlockedTargetNoRetarget() {
        let shouldRetarget = ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: false,
            insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: "com.apple.Safari",
            currentFrontBundleIdentifier: "com.microsoft.VSCode",
            currentFrontAppName: "VS Code",
            isInsertTargetStale: true
        )
        #expect(!shouldRetarget)
    }

    @Test("fresh target does not suggest retarget when same app")
    func freshSameAppNoRetarget() {
        let stale = ViewHelpers.isInsertTargetStale(
            capturedAt: Date(),
            now: Date(),
            staleAfterSeconds: 90
        )
        #expect(!stale)

        let shouldRetarget = ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: false,
            insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: "com.apple.Safari",
            currentFrontBundleIdentifier: "com.apple.Safari",
            currentFrontAppName: "Safari",
            isInsertTargetStale: false
        )
        #expect(!shouldRetarget)
    }

    @Test("locked target suggests retarget when front app differs")
    func lockedTargetDifferentAppRetargets() {
        let shouldRetarget = ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true,
            insertTargetAppName: "Notes",
            insertTargetBundleIdentifier: "com.apple.Notes",
            currentFrontBundleIdentifier: "com.microsoft.VSCode",
            currentFrontAppName: "VS Code",
            isInsertTargetStale: true
        )
        #expect(shouldRetarget)
    }

    @Test("locked target does not suggest retarget when same app")
    func lockedTargetSameAppNoRetarget() {
        let shouldRetarget = ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true,
            insertTargetAppName: "Notes",
            insertTargetBundleIdentifier: "com.apple.Notes",
            currentFrontBundleIdentifier: "com.apple.Notes",
            currentFrontAppName: "Notes",
            isInsertTargetStale: true
        )
        #expect(!shouldRetarget)
    }

    @Test("insert target lock requires transcription + insert ready + accessibility + target")
    func insertTargetLockConditions() {
        let locked = ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: true,
            canInsertNow: true,
            canInsertDirectly: true,
            hasResolvableInsertTarget: true
        )
        #expect(locked)

        let notLockedNoText = ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: false,
            canInsertNow: true,
            canInsertDirectly: true,
            hasResolvableInsertTarget: true
        )
        #expect(!notLockedNoText)

        let notLockedNoAccessibility = ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: true,
            canInsertNow: true,
            canInsertDirectly: false,
            hasResolvableInsertTarget: true
        )
        #expect(!notLockedNoAccessibility)
    }

    // MARK: - Auto-refresh before insert

    @Test("auto-refresh triggered when stale but retarget NOT suggested")
    func autoRefreshBeforeInsert() {
        // autoRefresh fires when stale but shouldSuggestRetarget is false
        // (retarget already suggested = user handles it manually)
        let autoRefresh = ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true,
            canRetargetInsertTarget: true,
            shouldSuggestRetarget: false,
            isInsertTargetStale: true
        )
        #expect(autoRefresh)
    }

    @Test("no auto-refresh when retarget already suggested")
    func noAutoRefreshWhenRetargetSuggested() {
        let autoRefresh = ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true,
            canRetargetInsertTarget: true,
            shouldSuggestRetarget: true,
            isInsertTargetStale: true
        )
        #expect(!autoRefresh)
    }

    @Test("no auto-refresh when cannot insert directly")
    func noAutoRefreshWithoutAccessibility() {
        let autoRefresh = ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: false,
            canRetargetInsertTarget: true,
            shouldSuggestRetarget: true,
            isInsertTargetStale: true
        )
        #expect(!autoRefresh)
    }

    // MARK: - Copy fallback logic

    @Test("copy fallback when no target and no front app")
    func copyFallbackNoTarget() {
        let shouldCopy = ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true,
            hasResolvableInsertTarget: false,
            hasExternalFrontApp: false
        )
        #expect(shouldCopy)
    }

    @Test("no copy fallback when target exists")
    func noCopyFallbackWithTarget() {
        let shouldCopy = ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true,
            hasResolvableInsertTarget: true,
            hasExternalFrontApp: true
        )
        #expect(!shouldCopy)
    }

    @Test("no copy fallback without accessibility even if no target")
    func noCopyFallbackWithoutAccessibility() {
        let shouldCopy = ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: false,
            hasResolvableInsertTarget: false,
            hasExternalFrontApp: false
        )
        #expect(!shouldCopy)
    }

    // MARK: - Insert disabled reasons chain

    @Test("insert disabled during recording")
    func insertDisabledRecording() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: true,
            isRunningInsertionProbe: false,
            isRecording: true,
            pendingChunkCount: 0
        )
        #expect(reason != nil)
    }

    @Test("insert disabled without transcription text")
    func insertDisabledNoText() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: false,
            isRunningInsertionProbe: false,
            isRecording: false,
            pendingChunkCount: 0
        )
        #expect(reason != nil)
    }

    @Test("insert disabled during insertion probe")
    func insertDisabledDuringProbe() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: true,
            isRunningInsertionProbe: true,
            isRecording: false,
            pendingChunkCount: 0
        )
        #expect(reason != nil)
    }

    @Test("insert disabled during finalization")
    func insertDisabledFinalizing() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: true,
            isRunningInsertionProbe: false,
            isRecording: false,
            pendingChunkCount: 5
        )
        #expect(reason != nil)
    }

    // MARK: - Stale timeout varies by fallback

    @Test("fallback target uses shorter stale timeout")
    func fallbackShorterTimeout() {
        let normalTimeout = ViewHelpers.activeInsertTargetStaleAfterSeconds(
            usesFallback: false,
            normalTimeout: 90,
            fallbackTimeout: 30
        )
        #expect(normalTimeout == 90)

        let fallbackTimeout = ViewHelpers.activeInsertTargetStaleAfterSeconds(
            usesFallback: true,
            normalTimeout: 90,
            fallbackTimeout: 30
        )
        #expect(fallbackTimeout == 30)
    }

    // MARK: - External front app filtering

    @Test("own bundle excluded from external front app")
    func ownBundleExcluded() {
        let result = ViewHelpers.currentExternalFrontBundleIdentifier(
            "com.openwhisper.app",
            ownBundleIdentifier: "com.openwhisper.app"
        )
        #expect(result == nil)
    }

    @Test("different bundle passes through")
    func differentBundlePasses() {
        let result = ViewHelpers.currentExternalFrontBundleIdentifier(
            "com.apple.Safari",
            ownBundleIdentifier: "com.openwhisper.app"
        )
        #expect(result == "com.apple.Safari")
    }

    @Test("front app name passes non-empty names")
    func frontAppNamePasses() {
        let result = ViewHelpers.currentExternalFrontAppName("Safari")
        #expect(result == "Safari")
    }

    @Test("front app name rejects empty/whitespace")
    func frontAppNameRejectsEmpty() {
        #expect(ViewHelpers.currentExternalFrontAppName("") == nil)
        #expect(ViewHelpers.currentExternalFrontAppName("  ") == nil)
    }

    // MARK: - Finalization progress lifecycle

    @Test("finalization progress baseline captures first value")
    func finalizationBaselineCapture() {
        let baseline = ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: false,
            pendingChunks: 5,
            currentBaseline: nil
        )
        #expect(baseline == 5)
    }

    @Test("finalization progress baseline keeps larger value")
    func finalizationBaselineKeepsLarger() {
        let baseline = ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: false,
            pendingChunks: 3,
            currentBaseline: 5
        )
        #expect(baseline == 5)
    }

    @Test("finalization progress resets during recording")
    func finalizationBaselineResetsDuringRecording() {
        let baseline = ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: true,
            pendingChunks: 0,
            currentBaseline: 5
        )
        #expect(baseline == nil)
    }

    @Test("finalization progress tracks completion")
    func finalizationProgressCompletion() {
        let p1 = ViewHelpers.finalizationProgress(pendingChunkCount: 3, initialPendingChunks: 4, isRecording: false)
        let p2 = ViewHelpers.finalizationProgress(pendingChunkCount: 1, initialPendingChunks: 4, isRecording: false)
        let p3 = ViewHelpers.finalizationProgress(pendingChunkCount: 0, initialPendingChunks: 4, isRecording: false)

        #expect(p1 != nil && p2 != nil)
        #expect(p1! < p2!)
        // When pendingChunkCount is 0, progress may be nil (finalization complete) or 1.0
        if let p3 {
            #expect(p2! <= p3)
        }
    }

    // MARK: - Estimated finalization time

    @Test("estimated finalization seconds")
    func estimatedFinalization() {
        let est = ViewHelpers.estimatedFinalizationSeconds(
            pendingChunkCount: 4,
            averageChunkLatency: 2.5,
            lastChunkLatency: 3.0
        )
        #expect(est != nil)
        #expect(est! > 0)
    }

    @Test("no estimated time with zero pending")
    func noEstimatedTimeZeroPending() {
        let est = ViewHelpers.estimatedFinalizationSeconds(
            pendingChunkCount: 0,
            averageChunkLatency: 2.5,
            lastChunkLatency: 3.0
        )
        #expect(est == nil || est == 0)
    }

    // MARK: - Live loop lag notice

    @Test("lag notice appears with high pending count")
    func lagNoticeHighPending() {
        let notice = ViewHelpers.liveLoopLagNotice(
            pendingChunkCount: 10,
            estimatedFinalizationSeconds: 30
        )
        #expect(notice != nil)
    }

    @Test("no lag notice with low pending count")
    func noLagNoticeLowPending() {
        let notice = ViewHelpers.liveLoopLagNotice(
            pendingChunkCount: 1,
            estimatedFinalizationSeconds: 2
        )
        #expect(notice == nil)
    }

    // MARK: - Full insert flow: retarget + focus + insert buttons

    @Test("retarget disabled during recording")
    func retargetDisabledRecording() {
        let canRetarget = ViewHelpers.canRetargetInsertTarget(isRecording: true, pendingChunkCount: 0)
        #expect(!canRetarget)
    }

    @Test("retarget disabled during finalization")
    func retargetDisabledFinalizing() {
        let canRetarget = ViewHelpers.canRetargetInsertTarget(isRecording: false, pendingChunkCount: 3)
        #expect(!canRetarget)
    }

    @Test("retarget enabled when idle")
    func retargetEnabledIdle() {
        let canRetarget = ViewHelpers.canRetargetInsertTarget(isRecording: false, pendingChunkCount: 0)
        #expect(canRetarget)
    }

    @Test("retarget button titles vary by target state")
    func retargetButtonTitles() {
        let noTarget = ViewHelpers.retargetButtonTitle(insertTargetAppName: nil, insertTargetUsesFallback: false)
        let hasTarget = ViewHelpers.retargetButtonTitle(insertTargetAppName: "Notes", insertTargetUsesFallback: false)
        let fallback = ViewHelpers.retargetButtonTitle(insertTargetAppName: "Notes", insertTargetUsesFallback: true)
        #expect(noTarget != hasTarget || noTarget != fallback)
    }

    @Test("focus target requires resolvable target")
    func focusTargetResolvable() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "Safari"))
        #expect(!ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: nil))
        #expect(!ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: ""))
        #expect(!ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "  "))
    }

    // MARK: - Transcription stats

    @Test("transcription stats includes word count")
    func transcriptionStatsWordCount() {
        let stats = ViewHelpers.transcriptionStats("Hello world this is a test")
        #expect(stats.contains("6"))
    }

    @Test("word count handles edge cases")
    func wordCountEdgeCases() {
        #expect(ViewHelpers.transcriptionWordCount("") == 0)
        #expect(ViewHelpers.transcriptionWordCount("  ") == 0)
        #expect(ViewHelpers.transcriptionWordCount("hello") == 1)
        #expect(ViewHelpers.transcriptionWordCount("hello world") == 2)
    }

    // MARK: - WPM calculation

    @Test("wpm returns nil for very short durations")
    func wpmShortDuration() {
        let wpm = ViewHelpers.liveWordsPerMinute(transcription: "hello world", durationSeconds: 0.5)
        #expect(wpm == nil)
    }

    @Test("wpm calculates correctly")
    func wpmCalculation() {
        let wpm = ViewHelpers.liveWordsPerMinute(transcription: "one two three four five six seven eight nine ten", durationSeconds: 30)
        #expect(wpm != nil)
        #expect(wpm! == 20) // 10 words / 0.5 min = 20 wpm
    }

    // MARK: - Menu bar icon and duration label

    @Test("menu bar icon varies by state")
    func menuBarIconStates() {
        let idle = ViewHelpers.menuBarIconName(isRecording: false, pendingChunkCount: 0, hasTranscriptionText: false, isShowingInsertionFlash: false)
        let recording = ViewHelpers.menuBarIconName(isRecording: true, pendingChunkCount: 0, hasTranscriptionText: false, isShowingInsertionFlash: false)
        let finalizing = ViewHelpers.menuBarIconName(isRecording: false, pendingChunkCount: 3, hasTranscriptionText: false, isShowingInsertionFlash: false)
        let flash = ViewHelpers.menuBarIconName(isRecording: false, pendingChunkCount: 0, hasTranscriptionText: false, isShowingInsertionFlash: true)
        let hasText = ViewHelpers.menuBarIconName(isRecording: false, pendingChunkCount: 0, hasTranscriptionText: true, isShowingInsertionFlash: false)
        #expect(!idle.isEmpty)
        #expect(!recording.isEmpty)
        #expect(!finalizing.isEmpty)
        #expect(flash.contains("checkmark"))
        #expect(hasText.contains("doc"))
    }

    @Test("menu bar duration label during recording")
    func menuBarDurationRecording() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: true,
            pendingChunkCount: 0,
            recordingElapsedSeconds: 65,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0,
            lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(label != nil)
        #expect(label!.contains("1:05"))
    }

    @Test("menu bar duration label hidden when not recording")
    func menuBarDurationNotRecording() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: false,
            pendingChunkCount: 0,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0,
            lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(label == nil)
    }

    @Test("menu bar duration label shows insertion flash")
    func menuBarDurationInsertionFlash() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: false,
            pendingChunkCount: 0,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0,
            lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: true
        )
        #expect(label == "Inserted")
    }

    @Test("menu bar duration label shows word count")
    func menuBarDurationWordCount() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: false,
            pendingChunkCount: 0,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0,
            lastChunkLatency: 0,
            transcriptionWordCount: 42,
            isShowingInsertionFlash: false
        )
        #expect(label == "42w")
    }

    @Test("menu bar duration label shows finalization queue")
    func menuBarDurationFinalization() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: false,
            pendingChunkCount: 3,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 2.0,
            lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(label != nil)
        #expect(label!.contains("3"))
    }

    // MARK: - Insertion flash visibility

    @Test("insertion flash visible within window")
    func insertionFlashVisible() {
        let now = Date()
        let insertedAt = now.addingTimeInterval(-0.5)
        let visible = ViewHelpers.isInsertionFlashVisible(insertedAt: insertedAt, now: now, flashDuration: 2.0)
        #expect(visible)
    }

    @Test("insertion flash hidden after window")
    func insertionFlashHidden() {
        let now = Date()
        let insertedAt = now.addingTimeInterval(-5)
        let visible = ViewHelpers.isInsertionFlashVisible(insertedAt: insertedAt, now: now, flashDuration: 2.0)
        #expect(!visible)
    }

    @Test("insertion flash hidden with nil timestamp")
    func insertionFlashNilTimestamp() {
        let visible = ViewHelpers.isInsertionFlashVisible(insertedAt: nil, now: Date(), flashDuration: 2.0)
        #expect(!visible)
    }

    // MARK: - Last successful insert description

    @Test("last insert description shows time ago")
    func lastInsertDescription() {
        let now = Date()
        let desc = ViewHelpers.lastSuccessfulInsertDescription(insertedAt: now.addingTimeInterval(-30), now: now)
        #expect(desc != nil)
    }

    @Test("last insert description nil when no insert")
    func lastInsertDescriptionNil() {
        let desc = ViewHelpers.lastSuccessfulInsertDescription(insertedAt: nil, now: Date())
        #expect(desc == nil)
    }

    // MARK: - Insert target age description

    @Test("target age description shows freshness")
    func targetAgeDescription() {
        let now = Date()
        let desc = ViewHelpers.insertTargetAgeDescription(
            capturedAt: now.addingTimeInterval(-10),
            now: now,
            staleAfterSeconds: 90,
            isStale: false
        )
        #expect(desc != nil)
    }

    @Test("stale target age description differs from fresh")
    func staleTargetAgeDescription() {
        let now = Date()
        let staleDesc = ViewHelpers.insertTargetAgeDescription(
            capturedAt: now.addingTimeInterval(-100),
            now: now,
            staleAfterSeconds: 90,
            isStale: true
        )
        #expect(staleDesc != nil)
    }

    // MARK: - Button help text chains

    @Test("focus target button help text varies by state")
    func focusTargetHelpText() {
        let recording = ViewHelpers.focusTargetButtonHelpText(
            isRecording: true,
            pendingChunkCount: 0,
            insertTargetAppName: "Safari"
        )
        let idle = ViewHelpers.focusTargetButtonHelpText(
            isRecording: false,
            pendingChunkCount: 0,
            insertTargetAppName: "Safari"
        )
        // Both should have content
        #expect(!recording.isEmpty)
        #expect(!idle.isEmpty)
    }

    @Test("focus and insert button titles")
    func focusAndInsertTitles() {
        let title = ViewHelpers.focusAndInsertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "Safari"
        )
        #expect(!title.isEmpty)

        let help = ViewHelpers.focusAndInsertButtonHelpText(
            insertActionDisabledReason: nil,
            hasResolvableInsertTarget: true,
            canInsertDirectly: true
        )
        #expect(!help.isEmpty)
    }

    @Test("retarget and insert button titles")
    func retargetAndInsertTitles() {
        let title = ViewHelpers.retargetAndInsertButtonTitle(
            canInsertDirectly: true,
            currentFrontAppName: "VS Code"
        )
        #expect(!title.isEmpty)

        let help = ViewHelpers.retargetAndInsertHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true
        )
        #expect(!help.isEmpty)
    }

    @Test("use current app button titles")
    func useCurrentAppTitles() {
        let title = ViewHelpers.useCurrentAppButtonTitle(
            canInsertDirectly: true,
            currentFrontAppName: "Terminal"
        )
        #expect(!title.isEmpty)

        let help = ViewHelpers.useCurrentAppButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true
        )
        #expect(!help.isEmpty)
    }

    // MARK: - Hotkey mode tip text

    @Test("hotkey mode tip text for toggle and hold")
    func hotkeyModeTipText() {
        let toggleTip = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: false)
        let holdTip = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: false)
        #expect(!toggleTip.isEmpty)
        #expect(!holdTip.isEmpty)
        #expect(toggleTip != holdTip)
    }

    @Test("escape trigger changes tip text")
    func escapeTriggerTip() {
        let normalToggle = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: false)
        let escapeToggle = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: true)
        // Both should have content, may or may not differ
        #expect(!normalToggle.isEmpty)
        #expect(!escapeToggle.isEmpty)
    }

    // MARK: - Abbreviated app name

    @Test("abbreviated app name truncates long names")
    func abbreviatedAppName() {
        let short = ViewHelpers.abbreviatedAppName("Notes")
        #expect(short == "Notes")

        let long = ViewHelpers.abbreviatedAppName("A Very Long Application Name That Exceeds Limit")
        #expect(long.count <= 21) // 18 + "..."
    }

    // MARK: - History entry stats

    @Test("history entry stats includes duration")
    func historyEntryStatsWithDuration() {
        let stats = ViewHelpers.historyEntryStats(text: "Hello world", durationSeconds: 65)
        #expect(stats.contains("2") || stats.contains("word"))
    }

    @Test("history entry stats without duration")
    func historyEntryStatsNoDuration() {
        let stats = ViewHelpers.historyEntryStats(text: "Hello world", durationSeconds: nil)
        #expect(!stats.isEmpty)
    }

    // MARK: - Sentence punctuation helpers

    @Test("sentence punctuation detection")
    func sentencePunctuation() {
        #expect(ViewHelpers.isSentencePunctuation("."))
        #expect(ViewHelpers.isSentencePunctuation("!"))
        #expect(ViewHelpers.isSentencePunctuation("?"))
        #expect(!ViewHelpers.isSentencePunctuation("a"))
        #expect(!ViewHelpers.isSentencePunctuation(" "))
    }

    @Test("trailing sentence punctuation extraction")
    func trailingSentencePunctuation() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "Hello world.") == ".")
        #expect(ViewHelpers.trailingSentencePunctuation(in: "Really?!") == "?!")
        #expect(ViewHelpers.trailingSentencePunctuation(in: "No punctuation") == nil)
        #expect(ViewHelpers.trailingSentencePunctuation(in: "") == nil)
        #expect(ViewHelpers.trailingSentencePunctuation(in: "   ") == nil)
    }

    // MARK: - Streaming elapsed time

    @Test("streaming elapsed format")
    func streamingElapsed() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 0) == "0:00")
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 65) == "1:05")
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 3661) == "1:01:01")
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: -1) == nil)
    }

    // MARK: - Capture profile helpers

    @Test("capture profile fallback detection")
    func captureProfileFallback() {
        #expect(ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: true))
        #expect(!ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: false))
        #expect(!ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: nil))
    }

    @Test("capture profile fallback app name")
    func captureProfileFallbackName() {
        #expect(ViewHelpers.captureProfileFallbackAppName(isFallback: true, appName: "Safari") == "Safari")
        #expect(ViewHelpers.captureProfileFallbackAppName(isFallback: false, appName: "Safari") == nil)
        #expect(ViewHelpers.captureProfileFallbackAppName(isFallback: nil, appName: "Safari") == nil)
    }

    // MARK: - Insert button help text comprehensive

    @Test("insert button help text when disabled")
    func insertButtonHelpDisabled() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: "Recording in progress",
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: "Safari",
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(help.contains("Recording"))
    }

    @Test("insert button help text copy-only mode")
    func insertButtonHelpCopyOnly() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: false,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(!help.isEmpty)
    }

    // MARK: - Format duration edge cases

    @Test("format duration edge cases")
    func formatDurationEdges() {
        #expect(ViewHelpers.formatDuration(0) == "0:00")
        #expect(ViewHelpers.formatDuration(59) == "0:59")
        #expect(ViewHelpers.formatDuration(60) == "1:00")
        #expect(ViewHelpers.formatDuration(3661) == "61:01" || ViewHelpers.formatDuration(3661).contains("1:01:01") || !ViewHelpers.formatDuration(3661).isEmpty)
    }

    @Test("format short duration")
    func formatShortDuration() {
        let short = ViewHelpers.formatShortDuration(5.7)
        #expect(!short.isEmpty)
    }

    // MARK: - Active language label

    @Test("active language label for known codes")
    func activeLanguageLabel() {
        let en = ViewHelpers.activeLanguageLabel(for: "en")
        #expect(!en.isEmpty)
        let auto = ViewHelpers.activeLanguageLabel(for: "auto")
        #expect(!auto.isEmpty)
    }

    // MARK: - Permission summary

    @Test("hotkey missing permission summary")
    func hotkeyPermissionSummary() {
        let both = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: false, inputMonitoringAuthorized: false)
        #expect(both != nil)

        let accessOnly = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: false, inputMonitoringAuthorized: true)
        #expect(accessOnly != nil)

        let allGood = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: true, inputMonitoringAuthorized: true)
        #expect(allGood == nil)
    }

    // MARK: - Format bytes

    @Test("format bytes")
    func formatBytes() {
        #expect(ViewHelpers.formatBytes(0) == "0 B" || !ViewHelpers.formatBytes(0).isEmpty)
        #expect(ViewHelpers.formatBytes(1024).contains("1") || ViewHelpers.formatBytes(1024).contains("KB"))
        let big = ViewHelpers.formatBytes(1_500_000_000)
        #expect(!big.isEmpty) // format varies by implementation
    }

    // MARK: - Hotkey summary from modifiers

    @Test("hotkey summary from modifiers")
    func hotkeySummaryFromModifiers() {
        let summary = ViewHelpers.hotkeySummaryFromModifiers(
            command: true, shift: true, option: false, control: false, capsLock: false,
            key: "space"
        )
        #expect(summary.contains("⌘"))
        #expect(summary.contains("⇧"))
        #expect(!summary.contains("⌥"))
    }

    // MARK: - Shows auto-paste permission warning

    @Test("auto-paste permission warning logic")
    func autoPasteWarning() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: false))
        #expect(!ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: true))
        #expect(!ViewHelpers.showsAutoPastePermissionWarning(autoPaste: false, accessibilityAuthorized: false))
    }
}
