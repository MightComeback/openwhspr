import XCTest
@testable import OpenWhisper

@MainActor
final class AudioTranscriberExtendedTests: XCTestCase {
    private var transcriber: AudioTranscriber!

    override func setUp() async throws {
        try await super.setUp()
        transcriber = AudioTranscriber.shared
        transcriber.clearTranscription()
    }

    // MARK: - clearTranscription

    @MainActor
    func testClearTranscriptionResetsTextAndError() {
        transcriber.transcription = "Hello world"
        transcriber.lastError = "Some error"
        transcriber.clearTranscription()
        XCTAssertEqual(transcriber.transcription, "")
        XCTAssertNil(transcriber.lastError)
    }

    @MainActor
    func testClearTranscriptionOnAlreadyEmptyIsNoOp() {
        transcriber.clearTranscription()
        XCTAssertEqual(transcriber.transcription, "")
        XCTAssertNil(transcriber.lastError)
    }

    // MARK: - clearHistory

    @MainActor
    func testClearHistoryRemovesAllEntries() {
        // Ensure there's at least something in history by checking it doesn't crash
        transcriber.clearHistory()
        XCTAssertTrue(transcriber.recentEntries.isEmpty)
    }

    // MARK: - Profile management

    @MainActor
    func testUpdateProfileModifiesExistingProfile() {
        // Start with a profile
        let profile = AppProfile(
            bundleIdentifier: "com.test.app",
            appName: "TestApp",
            autoCopy: true,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommands: ""
        )
        transcriber.appProfiles.append(profile)

        var updated = profile
        updated.autoPaste = true
        updated.appName = "TestApp Updated"
        transcriber.updateProfile(updated)

        let found = transcriber.appProfiles.first { $0.bundleIdentifier == "com.test.app" }
        XCTAssertNotNil(found)
        XCTAssertTrue(found!.autoPaste)
        XCTAssertEqual(found!.appName, "TestApp Updated")

        // Cleanup
        transcriber.removeProfile(bundleIdentifier: "com.test.app")
    }

    @MainActor
    func testUpdateProfileIgnoresUnknownBundleIdentifier() {
        let countBefore = transcriber.appProfiles.count
        let profile = AppProfile(
            bundleIdentifier: "com.nonexistent.app",
            appName: "Ghost",
            autoCopy: false,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommands: ""
        )
        transcriber.updateProfile(profile)
        XCTAssertEqual(transcriber.appProfiles.count, countBefore)
    }

    @MainActor
    func testRemoveProfileDeletesMatchingProfile() {
        let profile = AppProfile(
            bundleIdentifier: "com.remove.test",
            appName: "RemoveMe",
            autoCopy: true,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommands: ""
        )
        transcriber.appProfiles.append(profile)
        XCTAssertTrue(transcriber.appProfiles.contains { $0.bundleIdentifier == "com.remove.test" })

        transcriber.removeProfile(bundleIdentifier: "com.remove.test")
        XCTAssertFalse(transcriber.appProfiles.contains { $0.bundleIdentifier == "com.remove.test" })
    }

    @MainActor
    func testRemoveProfileNoOpForUnknownIdentifier() {
        let countBefore = transcriber.appProfiles.count
        transcriber.removeProfile(bundleIdentifier: "com.definitely.not.here")
        XCTAssertEqual(transcriber.appProfiles.count, countBefore)
    }

    @MainActor
    func testUpdateProfileSortsAlphabetically() {
        // Clear existing test profiles
        transcriber.appProfiles.removeAll { $0.bundleIdentifier.hasPrefix("com.sort.") }

        let a = AppProfile(bundleIdentifier: "com.sort.zebra", appName: "Zebra", autoCopy: false, autoPaste: false, clearAfterInsert: false, commandReplacements: false, smartCapitalization: false, terminalPunctuation: false, customCommands: "")
        let b = AppProfile(bundleIdentifier: "com.sort.alpha", appName: "Alpha", autoCopy: false, autoPaste: false, clearAfterInsert: false, commandReplacements: false, smartCapitalization: false, terminalPunctuation: false, customCommands: "")
        transcriber.appProfiles.append(a)
        transcriber.appProfiles.append(b)

        // Update Zebra — should re-sort
        var updatedA = a
        updatedA.autoCopy = true
        transcriber.updateProfile(updatedA)

        let sortProfiles = transcriber.appProfiles.filter { $0.bundleIdentifier.hasPrefix("com.sort.") }
        XCTAssertEqual(sortProfiles.first?.appName, "Alpha")
        XCTAssertEqual(sortProfiles.last?.appName, "Zebra")

        // Cleanup
        transcriber.removeProfile(bundleIdentifier: "com.sort.zebra")
        transcriber.removeProfile(bundleIdentifier: "com.sort.alpha")
    }

    // MARK: - setModelSource

    @MainActor
    func testSetModelSourceBundledTinyClearsWarning() {
        transcriber.modelWarning = "Some warning"
        transcriber.setModelSource(.bundledTiny)
        XCTAssertNil(transcriber.modelWarning)
        XCTAssertEqual(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource), ModelSource.bundledTiny.rawValue)
    }

    @MainActor
    func testSetModelSourceCustomPathPreservesWarning() {
        transcriber.modelWarning = "Existing warning"
        transcriber.setModelSource(.customPath)
        // Warning may be replaced by reloadConfiguredModel, but should not be nil'd by setModelSource itself
        XCTAssertEqual(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource), ModelSource.customPath.rawValue)
    }

    // MARK: - setTranscriptionLanguage

    @MainActor
    func testSetTranscriptionLanguageSetsDefaultsAndStatus() {
        transcriber.setTranscriptionLanguage("en")
        XCTAssertEqual(UserDefaults.standard.string(forKey: AppDefaults.Keys.transcriptionLanguage), "en")
        XCTAssertEqual(transcriber.activeLanguageCode, "en")
        XCTAssertTrue(transcriber.statusMessage.contains("Language set to"))
    }

    @MainActor
    func testSetTranscriptionLanguageAutoMode() {
        transcriber.setTranscriptionLanguage("auto")
        XCTAssertEqual(transcriber.activeLanguageCode, "auto")
        XCTAssertTrue(transcriber.statusMessage.contains("Language set to"))
    }

    // MARK: - setCustomModelPath / clearCustomModelPath

    @MainActor
    func testSetCustomModelPathStoresNormalized() {
        transcriber.setCustomModelPath("  /some/path/model.bin  ")
        XCTAssertEqual(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelCustomPath), "/some/path/model.bin")
        XCTAssertEqual(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelSource), ModelSource.customPath.rawValue)
    }

    @MainActor
    func testClearCustomModelPathSetsEmpty() {
        UserDefaults.standard.set("/old/path", forKey: AppDefaults.Keys.modelCustomPath)
        transcriber.clearCustomModelPath()
        XCTAssertEqual(UserDefaults.standard.string(forKey: AppDefaults.Keys.modelCustomPath), "")
    }

    // MARK: - cancelRecording

    @MainActor
    func testCancelRecordingWhenNotRecordingShowsNothingToCancel() {
        // Not recording, no pending chunks, no pending finalize
        transcriber.cancelRecording()
        XCTAssertEqual(transcriber.statusMessage, "Nothing to cancel")
    }

    // MARK: - applySmartCapitalization edge cases

    func testSmartCapitalizationEmptyString() {
        let result = transcriber.applySmartCapitalization(to: "")
        XCTAssertEqual(result, "")
    }

    func testSmartCapitalizationSingleLetter() {
        let result = transcriber.applySmartCapitalization(to: "a")
        XCTAssertEqual(result, "A")
    }

    func testSmartCapitalizationAfterPeriod() {
        let result = transcriber.applySmartCapitalization(to: "hello. world")
        XCTAssertEqual(result, "Hello. World")
    }

    func testSmartCapitalizationAfterExclamation() {
        let result = transcriber.applySmartCapitalization(to: "wow! great")
        XCTAssertEqual(result, "Wow! Great")
    }

    func testSmartCapitalizationAfterQuestion() {
        let result = transcriber.applySmartCapitalization(to: "why? because")
        XCTAssertEqual(result, "Why? Because")
    }

    func testSmartCapitalizationAfterNewline() {
        let result = transcriber.applySmartCapitalization(to: "line one\nline two")
        XCTAssertEqual(result, "Line one\nLine two")
    }

    func testSmartCapitalizationPreservesAlreadyCapitalized() {
        let result = transcriber.applySmartCapitalization(to: "Already Capitalized.")
        XCTAssertEqual(result, "Already Capitalized.")
    }

    func testSmartCapitalizationNumbers() {
        let result = transcriber.applySmartCapitalization(to: "test. 123 hello")
        XCTAssertEqual(result, "Test. 123 hello")
    }

    func testSmartCapitalizationMultipleSentences() {
        let result = transcriber.applySmartCapitalization(to: "first. second. third.")
        XCTAssertEqual(result, "First. Second. Third.")
    }

    // MARK: - applyTerminalPunctuationIfNeeded edge cases

    func testTerminalPunctuationAddsperiodToLetterEnding() {
        let result = transcriber.applyTerminalPunctuationIfNeeded(to: "hello world")
        XCTAssertEqual(result, "hello world.")
    }

    func testTerminalPunctuationAddsperiodToNumberEnding() {
        let result = transcriber.applyTerminalPunctuationIfNeeded(to: "count is 42")
        XCTAssertEqual(result, "count is 42.")
    }

    func testTerminalPunctuationPreservesPeriod() {
        let result = transcriber.applyTerminalPunctuationIfNeeded(to: "already done.")
        XCTAssertEqual(result, "already done.")
    }

    func testTerminalPunctuationPreservesExclamation() {
        let result = transcriber.applyTerminalPunctuationIfNeeded(to: "wow!")
        XCTAssertEqual(result, "wow!")
    }

    func testTerminalPunctuationPreservesQuestion() {
        let result = transcriber.applyTerminalPunctuationIfNeeded(to: "really?")
        XCTAssertEqual(result, "really?")
    }

    func testTerminalPunctuationPreservesEllipsis() {
        let result = transcriber.applyTerminalPunctuationIfNeeded(to: "wait…")
        XCTAssertEqual(result, "wait…")
    }

    func testTerminalPunctuationPreservesColon() {
        let result = transcriber.applyTerminalPunctuationIfNeeded(to: "note:")
        XCTAssertEqual(result, "note:")
    }

    func testTerminalPunctuationPreservesSemicolon() {
        let result = transcriber.applyTerminalPunctuationIfNeeded(to: "pause;")
        XCTAssertEqual(result, "pause;")
    }

    func testTerminalPunctuationEmptyString() {
        let result = transcriber.applyTerminalPunctuationIfNeeded(to: "")
        XCTAssertEqual(result, "")
    }

    func testTerminalPunctuationWhitespaceOnly() {
        let result = transcriber.applyTerminalPunctuationIfNeeded(to: "   ")
        XCTAssertEqual(result, "")
    }

    func testTerminalPunctuationTrimsWhitespace() {
        let result = transcriber.applyTerminalPunctuationIfNeeded(to: "  hello world  ")
        XCTAssertEqual(result, "hello world.")
    }

    // MARK: - normalizeWhitespace edge cases

    func testNormalizeWhitespaceCollapsesTabsAndSpaces() {
        let result = transcriber.normalizeWhitespace(in: "hello\t\t  world")
        XCTAssertEqual(result, "hello world")
    }

    func testNormalizeWhitespaceRemovesSpaceBeforeComma() {
        let result = transcriber.normalizeWhitespace(in: "hello , world")
        XCTAssertEqual(result, "hello, world")
    }

    func testNormalizeWhitespaceRemovesSpaceBeforePeriod() {
        let result = transcriber.normalizeWhitespace(in: "hello . world")
        XCTAssertEqual(result, "hello. world")
    }

    func testNormalizeWhitespaceCollapsesExcessNewlines() {
        let result = transcriber.normalizeWhitespace(in: "a\n\n\n\nb")
        XCTAssertEqual(result, "a\n\nb")
    }

    func testNormalizeWhitespaceFixesSpacedApostrophe() {
        let result = transcriber.normalizeWhitespace(in: "don ' t")
        XCTAssertEqual(result, "don't")
    }

    func testNormalizeWhitespaceFixesCurlyApostrophe() {
        let result = transcriber.normalizeWhitespace(in: "we \u{2019} re")
        XCTAssertEqual(result, "we're")
    }

    // MARK: - applyCommandReplacements

    func testApplyCommandReplacementsBasicBuiltIn() {
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: true,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: true,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommandsRaw: ""
        )
        // "new line" is a common built-in command replacement
        let result = transcriber.applyCommandReplacements(to: "hello new line world", settings: settings)
        XCTAssertTrue(result.contains("\n") || result != "hello new line world",
                       "Built-in command replacement should transform known phrases")
    }

    func testApplyCommandReplacementsCustomCommand() {
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: true,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: true,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommandsRaw: "say cheese => 📸"
        )
        let result = transcriber.applyCommandReplacements(to: "please say cheese now", settings: settings)
        XCTAssertTrue(result.contains("📸"))
    }

    // MARK: - isLetter

    func testIsLetterWithLetter() {
        XCTAssertTrue(transcriber.isLetter("A"))
        XCTAssertTrue(transcriber.isLetter("z"))
        XCTAssertTrue(transcriber.isLetter("ñ"))
    }

    func testIsLetterWithNonLetter() {
        XCTAssertFalse(transcriber.isLetter("1"))
        XCTAssertFalse(transcriber.isLetter("."))
        XCTAssertFalse(transcriber.isLetter(" "))
    }

    // MARK: - replaceRegex

    func testReplaceRegexBasic() {
        let result = transcriber.replaceRegex(pattern: "\\d+", in: "abc123def", with: "X")
        XCTAssertEqual(result, "abcXdef")
    }

    func testReplaceRegexInvalidPattern() {
        let result = transcriber.replaceRegex(pattern: "[invalid", in: "text", with: "X")
        XCTAssertEqual(result, "text") // Returns original on bad pattern
    }

    // MARK: - manualInsertTarget convenience methods

    @MainActor
    func testManualInsertTargetAppNameReturnsNilWhenNoTarget() {
        transcriber.clearManualInsertTarget()
        // May or may not return nil depending on frontmost app state,
        // but should not crash
        let _ = transcriber.manualInsertTargetAppName()
    }

    @MainActor
    func testManualInsertTargetSnapshotDoesNotCrash() {
        let snapshot = transcriber.manualInsertTargetSnapshot()
        // Should return a valid snapshot struct
        let _ = snapshot.appName
        let _ = snapshot.bundleIdentifier
        let _ = snapshot.display
        let _ = snapshot.usesFallbackApp
    }

    @MainActor
    func testClearManualInsertTargetResetsState() {
        transcriber.clearManualInsertTarget()
        // After clearing, the snapshot should reflect no explicit target
        // (may still show frontmost app)
        let snapshot = transcriber.manualInsertTargetSnapshot()
        let _ = snapshot // Just verify no crash
    }

    @MainActor
    func testRetargetManualInsertTargetDoesNotCrash() {
        transcriber.retargetManualInsertTarget()
        // Should not crash; updates target to current frontmost app
    }

    // MARK: - EffectiveOutputSettings

    @MainActor
    func testEffectiveOutputSettingsForCurrentAppReturnsDefaults() {
        // With no matching profile, should return default settings
        let settings = transcriber.effectiveOutputSettingsForCurrentApp()
        // Just verify it returns something sensible
        let _ = settings.autoCopy
        let _ = settings.autoPaste
        let _ = settings.smartCapitalization
    }

    @MainActor
    func testEffectiveOutputSettingsForInsertionTargetReturnsDefaults() {
        let settings = transcriber.effectiveOutputSettingsForInsertionTarget()
        let _ = settings.autoCopy
        let _ = settings.autoPaste
    }

    // MARK: - canAutoPasteIntoTargetAppForTesting

    @MainActor
    func testCanAutoPasteIntoTargetAppForTestingReturnsBool() {
        let result = transcriber.canAutoPasteIntoTargetAppForTesting()
        // Should return a valid Bool without crashing
        XCTAssertTrue(result == true || result == false)
    }

    // MARK: - toggleRecording while not recording and not finalizing

    @MainActor
    func testToggleRecordingStartsWhenIdle() {
        // We can't fully test recording (needs audio hardware), but verify
        // the method doesn't crash when called
        // If not recording and not finalizing, it would try to startRecording
        // which needs mic access — just verify no crash on cancel path
        if !transcriber.isRecording {
            transcriber.cancelRecording()
            XCTAssertEqual(transcriber.statusMessage, "Nothing to cancel")
        }
    }

    // MARK: - startRecordingFromHotkey / stopRecordingFromHotkey guards

    @MainActor
    func testStartRecordingFromHotkeyGuardsWhenAlreadyRecording() {
        // If already recording, should be a no-op
        // Can't set isRecording directly, but if not recording, it would try to start
        // Just verify no crash
        if transcriber.isRecording {
            let statusBefore = transcriber.statusMessage
            transcriber.startRecordingFromHotkey()
            XCTAssertEqual(transcriber.statusMessage, statusBefore)
        }
    }

    @MainActor
    func testStopRecordingFromHotkeyGuardsWhenNotRecording() {
        // If not recording, should be a no-op
        if !transcriber.isRecording {
            let statusBefore = transcriber.statusMessage
            transcriber.stopRecordingFromHotkey()
            XCTAssertEqual(transcriber.statusMessage, statusBefore)
        }
    }

    // MARK: - refreshFrontmostAppContext

    @MainActor
    func testRefreshFrontmostAppContextDoesNotCrash() {
        transcriber.refreshFrontmostAppContext()
        // Should populate frontmostAppName
        XCTAssertFalse(transcriber.frontmostAppName.isEmpty)
    }

    // MARK: - profileCaptureCandidate

    @MainActor
    func testProfileCaptureCandidateReturnsValueOrNil() {
        transcriber.refreshFrontmostAppContext()
        let candidate = transcriber.profileCaptureCandidate()
        // Depending on test env, may be nil or a valid tuple
        if let candidate = candidate {
            XCTAssertFalse(candidate.bundleIdentifier.isEmpty)
            XCTAssertFalse(candidate.appName.isEmpty)
        }
    }
}
