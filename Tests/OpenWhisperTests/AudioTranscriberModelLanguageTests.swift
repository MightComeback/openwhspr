import Testing
import Foundation
@testable import OpenWhisper

/// Tests for AudioTranscriber model/language/cancel methods.
/// NOTE: Avoid calling setModelSource / setCustomModelPath / clearCustomModelPath
/// with multiple model reloads in a single suite — Whisper init blocks the main
/// thread and can deadlock when run concurrently or serialized.
@Suite("AudioTranscriber Model & Language")
struct AudioTranscriberModelLanguageTests {

    // MARK: - setTranscriptionLanguage

    @Test("setTranscriptionLanguage stores code in UserDefaults")
    @MainActor func setLanguageStoresDefaults() {
        let t = AudioTranscriber.shared
        t.setTranscriptionLanguage("en")
        #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.transcriptionLanguage) == "en")
    }

    @Test("setTranscriptionLanguage updates activeLanguageCode")
    @MainActor func setLanguageUpdatesActive() {
        let t = AudioTranscriber.shared
        t.setTranscriptionLanguage("de")
        #expect(t.activeLanguageCode == "de")
    }

    @Test("setTranscriptionLanguage updates statusMessage")
    @MainActor func setLanguageUpdatesStatus() {
        let t = AudioTranscriber.shared
        t.setTranscriptionLanguage("fr")
        #expect(t.statusMessage.contains("Language set to"))
    }

    @Test("setTranscriptionLanguage auto is valid")
    @MainActor func setLanguageAuto() {
        let t = AudioTranscriber.shared
        t.setTranscriptionLanguage("auto")
        #expect(t.activeLanguageCode == "auto")
        #expect(t.statusMessage.contains("Language set to"))
    }

    @Test("setTranscriptionLanguage unknown code does not crash")
    @MainActor func setLanguageUnknown() {
        let t = AudioTranscriber.shared
        t.setTranscriptionLanguage("xx")
        #expect(t.activeLanguageCode == "xx")
    }

    // MARK: - cancelRecording

    @Test("cancelRecording when idle sets 'Nothing to cancel'")
    @MainActor func cancelRecordingIdle() {
        let t = AudioTranscriber.shared
        if t.isRecording { return }
        if t.pendingChunkCount > 0 { return }
        t.cancelRecording()
        #expect(t.statusMessage == "Nothing to cancel")
    }

    @Test("cancelRecording does not crash when called multiple times")
    @MainActor func cancelRecordingMultiple() {
        let t = AudioTranscriber.shared
        t.cancelRecording()
        t.cancelRecording()
        t.cancelRecording()
    }

    @Test("cancelRecording resets pending state when finalizing")
    @MainActor func cancelRecordingDuringFinalization() {
        let t = AudioTranscriber.shared
        t.setPendingSessionFinalizeForTesting(true)
        t.cancelRecording()
        #expect(t.pendingChunkCount == 0)
        #expect(t.statusMessage == "Recording discarded")
        #expect(t.pendingSessionFinalizeForTesting == false)
    }

    @Test("cancelRecording clears lastError")
    @MainActor func cancelRecordingClearsError() {
        let t = AudioTranscriber.shared
        t.setPendingSessionFinalizeForTesting(true)
        t.cancelRecording()
        #expect(t.lastError == nil)
    }

    @Test("cancelRecording clears recordingStartedAt")
    @MainActor func cancelRecordingClearsStartedAt() {
        let t = AudioTranscriber.shared
        t.setPendingSessionFinalizeForTesting(true)
        t.cancelRecording()
        #expect(t.recordingStartedAt == nil)
    }

    @Test("cancelRecording resets inputLevel to 0")
    @MainActor func cancelRecordingResetsInputLevel() {
        let t = AudioTranscriber.shared
        t.setPendingSessionFinalizeForTesting(true)
        t.cancelRecording()
        #expect(t.inputLevel == 0)
    }

    @Test("cancelRecording resets startRecordingAfterFinalizeRequested")
    @MainActor func cancelRecordingResetsStartAfterFinalize() {
        let t = AudioTranscriber.shared
        t.setPendingSessionFinalizeForTesting(true)
        t.cancelRecording()
        #expect(t.startRecordingAfterFinalizeRequestedForTesting == false)
    }

    // MARK: - Model source UserDefaults (no reload)

    @Test("ModelSource rawValues write to UserDefaults correctly")
    func modelSourceRawValues() {
        for source in ModelSource.allCases {
            UserDefaults.standard.set(source.rawValue, forKey: AppDefaults.Keys.modelSource)
            let stored = UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource)
            #expect(stored == source.rawValue)
        }
    }

    @Test("Custom model path stores trimmed in UserDefaults")
    func customModelPathTrimmed() {
        let key = AppDefaults.Keys.modelCustomPath
        let path = "  /some/path.bin  "
        UserDefaults.standard.set(path.trimmingCharacters(in: .whitespacesAndNewlines), forKey: key)
        #expect(UserDefaults.standard.string(forKey: key) == "/some/path.bin")
    }

    @Test("clearCustomModelPath empties UserDefaults key")
    func clearCustomModelPathDefaults() {
        let key = AppDefaults.Keys.modelCustomPath
        UserDefaults.standard.set("/old/path.bin", forKey: key)
        UserDefaults.standard.set("", forKey: key)
        #expect(UserDefaults.standard.string(forKey: key) == "")
    }

    // MARK: - resolveConfiguredModelURL (does not trigger full model load)

    @Test("resolveConfiguredModelURL bundled returns bundledTiny source")
    @MainActor func resolveURLBundled() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set(ModelSource.bundledTiny.rawValue, forKey: AppDefaults.Keys.modelSource)
        let result = t.resolveConfiguredModelURL()
        #expect(result.loadedSource == .bundledTiny)
    }

    @Test("resolveConfiguredModelURL custom invalid path falls back with warning")
    @MainActor func resolveURLCustomInvalid() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set(ModelSource.customPath.rawValue, forKey: AppDefaults.Keys.modelSource)
        UserDefaults.standard.set("/nonexistent/path/model.bin", forKey: AppDefaults.Keys.modelCustomPath)
        let result = t.resolveConfiguredModelURL()
        #expect(result.loadedSource == .bundledTiny)
        #expect(result.warning != nil)
        #expect(result.warning?.contains("not found") == true)
        // Restore
        UserDefaults.standard.set(ModelSource.bundledTiny.rawValue, forKey: AppDefaults.Keys.modelSource)
    }

    @Test("resolveConfiguredModelURL custom empty path falls back with warning")
    @MainActor func resolveURLCustomEmpty() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set(ModelSource.customPath.rawValue, forKey: AppDefaults.Keys.modelSource)
        UserDefaults.standard.set("", forKey: AppDefaults.Keys.modelCustomPath)
        let result = t.resolveConfiguredModelURL()
        #expect(result.loadedSource == .bundledTiny)
        #expect(result.warning?.contains("empty") == true)
        UserDefaults.standard.set(ModelSource.bundledTiny.rawValue, forKey: AppDefaults.Keys.modelSource)
    }
}
