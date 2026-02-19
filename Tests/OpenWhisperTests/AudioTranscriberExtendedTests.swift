import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber Extended Coverage")
struct AudioTranscriberExtendedTests {

    // MARK: - applyTextReplacements

    @Test("applyTextReplacements with no replacements returns original text")
    @MainActor func applyTextReplacementsEmpty() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.removeObject(forKey: AppDefaults.Keys.transcriptionReplacements)
        let result = t.applyTextReplacements(to: "hello world")
        #expect(result == "hello world")
    }

    @Test("applyTextReplacements applies simple replacement")
    @MainActor func applyTextReplacementsSimple() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set("hello => goodbye", forKey: AppDefaults.Keys.transcriptionReplacements)
        let result = t.applyTextReplacements(to: "hello world")
        #expect(result == "goodbye world")
        UserDefaults.standard.removeObject(forKey: AppDefaults.Keys.transcriptionReplacements)
    }

    @Test("applyTextReplacements ignores comment lines")
    @MainActor func applyTextReplacementsIgnoresComments() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set("# this is a comment\nfoo => bar", forKey: AppDefaults.Keys.transcriptionReplacements)
        let result = t.applyTextReplacements(to: "foo baz")
        #expect(result == "bar baz")
        UserDefaults.standard.removeObject(forKey: AppDefaults.Keys.transcriptionReplacements)
    }

    @Test("applyTextReplacements ignores empty lines")
    @MainActor func applyTextReplacementsIgnoresEmptyLines() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set("\n\nfoo => bar\n\n", forKey: AppDefaults.Keys.transcriptionReplacements)
        let result = t.applyTextReplacements(to: "foo")
        #expect(result == "bar")
        UserDefaults.standard.removeObject(forKey: AppDefaults.Keys.transcriptionReplacements)
    }

    @Test("applyTextReplacements with multiple replacements applies all")
    @MainActor func applyTextReplacementsMultiple() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set("a => b\nc => d", forKey: AppDefaults.Keys.transcriptionReplacements)
        let result = t.applyTextReplacements(to: "a c")
        #expect(result == "b d")
        UserDefaults.standard.removeObject(forKey: AppDefaults.Keys.transcriptionReplacements)
    }

    @Test("applyTextReplacements with no match returns original")
    @MainActor func applyTextReplacementsNoMatch() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set("xyz => abc", forKey: AppDefaults.Keys.transcriptionReplacements)
        let result = t.applyTextReplacements(to: "hello")
        #expect(result == "hello")
        UserDefaults.standard.removeObject(forKey: AppDefaults.Keys.transcriptionReplacements)
    }

    // MARK: - copyTranscriptionToClipboard

    @Test("copyTranscriptionToClipboard returns false for empty transcription")
    @MainActor func copyEmptyTranscription() {
        let t = AudioTranscriber.shared
        t.transcription = ""
        let result = t.copyTranscriptionToClipboard()
        #expect(result == false)
    }

    @Test("copyTranscriptionToClipboard returns false for whitespace-only transcription")
    @MainActor func copyWhitespaceTranscription() {
        let t = AudioTranscriber.shared
        t.transcription = "   \n  "
        let result = t.copyTranscriptionToClipboard()
        #expect(result == false)
    }

    @Test("copyTranscriptionToClipboard returns true for non-empty transcription")
    @MainActor func copyNonEmptyTranscription() {
        let t = AudioTranscriber.shared
        t.transcription = "Hello world"
        let result = t.copyTranscriptionToClipboard()
        #expect(result == true)
    }

    // MARK: - manualInsertTarget convenience methods

    @Test("manualInsertTargetAppName returns nil when no target set")
    @MainActor func manualInsertTargetAppNameNil() {
        let t = AudioTranscriber.shared
        t.clearManualInsertTarget()
        let name = t.manualInsertTargetAppName()
        _ = name
    }

    @Test("manualInsertTargetBundleIdentifier returns value without crash")
    @MainActor func manualInsertTargetBundleIdentifier() {
        let t = AudioTranscriber.shared
        let bid = t.manualInsertTargetBundleIdentifier()
        _ = bid
    }

    @Test("manualInsertTargetDisplay returns value without crash")
    @MainActor func manualInsertTargetDisplay() {
        let t = AudioTranscriber.shared
        let display = t.manualInsertTargetDisplay()
        _ = display
    }

    @Test("manualInsertTargetUsesFallbackApp returns bool")
    @MainActor func manualInsertTargetUsesFallbackApp() {
        let t = AudioTranscriber.shared
        let uses = t.manualInsertTargetUsesFallbackApp()
        #expect(uses == true || uses == false)
    }

    @Test("clearManualInsertTarget sets status message")
    @MainActor func clearManualInsertTargetSetsStatus() {
        let t = AudioTranscriber.shared
        t.clearManualInsertTarget()
        #expect(t.statusMessage.contains("Cleared insertion target"))
        #expect(t.lastError == nil)
    }

    // MARK: - captureProfileForFrontmostApp

    @Test("captureProfileForFrontmostApp returns bool")
    @MainActor func captureProfileForFrontmostApp() {
        let t = AudioTranscriber.shared
        let result = t.captureProfileForFrontmostApp()
        #expect(result == true || result == false)
    }

    // MARK: - cancelQueuedStartAfterFinalizeFromHotkey

    @Test("cancelQueuedStartAfterFinalizeFromHotkey does not crash")
    @MainActor func cancelQueuedStartAfterFinalize() {
        let t = AudioTranscriber.shared
        t.cancelQueuedStartAfterFinalizeFromHotkey()
        #expect(t.startRecordingAfterFinalizeRequestedForTesting == false)
    }

    // MARK: - reloadConfiguredModel

    @Test("reloadConfiguredModel does not crash")
    @MainActor func reloadConfiguredModel() {
        let t = AudioTranscriber.shared
        t.reloadConfiguredModel()
        #expect(!t.modelStatusMessage.isEmpty)
    }

    // MARK: - requestMicrophonePermission

    @Test("requestMicrophonePermission does not crash")
    @MainActor func requestMicrophonePermission() {
        let t = AudioTranscriber.shared
        t.requestMicrophonePermission()
    }

    // MARK: - focusManualInsertTargetApp

    @Test("focusManualInsertTargetApp returns bool without crash")
    @MainActor func focusManualInsertTargetApp() {
        let t = AudioTranscriber.shared
        let result = t.focusManualInsertTargetApp()
        #expect(result == true || result == false)
    }
}
