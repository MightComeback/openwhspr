import Testing
import Foundation
@testable import OpenWhisper

@Suite("ContentView Extracted Helpers")
struct ContentViewExtractedHelpersTests {

    // MARK: - liveWordsPerMinute

    @Test("liveWordsPerMinute: nil when duration < 5s")
    func wpmShortDuration() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello world", durationSeconds: 4.9) == nil)
    }

    @Test("liveWordsPerMinute: nil when duration is 0")
    func wpmZeroDuration() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello", durationSeconds: 0) == nil)
    }

    @Test("liveWordsPerMinute: nil for empty transcription")
    func wpmEmptyText() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "", durationSeconds: 60) == nil)
    }

    @Test("liveWordsPerMinute: nil for whitespace-only transcription")
    func wpmWhitespaceOnly() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "   \n  ", durationSeconds: 60) == nil)
    }

    @Test("liveWordsPerMinute: computes correctly for 60 words in 60 seconds")
    func wpmNormal() {
        let words = (1...60).map { "word\($0)" }.joined(separator: " ")
        let result = ViewHelpers.liveWordsPerMinute(transcription: words, durationSeconds: 60)
        #expect(result == 60)
    }

    @Test("liveWordsPerMinute: returns at least 1")
    func wpmMinimumOne() {
        let result = ViewHelpers.liveWordsPerMinute(transcription: "hi", durationSeconds: 600)
        #expect(result != nil)
        #expect(result! >= 1)
    }

    @Test("liveWordsPerMinute: handles exactly 5s duration")
    func wpmExactlyFiveSeconds() {
        let result = ViewHelpers.liveWordsPerMinute(transcription: "one two three", durationSeconds: 5)
        #expect(result != nil)
    }

    @Test("liveWordsPerMinute: punctuation-only is nil")
    func wpmPunctuationOnly() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "... --- !!!", durationSeconds: 10) == nil)
    }

    @Test("liveWordsPerMinute: negative duration returns nil")
    func wpmNegativeDuration() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello", durationSeconds: -5) == nil)
    }

    // MARK: - transcriptionStats

    @Test("transcriptionStats: empty text")
    func statsEmpty() {
        #expect(ViewHelpers.transcriptionStats("") == "0w · 0c")
    }

    @Test("transcriptionStats: single word")
    func statsSingleWord() {
        #expect(ViewHelpers.transcriptionStats("hello") == "1w · 5c")
    }

    @Test("transcriptionStats: multiple words")
    func statsMultipleWords() {
        #expect(ViewHelpers.transcriptionStats("hello world") == "2w · 11c")
    }

    @Test("transcriptionStats: trims whitespace")
    func statsTrimsWhitespace() {
        #expect(ViewHelpers.transcriptionStats("  hello  ") == "1w · 5c")
    }

    @Test("transcriptionStats: punctuation separates")
    func statsPunctuation() {
        let result = ViewHelpers.transcriptionStats("hello, world!")
        #expect(result == "2w · 13c")
    }

    @Test("transcriptionStats: numbers count as words")
    func statsNumbers() {
        #expect(ViewHelpers.transcriptionStats("test 123") == "2w · 8c")
    }

    // MARK: - insertButtonTitle

    @Test("insertButtonTitle: cannot insert directly")
    func insertTitleNoAccess() {
        let result = ViewHelpers.insertButtonTitle(
            canInsertDirectly: false, insertTargetAppName: "Safari",
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: "Safari"
        )
        #expect(result == "Copy → Clipboard")
    }

    @Test("insertButtonTitle: no target, no front app")
    func insertTitleNoTargetNoFront() {
        let result = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: nil,
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: nil
        )
        #expect(result == "Copy → Clipboard")
    }

    @Test("insertButtonTitle: no target, has front app")
    func insertTitleNoTargetWithFront() {
        let result = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: nil,
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: "Notes"
        )
        #expect(result == "Insert → Notes")
    }

    @Test("insertButtonTitle: has target, normal")
    func insertTitleNormal() {
        let result = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: "Safari",
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: nil
        )
        #expect(result == "Insert → Safari")
    }

    @Test("insertButtonTitle: fallback target")
    func insertTitleFallback() {
        let result = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: "Safari",
            insertTargetUsesFallback: true, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: nil
        )
        #expect(result == "Insert → Safari (recent)")
    }

    @Test("insertButtonTitle: stale target shows warning")
    func insertTitleStale() {
        let result = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: "Safari",
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: true, liveFrontAppName: nil
        )
        #expect(result.contains("⚠︎"))
    }

    @Test("insertButtonTitle: suggest retarget shows warning")
    func insertTitleRetarget() {
        let result = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: "Safari",
            insertTargetUsesFallback: false, shouldSuggestRetarget: true,
            isInsertTargetStale: false, liveFrontAppName: nil
        )
        #expect(result.contains("⚠︎"))
    }

    @Test("insertButtonTitle: empty target treated as no target")
    func insertTitleEmptyTarget() {
        let result = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: "",
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: "Notes"
        )
        #expect(result == "Insert → Notes")
    }

    @Test("insertButtonTitle: long app name truncated")
    func insertTitleLongName() {
        let result = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: "A Very Long Application Name That Exceeds Limit",
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: nil
        )
        #expect(result.contains("…"))
    }

    // MARK: - insertButtonHelpText

    @Test("insertButtonHelpText: disabled reason")
    func helpTextDisabled() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: "Recording in progress",
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: nil, insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(result == "Recording in progress before inserting")
    }

    @Test("insertButtonHelpText: no accessibility, no target")
    func helpTextNoAccessNoTarget() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: false, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: nil, insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(result.contains("Accessibility"))
        #expect(result.contains("clipboard"))
    }

    @Test("insertButtonHelpText: no accessibility, with target")
    func helpTextNoAccessWithTarget() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: false, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: "Notes", insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(result.contains("Notes"))
    }

    @Test("insertButtonHelpText: copy because target unknown")
    func helpTextTargetUnknown() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: true,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: nil, insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(result.contains("No destination"))
    }

    @Test("insertButtonHelpText: suggest retarget")
    func helpTextSuggestRetarget() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: true, isInsertTargetStale: false,
            insertTargetAppName: "Safari", insertTargetUsesFallback: false,
            currentFrontAppName: "Notes"
        )
        #expect(result.contains("Notes"))
        #expect(result.contains("Safari"))
        #expect(result.contains("Retarget"))
    }

    @Test("insertButtonHelpText: stale target")
    func helpTextStale() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: true,
            insertTargetAppName: "Safari", insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(result.contains("stale") || result.contains("a while ago"))
    }

    @Test("insertButtonHelpText: fallback target")
    func helpTextFallback() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: "Notes", insertTargetUsesFallback: true,
            currentFrontAppName: nil
        )
        #expect(result.contains("recent app context"))
    }

    @Test("insertButtonHelpText: normal target")
    func helpTextNormal() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: "Notes", insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(result == "Insert into Notes")
    }

    @Test("insertButtonHelpText: no target, live front app")
    func helpTextNoTargetLiveFront() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: nil, insertTargetUsesFallback: false,
            currentFrontAppName: "Terminal"
        )
        #expect(result == "Insert into Terminal")
    }

    @Test("insertButtonHelpText: no target, no front app")
    func helpTextNoTargetNoFront() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: nil, insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(result == "Insert into the last active app")
    }

    // MARK: - shouldCopyBecauseTargetUnknown

    @Test("shouldCopy: false when cannot insert directly")
    func copyNoAccess() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(canInsertDirectly: false, hasResolvableInsertTarget: false, hasExternalFrontApp: false) == false)
    }

    @Test("shouldCopy: false when has resolvable target")
    func copyHasTarget() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(canInsertDirectly: true, hasResolvableInsertTarget: true, hasExternalFrontApp: false) == false)
    }

    @Test("shouldCopy: true when no target and no front app")
    func copyNoTargetNoFront() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(canInsertDirectly: true, hasResolvableInsertTarget: false, hasExternalFrontApp: false) == true)
    }

    @Test("shouldCopy: false when no target but has front app")
    func copyNoTargetWithFront() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(canInsertDirectly: true, hasResolvableInsertTarget: false, hasExternalFrontApp: true) == false)
    }

    // MARK: - shouldSuggestRetarget

    @Test("suggestRetarget: false when not locked")
    func retargetNotLocked() {
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: false, insertTargetAppName: "Safari", insertTargetBundleIdentifier: nil, currentFrontBundleIdentifier: nil, currentFrontAppName: "Notes", isInsertTargetStale: false) == false)
    }

    @Test("suggestRetarget: false when no target name")
    func retargetNoTarget() {
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: true, insertTargetAppName: nil, insertTargetBundleIdentifier: nil, currentFrontBundleIdentifier: nil, currentFrontAppName: "Notes", isInsertTargetStale: false) == false)
    }

    @Test("suggestRetarget: false when empty target name")
    func retargetEmptyTarget() {
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: true, insertTargetAppName: "  ", insertTargetBundleIdentifier: nil, currentFrontBundleIdentifier: nil, currentFrontAppName: "Notes", isInsertTargetStale: false) == false)
    }

    @Test("suggestRetarget: true when bundle ids differ")
    func retargetDifferentBundles() {
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: true, insertTargetAppName: "Safari", insertTargetBundleIdentifier: "com.apple.Safari", currentFrontBundleIdentifier: "com.apple.Notes", currentFrontAppName: nil, isInsertTargetStale: false) == true)
    }

    @Test("suggestRetarget: false when bundle ids match")
    func retargetSameBundles() {
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: true, insertTargetAppName: "Safari", insertTargetBundleIdentifier: "com.apple.Safari", currentFrontBundleIdentifier: "com.apple.safari", currentFrontAppName: nil, isInsertTargetStale: false) == false)
    }

    @Test("suggestRetarget: true when app names differ (no bundles)")
    func retargetDifferentNames() {
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: true, insertTargetAppName: "Safari", insertTargetBundleIdentifier: nil, currentFrontBundleIdentifier: nil, currentFrontAppName: "Notes", isInsertTargetStale: false) == true)
    }

    @Test("suggestRetarget: false when app names match case-insensitive")
    func retargetSameNames() {
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: true, insertTargetAppName: "Safari", insertTargetBundleIdentifier: nil, currentFrontBundleIdentifier: nil, currentFrontAppName: "safari", isInsertTargetStale: false) == false)
    }

    @Test("suggestRetarget: falls back to stale when no front app")
    func retargetFallbackToStale() {
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: true, insertTargetAppName: "Safari", insertTargetBundleIdentifier: nil, currentFrontBundleIdentifier: nil, currentFrontAppName: nil, isInsertTargetStale: true) == true)
        #expect(ViewHelpers.shouldSuggestRetarget(isInsertTargetLocked: true, insertTargetAppName: "Safari", insertTargetBundleIdentifier: nil, currentFrontBundleIdentifier: nil, currentFrontAppName: nil, isInsertTargetStale: false) == false)
    }

    // MARK: - shouldAutoRefreshInsertTargetBeforePrimaryInsert

    @Test("autoRefresh: false when cannot insert directly")
    func autoRefreshNoAccess() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(canInsertDirectly: false, canRetargetInsertTarget: true, shouldSuggestRetarget: false, isInsertTargetStale: true) == false)
    }

    @Test("autoRefresh: false when cannot retarget")
    func autoRefreshCantRetarget() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(canInsertDirectly: true, canRetargetInsertTarget: false, shouldSuggestRetarget: false, isInsertTargetStale: true) == false)
    }

    @Test("autoRefresh: false when should suggest retarget")
    func autoRefreshSuggestRetarget() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(canInsertDirectly: true, canRetargetInsertTarget: true, shouldSuggestRetarget: true, isInsertTargetStale: true) == false)
    }

    @Test("autoRefresh: false when not stale")
    func autoRefreshNotStale() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(canInsertDirectly: true, canRetargetInsertTarget: true, shouldSuggestRetarget: false, isInsertTargetStale: false) == false)
    }

    @Test("autoRefresh: true when all conditions met")
    func autoRefreshTrue() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(canInsertDirectly: true, canRetargetInsertTarget: true, shouldSuggestRetarget: false, isInsertTargetStale: true) == true)
    }
}
