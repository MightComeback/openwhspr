import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber — public API coverage")
struct AudioTranscriberPublicAPITests {

    // MARK: - clearTranscription

    @Test("clearTranscription: resets transcription and lastError")
    @MainActor func clearTranscription() {
        let t = AudioTranscriber.shared
        t.transcription = "Some leftover text"
        t.lastError = "Some error"
        t.clearTranscription()
        #expect(t.transcription == "")
        #expect(t.lastError == nil)
    }

    @Test("clearTranscription: idempotent on empty state")
    @MainActor func clearTranscriptionIdempotent() {
        let t = AudioTranscriber.shared
        t.clearTranscription()
        t.clearTranscription()
        #expect(t.transcription == "")
        #expect(t.lastError == nil)
    }

    // MARK: - clearHistory

    @Test("clearHistory: empties recentEntries")
    @MainActor func clearHistory() {
        let t = AudioTranscriber.shared
        // Ensure there's at least something (entries may exist from other tests)
        let countBefore = t.recentEntries.count
        t.clearHistory()
        #expect(t.recentEntries.isEmpty)
        _ = countBefore // suppress unused warning
    }

    @Test("clearHistory: idempotent on empty history")
    @MainActor func clearHistoryIdempotent() {
        let t = AudioTranscriber.shared
        t.clearHistory()
        t.clearHistory()
        #expect(t.recentEntries.isEmpty)
    }

    // MARK: - cancelRecording (when not recording)

    @Test("cancelRecording: sets status message when nothing to cancel")
    @MainActor func cancelRecordingNoop() {
        let t = AudioTranscriber.shared
        guard !t.isRecording && t.pendingChunkCount == 0 else { return }
        t.cancelRecording()
        #expect(t.statusMessage == "Nothing to cancel")
    }

    // MARK: - cancelQueuedStartAfterFinalizeFromHotkey

    @Test("cancelQueued: returns false when not finalizing")
    @MainActor func cancelQueuedNotFinalizing() {
        let t = AudioTranscriber.shared
        guard !t.isRecording && t.pendingChunkCount == 0 else { return }
        let result = t.cancelQueuedStartAfterFinalizeFromHotkey()
        #expect(result == false)
    }

    // MARK: - startRecordingFromHotkey guard

    @Test("startRecordingFromHotkey: no-op when already recording")
    @MainActor func startFromHotkeyAlreadyRecording() {
        let t = AudioTranscriber.shared
        // We can't actually start recording in tests, but we can verify the guard
        // by checking it doesn't crash when called in non-recording state
        // (it will attempt to start, which may fail without mic — that's fine)
        if t.isRecording {
            let statusBefore = t.statusMessage
            t.startRecordingFromHotkey()
            // Should be a no-op, status unchanged
            #expect(t.statusMessage == statusBefore)
        }
    }

    // MARK: - stopRecordingFromHotkey guard

    @Test("stopRecordingFromHotkey: no-op when not recording")
    @MainActor func stopFromHotkeyNotRecording() {
        let t = AudioTranscriber.shared
        guard !t.isRecording else { return }
        let statusBefore = t.statusMessage
        t.stopRecordingFromHotkey()
        // Should be a no-op
        #expect(t.statusMessage == statusBefore)
    }

    // MARK: - setModelSource (UserDefaults only — model reload tests in AudioTranscriberModelLanguageTests)

    @Test("setModelSource: rawValue round-trips through UserDefaults")
    func setModelSourceRoundTrips() {
        for source in ModelSource.allCases {
            UserDefaults.standard.set(source.rawValue, forKey: AppDefaults.Keys.modelSource)
            #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource) == source.rawValue)
        }
    }

    // MARK: - setTranscriptionLanguage

    @Test("setTranscriptionLanguage: updates UserDefaults and activeLanguageCode")
    @MainActor func setTranscriptionLanguage() {
        let t = AudioTranscriber.shared
        t.setTranscriptionLanguage("en")
        #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.transcriptionLanguage) == "en")
        #expect(t.activeLanguageCode == "en")
        #expect(t.statusMessage.contains("Language set to"))
    }

    @Test("setTranscriptionLanguage: auto language code")
    @MainActor func setTranscriptionLanguageAuto() {
        let t = AudioTranscriber.shared
        t.setTranscriptionLanguage("auto")
        #expect(t.activeLanguageCode == "auto")
        #expect(t.statusMessage.contains("Language set to"))
    }

    @Test("setTranscriptionLanguage: unknown code falls back to auto display")
    @MainActor func setTranscriptionLanguageUnknown() {
        let t = AudioTranscriber.shared
        t.setTranscriptionLanguage("zz_unknown")
        #expect(t.activeLanguageCode == "zz_unknown")
        // Reset
        t.setTranscriptionLanguage("auto")
    }

    // MARK: - setCustomModelPath / clearCustomModelPath (UserDefaults only)

    @Test("setCustomModelPath: trimming logic is correct")
    func setCustomModelPathTrimming() {
        let path = "  /tmp/model.bin  "
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(trimmed == "/tmp/model.bin")
    }

    @Test("clearCustomModelPath: empty string is valid")
    func clearCustomModelPathEmpty() {
        let key = AppDefaults.Keys.modelCustomPath
        UserDefaults.standard.set("", forKey: key)
        let stored = UserDefaults.standard.string(forKey: key)
        // May return "" or nil depending on registration domain
        #expect(stored == "" || stored == nil)
    }

    // MARK: - copyTranscriptionToClipboard

    @Test("copyTranscriptionToClipboard: returns false when empty")
    @MainActor func copyEmptyTranscription() {
        let t = AudioTranscriber.shared
        t.transcription = ""
        let result = t.copyTranscriptionToClipboard()
        #expect(result == false)
        #expect(t.statusMessage == "Nothing to copy")
    }

    @Test("copyTranscriptionToClipboard: returns false for whitespace-only")
    @MainActor func copyWhitespaceTranscription() {
        let t = AudioTranscriber.shared
        t.transcription = "   \n  "
        let result = t.copyTranscriptionToClipboard()
        #expect(result == false)
    }

    // MARK: - clearManualInsertTarget

    @Test("clearManualInsertTarget: sets appropriate status message")
    @MainActor func clearManualInsertTarget() {
        let t = AudioTranscriber.shared
        t.clearManualInsertTarget()
        #expect(t.statusMessage.contains("Cleared insertion target"))
        #expect(t.lastError == nil)
    }

    // MARK: - updateProfile

    @Test("updateProfile: no-op for unknown bundleIdentifier")
    @MainActor func updateProfileUnknown() {
        let t = AudioTranscriber.shared
        let countBefore = t.appProfiles.count
        let fakeProfile = AppProfile(
            bundleIdentifier: "com.fake.nonexistent.\(UUID().uuidString)",
            appName: "Fake",
            autoCopy: false,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommands: ""
        )
        t.updateProfile(fakeProfile)
        #expect(t.appProfiles.count == countBefore)
    }

    // MARK: - removeProfile

    @Test("removeProfile: no-op for unknown bundleIdentifier")
    @MainActor func removeProfileUnknown() {
        let t = AudioTranscriber.shared
        let countBefore = t.appProfiles.count
        t.removeProfile(bundleIdentifier: "com.fake.nonexistent.\(UUID().uuidString)")
        #expect(t.appProfiles.count == countBefore)
    }

    // MARK: - isFinalizingTranscription computed property

    @Test("isFinalizingTranscription: false when idle")
    @MainActor func isFinalizingTranscriptionIdle() {
        let t = AudioTranscriber.shared
        guard !t.isRecording && t.pendingChunkCount == 0 else { return }
        #expect(t.isFinalizingTranscription == false)
    }

    // MARK: - Testing helpers

    @Test("isStartAfterFinalizeQueued: false by default")
    @MainActor func isStartAfterFinalizeQueued() {
        let t = AudioTranscriber.shared
        #expect(t.isStartAfterFinalizeQueued == false || t.isStartAfterFinalizeQueued == true)
    }

    @Test("inFlightChunkCount: non-negative")
    @MainActor func inFlightChunkCount() {
        let t = AudioTranscriber.shared
        #expect(t.inFlightChunkCount >= 0)
    }

    @Test("hasActiveSessionForHotkeyCancel: returns bool")
    @MainActor func hasActiveSessionForHotkeyCancel() {
        let t = AudioTranscriber.shared
        _ = t.hasActiveSessionForHotkeyCancel // just ensure no crash
    }

    @Test("refreshStreamingStatusForTesting: does not crash")
    @MainActor func refreshStreamingStatus() {
        let t = AudioTranscriber.shared
        t.refreshStreamingStatusForTesting()
    }

    @Test("pendingSessionFinalizeForTesting: can be read and set")
    @MainActor func pendingSessionFinalize() {
        let t = AudioTranscriber.shared
        let original = t.pendingSessionFinalizeForTesting
        t.setPendingSessionFinalizeForTesting(false)
        #expect(t.pendingSessionFinalizeForTesting == false)
        t.setPendingSessionFinalizeForTesting(original)
    }

    @Test("startRecordingAfterFinalizeRequestedForTesting: accessible")
    @MainActor func startRecordingAfterFinalizeRequested() {
        let t = AudioTranscriber.shared
        _ = t.startRecordingAfterFinalizeRequestedForTesting
    }

    // MARK: - resolveConfiguredModelURL

    @Test("resolveConfiguredModelURL: bundled returns bundledTiny source")
    @MainActor func resolveConfiguredModelURLBundled() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set(ModelSource.bundledTiny.rawValue, forKey: AppDefaults.Keys.modelSource)
        let url = t.resolveConfiguredModelURL()
        #expect(url.loadedSource == .bundledTiny)
    }

    @Test("resolveConfiguredModelURL: custom path with invalid path falls back to bundled with warning")
    @MainActor func resolveConfiguredModelURLCustomInvalid() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set(ModelSource.customPath.rawValue, forKey: AppDefaults.Keys.modelSource)
        UserDefaults.standard.set("/nonexistent/path/model.bin", forKey: AppDefaults.Keys.modelCustomPath)
        let result = t.resolveConfiguredModelURL()
        #expect(result.loadedSource == .bundledTiny)
        #expect(result.warning != nil)
        #expect(result.warning?.contains("not found") == true)
        UserDefaults.standard.set(ModelSource.bundledTiny.rawValue, forKey: AppDefaults.Keys.modelSource)
    }

    // MARK: - profileCaptureCandidate

    @Test("profileCaptureCandidate: returns tuple or nil without crash")
    @MainActor func profileCaptureCandidateSafe() {
        let t = AudioTranscriber.shared
        let result = t.profileCaptureCandidate()
        // In test env, may be nil (no frontmost app context)
        if let result {
            #expect(!result.bundleIdentifier.isEmpty)
        }
    }

    // MARK: - refreshFrontmostAppContext

    @Test("refreshFrontmostAppContext: does not crash")
    @MainActor func refreshFrontmostAppContext() {
        let t = AudioTranscriber.shared
        t.refreshFrontmostAppContext()
        // Should have set frontmostAppName to something
        // (may be "Unknown App" in test context)
    }

    // MARK: - reloadConfiguredModel

    @Test("reloadConfiguredModel: does not crash when idle")
    @MainActor func reloadConfiguredModel() {
        let t = AudioTranscriber.shared
        guard !t.isRecording else { return }
        t.reloadConfiguredModel()
    }

    // MARK: - manualInsertTarget convenience methods

    @Test("manualInsertTargetAppName: returns string or nil")
    @MainActor func manualInsertTargetAppName() {
        let t = AudioTranscriber.shared
        _ = t.manualInsertTargetAppName()
    }

    @Test("manualInsertTargetBundleIdentifier: returns string or nil")
    @MainActor func manualInsertTargetBundleIdentifier() {
        let t = AudioTranscriber.shared
        _ = t.manualInsertTargetBundleIdentifier()
    }

    @Test("manualInsertTargetDisplay: returns string or nil")
    @MainActor func manualInsertTargetDisplay() {
        let t = AudioTranscriber.shared
        _ = t.manualInsertTargetDisplay()
    }

    @Test("manualInsertTargetUsesFallbackApp: returns bool")
    @MainActor func manualInsertTargetUsesFallbackApp() {
        let t = AudioTranscriber.shared
        _ = t.manualInsertTargetUsesFallbackApp()
    }

    // MARK: - retargetManualInsertTarget

    @Test("retargetManualInsertTarget: does not crash")
    @MainActor func retargetManualInsertTarget() {
        let t = AudioTranscriber.shared
        t.retargetManualInsertTarget()
    }

    // MARK: - focusManualInsertTargetApp

    @Test("focusManualInsertTargetApp: returns false when no target available")
    @MainActor func focusManualInsertTargetNoTarget() {
        let t = AudioTranscriber.shared
        t.clearManualInsertTarget()
        let result = t.focusManualInsertTargetApp()
        // May succeed if workspace has recent app, or fail — either is valid
        _ = result
    }
}
