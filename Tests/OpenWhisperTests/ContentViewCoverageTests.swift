import Testing
import Foundation
@testable import OpenWhisper

@Suite("ContentView coverage — extracted helpers")
struct ContentViewCoverageTests {

    // MARK: - currentExternalFrontBundleIdentifier

    @Test("frontBundleId: returns nil for empty string")
    func frontBundleIdEmpty() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("", ownBundleIdentifier: nil) == nil)
    }

    @Test("frontBundleId: returns nil for whitespace-only")
    func frontBundleIdWhitespace() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("   ", ownBundleIdentifier: nil) == nil)
    }

    @Test("frontBundleId: returns nil when matching own bundle id")
    func frontBundleIdOwnApp() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("com.app.OpenWhisper", ownBundleIdentifier: "com.app.OpenWhisper") == nil)
    }

    @Test("frontBundleId: case-insensitive match with own")
    func frontBundleIdOwnAppCaseInsensitive() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("COM.APP.OPENWHISPER", ownBundleIdentifier: "com.app.OpenWhisper") == nil)
    }

    @Test("frontBundleId: returns trimmed value for external app")
    func frontBundleIdExternal() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("  com.apple.Safari  ", ownBundleIdentifier: "com.app.OpenWhisper") == "com.apple.Safari")
    }

    @Test("frontBundleId: returns value when own is nil")
    func frontBundleIdOwnNil() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("com.apple.Notes", ownBundleIdentifier: nil) == "com.apple.Notes")
    }

    // MARK: - currentExternalFrontAppName

    @Test("frontAppName: returns nil for empty string")
    func frontAppNameEmpty() {
        #expect(ViewHelpers.currentExternalFrontAppName("") == nil)
    }

    @Test("frontAppName: returns nil for whitespace-only")
    func frontAppNameWhitespace() {
        #expect(ViewHelpers.currentExternalFrontAppName("   ") == nil)
    }

    @Test("frontAppName: returns nil for Unknown App")
    func frontAppNameUnknown() {
        #expect(ViewHelpers.currentExternalFrontAppName("Unknown App") == nil)
    }

    @Test("frontAppName: case-insensitive Unknown App")
    func frontAppNameUnknownCase() {
        #expect(ViewHelpers.currentExternalFrontAppName("unknown app") == nil)
    }

    @Test("frontAppName: returns nil for OpenWhisper")
    func frontAppNameSelf() {
        #expect(ViewHelpers.currentExternalFrontAppName("OpenWhisper") == nil)
    }

    @Test("frontAppName: case-insensitive OpenWhisper")
    func frontAppNameSelfCase() {
        #expect(ViewHelpers.currentExternalFrontAppName("openwhisper") == nil)
    }

    @Test("frontAppName: returns trimmed value for valid app")
    func frontAppNameValid() {
        #expect(ViewHelpers.currentExternalFrontAppName("  Safari  ") == "Safari")
    }

    // MARK: - refreshFinalizationProgressBaseline

    @Test("baseline: returns nil when recording")
    func baselineRecording() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(isRecording: true, pendingChunks: 5, currentBaseline: 3) == nil)
    }

    @Test("baseline: returns nil when no pending chunks")
    func baselineNoPending() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(isRecording: false, pendingChunks: 0, currentBaseline: 3) == nil)
    }

    @Test("baseline: sets initial when no current baseline")
    func baselineInitial() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(isRecording: false, pendingChunks: 5, currentBaseline: nil) == 5)
    }

    @Test("baseline: keeps max of current and new")
    func baselineKeepsMax() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(isRecording: false, pendingChunks: 3, currentBaseline: 5) == 5)
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(isRecording: false, pendingChunks: 7, currentBaseline: 5) == 7)
    }

    // MARK: - canToggleRecording

    @Test("canToggle: true when recording")
    func canToggleRecording() {
        #expect(ViewHelpers.canToggleRecording(isRecording: true, pendingChunkCount: 0, microphoneAuthorized: false) == true)
    }

    @Test("canToggle: true when pending chunks")
    func canTogglePending() {
        #expect(ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 1, microphoneAuthorized: false) == true)
    }

    @Test("canToggle: true when mic authorized")
    func canToggleMicAuthorized() {
        #expect(ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 0, microphoneAuthorized: true) == true)
    }

    @Test("canToggle: false when idle and no mic")
    func canToggleFalse() {
        #expect(ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 0, microphoneAuthorized: false) == false)
    }

    // MARK: - isInsertTargetStale

    @Test("stale: false when capturedAt is nil")
    func staleNilDate() {
        #expect(ViewHelpers.isInsertTargetStale(capturedAt: nil, now: Date(), staleAfterSeconds: 90) == false)
    }

    @Test("stale: false when within threshold")
    func staleFresh() {
        let now = Date()
        let recent = now.addingTimeInterval(-30)
        #expect(ViewHelpers.isInsertTargetStale(capturedAt: recent, now: now, staleAfterSeconds: 90) == false)
    }

    @Test("stale: true when past threshold")
    func staleOld() {
        let now = Date()
        let old = now.addingTimeInterval(-91)
        #expect(ViewHelpers.isInsertTargetStale(capturedAt: old, now: now, staleAfterSeconds: 90) == true)
    }

    @Test("stale: true at exact threshold")
    func staleExact() {
        let now = Date()
        let exact = now.addingTimeInterval(-90)
        #expect(ViewHelpers.isInsertTargetStale(capturedAt: exact, now: now, staleAfterSeconds: 90) == true)
    }

    // MARK: - activeInsertTargetStaleAfterSeconds

    @Test("staleTimeout: normal when not fallback")
    func staleTimeoutNormal() {
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: false) == 90)
    }

    @Test("staleTimeout: short when fallback")
    func staleTimeoutFallback() {
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: true) == 30)
    }

    @Test("staleTimeout: custom values")
    func staleTimeoutCustom() {
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: false, normalTimeout: 120, fallbackTimeout: 15) == 120)
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: true, normalTimeout: 120, fallbackTimeout: 15) == 15)
    }

    // MARK: - isInsertTargetLocked

    @Test("locked: true when all conditions met")
    func lockedAllTrue() {
        #expect(ViewHelpers.isInsertTargetLocked(hasTranscriptionText: true, canInsertNow: true, canInsertDirectly: true, hasResolvableInsertTarget: true) == true)
    }

    @Test("locked: false when no text")
    func lockedNoText() {
        #expect(ViewHelpers.isInsertTargetLocked(hasTranscriptionText: false, canInsertNow: true, canInsertDirectly: true, hasResolvableInsertTarget: true) == false)
    }

    @Test("locked: false when cannot insert now")
    func lockedCannotInsert() {
        #expect(ViewHelpers.isInsertTargetLocked(hasTranscriptionText: true, canInsertNow: false, canInsertDirectly: true, hasResolvableInsertTarget: true) == false)
    }

    @Test("locked: false when no accessibility")
    func lockedNoAccessibility() {
        #expect(ViewHelpers.isInsertTargetLocked(hasTranscriptionText: true, canInsertNow: true, canInsertDirectly: false, hasResolvableInsertTarget: true) == false)
    }

    @Test("locked: false when no resolvable target")
    func lockedNoTarget() {
        #expect(ViewHelpers.isInsertTargetLocked(hasTranscriptionText: true, canInsertNow: true, canInsertDirectly: true, hasResolvableInsertTarget: false) == false)
    }

    // MARK: - shouldShowUseCurrentAppQuickAction

    @Test("showUseCurrentApp: true when retarget suggested")
    func showUseCurrentAppRetarget() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: true, isInsertTargetStale: false) == true)
    }

    @Test("showUseCurrentApp: true when stale")
    func showUseCurrentAppStale() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: false, isInsertTargetStale: true) == true)
    }

    @Test("showUseCurrentApp: true when both")
    func showUseCurrentAppBoth() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: true, isInsertTargetStale: true) == true)
    }

    @Test("showUseCurrentApp: false when neither")
    func showUseCurrentAppNeither() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: false, isInsertTargetStale: false) == false)
    }
}
