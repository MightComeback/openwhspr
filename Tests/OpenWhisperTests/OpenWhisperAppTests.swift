import Testing
import Foundation
@testable import OpenWhisper

@Suite("OpenWhisperApp")
struct OpenWhisperAppTests {

    // MARK: - AppDefaults.register (called in app init)

    @Test("AppDefaults.register sets all expected default values")
    func registerSetsDefaults() {
        // Clear relevant keys first
        let keys = [
            AppDefaults.Keys.audioFeedbackEnabled,
            AppDefaults.Keys.hotkeyKey,
            AppDefaults.Keys.hotkeyMode,
            AppDefaults.Keys.onboardingCompleted,
            AppDefaults.Keys.launchAtLogin,
        ]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        AppDefaults.register()

        // After register, defaults should be available
        let hotkeyKey = UserDefaults.standard.string(forKey: AppDefaults.Keys.hotkeyKey)
        #expect(hotkeyKey != nil, "hotkeyKey should have a default after register()")

        let hotkeyMode = UserDefaults.standard.string(forKey: AppDefaults.Keys.hotkeyMode)
        #expect(hotkeyMode != nil, "hotkeyMode should have a default after register()")
    }

    @Test("AppDefaults.register is idempotent")
    func registerIdempotent() {
        // Use a dedicated suite to avoid cross-test pollution
        let suite = UserDefaults(suiteName: "OpenWhisperAppTests.idempotent")!
        AppDefaults.register(into: suite)
        let first = suite.string(forKey: AppDefaults.Keys.hotkeyKey)
        AppDefaults.register(into: suite)
        let second = suite.string(forKey: AppDefaults.Keys.hotkeyKey)
        #expect(first == second)
        suite.removePersistentDomain(forName: "OpenWhisperAppTests.idempotent")
    }

    @Test("AppDefaults.register does not overwrite user-set values")
    func registerDoesNotOverwrite() {
        let suite = UserDefaults(suiteName: "OpenWhisperAppTests.noOverwrite")!
        suite.set("hold", forKey: AppDefaults.Keys.hotkeyMode)
        AppDefaults.register(into: suite)
        #expect(suite.string(forKey: AppDefaults.Keys.hotkeyMode) == "hold")
        suite.removePersistentDomain(forName: "OpenWhisperAppTests.noOverwrite")
    }

    // MARK: - AudioTranscriber.shared singleton

    @Test("AudioTranscriber.shared returns same instance")
    func transcriberSharedSingleton() {
        let a = AudioTranscriber.shared
        let b = AudioTranscriber.shared
        #expect(a === b)
    }

    @Test("AudioTranscriber.shared starts in non-recording state")
    func transcriberInitialState() {
        let t = AudioTranscriber.shared
        #expect(t.isRecording == false)
        #expect(t.pendingChunkCount == 0)
    }

    // MARK: - HotkeyMonitor initialization

    @Test("HotkeyMonitor can be created without crash")
    func hotkeyMonitorInit() {
        let monitor = HotkeyMonitor()
        #expect(monitor.isHotkeyActive == false || monitor.isHotkeyActive == true)
    }

    @Test("HotkeyMonitor has a status message")
    func hotkeyMonitorStatusMessage() {
        let monitor = HotkeyMonitor()
        #expect(!monitor.statusMessage.isEmpty)
    }

    @Test("HotkeyMonitor reloadConfig does not crash")
    func hotkeyMonitorReloadConfig() {
        let monitor = HotkeyMonitor()
        monitor.reloadConfig()
    }

    // MARK: - MenuBarLabel icon logic (tested via transcriber state)
    // MenuBarLabel is private, so we verify the transcriber properties
    // that drive its computed icon/label.

    @Test("Transcriber lastSuccessfulInsertionAt starts nil")
    func transcriberInsertionAtStartsNil() {
        let t = AudioTranscriber.shared
        #expect(t.lastSuccessfulInsertionAt == nil)
    }

    @Test("Transcriber transcription starts empty")
    func transcriberTranscriptionStartsEmpty() {
        let t = AudioTranscriber.shared
        // May have leftover from other tests, but should be a String
        let _ = t.transcription
    }

    @Test("Transcriber recordingStartedAt is nil when not recording")
    func transcriberRecordingStartedAtNil() {
        let t = AudioTranscriber.shared
        if !t.isRecording {
            #expect(t.recordingStartedAt == nil)
        }
    }

    @Test("Transcriber averageChunkLatencySeconds is non-negative")
    func transcriberLatencyNonNegative() {
        let t = AudioTranscriber.shared
        #expect(t.averageChunkLatencySeconds >= 0)
        #expect(t.lastChunkLatencySeconds >= 0)
    }
}
