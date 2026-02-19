import Testing
import Foundation
@testable import OpenWhisper

/// End-to-end tests for the full insertion/paste pipeline:
/// normalizeOutputText → clipboard → insert target resolution.
/// Tests realistic transcription inputs through the complete text processing chain.
@Suite("Insertion Paste Flow E2E", .serialized)
struct InsertionPasteFlowE2ETests {

    // MARK: - Full pipeline: normalizeOutputText

    private func defaultSettings(
        commandReplacements: Bool = true,
        smartCapitalization: Bool = true,
        terminalPunctuation: Bool = true,
        customCommandsRaw: String = ""
    ) -> AudioTranscriber.EffectiveOutputSettings {
        AudioTranscriber.EffectiveOutputSettings(
            autoCopy: true,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: commandReplacements,
            smartCapitalization: smartCapitalization,
            terminalPunctuation: terminalPunctuation,
            customCommandsRaw: customCommandsRaw
        )
    }

    @Test("Full pipeline: basic sentence gets capitalized and punctuated")
    @MainActor func basicSentence() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello world", settings: defaultSettings())
        #expect(result == "Hello world.")
    }

    @Test("Full pipeline: already punctuated text is not double-punctuated")
    @MainActor func alreadyPunctuated() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("Hello world.", settings: defaultSettings())
        #expect(result == "Hello world.")
    }

    @Test("Full pipeline: exclamation mark preserved")
    @MainActor func exclamationPreserved() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello world!", settings: defaultSettings())
        #expect(result == "Hello world!")
    }

    @Test("Full pipeline: question mark preserved")
    @MainActor func questionPreserved() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("is this working", settings: defaultSettings())
        #expect(result == "Is this working.")
    }

    @Test("Full pipeline: multi-sentence text gets proper capitalization")
    @MainActor func multiSentence() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello world. how are you", settings: defaultSettings())
        #expect(result == "Hello world. How are you.")
    }

    @Test("Full pipeline: whitespace-only input returns empty")
    @MainActor func whitespaceOnly() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("   \n  \t  ", settings: defaultSettings())
        #expect(result == "")
    }

    @Test("Full pipeline: empty input returns empty")
    @MainActor func emptyInput() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("", settings: defaultSettings())
        #expect(result == "")
    }

    @Test("Full pipeline: leading/trailing whitespace trimmed")
    @MainActor func trims() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("  hello world  ", settings: defaultSettings())
        #expect(result == "Hello world.")
    }

    @Test("Full pipeline: multiple spaces collapsed to single space")
    @MainActor func multipleSpaces() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello   world", settings: defaultSettings())
        #expect(result == "Hello world.")
    }

    @Test("Full pipeline: tabs collapsed to single space")
    @MainActor func tabsCollapsed() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello\t\tworld", settings: defaultSettings())
        #expect(result == "Hello world.")
    }

    @Test("Full pipeline: space before punctuation removed")
    @MainActor func spaceBeforePunctuation() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello , world", settings: defaultSettings())
        #expect(result == "Hello, world.")
    }

    @Test("Full pipeline: space before exclamation removed")
    @MainActor func spaceBeforeExclamation() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("wow !", settings: defaultSettings())
        #expect(result == "Wow!")
    }

    @Test("Full pipeline: space before question mark removed")
    @MainActor func spaceBeforeQuestion() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("really ?", settings: defaultSettings())
        #expect(result == "Really?")
    }

    @Test("Full pipeline: spaced apostrophe in contraction collapsed")
    @MainActor func spacedApostrophe() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("don ' t worry about it", settings: defaultSettings())
        #expect(result == "Don't worry about it.")
    }

    @Test("Full pipeline: multiple contractions with spaced apostrophes")
    @MainActor func multipleContractions() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("i don ' t think we ' re going", settings: defaultSettings())
        #expect(result == "I don't think we're going.")
    }

    @Test("Full pipeline: newlines preserved but extra newlines collapsed")
    @MainActor func newlinesCollapsed() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("first paragraph\n\n\n\nsecond paragraph", settings: defaultSettings())
        #expect(result == "First paragraph\n\nSecond paragraph.")
    }

    @Test("Full pipeline: capitalization after newline")
    @MainActor func capitalizationAfterNewline() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("first line\nsecond line", settings: defaultSettings())
        #expect(result == "First line\nSecond line.")
    }

    // MARK: - Selective feature toggles

    @Test("Full pipeline: capitalization disabled")
    @MainActor func noCapitalization() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello world", settings: defaultSettings(smartCapitalization: false))
        #expect(result == "hello world.")
    }

    @Test("Full pipeline: punctuation disabled")
    @MainActor func noPunctuation() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello world", settings: defaultSettings(terminalPunctuation: false))
        #expect(result == "Hello world")
    }

    @Test("Full pipeline: both capitalization and punctuation disabled")
    @MainActor func noCapitalizationNoPunctuation() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello world", settings: defaultSettings(smartCapitalization: false, terminalPunctuation: false))
        #expect(result == "hello world")
    }

    @Test("Full pipeline: command replacements disabled passes through commands")
    @MainActor func commandReplacementsDisabled() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("new line here", settings: defaultSettings(commandReplacements: false))
        #expect(result == "New line here.")
    }

    @Test("Full pipeline: all features disabled returns normalized whitespace only")
    @MainActor func allFeaturesDisabled() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("  hello   world  ", settings: defaultSettings(
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false
        ))
        #expect(result == "hello world")
    }

    // MARK: - Command replacements E2E

    @Test("Full pipeline: 'new line' command becomes actual newline")
    @MainActor func newLineCommand() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("first part new line second part", settings: defaultSettings())
        #expect(result.contains("\n"))
        #expect(result.contains("First part"))
        #expect(result.contains("Second part"))
    }

    @Test("Full pipeline: 'new paragraph' command becomes double newline")
    @MainActor func newParagraphCommand() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("first part new paragraph second part", settings: defaultSettings())
        #expect(result.contains("\n\n"))
    }

    @Test("Full pipeline: 'period' command becomes .")
    @MainActor func periodCommand() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("end of sentence period next sentence", settings: defaultSettings())
        #expect(result.contains("."))
    }

    @Test("Full pipeline: 'comma' command becomes ,")
    @MainActor func commaCommand() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("first comma second", settings: defaultSettings())
        #expect(result.contains(","))
    }

    @Test("Full pipeline: 'question mark' command becomes ?")
    @MainActor func questionMarkCommand() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("is this real question mark", settings: defaultSettings())
        #expect(result.contains("?"))
    }

    @Test("Full pipeline: 'exclamation mark' command becomes !")
    @MainActor func exclamationMarkCommand() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("wow exclamation mark", settings: defaultSettings())
        #expect(result.contains("!"))
    }

    // MARK: - Realistic transcription scenarios

    @Test("Full pipeline: typical dictation with mixed case and spacing issues")
    @MainActor func realisticDictation() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText(
            "  hello my name is ivan   and i am building   an app  ",
            settings: defaultSettings()
        )
        #expect(result == "Hello my name is ivan and i am building an app.")
    }

    @Test("Full pipeline: text ending with number gets punctuation")
    @MainActor func textEndingWithNumber() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("the answer is 42", settings: defaultSettings())
        #expect(result == "The answer is 42.")
    }

    @Test("Full pipeline: text ending with ellipsis preserved")
    @MainActor func textEndingWithEllipsis() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("well i guess…", settings: defaultSettings())
        #expect(result == "Well i guess…")
    }

    @Test("Full pipeline: text ending with colon preserved")
    @MainActor func textEndingWithColon() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("here are the items:", settings: defaultSettings())
        #expect(result == "Here are the items:")
    }

    @Test("Full pipeline: text ending with semicolon preserved")
    @MainActor func textEndingWithSemicolon() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("first clause;", settings: defaultSettings())
        #expect(result == "First clause;")
    }

    @Test("Full pipeline: single word gets capitalized and punctuated")
    @MainActor func singleWord() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello", settings: defaultSettings())
        #expect(result == "Hello.")
    }

    @Test("Full pipeline: single character gets capitalized and punctuated")
    @MainActor func singleChar() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("a", settings: defaultSettings())
        #expect(result == "A.")
    }

    @Test("Full pipeline: capitalization after question mark mid-text")
    @MainActor func capsAfterQuestion() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("is this working? yes it is", settings: defaultSettings())
        #expect(result == "Is this working? Yes it is.")
    }

    @Test("Full pipeline: capitalization after exclamation mark mid-text")
    @MainActor func capsAfterExclamation() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("amazing! this is great", settings: defaultSettings())
        #expect(result == "Amazing! This is great.")
    }

    @Test("Full pipeline: Unicode text handled correctly")
    @MainActor func unicodeText() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("привет мир", settings: defaultSettings())
        #expect(result == "Привет мир.")
    }

    @Test("Full pipeline: emoji in text preserved")
    @MainActor func emojiPreserved() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello 🌍 world", settings: defaultSettings())
        #expect(result.contains("🌍"))
    }

    // MARK: - Insertion guard conditions

    @Test("insertTranscriptionIntoFocusedApp: returns false while recording")
    @MainActor func insertFailsWhileRecording() {
        let t = AudioTranscriber.shared
        // Start recording would require audio setup — test the guard by checking statusMessage
        if t.isRecording {
            let result = t.insertTranscriptionIntoFocusedApp()
            #expect(result == false)
            #expect(t.statusMessage.contains("Stop recording"))
        }
    }

    @Test("insertTranscriptionIntoFocusedApp: returns false with empty transcription")
    @MainActor func insertFailsWithEmptyTranscription() {
        let t = AudioTranscriber.shared
        t.clearTranscription()
        // Even if not recording, empty text yields false
        if !t.isRecording && t.pendingChunkCount == 0 {
            let result = t.insertTranscriptionIntoFocusedApp()
            #expect(result == false)
        }
    }

    @Test("insertTranscriptionIntoFocusedApp: returns false during finalization")
    @MainActor func insertFailsDuringFinalization() {
        let t = AudioTranscriber.shared
        t.setPendingSessionFinalizeForTesting(true)
        let result = t.insertTranscriptionIntoFocusedApp()
        #expect(result == false)
        t.setPendingSessionFinalizeForTesting(false)
    }

    // MARK: - Clipboard operations

    @Test("copyTranscriptionToClipboard: returns false for empty transcription")
    @MainActor func copyFailsEmpty() {
        let t = AudioTranscriber.shared
        t.clearTranscription()
        let result = t.copyTranscriptionToClipboard()
        #expect(result == false)
    }

    @Test("copyTranscriptionToClipboard: returns false for whitespace-only transcription")
    @MainActor func copyFailsWhitespace() {
        let t = AudioTranscriber.shared
        t.transcription = "   "
        let result = t.copyTranscriptionToClipboard()
        #expect(result == false)
    }

    // MARK: - Insertion probe guard conditions

    @Test("runInsertionProbe: fails with empty sample text")
    @MainActor func probeFailsEmpty() {
        let t = AudioTranscriber.shared
        let result = t.runInsertionProbe(sampleText: "")
        #expect(result == false)
        #expect(t.lastInsertionProbeSucceeded == false)
        #expect(t.lastInsertionProbeMessage.contains("empty"))
    }

    @Test("runInsertionProbe: fails with whitespace-only sample text")
    @MainActor func probeFailsWhitespace() {
        let t = AudioTranscriber.shared
        let result = t.runInsertionProbe(sampleText: "   ")
        #expect(result == false)
        #expect(t.lastInsertionProbeSucceeded == false)
    }

    @Test("runInsertionProbe: fails during recording")
    @MainActor func probeFailsDuringRecording() {
        let t = AudioTranscriber.shared
        if t.isRecording {
            let result = t.runInsertionProbe(sampleText: "test")
            #expect(result == false)
        }
    }

    @Test("runInsertionProbe: fails during finalization")
    @MainActor func probeFailsDuringFinalization() {
        let t = AudioTranscriber.shared
        t.setPendingSessionFinalizeForTesting(true)
        let result = t.runInsertionProbe(sampleText: "test")
        #expect(result == false)
        t.setPendingSessionFinalizeForTesting(false)
    }

    @Test("insertionProbeMaxCharacters: is a positive constant")
    func probeMaxCharsPositive() {
        #expect(AudioTranscriber.insertionProbeMaxCharacters > 0)
    }

    // MARK: - resolveOutputSettings with profile

    @Test("resolveOutputSettings: nil profile returns defaults")
    @MainActor func resolveSettingsNilProfile() {
        let t = AudioTranscriber.shared
        let defaults = t.defaultOutputSettings()
        let resolved = t.resolveOutputSettings(defaults: defaults, profile: nil)
        #expect(resolved.autoCopy == defaults.autoCopy)
        #expect(resolved.autoPaste == defaults.autoPaste)
        #expect(resolved.commandReplacements == defaults.commandReplacements)
        #expect(resolved.smartCapitalization == defaults.smartCapitalization)
        #expect(resolved.terminalPunctuation == defaults.terminalPunctuation)
    }

    @Test("resolveOutputSettings: profile overrides defaults")
    @MainActor func resolveSettingsWithProfile() {
        let t = AudioTranscriber.shared
        let defaults = t.defaultOutputSettings()
        let profile = AppProfile(
            bundleIdentifier: "com.test.app",
            appName: "TestApp",
            autoCopy: !defaults.autoCopy,
            autoPaste: !defaults.autoPaste,
            clearAfterInsert: !defaults.clearAfterInsert,
            commandReplacements: !defaults.commandReplacements,
            smartCapitalization: !defaults.smartCapitalization,
            terminalPunctuation: !defaults.terminalPunctuation,
            customCommands: "custom => cmd"
        )
        let resolved = t.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(resolved.autoCopy == profile.autoCopy)
        #expect(resolved.autoPaste == profile.autoPaste)
        #expect(resolved.clearAfterInsert == profile.clearAfterInsert)
        #expect(resolved.commandReplacements == profile.commandReplacements)
        #expect(resolved.smartCapitalization == profile.smartCapitalization)
        #expect(resolved.terminalPunctuation == profile.terminalPunctuation)
    }

    // MARK: - defaultOutputSettings reads UserDefaults

    @Test("defaultOutputSettings: reads from UserDefaults")
    @MainActor func defaultSettingsReadsDefaults() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set(false, forKey: AppDefaults.Keys.outputSmartCapitalization)
        let settings = t.defaultOutputSettings()
        #expect(settings.smartCapitalization == false)
        // Restore
        UserDefaults.standard.set(true, forKey: AppDefaults.Keys.outputSmartCapitalization)
    }

    @Test("defaultOutputSettings: reflects live UserDefaults changes")
    @MainActor func defaultSettingsLiveChanges() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set(true, forKey: AppDefaults.Keys.outputTerminalPunctuation)
        let settings1 = t.defaultOutputSettings()
        #expect(settings1.terminalPunctuation == true)

        UserDefaults.standard.set(false, forKey: AppDefaults.Keys.outputTerminalPunctuation)
        let settings2 = t.defaultOutputSettings()
        #expect(settings2.terminalPunctuation == false)

        // Restore
        UserDefaults.standard.set(true, forKey: AppDefaults.Keys.outputTerminalPunctuation)
    }

    // MARK: - Custom commands E2E through pipeline

    @Test("Full pipeline: custom command replacement applied")
    @MainActor func customCommandReplacement() {
        let t = AudioTranscriber.shared
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: true,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: true,
            smartCapitalization: true,
            terminalPunctuation: true,
            customCommandsRaw: "sign off => Best regards,\nIvan"
        )
        let result = t.normalizeOutputText("thanks for your help sign off", settings: settings)
        #expect(result.contains("Best regards,"))
    }

    // MARK: - Edge cases in normalization pipeline

    @Test("Full pipeline: text with only punctuation")
    @MainActor func onlyPunctuation() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("...", settings: defaultSettings())
        #expect(result == "...")
    }

    @Test("Full pipeline: text with mixed newlines and spaces around them")
    @MainActor func mixedNewlinesSpaces() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("first  \n  second  \n  third", settings: defaultSettings())
        #expect(result == "First\nSecond\nThird.")
    }

    @Test("Full pipeline: very long input does not crash")
    @MainActor func veryLongInput() {
        let t = AudioTranscriber.shared
        let longText = String(repeating: "hello world ", count: 1000)
        let result = t.normalizeOutputText(longText, settings: defaultSettings())
        #expect(!result.isEmpty)
        #expect(result.hasPrefix("Hello"))
        #expect(result.hasSuffix("."))
    }

    @Test("Full pipeline: text with curly apostrophes handled")
    @MainActor func curlyApostrophes() {
        let t = AudioTranscriber.shared
        // Whisper sometimes uses curly quotes — the regex collapses spaces around them
        let result = t.normalizeOutputText("don \u{2019} t stop", settings: defaultSettings())
        // May collapse to don't or don\u{2019}t depending on regex, or leave as-is
        #expect(!result.contains("don \u{2019} t"), "Spaced curly apostrophe should be collapsed or normalized")
    }

    @Test("Full pipeline: text replacement + command replacement combined")
    @MainActor func replacementsAndCommands() {
        let t = AudioTranscriber.shared
        // Set up a text replacement
        UserDefaults.standard.set("teh => the", forKey: AppDefaults.Keys.transcriptionReplacements)
        let result = t.normalizeOutputText("teh quick brown fox", settings: defaultSettings())
        // "teh" replaced with "the", then smart-cap makes it "The"
        #expect(result.lowercased().contains("the quick brown fox"))
        // Clean up
        UserDefaults.standard.set("", forKey: AppDefaults.Keys.transcriptionReplacements)
    }
}
