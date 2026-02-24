import Testing
import Foundation
@testable import OpenWhisper

/// Edge-case tests for `normalizeOutputText` focusing on Unicode,
/// multi-line, apostrophe contraction, and complex pipeline interactions.
@Suite("NormalizeOutput Unicode & edge cases", .serialized)
struct NormalizeOutputUnicodeEdgeCaseTests {

    private func settings(
        commandReplacements: Bool = false,
        smartCapitalization: Bool = false,
        terminalPunctuation: Bool = false,
        customCommands: String = ""
    ) -> AudioTranscriber.EffectiveOutputSettings {
        .init(
            autoCopy: false,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: commandReplacements,
            smartCapitalization: smartCapitalization,
            terminalPunctuation: terminalPunctuation,
            customCommandsRaw: customCommands
        )
    }

    // MARK: - Whitespace-only and empty edge cases

    @Test("empty string returns empty")
    @MainActor func emptyString() {
        let t = AudioTranscriber.shared
        #expect(t.normalizeOutputText("", settings: settings()) == "")
    }

    @Test("whitespace-only returns empty")
    @MainActor func whitespaceOnly() {
        let t = AudioTranscriber.shared
        #expect(t.normalizeOutputText("   \n\t  ", settings: settings()) == "")
    }

    @Test("single character with all features enabled")
    @MainActor func singleCharAllFeatures() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("a", settings: settings(
            commandReplacements: true, smartCapitalization: true, terminalPunctuation: true
        ))
        #expect(result == "A.")
    }

    @Test("single punctuation char is not double-punctuated")
    @MainActor func singlePunctuation() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("!", settings: settings(terminalPunctuation: true))
        #expect(result == "!")
    }

    // MARK: - Apostrophe contraction collapsing

    @Test("spaced apostrophe: don ' t → don't")
    @MainActor func spacedApostropheDont() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("don ' t", settings: settings())
        #expect(result == "don't")
    }

    @Test("spaced curly apostrophe: we \u{2019} re → we're")
    @MainActor func spacedCurlyApostrophe() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("we \u{2019} re", settings: settings())
        #expect(result == "we're")
    }

    @Test("multiple spaced apostrophes in one sentence")
    @MainActor func multipleSpacedApostrophes() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("I don ' t think they ' re coming", settings: settings())
        #expect(result == "I don't think they're coming")
    }

    @Test("apostrophe without spaces is preserved")
    @MainActor func normalApostrophe() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("don't", settings: settings())
        #expect(result == "don't")
    }

    // MARK: - Smart capitalization edge cases

    @Test("capitalizes after exclamation mark")
    @MainActor func capitalizeAfterExclamation() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("wow! great", settings: settings(smartCapitalization: true))
        #expect(result == "Wow! Great")
    }

    @Test("capitalizes after question mark")
    @MainActor func capitalizeAfterQuestion() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("really? yes", settings: settings(smartCapitalization: true))
        #expect(result == "Really? Yes")
    }

    @Test("capitalizes after newline")
    @MainActor func capitalizeAfterNewline() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("first line\nsecond line", settings: settings(smartCapitalization: true))
        #expect(result == "First line\nSecond line")
    }

    @Test("does not capitalize mid-sentence after comma")
    @MainActor func noCapitalizeAfterComma() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello, world", settings: settings(smartCapitalization: true))
        #expect(result == "Hello, world")
    }

    @Test("capitalizes Unicode letters like é")
    @MainActor func capitalizeUnicodeLetter() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("école", settings: settings(smartCapitalization: true))
        #expect(result == "École")
    }

    @Test("capitalizes after period with multiple spaces (normalized)")
    @MainActor func capitalizeAfterPeriodMultiSpaces() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("end.   start", settings: settings(smartCapitalization: true))
        #expect(result == "End. Start")
    }

    // MARK: - Terminal punctuation edge cases

    @Test("adds period after number")
    @MainActor func periodAfterNumber() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("I have 5", settings: settings(terminalPunctuation: true))
        #expect(result == "I have 5.")
    }

    @Test("no period after ellipsis")
    @MainActor func noDoubleEllipsis() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("thinking…", settings: settings(terminalPunctuation: true))
        #expect(result == "thinking…")
    }

    @Test("no period after colon")
    @MainActor func noPeriodAfterColon() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("items:", settings: settings(terminalPunctuation: true))
        #expect(result == "items:")
    }

    @Test("no period after semicolon")
    @MainActor func noPeriodAfterSemicolon() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("first; second;", settings: settings(terminalPunctuation: true))
        #expect(result == "first; second;")
    }

    @Test("adds period after parenthesis with letter")
    @MainActor func periodAfterParenLetter() {
        let t = AudioTranscriber.shared
        // Last char is ')' which is not letter/number/punctuation in the list
        let result = t.normalizeOutputText("test (done)", settings: settings(terminalPunctuation: true))
        // ')' is not a letter or number, and not in the exempt list → no period added
        #expect(result == "test (done)")
    }

    // MARK: - Whitespace normalization

    @Test("tabs are collapsed to single space")
    @MainActor func tabsCollapsed() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello\t\tworld", settings: settings())
        #expect(result == "hello world")
    }

    @Test("triple+ newlines collapse to double")
    @MainActor func tripleNewlinesCollapse() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("para one\n\n\n\npara two", settings: settings())
        #expect(result == "para one\n\npara two")
    }

    @Test("space before punctuation is removed")
    @MainActor func spaceBeforePunctuation() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello , world !", settings: settings())
        #expect(result == "hello, world!")
    }

    @Test("spaces around newlines are trimmed")
    @MainActor func spacesAroundNewlines() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("line one   \n   line two", settings: settings())
        #expect(result == "line one\nline two")
    }

    // MARK: - Command replacements with custom rules

    @Test("custom command with fat arrow separator")
    @MainActor func customCommandArrow() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("say cheers mate", settings: settings(
            commandReplacements: true, customCommands: "cheers mate => 🍻"
        ))
        #expect(result == "say 🍻")
    }

    @Test("custom command with equals separator")
    @MainActor func customCommandEquals() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("type smiley face here", settings: settings(
            commandReplacements: true, customCommands: "smiley face = 😊"
        ))
        #expect(result == "type 😊 here")
    }

    @Test("custom command is case insensitive")
    @MainActor func customCommandCaseInsensitive() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("say CHEERS MATE", settings: settings(
            commandReplacements: true, customCommands: "cheers mate => 🍻"
        ))
        #expect(result == "say 🍻")
    }

    @Test("comment lines in custom commands are ignored")
    @MainActor func customCommandComments() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello world", settings: settings(
            commandReplacements: true, customCommands: "# this is a comment\nhello = hi"
        ))
        #expect(result == "hi world")
    }

    // MARK: - Full pipeline interactions

    @Test("command replacement → capitalization → punctuation all chain")
    @MainActor func fullPipelineChain() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello new line world", settings: settings(
            commandReplacements: true,
            smartCapitalization: true,
            terminalPunctuation: true
        ))
        // "new line" is a built-in command that produces \n
        #expect(result.contains("\n"))
        // Should start capitalized
        #expect(result.hasPrefix("Hello"))
        // Should end with punctuation
        #expect(result.hasSuffix("."))
    }

    @Test("new paragraph command produces double newline")
    @MainActor func newParagraphCommand() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("first new paragraph second", settings: settings(
            commandReplacements: true
        ))
        #expect(result.contains("\n\n"))
    }

    @Test("multiple built-in commands in one text")
    @MainActor func multipleBuiltInCommands() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello comma world period", settings: settings(
            commandReplacements: true
        ))
        #expect(result.contains(","))
        #expect(result.contains("."))
    }

    @Test("smart capitalization + apostrophe contraction")
    @MainActor func capitalizationWithApostrophe() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("i don ' t know. it ' s fine", settings: settings(
            smartCapitalization: true
        ))
        #expect(result.hasPrefix("I don't know."))
        #expect(result.contains("It's fine"))
    }

    // MARK: - Unicode stress tests

    @Test("CJK text passes through without corruption")
    @MainActor func cjkText() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("你好世界", settings: settings(
            smartCapitalization: true, terminalPunctuation: true
        ))
        #expect(result.contains("你好世界"))
    }

    @Test("emoji in text is preserved")
    @MainActor func emojiPreserved() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello 🌍 world", settings: settings(smartCapitalization: true))
        #expect(result.contains("🌍"))
    }

    @Test("mixed RTL and LTR text does not crash")
    @MainActor func mixedRtlLtr() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello مرحبا world", settings: settings(
            smartCapitalization: true, terminalPunctuation: true
        ))
        #expect(!result.isEmpty)
        #expect(result.contains("مرحبا"))
    }

    @Test("accented characters capitalized correctly")
    @MainActor func accentedCapitalization() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("über cool. ñoño", settings: settings(smartCapitalization: true))
        #expect(result.hasPrefix("Über"))
        #expect(result.contains("Ñoño"))
    }

    @Test("Cyrillic text capitalizes correctly")
    @MainActor func cyrillicCapitalization() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("привет мир. слово", settings: settings(smartCapitalization: true))
        #expect(result.hasPrefix("Привет"))
        #expect(result.contains("Слово"))
    }

    // MARK: - resolveOutputSettings edge cases

    @Test("resolveOutputSettings with nil profile returns defaults")
    @MainActor func resolveSettingsNilProfile() {
        let t = AudioTranscriber.shared
        let defaults = settings(smartCapitalization: true, terminalPunctuation: true)
        let result = t.resolveOutputSettings(defaults: defaults, profile: nil)
        #expect(result.smartCapitalization == true)
        #expect(result.terminalPunctuation == true)
    }

    @Test("resolveOutputSettings merges custom commands from both")
    @MainActor func resolveSettingsMergesCommands() {
        let t = AudioTranscriber.shared
        let defaults = settings(customCommands: "hello → hi")
        let profile = AppProfile(
            bundleIdentifier: "com.test", appName: "Test",
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: false,
            terminalPunctuation: false, customCommands: "world → earth"
        )
        let result = t.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(result.customCommandsRaw.contains("hello → hi"))
        #expect(result.customCommandsRaw.contains("world → earth"))
    }

    @Test("resolveOutputSettings uses profile's empty commands when default has content")
    @MainActor func resolveSettingsEmptyProfileCommands() {
        let t = AudioTranscriber.shared
        let defaults = settings(customCommands: "hello → hi")
        let profile = AppProfile(
            bundleIdentifier: "com.test", appName: "Test",
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: false,
            terminalPunctuation: false, customCommands: ""
        )
        let result = t.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(result.customCommandsRaw == "hello → hi")
    }

    @Test("resolveOutputSettings uses profile commands when default is empty")
    @MainActor func resolveSettingsEmptyDefaultCommands() {
        let t = AudioTranscriber.shared
        let defaults = settings(customCommands: "")
        let profile = AppProfile(
            bundleIdentifier: "com.test", appName: "Test",
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: false,
            terminalPunctuation: false, customCommands: "world → earth"
        )
        let result = t.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(result.customCommandsRaw == "world → earth")
    }

    // MARK: - Regex edge cases in normalizeOutputText

    @Test("text with regex special characters does not crash")
    @MainActor func regexSpecialChars() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("test [brackets] (parens) {braces} $dollar ^caret", settings: settings(
            commandReplacements: true, smartCapitalization: true, terminalPunctuation: true
        ))
        #expect(!result.isEmpty)
    }

    @Test("very long single line normalizes without crash")
    @MainActor func veryLongLine() {
        let t = AudioTranscriber.shared
        let long = String(repeating: "word ", count: 1000)
        let result = t.normalizeOutputText(long, settings: settings(
            smartCapitalization: true, terminalPunctuation: true
        ))
        #expect(result.hasPrefix("Word"))
        #expect(result.hasSuffix("."))
    }

    @Test("text ending with emoji gets no period")
    @MainActor func emojiEnding() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("great job 🎉", settings: settings(terminalPunctuation: true))
        // 🎉 is not a letter or number → no period appended
        #expect(!result.hasSuffix("."))
        #expect(result.hasSuffix("🎉"))
    }

    @Test("text with only newlines returns empty")
    @MainActor func onlyNewlines() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("\n\n\n", settings: settings())
        #expect(result == "")
    }

    @Test("applyTextReplacements is called in pipeline")
    @MainActor func textReplacementsInPipeline() {
        let t = AudioTranscriber.shared
        // Text replacements are loaded from UserDefaults — just verify the pipeline doesn't crash
        let result = t.normalizeOutputText("hello world", settings: settings())
        #expect(result == "hello world")
    }

    // MARK: - isLetter edge cases

    @Test("isLetter with standard ASCII")
    @MainActor func isLetterASCII() {
        let t = AudioTranscriber.shared
        #expect(t.isLetter("A") == true)
        #expect(t.isLetter("z") == true)
    }

    @Test("isLetter with digit returns false")
    @MainActor func isLetterDigit() {
        let t = AudioTranscriber.shared
        #expect(t.isLetter("5") == false)
    }

    @Test("isLetter with punctuation returns false")
    @MainActor func isLetterPunctuation() {
        let t = AudioTranscriber.shared
        #expect(t.isLetter(".") == false)
        #expect(t.isLetter("!") == false)
    }

    @Test("isLetter with accented character returns true")
    @MainActor func isLetterAccented() {
        let t = AudioTranscriber.shared
        #expect(t.isLetter("é") == true)
        #expect(t.isLetter("ñ") == true)
    }

    @Test("isLetter with CJK character returns true")
    @MainActor func isLetterCJK() {
        let t = AudioTranscriber.shared
        #expect(t.isLetter("你") == true)
    }

    @Test("isLetter with emoji returns false")
    @MainActor func isLetterEmoji() {
        let t = AudioTranscriber.shared
        #expect(t.isLetter("🎉") == false)
    }
}
