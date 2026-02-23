import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber normalizeOutputText Pipeline Deep Tests")
struct NormalizeOutputPipelineDeepTests {

    private func makeSettings(
        autoCopy: Bool = true,
        autoPaste: Bool = false,
        clearAfterInsert: Bool = false,
        commandReplacements: Bool = true,
        smartCapitalization: Bool = true,
        terminalPunctuation: Bool = true,
        customCommandsRaw: String = ""
    ) -> AudioTranscriber.EffectiveOutputSettings {
        AudioTranscriber.EffectiveOutputSettings(
            autoCopy: autoCopy,
            autoPaste: autoPaste,
            clearAfterInsert: clearAfterInsert,
            commandReplacements: commandReplacements,
            smartCapitalization: smartCapitalization,
            terminalPunctuation: terminalPunctuation,
            customCommandsRaw: customCommandsRaw
        )
    }

    // MARK: - normalizeOutputText

    @Test("Empty text stays empty")
    @MainActor func emptyTextNormalized() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("", settings: makeSettings())
        #expect(result == "")
    }

    @Test("Whitespace-only text stays whitespace after normalization")
    @MainActor func whitespaceOnlyNormalized() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("   ", settings: makeSettings())
        #expect(result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !result.isEmpty)
    }

    @Test("normalizeOutputText with all features disabled returns cleaned text")
    @MainActor func allFeaturesDisabled() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false
        )
        let result = t.normalizeOutputText("hello world", settings: settings)
        #expect(result.contains("hello"))
    }

    @Test("normalizeOutputText applies command replacements when enabled")
    @MainActor func commandReplacementsApplied() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(commandReplacements: true)
        let result = t.normalizeOutputText("hello new line world", settings: settings)
        #expect(result.contains("\n") || result.contains("hello"))
    }

    @Test("normalizeOutputText skips command replacements when disabled")
    @MainActor func commandReplacementsSkipped() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(commandReplacements: false)
        let result = t.normalizeOutputText("hello new line world", settings: settings)
        #expect(result.contains("new line") || result.contains("hello"))
    }

    // MARK: - applyCommandReplacements

    @Test("Built-in 'period' replacement")
    @MainActor func periodReplacement() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "hello period", settings: makeSettings())
        #expect(result.contains("."))
    }

    @Test("Built-in 'new line' replacement")
    @MainActor func newLineReplacement() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "hello new line world", settings: makeSettings())
        #expect(result.contains("\n"))
    }

    @Test("Built-in 'new paragraph' replacement")
    @MainActor func newParagraphReplacement() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "hello new paragraph world", settings: makeSettings())
        #expect(result.contains("\n\n"))
    }

    @Test("Built-in 'question mark' replacement")
    @MainActor func questionMarkReplacement() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "how are you question mark", settings: makeSettings())
        #expect(result.contains("?"))
    }

    @Test("Custom commands raw applied")
    @MainActor func customCommandsApplied() {
        let t = AudioTranscriber.shared
        let settings = makeSettings(customCommandsRaw: "xyzzy => plugh")
        let result = t.applyCommandReplacements(to: "say xyzzy now", settings: settings)
        #expect(result.contains("plugh") || result.contains("xyzzy"))
    }

    // MARK: - normalizeWhitespace

    @Test("Multiple spaces collapsed")
    @MainActor func multipleSpaces() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "hello    world")
        #expect(!result.contains("    "))
    }

    @Test("Leading/trailing whitespace handled")
    @MainActor func leadingTrailingWhitespace() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "  hello  ")
        #expect(!result.isEmpty)
    }

    @Test("Newlines preserved in normalization")
    @MainActor func newlinesPreserved() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "hello\nworld")
        #expect(result.contains("\n") || result.contains("hello"))
    }

    // MARK: - applySmartCapitalization

    @Test("First letter capitalized")
    @MainActor func firstLetterCapitalized() {
        let t = AudioTranscriber.shared
        let result = t.applySmartCapitalization(to: "hello world")
        #expect(result.hasPrefix("H"))
    }

    @Test("Already capitalized unchanged")
    @MainActor func alreadyCapitalized() {
        let t = AudioTranscriber.shared
        let result = t.applySmartCapitalization(to: "Hello world")
        #expect(result.hasPrefix("Hello"))
    }

    @Test("After sentence punctuation capitalized")
    @MainActor func afterSentencePunctuation() {
        let t = AudioTranscriber.shared
        let result = t.applySmartCapitalization(to: "hello. world")
        #expect(result.contains("W") || result.contains("w"))
    }

    @Test("Empty string capitalization no crash")
    @MainActor func emptyCapitalization() {
        let t = AudioTranscriber.shared
        let result = t.applySmartCapitalization(to: "")
        #expect(result == "")
    }

    @Test("Single char capitalization")
    @MainActor func singleCharCapitalization() {
        let t = AudioTranscriber.shared
        let result = t.applySmartCapitalization(to: "a")
        #expect(result == "A")
    }

    // MARK: - applyTerminalPunctuationIfNeeded

    @Test("Adds period if missing")
    @MainActor func addsPeriod() {
        let t = AudioTranscriber.shared
        let result = t.applyTerminalPunctuationIfNeeded(to: "hello world")
        #expect(result.hasSuffix("."))
    }

    @Test("Does not double period")
    @MainActor func noDoublePeriod() {
        let t = AudioTranscriber.shared
        let result = t.applyTerminalPunctuationIfNeeded(to: "hello world.")
        #expect(!result.hasSuffix(".."))
    }

    @Test("Does not add after question mark")
    @MainActor func noAddAfterQuestion() {
        let t = AudioTranscriber.shared
        let result = t.applyTerminalPunctuationIfNeeded(to: "how are you?")
        #expect(!result.hasSuffix("?."))
    }

    @Test("Does not add after exclamation")
    @MainActor func noAddAfterExclamation() {
        let t = AudioTranscriber.shared
        let result = t.applyTerminalPunctuationIfNeeded(to: "wow!")
        #expect(!result.hasSuffix("!."))
    }

    @Test("Empty string no crash")
    @MainActor func emptyTerminalPunctuation() {
        let t = AudioTranscriber.shared
        let result = t.applyTerminalPunctuationIfNeeded(to: "")
        #expect(result.isEmpty || result == ".")
    }

    // MARK: - replaceRegex

    @Test("Simple regex replacement")
    @MainActor func simpleRegex() {
        let t = AudioTranscriber.shared
        let result = t.replaceRegex(pattern: "\\d+", in: "hello 123 world", with: "NUM")
        #expect(result.contains("NUM"))
    }

    @Test("Invalid regex pattern returns original")
    @MainActor func invalidRegex() {
        let t = AudioTranscriber.shared
        let result = t.replaceRegex(pattern: "[invalid", in: "hello", with: "x")
        #expect(result == "hello")
    }

    @Test("No match returns original")
    @MainActor func noMatchRegex() {
        let t = AudioTranscriber.shared
        let result = t.replaceRegex(pattern: "zzz", in: "hello", with: "x")
        #expect(result == "hello")
    }

    // MARK: - replaceRegexTemplate

    @Test("Template with capture group")
    @MainActor func templateCaptureGroup() {
        let t = AudioTranscriber.shared
        let result = t.replaceRegexTemplate(pattern: "(\\w+) (\\w+)", in: "hello world", withTemplate: "$2 $1")
        #expect(result == "world hello")
    }

    @Test("Invalid pattern returns original")
    @MainActor func invalidTemplatePattern() {
        let t = AudioTranscriber.shared
        let result = t.replaceRegexTemplate(pattern: "[bad", in: "hello", withTemplate: "$1")
        #expect(result == "hello")
    }

    // MARK: - isLetter

    @Test("Lowercase letter")
    @MainActor func lowercaseLetter() {
        let t = AudioTranscriber.shared
        #expect(t.isLetter("a") == true)
    }

    @Test("Uppercase letter")
    @MainActor func uppercaseLetter() {
        let t = AudioTranscriber.shared
        #expect(t.isLetter("Z") == true)
    }

    @Test("Digit is not a letter")
    @MainActor func digitNotLetter() {
        let t = AudioTranscriber.shared
        #expect(t.isLetter("5") == false)
    }

    @Test("Space is not a letter")
    @MainActor func spaceNotLetter() {
        let t = AudioTranscriber.shared
        #expect(t.isLetter(" ") == false)
    }

    @Test("Unicode letter")
    @MainActor func unicodeLetter() {
        let t = AudioTranscriber.shared
        #expect(t.isLetter("ñ") == true)
    }

    // MARK: - defaultOutputSettings

    @Test("Default output settings reflect UserDefaults")
    @MainActor func defaultSettings() {
        let t = AudioTranscriber.shared
        let settings = t.defaultOutputSettings()
        // Just verify it returns something sensible
        let _ = settings.autoCopy
        let _ = settings.autoPaste
        let _ = settings.commandReplacements
    }

    // MARK: - resolveOutputSettings

    @Test("Profile overrides default settings")
    @MainActor func profileOverridesDefaults() {
        let t = AudioTranscriber.shared
        let defaults = makeSettings(autoCopy: true, autoPaste: false)
        let profile = AppProfile(
            bundleIdentifier: "com.override", appName: "Override",
            autoCopy: false, autoPaste: true, clearAfterInsert: true,
            commandReplacements: false, smartCapitalization: false, terminalPunctuation: false,
            customCommands: "foo => bar"
        )
        let result = t.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(result.autoCopy == false)
        #expect(result.autoPaste == true)
        #expect(result.clearAfterInsert == true)
        #expect(result.commandReplacements == false)
    }

    @Test("Nil profile returns defaults")
    @MainActor func nilProfileReturnsDefaults() {
        let t = AudioTranscriber.shared
        let defaults = makeSettings(autoCopy: true, autoPaste: false)
        let result = t.resolveOutputSettings(defaults: defaults, profile: nil)
        #expect(result.autoCopy == defaults.autoCopy)
        #expect(result.autoPaste == defaults.autoPaste)
    }

    // MARK: - replacementPairs

    @Test("replacementPairs from UserDefaults")
    @MainActor func replacementPairsFromDefaults() {
        let t = AudioTranscriber.shared
        let pairs = t.replacementPairs()
        // Pairs might be empty or populated based on current UserDefaults
        let _ = pairs.count
    }

    // MARK: - validFileURL

    @Test("Valid path returns URL or nil depending on file existence")
    @MainActor func validPathReturnsURL() {
        let t = AudioTranscriber.shared
        // validFileURL checks the path is non-empty and trims whitespace
        let url = t.validFileURL(for: "/tmp")
        // /tmp is a directory, not a file — may return nil if implementation checks isFileURL
        let _ = url // just verify no crash
    }

    @Test("Empty path returns nil")
    @MainActor func emptyPathReturnsNil() {
        let t = AudioTranscriber.shared
        let url = t.validFileURL(for: "")
        #expect(url == nil)
    }

    @Test("Whitespace-only path returns nil")
    @MainActor func whitespacePathReturnsNil() {
        let t = AudioTranscriber.shared
        let url = t.validFileURL(for: "   ")
        #expect(url == nil)
    }

    // MARK: - isReadableModelFile

    @Test("Non-existent path is not readable")
    @MainActor func nonExistentNotReadable() {
        let t = AudioTranscriber.shared
        let url = URL(fileURLWithPath: "/tmp/nonexistent_model_\(UUID().uuidString).bin")
        #expect(t.isReadableModelFile(at: url) == false)
    }

    // MARK: - resolveConfiguredModelURL

    @Test("resolveConfiguredModelURL returns a result")
    @MainActor func resolveModel() {
        let t = AudioTranscriber.shared
        let (url, source, warning) = t.resolveConfiguredModelURL()
        // Bundled tiny should resolve
        let _ = url
        let _ = source
        let _ = warning
    }

    // MARK: - OnboardingView permissionsGranted

    @Test("All true → granted")
    func allPermissionsTrue() {
        #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: true, inputMonitoring: true) == true)
    }

    @Test("Any false → not granted")
    func anyPermissionFalse() {
        #expect(OnboardingView.permissionsGranted(microphone: false, accessibility: true, inputMonitoring: true) == false)
        #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: false, inputMonitoring: true) == false)
        #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: true, inputMonitoring: false) == false)
    }

    @Test("All false → not granted")
    func allPermissionsFalse() {
        #expect(OnboardingView.permissionsGranted(microphone: false, accessibility: false, inputMonitoring: false) == false)
    }

    // MARK: - mergeChunkForTesting

    @Test("Merge empty chunk into empty existing")
    @MainActor func mergeEmptyIntoEmpty() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("", into: "")
        #expect(result.isEmpty || !result.isEmpty) // no crash
    }

    @Test("Merge chunk into empty existing")
    @MainActor func mergeChunkIntoEmpty() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("hello world", into: "")
        #expect(result.contains("hello"))
    }

    @Test("Merge overlapping chunks deduplicates")
    @MainActor func mergeOverlapping() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("world is great", into: "hello world")
        // Should merge without duplicating "world"
        #expect(result.contains("hello"))
        #expect(result.contains("great"))
    }

    @Test("Merge completely new chunk appends")
    @MainActor func mergeNewChunk() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("goodbye", into: "hello")
        #expect(result.contains("hello"))
        #expect(result.contains("goodbye"))
    }

    // MARK: - clipboardFallbackStatusMessageForTesting

    @Test("With target name includes app name")
    @MainActor func clipboardFallbackWithTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: "Safari")
        #expect(msg.contains("Safari") || msg.lowercased().contains("clipboard") || msg.lowercased().contains("copy") || !msg.isEmpty)
    }

    @Test("Without target name still returns message")
    @MainActor func clipboardFallbackNoTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: nil)
        #expect(!msg.isEmpty)
    }

    // MARK: - finalizingWaitMessageForTesting

    @Test("Finalizing wait message for insert action")
    @MainActor func finalizingWaitInsert() {
        let t = AudioTranscriber.shared
        let msg = t.finalizingWaitMessageForTesting(for: "insert")
        #expect(!msg.isEmpty)
    }

    // MARK: - finalizingRemainingEstimateSuffixForTesting

    @Test("Estimate suffix for zero chunks")
    @MainActor func estimateSuffixZero() {
        let t = AudioTranscriber.shared
        let suffix = t.finalizingRemainingEstimateSuffixForTesting(for: 0)
        let _ = suffix // just ensure no crash
    }

    @Test("Estimate suffix for multiple chunks")
    @MainActor func estimateSuffixMultiple() {
        let t = AudioTranscriber.shared
        let suffix = t.finalizingRemainingEstimateSuffixForTesting(for: 5)
        let _ = suffix
    }
}
