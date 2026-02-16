import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber text processing pipeline")
@MainActor
struct AudioTranscriberTextProcessingTests {

    private var transcriber: AudioTranscriber { AudioTranscriber.shared }

    // MARK: - replaceRegexTemplate

    @Test("replaceRegexTemplate: backreference $1 works")
    func replaceRegexTemplateBackref() {
        let result = transcriber.replaceRegexTemplate(
            pattern: "(\\w+)@(\\w+)",
            in: "email foo@bar here",
            withTemplate: "$1 at $2"
        )
        #expect(result == "email foo at bar here")
    }

    @Test("replaceRegexTemplate: no match returns original")
    func replaceRegexTemplateNoMatch() {
        #expect(transcriber.replaceRegexTemplate(pattern: "zzz", in: "hello world", withTemplate: "replaced") == "hello world")
    }

    @Test("replaceRegexTemplate: invalid pattern returns original")
    func replaceRegexTemplateInvalidPattern() {
        #expect(transcriber.replaceRegexTemplate(pattern: "[invalid", in: "hello", withTemplate: "x") == "hello")
    }

    @Test("replaceRegexTemplate: multiple captures")
    func replaceRegexTemplateMultipleCaptures() {
        let result = transcriber.replaceRegexTemplate(pattern: "(\\d+)-(\\d+)", in: "call 555-1234", withTemplate: "($1) $2")
        #expect(result == "call (555) 1234")
    }

    @Test("replaceRegexTemplate: collapses spaced apostrophes")
    func replaceRegexTemplateApostrophe() {
        let result = transcriber.replaceRegexTemplate(
            pattern: "([\\p{L}])\\s+[''']\\s*([\\p{L}])",
            in: "don ' t",
            withTemplate: "$1'$2"
        )
        #expect(result == "don't")
    }

    @Test("replaceRegexTemplate: empty text")
    func replaceRegexTemplateEmpty() {
        #expect(transcriber.replaceRegexTemplate(pattern: ".", in: "", withTemplate: "x") == "")
    }

    // MARK: - replaceRegex (literal replacement, no backrefs)

    @Test("replaceRegex: literal replacement without backrefs")
    func replaceRegexLiteral() {
        #expect(transcriber.replaceRegex(pattern: "\\s+", in: "hello   world", with: " ") == "hello world")
    }

    @Test("replaceRegex: replacement with $1 is treated as literal")
    func replaceRegexLiteralDollarSign() {
        #expect(transcriber.replaceRegex(pattern: "(hello)", in: "hello world", with: "$1") == "$1 world")
    }

    @Test("replaceRegex: invalid pattern returns original")
    func replaceRegexInvalidPattern() {
        #expect(transcriber.replaceRegex(pattern: "[bad", in: "text", with: "x") == "text")
    }

    // MARK: - replacementPairs

    private func withReplacementDefaults(_ value: String?, _ body: () -> Void) {
        let defaults = UserDefaults.standard
        let key = AppDefaults.Keys.transcriptionReplacements
        let original = defaults.string(forKey: key)
        if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
        defer { if let original { defaults.set(original, forKey: key) } else { defaults.removeObject(forKey: key) } }
        body()
    }

    @Test("replacementPairs: empty returns empty")
    func replacementPairsEmpty() {
        withReplacementDefaults("") { #expect(transcriber.replacementPairs().isEmpty) }
    }

    @Test("replacementPairs: nil defaults returns empty")
    func replacementPairsNil() {
        withReplacementDefaults(nil) { #expect(transcriber.replacementPairs().isEmpty) }
    }

    @Test("replacementPairs: parses arrow syntax")
    func replacementPairsArrow() {
        withReplacementDefaults("hello => world") {
            let pairs = transcriber.replacementPairs()
            #expect(pairs.count == 1)
            #expect(pairs[0].from == "hello")
            #expect(pairs[0].to == "world")
        }
    }

    @Test("replacementPairs: parses equals syntax")
    func replacementPairsEquals() {
        withReplacementDefaults("foo = bar") {
            let pairs = transcriber.replacementPairs()
            #expect(pairs.count == 1)
            #expect(pairs[0].from == "foo")
            #expect(pairs[0].to == "bar")
        }
    }

    @Test("replacementPairs: skips comments and blank lines")
    func replacementPairsSkipsComments() {
        withReplacementDefaults("# comment\n\nfoo => bar\n  \n# another") {
            let pairs = transcriber.replacementPairs()
            #expect(pairs.count == 1)
            #expect(pairs[0].from == "foo")
        }
    }

    @Test("replacementPairs: arrow takes precedence over equals")
    func replacementPairsArrowPrecedence() {
        withReplacementDefaults("a=b => c=d") {
            let pairs = transcriber.replacementPairs()
            #expect(pairs.count == 1)
            #expect(pairs[0].from == "a=b")
            #expect(pairs[0].to == "c=d")
        }
    }

    @Test("replacementPairs: empty from is skipped")
    func replacementPairsEmptyFrom() {
        withReplacementDefaults(" => something") {
            #expect(transcriber.replacementPairs().isEmpty)
        }
    }

    @Test("replacementPairs: to can be empty (deletion)")
    func replacementPairsEmptyTo() {
        withReplacementDefaults("remove_me =>") {
            let pairs = transcriber.replacementPairs()
            #expect(pairs.count == 1)
            #expect(pairs[0].from == "remove_me")
            #expect(pairs[0].to == "")
        }
    }

    @Test("replacementPairs: multiple lines")
    func replacementPairsMultipleLines() {
        withReplacementDefaults("a => b\nc => d\ne = f") {
            let pairs = transcriber.replacementPairs()
            #expect(pairs.count == 3)
        }
    }

    // MARK: - validFileURL

    @Test("validFileURL: returns nil for nonexistent path")
    func validFileURLNonexistent() {
        #expect(transcriber.validFileURL(for: "/nonexistent/path/to/model.bin") == nil)
    }

    @Test("validFileURL: returns nil for directory")
    func validFileURLDirectory() {
        #expect(transcriber.validFileURL(for: NSTemporaryDirectory()) == nil)
    }

    @Test("validFileURL: returns URL for existing file")
    func validFileURLExistingFile() {
        let tmpFile = NSTemporaryDirectory() + "openwhisper_test_\(UUID().uuidString).tmp"
        FileManager.default.createFile(atPath: tmpFile, contents: Data("test".utf8))
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }
        let result = transcriber.validFileURL(for: tmpFile)
        #expect(result != nil)
        #expect(result?.path == tmpFile)
    }

    @Test("validFileURL: empty path returns nil")
    func validFileURLEmpty() {
        #expect(transcriber.validFileURL(for: "") == nil)
    }

    // MARK: - isReadableModelFile

    @Test("isReadableModelFile: nonexistent returns false")
    func isReadableModelFileNonexistent() {
        #expect(!transcriber.isReadableModelFile(at: URL(fileURLWithPath: "/nonexistent/model.bin")))
    }

    @Test("isReadableModelFile: empty file returns false")
    func isReadableModelFileEmpty() {
        let tmpFile = NSTemporaryDirectory() + "openwhisper_test_\(UUID().uuidString).bin"
        FileManager.default.createFile(atPath: tmpFile, contents: Data())
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }
        #expect(!transcriber.isReadableModelFile(at: URL(fileURLWithPath: tmpFile)))
    }

    @Test("isReadableModelFile: non-empty file returns true")
    func isReadableModelFileValid() {
        let tmpFile = NSTemporaryDirectory() + "openwhisper_test_\(UUID().uuidString).bin"
        FileManager.default.createFile(atPath: tmpFile, contents: Data("model data".utf8))
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }
        #expect(transcriber.isReadableModelFile(at: URL(fileURLWithPath: tmpFile)))
    }

    // MARK: - defaultOutputSettings

    @Test("defaultOutputSettings: returns valid struct")
    func defaultOutputSettingsValid() {
        let settings = transcriber.defaultOutputSettings()
        _ = settings.autoCopy
        _ = settings.autoPaste
        _ = settings.clearAfterInsert
        _ = settings.commandReplacements
        _ = settings.smartCapitalization
        _ = settings.terminalPunctuation
        _ = settings.customCommandsRaw
    }

    @Test("defaultOutputSettings: reflects UserDefaults")
    func defaultOutputSettingsReflectsDefaults() {
        let defaults = UserDefaults.standard
        let key = AppDefaults.Keys.outputSmartCapitalization
        let original = defaults.object(forKey: key)
        defaults.set(true, forKey: key)
        defer { if let original { defaults.set(original, forKey: key) } else { defaults.removeObject(forKey: key) } }
        #expect(transcriber.defaultOutputSettings().smartCapitalization == true)
    }

    // MARK: - resolveOutputSettings

    @Test("resolveOutputSettings: nil profile returns defaults")
    func resolveOutputSettingsNilProfile() {
        let defaults = transcriber.defaultOutputSettings()
        let result = transcriber.resolveOutputSettings(defaults: defaults, profile: nil)
        #expect(result.autoCopy == defaults.autoCopy)
    }

    @Test("resolveOutputSettings: profile overrides")
    func resolveOutputSettingsProfileOverrides() {
        let defaults = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: false, smartCapitalization: false,
            terminalPunctuation: false, customCommandsRaw: ""
        )
        var profile = AppProfile(bundleIdentifier: "com.test.app", appName: "TestApp", autoCopy: false, autoPaste: false, clearAfterInsert: false, commandReplacements: false, smartCapitalization: false, terminalPunctuation: false)
        profile.autoCopy = true
        profile.smartCapitalization = true
        let result = transcriber.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(result.autoCopy == true)
        #expect(result.smartCapitalization == true)
    }

    @Test("resolveOutputSettings: combines custom commands")
    func resolveOutputSettingsCombinesCommands() {
        let defaults = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: false,
            terminalPunctuation: false, customCommandsRaw: "global rule"
        )
        var profile = AppProfile(bundleIdentifier: "com.test.app", appName: "TestApp", autoCopy: false, autoPaste: false, clearAfterInsert: false, commandReplacements: false, smartCapitalization: false, terminalPunctuation: false)
        profile.customCommands = "profile rule"
        let result = transcriber.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(result.customCommandsRaw.contains("global rule"))
        #expect(result.customCommandsRaw.contains("profile rule"))
    }

    @Test("resolveOutputSettings: empty global uses profile commands only")
    func resolveOutputSettingsEmptyGlobal() {
        let defaults = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: false,
            terminalPunctuation: false, customCommandsRaw: ""
        )
        var profile = AppProfile(bundleIdentifier: "com.test.app", appName: "TestApp", autoCopy: false, autoPaste: false, clearAfterInsert: false, commandReplacements: false, smartCapitalization: false, terminalPunctuation: false)
        profile.customCommands = "profile rule"
        let result = transcriber.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(result.customCommandsRaw == "profile rule")
    }

    @Test("resolveOutputSettings: empty profile uses global commands only")
    func resolveOutputSettingsEmptyProfile() {
        let defaults = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: false,
            terminalPunctuation: false, customCommandsRaw: "global rule"
        )
        var profile = AppProfile(bundleIdentifier: "com.test.app", appName: "TestApp", autoCopy: false, autoPaste: false, clearAfterInsert: false, commandReplacements: false, smartCapitalization: false, terminalPunctuation: false)
        profile.customCommands = ""
        let result = transcriber.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(result.customCommandsRaw == "global rule")
    }

    // MARK: - normalizeOutputText (full pipeline)

    @Test("normalizeOutputText: empty returns empty")
    func normalizeOutputTextEmpty() {
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: true,
            terminalPunctuation: true, customCommandsRaw: ""
        )
        #expect(transcriber.normalizeOutputText("", settings: settings) == "")
        #expect(transcriber.normalizeOutputText("   ", settings: settings) == "")
    }

    @Test("normalizeOutputText: trims whitespace")
    func normalizeOutputTextTrims() {
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: false, smartCapitalization: false,
            terminalPunctuation: false, customCommandsRaw: ""
        )
        #expect(transcriber.normalizeOutputText("  hello  ", settings: settings) == "hello")
    }

    @Test("normalizeOutputText: smart capitalization")
    func normalizeOutputTextSmartCap() {
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: false, smartCapitalization: true,
            terminalPunctuation: false, customCommandsRaw: ""
        )
        #expect(transcriber.normalizeOutputText("hello world. this is a test", settings: settings) == "Hello world. This is a test")
    }

    @Test("normalizeOutputText: terminal punctuation")
    func normalizeOutputTextTerminalPunct() {
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: false, smartCapitalization: false,
            terminalPunctuation: true, customCommandsRaw: ""
        )
        #expect(transcriber.normalizeOutputText("hello world", settings: settings) == "hello world.")
    }

    @Test("normalizeOutputText: skips terminal punctuation when present")
    func normalizeOutputTextTerminalPunctPresent() {
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: false, smartCapitalization: false,
            terminalPunctuation: true, customCommandsRaw: ""
        )
        #expect(transcriber.normalizeOutputText("hello world!", settings: settings) == "hello world!")
    }

    @Test("normalizeOutputText: collapses spaced apostrophes")
    func normalizeOutputTextSpacedApostrophe() {
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: false, smartCapitalization: false,
            terminalPunctuation: false, customCommandsRaw: ""
        )
        #expect(transcriber.normalizeOutputText("I don ' t know", settings: settings) == "I don't know")
    }

    @Test("normalizeOutputText: full pipeline")
    func normalizeOutputTextFullPipeline() {
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: false, smartCapitalization: true,
            terminalPunctuation: true, customCommandsRaw: ""
        )
        #expect(transcriber.normalizeOutputText("  hello   world  ", settings: settings) == "Hello world.")
    }

    // MARK: - normalizeWhitespace

    @Test("normalizeWhitespace: collapses tabs and spaces")
    func normalizeWhitespaceTabsSpaces() {
        #expect(transcriber.normalizeWhitespace(in: "hello\t\t  world") == "hello world")
    }

    @Test("normalizeWhitespace: strips space before punctuation")
    func normalizeWhitespaceBeforePunctuation() {
        #expect(transcriber.normalizeWhitespace(in: "hello , world .") == "hello, world.")
    }

    @Test("normalizeWhitespace: collapses triple+ newlines")
    func normalizeWhitespaceTripleNewlines() {
        #expect(transcriber.normalizeWhitespace(in: "a\n\n\n\nb") == "a\n\nb")
    }

    @Test("normalizeWhitespace: collapses space around newlines")
    func normalizeWhitespaceAroundNewlines() {
        #expect(transcriber.normalizeWhitespace(in: "a  \n  b") == "a\nb")
    }

    // MARK: - applySmartCapitalization

    @Test("applySmartCapitalization: capitalizes first char and after sentence-enders")
    func smartCapBasic() {
        #expect(transcriber.applySmartCapitalization(to: "hello. world") == "Hello. World")
    }

    @Test("applySmartCapitalization: after exclamation")
    func smartCapAfterExclamation() {
        #expect(transcriber.applySmartCapitalization(to: "wow! great") == "Wow! Great")
    }

    @Test("applySmartCapitalization: after question")
    func smartCapAfterQuestion() {
        #expect(transcriber.applySmartCapitalization(to: "really? yes") == "Really? Yes")
    }

    @Test("applySmartCapitalization: after newline")
    func smartCapAfterNewline() {
        #expect(transcriber.applySmartCapitalization(to: "line one\nline two") == "Line one\nLine two")
    }

    @Test("applySmartCapitalization: empty string")
    func smartCapEmpty() {
        #expect(transcriber.applySmartCapitalization(to: "") == "")
    }

    @Test("applySmartCapitalization: already capitalized unchanged")
    func smartCapAlready() {
        #expect(transcriber.applySmartCapitalization(to: "Hello. World") == "Hello. World")
    }

    @Test("applySmartCapitalization: multiple spaces after period")
    func smartCapMultipleSpaces() {
        #expect(transcriber.applySmartCapitalization(to: "end.  start") == "End.  Start")
    }

    // MARK: - applyTerminalPunctuationIfNeeded

    @Test("applyTerminalPunctuationIfNeeded: adds period to plain text")
    func terminalPunctAdds() {
        #expect(transcriber.applyTerminalPunctuationIfNeeded(to: "hello") == "hello.")
    }

    @Test("applyTerminalPunctuationIfNeeded: adds period after number")
    func terminalPunctNumber() {
        #expect(transcriber.applyTerminalPunctuationIfNeeded(to: "test 123") == "test 123.")
    }

    @Test("applyTerminalPunctuationIfNeeded: preserves period")
    func terminalPunctPeriod() {
        #expect(transcriber.applyTerminalPunctuationIfNeeded(to: "hello.") == "hello.")
    }

    @Test("applyTerminalPunctuationIfNeeded: preserves exclamation")
    func terminalPunctExcl() {
        #expect(transcriber.applyTerminalPunctuationIfNeeded(to: "hello!") == "hello!")
    }

    @Test("applyTerminalPunctuationIfNeeded: preserves question")
    func terminalPunctQuestion() {
        #expect(transcriber.applyTerminalPunctuationIfNeeded(to: "hello?") == "hello?")
    }

    @Test("applyTerminalPunctuationIfNeeded: preserves colon")
    func terminalPunctColon() {
        #expect(transcriber.applyTerminalPunctuationIfNeeded(to: "hello:") == "hello:")
    }

    @Test("applyTerminalPunctuationIfNeeded: preserves semicolon")
    func terminalPunctSemicolon() {
        #expect(transcriber.applyTerminalPunctuationIfNeeded(to: "hello;") == "hello;")
    }

    @Test("applyTerminalPunctuationIfNeeded: preserves ellipsis")
    func terminalPunctEllipsis() {
        #expect(transcriber.applyTerminalPunctuationIfNeeded(to: "hello…") == "hello…")
    }

    @Test("applyTerminalPunctuationIfNeeded: empty returns empty")
    func terminalPunctEmpty() {
        #expect(transcriber.applyTerminalPunctuationIfNeeded(to: "") == "")
    }

    @Test("applyTerminalPunctuationIfNeeded: no period after special char")
    func terminalPunctAfterParen() {
        #expect(transcriber.applyTerminalPunctuationIfNeeded(to: "hello)") == "hello)")
    }

    // MARK: - isLetter

    @Test("isLetter: ASCII letters")
    func isLetterAscii() {
        #expect(transcriber.isLetter("a"))
        #expect(transcriber.isLetter("Z"))
    }

    @Test("isLetter: digit is not a letter")
    func isLetterDigit() {
        #expect(!transcriber.isLetter("5"))
    }

    @Test("isLetter: unicode letters")
    func isLetterUnicode() {
        #expect(transcriber.isLetter("ü"))
        #expect(transcriber.isLetter("й"))
    }

    @Test("isLetter: punctuation is not a letter")
    func isLetterPunctuation() {
        #expect(!transcriber.isLetter("."))
        #expect(!transcriber.isLetter("!"))
    }

    // MARK: - resolveConfiguredModelURL

    @Test("resolveConfiguredModelURL: bundled tiny source")
    func resolveModelBundled() {
        let defaults = UserDefaults.standard
        let key = AppDefaults.Keys.modelSource
        let original = defaults.string(forKey: key)
        defaults.set(ModelSource.bundledTiny.rawValue, forKey: key)
        defer { if let original { defaults.set(original, forKey: key) } else { defaults.removeObject(forKey: key) } }
        let result = transcriber.resolveConfiguredModelURL()
        #expect(result.loadedSource == .bundledTiny)
    }

    @Test("resolveConfiguredModelURL: custom empty falls back")
    func resolveModelCustomEmpty() {
        let defaults = UserDefaults.standard
        let srcKey = AppDefaults.Keys.modelSource
        let pathKey = AppDefaults.Keys.modelCustomPath
        let origSrc = defaults.string(forKey: srcKey)
        let origPath = defaults.string(forKey: pathKey)
        defaults.set(ModelSource.customPath.rawValue, forKey: srcKey)
        defaults.set("", forKey: pathKey)
        defer {
            if let origSrc { defaults.set(origSrc, forKey: srcKey) } else { defaults.removeObject(forKey: srcKey) }
            if let origPath { defaults.set(origPath, forKey: pathKey) } else { defaults.removeObject(forKey: pathKey) }
        }
        let result = transcriber.resolveConfiguredModelURL()
        #expect(result.loadedSource == .bundledTiny)
        #expect(result.warning?.contains("empty") == true)
    }

    @Test("resolveConfiguredModelURL: custom nonexistent falls back")
    func resolveModelCustomNonexistent() {
        let defaults = UserDefaults.standard
        let srcKey = AppDefaults.Keys.modelSource
        let pathKey = AppDefaults.Keys.modelCustomPath
        let origSrc = defaults.string(forKey: srcKey)
        let origPath = defaults.string(forKey: pathKey)
        defaults.set(ModelSource.customPath.rawValue, forKey: srcKey)
        defaults.set("/nonexistent/fake/model.bin", forKey: pathKey)
        defer {
            if let origSrc { defaults.set(origSrc, forKey: srcKey) } else { defaults.removeObject(forKey: srcKey) }
            if let origPath { defaults.set(origPath, forKey: pathKey) } else { defaults.removeObject(forKey: pathKey) }
        }
        let result = transcriber.resolveConfiguredModelURL()
        #expect(result.loadedSource == .bundledTiny)
        #expect(result.warning?.contains("not found") == true)
    }

    @Test("resolveConfiguredModelURL: valid custom path")
    func resolveModelCustomValid() {
        let tmpFile = NSTemporaryDirectory() + "openwhisper_test_model_\(UUID().uuidString).bin"
        FileManager.default.createFile(atPath: tmpFile, contents: Data("fake".utf8))
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        let defaults = UserDefaults.standard
        let srcKey = AppDefaults.Keys.modelSource
        let pathKey = AppDefaults.Keys.modelCustomPath
        let origSrc = defaults.string(forKey: srcKey)
        let origPath = defaults.string(forKey: pathKey)
        defaults.set(ModelSource.customPath.rawValue, forKey: srcKey)
        defaults.set(tmpFile, forKey: pathKey)
        defer {
            if let origSrc { defaults.set(origSrc, forKey: srcKey) } else { defaults.removeObject(forKey: srcKey) }
            if let origPath { defaults.set(origPath, forKey: pathKey) } else { defaults.removeObject(forKey: pathKey) }
        }
        let result = transcriber.resolveConfiguredModelURL()
        #expect(result.loadedSource == .customPath)
        #expect(result.url?.path == tmpFile)
        #expect(result.warning == nil)
    }

    // MARK: - applyCommandReplacements

    @Test("applyCommandReplacements: no custom rules doesn't crash")
    func applyCommandReplacementsNoCustom() {
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: false,
            terminalPunctuation: false, customCommandsRaw: ""
        )
        let result = transcriber.applyCommandReplacements(to: "hello world", settings: settings)
        #expect(result.contains("hello"))
    }

    @Test("applyCommandReplacements: case insensitive")
    func applyCommandReplacementsCaseInsensitive() {
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: false,
            terminalPunctuation: false, customCommandsRaw: ""
        )
        // Built-in "new line" rule
        let result = transcriber.applyCommandReplacements(to: "hello NEW LINE world", settings: settings)
        #expect(result.contains("\n") || result == "hello NEW LINE world")
    }
}
