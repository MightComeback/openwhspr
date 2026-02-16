import Testing
import Foundation
@testable import OpenWhisper

@Suite("ContentView extracted logic")
struct ContentViewLogicTests {

    // MARK: - liveWordsPerMinute

    @Test("returns nil when duration under 5 seconds")
    func wpmNilShortDuration() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello world", durationSeconds: 4.9) == nil)
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello world", durationSeconds: 0) == nil)
    }

    @Test("returns nil when transcription is empty")
    func wpmNilEmptyText() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "", durationSeconds: 10) == nil)
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "   ", durationSeconds: 10) == nil)
    }

    @Test("computes correct wpm for known input")
    func wpmCorrect() {
        // 60 words in 60 seconds = 60 wpm
        let words60 = (0..<60).map { "word\($0)" }.joined(separator: " ")
        #expect(ViewHelpers.liveWordsPerMinute(transcription: words60, durationSeconds: 60) == 60)
    }

    @Test("wpm minimum is 1")
    func wpmMinimumOne() {
        // 1 word in 300 seconds = 0.2 wpm, should clamp to 1
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello", durationSeconds: 300) == 1)
    }

    @Test("wpm at exactly 5 seconds works")
    func wpmAtFiveSeconds() {
        let result = ViewHelpers.liveWordsPerMinute(transcription: "one two three", durationSeconds: 5)
        #expect(result != nil)
        #expect(result! > 0)
    }

    // MARK: - shouldCopyBecauseTargetUnknown

    @Test("returns false when cannot insert directly")
    func copyUnknownNoDirectInsert() {
        #expect(!ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: false, hasResolvableInsertTarget: false, hasExternalFrontApp: false
        ))
    }

    @Test("returns false when has resolvable target")
    func copyUnknownHasTarget() {
        #expect(!ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true, hasResolvableInsertTarget: true, hasExternalFrontApp: false
        ))
    }

    @Test("returns false when external front app exists")
    func copyUnknownHasFrontApp() {
        #expect(!ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true, hasResolvableInsertTarget: false, hasExternalFrontApp: true
        ))
    }

    @Test("returns true when can insert but no target and no front app")
    func copyUnknownTrue() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true, hasResolvableInsertTarget: false, hasExternalFrontApp: false
        ))
    }

    // MARK: - shouldSuggestRetarget

    @Test("returns false when insert target not locked")
    func retargetNotLocked() {
        #expect(!ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: false, insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: "com.apple.Safari",
            currentFrontBundleIdentifier: "com.apple.Notes",
            currentFrontAppName: "Notes", isInsertTargetStale: false
        ))
    }

    @Test("returns false when target name is nil")
    func retargetNilTarget() {
        #expect(!ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true, insertTargetAppName: nil,
            insertTargetBundleIdentifier: nil,
            currentFrontBundleIdentifier: "com.apple.Notes",
            currentFrontAppName: "Notes", isInsertTargetStale: false
        ))
    }

    @Test("returns false when target name is empty")
    func retargetEmptyTarget() {
        #expect(!ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true, insertTargetAppName: "  ",
            insertTargetBundleIdentifier: nil,
            currentFrontBundleIdentifier: nil,
            currentFrontAppName: nil, isInsertTargetStale: false
        ))
    }

    @Test("returns true when bundle IDs differ")
    func retargetDifferentBundle() {
        #expect(ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true, insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: "com.apple.Safari",
            currentFrontBundleIdentifier: "com.apple.Notes",
            currentFrontAppName: "Notes", isInsertTargetStale: false
        ))
    }

    @Test("returns false when bundle IDs match")
    func retargetSameBundle() {
        #expect(!ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true, insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: "com.apple.Safari",
            currentFrontBundleIdentifier: "com.apple.Safari",
            currentFrontAppName: "Safari", isInsertTargetStale: false
        ))
    }

    @Test("falls back to app name comparison when no bundle IDs")
    func retargetAppNameFallback() {
        #expect(ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true, insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: nil,
            currentFrontBundleIdentifier: nil,
            currentFrontAppName: "Notes", isInsertTargetStale: false
        ))
    }

    @Test("returns false when app names match case-insensitively")
    func retargetSameAppName() {
        #expect(!ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true, insertTargetAppName: "safari",
            insertTargetBundleIdentifier: nil,
            currentFrontBundleIdentifier: nil,
            currentFrontAppName: "Safari", isInsertTargetStale: false
        ))
    }

    @Test("falls back to stale check when no front app info")
    func retargetStaleFallback() {
        #expect(ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true, insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: nil,
            currentFrontBundleIdentifier: nil,
            currentFrontAppName: nil, isInsertTargetStale: true
        ))
        #expect(!ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true, insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: nil,
            currentFrontBundleIdentifier: nil,
            currentFrontAppName: nil, isInsertTargetStale: false
        ))
    }

    // MARK: - shouldAutoRefreshInsertTargetBeforePrimaryInsert

    @Test("returns false when cannot insert directly")
    func autoRefreshNoDirectInsert() {
        #expect(!ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: false, canRetargetInsertTarget: true,
            shouldSuggestRetarget: false, isInsertTargetStale: true
        ))
    }

    @Test("returns false when cannot retarget")
    func autoRefreshNoRetarget() {
        #expect(!ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true, canRetargetInsertTarget: false,
            shouldSuggestRetarget: false, isInsertTargetStale: true
        ))
    }

    @Test("returns false when retarget is suggested (user switched apps)")
    func autoRefreshRetargetSuggested() {
        #expect(!ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true, canRetargetInsertTarget: true,
            shouldSuggestRetarget: true, isInsertTargetStale: true
        ))
    }

    @Test("returns false when not stale")
    func autoRefreshNotStale() {
        #expect(!ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true, canRetargetInsertTarget: true,
            shouldSuggestRetarget: false, isInsertTargetStale: false
        ))
    }

    @Test("returns true when all conditions met")
    func autoRefreshTrue() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true, canRetargetInsertTarget: true,
            shouldSuggestRetarget: false, isInsertTargetStale: true
        ))
    }

    // MARK: - recordingDuration

    @Test("returns 0 when startedAt is nil")
    func durationNilStart() {
        #expect(ViewHelpers.recordingDuration(startedAt: nil, now: Date()) == 0)
    }

    @Test("returns positive duration for past start")
    func durationPositive() {
        let now = Date()
        let start = now.addingTimeInterval(-10)
        let d = ViewHelpers.recordingDuration(startedAt: start, now: now)
        #expect(d >= 9.9)
        #expect(d <= 10.1)
    }

    @Test("clamps to 0 when start is in the future")
    func durationFutureStart() {
        let now = Date()
        let start = now.addingTimeInterval(10)
        #expect(ViewHelpers.recordingDuration(startedAt: start, now: now) == 0)
    }
}
