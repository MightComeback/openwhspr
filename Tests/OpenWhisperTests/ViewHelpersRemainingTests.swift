import Testing
import Foundation
@testable import OpenWhisper

// MARK: - currentExternalFrontBundleIdentifier

@Suite("ViewHelpers.currentExternalFrontBundleIdentifier")
struct CurrentExternalFrontBundleIdentifierTests {
    @Test("returns nil for empty string")
    func emptyString() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("", ownBundleIdentifier: "com.example.app") == nil)
    }

    @Test("returns nil for whitespace-only string")
    func whitespaceOnly() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("   ", ownBundleIdentifier: "com.example.app") == nil)
    }

    @Test("returns nil when candidate matches own bundle id")
    func matchesOwn() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("com.example.App", ownBundleIdentifier: "com.example.App") == nil)
    }

    @Test("returns nil when candidate matches own bundle id case-insensitively")
    func matchesOwnCaseInsensitive() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("COM.EXAMPLE.APP", ownBundleIdentifier: "com.example.app") == nil)
    }

    @Test("returns candidate when different from own bundle id")
    func differentBundle() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("com.other.app", ownBundleIdentifier: "com.example.app") == "com.other.app")
    }

    @Test("returns candidate when own bundle id is nil")
    func ownNil() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("com.other.app", ownBundleIdentifier: nil) == "com.other.app")
    }

    @Test("trims whitespace from candidate")
    func trimsWhitespace() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("  com.other.app  ", ownBundleIdentifier: nil) == "com.other.app")
    }
}

// MARK: - currentExternalFrontAppName

@Suite("ViewHelpers.currentExternalFrontAppName")
struct CurrentExternalFrontAppNameTests {
    @Test("returns nil for empty string")
    func emptyString() {
        #expect(ViewHelpers.currentExternalFrontAppName("") == nil)
    }

    @Test("returns nil for whitespace-only string")
    func whitespaceOnly() {
        #expect(ViewHelpers.currentExternalFrontAppName("   ") == nil)
    }

    @Test("returns nil for Unknown App")
    func unknownApp() {
        #expect(ViewHelpers.currentExternalFrontAppName("Unknown App") == nil)
    }

    @Test("returns nil for unknown app case-insensitive")
    func unknownAppCaseInsensitive() {
        #expect(ViewHelpers.currentExternalFrontAppName("unknown app") == nil)
    }

    @Test("returns nil for OpenWhisper")
    func openWhisper() {
        #expect(ViewHelpers.currentExternalFrontAppName("OpenWhisper") == nil)
    }

    @Test("returns nil for openwhisper case-insensitive")
    func openWhisperCaseInsensitive() {
        #expect(ViewHelpers.currentExternalFrontAppName("openwhisper") == nil)
    }

    @Test("returns valid app name")
    func validAppName() {
        #expect(ViewHelpers.currentExternalFrontAppName("Safari") == "Safari")
    }

    @Test("trims whitespace from valid name")
    func trimsWhitespace() {
        #expect(ViewHelpers.currentExternalFrontAppName("  Safari  ") == "Safari")
    }
}

// MARK: - refreshFinalizationProgressBaseline

@Suite("ViewHelpers.refreshFinalizationProgressBaseline")
struct RefreshFinalizationProgressBaselineTests {
    @Test("returns nil when recording")
    func recording() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(isRecording: true, pendingChunks: 5, currentBaseline: 3) == nil)
    }

    @Test("returns nil when no pending chunks")
    func noPending() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(isRecording: false, pendingChunks: 0, currentBaseline: 3) == nil)
    }

    @Test("returns pending chunks when no current baseline")
    func noBaseline() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(isRecording: false, pendingChunks: 5, currentBaseline: nil) == 5)
    }

    @Test("returns max of current baseline and pending chunks when baseline is higher")
    func baselineHigher() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(isRecording: false, pendingChunks: 3, currentBaseline: 5) == 5)
    }

    @Test("returns max of current baseline and pending chunks when pending is higher")
    func pendingHigher() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(isRecording: false, pendingChunks: 7, currentBaseline: 5) == 7)
    }

    @Test("returns pending when equal to baseline")
    func equal() {
        #expect(ViewHelpers.refreshFinalizationProgressBaseline(isRecording: false, pendingChunks: 5, currentBaseline: 5) == 5)
    }
}

// MARK: - canToggleRecording

@Suite("ViewHelpers.canToggleRecording")
struct CanToggleRecordingTests {
    @Test("returns true when recording")
    func recording() {
        #expect(ViewHelpers.canToggleRecording(isRecording: true, pendingChunkCount: 0, microphoneAuthorized: false))
    }

    @Test("returns true when pending chunks > 0")
    func pendingChunks() {
        #expect(ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 3, microphoneAuthorized: false))
    }

    @Test("returns true when mic authorized and not recording")
    func micAuthorized() {
        #expect(ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 0, microphoneAuthorized: true))
    }

    @Test("returns false when not recording, no pending, mic not authorized")
    func allFalse() {
        #expect(!ViewHelpers.canToggleRecording(isRecording: false, pendingChunkCount: 0, microphoneAuthorized: false))
    }
}

// MARK: - isInsertTargetStale

@Suite("ViewHelpers.isInsertTargetStale")
struct IsInsertTargetStaleTests {
    @Test("returns false when capturedAt is nil")
    func nilCapturedAt() {
        #expect(!ViewHelpers.isInsertTargetStale(capturedAt: nil, now: Date(), staleAfterSeconds: 90))
    }

    @Test("returns false when within threshold")
    func withinThreshold() {
        let now = Date()
        let captured = now.addingTimeInterval(-30)
        #expect(!ViewHelpers.isInsertTargetStale(capturedAt: captured, now: now, staleAfterSeconds: 90))
    }

    @Test("returns true when exactly at threshold")
    func exactlyAtThreshold() {
        let now = Date()
        let captured = now.addingTimeInterval(-90)
        #expect(ViewHelpers.isInsertTargetStale(capturedAt: captured, now: now, staleAfterSeconds: 90))
    }

    @Test("returns true when past threshold")
    func pastThreshold() {
        let now = Date()
        let captured = now.addingTimeInterval(-120)
        #expect(ViewHelpers.isInsertTargetStale(capturedAt: captured, now: now, staleAfterSeconds: 90))
    }
}

// MARK: - activeInsertTargetStaleAfterSeconds

@Suite("ViewHelpers.activeInsertTargetStaleAfterSeconds")
struct ActiveInsertTargetStaleAfterSecondsTests {
    @Test("returns normal timeout when not fallback")
    func normalTimeout() {
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: false) == 90)
    }

    @Test("returns fallback timeout when fallback")
    func fallbackTimeout() {
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: true) == 30)
    }

    @Test("respects custom normal timeout")
    func customNormal() {
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: false, normalTimeout: 120) == 120)
    }

    @Test("respects custom fallback timeout")
    func customFallback() {
        #expect(ViewHelpers.activeInsertTargetStaleAfterSeconds(usesFallback: true, fallbackTimeout: 15) == 15)
    }
}

// MARK: - isInsertTargetLocked

@Suite("ViewHelpers.isInsertTargetLocked")
struct IsInsertTargetLockedTests {
    @Test("returns true when all conditions met")
    func allTrue() {
        #expect(ViewHelpers.isInsertTargetLocked(hasTranscriptionText: true, canInsertNow: true, canInsertDirectly: true, hasResolvableInsertTarget: true))
    }

    @Test("returns false when no transcription text")
    func noText() {
        #expect(!ViewHelpers.isInsertTargetLocked(hasTranscriptionText: false, canInsertNow: true, canInsertDirectly: true, hasResolvableInsertTarget: true))
    }

    @Test("returns false when cannot insert now")
    func cannotInsertNow() {
        #expect(!ViewHelpers.isInsertTargetLocked(hasTranscriptionText: true, canInsertNow: false, canInsertDirectly: true, hasResolvableInsertTarget: true))
    }

    @Test("returns false when cannot insert directly")
    func cannotInsertDirectly() {
        #expect(!ViewHelpers.isInsertTargetLocked(hasTranscriptionText: true, canInsertNow: true, canInsertDirectly: false, hasResolvableInsertTarget: true))
    }

    @Test("returns false when no resolvable target")
    func noResolvableTarget() {
        #expect(!ViewHelpers.isInsertTargetLocked(hasTranscriptionText: true, canInsertNow: true, canInsertDirectly: true, hasResolvableInsertTarget: false))
    }
}

// MARK: - shouldShowUseCurrentAppQuickAction

@Suite("ViewHelpers.shouldShowUseCurrentAppQuickAction")
struct ShouldShowUseCurrentAppQuickActionTests {
    @Test("returns true when retarget suggested")
    func retargetSuggested() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: true, isInsertTargetStale: false))
    }

    @Test("returns true when target is stale")
    func staleTarget() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: false, isInsertTargetStale: true))
    }

    @Test("returns true when both")
    func both() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: true, isInsertTargetStale: true))
    }

    @Test("returns false when neither")
    func neither() {
        #expect(!ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: false, isInsertTargetStale: false))
    }
}
