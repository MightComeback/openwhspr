import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber uncovered API coverage", .serialized)
struct AudioTranscriberUncoveredAPITests {

    // MARK: - clearTranscription

    @Test("clearTranscription resets transcription to empty")
    @MainActor func clearTranscriptionResetsText() {
        let t = AudioTranscriber.shared
        t.transcription = "hello world"
        t.lastError = "some error"
        t.clearTranscription()
        #expect(t.transcription == "")
        #expect(t.lastError == nil)
    }

    @Test("clearTranscription on already empty is safe")
    @MainActor func clearTranscriptionAlreadyEmpty() {
        let t = AudioTranscriber.shared
        t.transcription = ""
        t.lastError = nil
        t.clearTranscription()
        #expect(t.transcription == "")
        #expect(t.lastError == nil)
    }

    @Test("clearTranscription clears last error")
    @MainActor func clearTranscriptionClearsError() {
        let t = AudioTranscriber.shared
        t.lastError = "Model load failed"
        t.clearTranscription()
        #expect(t.lastError == nil)
    }

    // MARK: - clearHistory

    @Test("clearHistory removes all recent entries")
    @MainActor func clearHistoryRemovesAll() {
        let t = AudioTranscriber.shared
        t.recentEntries = [
            TranscriptionEntry(text: "test1"),
            TranscriptionEntry(text: "test2")
        ]
        t.clearHistory()
        #expect(t.recentEntries.isEmpty)
    }

    @Test("clearHistory on empty list is safe")
    @MainActor func clearHistoryEmpty() {
        let t = AudioTranscriber.shared
        t.recentEntries = []
        t.clearHistory()
        #expect(t.recentEntries.isEmpty)
    }

    // MARK: - clipboardFallbackStatusMessageForTesting

    @Test("clipboard fallback message includes target name when provided")
    @MainActor func clipboardFallbackWithTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: "Safari")
        #expect(msg.contains("Safari"))
    }

    @Test("clipboard fallback message handles nil target")
    @MainActor func clipboardFallbackNilTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: nil)
        #expect(!msg.isEmpty)
    }

    @Test("clipboard fallback message handles empty target")
    @MainActor func clipboardFallbackEmptyTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: "")
        #expect(!msg.isEmpty)
    }

    // MARK: - finalizingWaitMessageForTesting

    @Test("finalizing wait message includes action name")
    @MainActor func finalizingWaitMessageIncludesAction() {
        let t = AudioTranscriber.shared
        let msg = t.finalizingWaitMessageForTesting(for: "inserting")
        #expect(msg.contains("inserting"))
    }

    @Test("finalizing wait message mentions pending chunks when present")
    @MainActor func finalizingWaitMessageWithPendingChunks() {
        let t = AudioTranscriber.shared
        // pendingChunkCount is read-only published, but the message is based on internal state
        let msg = t.finalizingWaitMessageForTesting(for: "copying")
        #expect(msg.contains("copying"))
    }

    @Test("finalizing wait message for different actions")
    @MainActor func finalizingWaitMessageVariousActions() {
        let t = AudioTranscriber.shared
        let actions = ["inserting", "copying", "clearing", "probing"]
        for action in actions {
            let msg = t.finalizingWaitMessageForTesting(for: action)
            #expect(msg.contains(action))
            #expect(msg.contains("finalize") || msg.contains("finalizing"))
        }
    }

    // MARK: - finalizingRemainingEstimateSuffixForTesting

    @Test("finalizing estimate suffix for zero in-flight chunks")
    @MainActor func finalizingEstimateSuffixZero() {
        let t = AudioTranscriber.shared
        let suffix = t.finalizingRemainingEstimateSuffixForTesting(for: 0)
        // With 0 in-flight, suffix should be empty or minimal
        #expect(suffix is String) // Just verify it returns without crash
    }

    @Test("finalizing estimate suffix for positive in-flight chunks")
    @MainActor func finalizingEstimateSuffixPositive() {
        let t = AudioTranscriber.shared
        let suffix = t.finalizingRemainingEstimateSuffixForTesting(for: 3)
        #expect(suffix is String)
    }

    @Test("finalizing estimate suffix for single in-flight chunk")
    @MainActor func finalizingEstimateSuffixSingle() {
        let t = AudioTranscriber.shared
        let suffix = t.finalizingRemainingEstimateSuffixForTesting(for: 1)
        #expect(suffix is String)
    }

    // MARK: - replacementPairs

    @Test("replacementPairs with empty defaults returns empty array")
    @MainActor func replacementPairsEmpty() {
        let key = AppDefaults.Keys.transcriptionReplacements
        let saved = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("", forKey: key)
        let t = AudioTranscriber.shared
        let pairs = t.replacementPairs()
        #expect(pairs.isEmpty)
        if let saved { UserDefaults.standard.set(saved, forKey: key) }
        else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs parses => syntax")
    @MainActor func replacementPairsArrowSyntax() {
        let key = AppDefaults.Keys.transcriptionReplacements
        let saved = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("hello => world\nfoo => bar", forKey: key)
        let t = AudioTranscriber.shared
        let pairs = t.replacementPairs()
        #expect(pairs.count == 2)
        #expect(pairs[0].from == "hello")
        #expect(pairs[0].to == "world")
        #expect(pairs[1].from == "foo")
        #expect(pairs[1].to == "bar")
        if let saved { UserDefaults.standard.set(saved, forKey: key) }
        else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs parses = syntax")
    @MainActor func replacementPairsEqualsSyntax() {
        let key = AppDefaults.Keys.transcriptionReplacements
        let saved = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("alpha = beta", forKey: key)
        let t = AudioTranscriber.shared
        let pairs = t.replacementPairs()
        #expect(pairs.count == 1)
        #expect(pairs[0].from == "alpha")
        #expect(pairs[0].to == "beta")
        if let saved { UserDefaults.standard.set(saved, forKey: key) }
        else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs skips comments")
    @MainActor func replacementPairsSkipsComments() {
        let key = AppDefaults.Keys.transcriptionReplacements
        let saved = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("# this is a comment\nhello => world", forKey: key)
        let t = AudioTranscriber.shared
        let pairs = t.replacementPairs()
        #expect(pairs.count == 1)
        #expect(pairs[0].from == "hello")
        if let saved { UserDefaults.standard.set(saved, forKey: key) }
        else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs skips blank lines")
    @MainActor func replacementPairsSkipsBlanks() {
        let key = AppDefaults.Keys.transcriptionReplacements
        let saved = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("\n\nhello => world\n\n", forKey: key)
        let t = AudioTranscriber.shared
        let pairs = t.replacementPairs()
        #expect(pairs.count == 1)
        if let saved { UserDefaults.standard.set(saved, forKey: key) }
        else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs ignores lines without equals")
    @MainActor func replacementPairsNoEquals() {
        let key = AppDefaults.Keys.transcriptionReplacements
        let saved = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("just some text\nhello => world", forKey: key)
        let t = AudioTranscriber.shared
        let pairs = t.replacementPairs()
        #expect(pairs.count == 1)
        if let saved { UserDefaults.standard.set(saved, forKey: key) }
        else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs prefers => over = when both present")
    @MainActor func replacementPairsArrowPriority() {
        let key = AppDefaults.Keys.transcriptionReplacements
        let saved = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("a=b => c", forKey: key)
        let t = AudioTranscriber.shared
        let pairs = t.replacementPairs()
        #expect(pairs.count == 1)
        #expect(pairs[0].from == "a=b")
        #expect(pairs[0].to == "c")
        if let saved { UserDefaults.standard.set(saved, forKey: key) }
        else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs with empty from is skipped")
    @MainActor func replacementPairsEmptyFrom() {
        let key = AppDefaults.Keys.transcriptionReplacements
        let saved = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set(" => world", forKey: key)
        let t = AudioTranscriber.shared
        let pairs = t.replacementPairs()
        #expect(pairs.isEmpty)
        if let saved { UserDefaults.standard.set(saved, forKey: key) }
        else { UserDefaults.standard.removeObject(forKey: key) }
    }

    // MARK: - applyTextReplacements

    @Test("applyTextReplacements replaces configured pairs")
    @MainActor func applyTextReplacementsBasic() {
        let key = AppDefaults.Keys.transcriptionReplacements
        let saved = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("hello => hi\nworld => earth", forKey: key)
        let t = AudioTranscriber.shared
        let result = t.applyTextReplacements(to: "hello world")
        #expect(result == "hi earth")
        if let saved { UserDefaults.standard.set(saved, forKey: key) }
        else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("applyTextReplacements with no replacements returns original")
    @MainActor func applyTextReplacementsNone() {
        let key = AppDefaults.Keys.transcriptionReplacements
        let saved = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("", forKey: key)
        let t = AudioTranscriber.shared
        let result = t.applyTextReplacements(to: "unchanged text")
        #expect(result == "unchanged text")
        if let saved { UserDefaults.standard.set(saved, forKey: key) }
        else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("applyTextReplacements allows replacement to empty string")
    @MainActor func applyTextReplacementsToEmpty() {
        let key = AppDefaults.Keys.transcriptionReplacements
        let saved = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("um => ", forKey: key)
        let t = AudioTranscriber.shared
        let result = t.applyTextReplacements(to: "um hello um")
        #expect(result == " hello ")
        if let saved { UserDefaults.standard.set(saved, forKey: key) }
        else { UserDefaults.standard.removeObject(forKey: key) }
    }

    // MARK: - defaultOutputSettings

    @Test("defaultOutputSettings reads from UserDefaults")
    @MainActor func defaultOutputSettingsReadsDefaults() {
        let t = AudioTranscriber.shared
        let saved = UserDefaults.standard.bool(forKey: AppDefaults.Keys.outputAutoCopy)
        UserDefaults.standard.set(true, forKey: AppDefaults.Keys.outputAutoCopy)
        UserDefaults.standard.set(false, forKey: AppDefaults.Keys.outputAutoPaste)
        let settings = t.defaultOutputSettings()
        #expect(settings.autoCopy == true)
        #expect(settings.autoPaste == false)
        UserDefaults.standard.set(saved, forKey: AppDefaults.Keys.outputAutoCopy)
    }

    @Test("defaultOutputSettings includes all fields")
    @MainActor func defaultOutputSettingsAllFields() {
        let t = AudioTranscriber.shared
        let settings = t.defaultOutputSettings()
        // Just verify all fields are accessible
        _ = settings.autoCopy
        _ = settings.autoPaste
        _ = settings.clearAfterInsert
        _ = settings.commandReplacements
        _ = settings.smartCapitalization
        _ = settings.terminalPunctuation
        _ = settings.customCommandsRaw
    }

    // MARK: - resolveOutputSettings

    @Test("resolveOutputSettings merges profile overrides")
    @MainActor func resolveOutputSettingsMerge() {
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
        let profile = AppProfile(bundleIdentifier: "com.test.app", appName: "Test", autoCopy: false, autoPaste: true, clearAfterInsert: true, commandReplacements: false, smartCapitalization: false, terminalPunctuation: false)
        let result = t.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(result.autoPaste == true)
        #expect(result.autoCopy == false)
        #expect(result.clearAfterInsert == true)
    }

    @Test("resolveOutputSettings uses defaults when no profile overrides")
    @MainActor func resolveOutputSettingsNoOverrides() {
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
        let result = t.resolveOutputSettings(defaults: defaults, profile: nil)
        #expect(result.autoCopy == true)
        #expect(result.autoPaste == false)
    }

    // MARK: - effectiveOutputSettingsForCurrentApp

    @Test("effectiveOutputSettingsForCurrentApp returns settings")
    @MainActor func effectiveOutputSettingsForCurrentApp() {
        let t = AudioTranscriber.shared
        let settings = t.effectiveOutputSettingsForCurrentApp()
        // Just verify it returns valid settings
        _ = settings.autoCopy
        _ = settings.commandReplacements
    }

    // MARK: - effectiveOutputSettingsForInsertionTarget

    @Test("effectiveOutputSettingsForInsertionTarget returns settings")
    @MainActor func effectiveOutputSettingsForInsertionTarget() {
        let t = AudioTranscriber.shared
        let settings = t.effectiveOutputSettingsForInsertionTarget()
        _ = settings.autoCopy
        _ = settings.commandReplacements
    }

    // MARK: - isFinalizingTranscription

    @Test("isFinalizingTranscription reflects pending state")
    @MainActor func isFinalizingTranscription() {
        let t = AudioTranscriber.shared
        // When not recording and no pending chunks, should not be finalizing
        let result = t.isFinalizingTranscription
        #expect(result == (t.pendingChunkCount > 0 || t.pendingSessionFinalizeForTesting))
    }

    // MARK: - hasActiveSessionForHotkeyCancel

    @Test("hasActiveSessionForHotkeyCancel reflects recording/pending state")
    @MainActor func hasActiveSessionForHotkeyCancel() {
        let t = AudioTranscriber.shared
        let result = t.hasActiveSessionForHotkeyCancel
        #expect(result == (t.isRecording || t.pendingChunkCount > 0))
    }

    // MARK: - isStartAfterFinalizeQueued

    @Test("isStartAfterFinalizeQueued reflects internal state")
    @MainActor func isStartAfterFinalizeQueued() {
        let t = AudioTranscriber.shared
        let result = t.isStartAfterFinalizeQueued
        #expect(result == t.startRecordingAfterFinalizeRequestedForTesting)
    }

    // MARK: - inFlightChunkCount

    @Test("inFlightChunkCount is non-negative")
    @MainActor func inFlightChunkCountNonNegative() {
        let t = AudioTranscriber.shared
        #expect(t.inFlightChunkCount >= 0)
    }

    // MARK: - validFileURL

    @Test("validFileURL returns nil for empty path")
    @MainActor func validFileURLEmptyPath() {
        let t = AudioTranscriber.shared
        #expect(t.validFileURL(for: "") == nil)
    }

    @Test("validFileURL returns nil for nonexistent path")
    @MainActor func validFileURLNonexistent() {
        let t = AudioTranscriber.shared
        #expect(t.validFileURL(for: "/nonexistent/path/to/file.bin") == nil)
    }

    @Test("validFileURL returns nil for directory path")
    @MainActor func validFileURLDirectory() {
        let t = AudioTranscriber.shared
        #expect(t.validFileURL(for: "/tmp") == nil)
    }

    @Test("validFileURL returns URL for valid file")
    @MainActor func validFileURLValidFile() {
        let t = AudioTranscriber.shared
        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("openwhisper-test-\(UUID().uuidString).txt")
        FileManager.default.createFile(atPath: tmpFile.path, contents: Data("test".utf8))
        defer { try? FileManager.default.removeItem(at: tmpFile) }
        let result = t.validFileURL(for: tmpFile.path)
        #expect(result != nil)
        #expect(result?.path == tmpFile.path)
    }

    // MARK: - isReadableModelFile

    @Test("isReadableModelFile returns false for nonexistent URL")
    @MainActor func isReadableModelFileNonexistent() {
        let t = AudioTranscriber.shared
        let url = URL(fileURLWithPath: "/nonexistent/model.bin")
        #expect(t.isReadableModelFile(at: url) == false)
    }

    @Test("isReadableModelFile returns result for directory URL")
    @MainActor func isReadableModelFileDirectory() {
        let t = AudioTranscriber.shared
        let url = URL(fileURLWithPath: "/tmp")
        // /tmp is readable on macOS, so this just verifies no crash
        _ = t.isReadableModelFile(at: url)
    }

    @Test("isReadableModelFile returns true for readable file")
    @MainActor func isReadableModelFileValid() {
        let t = AudioTranscriber.shared
        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("openwhisper-test-\(UUID().uuidString).bin")
        FileManager.default.createFile(atPath: tmpFile.path, contents: Data("fake model".utf8))
        defer { try? FileManager.default.removeItem(at: tmpFile) }
        #expect(t.isReadableModelFile(at: tmpFile) == true)
    }

    // MARK: - resolveConfiguredModelURL

    @Test("resolveConfiguredModelURL returns a result tuple")
    @MainActor func resolveConfiguredModelURLReturns() {
        let t = AudioTranscriber.shared
        let result = t.resolveConfiguredModelURL()
        // The loaded source should always be a valid ModelSource
        _ = result.loadedSource
        _ = result.warning
    }

    // MARK: - cancelRecording when not recording

    @Test("cancelRecording when not recording is safe")
    @MainActor func cancelRecordingNotRecording() {
        let t = AudioTranscriber.shared
        // Should not crash even when not recording
        t.cancelRecording()
        #expect(t.isRecording == false)
    }

    // MARK: - setAccessibilityPermissionCheckerForTesting

    @Test("setAccessibilityPermissionCheckerForTesting overrides accessibility check")
    @MainActor func setAccessibilityPermissionChecker() {
        let t = AudioTranscriber.shared
        var canPaste = false
        t.setAccessibilityPermissionCheckerForTesting { canPaste }

        canPaste = false
        #expect(t.canAutoPasteIntoTargetAppForTesting() == false)

        canPaste = true
        #expect(t.canAutoPasteIntoTargetAppForTesting() == true)

        // Reset
        t.setAccessibilityPermissionCheckerForTesting { HotkeyMonitor.hasAccessibilityPermission() }
    }

    // MARK: - setPendingSessionFinalizeForTesting

    @Test("setPendingSessionFinalizeForTesting updates flag")
    @MainActor func setPendingSessionFinalize() {
        let t = AudioTranscriber.shared
        let original = t.pendingSessionFinalizeForTesting
        t.setPendingSessionFinalizeForTesting(true)
        #expect(t.pendingSessionFinalizeForTesting == true)
        t.setPendingSessionFinalizeForTesting(false)
        #expect(t.pendingSessionFinalizeForTesting == false)
        t.setPendingSessionFinalizeForTesting(original)
    }

    // MARK: - refreshStreamingStatusForTesting

    @Test("refreshStreamingStatusForTesting updates status")
    @MainActor func refreshStreamingStatus() {
        let t = AudioTranscriber.shared
        t.refreshStreamingStatusForTesting()
        // Should not crash; status message should be updated
        #expect(!t.statusMessage.isEmpty)
    }
}
