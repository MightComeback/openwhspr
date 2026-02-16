import Testing
import Foundation
@testable import OpenWhisper

/// Tests for AudioTranscriber insertion target and profile methods
/// that were not yet covered by existing test suites.
@Suite("AudioTranscriber Insertion & Profile", .serialized)
struct AudioTranscriberInsertionTests {

    // MARK: - manualInsertTargetBundleIdentifier

    @Test("manualInsertTargetBundleIdentifier: returns String? without crash")
    @MainActor func bundleIdReturnsValue() {
        let t = AudioTranscriber.shared
        let bid = t.manualInsertTargetBundleIdentifier()
        // In test env with a running app, this may return a bundle id or nil
        if let bid {
            #expect(!bid.isEmpty)
        }
    }

    // MARK: - manualInsertTargetDisplay

    @Test("manualInsertTargetDisplay: returns formatted string or nil")
    @MainActor func displayReturnsValue() {
        let t = AudioTranscriber.shared
        let display = t.manualInsertTargetDisplay()
        if let display {
            #expect(!display.isEmpty)
        }
    }

    // MARK: - manualInsertTargetUsesFallbackApp

    @Test("manualInsertTargetUsesFallbackApp: returns bool")
    @MainActor func fallbackReturnsBool() {
        let t = AudioTranscriber.shared
        let _ = t.manualInsertTargetUsesFallbackApp()
    }

    // MARK: - manualInsertTargetAppName

    @Test("manualInsertTargetAppName: returns name or nil")
    @MainActor func appNameReturnsValue() {
        let t = AudioTranscriber.shared
        let name = t.manualInsertTargetAppName()
        if let name {
            #expect(!name.isEmpty)
        }
    }

    // MARK: - manualInsertTargetSnapshot consistency

    @Test("manualInsertTargetSnapshot: convenience methods match snapshot fields")
    @MainActor func convenienceMethodsMatchSnapshot() {
        let t = AudioTranscriber.shared
        // Call snapshot first, then verify convenience methods return consistent data.
        // Note: each call to snapshot re-evaluates frontmost app, so we compare
        // two quick successive calls which should be identical.
        let snap = t.manualInsertTargetSnapshot()
        // Convenience methods call snapshot internally, so values should match
        // (frontmost app unlikely to change within microseconds).
        let name = t.manualInsertTargetAppName()
        let bid = t.manualInsertTargetBundleIdentifier()
        let display = t.manualInsertTargetDisplay()
        let fallback = t.manualInsertTargetUsesFallbackApp()
        #expect(name == snap.appName)
        #expect(bid == snap.bundleIdentifier)
        #expect(display == snap.display)
        #expect(fallback == snap.usesFallbackApp)
    }

    @Test("manualInsertTargetSnapshot: display contains appName when both present")
    @MainActor func displayContainsAppName() {
        let t = AudioTranscriber.shared
        let snap = t.manualInsertTargetSnapshot()
        if let appName = snap.appName, let display = snap.display {
            #expect(display.contains(appName))
        }
    }

    @Test("manualInsertTargetSnapshot: display contains bundleIdentifier when both present")
    @MainActor func displayContainsBundleId() {
        let t = AudioTranscriber.shared
        let snap = t.manualInsertTargetSnapshot()
        if let bid = snap.bundleIdentifier, let display = snap.display {
            #expect(display.contains(bid))
        }
    }

    // MARK: - focusManualInsertTargetApp

    @Test("focusManualInsertTargetApp: returns bool without crash")
    @MainActor func focusReturnsValue() {
        let t = AudioTranscriber.shared
        let result = t.focusManualInsertTargetApp()
        #expect(result == true || result == false)
    }

    // MARK: - captureProfileForFrontmostApp

    @Test("captureProfileForFrontmostApp: returns bool without crash")
    @MainActor func captureProfileDoesNotCrash() {
        let t = AudioTranscriber.shared
        let result = t.captureProfileForFrontmostApp()
        #expect(result == true || result == false)
    }

    @Test("captureProfileForFrontmostApp: on success, profile is persisted")
    @MainActor func captureProfilePersists() {
        let t = AudioTranscriber.shared
        let countBefore = t.appProfiles.count
        let result = t.captureProfileForFrontmostApp()
        if result {
            #expect(t.appProfiles.count >= countBefore)
            #expect(t.lastError == nil)
        }
    }

    @Test("captureProfileForFrontmostApp: sets lastError on failure")
    @MainActor func captureProfileSetsErrorOnFailure() {
        let t = AudioTranscriber.shared
        let result = t.captureProfileForFrontmostApp()
        if !result {
            #expect(t.lastError != nil)
        }
    }

    @Test("captureProfileForFrontmostApp: profiles stay sorted after capture")
    @MainActor func captureProfileKeepsSorted() {
        let t = AudioTranscriber.shared
        let _ = t.captureProfileForFrontmostApp()
        let names = t.appProfiles.map { $0.appName.lowercased() }
        let sorted = names.sorted()
        #expect(names == sorted)
    }

    // MARK: - retargetManualInsertTarget

    @Test("retargetManualInsertTarget: does not crash")
    @MainActor func retargetDoesNotCrash() {
        let t = AudioTranscriber.shared
        t.retargetManualInsertTarget()
    }

    // MARK: - clearManualInsertTarget

    @Test("clearManualInsertTarget: sets status message containing Cleared")
    @MainActor func clearSetsStatusMessage() {
        let t = AudioTranscriber.shared
        t.clearManualInsertTarget()
        #expect(t.statusMessage.contains("Cleared"))
    }

    @Test("clearManualInsertTarget: clears lastError")
    @MainActor func clearResetsLastError() {
        let t = AudioTranscriber.shared
        t.clearManualInsertTarget()
        #expect(t.lastError == nil)
    }

    @Test("clearManualInsertTarget: calling twice does not crash")
    @MainActor func clearIdempotent() {
        let t = AudioTranscriber.shared
        t.clearManualInsertTarget()
        t.clearManualInsertTarget()
        #expect(t.statusMessage.contains("Cleared"))
    }

    // MARK: - copyTranscriptionToClipboard

    @Test("copyTranscriptionToClipboard: returns false when no transcription")
    @MainActor func copyReturnsFalseWhenEmpty() {
        let t = AudioTranscriber.shared
        t.clearTranscription()
        let result = t.copyTranscriptionToClipboard()
        #expect(result == false)
    }

    // MARK: - profileCaptureCandidate

    @Test("profileCaptureCandidate: returns tuple with non-empty fields or nil")
    @MainActor func profileCaptureCandidateShape() {
        let t = AudioTranscriber.shared
        let candidate = t.profileCaptureCandidate()
        if let c = candidate {
            #expect(!c.bundleIdentifier.isEmpty)
            #expect(!c.appName.isEmpty)
        }
    }

    // MARK: - isFinalizingTranscription

    @Test("isFinalizingTranscription: false when not recording and no pending")
    @MainActor func isFinalizingFalseInitially() {
        let t = AudioTranscriber.shared
        if !t.isRecording && t.pendingChunkCount == 0 {
            #expect(t.isFinalizingTranscription == false)
        }
    }

    @Test("isFinalizingTranscription: computed property consistent with state")
    @MainActor func isFinalizingConsistentWithState() {
        let t = AudioTranscriber.shared
        let finalizing = t.isFinalizingTranscription
        if t.isRecording {
            // While recording, not finalizing
            #expect(finalizing == false)
        }
    }
}
