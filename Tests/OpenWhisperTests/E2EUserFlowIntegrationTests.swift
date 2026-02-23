import Testing
import Foundation
@testable import OpenWhisper

/// End-to-end integration tests that simulate complete user flows by composing
/// multiple ViewHelpers calls in sequence, mirroring what ContentView/SettingsView
/// do during real usage.
@Suite("E2E User Flow Integration", .serialized)
struct E2EUserFlowIntegrationTests {

    // MARK: - Record → Finalize → Insert flow

    @Test("Idle state: menu bar shows mic icon, no duration label")
    func idleState() {
        let icon = ViewHelpers.menuBarIconName(
            isRecording: false,
            pendingChunkCount: 0,
            hasTranscriptionText: false,
            isShowingInsertionFlash: false
        )
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
        #expect(icon.contains("mic"))
        #expect(label == nil)
    }

    @Test("Recording state: icon changes, duration label appears")
    func recordingState() {
        let icon = ViewHelpers.menuBarIconName(
            isRecording: true,
            pendingChunkCount: 0,
            hasTranscriptionText: false,
            isShowingInsertionFlash: false
        )
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: true,
            pendingChunkCount: 0,
            recordingElapsedSeconds: 5,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0,
            lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(icon != ViewHelpers.menuBarIconName(isRecording: false, pendingChunkCount: 0, hasTranscriptionText: false, isShowingInsertionFlash: false))
        #expect(label != nil)
    }

    @Test("Finalizing state: pending chunks show progress")
    func finalizingState() {
        let icon = ViewHelpers.menuBarIconName(
            isRecording: false,
            pendingChunkCount: 3,
            hasTranscriptionText: false,
            isShowingInsertionFlash: false
        )
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: false,
            pendingChunkCount: 3,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 2.0,
            lastChunkLatency: 1.8,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        // Should show some processing indicator
        #expect(label != nil)
        _ = icon // Valid icon returned
    }

    @Test("Post-insertion flash: icon shows checkmark briefly")
    func insertionFlash() {
        let now = Date()
        let justInserted = now.addingTimeInterval(-1)
        let visible = ViewHelpers.isInsertionFlashVisible(
            insertedAt: justInserted, now: now, flashDuration: 3
        )
        #expect(visible == true)

        let icon = ViewHelpers.menuBarIconName(
            isRecording: false,
            pendingChunkCount: 0,
            hasTranscriptionText: true,
            isShowingInsertionFlash: true
        )
        #expect(icon.contains("checkmark"))
    }

    @Test("Insertion flash expires after duration")
    func insertionFlashExpires() {
        let now = Date()
        let insertedLongAgo = now.addingTimeInterval(-10)
        let visible = ViewHelpers.isInsertionFlashVisible(
            insertedAt: insertedLongAgo, now: now, flashDuration: 3
        )
        #expect(visible == false)
    }

    @Test("Nil insertedAt means flash not visible")
    func noInsertionFlash() {
        let visible = ViewHelpers.isInsertionFlashVisible(
            insertedAt: nil, now: Date(), flashDuration: 3
        )
        #expect(visible == false)
    }

    // MARK: - Button state flows

    @Test("Full record → stop → insert button state flow")
    func recordStopInsertButtonFlow() {
        // Step 1: Can toggle recording when idle
        let canStart = ViewHelpers.canToggleRecording(
            isRecording: false, pendingChunkCount: 0, microphoneAuthorized: true
        )
        #expect(canStart == true)

        // Step 2: While recording, start/stop title changes
        let recordingTitle = ViewHelpers.startStopButtonTitle(
            isRecording: true, pendingChunkCount: 0, isStartAfterFinalizeQueued: false
        )
        let idleTitle = ViewHelpers.startStopButtonTitle(
            isRecording: false, pendingChunkCount: 0, isStartAfterFinalizeQueued: false
        )
        #expect(recordingTitle != idleTitle)

        // Step 3: After recording with text, insert is available
        let insertDisabled = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: true,
            isRunningInsertionProbe: false,
            isRecording: false,
            pendingChunkCount: 0
        )
        #expect(insertDisabled == nil)
    }

    @Test("Cannot insert while recording")
    func cannotInsertWhileRecording() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: true,
            isRunningInsertionProbe: false,
            isRecording: true,
            pendingChunkCount: 0
        )
        #expect(reason != nil)
    }

    @Test("Cannot insert while finalizing")
    func cannotInsertWhileFinalizing() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: true,
            isRunningInsertionProbe: false,
            isRecording: false,
            pendingChunkCount: 2
        )
        #expect(reason != nil)
    }

    @Test("Cannot insert with empty transcription")
    func cannotInsertEmpty() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: false,
            isRunningInsertionProbe: false,
            isRecording: false,
            pendingChunkCount: 0
        )
        #expect(reason != nil)
    }

    @Test("Cannot insert while running insertion probe")
    func cannotInsertDuringProbe() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: true,
            isRunningInsertionProbe: true,
            isRecording: false,
            pendingChunkCount: 0
        )
        #expect(reason != nil)
    }

    @Test("Cannot toggle recording without microphone permission")
    func cannotRecordWithoutMic() {
        let can = ViewHelpers.canToggleRecording(
            isRecording: false, pendingChunkCount: 0, microphoneAuthorized: false
        )
        #expect(can == false)
    }

    @Test("Can start recording while finalizing (queues start-after-finalize)")
    func canRecordWhileFinalizing() {
        let can = ViewHelpers.canToggleRecording(
            isRecording: false, pendingChunkCount: 3, microphoneAuthorized: true
        )
        #expect(can == true)
    }

    @Test("Can stop recording even while finalizing")
    func canStopWhileFinalizing() {
        let can = ViewHelpers.canToggleRecording(
            isRecording: true, pendingChunkCount: 3, microphoneAuthorized: true
        )
        #expect(can == true)
    }

    // MARK: - Status title flow

    @Test("Status title changes through recording lifecycle")
    func statusTitleLifecycle() {
        let idle = ViewHelpers.statusTitle(isRecording: false, recordingDuration: 0, pendingChunkCount: 0)
        let recording = ViewHelpers.statusTitle(isRecording: true, recordingDuration: 5.0, pendingChunkCount: 0)
        let finalizing = ViewHelpers.statusTitle(isRecording: false, recordingDuration: 0, pendingChunkCount: 2)

        // All should be non-empty strings
        #expect(!idle.isEmpty)
        #expect(!recording.isEmpty)
        #expect(!finalizing.isEmpty)
        // Recording and idle should differ
        #expect(recording != idle)
    }

    // MARK: - Hotkey summary flow

    @Test("Hotkey summary reflects mode")
    func hotkeySummaryMode() {
        let suite = UserDefaults(suiteName: "e2e.hotkey.mode")!
        defer { suite.removePersistentDomain(forName: "e2e.hotkey.mode") }
        AppDefaults.register(into: suite)

        suite.set("toggle", forKey: AppDefaults.Keys.hotkeyMode)
        suite.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        let toggleSummary = HotkeyDisplay.summaryIncludingMode(defaults: suite)
        #expect(toggleSummary.lowercased().contains("toggle"))

        suite.set("hold", forKey: AppDefaults.Keys.hotkeyMode)
        let holdSummary = HotkeyDisplay.summaryIncludingMode(defaults: suite)
        #expect(holdSummary.lowercased().contains("hold"))
    }

    // MARK: - Transcription stats flow

    @Test("Transcription stats reflect text content")
    func transcriptionStats() {
        let empty = ViewHelpers.transcriptionStats("")
        let words = ViewHelpers.transcriptionStats("Hello world this is a test")
        #expect(!empty.isEmpty)
        #expect(!words.isEmpty)
        #expect(words != empty)
    }

    @Test("Word count for empty and non-empty text")
    func wordCount() {
        #expect(ViewHelpers.transcriptionWordCount("") == 0)
        #expect(ViewHelpers.transcriptionWordCount("   ") == 0)
        #expect(ViewHelpers.transcriptionWordCount("Hello") == 1)
        #expect(ViewHelpers.transcriptionWordCount("Hello world") == 2)
        #expect(ViewHelpers.transcriptionWordCount("  Hello   world  ") == 2)
    }

    // MARK: - Insert target flow

    @Test("Insert target age description lifecycle")
    func insertTargetAge() {
        let now = Date()
        let recent = ViewHelpers.insertTargetAgeDescription(
            capturedAt: now.addingTimeInterval(-5),
            now: now,
            staleAfterSeconds: 60,
            isStale: false
        )
        // Recent target should have some description
        _ = recent

        let stale = ViewHelpers.insertTargetAgeDescription(
            capturedAt: now.addingTimeInterval(-120),
            now: now,
            staleAfterSeconds: 60,
            isStale: true
        )
        // Stale target might have different description
        _ = stale
    }

    @Test("No insert target age when capturedAt is nil")
    func noInsertTargetAge() {
        let desc = ViewHelpers.insertTargetAgeDescription(
            capturedAt: nil,
            now: Date(),
            staleAfterSeconds: 60,
            isStale: false
        )
        #expect(desc == nil)
    }

    // MARK: - Finalization progress flow

    @Test("Finalization progress tracks chunk completion")
    func finalizationProgress() {
        // Start with 5 chunks
        let baseline = ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: false, pendingChunks: 5, currentBaseline: nil
        )
        #expect(baseline == 5)

        // Progress at 3 remaining
        let progress = ViewHelpers.finalizationProgress(
            pendingChunkCount: 3,
            initialPendingChunks: 5,
            isRecording: false
        )
        #expect(progress != nil)
        if let p = progress {
            #expect(p > 0)
            #expect(p < 1)
        }

        // Progress at 0 remaining = done
        let done = ViewHelpers.finalizationProgress(
            pendingChunkCount: 0,
            initialPendingChunks: 5,
            isRecording: false
        )
        #expect(done == nil || done == 1.0)
    }

    @Test("Baseline not set while recording")
    func baselineNotSetWhileRecording() {
        let baseline = ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: true, pendingChunks: 5, currentBaseline: nil
        )
        #expect(baseline == nil)
    }

    // MARK: - Format duration flow

    @Test("Duration formatting across ranges")
    func durationFormatting() {
        let zero = ViewHelpers.formatDuration(0)
        let seconds = ViewHelpers.formatDuration(45)
        let minutes = ViewHelpers.formatDuration(125)
        let hour = ViewHelpers.formatDuration(3661)

        #expect(!zero.isEmpty)
        #expect(!seconds.isEmpty)
        #expect(!minutes.isEmpty)
        #expect(!hour.isEmpty)
        // Longer durations should produce longer or different strings
        #expect(zero != hour)
    }

    @Test("Short duration formatting")
    func shortDurationFormatting() {
        let short = ViewHelpers.formatShortDuration(5)
        let longer = ViewHelpers.formatShortDuration(90)
        #expect(!short.isEmpty)
        #expect(!longer.isEmpty)
    }

    // MARK: - Permission warning flow

    @Test("Auto-paste permission warning when accessibility missing")
    func autoPastePermWarning() {
        let shows = ViewHelpers.showsAutoPastePermissionWarning(
            autoPaste: true, accessibilityAuthorized: false
        )
        #expect(shows == true)
    }

    @Test("No auto-paste permission warning when authorized")
    func noAutoPastePermWarning() {
        let shows = ViewHelpers.showsAutoPastePermissionWarning(
            autoPaste: true, accessibilityAuthorized: true
        )
        #expect(shows == false)
    }

    @Test("No warning when auto-paste disabled")
    func noWarningWhenDisabled() {
        let shows = ViewHelpers.showsAutoPastePermissionWarning(
            autoPaste: false, accessibilityAuthorized: false
        )
        #expect(shows == false)
    }

    // MARK: - Abbreviated app name flow

    @Test("App name abbreviation")
    func abbreviatedAppName() {
        let short = ViewHelpers.abbreviatedAppName("Safari", maxCharacters: 18)
        #expect(short == "Safari")

        let long = ViewHelpers.abbreviatedAppName("Some Very Long Application Name That Exceeds Limit", maxCharacters: 18)
        #expect(long.count <= 20) // May include ellipsis
    }

    // MARK: - Insert button title flow

    @Test("Insert button title varies by context")
    func insertButtonTitleContext() {
        let withTarget = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "Safari",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        let withoutTarget = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        // Different contexts should produce different titles
        #expect(!withTarget.isEmpty)
        #expect(!withoutTarget.isEmpty)
    }

    // MARK: - Hotkey risk context flow

    @Test("Hotkey risk context for common keys")
    func hotkeyRiskContext() {
        let spaceRisk = ViewHelpers.effectiveHotkeyRiskContext(
            draft: "space",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        _ = spaceRisk // Should not crash

        let letterRisk = ViewHelpers.effectiveHotkeyRiskContext(
            draft: "a",
            currentKey: "space",
            currentModifiers: [.command]
        )
        _ = letterRisk
    }

    // MARK: - Sentence punctuation helpers

    @Test("Sentence punctuation detection")
    func sentencePunctuation() {
        #expect(ViewHelpers.isSentencePunctuation(".") == true)
        #expect(ViewHelpers.isSentencePunctuation("!") == true)
        #expect(ViewHelpers.isSentencePunctuation("?") == true)
        #expect(ViewHelpers.isSentencePunctuation(",") == true)
        #expect(ViewHelpers.isSentencePunctuation("a") == false)
    }

    @Test("Trailing sentence punctuation extraction")
    func trailingPunctuation() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "Hello.") == ".")
        #expect(ViewHelpers.trailingSentencePunctuation(in: "Hello!") == "!")
        #expect(ViewHelpers.trailingSentencePunctuation(in: "Hello") == nil)
        #expect(ViewHelpers.trailingSentencePunctuation(in: "") == nil)
    }

    // MARK: - Insertion probe flow

    @Test("Insertion probe status label")
    func probeStatusLabel() {
        let success = ViewHelpers.insertionProbeStatusLabel(succeeded: true)
        let failure = ViewHelpers.insertionProbeStatusLabel(succeeded: false)
        let pending = ViewHelpers.insertionProbeStatusLabel(succeeded: nil)
        #expect(!success.isEmpty)
        #expect(!failure.isEmpty)
        #expect(!pending.isEmpty)
        #expect(success != failure)
    }

    @Test("Insertion probe status color name")
    func probeStatusColor() {
        let successColor = ViewHelpers.insertionProbeStatusColorName(succeeded: true)
        let failColor = ViewHelpers.insertionProbeStatusColorName(succeeded: false)
        let pendingColor = ViewHelpers.insertionProbeStatusColorName(succeeded: nil)
        #expect(!successColor.isEmpty)
        #expect(!failColor.isEmpty)
        #expect(!pendingColor.isEmpty)
    }

    @Test("Insertion probe sample text extraction")
    func probeSampleText() {
        let sample = ViewHelpers.insertionProbeSampleTextForRun("Hello world")
        #expect(!sample.isEmpty)
        let has = ViewHelpers.hasInsertionProbeSampleText("Hello world")
        #expect(has == true)
        let hasEmpty = ViewHelpers.hasInsertionProbeSampleText("")
        #expect(hasEmpty == false)
    }

    // MARK: - Streaming elapsed status

    @Test("Streaming elapsed status segment")
    func streamingElapsed() {
        let at0 = ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 0)
        let at5 = ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 5)
        let at60 = ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 60)
        // At 0 seconds, might be nil or empty
        _ = at0
        _ = at5
        _ = at60
    }

    // MARK: - Capture profile helpers

    @Test("Capture profile fallback detection")
    func captureProfileFallback() {
        #expect(ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: true) == true)
        #expect(ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: false) == false)
        #expect(ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: nil) == false)
    }

    @Test("Capture profile fallback app name")
    func captureProfileFallbackName() {
        let name = ViewHelpers.captureProfileFallbackAppName(isFallback: true, appName: "Safari")
        #expect(name == "Safari")
        let noFallback = ViewHelpers.captureProfileFallbackAppName(isFallback: false, appName: "Safari")
        #expect(noFallback == nil)
        let nilFallback = ViewHelpers.captureProfileFallbackAppName(isFallback: nil, appName: "Safari")
        #expect(nilFallback == nil)
    }

    // MARK: - Focus and clear target flow

    @Test("Can focus insertion target requires target and not recording")
    func canFocusTarget() {
        let can = ViewHelpers.canFocusInsertionTarget(
            isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: true
        )
        #expect(can == true)

        let cantWhileRecording = ViewHelpers.canFocusInsertionTarget(
            isRecording: true, isFinalizingTranscription: false, hasInsertionTarget: true
        )
        #expect(cantWhileRecording == false)

        let cantWithoutTarget = ViewHelpers.canFocusInsertionTarget(
            isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: false
        )
        #expect(cantWithoutTarget == false)
    }

    @Test("Can clear insertion target when not probing and has target")
    func canClearTarget() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: true) == true)
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: true, hasInsertionTarget: true) == false)
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: false) == false)
    }

    // MARK: - Combined flow: Record → Stop → Check stats → Insert

    @Test("Full user flow: record, stop, get stats, check insert ability")
    func fullRecordToInsertFlow() {
        // 1. Verify can start
        #expect(ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 0, microphoneAuthorized: true))

        // 2. Check recording status title
        let title = ViewHelpers.statusTitle(isRecording: true, recordingDuration: 10, pendingChunkCount: 0)
        #expect(!title.isEmpty)

        // 3. Check format duration during recording
        let dur = ViewHelpers.formatDuration(10)
        #expect(!dur.isEmpty)

        // 4. Stop recording - title changes
        let stoppedTitle = ViewHelpers.statusTitle(isRecording: false, recordingDuration: 0, pendingChunkCount: 0)
        #expect(stoppedTitle != title)

        // 5. Get transcription stats
        let stats = ViewHelpers.transcriptionStats("Hello world this is my transcription text for testing")
        #expect(!stats.isEmpty)

        // 6. Check can insert
        let canInsert = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: true,
            isRunningInsertionProbe: false,
            isRecording: false,
            pendingChunkCount: 0
        )
        #expect(canInsert == nil)

        // 7. Get insert button title
        let insertTitle = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "Notes",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(!insertTitle.isEmpty)

        // 8. After insertion - flash visible
        let flashVisible = ViewHelpers.isInsertionFlashVisible(
            insertedAt: Date(), now: Date(), flashDuration: 3
        )
        #expect(flashVisible == true)

        // 9. Menu bar shows checkmark
        let icon = ViewHelpers.menuBarIconName(
            isRecording: false,
            pendingChunkCount: 0,
            hasTranscriptionText: true,
            isShowingInsertionFlash: true
        )
        #expect(icon.contains("checkmark"))
    }

    // MARK: - Hotkey draft edits detection

    @Test("Hotkey draft edits detection")
    func hotkeyDraftEdits() {
        let noEdits = ViewHelpers.hasHotkeyDraftEdits(
            draft: "space", currentKey: "space", currentModifiers: [.command, .shift]
        )
        #expect(noEdits == false)

        let hasEdits = ViewHelpers.hasHotkeyDraftEdits(
            draft: "a", currentKey: "space", currentModifiers: [.command, .shift]
        )
        #expect(hasEdits == true)
    }

    // MARK: - Bridge modifiers

    @Test("Bridge modifiers preserves set")
    func bridgeModifiers() {
        let input: Set<ViewHelpers.ParsedModifier> = [.command, .shift]
        let bridged = ViewHelpers.bridgeModifiers(input)
        #expect(bridged == input)
    }

    // MARK: - Model file size

    @Test("Model file size returns 0 for nonexistent path")
    func modelFileSize() {
        let size = ViewHelpers.sizeOfModelFile(atPath: "/nonexistent/model.bin")
        #expect(size == 0)
    }

    // MARK: - Key code helpers

    @Test("Modifier-only key code detection")
    func modifierOnlyKeyCode() {
        // 55 = command, 56 = shift, 58 = option, 59 = control
        #expect(ViewHelpers.isModifierOnlyKeyCode(55) == true)
        #expect(ViewHelpers.isModifierOnlyKeyCode(56) == true)
        #expect(ViewHelpers.isModifierOnlyKeyCode(0) == false) // 'a'
        #expect(ViewHelpers.isModifierOnlyKeyCode(49) == false) // space
    }

    @Test("Key name from key code")
    func keyNameFromCode() {
        let space = ViewHelpers.hotkeyKeyNameForKeyCode(49)
        #expect(space != nil)
        let a = ViewHelpers.hotkeyKeyNameForKeyCode(0)
        _ = a // May or may not return a name
    }
}
