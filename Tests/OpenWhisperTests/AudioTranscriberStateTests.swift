import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber – state properties")
struct AudioTranscriberStateTests {

    // MARK: - isStartAfterFinalizeQueued

    @Test("isStartAfterFinalizeQueued mirrors startRecordingAfterFinalizeRequested")
    @MainActor func isStartAfterFinalizeQueued() {
        let t = AudioTranscriber.shared
        // Both should report the same value
        #expect(t.isStartAfterFinalizeQueued == t.startRecordingAfterFinalizeRequestedForTesting)
    }

    // MARK: - inFlightChunkCount

    @Test("inFlightChunkCount is at least pendingChunkCount")
    @MainActor func inFlightChunkCountBaseline() {
        let t = AudioTranscriber.shared
        #expect(t.inFlightChunkCount >= t.pendingChunkCount)
    }

    @Test("inFlightChunkCount is zero when idle")
    @MainActor func inFlightChunkCountIdle() {
        let t = AudioTranscriber.shared
        if !t.isRecording && t.pendingChunkCount == 0 {
            #expect(t.inFlightChunkCount == 0)
        }
    }

    // MARK: - hasActiveSessionForHotkeyCancel

    @Test("hasActiveSessionForHotkeyCancel is false when fully idle")
    @MainActor func hasActiveSessionIdle() {
        let t = AudioTranscriber.shared
        if !t.isRecording && t.pendingChunkCount == 0 && !t.pendingSessionFinalizeForTesting {
            #expect(t.hasActiveSessionForHotkeyCancel == false)
        }
    }

    @Test("hasActiveSessionForHotkeyCancel is true when pendingSessionFinalize is set")
    @MainActor func hasActiveSessionWithPendingFinalize() {
        let t = AudioTranscriber.shared
        let wasPending = t.pendingSessionFinalizeForTesting
        t.setPendingSessionFinalizeForTesting(true)
        #expect(t.hasActiveSessionForHotkeyCancel == true)
        t.setPendingSessionFinalizeForTesting(wasPending)
    }

    // MARK: - isFinalizingTranscription

    @Test("isFinalizingTranscription is false when not recording and no pending chunks")
    @MainActor func isFinalizingIdle() {
        let t = AudioTranscriber.shared
        if !t.isRecording && t.pendingChunkCount == 0 {
            #expect(t.isFinalizingTranscription == false)
        }
    }

    // MARK: - insertionProbeMaxCharacters

    @Test("insertionProbeMaxCharacters is positive")
    func probeMaxChars() {
        #expect(AudioTranscriber.insertionProbeMaxCharacters > 0)
        #expect(AudioTranscriber.insertionProbeMaxCharacters == 120)
    }

    // MARK: - EffectiveOutputSettings defaults

    @Test("defaultOutputSettings returns sensible defaults")
    @MainActor func defaultOutputSettings() {
        let t = AudioTranscriber.shared
        let settings = t.defaultOutputSettings()
        // Should be a valid settings struct
        let _ = settings.autoCopy
        let _ = settings.autoPaste
        let _ = settings.clearAfterInsert
        let _ = settings.commandReplacements
        let _ = settings.smartCapitalization
        let _ = settings.terminalPunctuation
        let _ = settings.customCommandsRaw
    }

    @Test("effectiveOutputSettingsForCurrentApp returns settings")
    @MainActor func effectiveOutputForCurrentApp() {
        let t = AudioTranscriber.shared
        let settings = t.effectiveOutputSettingsForCurrentApp()
        // Should not crash and should return a valid struct
        let _ = settings.autoCopy
    }

    @Test("effectiveOutputSettingsForInsertionTarget returns settings")
    @MainActor func effectiveOutputForInsertionTarget() {
        let t = AudioTranscriber.shared
        let settings = t.effectiveOutputSettingsForInsertionTarget()
        let _ = settings.autoCopy
    }

    // MARK: - isLetter

    @Test("isLetter returns true for letters")
    func isLetterTrue() {
        let t = AudioTranscriber.shared
        #expect(t.isLetter("A") == true)
        #expect(t.isLetter("z") == true)
        #expect(t.isLetter("Ñ") == true)
    }

    @Test("isLetter returns false for non-letters")
    func isLetterFalse() {
        let t = AudioTranscriber.shared
        #expect(t.isLetter("1") == false)
        #expect(t.isLetter(".") == false)
        #expect(t.isLetter(" ") == false)
    }

    // MARK: - replaceRegexTemplate

    @Test("replaceRegexTemplate applies regex with template")
    func replaceRegexTemplate() {
        let t = AudioTranscriber.shared
        let result = t.replaceRegexTemplate(pattern: "(\\w+)@(\\w+)", in: "user@host", withTemplate: "$1 at $2")
        #expect(result == "user at host")
    }

    @Test("replaceRegexTemplate returns original on invalid pattern")
    func replaceRegexTemplateInvalid() {
        let t = AudioTranscriber.shared
        let result = t.replaceRegexTemplate(pattern: "[invalid", in: "hello", withTemplate: "bye")
        #expect(result == "hello")
    }

    // MARK: - resolveOutputSettings with profile override

    @Test("resolveOutputSettings uses profile overrides when present")
    func resolveWithProfile() {
        let t = AudioTranscriber.shared
        let defaults = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: true,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: true,
            smartCapitalization: true,
            terminalPunctuation: true,
            customCommandsRaw: ""
        )

        let profile = AppProfile(
            bundleIdentifier: "com.test.app",
            appName: "TestApp",
            autoCopy: false,
            autoPaste: true,
            clearAfterInsert: true,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false
        )

        let result = t.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(result.autoPaste == true)
    }

    @Test("resolveOutputSettings falls back to defaults without profile")
    func resolveWithoutProfile() {
        let t = AudioTranscriber.shared
        let defaults = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false,
            autoPaste: true,
            clearAfterInsert: true,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommandsRaw: "test"
        )
        let result = t.resolveOutputSettings(defaults: defaults, profile: nil)
        #expect(result.autoCopy == false)
        #expect(result.autoPaste == true)
        #expect(result.clearAfterInsert == true)
    }

    // MARK: - validFileURL

    @Test("validFileURL returns nil for empty path")
    func validFileURLEmpty() {
        let t = AudioTranscriber.shared
        #expect(t.validFileURL(for: "") == nil)
    }

    @Test("validFileURL returns nil for directory")
    func validFileURLDirectory() {
        let t = AudioTranscriber.shared
        #expect(t.validFileURL(for: "/tmp") == nil)
    }

    @Test("validFileURL returns nil for nonexistent file")
    func validFileURLNonexistent() {
        let t = AudioTranscriber.shared
        #expect(t.validFileURL(for: "/nonexistent/file.bin") == nil)
    }

    // MARK: - clearTranscription / clearHistory

    @Test("clearTranscription resets transcription text")
    @MainActor func clearTranscription() {
        let t = AudioTranscriber.shared
        t.clearTranscription()
        #expect(t.transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    @Test("clearHistory empties recentEntries")
    @MainActor func clearHistory() {
        let t = AudioTranscriber.shared
        t.clearHistory()
        #expect(t.recentEntries.isEmpty)
    }
}
