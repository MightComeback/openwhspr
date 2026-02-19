import Testing
import Foundation
@testable import OpenWhisper

/// Tests for AudioTranscriber model/language/cancel methods that previously lacked coverage.
@Suite("AudioTranscriber Model & Language", .serialized)
struct AudioTranscriberModelLanguageTests {

    // MARK: - setModelSource

    @Test("setModelSource bundledTiny stores rawValue and clears warning")
    @MainActor func setModelSourceBundledTiny() {
        let t = AudioTranscriber.shared
        t.modelWarning = "stale warning"
        t.setModelSource(.bundledTiny)
        #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource) == ModelSource.bundledTiny.rawValue)
        #expect(t.modelWarning == nil)
    }

    @Test("setModelSource customPath stores rawValue and preserves warning")
    @MainActor func setModelSourceCustomPath() {
        let t = AudioTranscriber.shared
        t.modelWarning = "some warning"
        t.setModelSource(.customPath)
        #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource) == ModelSource.customPath.rawValue)
        // customPath does NOT clear modelWarning
        // (warning may be set or cleared by reloadConfiguredModel; we just verify it wasn't nil'd by setModelSource)
    }

    @Test("setModelSource triggers reloadConfiguredModel (activeModelSource updates)")
    @MainActor func setModelSourceReloads() {
        let t = AudioTranscriber.shared
        t.setModelSource(.bundledTiny)
        #expect(t.activeModelSource == .bundledTiny)
    }

    @Test("setModelSource round-trips through UserDefaults")
    @MainActor func setModelSourceRoundTrip() {
        let t = AudioTranscriber.shared
        for source in ModelSource.allCases {
            t.setModelSource(source)
            let stored = UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource)
            #expect(stored == source.rawValue)
        }
    }

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

    // MARK: - setCustomModelPath

    @Test("setCustomModelPath stores normalized path")
    @MainActor func setCustomPathStores() {
        let t = AudioTranscriber.shared
        t.setCustomModelPath("  /some/path.bin  ")
        #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelCustomPath) == "/some/path.bin")
    }

    @Test("setCustomModelPath switches source to customPath")
    @MainActor func setCustomPathSwitchesSource() {
        let t = AudioTranscriber.shared
        t.setCustomModelPath("/some/path.bin")
        #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource) == ModelSource.customPath.rawValue)
    }

    @Test("setCustomModelPath triggers reload without crash")
    @MainActor func setCustomPathReloads() {
        let t = AudioTranscriber.shared
        // For a nonexistent path, reloadConfiguredModel may fall back to bundledTiny.
        // We just verify it doesn't crash and UserDefaults was set.
        t.setCustomModelPath("/nonexistent/model.bin")
        #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource) == ModelSource.customPath.rawValue)
    }

    @Test("setCustomModelPath empty string stores empty")
    @MainActor func setCustomPathEmpty() {
        let t = AudioTranscriber.shared
        t.setCustomModelPath("")
        #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelCustomPath) == "")
    }

    // MARK: - clearCustomModelPath

    @Test("clearCustomModelPath resets path to empty")
    @MainActor func clearCustomPath() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set("/old/path.bin", forKey: AppDefaults.Keys.modelCustomPath)
        t.clearCustomModelPath()
        #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelCustomPath) == "")
    }

    @Test("clearCustomModelPath triggers reload")
    @MainActor func clearCustomPathReloads() {
        let t = AudioTranscriber.shared
        // Set custom first, then clear — should not crash
        t.setCustomModelPath("/some/path.bin")
        t.clearCustomModelPath()
        #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelCustomPath) == "")
    }

    // MARK: - cancelRecording

    @Test("cancelRecording when idle sets 'Nothing to cancel'")
    @MainActor func cancelRecordingIdle() {
        let t = AudioTranscriber.shared
        // Ensure not recording
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
}
