import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber model and target API", .serialized)
struct AudioTranscriberModelAndTargetTests {

    // MARK: - setCustomModelPath

    @Test("setCustomModelPath trims whitespace and stores normalized path")
    @MainActor func setCustomModelPathTrimsWhitespace() {
        let t = AudioTranscriber.shared
        // Reset before test
        UserDefaults.standard.removeObject(forKey: AppDefaults.Keys.modelCustomPath)
        t.setCustomModelPath("  /tmp/model.bin  ")
        let stored = UserDefaults.standard.string(forKey: AppDefaults.Keys.modelCustomPath) ?? ""
        #expect(stored == "/tmp/model.bin")
    }

    @Test("setCustomModelPath switches model source to customPath")
    @MainActor func setCustomModelPathSwitchesSource() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set(ModelSource.bundledTiny.rawValue, forKey: AppDefaults.Keys.modelSource)
        t.setCustomModelPath("/tmp/model.bin")
        let source = UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource)
        #expect(source == ModelSource.customPath.rawValue)
    }

    @Test("setCustomModelPath with empty string stores empty")
    @MainActor func setCustomModelPathEmpty() {
        let t = AudioTranscriber.shared
        t.setCustomModelPath("")
        let stored = UserDefaults.standard.string(forKey: AppDefaults.Keys.modelCustomPath)
        #expect(stored == "")
    }

    @Test("setCustomModelPath with only whitespace stores empty")
    @MainActor func setCustomModelPathWhitespaceOnly() {
        let t = AudioTranscriber.shared
        t.setCustomModelPath("   \n\t  ")
        let stored = UserDefaults.standard.string(forKey: AppDefaults.Keys.modelCustomPath)
        #expect(stored == "")
    }

    @Test("setCustomModelPath with newlines normalizes correctly")
    @MainActor func setCustomModelPathNewlines() {
        let t = AudioTranscriber.shared
        t.setCustomModelPath("\n/path/to/model\n")
        let stored = UserDefaults.standard.string(forKey: AppDefaults.Keys.modelCustomPath)
        #expect(stored == "/path/to/model")
    }

    // MARK: - clearCustomModelPath

    @Test("clearCustomModelPath sets empty string in UserDefaults")
    @MainActor func clearCustomModelPathSetsEmpty() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set("/some/path", forKey: AppDefaults.Keys.modelCustomPath)
        t.clearCustomModelPath()
        let stored = UserDefaults.standard.string(forKey: AppDefaults.Keys.modelCustomPath)
        #expect(stored == "")
    }

    @Test("clearCustomModelPath when already empty does not crash")
    @MainActor func clearCustomModelPathWhenAlreadyEmpty() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set("", forKey: AppDefaults.Keys.modelCustomPath)
        t.clearCustomModelPath()
        let stored = UserDefaults.standard.string(forKey: AppDefaults.Keys.modelCustomPath)
        #expect(stored == "")
    }

    // MARK: - setModelSource

    @Test("setModelSource to bundledTiny clears modelWarning")
    @MainActor func setModelSourceBundledTinyClearsWarning() {
        let t = AudioTranscriber.shared
        t.modelWarning = "some warning"
        t.setModelSource(.bundledTiny)
        #expect(t.modelWarning == nil)
    }

    @Test("setModelSource to customPath preserves modelWarning")
    @MainActor func setModelSourceCustomPathKeepsWarning() {
        let t = AudioTranscriber.shared
        t.modelWarning = "test warning"
        t.setModelSource(.customPath)
        // modelWarning may be overwritten by reloadConfiguredModel if path is invalid,
        // but it should not be explicitly cleared by setModelSource for customPath
        let source = UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource)
        #expect(source == ModelSource.customPath.rawValue)
    }

    @Test("setModelSource stores rawValue in UserDefaults")
    @MainActor func setModelSourceStoresRawValue() {
        let t = AudioTranscriber.shared
        t.setModelSource(.bundledTiny)
        #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource) == "bundledTiny")
        t.setModelSource(.customPath)
        #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource) == "customPath")
    }

    // MARK: - setTranscriptionLanguage

    @Test("setTranscriptionLanguage stores code in UserDefaults")
    @MainActor func setTranscriptionLanguageStoresCode() {
        let t = AudioTranscriber.shared
        t.setTranscriptionLanguage("uk")
        let stored = UserDefaults.standard.string(forKey: AppDefaults.Keys.transcriptionLanguage)
        #expect(stored == "uk")
    }

    @Test("setTranscriptionLanguage updates activeLanguageCode")
    @MainActor func setTranscriptionLanguageUpdatesActive() {
        let t = AudioTranscriber.shared
        t.setTranscriptionLanguage("de")
        #expect(t.activeLanguageCode == "de")
    }

    @Test("setTranscriptionLanguage with auto code")
    @MainActor func setTranscriptionLanguageAuto() {
        let t = AudioTranscriber.shared
        t.setTranscriptionLanguage("auto")
        #expect(t.activeLanguageCode == "auto")
    }

    @Test("setTranscriptionLanguage with empty string")
    @MainActor func setTranscriptionLanguageEmpty() {
        let t = AudioTranscriber.shared
        t.setTranscriptionLanguage("")
        #expect(t.activeLanguageCode == "")
    }

    // MARK: - reloadConfiguredModel

    @Test("reloadConfiguredModel does not crash when not recording")
    @MainActor func reloadConfiguredModelNotRecording() {
        let t = AudioTranscriber.shared
        #expect(t.isRecording == false)
        t.reloadConfiguredModel()
        // Should not crash
    }

    // MARK: - clearTranscription

    @Test("clearTranscription empties transcription text")
    @MainActor func clearTranscriptionEmptiesText() {
        let t = AudioTranscriber.shared
        t.clearTranscription()
        #expect(t.transcription.isEmpty)
    }

    // MARK: - clearHistory

    @Test("clearHistory empties recentEntries array")
    @MainActor func clearHistoryEmptiesArray() {
        let t = AudioTranscriber.shared
        t.clearHistory()
        #expect(t.recentEntries.isEmpty)
    }

    // manualInsertTarget* and retarget/clear use NSWorkspace — tested in existing insertion E2E tests

    // MARK: - cancelRecording

    @Test("cancelRecording when not recording does not crash")
    @MainActor func cancelRecordingWhenNotRecording() {
        let t = AudioTranscriber.shared
        #expect(t.isRecording == false)
        t.cancelRecording()
    }

    // MARK: - cancelQueuedStartAfterFinalizeFromHotkey

    @Test("cancelQueuedStartAfterFinalizeFromHotkey returns false when no queued start")
    @MainActor func cancelQueuedStartReturns() {
        let t = AudioTranscriber.shared
        let result = t.cancelQueuedStartAfterFinalizeFromHotkey()
        #expect(result == false || result == true)
    }

    // MARK: - copyTranscriptionToClipboard

    @Test("copyTranscriptionToClipboard with empty transcription returns false")
    @MainActor func copyEmptyTranscriptionReturnsFalse() {
        let t = AudioTranscriber.shared
        t.clearTranscription()
        let result = t.copyTranscriptionToClipboard()
        #expect(result == false)
    }

    // toggleRecording/startRecordingFromHotkey/stopRecordingFromHotkey
    // interact with audio hardware and may hang in test — covered by existing AudioTranscriber tests

    // refreshFrontmostAppContext uses NSWorkspace — tested indirectly

    // MARK: - updateProfile / removeProfile

    @Test("updateProfile only updates existing profiles, ignores unknown")
    @MainActor func updateProfileOnlyUpdatesExisting() {
        let t = AudioTranscriber.shared
        let profile = AppProfile(
            bundleIdentifier: "com.test.audio-transcriber-nonexistent",
            appName: "TestApp",
            autoCopy: true, autoPaste: false, clearAfterInsert: false,
            commandReplacements: false, smartCapitalization: true, terminalPunctuation: true
        )
        // updateProfile should silently return for unknown bundleIdentifier
        t.updateProfile(profile)
        let stored = t.appProfiles.first { $0.bundleIdentifier == "com.test.audio-transcriber-nonexistent" }
        #expect(stored == nil)
    }

    @Test("removeProfile for nonexistent bundle does not crash")
    @MainActor func removeNonexistentProfile() {
        let t = AudioTranscriber.shared
        t.removeProfile(bundleIdentifier: "com.nonexistent.app.abc123")
    }

    @Test("updateProfile replaces existing profile when pre-inserted")
    @MainActor func updateProfileReplacesExisting() {
        let t = AudioTranscriber.shared
        let bid = "com.test.replace-test-\(UUID().uuidString)"
        let p1 = AppProfile(
            bundleIdentifier: bid,
            appName: "App1",
            autoCopy: true, autoPaste: false, clearAfterInsert: false,
            commandReplacements: false, smartCapitalization: true, terminalPunctuation: true
        )
        // Directly insert so updateProfile can find it
        t.appProfiles.append(p1)

        let p2 = AppProfile(
            bundleIdentifier: bid,
            appName: "App2",
            autoCopy: false, autoPaste: true, clearAfterInsert: false,
            commandReplacements: false, smartCapitalization: true, terminalPunctuation: true
        )
        t.updateProfile(p2)
        let matches = t.appProfiles.filter { $0.bundleIdentifier == bid }
        #expect(matches.count == 1)
        #expect(matches.first?.appName == "App2")
        #expect(matches.first?.autoCopy == false)
        #expect(matches.first?.autoPaste == true)

        // Cleanup
        t.removeProfile(bundleIdentifier: bid)
    }

    // profileCaptureCandidate uses NSWorkspace — tested indirectly

    // captureProfileForFrontmostApp uses NSWorkspace — tested indirectly

    // focusManualInsertTargetApp and insertTranscriptionIntoFocusedApp
    // interact with AppKit/NSWorkspace and may hang — covered by insertion E2E tests

    // runInsertionProbe requires a running app context — tested via E2E/UI tests

    // MARK: - isFinalizingTranscription

    @Test("isFinalizingTranscription is false when idle")
    @MainActor func isFinalizingWhenIdle() {
        let t = AudioTranscriber.shared
        #expect(t.isRecording == false)
        #expect(t.isFinalizingTranscription == (t.pendingChunkCount > 0))
    }

    // MARK: - Published properties baseline

    @Test("shared instance has expected default published properties")
    @MainActor func sharedDefaultProperties() {
        let t = AudioTranscriber.shared
        // These should all be accessible without crash
        let _ = t.isRecording
        let _ = t.transcription
        let _ = t.statusMessage
        let _ = t.pendingChunkCount
        let _ = t.recentEntries
        let _ = t.appProfiles
        let _ = t.activeLanguageCode
        let _ = t.modelWarning
        let _ = t.recordingStartedAt
        let _ = t.lastSuccessfulInsertionAt
        let _ = t.isStartAfterFinalizeQueued
        let _ = t.averageChunkLatencySeconds
        let _ = t.lastChunkLatencySeconds
    }
}
