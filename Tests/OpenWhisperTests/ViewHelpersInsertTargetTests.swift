import Testing
import Foundation
@testable import OpenWhisper

@Suite("ViewHelpers – Insert Target & Stale Logic")
struct ViewHelpersInsertTargetTests {

    // MARK: - isInsertTargetStale

    @Test("isInsertTargetStale: nil capturedAt returns false")
    func staleNilCapturedAt() {
        #expect(ViewHelpers.isInsertTargetStale(capturedAt: nil, now: Date(), staleAfterSeconds: 90) == false)
    }

    @Test("isInsertTargetStale: recent capture is not stale")
    func staleRecentCapture() {
        let now = Date()
        let capturedAt = now.addingTimeInterval(-30)
        #expect(ViewHelpers.isInsertTargetStale(capturedAt: capturedAt, now: now, staleAfterSeconds: 90) == false)
    }

    @Test("isInsertTargetStale: exactly at threshold is stale")
    func staleExactThreshold() {
        let now = Date()
        let capturedAt = now.addingTimeInterval(-90)
        #expect(ViewHelpers.isInsertTargetStale(capturedAt: capturedAt, now: now, staleAfterSeconds: 90) == true)
    }

    @Test("isInsertTargetStale: past threshold is stale")
    func stalePastThreshold() {
        let now = Date()
        let capturedAt = now.addingTimeInterval(-200)
        #expect(ViewHelpers.isInsertTargetStale(capturedAt: capturedAt, now: now, staleAfterSeconds: 90) == true)
    }

    @Test("isInsertTargetStale: zero threshold always stale")
    func staleZeroThreshold() {
        let now = Date()
        let capturedAt = now.addingTimeInterval(-0.001)
        #expect(ViewHelpers.isInsertTargetStale(capturedAt: capturedAt, now: now, staleAfterSeconds: 0) == true)
    }

    // MARK: - activeInsertTargetStaleAfterSeconds

    @Test("activeInsertTargetStaleAfterSeconds: normal target uses 90s default")
    func staleTimeoutNormal() {
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: false) == 90)
    }

    @Test("activeInsertTargetStaleAfterSeconds: fallback target uses 30s default")
    func staleTimeoutFallback() {
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: true) == 30)
    }

    @Test("activeInsertTargetStaleAfterSeconds: custom normal timeout")
    func staleTimeoutCustomNormal() {
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: false, normalTimeout: 120) == 120)
    }

    @Test("activeInsertTargetStaleAfterSeconds: custom fallback timeout")
    func staleTimeoutCustomFallback() {
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: true, fallbackTimeout: 15) == 15)
    }

    // MARK: - isInsertTargetLocked

    @Test("isInsertTargetLocked: all true returns true")
    func lockedAllTrue() {
        #expect(ViewHelpers.isInsertTargetLocked(hasTranscriptionText: true, canInsertNow: true, canInsertDirectly: true, hasResolvableInsertTarget: true) == true)
    }

    @Test("isInsertTargetLocked: no text returns false")
    func lockedNoText() {
        #expect(ViewHelpers.isInsertTargetLocked(hasTranscriptionText: false, canInsertNow: true, canInsertDirectly: true, hasResolvableInsertTarget: true) == false)
    }

    @Test("isInsertTargetLocked: cannot insert now returns false")
    func lockedCannotInsert() {
        #expect(ViewHelpers.isInsertTargetLocked(hasTranscriptionText: true, canInsertNow: false, canInsertDirectly: true, hasResolvableInsertTarget: true) == false)
    }

    @Test("isInsertTargetLocked: no accessibility returns false")
    func lockedNoAccessibility() {
        #expect(ViewHelpers.isInsertTargetLocked(hasTranscriptionText: true, canInsertNow: true, canInsertDirectly: false, hasResolvableInsertTarget: true) == false)
    }

    @Test("isInsertTargetLocked: no resolvable target returns false")
    func lockedNoTarget() {
        #expect(ViewHelpers.isInsertTargetLocked(hasTranscriptionText: true, canInsertNow: true, canInsertDirectly: true, hasResolvableInsertTarget: false) == false)
    }

    @Test("isInsertTargetLocked: all false returns false")
    func lockedAllFalse() {
        #expect(ViewHelpers.isInsertTargetLocked(hasTranscriptionText: false, canInsertNow: false, canInsertDirectly: false, hasResolvableInsertTarget: false) == false)
    }

    // MARK: - shouldShowUseCurrentAppQuickAction

    @Test("shouldShowUseCurrentAppQuickAction: both false returns false")
    func quickActionBothFalse() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: false, isInsertTargetStale: false) == false)
    }

    @Test("shouldShowUseCurrentAppQuickAction: suggest retarget true returns true")
    func quickActionRetarget() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: true, isInsertTargetStale: false) == true)
    }

    @Test("shouldShowUseCurrentAppQuickAction: stale true returns true")
    func quickActionStale() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: false, isInsertTargetStale: true) == true)
    }

    @Test("shouldShowUseCurrentAppQuickAction: both true returns true")
    func quickActionBothTrue() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: true, isInsertTargetStale: true) == true)
    }

    // MARK: - shouldAutoRefreshInsertTargetBeforePrimaryInsert

    @Test("shouldAutoRefresh: stale and all conditions met returns true")
    func autoRefreshAllMet() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true, canRetargetInsertTarget: true,
            shouldSuggestRetarget: false, isInsertTargetStale: true
        ) == true)
    }

    @Test("shouldAutoRefresh: not stale returns false")
    func autoRefreshNotStale() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true, canRetargetInsertTarget: true,
            shouldSuggestRetarget: false, isInsertTargetStale: false
        ) == false)
    }

    @Test("shouldAutoRefresh: cannot insert directly returns false")
    func autoRefreshNoAccessibility() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: false, canRetargetInsertTarget: true,
            shouldSuggestRetarget: false, isInsertTargetStale: true
        ) == false)
    }

    @Test("shouldAutoRefresh: cannot retarget returns false")
    func autoRefreshCannotRetarget() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true, canRetargetInsertTarget: false,
            shouldSuggestRetarget: false, isInsertTargetStale: true
        ) == false)
    }

    @Test("shouldAutoRefresh: suggest retarget blocks auto refresh")
    func autoRefreshSuggestRetargetBlocks() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true, canRetargetInsertTarget: true,
            shouldSuggestRetarget: true, isInsertTargetStale: true
        ) == false)
    }

    // MARK: - refreshFinalizationProgressBaseline

    @Test("refreshFinalizationProgressBaseline: recording returns nil")
    func baselineRecording() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(isRecording: true, pendingChunks: 5, currentBaseline: nil) == nil)
    }

    @Test("refreshFinalizationProgressBaseline: no pending returns nil")
    func baselineNoPending() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(isRecording: false, pendingChunks: 0, currentBaseline: nil) == nil)
    }

    @Test("refreshFinalizationProgressBaseline: first time sets baseline")
    func baselineFirstTime() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(isRecording: false, pendingChunks: 5, currentBaseline: nil) == 5)
    }

    @Test("refreshFinalizationProgressBaseline: higher pending updates baseline")
    func baselineHigherUpdates() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(isRecording: false, pendingChunks: 10, currentBaseline: 5) == 10)
    }

    @Test("refreshFinalizationProgressBaseline: lower pending keeps baseline")
    func baselineLowerKeeps() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(isRecording: false, pendingChunks: 3, currentBaseline: 5) == 5)
    }

    @Test("refreshFinalizationProgressBaseline: equal pending keeps baseline")
    func baselineEqualKeeps() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(isRecording: false, pendingChunks: 5, currentBaseline: 5) == 5)
    }

    // MARK: - currentExternalFrontBundleIdentifier

    @Test("currentExternalFrontBundleIdentifier: empty returns nil")
    func bundleIdEmpty() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("", ownBundleIdentifier: nil) == nil)
    }

    @Test("currentExternalFrontBundleIdentifier: whitespace returns nil")
    func bundleIdWhitespace() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("   ", ownBundleIdentifier: nil) == nil)
    }

    @Test("currentExternalFrontBundleIdentifier: own bundle returns nil")
    func bundleIdOwnBundle() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("com.example.openwhisper", ownBundleIdentifier: "com.example.openwhisper") == nil)
    }

    @Test("currentExternalFrontBundleIdentifier: own bundle case insensitive")
    func bundleIdOwnBundleCaseInsensitive() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("COM.Example.OpenWhisper", ownBundleIdentifier: "com.example.openwhisper") == nil)
    }

    @Test("currentExternalFrontBundleIdentifier: different bundle returns it")
    func bundleIdDifferent() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("com.apple.Safari", ownBundleIdentifier: "com.example.openwhisper") == "com.apple.Safari")
    }

    @Test("currentExternalFrontBundleIdentifier: nil own bundle returns candidate")
    func bundleIdNilOwn() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("com.apple.Safari", ownBundleIdentifier: nil) == "com.apple.Safari")
    }

    @Test("currentExternalFrontBundleIdentifier: trims whitespace")
    func bundleIdTrims() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("  com.apple.Safari  ", ownBundleIdentifier: nil) == "com.apple.Safari")
    }

    // MARK: - currentExternalFrontAppName

    @Test("currentExternalFrontAppName: empty returns nil")
    func appNameEmpty() {
        #expect(ViewHelpers.currentExternalFrontAppName("") == nil)
    }

    @Test("currentExternalFrontAppName: whitespace returns nil")
    func appNameWhitespace() {
        #expect(ViewHelpers.currentExternalFrontAppName("   ") == nil)
    }

    @Test("currentExternalFrontAppName: Unknown App returns nil")
    func appNameUnknown() {
        #expect(ViewHelpers.currentExternalFrontAppName("Unknown App") == nil)
    }

    @Test("currentExternalFrontAppName: Unknown App case insensitive")
    func appNameUnknownCaseInsensitive() {
        #expect(ViewHelpers.currentExternalFrontAppName("unknown app") == nil)
    }

    @Test("currentExternalFrontAppName: OpenWhisper returns nil")
    func appNameOpenWhisper() {
        #expect(ViewHelpers.currentExternalFrontAppName("OpenWhisper") == nil)
    }

    @Test("currentExternalFrontAppName: OpenWhisper case insensitive")
    func appNameOpenWhisperCase() {
        #expect(ViewHelpers.currentExternalFrontAppName("openwhisper") == nil)
    }

    @Test("currentExternalFrontAppName: valid name returns it")
    func appNameValid() {
        #expect(ViewHelpers.currentExternalFrontAppName("Safari") == "Safari")
    }

    @Test("currentExternalFrontAppName: trims whitespace")
    func appNameTrims() {
        #expect(ViewHelpers.currentExternalFrontAppName("  Safari  ") == "Safari")
    }

    // MARK: - canToggleRecording

    @Test("canToggleRecording: recording returns true regardless of mic")
    func canToggleRecording() {
        #expect(ViewHelpers.canToggleRecording(isRecording: true, pendingChunkCount: 0, microphoneAuthorized: false) == true)
    }

    @Test("canToggleRecording: pending chunks returns true regardless of mic")
    func canTogglePending() {
        #expect(ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 3, microphoneAuthorized: false) == true)
    }

    @Test("canToggleRecording: idle with mic returns true")
    func canToggleIdleMic() {
        #expect(ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 0, microphoneAuthorized: true) == true)
    }

    @Test("canToggleRecording: idle without mic returns false")
    func canToggleIdleNoMic() {
        #expect(ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 0, microphoneAuthorized: false) == false)
    }
}
