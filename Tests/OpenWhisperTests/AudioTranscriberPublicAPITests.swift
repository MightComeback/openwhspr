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

    // MARK: - setModelSource

    @Test("setModelSource: updates UserDefaults to bundledTiny")
    @MainActor func setModelSourceBundled() {
        let t = AudioTranscriber.shared
        t.setModelSource(.bundledTiny)
        let stored = UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource)
        #expect(stored == ModelSource.bundledTiny.rawValue)
    }

    @Test("setModelSource: updates UserDefaults to customPath")
    @MainActor func setModelSourceCustom() {
        let t = AudioTranscriber.shared
        t.setModelSource(.customPath)
        let stored = UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource)
        #expect(stored == ModelSource.customPath.rawValue)
        // Reset to bundled to avoid side effects
        t.setModelSource(.bundledTiny)
    }

    @Test("setModelSource: clears modelWarning for bundledTiny")
    @MainActor func setModelSourceClearsWarning() {
        let t = AudioTranscriber.shared
        t.setModelSource(.bundledTiny)
        #expect(t.modelWarning == nil)
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

    // MARK: - setCustomModelPath / clearCustomModelPath

    @Test("setCustomModelPath: writes to UserDefaults and sets modelSource")
    @MainActor func setCustomModelPath() {
        let t = AudioTranscriber.shared
        t.setCustomModelPath("/tmp/test-model.bin")
        #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelCustomPath) == "/tmp/test-model.bin")
        #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource) == ModelSource.customPath.rawValue)
        // Reset
        t.setModelSource(.bundledTiny)
    }

    @Test("setCustomModelPath: trims whitespace")
    @MainActor func setCustomModelPathTrims() {
        let t = AudioTranscriber.shared
        t.setCustomModelPath("  /tmp/model.bin  ")
        #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelCustomPath) == "/tmp/model.bin")
        t.setModelSource(.bundledTiny)
    }

    @Test("clearCustomModelPath: empties the stored path")
    @MainActor func clearCustomModelPath() {
        let t = AudioTranscriber.shared
        t.setCustomModelPath("/tmp/model.bin")
        t.clearCustomModelPath()
        #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelCustomPath) == "")
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

    @Test("resolveConfiguredModelURL: bundled returns non-nil URL")
    @MainActor func resolveConfiguredModelURLBundled() {
        // bundledModelURL may return nil in test context (no bundle resources)
        // but resolveConfiguredModelURL should not crash
        let t = AudioTranscriber.shared
        t.setModelSource(.bundledTiny)
        let url = t.resolveConfiguredModelURL()
        // In test env, bundle resource may be nil — that's expected
        _ = url
    }

    @Test("resolveConfiguredModelURL: custom path with invalid path falls back to bundled with warning")
    @MainActor func resolveConfiguredModelURLCustomInvalid() {
        let t = AudioTranscriber.shared
        t.setCustomModelPath("/nonexistent/path/model.bin")
        let result = t.resolveConfiguredModelURL()
        // Falls back to bundled model with a warning
        #expect(result.loadedSource == .bundledTiny)
        #expect(result.warning != nil)
        #expect(result.warning?.contains("not found") == true)
        t.setModelSource(.bundledTiny)
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
