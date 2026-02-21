import Testing
import Foundation
@testable import OpenWhisper

/// Comprehensive E2E coverage for ContentView logic paths exercised through ViewHelpers.
/// Focuses on complex branching in menu bar, insert buttons, finalization, and recording state.
@Suite("ContentView E2E Coverage")
struct ContentViewE2ECoverageTests {

    // MARK: - menuBarIconName exhaustive branches

    @Test("menuBarIconName: insertion flash overrides everything")
    func menuBarIconFlashOverridesAll() {
        let icon = ViewHelpers.menuBarIconName(
            isRecording: true,
            pendingChunkCount: 5,
            hasTranscriptionText: true,
            isShowingInsertionFlash: true
        )
        #expect(icon == "checkmark.circle.fill")
    }

    @Test("menuBarIconName: recording overrides pending and text")
    func menuBarIconRecordingOverrides() {
        let icon = ViewHelpers.menuBarIconName(
            isRecording: true,
            pendingChunkCount: 3,
            hasTranscriptionText: true,
            isShowingInsertionFlash: false
        )
        #expect(icon == "waveform.circle.fill")
    }

    @Test("menuBarIconName: pending overrides text")
    func menuBarIconPendingOverrides() {
        let icon = ViewHelpers.menuBarIconName(
            isRecording: false,
            pendingChunkCount: 1,
            hasTranscriptionText: true,
            isShowingInsertionFlash: false
        )
        #expect(icon == "ellipsis.circle")
    }

    @Test("menuBarIconName: text present, nothing else")
    func menuBarIconTextPresent() {
        let icon = ViewHelpers.menuBarIconName(
            isRecording: false,
            pendingChunkCount: 0,
            hasTranscriptionText: true,
            isShowingInsertionFlash: false
        )
        #expect(icon == "doc.text")
    }

    @Test("menuBarIconName: idle state")
    func menuBarIconIdle() {
        let icon = ViewHelpers.menuBarIconName(
            isRecording: false,
            pendingChunkCount: 0,
            hasTranscriptionText: false,
            isShowingInsertionFlash: false
        )
        #expect(icon == "mic")
    }

    // MARK: - menuBarDurationLabel exhaustive branches

    @Test("menuBarDurationLabel: insertion flash returns Inserted")
    func durationLabelInsertionFlash() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: true,
            pendingChunkCount: 5,
            recordingElapsedSeconds: 90,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 2.0,
            lastChunkLatency: 1.5,
            transcriptionWordCount: 10,
            isShowingInsertionFlash: true
        )
        #expect(label == "Inserted")
    }

    @Test("menuBarDurationLabel: recording with elapsed time formats correctly")
    func durationLabelRecording() {
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
        #expect(label == "1:05")
    }

    @Test("menuBarDurationLabel: recording with zero elapsed")
    func durationLabelRecordingZero() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: true,
            pendingChunkCount: 0,
            recordingElapsedSeconds: 0,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0,
            lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(label == "0:00")
    }

    @Test("menuBarDurationLabel: recording with nil elapsed returns nil")
    func durationLabelRecordingNilElapsed() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: true,
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

    @Test("menuBarDurationLabel: pending with average latency shows ETA")
    func durationLabelPendingWithLatency() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: false,
            pendingChunkCount: 3,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 2.0,
            lastChunkLatency: 1.0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(label == "3⏳6s")
    }

    @Test("menuBarDurationLabel: pending with only last latency")
    func durationLabelPendingLastLatencyOnly() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: false,
            pendingChunkCount: 2,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0,
            lastChunkLatency: 3.0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(label == "2⏳6s")
    }

    @Test("menuBarDurationLabel: pending with queued start suffix")
    func durationLabelPendingQueuedStart() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: false,
            pendingChunkCount: 1,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: true,
            averageChunkLatency: 2.0,
            lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(label == "1⏳2s→●")
    }

    @Test("menuBarDurationLabel: pending with no latency shows count")
    func durationLabelPendingNoLatency() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: false,
            pendingChunkCount: 4,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0,
            lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(label == "4 left")
    }

    @Test("menuBarDurationLabel: pending with no latency and queued start")
    func durationLabelPendingNoLatencyQueued() {
        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: false,
            pendingChunkCount: 2,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: true,
            averageChunkLatency: 0,
            lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(label == "2 left→●")
    }

    @Test("menuBarDurationLabel: word count shown when idle with text")
    func durationLabelWordCount() {
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

    @Test("menuBarDurationLabel: completely idle returns nil")
    func durationLabelIdle() {
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

    // MARK: - isInsertionFlashVisible

    @Test("isInsertionFlashVisible: nil insertedAt is not visible")
    func flashVisibleNil() {
        #expect(!ViewHelpers.isInsertionFlashVisible(insertedAt: nil, now: Date()))
    }

    @Test("isInsertionFlashVisible: just inserted is visible")
    func flashVisibleJustInserted() {
        let now = Date()
        #expect(ViewHelpers.isInsertionFlashVisible(insertedAt: now, now: now))
    }

    @Test("isInsertionFlashVisible: within duration is visible")
    func flashVisibleWithinDuration() {
        let now = Date()
        let insertedAt = now.addingTimeInterval(-2)
        #expect(ViewHelpers.isInsertionFlashVisible(insertedAt: insertedAt, now: now, flashDuration: 3))
    }

    @Test("isInsertionFlashVisible: past duration is not visible")
    func flashVisiblePastDuration() {
        let now = Date()
        let insertedAt = now.addingTimeInterval(-4)
        #expect(!ViewHelpers.isInsertionFlashVisible(insertedAt: insertedAt, now: now, flashDuration: 3))
    }

    @Test("isInsertionFlashVisible: custom short duration")
    func flashVisibleCustomDuration() {
        let now = Date()
        let insertedAt = now.addingTimeInterval(-0.5)
        #expect(ViewHelpers.isInsertionFlashVisible(insertedAt: insertedAt, now: now, flashDuration: 1))
        #expect(!ViewHelpers.isInsertionFlashVisible(insertedAt: insertedAt, now: now, flashDuration: 0.4))
    }

    // MARK: - insertButtonTitle complex branches

    @Test("insertButtonTitle: canInsert, no target, no live front → clipboard")
    func insertTitleNoTargetNoFront() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(title == "Copy → Clipboard")
    }

    @Test("insertButtonTitle: canInsert, no target, live front present")
    func insertTitleNoTargetWithFront() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: "Safari"
        )
        #expect(title == "Insert → Safari")
    }

    @Test("insertButtonTitle: canInsert, no target, empty live front → clipboard")
    func insertTitleEmptyLiveFront() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: ""
        )
        #expect(title == "Copy → Clipboard")
    }

    @Test("insertButtonTitle: canInsert, empty target name → clipboard")
    func insertTitleEmptyTarget() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(title == "Copy → Clipboard")
    }

    @Test("insertButtonTitle: canInsert, fallback target shows (recent)")
    func insertTitleFallbackTarget() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "Xcode",
            insertTargetUsesFallback: true,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(title == "Insert → Xcode (recent)")
    }

    @Test("insertButtonTitle: canInsert, target stale shows warning")
    func insertTitleStaleTarget() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "Xcode",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: true,
            liveFrontAppName: nil
        )
        #expect(title.contains("⚠︎"))
    }

    @Test("insertButtonTitle: canInsert, suggest retarget shows warning")
    func insertTitleSuggestRetarget() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "Notes",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: true,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(title.contains("⚠︎"))
        #expect(title.contains("Notes"))
    }

    @Test("insertButtonTitle: canInsert, normal target")
    func insertTitleNormalTarget() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "Slack",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(title == "Insert → Slack")
    }

    @Test("insertButtonTitle: cannot insert → always clipboard")
    func insertTitleCannotInsert() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: false,
            insertTargetAppName: "Xcode",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: "Safari"
        )
        #expect(title == "Copy → Clipboard")
    }

    @Test("insertButtonTitle: long app name gets abbreviated")
    func insertTitleLongAppName() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "Some Very Long Application Name Here",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(title.contains("Insert →"))
        #expect(title.count < 60) // abbreviated
    }

    // MARK: - insertButtonHelpText complex branches

    @Test("insertButtonHelpText: disabled reason takes priority")
    func insertHelpDisabledReason() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: "Record something",
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: true,
            shouldSuggestRetarget: true,
            isInsertTargetStale: true,
            insertTargetAppName: "Xcode",
            insertTargetUsesFallback: false,
            currentFrontAppName: "Safari"
        )
        #expect(help == "Record something before inserting")
    }

    @Test("insertButtonHelpText: no accessibility, with target name")
    func insertHelpNoAccessibilityWithTarget() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: false,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: "TextEdit",
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(help.contains("Accessibility"))
        #expect(help.contains("TextEdit"))
    }

    @Test("insertButtonHelpText: no accessibility, no target")
    func insertHelpNoAccessibilityNoTarget() {
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
        #expect(help.contains("Accessibility"))
        #expect(help.contains("clipboard"))
    }

    @Test("insertButtonHelpText: copy because target unknown")
    func insertHelpCopyTargetUnknown() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: true,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(help.contains("No destination"))
    }

    @Test("insertButtonHelpText: suggest retarget with both front and target")
    func insertHelpSuggestRetarget() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: true,
            isInsertTargetStale: false,
            insertTargetAppName: "Notes",
            insertTargetUsesFallback: false,
            currentFrontAppName: "Safari"
        )
        #expect(help.contains("Safari"))
        #expect(help.contains("Notes"))
        #expect(help.contains("Retarget"))
    }

    @Test("insertButtonHelpText: stale target warning")
    func insertHelpStaleTarget() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: true,
            insertTargetAppName: "Xcode",
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(help.contains("a while ago"))
        #expect(help.contains("Xcode"))
    }

    @Test("insertButtonHelpText: normal target with fallback")
    func insertHelpFallbackTarget() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: "Terminal",
            insertTargetUsesFallback: true,
            currentFrontAppName: nil
        )
        #expect(help.contains("Terminal"))
        #expect(help.contains("recent"))
    }

    @Test("insertButtonHelpText: no target, with live front app")
    func insertHelpNoTargetLiveFront() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            currentFrontAppName: "Finder"
        )
        #expect(help.contains("Finder"))
    }

    @Test("insertButtonHelpText: no target, no front app")
    func insertHelpNoTargetNoFront() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(help.contains("last active"))
    }

    @Test("insertButtonHelpText: normal insert into target")
    func insertHelpNormalTarget() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: "Messages",
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(help == "Insert into Messages")
    }

    // MARK: - insertionTestDisabledReason all branches

    @Test("insertionTestDisabledReason: recording")
    func insertionTestRecording() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: true, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true,
            hasInsertionTarget: true
        )
        #expect(reason.contains("Stop recording"))
    }

    @Test("insertionTestDisabledReason: finalizing")
    func insertionTestFinalizing() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: true,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true,
            hasInsertionTarget: true
        )
        #expect(reason.contains("finalizing"))
    }

    @Test("insertionTestDisabledReason: already running")
    func insertionTestRunning() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: true, hasInsertionProbeSampleText: true,
            hasInsertionTarget: true
        )
        #expect(reason.contains("already running"))
    }

    @Test("insertionTestDisabledReason: empty sample text")
    func insertionTestEmptyText() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: false,
            hasInsertionTarget: true
        )
        #expect(reason.contains("empty"))
    }

    @Test("insertionTestDisabledReason: no target")
    func insertionTestNoTarget() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true,
            hasInsertionTarget: false
        )
        #expect(reason.contains("No destination"))
    }

    // MARK: - finalizationProgress edge cases

    @Test("finalizationProgress: recording returns nil")
    func finalizationProgressRecording() {
        let progress = ViewHelpers.finalizationProgress(
            pendingChunkCount: 3, initialPendingChunks: 5, isRecording: true
        )
        #expect(progress == nil)
    }

    @Test("finalizationProgress: no pending returns nil")
    func finalizationProgressNoPending() {
        let progress = ViewHelpers.finalizationProgress(
            pendingChunkCount: 0, initialPendingChunks: 5, isRecording: false
        )
        #expect(progress == nil)
    }

    @Test("finalizationProgress: nil initial returns nil")
    func finalizationProgressNilInitial() {
        let progress = ViewHelpers.finalizationProgress(
            pendingChunkCount: 3, initialPendingChunks: nil, isRecording: false
        )
        #expect(progress == nil)
    }

    @Test("finalizationProgress: zero initial returns nil")
    func finalizationProgressZeroInitial() {
        let progress = ViewHelpers.finalizationProgress(
            pendingChunkCount: 3, initialPendingChunks: 0, isRecording: false
        )
        #expect(progress == nil)
    }

    @Test("finalizationProgress: normal progress calculation")
    func finalizationProgressNormal() {
        let progress = ViewHelpers.finalizationProgress(
            pendingChunkCount: 2, initialPendingChunks: 4, isRecording: false
        )
        #expect(progress != nil)
        #expect(progress! >= 0.0)
        #expect(progress! <= 1.0)
    }

    @Test("finalizationProgress: all done (pending == 0 but initial > 0, recording false)")
    func finalizationProgressAllDone() {
        // pendingChunkCount == 0 → nil (already handled)
        let progress = ViewHelpers.finalizationProgress(
            pendingChunkCount: 0, initialPendingChunks: 4, isRecording: false
        )
        #expect(progress == nil)
    }

    // MARK: - statusTitle branches

    @Test("statusTitle: recording with duration")
    func statusTitleRecording() {
        let title = ViewHelpers.statusTitle(
            isRecording: true, recordingDuration: 30, pendingChunkCount: 0
        )
        #expect(title.contains("Recording"))
    }

    @Test("statusTitle: not recording, pending chunks")
    func statusTitleFinalizing() {
        let title = ViewHelpers.statusTitle(
            isRecording: false, recordingDuration: 0, pendingChunkCount: 3
        )
        #expect(title.contains("Finaliz") || title.contains("Processing"))
    }

    @Test("statusTitle: idle")
    func statusTitleIdle() {
        let title = ViewHelpers.statusTitle(
            isRecording: false, recordingDuration: 0, pendingChunkCount: 0
        )
        #expect(!title.isEmpty)
    }

    // MARK: - recordingDuration

    @Test("recordingDuration: nil startedAt returns 0")
    func recordingDurationNil() {
        let dur = ViewHelpers.recordingDuration(startedAt: nil, now: Date())
        #expect(dur == 0)
    }

    @Test("recordingDuration: future startedAt returns 0")
    func recordingDurationFuture() {
        let now = Date()
        let dur = ViewHelpers.recordingDuration(startedAt: now.addingTimeInterval(10), now: now)
        #expect(dur == 0)
    }

    @Test("recordingDuration: normal calculation")
    func recordingDurationNormal() {
        let now = Date()
        let dur = ViewHelpers.recordingDuration(startedAt: now.addingTimeInterval(-5), now: now)
        #expect(dur >= 4.9)
        #expect(dur <= 5.1)
    }

    // MARK: - estimatedFinalizationSeconds

    @Test("estimatedFinalizationSeconds: zero pending returns nil")
    func estFinSecZeroPending() {
        let est = ViewHelpers.estimatedFinalizationSeconds(
            pendingChunkCount: 0, averageChunkLatency: 2.0, lastChunkLatency: 1.5
        )
        #expect(est == nil)
    }

    @Test("estimatedFinalizationSeconds: with average latency")
    func estFinSecWithAvg() {
        let est = ViewHelpers.estimatedFinalizationSeconds(
            pendingChunkCount: 3, averageChunkLatency: 2.0, lastChunkLatency: 1.0
        )
        #expect(est != nil)
    }

    @Test("estimatedFinalizationSeconds: no latency returns nil")
    func estFinSecNoLatency() {
        let est = ViewHelpers.estimatedFinalizationSeconds(
            pendingChunkCount: 3, averageChunkLatency: 0, lastChunkLatency: 0
        )
        #expect(est == nil)
    }

    // MARK: - liveLoopLagNotice

    @Test("liveLoopLagNotice: low pending, no ETA → nil")
    func lagNoticeNil() {
        let notice = ViewHelpers.liveLoopLagNotice(
            pendingChunkCount: 1, estimatedFinalizationSeconds: nil
        )
        #expect(notice == nil)
    }

    @Test("liveLoopLagNotice: high ETA triggers notice")
    func lagNoticeHighETA() {
        let notice = ViewHelpers.liveLoopLagNotice(
            pendingChunkCount: 1, estimatedFinalizationSeconds: 10
        )
        #expect(notice != nil)
        #expect(notice!.contains("falling behind"))
    }

    @Test("liveLoopLagNotice: 3+ chunks with no ETA triggers notice")
    func lagNoticeHighChunks() {
        let notice = ViewHelpers.liveLoopLagNotice(
            pendingChunkCount: 3, estimatedFinalizationSeconds: nil
        )
        #expect(notice != nil)
        #expect(notice!.contains("3 chunks"))
    }

    @Test("liveLoopLagNotice: low ETA, low chunks → nil")
    func lagNoticeLowETALowChunks() {
        let notice = ViewHelpers.liveLoopLagNotice(
            pendingChunkCount: 1, estimatedFinalizationSeconds: 2
        )
        #expect(notice == nil)
    }

    // MARK: - shouldCopyBecauseTargetUnknown

    @Test("shouldCopyBecauseTargetUnknown: can insert, no target, no front → true")
    func copyBecauseUnknownTrue() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true, hasResolvableInsertTarget: false, hasExternalFrontApp: false
        ))
    }

    @Test("shouldCopyBecauseTargetUnknown: has target → false")
    func copyBecauseUnknownHasTarget() {
        #expect(!ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true, hasResolvableInsertTarget: true, hasExternalFrontApp: false
        ))
    }

    @Test("shouldCopyBecauseTargetUnknown: cannot insert directly → false")
    func copyBecauseUnknownCannotInsert() {
        #expect(!ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: false, hasResolvableInsertTarget: false, hasExternalFrontApp: false
        ))
    }

    @Test("shouldCopyBecauseTargetUnknown: has external front app → false")
    func copyBecauseUnknownHasFrontApp() {
        #expect(!ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true, hasResolvableInsertTarget: false, hasExternalFrontApp: true
        ))
    }

    // MARK: - canToggleRecording

    @Test("canToggleRecording: not recording, no pending, mic authorized → true")
    func canToggleTrue() {
        #expect(ViewHelpers.canToggleRecording(
            isRecording: false, pendingChunkCount: 0, microphoneAuthorized: true
        ))
    }

    @Test("canToggleRecording: recording → true (can stop)")
    func canToggleRecordingActive() {
        #expect(ViewHelpers.canToggleRecording(
            isRecording: true, pendingChunkCount: 0, microphoneAuthorized: true
        ))
    }

    @Test("canToggleRecording: pending chunks, not recording → true (can still toggle)")
    func canTogglePending() {
        // When pending > 0 and not recording, the function returns true (pending || recording path)
        #expect(ViewHelpers.canToggleRecording(
            isRecording: false, pendingChunkCount: 2, microphoneAuthorized: true
        ))
    }

    @Test("canToggleRecording: mic not authorized, not recording, no pending → false")
    func canToggleNoMic() {
        #expect(!ViewHelpers.canToggleRecording(
            isRecording: false, pendingChunkCount: 0, microphoneAuthorized: false
        ))
    }

    // MARK: - refreshFinalizationProgressBaseline

    @Test("refreshFinalizationProgressBaseline: returns correct initial value")
    func refreshBaselineNormal() {
        let result = ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: false,
            pendingChunks: 5,
            currentBaseline: nil
        )
        #expect(result == 5)
    }

    @Test("refreshFinalizationProgressBaseline: recording resets to nil")
    func refreshBaselineRecording() {
        let result = ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: true,
            pendingChunks: 5,
            currentBaseline: 3
        )
        #expect(result == nil)
    }

    @Test("refreshFinalizationProgressBaseline: zero pending resets to nil")
    func refreshBaselineZeroPending() {
        let result = ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: false,
            pendingChunks: 0,
            currentBaseline: 5
        )
        #expect(result == nil)
    }

    @Test("refreshFinalizationProgressBaseline: keeps max of current and new")
    func refreshBaselineKeepsMax() {
        let result = ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: false,
            pendingChunks: 3,
            currentBaseline: 5
        )
        #expect(result == 5)
    }

    // MARK: - isInsertTargetStale

    @Test("isInsertTargetStale: nil capturedAt is not stale")
    func staleNilCaptured() {
        #expect(!ViewHelpers.isInsertTargetStale(capturedAt: nil, now: Date(), staleAfterSeconds: 90))
    }

    @Test("isInsertTargetStale: recent capture is not stale")
    func staleRecentCapture() {
        let now = Date()
        #expect(!ViewHelpers.isInsertTargetStale(
            capturedAt: now.addingTimeInterval(-10), now: now, staleAfterSeconds: 90
        ))
    }

    @Test("isInsertTargetStale: old capture is stale")
    func staleOldCapture() {
        let now = Date()
        #expect(ViewHelpers.isInsertTargetStale(
            capturedAt: now.addingTimeInterval(-100), now: now, staleAfterSeconds: 90
        ))
    }

    // MARK: - activeInsertTargetStaleAfterSeconds

    @Test("activeInsertTargetStaleAfterSeconds: fallback uses shorter timeout")
    func staleSecondsFallback() {
        let secs = ViewHelpers.activeInsertTargetStaleAfterSeconds(
            usesFallback: true,
            normalTimeout: 90,
            fallbackTimeout: 30
        )
        #expect(secs == 30)
    }

    @Test("activeInsertTargetStaleAfterSeconds: non-fallback uses normal timeout")
    func staleSecondsNormal() {
        let secs = ViewHelpers.activeInsertTargetStaleAfterSeconds(
            usesFallback: false,
            normalTimeout: 90,
            fallbackTimeout: 30
        )
        #expect(secs == 90)
    }

    // MARK: - isInsertTargetLocked

    @Test("isInsertTargetLocked: all conditions true → locked")
    func lockedAllTrue() {
        #expect(ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: true, canInsertNow: true,
            canInsertDirectly: true, hasResolvableInsertTarget: true
        ))
    }

    @Test("isInsertTargetLocked: missing text → not locked")
    func lockedNoText() {
        #expect(!ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: false, canInsertNow: true,
            canInsertDirectly: true, hasResolvableInsertTarget: true
        ))
    }

    @Test("isInsertTargetLocked: cannot insert → not locked")
    func lockedCannotInsert() {
        #expect(!ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: true, canInsertNow: true,
            canInsertDirectly: false, hasResolvableInsertTarget: true
        ))
    }

    @Test("isInsertTargetLocked: no resolvable target → not locked")
    func lockedNoTarget() {
        #expect(!ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: true, canInsertNow: true,
            canInsertDirectly: true, hasResolvableInsertTarget: false
        ))
    }

    // MARK: - currentExternalFrontBundleIdentifier

    @Test("currentExternalFrontBundleIdentifier: filters own bundle")
    func externalFrontFiltersSelf() {
        let result = ViewHelpers.currentExternalFrontBundleIdentifier(
            "com.example.openwhisper", ownBundleIdentifier: "com.example.openwhisper"
        )
        #expect(result == nil)
    }

    @Test("currentExternalFrontBundleIdentifier: returns external bundle")
    func externalFrontReturnsExternal() {
        let result = ViewHelpers.currentExternalFrontBundleIdentifier(
            "com.apple.Safari", ownBundleIdentifier: "com.example.openwhisper"
        )
        #expect(result == "com.apple.Safari")
    }

    @Test("currentExternalFrontBundleIdentifier: nil own bundle returns candidate")
    func externalFrontNilOwn() {
        let result = ViewHelpers.currentExternalFrontBundleIdentifier(
            "com.apple.Safari", ownBundleIdentifier: nil
        )
        #expect(result == "com.apple.Safari")
    }

    // MARK: - currentExternalFrontAppName

    @Test("currentExternalFrontAppName: non-empty returns name")
    func externalFrontAppNameNonEmpty() {
        #expect(ViewHelpers.currentExternalFrontAppName("Safari") == "Safari")
    }

    @Test("currentExternalFrontAppName: empty returns nil")
    func externalFrontAppNameEmpty() {
        #expect(ViewHelpers.currentExternalFrontAppName("") == nil)
    }

    // MARK: - liveWordsPerMinute

    @Test("liveWordsPerMinute: zero duration returns nil")
    func wpmZeroDuration() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello world", durationSeconds: 0) == nil)
    }

    @Test("liveWordsPerMinute: empty text returns nil")
    func wpmEmptyText() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "", durationSeconds: 60) == nil)
    }

    @Test("liveWordsPerMinute: normal calculation")
    func wpmNormal() {
        let wpm = ViewHelpers.liveWordsPerMinute(transcription: "one two three four five six", durationSeconds: 30)
        #expect(wpm != nil)
        #expect(wpm! == 12) // 6 words in 30s = 12 wpm
    }

    // MARK: - transcriptionStats

    @Test("transcriptionStats: empty text")
    func statsEmpty() {
        let stats = ViewHelpers.transcriptionStats("")
        #expect(!stats.isEmpty)
    }

    @Test("transcriptionStats: multi-word text")
    func statsMultiWord() {
        let stats = ViewHelpers.transcriptionStats("hello world foo bar")
        #expect(stats.contains("4"))
    }

    // MARK: - transcriptionWordCount

    @Test("transcriptionWordCount: empty is 0")
    func wordCountEmpty() {
        #expect(ViewHelpers.transcriptionWordCount("") == 0)
    }

    @Test("transcriptionWordCount: whitespace only is 0")
    func wordCountWhitespace() {
        #expect(ViewHelpers.transcriptionWordCount("   \n  ") == 0)
    }

    @Test("transcriptionWordCount: normal text")
    func wordCountNormal() {
        #expect(ViewHelpers.transcriptionWordCount("hello world") == 2)
    }

    // MARK: - shouldShowUseCurrentAppQuickAction

    @Test("shouldShowUseCurrentAppQuickAction: suggest retarget + not stale → true")
    func showUseCurrentAppTrue() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(
            shouldSuggestRetarget: true, isInsertTargetStale: false
        ))
    }

    @Test("shouldShowUseCurrentAppQuickAction: stale → true")
    func showUseCurrentAppStale() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(
            shouldSuggestRetarget: false, isInsertTargetStale: true
        ))
    }

    @Test("shouldShowUseCurrentAppQuickAction: neither → false")
    func showUseCurrentAppFalse() {
        #expect(!ViewHelpers.shouldShowUseCurrentAppQuickAction(
            shouldSuggestRetarget: false, isInsertTargetStale: false
        ))
    }
}
