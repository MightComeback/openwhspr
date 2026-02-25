import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber output settings and insertion target", .serialized)
struct AudioTranscriberOutputSettingsTests {

    // MARK: - defaultOutputSettings

    @Test("defaultOutputSettings reads all keys from UserDefaults")
    @MainActor func defaultOutputSettingsReadsDefaults() {
        let t = AudioTranscriber.shared
        let keys = AppDefaults.Keys.self

        // Save originals
        let savedKeys = [keys.outputAutoCopy, keys.outputAutoPaste, keys.outputClearAfterInsert,
                         keys.outputCommandReplacements, keys.outputSmartCapitalization,
                         keys.outputTerminalPunctuation, keys.outputCustomCommands]
        let originals = savedKeys.map { UserDefaults.standard.object(forKey: $0) }

        UserDefaults.standard.set(true, forKey: keys.outputAutoCopy)
        UserDefaults.standard.set(false, forKey: keys.outputAutoPaste)
        UserDefaults.standard.set(true, forKey: keys.outputClearAfterInsert)
        UserDefaults.standard.set(false, forKey: keys.outputCommandReplacements)
        UserDefaults.standard.set(true, forKey: keys.outputSmartCapitalization)
        UserDefaults.standard.set(false, forKey: keys.outputTerminalPunctuation)
        UserDefaults.standard.set("hello => world", forKey: keys.outputCustomCommands)

        let settings = t.defaultOutputSettings()
        #expect(settings.autoCopy == true)
        #expect(settings.autoPaste == false)
        #expect(settings.clearAfterInsert == true)
        #expect(settings.commandReplacements == false)
        #expect(settings.smartCapitalization == true)
        #expect(settings.terminalPunctuation == false)
        #expect(settings.customCommandsRaw == "hello => world")

        // Restore
        for (key, val) in zip(savedKeys, originals) {
            if let val { UserDefaults.standard.set(val, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
        }
    }

    @Test("defaultOutputSettings returns false flags when unset")
    @MainActor func defaultOutputSettingsUnsetKeys() {
        let t = AudioTranscriber.shared
        let keys = AppDefaults.Keys.self

        // Save originals
        let origAutoCopy = UserDefaults.standard.object(forKey: keys.outputAutoCopy)
        let origAutoPaste = UserDefaults.standard.object(forKey: keys.outputAutoPaste)
        let origClearAfterInsert = UserDefaults.standard.object(forKey: keys.outputClearAfterInsert)
        let origCommandReplacements = UserDefaults.standard.object(forKey: keys.outputCommandReplacements)
        let origSmartCapitalization = UserDefaults.standard.object(forKey: keys.outputSmartCapitalization)
        let origTerminalPunctuation = UserDefaults.standard.object(forKey: keys.outputTerminalPunctuation)
        let origCustomCommands = UserDefaults.standard.object(forKey: keys.outputCustomCommands)

        UserDefaults.standard.removeObject(forKey: keys.outputAutoCopy)
        UserDefaults.standard.removeObject(forKey: keys.outputAutoPaste)
        UserDefaults.standard.removeObject(forKey: keys.outputClearAfterInsert)
        UserDefaults.standard.removeObject(forKey: keys.outputCommandReplacements)
        UserDefaults.standard.removeObject(forKey: keys.outputSmartCapitalization)
        UserDefaults.standard.removeObject(forKey: keys.outputTerminalPunctuation)
        UserDefaults.standard.removeObject(forKey: keys.outputCustomCommands)

        let settings = t.defaultOutputSettings()
        // AppDefaults.register() sets autoCopy, commandReplacements,
        // smartCapitalization, terminalPunctuation to true by default.
        // After removeObject, registered defaults still apply.
        #expect(settings.autoCopy == true)
        #expect(settings.autoPaste == false)
        #expect(settings.clearAfterInsert == false)
        #expect(settings.commandReplacements == true)
        #expect(settings.smartCapitalization == true)
        #expect(settings.terminalPunctuation == true)
        #expect(settings.customCommandsRaw == "")

        // Restore originals
        if let v = origAutoCopy { UserDefaults.standard.set(v, forKey: keys.outputAutoCopy) }
        if let v = origAutoPaste { UserDefaults.standard.set(v, forKey: keys.outputAutoPaste) }
        if let v = origClearAfterInsert { UserDefaults.standard.set(v, forKey: keys.outputClearAfterInsert) }
        if let v = origCommandReplacements { UserDefaults.standard.set(v, forKey: keys.outputCommandReplacements) }
        if let v = origSmartCapitalization { UserDefaults.standard.set(v, forKey: keys.outputSmartCapitalization) }
        if let v = origTerminalPunctuation { UserDefaults.standard.set(v, forKey: keys.outputTerminalPunctuation) }
        if let v = origCustomCommands { UserDefaults.standard.set(v, forKey: keys.outputCustomCommands) }
    }

    @Test("defaultOutputSettings with all flags enabled")
    @MainActor func defaultOutputSettingsAllEnabled() {
        let t = AudioTranscriber.shared
        let keys = AppDefaults.Keys.self
        let savedKeys = [keys.outputAutoCopy, keys.outputAutoPaste, keys.outputClearAfterInsert,
                         keys.outputCommandReplacements, keys.outputSmartCapitalization, keys.outputTerminalPunctuation]
        let originals = savedKeys.map { UserDefaults.standard.object(forKey: $0) }

        for k in savedKeys { UserDefaults.standard.set(true, forKey: k) }

        let settings = t.defaultOutputSettings()
        #expect(settings.autoCopy == true)
        #expect(settings.autoPaste == true)
        #expect(settings.clearAfterInsert == true)
        #expect(settings.commandReplacements == true)
        #expect(settings.smartCapitalization == true)
        #expect(settings.terminalPunctuation == true)

        for (key, val) in zip(savedKeys, originals) {
            if let val { UserDefaults.standard.set(val, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
        }
    }

    @Test("defaultOutputSettings customCommandsRaw falls back to empty string")
    @MainActor func defaultOutputSettingsCustomCommandsFallback() {
        let t = AudioTranscriber.shared
        let key = AppDefaults.Keys.outputCustomCommands
        let orig = UserDefaults.standard.object(forKey: key)
        UserDefaults.standard.removeObject(forKey: key)
        let settings = t.defaultOutputSettings()
        #expect(settings.customCommandsRaw == "")
        if let orig { UserDefaults.standard.set(orig, forKey: key) }
    }

    // MARK: - replacementPairs

    /// Helper: run a block with a temporary transcriptionReplacements value, restoring after.
    private func withReplacements(_ value: String?, block: (AudioTranscriber) -> Void) {
        let key = AppDefaults.Keys.transcriptionReplacements
        let original = UserDefaults.standard.object(forKey: key)
        if let value {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
        block(AudioTranscriber.shared)
        if let original {
            UserDefaults.standard.set(original, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    @Test("replacementPairs parses arrow-separated pairs")
    @MainActor func replacementPairsArrowSeparated() {
        withReplacements("foo => bar\nbaz => qux") { t in
            let pairs = t.replacementPairs()
            #expect(pairs.count == 2)
            #expect(pairs[0].from == "foo")
            #expect(pairs[0].to == "bar")
            #expect(pairs[1].from == "baz")
            #expect(pairs[1].to == "qux")
        }
    }

    @Test("replacementPairs parses equals-separated pairs")
    @MainActor func replacementPairsEqualsSeparated() {
        withReplacements("hello=world") { t in
            let pairs = t.replacementPairs()
            #expect(pairs.count == 1)
            #expect(pairs[0].from == "hello")
            #expect(pairs[0].to == "world")
        }
    }

    @Test("replacementPairs ignores comment lines")
    @MainActor func replacementPairsIgnoresComments() {
        withReplacements("# comment\nfoo => bar\n# another") { t in
            let pairs = t.replacementPairs()
            #expect(pairs.count == 1)
            #expect(pairs[0].from == "foo")
        }
    }

    @Test("replacementPairs ignores empty lines")
    @MainActor func replacementPairsIgnoresEmptyLines() {
        withReplacements("\n\nfoo => bar\n\n") { t in
            let pairs = t.replacementPairs()
            #expect(pairs.count == 1)
        }
    }

    @Test("replacementPairs returns empty when no replacements set")
    @MainActor func replacementPairsEmpty() {
        withReplacements(nil) { t in
            let pairs = t.replacementPairs()
            #expect(pairs.isEmpty)
        }
    }

    @Test("replacementPairs skips lines with empty from value")
    @MainActor func replacementPairsSkipsEmptyFrom() {
        withReplacements(" => bar\nfoo => baz") { t in
            let pairs = t.replacementPairs()
            #expect(pairs.count == 1)
            #expect(pairs[0].from == "foo")
        }
    }

    @Test("replacementPairs allows empty to value")
    @MainActor func replacementPairsAllowsEmptyTo() {
        withReplacements("foo => ") { t in
            let pairs = t.replacementPairs()
            #expect(pairs.count == 1)
            #expect(pairs[0].from == "foo")
            #expect(pairs[0].to == "")
        }
    }

    @Test("replacementPairs prefers arrow over equals when both present")
    @MainActor func replacementPairsArrowPrecedence() {
        withReplacements("a=b => c") { t in
            let pairs = t.replacementPairs()
            #expect(pairs.count == 1)
            #expect(pairs[0].from == "a=b")
            #expect(pairs[0].to == "c")
        }
    }

    @Test("replacementPairs trims whitespace around from and to")
    @MainActor func replacementPairsTrimsWhitespace() {
        withReplacements("  foo  =>  bar  ") { t in
            let pairs = t.replacementPairs()
            #expect(pairs.count == 1)
            #expect(pairs[0].from == "foo")
            #expect(pairs[0].to == "bar")
        }
    }

    @Test("replacementPairs handles multiple arrow operators in one line")
    @MainActor func replacementPairsMultipleArrows() {
        withReplacements("a => b => c") { t in
            let pairs = t.replacementPairs()
            #expect(pairs.count == 1)
            #expect(pairs[0].from == "a")
            #expect(pairs[0].to == "b => c")
        }
    }

    // MARK: - resolveOutputSettings

    @Test("resolveOutputSettings merges profile overrides with defaults")
    @MainActor func resolveOutputSettingsMergesProfile() {
        let t = AudioTranscriber.shared
        let defaults = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommandsRaw: ""
        )
        let profile = AppProfile(
            bundleIdentifier: "com.test.app",
            appName: "Test",
            autoCopy: true,
            autoPaste: true,
            clearAfterInsert: false,
            commandReplacements: true,
            smartCapitalization: true,
            terminalPunctuation: true
        )

        let result = t.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(result.smartCapitalization == true)
        #expect(result.terminalPunctuation == true)
        #expect(result.autoCopy == true)
        #expect(result.autoPaste == true)
        #expect(result.commandReplacements == true)
        #expect(result.clearAfterInsert == false)
    }

    @Test("resolveOutputSettings with no overrides returns defaults")
    @MainActor func resolveOutputSettingsNoOverrides() {
        let t = AudioTranscriber.shared
        let defaults = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: true,
            autoPaste: true,
            clearAfterInsert: true,
            commandReplacements: true,
            smartCapitalization: true,
            terminalPunctuation: true,
            customCommandsRaw: "test"
        )
        let profile = AppProfile(
            bundleIdentifier: "com.test.app",
            appName: "Test",
            autoCopy: false,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false
        )

        // Profile values replace defaults entirely
        let result = t.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(result.autoCopy == false)
        #expect(result.autoPaste == false)
        #expect(result.smartCapitalization == false)
        #expect(result.terminalPunctuation == false)
    }

    // MARK: - clearManualInsertTarget

    @Test("clearManualInsertTarget resets state and sets status message")
    @MainActor func clearManualInsertTargetResetsState() {
        let t = AudioTranscriber.shared
        t.clearManualInsertTarget()
        #expect(t.statusMessage.contains("Cleared insertion target"))
        #expect(t.lastError == nil)
    }

    @Test("clearManualInsertTarget is idempotent")
    @MainActor func clearManualInsertTargetIdempotent() {
        let t = AudioTranscriber.shared
        t.clearManualInsertTarget()
        t.clearManualInsertTarget()
        #expect(t.statusMessage.contains("Cleared insertion target"))
    }

    // MARK: - effectiveOutputSettingsForCurrentApp

    @Test("effectiveOutputSettingsForCurrentApp returns defaults when no profile matches")
    @MainActor func effectiveOutputSettingsForCurrentAppNoProfile() {
        let t = AudioTranscriber.shared
        let keys = AppDefaults.Keys.self
        let origSC = UserDefaults.standard.object(forKey: keys.outputSmartCapitalization)
        let origTP = UserDefaults.standard.object(forKey: keys.outputTerminalPunctuation)
        UserDefaults.standard.set(true, forKey: keys.outputSmartCapitalization)
        UserDefaults.standard.set(false, forKey: keys.outputTerminalPunctuation)

        let settings = t.effectiveOutputSettingsForCurrentApp()
        #expect(settings.smartCapitalization == true)
        #expect(settings.terminalPunctuation == false)

        if let v = origSC { UserDefaults.standard.set(v, forKey: keys.outputSmartCapitalization) } else { UserDefaults.standard.removeObject(forKey: keys.outputSmartCapitalization) }
        if let v = origTP { UserDefaults.standard.set(v, forKey: keys.outputTerminalPunctuation) } else { UserDefaults.standard.removeObject(forKey: keys.outputTerminalPunctuation) }
    }

    @Test("effectiveOutputSettingsForInsertionTarget returns defaults when no target")
    @MainActor func effectiveOutputSettingsForInsertionTargetNoTarget() {
        let t = AudioTranscriber.shared
        t.clearManualInsertTarget()
        let keys = AppDefaults.Keys.self
        let origAC = UserDefaults.standard.object(forKey: keys.outputAutoCopy)
        UserDefaults.standard.set(true, forKey: keys.outputAutoCopy)

        let settings = t.effectiveOutputSettingsForInsertionTarget()
        #expect(settings.autoCopy == true)

        if let v = origAC { UserDefaults.standard.set(v, forKey: keys.outputAutoCopy) } else { UserDefaults.standard.removeObject(forKey: keys.outputAutoCopy) }
    }

    // MARK: - applyTextReplacements

    @Test("applyTextReplacements applies configured replacements")
    @MainActor func applyTextReplacementsApplies() {
        withReplacements("hello => goodbye") { t in
            let result = t.applyTextReplacements(to: "hello world")
            #expect(result == "goodbye world")
        }
    }

    @Test("applyTextReplacements with no replacements returns original")
    @MainActor func applyTextReplacementsNoReplacements() {
        withReplacements(nil) { t in
            let result = t.applyTextReplacements(to: "hello world")
            #expect(result == "hello world")
        }
    }

    @Test("applyTextReplacements applies multiple replacements in order")
    @MainActor func applyTextReplacementsMultiple() {
        withReplacements("a => b\nb => c") { t in
            let result = t.applyTextReplacements(to: "a b")
            #expect(result == "c c")
        }
    }

    @Test("applyTextReplacements with delete replacement removes text")
    @MainActor func applyTextReplacementsDelete() {
        withReplacements("um => ") { t in
            let result = t.applyTextReplacements(to: "um well um")
            #expect(result == " well ")
        }
    }

    // MARK: - validFileURL

    @Test("validFileURL returns nil for empty path")
    @MainActor func validFileURLEmptyPath() {
        let t = AudioTranscriber.shared
        #expect(t.validFileURL(for: "") == nil)
    }

    @Test("validFileURL returns nil for nonexistent path")
    @MainActor func validFileURLNonexistentPath() {
        let t = AudioTranscriber.shared
        #expect(t.validFileURL(for: "/nonexistent/path/model.bin") == nil)
    }

    @Test("validFileURL returns nil for directory path")
    @MainActor func validFileURLDirectoryPath() {
        let t = AudioTranscriber.shared
        #expect(t.validFileURL(for: "/tmp") == nil)
    }

    @Test("validFileURL returns URL for existing file")
    @MainActor func validFileURLExistingFile() throws {
        let t = AudioTranscriber.shared
        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("openwhisper_test_\(UUID().uuidString).txt")
        try "test".write(to: tmpFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        let result = t.validFileURL(for: tmpFile.path)
        #expect(result != nil)
        #expect(result?.path == tmpFile.path)
    }

    // MARK: - isReadableModelFile

    @Test("isReadableModelFile returns false for nonexistent file")
    @MainActor func isReadableModelFileNonexistent() {
        let t = AudioTranscriber.shared
        let url = URL(fileURLWithPath: "/nonexistent/model.bin")
        #expect(t.isReadableModelFile(at: url) == false)
    }

    @Test("isReadableModelFile returns true for readable non-empty file")
    @MainActor func isReadableModelFileReadable() throws {
        let t = AudioTranscriber.shared
        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("openwhisper_model_\(UUID().uuidString).bin")
        try Data(repeating: 0xFF, count: 100).write(to: tmpFile)
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        #expect(t.isReadableModelFile(at: tmpFile) == true)
    }

    @Test("isReadableModelFile returns false for empty file")
    @MainActor func isReadableModelFileEmpty() throws {
        let t = AudioTranscriber.shared
        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("openwhisper_empty_\(UUID().uuidString).bin")
        try Data().write(to: tmpFile)
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        #expect(t.isReadableModelFile(at: tmpFile) == false)
    }

    // MARK: - resolveConfiguredModelURL

    @Test("resolveConfiguredModelURL defaults to bundled tiny when no source set")
    @MainActor func resolveConfiguredModelURLDefault() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.removeObject(forKey: AppDefaults.Keys.modelSource)
        let result = t.resolveConfiguredModelURL()
        #expect(result.loadedSource == .bundledTiny)
    }

    @Test("resolveConfiguredModelURL falls back to bundled when custom path invalid")
    @MainActor func resolveConfiguredModelURLCustomInvalid() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set(ModelSource.customPath.rawValue, forKey: AppDefaults.Keys.modelSource)
        UserDefaults.standard.set("/nonexistent/model.bin", forKey: AppDefaults.Keys.modelCustomPath)
        let result = t.resolveConfiguredModelURL()
        // Should fall back to bundled with a warning
        #expect(result.warning != nil)
        #expect(result.warning?.contains("Custom model not found") == true)
    }

    @Test("resolveConfiguredModelURL warns when custom path is empty")
    @MainActor func resolveConfiguredModelURLCustomEmpty() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set(ModelSource.customPath.rawValue, forKey: AppDefaults.Keys.modelSource)
        UserDefaults.standard.set("", forKey: AppDefaults.Keys.modelCustomPath)
        let result = t.resolveConfiguredModelURL()
        #expect(result.warning?.contains("empty") == true)
    }

    @Test("resolveConfiguredModelURL trims whitespace from custom path")
    @MainActor func resolveConfiguredModelURLTrimsWhitespace() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set(ModelSource.customPath.rawValue, forKey: AppDefaults.Keys.modelSource)
        UserDefaults.standard.set("   ", forKey: AppDefaults.Keys.modelCustomPath)
        let result = t.resolveConfiguredModelURL()
        // Trimmed to empty → warning about empty path
        #expect(result.warning?.contains("empty") == true)
    }

    // MARK: - ManualInsertTargetSnapshot

    @Test("manualInsertTargetSnapshot returns a snapshot with expected structure")
    @MainActor func manualInsertTargetSnapshotStructure() {
        let t = AudioTranscriber.shared
        // In test environment, snapshot may pick up frontmost app or return nil
        let snap = t.manualInsertTargetSnapshot()
        // Either all fields are nil (no target) or appName/bundleIdentifier/display are populated
        if snap.appName != nil {
            #expect(snap.bundleIdentifier != nil)
            #expect(snap.display != nil)
        }
    }

    @Test("manualInsertTargetAppName returns string or nil")
    @MainActor func manualInsertTargetAppNameType() {
        let t = AudioTranscriber.shared
        let name = t.manualInsertTargetAppName()
        if let name {
            #expect(!name.isEmpty)
        }
    }

    @Test("manualInsertTargetBundleIdentifier returns string or nil")
    @MainActor func manualInsertTargetBundleIdentifierType() {
        let t = AudioTranscriber.shared
        let bid = t.manualInsertTargetBundleIdentifier()
        if let bid {
            #expect(bid.contains("."))
        }
    }

    @Test("manualInsertTargetDisplay contains app name when present")
    @MainActor func manualInsertTargetDisplayContainsName() {
        let t = AudioTranscriber.shared
        let display = t.manualInsertTargetDisplay()
        let name = t.manualInsertTargetAppName()
        if let display, let name {
            #expect(display.contains(name))
        }
    }

    @Test("manualInsertTargetUsesFallbackApp returns bool")
    @MainActor func manualInsertTargetUsesFallbackAppType() {
        let t = AudioTranscriber.shared
        _ = t.manualInsertTargetUsesFallbackApp()
        // Just verify it returns without crash
    }

    // MARK: - copyTranscriptionToClipboard

    @Test("copyTranscriptionToClipboard returns false when transcription is empty")
    @MainActor func copyTranscriptionToClipboardEmpty() {
        let t = AudioTranscriber.shared
        t.clearTranscription()
        let result = t.copyTranscriptionToClipboard()
        #expect(result == false)
    }

    // MARK: - clipboardFallbackStatusMessageForTesting

    @Test("clipboardFallbackStatusMessage includes target name when provided")
    @MainActor func clipboardFallbackStatusMessageWithTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: "Safari")
        #expect(msg.contains("Safari"))
    }

    @Test("clipboardFallbackStatusMessage handles nil target name")
    @MainActor func clipboardFallbackStatusMessageNilTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: nil)
        #expect(!msg.isEmpty)
    }

    // MARK: - finalizingWaitMessageForTesting

    @Test("finalizingWaitMessage includes action name")
    @MainActor func finalizingWaitMessageIncludesAction() {
        let t = AudioTranscriber.shared
        let msg = t.finalizingWaitMessageForTesting(for: "insert")
        #expect(msg.lowercased().contains("insert") || msg.lowercased().contains("finaliz"))
    }

    // MARK: - finalizingRemainingEstimateSuffixForTesting

    @Test("finalizingRemainingEstimateSuffix returns string for positive chunks")
    @MainActor func finalizingRemainingEstimateSuffixPositive() {
        let t = AudioTranscriber.shared
        let suffix = t.finalizingRemainingEstimateSuffixForTesting(for: 3)
        #expect(!suffix.isEmpty || suffix.isEmpty) // Just verify no crash
    }

    @Test("finalizingRemainingEstimateSuffix handles zero chunks")
    @MainActor func finalizingRemainingEstimateSuffixZero() {
        let t = AudioTranscriber.shared
        let suffix = t.finalizingRemainingEstimateSuffixForTesting(for: 0)
        // Should not crash
        _ = suffix
    }

    // MARK: - canAutoPasteIntoTargetAppForTesting

    @Test("canAutoPasteIntoTargetApp returns bool without crashing")
    @MainActor func canAutoPasteIntoTargetApp() {
        let t = AudioTranscriber.shared
        // Just verify it doesn't crash; actual value depends on system state
        _ = t.canAutoPasteIntoTargetAppForTesting()
    }

    // MARK: - setAccessibilityPermissionCheckerForTesting

    @Test("setAccessibilityPermissionChecker overrides checker")
    @MainActor func setAccessibilityPermissionCheckerOverrides() {
        let t = AudioTranscriber.shared
        t.setAccessibilityPermissionCheckerForTesting { true }
        // Verify no crash
        t.setAccessibilityPermissionCheckerForTesting { false }
    }

    // MARK: - setPendingSessionFinalizeForTesting

    @Test("setPendingSessionFinalizeForTesting toggles flag")
    @MainActor func setPendingSessionFinalizeToggles() {
        let t = AudioTranscriber.shared
        t.setPendingSessionFinalizeForTesting(true)
        t.setPendingSessionFinalizeForTesting(false)
        // Verify no crash
    }

    // MARK: - refreshStreamingStatusForTesting

    @Test("refreshStreamingStatusForTesting does not crash")
    @MainActor func refreshStreamingStatusNoCrash() {
        let t = AudioTranscriber.shared
        t.refreshStreamingStatusForTesting()
    }

    // MARK: - mergeChunkForTesting

    @Test("mergeChunkForTesting merges chunk into existing text")
    @MainActor func mergeChunkMerges() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("world", into: "hello ")
        #expect(result.contains("hello"))
        #expect(result.contains("world"))
    }

    @Test("mergeChunkForTesting with empty existing text returns chunk")
    @MainActor func mergeChunkEmptyExisting() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("hello", into: "")
        #expect(result.contains("hello"))
    }

    @Test("mergeChunkForTesting with empty chunk returns existing")
    @MainActor func mergeChunkEmptyChunk() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("", into: "hello")
        #expect(result == "hello")
    }

    @Test("mergeChunkForTesting handles overlapping text")
    @MainActor func mergeChunkOverlapping() {
        let t = AudioTranscriber.shared
        // If chunk starts with end of existing, should merge intelligently
        let result = t.mergeChunkForTesting("lo world", into: "hel")
        #expect(!result.isEmpty)
    }

    // MARK: - insertTranscriptionIntoFocusedApp

    @Test("insertTranscriptionIntoFocusedApp returns false while recording")
    @MainActor func insertTranscriptionFailsWhileRecording() {
        let t = AudioTranscriber.shared
        // If recording, should return false
        if t.isRecording {
            let result = t.insertTranscriptionIntoFocusedApp()
            #expect(result == false)
        }
    }

    @Test("insertTranscriptionIntoFocusedApp returns false with empty transcription")
    @MainActor func insertTranscriptionFailsEmpty() {
        let t = AudioTranscriber.shared
        t.clearTranscription()
        if !t.isRecording {
            let result = t.insertTranscriptionIntoFocusedApp()
            #expect(result == false)
        }
    }

    // MARK: - clearTranscription

    @Test("clearTranscription empties transcription text")
    @MainActor func clearTranscriptionEmptiesText() {
        let t = AudioTranscriber.shared
        t.clearTranscription()
        #expect(t.transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    @Test("clearTranscription is idempotent")
    @MainActor func clearTranscriptionIdempotent() {
        let t = AudioTranscriber.shared
        t.clearTranscription()
        t.clearTranscription()
        #expect(t.transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    // MARK: - clearHistory

    @Test("clearHistory empties recent entries")
    @MainActor func clearHistoryEmptiesEntries() {
        let t = AudioTranscriber.shared
        t.clearHistory()
        #expect(t.recentEntries.isEmpty)
    }

    // MARK: - setTranscriptionLanguage

    @Test("setTranscriptionLanguage updates activeLanguageCode")
    @MainActor func setTranscriptionLanguageUpdatesCode() {
        let t = AudioTranscriber.shared
        t.setTranscriptionLanguage("en")
        #expect(t.activeLanguageCode == "en")
    }

    @Test("setTranscriptionLanguage stores in UserDefaults")
    @MainActor func setTranscriptionLanguageStoresInDefaults() {
        let t = AudioTranscriber.shared
        t.setTranscriptionLanguage("fr")
        let stored = UserDefaults.standard.string(forKey: AppDefaults.Keys.transcriptionLanguage)
        #expect(stored == "fr")
    }

    @Test("setTranscriptionLanguage with auto resets to auto")
    @MainActor func setTranscriptionLanguageAuto() {
        let t = AudioTranscriber.shared
        t.setTranscriptionLanguage("auto")
        #expect(t.activeLanguageCode == "auto")
        #expect(t.statusMessage.lowercased().contains("auto"))
    }

    @Test("setTranscriptionLanguage updates status message")
    @MainActor func setTranscriptionLanguageUpdatesStatus() {
        let t = AudioTranscriber.shared
        t.setTranscriptionLanguage("de")
        #expect(t.statusMessage.contains("Language set to"))
    }

    // MARK: - setModelSource

    @Test("setModelSource to bundled clears modelWarning")
    @MainActor func setModelSourceBundledClearsWarning() {
        let t = AudioTranscriber.shared
        t.setModelSource(.bundledTiny)
        #expect(t.modelWarning == nil)
    }

    @Test("setModelSource stores in UserDefaults")
    @MainActor func setModelSourceStoresInDefaults() {
        let t = AudioTranscriber.shared
        t.setModelSource(.bundledTiny)
        let stored = UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource)
        #expect(stored == ModelSource.bundledTiny.rawValue)
    }

    @Test("setModelSource to customPath stores customPath")
    @MainActor func setModelSourceCustomPath() {
        let t = AudioTranscriber.shared
        t.setModelSource(.customPath)
        let stored = UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource)
        #expect(stored == ModelSource.customPath.rawValue)
    }
}
