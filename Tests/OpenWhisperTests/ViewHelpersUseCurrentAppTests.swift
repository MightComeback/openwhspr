import Testing
import Foundation
@testable import OpenWhisper

@Suite("ViewHelpers useCurrentApp + remaining coverage")
struct ViewHelpersUseCurrentAppTests {

    // MARK: - useCurrentAppButtonTitle

    @Test("useCurrentAppTitle: can insert with front app")
    func useCurrentAppTitleCanInsertFrontApp() {
        let title = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: "Safari")
        #expect(title == "Use Current → Safari")
    }

    @Test("useCurrentAppTitle: can insert no front app")
    func useCurrentAppTitleCanInsertNoFrontApp() {
        let title = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: nil)
        #expect(title == "Use Current App")
    }

    @Test("useCurrentAppTitle: can insert empty front app")
    func useCurrentAppTitleCanInsertEmptyFrontApp() {
        let title = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: "")
        #expect(title == "Use Current App")
    }

    @Test("useCurrentAppTitle: cannot insert")
    func useCurrentAppTitleCannotInsert() {
        let title = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: false, currentFrontAppName: "Safari")
        #expect(title == "Use Current + Copy")
    }

    // MARK: - useCurrentAppButtonHelpText

    @Test("useCurrentAppHelp: disabled reason shown")
    func useCurrentAppHelpDisabledReason() {
        let help = ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: "Still recording", canInsertDirectly: true)
        #expect(help.contains("Still recording"))
    }

    @Test("useCurrentAppHelp: can insert directly")
    func useCurrentAppHelpCanInsert() {
        let help = ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true)
        #expect(help.contains("insert immediately"))
    }

    @Test("useCurrentAppHelp: cannot insert directly")
    func useCurrentAppHelpCannotInsert() {
        let help = ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: false)
        #expect(help.contains("copy to clipboard"))
    }

    // MARK: - shouldShowUseCurrentAppQuickAction

    @Test("showUseCurrentApp: true when retarget suggested")
    func showUseCurrentAppRetargetSuggested() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: true, isInsertTargetStale: false) == true)
    }

    @Test("showUseCurrentApp: true when stale")
    func showUseCurrentAppStale() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: false, isInsertTargetStale: true) == true)
    }

    @Test("showUseCurrentApp: false when neither")
    func showUseCurrentAppNeither() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: false, isInsertTargetStale: false) == false)
    }

    // MARK: - liveWordsPerMinute

    @Test("liveWPM: nil when duration under 5 seconds")
    func liveWPMShortDuration() {
        let wpm = ViewHelpers.liveWordsPerMinute(transcription: "hello world test", durationSeconds: 4.9)
        #expect(wpm == nil)
    }

    @Test("liveWPM: nil when empty transcription")
    func liveWPMEmpty() {
        let wpm = ViewHelpers.liveWordsPerMinute(transcription: "", durationSeconds: 10)
        #expect(wpm == nil)
    }

    @Test("liveWPM: computes correct value")
    func liveWPMCorrect() {
        let text = "one two three four five six seven eight nine ten"
        let wpm = ViewHelpers.liveWordsPerMinute(transcription: text, durationSeconds: 60)
        #expect(wpm == 10)
    }

    @Test("liveWPM: minimum is 1")
    func liveWPMMinimum() {
        let wpm = ViewHelpers.liveWordsPerMinute(transcription: "hello", durationSeconds: 600)
        #expect(wpm == 1)
    }

    // MARK: - recordingDuration

    @Test("recordingDuration: nil startedAt returns 0")
    func recordingDurationNil() {
        #expect(ViewHelpers.recordingDuration(startedAt: nil, now: Date()) == 0)
    }

    @Test("recordingDuration: positive for past start")
    func recordingDurationPositive() {
        let now = Date()
        let d = ViewHelpers.recordingDuration(startedAt: now.addingTimeInterval(-10), now: now)
        #expect(d >= 9.9 && d <= 10.1)
    }

    @Test("recordingDuration: clamps future start to 0")
    func recordingDurationFuture() {
        let now = Date()
        #expect(ViewHelpers.recordingDuration(startedAt: now.addingTimeInterval(5), now: now) == 0)
    }

    // MARK: - currentExternalFrontBundleIdentifier

    @Test("externalFrontBundle: nil for empty")
    func externalBundleEmpty() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("", ownBundleIdentifier: "com.app") == nil)
    }

    @Test("externalFrontBundle: nil when matching own")
    func externalBundleMatchesOwn() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("com.app", ownBundleIdentifier: "com.app") == nil)
    }

    @Test("externalFrontBundle: returns value for external app")
    func externalBundleExternal() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("com.safari", ownBundleIdentifier: "com.app") == "com.safari")
    }

    // MARK: - currentExternalFrontAppName

    @Test("externalFrontAppName: nil for empty")
    func externalAppNameEmpty() {
        #expect(ViewHelpers.currentExternalFrontAppName("") == nil)
    }

    @Test("externalFrontAppName: nil for OpenWhisper")
    func externalAppNameOpenWhisper() {
        #expect(ViewHelpers.currentExternalFrontAppName("OpenWhisper") == nil)
    }

    @Test("externalFrontAppName: returns valid app name")
    func externalAppNameValid() {
        #expect(ViewHelpers.currentExternalFrontAppName("Safari") == "Safari")
    }

    // MARK: - isInsertTargetStale

    @Test("stale: false when capturedAt is nil")
    func staleNilCapturedAt() {
        #expect(ViewHelpers.isInsertTargetStale(capturedAt: nil, now: Date(), staleAfterSeconds: 10) == false)
    }

    @Test("stale: false within threshold")
    func staleWithinThreshold() {
        let now = Date()
        #expect(ViewHelpers.isInsertTargetStale(capturedAt: now.addingTimeInterval(-5), now: now, staleAfterSeconds: 10) == false)
    }

    @Test("stale: true past threshold")
    func stalePastThreshold() {
        let now = Date()
        #expect(ViewHelpers.isInsertTargetStale(capturedAt: now.addingTimeInterval(-15), now: now, staleAfterSeconds: 10) == true)
    }

    // MARK: - activeInsertTargetStaleAfterSeconds

    @Test("staleTimeout: normal when not fallback")
    func staleTimeoutNormal() {
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: false) == 90)
    }

    @Test("staleTimeout: shorter when fallback")
    func staleTimeoutFallback() {
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: true) == 30)
    }

    // MARK: - isInsertTargetLocked

    @Test("locked: true when all conditions met")
    func lockedAllConditions() {
        #expect(ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: true, canInsertNow: true,
            canInsertDirectly: true, hasResolvableInsertTarget: true
        ) == true)
    }

    @Test("locked: false when no text")
    func lockedNoText() {
        #expect(ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: false, canInsertNow: true,
            canInsertDirectly: true, hasResolvableInsertTarget: true
        ) == false)
    }

    @Test("locked: false when cannot insert")
    func lockedCannotInsert() {
        #expect(ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: true, canInsertNow: false,
            canInsertDirectly: true, hasResolvableInsertTarget: true
        ) == false)
    }

    // MARK: - shouldCopyBecauseTargetUnknown

    @Test("copyBecauseTargetUnknown: true when no target and no front app")
    func copyTrue() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true, hasResolvableInsertTarget: false, hasExternalFrontApp: false
        ) == true)
    }

    @Test("copyBecauseTargetUnknown: false when has target")
    func copyFalseHasTarget() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true, hasResolvableInsertTarget: true, hasExternalFrontApp: false
        ) == false)
    }

    @Test("copyBecauseTargetUnknown: false when has external front app")
    func copyFalseHasFrontApp() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true, hasResolvableInsertTarget: false, hasExternalFrontApp: true
        ) == false)
    }

    @Test("copyBecauseTargetUnknown: false when cannot insert directly")
    func copyFalseCannotInsert() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: false, hasResolvableInsertTarget: false, hasExternalFrontApp: false
        ) == false)
    }

    // MARK: - shouldSuggestRetarget

    @Test("suggestRetarget: true when bundle IDs differ and locked")
    func suggestRetargetTrue() {
        #expect(ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true,
            insertTargetAppName: "A", insertTargetBundleIdentifier: "com.a",
            currentFrontBundleIdentifier: "com.b", currentFrontAppName: "B",
            isInsertTargetStale: false
        ) == true)
    }

    @Test("suggestRetarget: false when same bundle")
    func suggestRetargetFalse() {
        #expect(ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true,
            insertTargetAppName: "A", insertTargetBundleIdentifier: "com.a",
            currentFrontBundleIdentifier: "com.a", currentFrontAppName: "A",
            isInsertTargetStale: false
        ) == false)
    }

    @Test("suggestRetarget: false when not locked")
    func suggestRetargetNotLocked() {
        #expect(ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: false,
            insertTargetAppName: "A", insertTargetBundleIdentifier: "com.a",
            currentFrontBundleIdentifier: "com.b", currentFrontAppName: "B",
            isInsertTargetStale: false
        ) == false)
    }

    // MARK: - shouldAutoRefreshInsertTargetBeforePrimaryInsert

    @Test("autoRefresh: true when stale")
    func autoRefreshStale() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true, canRetargetInsertTarget: true,
            shouldSuggestRetarget: false, isInsertTargetStale: true
        ) == true)
    }

    @Test("autoRefresh: false when not stale and not suggesting retarget")
    func autoRefreshFalse() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true, canRetargetInsertTarget: true,
            shouldSuggestRetarget: false, isInsertTargetStale: false
        ) == false)
    }
}
