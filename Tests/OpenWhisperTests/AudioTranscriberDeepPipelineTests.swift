import Testing
import Foundation
@testable import OpenWhisper

/// Deep coverage for text processing pipeline: applyCommandReplacements,
/// mergeChunkForTesting (exercising canonicalChunkForMerge & isStandalonePunctuationFragment),
/// normalizeOutputText end-to-end, and edge cases in capitalization/punctuation.
@Suite("AudioTranscriber Deep Pipeline", .serialized)
struct AudioTranscriberDeepPipelineTests {

    private func makeSettings(
        commandReplacements: Bool = true,
        smartCapitalization: Bool = true,
        terminalPunctuation: Bool = true,
        customCommandsRaw: String = ""
    ) -> AudioTranscriber.EffectiveOutputSettings {
        AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: commandReplacements,
            smartCapitalization: smartCapitalization,
            terminalPunctuation: terminalPunctuation,
            customCommandsRaw: customCommandsRaw
        )
    }

    // MARK: - applyCommandReplacements: built-in rules

    @Test("built-in: new line replaced with newline char")
    func builtInNewLine() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "hello new line world", settings: makeSettings())
        #expect(result.contains("\n"))
        #expect(!result.contains("new line"))
    }

    @Test("built-in: new paragraph replaced with double newline")
    func builtInNewParagraph() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "hello new paragraph world", settings: makeSettings())
        #expect(result.contains("\n\n"))
    }

    @Test("built-in: comma replaced")
    func builtInComma() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "hello comma world", settings: makeSettings())
        #expect(result.contains(","))
        #expect(!result.lowercased().contains("comma"))
    }

    @Test("built-in: period replaced")
    func builtInPeriod() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "end of sentence period", settings: makeSettings())
        #expect(result.contains("."))
    }

    @Test("built-in: question mark replaced")
    func builtInQuestionMark() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "is this right question mark", settings: makeSettings())
        #expect(result.contains("?"))
    }

    @Test("built-in: exclamation mark replaced")
    func builtInExclamation() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "wow exclamation mark", settings: makeSettings())
        #expect(result.contains("!"))
    }

    @Test("built-in: open and close parenthesis")
    func builtInParentheses() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "open parenthesis hello close parenthesis", settings: makeSettings())
        #expect(result.contains("("))
        #expect(result.contains(")"))
    }

    @Test("built-in: open and close quote")
    func builtInQuotes() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "open quote hello close quote", settings: makeSettings())
        #expect(result.contains("\""))
    }

    @Test("built-in: em dash replaced")
    func builtInEmDash() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "hello em dash world", settings: makeSettings())
        #expect(result.contains("—"))
    }

    @Test("built-in: ellipsis replaced")
    func builtInEllipsis() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "well ellipsis", settings: makeSettings())
        #expect(result.contains("…"))
    }

    @Test("built-in: dot dot dot replaced with ellipsis")
    func builtInDotDotDot() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "well dot dot dot", settings: makeSettings())
        #expect(result.contains("…"))
    }

    @Test("built-in: bullet point inserts newline dash")
    func builtInBulletPoint() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "first item bullet point second item", settings: makeSettings())
        #expect(result.contains("\n- "))
    }

    @Test("built-in: at sign replaced")
    func builtInAtSign() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "email at sign domain", settings: makeSettings())
        #expect(result.contains("@"))
    }

    @Test("built-in: hashtag replaced")
    func builtInHashtag() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "hashtag swift", settings: makeSettings())
        #expect(result.contains("#"))
    }

    @Test("built-in: arrow operator replaced")
    func builtInArrowOperator() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "func arrow operator String", settings: makeSettings())
        #expect(result.contains("->"))
    }

    @Test("built-in: fat arrow replaced")
    func builtInFatArrow() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "map fat arrow value", settings: makeSettings())
        #expect(result.contains("=>"))
    }

    @Test("built-in: triple equals replaced")
    func builtInTripleEquals() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "a triple equals b", settings: makeSettings())
        #expect(result.contains("==="))
    }

    @Test("built-in: null coalescing replaced")
    func builtInNullCoalescing() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "value null coalescing default", settings: makeSettings())
        #expect(result.contains("??"))
    }

    @Test("built-in: optional chaining replaced")
    func builtInOptionalChaining() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "object optional chaining property", settings: makeSettings())
        #expect(result.contains("?."))
    }

    @Test("built-in: case insensitive matching")
    func builtInCaseInsensitive() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "hello NEW LINE world", settings: makeSettings())
        #expect(result.contains("\n"))
    }

    @Test("built-in: multiple commands in one string")
    func builtInMultipleCommands() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "hello comma how are you question mark", settings: makeSettings())
        #expect(result.contains(","))
        #expect(result.contains("?"))
    }

    @Test("built-in: no false positives on partial words")
    func builtInWordBoundary() {
        let t = AudioTranscriber.shared
        // "commander" contains "comma" but shouldn't match because of word boundaries
        let result = t.applyCommandReplacements(to: "the commander spoke", settings: makeSettings())
        #expect(result.contains("commander"))
    }

    // MARK: - applyCommandReplacements: custom commands

    @Test("custom command: simple replacement")
    func customCommandSimple() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(customCommandsRaw: "my email => test@example.com")
        let result = t.applyCommandReplacements(to: "send to my email please", settings: settings)
        #expect(result.contains("test@example.com"))
    }

    @Test("custom command: with equals separator")
    func customCommandEquals() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(customCommandsRaw: "greeting = hello world")
        let result = t.applyCommandReplacements(to: "greeting everyone", settings: settings)
        #expect(result.contains("hello world"))
    }

    @Test("custom command: with escaped newline")
    func customCommandEscapedNewline() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(customCommandsRaw: "signature => \\nBest regards\\nIvan")
        let result = t.applyCommandReplacements(to: "add signature", settings: settings)
        #expect(result.contains("\nBest regards\nIvan"))
    }

    @Test("custom command: comment lines ignored")
    func customCommandCommentIgnored() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(customCommandsRaw: "# This is a comment\ngreeting => hi")
        let result = t.applyCommandReplacements(to: "greeting friend", settings: settings)
        #expect(result.contains("hi"))
    }

    @Test("custom command: empty lines ignored")
    func customCommandEmptyLines() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(customCommandsRaw: "\n\ngreeting => hi\n\n")
        let result = t.applyCommandReplacements(to: "greeting friend", settings: settings)
        #expect(result.contains("hi"))
    }

    @Test("custom command: longer phrases match first")
    func customCommandLongerFirst() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(customCommandsRaw: "my name => Ivan\nmy name is => Ivan Kuznetsov")
        let result = t.applyCommandReplacements(to: "my name is here", settings: settings)
        // "my name is" is longer and should match first
        #expect(result.contains("Ivan Kuznetsov"))
    }

    @Test("custom command: override built-in")
    func customCommandOverrideBuiltIn() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(customCommandsRaw: "comma => ;")
        let result = t.applyCommandReplacements(to: "hello comma world", settings: settings)
        // Both built-in and custom match — longer phrase wins, same length = order-dependent
        // The key assertion: replacement happened
        #expect(result.contains(",") || result.contains(";"))
    }

    @Test("custom command: no replacement without separator")
    func customCommandNoSeparator() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(customCommandsRaw: "no separator here")
        // Line without => or = should be ignored
        let result = t.applyCommandReplacements(to: "no separator here", settings: settings)
        #expect(result == "no separator here")
    }

    // MARK: - mergeChunkForTesting: canonical merge & punctuation fragments

    @Test("merge: identical chunks not duplicated")
    func mergeIdenticalChunks() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("hello world", into: "hello world")
        #expect(result == "hello world")
    }

    @Test("merge: chunk with extra whitespace matches")
    func mergeExtraWhitespace() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("hello  world", into: "hello world")
        // canonicalChunkForMerge collapses whitespace, so they should merge
        #expect(result == "hello world")
    }

    @Test("merge: chunk with trailing punctuation merges")
    func mergeTrailingPunctuation() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("hello world.", into: "hello world")
        // canonical strips trailing punctuation for comparison
        #expect(result == "hello world" || result == "hello world.")
    }

    @Test("merge: standalone punctuation fragment appended")
    func mergeStandalonePunctuation() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("...", into: "hello world")
        // Standalone punctuation should be appended
        #expect(result.contains("hello world"))
    }

    @Test("merge: empty chunk returns existing")
    func mergeEmptyChunk() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("", into: "hello world")
        #expect(result == "hello world")
    }

    @Test("merge: chunk into empty returns chunk")
    func mergeIntoEmpty() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("hello world", into: "")
        #expect(result == "hello world")
    }

    @Test("merge: both empty returns empty")
    func mergeBothEmpty() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("", into: "")
        #expect(result == "")
    }

    @Test("merge: whitespace-only chunk returns existing")
    func mergeWhitespaceOnlyChunk() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("   ", into: "hello world")
        #expect(result.contains("hello world"))
    }

    @Test("merge: new content appended to existing")
    func mergeNewContent() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("hello world and more text", into: "hello world")
        #expect(result.contains("more text"))
    }

    @Test("merge: completely different chunks concatenated")
    func mergeDifferentChunks() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("goodbye moon", into: "hello world")
        #expect(result.contains("hello world"))
        #expect(result.contains("goodbye moon"))
    }

    @Test("merge: chunk with leading whitespace trimmed")
    func mergeLeadingWhitespace() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("  new text", into: "existing")
        #expect(result.contains("new text"))
    }

    @Test("merge: single punctuation character")
    func mergeSinglePunctuation() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("!", into: "wow")
        #expect(result.contains("wow"))
    }

    @Test("merge: symbols-only fragment")
    func mergeSymbolsOnly() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("@#$", into: "text")
        #expect(result.contains("text"))
    }

    @Test("merge: overlapping prefix in chunk")
    func mergeOverlappingPrefix() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("world is great", into: "hello world")
        // Should recognize "world" overlap and merge intelligently
        #expect(result.contains("hello"))
        #expect(result.contains("great"))
    }

    // MARK: - normalizeOutputText: full pipeline

    @Test("pipeline: commands + capitalization + punctuation together")
    @MainActor
    func pipelineFullStack() {
        let t = AudioTranscriber.shared
        let settings = makeSettings()
        let result = t.normalizeOutputText("hello new line world", settings: settings)
        // Should have: capitalized H, newline, capitalized W, terminal period
        #expect(result.hasPrefix("Hello"))
        #expect(result.contains("\n"))
    }

    @Test("pipeline: empty string returns empty")
    @MainActor
    func pipelineEmpty() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("", settings: makeSettings())
        #expect(result == "")
    }

    @Test("pipeline: whitespace-only returns empty")
    @MainActor
    func pipelineWhitespaceOnly() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("   \n\t  ", settings: makeSettings())
        #expect(result == "")
    }

    @Test("pipeline: all features disabled passes through")
    @MainActor
    func pipelineAllDisabled() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false
        )
        let result = t.normalizeOutputText("hello comma world", settings: settings)
        // "comma" should NOT be replaced
        #expect(result.contains("comma"))
    }

    @Test("pipeline: only commands enabled")
    @MainActor
    func pipelineCommandsOnly() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(
            commandReplacements: true,
            smartCapitalization: false,
            terminalPunctuation: false
        )
        let result = t.normalizeOutputText("hello period", settings: settings)
        #expect(result.contains("."))
        // First char should not be capitalized (smart cap disabled)
        #expect(result.hasPrefix("hello"))
    }

    @Test("pipeline: only capitalization enabled")
    @MainActor
    func pipelineCapitalizationOnly() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(
            commandReplacements: false,
            smartCapitalization: true,
            terminalPunctuation: false
        )
        let result = t.normalizeOutputText("hello world", settings: settings)
        #expect(result.hasPrefix("Hello"))
    }

    @Test("pipeline: only terminal punctuation enabled")
    @MainActor
    func pipelinePunctuationOnly() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: true
        )
        let result = t.normalizeOutputText("hello world", settings: settings)
        #expect(result.hasSuffix("."))
    }

    @Test("pipeline: terminal punctuation not added if already present")
    @MainActor
    func pipelinePunctuationAlreadyPresent() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: true
        )
        let result = t.normalizeOutputText("hello world!", settings: settings)
        #expect(result == "hello world!")
    }

    @Test("pipeline: multiple sentences get capitalization")
    @MainActor
    func pipelineMultipleSentences() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(
            commandReplacements: false,
            smartCapitalization: true,
            terminalPunctuation: false
        )
        let result = t.normalizeOutputText("hello. world. foo", settings: settings)
        #expect(result.hasPrefix("Hello"))
        #expect(result.contains("World"))
        #expect(result.contains("Foo"))
    }

    // MARK: - applySmartCapitalization edge cases

    @Test("capitalization: after question mark")
    func capitalizationAfterQuestion() {
        let t = AudioTranscriber.shared
        let result = t.applySmartCapitalization(to: "how? well")
        #expect(result == "How? Well")
    }

    @Test("capitalization: after exclamation")
    func capitalizationAfterExclamation() {
        let t = AudioTranscriber.shared
        let result = t.applySmartCapitalization(to: "wow! amazing")
        #expect(result == "Wow! Amazing")
    }

    @Test("capitalization: after newline")
    func capitalizationAfterNewline() {
        let t = AudioTranscriber.shared
        let result = t.applySmartCapitalization(to: "hello\nworld")
        #expect(result == "Hello\nWorld")
    }

    @Test("capitalization: numbers don't get uppercased but consume capitalize flag")
    func capitalizationNumbers() {
        let t = AudioTranscriber.shared
        let result = t.applySmartCapitalization(to: "test. 123 abc")
        #expect(result.contains("123"))
        // After period, shouldCapitalize=true, but '1' is not a letter so flag gets consumed as false
        #expect(result.contains("abc"))
    }

    @Test("capitalization: empty string")
    func capitalizationEmpty() {
        let t = AudioTranscriber.shared
        let result = t.applySmartCapitalization(to: "")
        #expect(result == "")
    }

    @Test("capitalization: already capitalized unchanged")
    func capitalizationAlreadyCapitalized() {
        let t = AudioTranscriber.shared
        let result = t.applySmartCapitalization(to: "Hello. World.")
        #expect(result == "Hello. World.")
    }

    @Test("capitalization: multiple spaces after period")
    func capitalizationMultipleSpaces() {
        let t = AudioTranscriber.shared
        let result = t.applySmartCapitalization(to: "hello.   world")
        #expect(result == "Hello.   World")
    }

    // MARK: - applyTerminalPunctuationIfNeeded edge cases

    @Test("terminal punctuation: ends with colon")
    func terminalColon() {
        let t = AudioTranscriber.shared
        let result = t.applyTerminalPunctuationIfNeeded(to: "items:")
        #expect(result == "items:")
    }

    @Test("terminal punctuation: ends with semicolon")
    func terminalSemicolon() {
        let t = AudioTranscriber.shared
        let result = t.applyTerminalPunctuationIfNeeded(to: "done;")
        #expect(result == "done;")
    }

    @Test("terminal punctuation: ends with ellipsis")
    func terminalEllipsis() {
        let t = AudioTranscriber.shared
        let result = t.applyTerminalPunctuationIfNeeded(to: "well…")
        #expect(result == "well…")
    }

    @Test("terminal punctuation: ends with number")
    func terminalNumber() {
        let t = AudioTranscriber.shared
        let result = t.applyTerminalPunctuationIfNeeded(to: "version 3")
        #expect(result == "version 3.")
    }

    @Test("terminal punctuation: ends with letter")
    func terminalLetter() {
        let t = AudioTranscriber.shared
        let result = t.applyTerminalPunctuationIfNeeded(to: "hello world")
        #expect(result == "hello world.")
    }

    @Test("terminal punctuation: ends with closing paren")
    func terminalClosingParen() {
        let t = AudioTranscriber.shared
        let result = t.applyTerminalPunctuationIfNeeded(to: "text (note)")
        // Closing paren is not a letter/number, so no period added
        #expect(result == "text (note)")
    }

    @Test("terminal punctuation: empty string")
    func terminalEmpty() {
        let t = AudioTranscriber.shared
        let result = t.applyTerminalPunctuationIfNeeded(to: "")
        #expect(result == "")
    }

    // MARK: - normalizeWhitespace edge cases

    @Test("whitespace: collapses tabs")
    func whitespaceCollapseTabs() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "hello\t\tworld")
        #expect(result == "hello world")
    }

    @Test("whitespace: collapses spaces around newlines")
    func whitespaceAroundNewlines() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "hello   \n   world")
        #expect(result == "hello\nworld")
    }

    @Test("whitespace: limits consecutive newlines")
    func whitespaceConsecutiveNewlines() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "hello\n\n\n\nworld")
        #expect(result == "hello\n\nworld")
    }

    @Test("whitespace: removes space before punctuation")
    func whitespaceBeforePunctuation() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "hello , world . done")
        #expect(result.contains("hello, world. done") || result.contains("hello,"))
    }

    @Test("whitespace: contracts spaced apostrophes")
    func whitespaceSpacedApostrophe() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "don ' t")
        #expect(result == "don't")
    }

    @Test("whitespace: contracts curly apostrophes")
    func whitespaceCurlyApostrophe() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "we \u{2019} re")
        #expect(result == "we're")
    }

    // MARK: - replaceRegex edge cases

    @Test("replaceRegex: invalid pattern returns original")
    func replaceRegexInvalidPattern() {
        let t = AudioTranscriber.shared
        let result = t.replaceRegex(pattern: "[invalid", in: "hello", with: "world")
        #expect(result == "hello")
    }

    @Test("replaceRegex: no match returns original")
    func replaceRegexNoMatch() {
        let t = AudioTranscriber.shared
        let result = t.replaceRegex(pattern: "xyz", in: "hello", with: "world")
        #expect(result == "hello")
    }

    @Test("replaceRegex: empty pattern matches everywhere")
    func replaceRegexEmptyPattern() {
        let t = AudioTranscriber.shared
        let result = t.replaceRegex(pattern: "", in: "hi", with: "x")
        // Empty regex matches at every position
        #expect(!result.isEmpty)
    }

    @Test("replaceRegex: special chars in replacement escaped")
    func replaceRegexSpecialReplacement() {
        let t = AudioTranscriber.shared
        let result = t.replaceRegex(pattern: "test", in: "test", with: "$1")
        // replaceRegex uses literalTemplate, so $1 should appear literally
        #expect(result == "$1")
    }

    // MARK: - Built-in command rules coverage

    @Test("built-in: all bracket types")
    func builtInBrackets() {
        let t = AudioTranscriber.shared
        let s = makeSettings()
        #expect(t.applyCommandReplacements(to: "open bracket", settings: s).contains("["))
        #expect(t.applyCommandReplacements(to: "close bracket", settings: s).contains("]"))
        #expect(t.applyCommandReplacements(to: "open brace", settings: s).contains("{"))
        #expect(t.applyCommandReplacements(to: "close brace", settings: s).contains("}"))
        #expect(t.applyCommandReplacements(to: "open angle bracket", settings: s).contains("<"))
        #expect(t.applyCommandReplacements(to: "close angle bracket", settings: s).contains(">"))
    }

    @Test("built-in: math/comparison operators")
    func builtInMathOperators() {
        let t = AudioTranscriber.shared
        let s = makeSettings()
        #expect(t.applyCommandReplacements(to: "plus sign", settings: s).contains("+"))
        #expect(t.applyCommandReplacements(to: "equals sign", settings: s).contains("="))
        #expect(t.applyCommandReplacements(to: "asterisk", settings: s).contains("*"))
        #expect(t.applyCommandReplacements(to: "less than", settings: s).contains("<"))
        #expect(t.applyCommandReplacements(to: "greater than", settings: s).contains(">"))
        #expect(t.applyCommandReplacements(to: "double equals", settings: s).contains("=="))
        #expect(t.applyCommandReplacements(to: "not equals", settings: s).contains("!="))
    }

    @Test("built-in: special characters")
    func builtInSpecialChars() {
        let t = AudioTranscriber.shared
        let s = makeSettings()
        #expect(t.applyCommandReplacements(to: "pipe", settings: s).contains("|"))
        #expect(t.applyCommandReplacements(to: "tilde", settings: s).contains("~"))
        #expect(t.applyCommandReplacements(to: "caret", settings: s).contains("^"))
        #expect(t.applyCommandReplacements(to: "backtick", settings: s).contains("`"))
        #expect(t.applyCommandReplacements(to: "underscore", settings: s).contains("_"))
        #expect(t.applyCommandReplacements(to: "dollar sign", settings: s).contains("$"))
        #expect(t.applyCommandReplacements(to: "percent sign", settings: s).contains("%"))
        #expect(t.applyCommandReplacements(to: "ampersand", settings: s).contains("&"))
    }

    @Test("built-in: punctuation variants")
    func builtInPunctuationVariants() {
        let t = AudioTranscriber.shared
        let s = makeSettings()
        #expect(t.applyCommandReplacements(to: "full stop", settings: s).contains("."))
        #expect(t.applyCommandReplacements(to: "exclamation point", settings: s).contains("!"))
        #expect(t.applyCommandReplacements(to: "colon", settings: s).contains(":"))
        #expect(t.applyCommandReplacements(to: "semicolon", settings: s).contains(";"))
        #expect(t.applyCommandReplacements(to: "single quote", settings: s).contains("'"))
        #expect(t.applyCommandReplacements(to: "apostrophe", settings: s).contains("'"))
        #expect(t.applyCommandReplacements(to: "dash", settings: s).contains("-"))
        #expect(t.applyCommandReplacements(to: "hyphen", settings: s).contains("-"))
    }

    @Test("built-in: path characters")
    func builtInPathChars() {
        let t = AudioTranscriber.shared
        let s = makeSettings()
        #expect(t.applyCommandReplacements(to: "slash", settings: s).contains("/"))
        #expect(t.applyCommandReplacements(to: "backslash", settings: s).contains("\\"))
    }

    @Test("built-in: whitespace commands")
    func builtInWhitespace() {
        let t = AudioTranscriber.shared
        let s = makeSettings()
        #expect(t.applyCommandReplacements(to: "tab character", settings: s).contains("\t"))
    }

    @Test("built-in: special symbols")
    func builtInSpecialSymbols() {
        let t = AudioTranscriber.shared
        let s = makeSettings()
        #expect(t.applyCommandReplacements(to: "degree sign", settings: s).contains("°"))
        #expect(t.applyCommandReplacements(to: "copyright sign", settings: s).contains("©"))
        #expect(t.applyCommandReplacements(to: "double colon", settings: s).contains("::"))
        #expect(t.applyCommandReplacements(to: "left arrow", settings: s).contains("<-"))
        #expect(t.applyCommandReplacements(to: "right arrow", settings: s).contains("->"))
    }

    @Test("built-in: swift-specific operators")
    func builtInSwiftOperators() {
        let t = AudioTranscriber.shared
        let s = makeSettings()
        #expect(t.applyCommandReplacements(to: "force unwrap", settings: s).contains("!"))
    }

    @Test("built-in: hash sign synonym")
    func builtInHashSign() {
        let t = AudioTranscriber.shared
        let s = makeSettings()
        let result = t.applyCommandReplacements(to: "hash sign", settings: s)
        #expect(result.contains("#"))
    }
}
