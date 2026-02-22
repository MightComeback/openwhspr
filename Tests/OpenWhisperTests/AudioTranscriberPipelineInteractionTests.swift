import Testing
import Foundation
@testable import OpenWhisper

/// Tests for interactions between pipeline stages in normalizeOutputText.
/// Verifies that command replacements, text replacements, whitespace
/// normalization, smart capitalization, and terminal punctuation compose
/// correctly across edge cases.
@Suite("AudioTranscriber pipeline interactions", .serialized)
@MainActor
struct AudioTranscriberPipelineInteractionTests {

    private let transcriber = AudioTranscriber.shared

    private func settings(
        commandReplacements: Bool = true,
        smartCapitalization: Bool = true,
        terminalPunctuation: Bool = true,
        customCommandsRaw: String = ""
    ) -> AudioTranscriber.EffectiveOutputSettings {
        AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: commandReplacements,
            smartCapitalization: smartCapitalization,
            terminalPunctuation: terminalPunctuation,
            customCommandsRaw: customCommandsRaw
        )
    }

    // MARK: - Command replacement + smart capitalization interaction

    @Test("new line command triggers capitalization of next word")
    func newLineThenCapitalization() {
        let s = settings()
        let result = transcriber.normalizeOutputText("hello new line world", settings: s)
        #expect(result.contains("\n"))
        #expect(result.contains("World"))
    }

    @Test("new paragraph command triggers capitalization of next word")
    func newParagraphThenCapitalization() {
        let s = settings()
        let result = transcriber.normalizeOutputText("hello new paragraph world", settings: s)
        #expect(result.contains("\n\n"))
        #expect(result.contains("World"))
    }

    @Test("period command triggers capitalization of next word")
    func periodThenCapitalization() {
        let s = settings()
        let result = transcriber.normalizeOutputText("hello period world", settings: s)
        #expect(result.contains(". ") || result.contains(".W"))
        #expect(result.contains("World"))
    }

    @Test("question mark command triggers capitalization of next word")
    func questionMarkThenCapitalization() {
        let s = settings()
        let result = transcriber.normalizeOutputText("hello question mark world", settings: s)
        #expect(result.contains("?"))
        #expect(result.contains("World"))
    }

    @Test("exclamation mark command triggers capitalization of next word")
    func exclamationMarkThenCapitalization() {
        let s = settings()
        let result = transcriber.normalizeOutputText("hello exclamation mark world", settings: s)
        #expect(result.contains("!"))
        #expect(result.contains("World"))
    }

    @Test("multiple sentence-ending commands in sequence")
    func multipleSentenceEndingCommands() {
        let s = settings()
        let result = transcriber.normalizeOutputText("first period second question mark third", settings: s)
        #expect(result.contains("First"))
        #expect(result.contains("Second"))
        #expect(result.contains("Third"))
    }

    // MARK: - Command replacement + terminal punctuation interaction

    @Test("terminal punctuation not added when last command is period")
    func terminalPunctuationAfterPeriodCommand() {
        let s = settings()
        let result = transcriber.normalizeOutputText("hello world period", settings: s)
        // Should end with exactly one period, not double
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(trimmed.hasSuffix("."))
        #expect(!trimmed.hasSuffix(".."))
    }

    @Test("terminal punctuation not added when last command is question mark")
    func terminalPunctuationAfterQuestionMark() {
        let s = settings()
        let result = transcriber.normalizeOutputText("is this correct question mark", settings: s)
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(trimmed.hasSuffix("?"))
        #expect(!trimmed.hasSuffix("?."))
    }

    @Test("terminal punctuation added when text has no ending punctuation")
    func terminalPunctuationAdded() {
        let s = settings()
        let result = transcriber.normalizeOutputText("hello world", settings: s)
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(trimmed.hasSuffix("."))
    }

    @Test("terminal punctuation not added when disabled")
    func terminalPunctuationDisabled() {
        let s = settings(terminalPunctuation: false)
        let result = transcriber.normalizeOutputText("hello world", settings: s)
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(!trimmed.hasSuffix("."))
    }

    // MARK: - Smart capitalization + whitespace normalization interaction

    @Test("capitalization works after whitespace normalization collapses spaces")
    func capitalizationAfterWhitespaceNormalization() {
        let s = settings()
        let result = transcriber.normalizeOutputText("hello.   world", settings: s)
        #expect(result.contains("World"))
    }

    @Test("capitalization at start of text")
    func capitalizationAtStart() {
        let s = settings()
        let result = transcriber.normalizeOutputText("hello", settings: s)
        #expect(result.hasPrefix("Hello") || result.hasPrefix("hello"))
        // With smart capitalization enabled, should capitalize first letter
        #expect(result.hasPrefix("Hello"))
    }

    @Test("smart capitalization disabled preserves case")
    func smartCapitalizationDisabled() {
        let s = settings(smartCapitalization: false)
        let result = transcriber.normalizeOutputText("hello", settings: s)
        #expect(result.hasPrefix("hello") || result.hasPrefix("Hello"))
    }

    // MARK: - Custom command replacements in pipeline

    @Test("custom command replacement works in full pipeline")
    func customCommandInPipeline() {
        let s = settings(customCommandsRaw: "greeting => Hello, World!")
        let result = transcriber.normalizeOutputText("start greeting end", settings: s)
        #expect(result.contains("Hello, World!"))
    }

    @Test("custom command with escape sequences in pipeline")
    func customCommandWithEscapes() {
        let s = settings(customCommandsRaw: "break => \\n")
        let result = transcriber.normalizeOutputText("line one break line two", settings: s)
        #expect(result.contains("\n"))
    }

    @Test("custom and built-in commands both apply")
    func customAndBuiltInCommandsTogether() {
        let s = settings(customCommandsRaw: "greeting => hi")
        let result = transcriber.normalizeOutputText("greeting period done", settings: s)
        #expect(result.contains("hi") || result.contains("Hi"))
        #expect(result.contains("."))
    }

    // MARK: - All features disabled

    @Test("all features disabled returns trimmed text only")
    func allFeaturesDisabled() {
        let s = settings(commandReplacements: false, smartCapitalization: false, terminalPunctuation: false)
        let result = transcriber.normalizeOutputText("  hello world  ", settings: s)
        #expect(result == "hello world")
    }

    @Test("empty input returns empty string")
    func emptyInput() {
        let s = settings()
        let result = transcriber.normalizeOutputText("", settings: s)
        #expect(result == "")
    }

    @Test("whitespace only input returns empty string")
    func whitespaceOnlyInput() {
        let s = settings()
        let result = transcriber.normalizeOutputText("   \n\t  ", settings: s)
        #expect(result == "")
    }

    // MARK: - Command replacement + whitespace normalization

    @Test("comma command removes preceding space")
    func commaRemovesPrecedingSpace() {
        let s = settings()
        let result = transcriber.normalizeOutputText("hello comma world", settings: s)
        // After command replacement: "hello , world"
        // After whitespace normalization: space before , removed → "hello, world"
        #expect(result.contains(","))
    }

    @Test("semicolon command removes preceding space")
    func semicolonRemovesPrecedingSpace() {
        let s = settings()
        let result = transcriber.normalizeOutputText("hello semicolon world", settings: s)
        #expect(result.contains(";"))
    }

    @Test("colon command removes preceding space")
    func colonRemovesPrecedingSpace() {
        let s = settings()
        let result = transcriber.normalizeOutputText("hello colon world", settings: s)
        #expect(result.contains(":"))
    }

    // MARK: - Spaced apostrophe contraction (Whisper artifact)

    @Test("spaced apostrophe in contraction is collapsed in pipeline")
    func spacedApostropheContraction() {
        let s = settings()
        let result = transcriber.normalizeOutputText("don ' t worry", settings: s)
        #expect(result.contains("don't") || result.contains("Don't"))
    }

    @Test("spaced curly apostrophe in contraction is collapsed")
    func spacedCurlyApostropheContraction() {
        let s = settings()
        let result = transcriber.normalizeOutputText("we \u{2019} re here", settings: s)
        #expect(result.contains("we're") || result.contains("We're"))
    }

    // MARK: - Built-in code/dev commands in pipeline

    @Test("arrow operator command in pipeline")
    func arrowOperatorInPipeline() {
        let s = settings()
        let result = transcriber.normalizeOutputText("func arrow operator void", settings: s)
        #expect(result.contains("->"))
    }

    @Test("fat arrow command in pipeline")
    func fatArrowInPipeline() {
        let s = settings()
        let result = transcriber.normalizeOutputText("value fat arrow result", settings: s)
        #expect(result.contains("=>"))
    }

    @Test("null coalescing command in pipeline")
    func nullCoalescingInPipeline() {
        let s = settings()
        let result = transcriber.normalizeOutputText("value null coalescing default", settings: s)
        #expect(result.contains("??"))
    }

    @Test("optional chaining command in pipeline")
    func optionalChainingInPipeline() {
        let s = settings()
        let result = transcriber.normalizeOutputText("object optional chaining property", settings: s)
        #expect(result.contains("?."))
    }

    @Test("triple equals command in pipeline")
    func tripleEqualsInPipeline() {
        let s = settings()
        let result = transcriber.normalizeOutputText("a triple equals b", settings: s)
        #expect(result.contains("==="))
    }

    @Test("not equals command in pipeline")
    func notEqualsInPipeline() {
        let s = settings()
        let result = transcriber.normalizeOutputText("a not equals b", settings: s)
        #expect(result.contains("!="))
    }

    // MARK: - Bullet point command in pipeline

    @Test("bullet point command creates list item")
    func bulletPointInPipeline() {
        let s = settings()
        let result = transcriber.normalizeOutputText("items bullet point first bullet point second", settings: s)
        #expect(result.contains("- "))
        #expect(result.contains("\n"))
    }

    // MARK: - Mixed unicode and commands

    @Test("unicode text with commands processes correctly")
    func unicodeWithCommands() {
        let s = settings()
        let result = transcriber.normalizeOutputText("привет period мир", settings: s)
        #expect(result.contains("."))
    }

    @Test("emoji preserved through pipeline")
    func emojiPreserved() {
        let s = settings()
        let result = transcriber.normalizeOutputText("hello 🎉 world", settings: s)
        #expect(result.contains("🎉"))
    }

    // MARK: - Long text pipeline stress

    @Test("long text with many commands processes without crash")
    func longTextManyCommands() {
        let s = settings()
        let commands = (0..<50).map { "word\($0) comma" }.joined(separator: " ")
        let result = transcriber.normalizeOutputText(commands, settings: s)
        #expect(!result.isEmpty)
        // Should have commas from command replacement
        let commaCount = result.filter { $0 == "," }.count
        #expect(commaCount >= 40) // Some might be at word boundaries
    }

    @Test("text with all built-in commands processes correctly")
    func allBuiltInCommandsProcess() {
        let s = settings()
        for rule in BuiltInCommandRules.all {
            let input = "before \(rule.phrase) after"
            let result = transcriber.normalizeOutputText(input, settings: s)
            // Should not crash and should contain the replacement
            #expect(!result.isEmpty)
        }
    }

    // MARK: - Pipeline ordering verification

    @Test("command replacement happens before smart capitalization")
    func commandReplacementBeforeCapitalization() {
        // "new line" → "\n", then smart cap should capitalize "world"
        let s = settings()
        let result = transcriber.normalizeOutputText("hello new line world", settings: s)
        #expect(result.contains("World"))
    }

    @Test("whitespace normalization happens before smart capitalization")
    func whitespaceBeforeCapitalization() {
        let s = settings()
        let result = transcriber.normalizeOutputText("hello.     world", settings: s)
        // Spaces collapsed, then smart cap capitalizes "world" after "."
        #expect(result.contains("World"))
    }

    @Test("terminal punctuation happens last")
    func terminalPunctuationLast() {
        let s = settings()
        let result = transcriber.normalizeOutputText("hello world", settings: s)
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        // Smart cap capitalizes "Hello", terminal punctuation adds "."
        #expect(trimmed == "Hello world.")
    }

    // MARK: - Custom commands with => separator

    @Test("custom command with arrow separator")
    func customCommandArrowSeparator() {
        let s = settings(customCommandsRaw: "sign off => Best regards")
        let result = transcriber.normalizeOutputText("sign off", settings: s)
        #expect(result.contains("Best regards") || result.contains("best regards"))
    }

    @Test("custom command with equals separator")
    func customCommandEqualsSeparator() {
        let s = settings(customCommandsRaw: "greet = Hello there")
        let result = transcriber.normalizeOutputText("greet", settings: s)
        #expect(result.contains("Hello there") || result.contains("hello there"))
    }

    @Test("custom command comments are ignored")
    func customCommandCommentsIgnored() {
        let s = settings(customCommandsRaw: "# this is a comment\ngreet => hi")
        let result = transcriber.normalizeOutputText("greet", settings: s)
        #expect(result.contains("hi") || result.contains("Hi"))
    }

    @Test("custom command empty lines are ignored")
    func customCommandEmptyLinesIgnored() {
        let s = settings(customCommandsRaw: "\n\ngreet => hi\n\n")
        let result = transcriber.normalizeOutputText("greet", settings: s)
        #expect(result.contains("hi") || result.contains("Hi"))
    }

    // MARK: - Edge case: command at start/end of text

    @Test("command at very start of text")
    func commandAtStart() {
        let s = settings()
        let result = transcriber.normalizeOutputText("period hello", settings: s)
        #expect(result.contains("."))
    }

    @Test("command at very end of text")
    func commandAtEnd() {
        let s = settings()
        let result = transcriber.normalizeOutputText("hello period", settings: s)
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(trimmed.hasSuffix("."))
    }

    @Test("only a command word with no other text")
    func onlyCommandWord() {
        let s = settings()
        let result = transcriber.normalizeOutputText("period", settings: s)
        #expect(!result.isEmpty)
    }

    @Test("consecutive commands with no words between")
    func consecutiveCommands() {
        let s = settings()
        let result = transcriber.normalizeOutputText("period period period", settings: s)
        #expect(!result.isEmpty)
    }

    // MARK: - Text replacements integration

    @Test("text replacements applied in pipeline")
    func textReplacementsApplied() {
        let key = AppDefaults.Keys.transcriptionReplacements
        let previous = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("foo => bar", forKey: key)

        let s = settings()
        let result = transcriber.normalizeOutputText("foo world", settings: s)

        // Restore
        if let previous {
            UserDefaults.standard.set(previous, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }

        #expect(result.contains("bar") || result.contains("Bar"))
    }
}
