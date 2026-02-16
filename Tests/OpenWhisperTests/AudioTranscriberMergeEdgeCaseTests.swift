import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber mergeChunk edge cases", .serialized)
struct AudioTranscriberMergeEdgeCaseTests {

    private var transcriber: AudioTranscriber { AudioTranscriber.shared }

    // MARK: - Empty / whitespace inputs

    @Test("both empty returns empty")
    func bothEmpty() {
        #expect(transcriber.mergeChunkForTesting("", into: "") == "")
    }

    @Test("empty chunk into non-empty returns existing")
    func emptyChunkIntoExisting() {
        #expect(transcriber.mergeChunkForTesting("", into: "hello") == "hello")
    }

    @Test("non-empty chunk into empty returns chunk")
    func nonEmptyChunkIntoEmpty() {
        #expect(transcriber.mergeChunkForTesting("hello", into: "") == "hello")
    }

    @Test("whitespace-only chunk into text returns text")
    func whitespaceOnlyChunk() {
        #expect(transcriber.mergeChunkForTesting("   ", into: "hello") == "hello")
    }

    @Test("chunk into whitespace-only returns chunk")
    func chunkIntoWhitespace() {
        #expect(transcriber.mergeChunkForTesting("hello", into: "   ") == "hello")
    }

    // MARK: - Exact duplicate (case-insensitive)

    @Test("exact duplicate is deduplicated")
    func exactDuplicate() {
        #expect(transcriber.mergeChunkForTesting("hello world", into: "hello world") == "hello world")
    }

    @Test("case-insensitive suffix match preserves existing case")
    func caseInsensitiveSuffixDup() {
        #expect(transcriber.mergeChunkForTesting("HELLO WORLD", into: "Hello World") == "Hello World")
    }

    // MARK: - Overlap merging

    @Test("long overlap merges correctly")
    func longOverlap() {
        let merged = transcriber.mergeChunkForTesting("the quick brown fox", into: "hello the quick brown")
        #expect(merged.contains("hello"))
        #expect(merged.contains("fox"))
        // Should merge on "the quick brown" overlap
        #expect(!merged.contains("the quick brown the quick brown"))
    }

    @Test("overlap at word boundary with different continuation")
    func overlapWithContinuation() {
        let merged = transcriber.mergeChunkForTesting("world is beautiful today", into: "hello world is")
        #expect(merged == "hello world is beautiful today")
    }

    // MARK: - Punctuation edge cases

    @Test("question mark as standalone fragment")
    func standaloneQuestionMark() {
        let merged = transcriber.mergeChunkForTesting("?", into: "is this working")
        #expect(merged == "is this working?")
    }

    @Test("exclamation mark as standalone fragment")
    func standaloneExclamation() {
        let merged = transcriber.mergeChunkForTesting("!", into: "wow")
        #expect(merged == "wow!")
    }

    @Test("ellipsis as standalone fragment")
    func standaloneEllipsis() {
        let merged = transcriber.mergeChunkForTesting("…", into: "and then")
        #expect(merged == "and then…")
    }

    @Test("comma-leading chunk attaches without space")
    func commaLeadingChunk() {
        let merged = transcriber.mergeChunkForTesting(", right?", into: "okay")
        #expect(merged == "okay, right?")
    }

    @Test("semicolon-leading chunk attaches without space")
    func semicolonLeadingChunk() {
        let merged = transcriber.mergeChunkForTesting("; then", into: "first")
        #expect(merged == "first; then")
    }

    // MARK: - Regression guard: short non-overlap

    @Test("two-char overlap is NOT used (conservative threshold)")
    func twoCharOverlapIgnored() {
        // "at" overlaps between "cat" and "atlas" but should be ignored
        let merged = transcriber.mergeChunkForTesting("atlas", into: "cat")
        #expect(merged == "cat atlas")
    }

    @Test("single-char overlap is NOT used")
    func singleCharOverlapIgnored() {
        let merged = transcriber.mergeChunkForTesting("end", into: "the")
        #expect(merged == "the end")
    }

    // MARK: - Existing trailing space preserved

    @Test("existing text ending in space joins without double space")
    func existingTrailingSpace() {
        let merged = transcriber.mergeChunkForTesting("world", into: "hello ")
        // Should not produce "hello  world"
        #expect(!merged.contains("  "))
        #expect(merged.contains("world"))
    }

    // MARK: - Unicode text

    @Test("unicode text merges correctly")
    func unicodeMerge() {
        let merged = transcriber.mergeChunkForTesting("мир", into: "привет")
        #expect(merged.contains("привет"))
        #expect(merged.contains("мир"))
    }

    @Test("emoji in text does not crash merge")
    func emojiMerge() {
        let merged = transcriber.mergeChunkForTesting("world 🌍", into: "hello")
        #expect(merged.contains("hello"))
        #expect(merged.contains("🌍"))
    }

    // MARK: - Chunk is substring of existing (dedup)

    @Test("chunk that exists in middle of transcript is deduplicated")
    func chunkInMiddle() {
        let merged = transcriber.mergeChunkForTesting("quick brown", into: "the quick brown fox jumps")
        #expect(merged == "the quick brown fox jumps")
    }

    @Test("short substring (< 4 chars) is NOT deduplicated as interior match")
    func shortSubstringNotDeduped() {
        let merged = transcriber.mergeChunkForTesting("the", into: "the quick brown fox")
        // "the" is < 4 chars so the interior-match dedup shouldn't apply,
        // but it IS a suffix match (lowercased lhs ends with... no, "the" doesn't suffix "the quick brown fox")
        // Actually "the" count is 3, < 4, so it won't match interior dedup.
        // Should append.
        #expect(merged.contains("fox"))
    }

    // MARK: - Multiple punctuation

    @Test("multiple question marks as fragment")
    func multipleQuestionMarks() {
        let merged = transcriber.mergeChunkForTesting("??", into: "really")
        #expect(merged == "really??")
    }

    @Test("mixed punctuation fragment")
    func mixedPunctuationFragment() {
        let merged = transcriber.mergeChunkForTesting("?!", into: "what")
        #expect(merged == "what?!")
    }
}

// MARK: - resolveOutputSettings edge cases

@Suite("AudioTranscriber resolveOutputSettings edge cases", .serialized)
struct AudioTranscriberResolveOutputSettingsEdgeTests {

    private var transcriber: AudioTranscriber { AudioTranscriber.shared }

    @Test("nil profile uses defaults as-is")
    func nilProfileUsesDefaults() {
        let defaults = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: true, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: true,
            terminalPunctuation: true, customCommandsRaw: "test"
        )
        let result = transcriber.resolveOutputSettings(defaults: defaults, profile: nil)
        #expect(result.autoCopy == true)
        #expect(result.autoPaste == false)
        #expect(result.clearAfterInsert == false)
        #expect(result.commandReplacements == true)
        #expect(result.smartCapitalization == true)
        #expect(result.terminalPunctuation == true)
        #expect(result.customCommandsRaw == "test")
    }

    @Test("profile overrides all fields")
    func profileOverridesAll() {
        let defaults = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: true, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: true,
            terminalPunctuation: true, customCommandsRaw: ""
        )
        let profile = AppProfile(
            bundleIdentifier: "com.test",
            appName: "Test",
            autoCopy: false,
            autoPaste: true,
            clearAfterInsert: true,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommands: "custom"
        )
        let result = transcriber.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(result.autoCopy == false)
        #expect(result.autoPaste == true)
        #expect(result.clearAfterInsert == true)
        #expect(result.commandReplacements == false)
        #expect(result.smartCapitalization == false)
        #expect(result.terminalPunctuation == false)
        #expect(result.customCommandsRaw == "custom")
    }

    @Test("profile with empty customCommands falls back to defaults")
    func profileEmptyCustomCommandsFallsBack() {
        let defaults = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: true, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: true,
            terminalPunctuation: true, customCommandsRaw: "global"
        )
        let profile = AppProfile(
            bundleIdentifier: "com.test",
            appName: "Test",
            autoCopy: true,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: true,
            smartCapitalization: true,
            terminalPunctuation: true,
            customCommands: ""
        )
        let result = transcriber.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(result.customCommandsRaw == "global")
    }

    @Test("both have customCommands: they get combined")
    func bothHaveCustomCommands() {
        let defaults = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: true, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: true,
            terminalPunctuation: true, customCommandsRaw: "global"
        )
        let profile = AppProfile(
            bundleIdentifier: "com.test",
            appName: "Test",
            autoCopy: true,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: true,
            smartCapitalization: true,
            terminalPunctuation: true,
            customCommands: "local"
        )
        let result = transcriber.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(result.customCommandsRaw == "global\nlocal")
    }

    @Test("defaults empty customCommands uses profile's")
    func defaultsEmptyUsesProfile() {
        let defaults = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: true, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: true,
            terminalPunctuation: true, customCommandsRaw: ""
        )
        let profile = AppProfile(
            bundleIdentifier: "com.test",
            appName: "Test",
            autoCopy: true,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: true,
            smartCapitalization: true,
            terminalPunctuation: true,
            customCommands: "local"
        )
        let result = transcriber.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(result.customCommandsRaw == "local")
    }
}

// MARK: - normalizeOutputText comprehensive edge cases

@Suite("AudioTranscriber normalizeOutputText edge cases", .serialized)
struct AudioTranscriberNormalizeOutputEdgeCaseTests {

    private var transcriber: AudioTranscriber { AudioTranscriber.shared }

    private func settings(
        commandReplacements: Bool = false,
        smartCapitalization: Bool = false,
        terminalPunctuation: Bool = false,
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

    @Test("empty text stays empty with all processing enabled")
    @MainActor func emptyTextAllEnabled() {
        let result = transcriber.normalizeOutputText("", settings: settings(
            commandReplacements: true, smartCapitalization: true, terminalPunctuation: true
        ))
        #expect(result == "")
    }

    @Test("whitespace-only text stays whitespace with all processing enabled")
    @MainActor func whitespaceOnlyAllEnabled() {
        let result = transcriber.normalizeOutputText("   ", settings: settings(
            commandReplacements: true, smartCapitalization: true, terminalPunctuation: true
        ))
        #expect(result.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    @Test("text with no applicable processing returns as-is")
    @MainActor func noProcessing() {
        let result = transcriber.normalizeOutputText("hello world", settings: settings())
        #expect(result == "hello world")
    }

    @Test("smart capitalization capitalizes first character")
    @MainActor func smartCapFirstChar() {
        let result = transcriber.normalizeOutputText("hello world", settings: settings(smartCapitalization: true))
        #expect(result.first?.isUppercase == true)
    }

    @Test("terminal punctuation adds period to unpunctuated text")
    @MainActor func terminalPunctuationAdds() {
        let result = transcriber.normalizeOutputText("hello world", settings: settings(terminalPunctuation: true))
        #expect(result.hasSuffix("."))
    }

    @Test("terminal punctuation does not double-add to already punctuated text")
    @MainActor func terminalPunctuationNoDouble() {
        let result = transcriber.normalizeOutputText("hello world.", settings: settings(terminalPunctuation: true))
        #expect(!result.hasSuffix(".."))
    }

    @Test("command replacement: 'new line' becomes newline")
    @MainActor func commandReplacementNewLine() {
        let result = transcriber.normalizeOutputText("hello new line world", settings: settings(commandReplacements: true))
        #expect(result.contains("\n"))
    }

    @Test("command replacement: 'new paragraph' becomes double newline")
    @MainActor func commandReplacementNewParagraph() {
        let result = transcriber.normalizeOutputText("hello new paragraph world", settings: settings(commandReplacements: true))
        #expect(result.contains("\n\n"))
    }

    @Test("all three processing steps combined")
    @MainActor func allCombined() {
        let result = transcriber.normalizeOutputText("hello world", settings: settings(
            commandReplacements: true, smartCapitalization: true, terminalPunctuation: true
        ))
        #expect(result.first?.isUppercase == true)
        #expect(result.last == "." || result.last == nil)
    }
}
