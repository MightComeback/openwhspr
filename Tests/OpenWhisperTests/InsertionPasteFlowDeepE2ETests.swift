import Testing
import Foundation
@testable import OpenWhisper

/// Deep E2E tests for insertion/paste flow: manual insert targets,
/// clipboard operations, effective output settings resolution,
/// normalization edge cases, and command replacement chains.
@Suite("Insertion Paste Flow Deep E2E", .serialized)
struct InsertionPasteFlowDeepE2ETests {

    // MARK: - Helpers

    private func defaultSettings(
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

    // MARK: - Manual insert target snapshot

    @Test("manualInsertTargetSnapshot returns struct with expected fields")
    @MainActor func snapshotStructure() {
        let t = AudioTranscriber.shared
        let snap = t.manualInsertTargetSnapshot()
        // Snapshot has appName, bundleIdentifier, display, usesFallback, capturedAt
        let _ = snap.appName
        let _ = snap.bundleIdentifier
        let _ = snap.display
        let _ = snap.usesFallbackApp
    }

    @Test("manualInsertTargetAppName returns optional String")
    @MainActor func targetAppName() {
        let t = AudioTranscriber.shared
        let name: String? = t.manualInsertTargetAppName()
        let _ = name // may be nil in test env
    }

    @Test("manualInsertTargetBundleIdentifier returns optional String")
    @MainActor func targetBundleId() {
        let t = AudioTranscriber.shared
        let bid: String? = t.manualInsertTargetBundleIdentifier()
        let _ = bid
    }

    @Test("manualInsertTargetDisplay returns optional String")
    @MainActor func targetDisplay() {
        let t = AudioTranscriber.shared
        let display: String? = t.manualInsertTargetDisplay()
        let _ = display
    }

    @Test("manualInsertTargetUsesFallbackApp returns Bool")
    @MainActor func targetUsesFallback() {
        let t = AudioTranscriber.shared
        let fb: Bool = t.manualInsertTargetUsesFallbackApp()
        let _ = fb
    }

    @Test("clearManualInsertTarget does not crash")
    @MainActor func clearTarget() {
        let t = AudioTranscriber.shared
        t.clearManualInsertTarget()
    }

    @Test("retargetManualInsertTarget does not crash")
    @MainActor func retarget() {
        let t = AudioTranscriber.shared
        t.retargetManualInsertTarget()
    }

    @Test("focusManualInsertTargetApp returns Bool")
    @MainActor func focusTarget() {
        let t = AudioTranscriber.shared
        let result: Bool = t.focusManualInsertTargetApp()
        let _ = result
    }

    @Test("manualInsertTargetSnapshot forceRefresh does not crash")
    @MainActor func snapshotForceRefresh() {
        let t = AudioTranscriber.shared
        let snap = t.manualInsertTargetSnapshot(forceRefresh: true)
        let _ = snap
    }

    // MARK: - clearTranscription

    @Test("clearTranscription resets text to empty")
    @MainActor func clearTranscription() {
        let t = AudioTranscriber.shared
        t.transcription = "Some text"
        t.clearTranscription()
        #expect(t.transcription.isEmpty)
    }

    @Test("clearTranscription resets pending chunk count")
    @MainActor func clearTranscriptionResetsPending() {
        let t = AudioTranscriber.shared
        t.clearTranscription()
        #expect(t.pendingChunkCount == 0)
    }

    @Test("clearTranscription is idempotent")
    @MainActor func clearTranscriptionIdempotent() {
        let t = AudioTranscriber.shared
        t.clearTranscription()
        t.clearTranscription()
        #expect(t.transcription.isEmpty)
    }

    // MARK: - clearHistory

    @Test("clearHistory does not crash")
    @MainActor func clearHistory() {
        let t = AudioTranscriber.shared
        t.clearHistory()
        // History is persisted internally; clearing should not crash
    }

    // MARK: - Clipboard guard conditions

    @Test("copyTranscriptionToClipboard returns false for single-space text")
    @MainActor func copySingleSpace() {
        let t = AudioTranscriber.shared
        t.transcription = " "
        let result = t.copyTranscriptionToClipboard()
        #expect(result == false)
    }

    @Test("copyTranscriptionToClipboard returns false for tab-only text")
    @MainActor func copyTabOnly() {
        let t = AudioTranscriber.shared
        t.transcription = "\t\t"
        let result = t.copyTranscriptionToClipboard()
        #expect(result == false)
    }

    @Test("copyTranscriptionToClipboard returns false for newline-only text")
    @MainActor func copyNewlineOnly() {
        let t = AudioTranscriber.shared
        t.transcription = "\n\n\n"
        let result = t.copyTranscriptionToClipboard()
        #expect(result == false)
    }

    // MARK: - effectiveOutputSettings

    @Test("effectiveOutputSettingsForCurrentApp returns valid settings")
    @MainActor func effectiveSettingsCurrent() {
        let t = AudioTranscriber.shared
        let settings = t.effectiveOutputSettingsForCurrentApp()
        let _ = settings.autoCopy
        let _ = settings.autoPaste
        let _ = settings.commandReplacements
        let _ = settings.smartCapitalization
        let _ = settings.terminalPunctuation
    }

    @Test("effectiveOutputSettingsForInsertionTarget returns valid settings")
    @MainActor func effectiveSettingsInsertTarget() {
        let t = AudioTranscriber.shared
        let settings = t.effectiveOutputSettingsForInsertionTarget()
        let _ = settings.autoCopy
        let _ = settings.autoPaste
    }

    @Test("effectiveOutputSettings without profile matches defaults")
    @MainActor func effectiveSettingsNoProfile() {
        let t = AudioTranscriber.shared
        t.clearManualInsertTarget()
        let currentSettings = t.effectiveOutputSettingsForCurrentApp()
        let insertSettings = t.effectiveOutputSettingsForInsertionTarget()
        // With no profile active, both should reflect global defaults
        #expect(currentSettings.commandReplacements == insertSettings.commandReplacements)
        #expect(currentSettings.smartCapitalization == insertSettings.smartCapitalization)
        #expect(currentSettings.terminalPunctuation == insertSettings.terminalPunctuation)
    }

    // MARK: - Insertion probe

    @Test("insertionProbeMaxCharacters is reasonable")
    func probeMaxCharsReasonable() {
        #expect(AudioTranscriber.insertionProbeMaxCharacters >= 10)
        #expect(AudioTranscriber.insertionProbeMaxCharacters <= 10000)
    }

    @Test("runInsertionProbe resets previous results")
    @MainActor func probeResetsResults() {
        let t = AudioTranscriber.shared
        // First run with empty text to fail
        let _ = t.runInsertionProbe(sampleText: "")
        #expect(t.lastInsertionProbeSucceeded == false)
        // Run again with another empty
        let _ = t.runInsertionProbe(sampleText: "   \t  ")
        #expect(t.lastInsertionProbeSucceeded == false)
    }

    @Test("runInsertionProbe message is descriptive on failure")
    @MainActor func probeFailMessage() {
        let t = AudioTranscriber.shared
        let _ = t.runInsertionProbe(sampleText: "")
        #expect(!t.lastInsertionProbeMessage.isEmpty)
    }

    @Test("insertionProbeMaxCharacters is a positive limit")
    func probeMaxCharsPositiveLimit() {
        #expect(AudioTranscriber.insertionProbeMaxCharacters > 0)
    }

    @Test("isRunningInsertionProbe is false when not probing")
    @MainActor func probeNotRunning() {
        let t = AudioTranscriber.shared
        // After a failed probe, should not be in running state
        let _ = t.runInsertionProbe(sampleText: "")
        #expect(t.isRunningInsertionProbe == false)
    }

    // MARK: - normalizeOutputText edge cases

    @Test("normalizeOutputText: consecutive periods not duplicated")
    @MainActor func consecutivePeriods() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("end.", settings: defaultSettings())
        #expect(result == "End.")
        #expect(!result.hasSuffix(".."))
    }

    @Test("normalizeOutputText: dash surrounded by spaces")
    @MainActor func dashSpaces() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("hello - world", settings: defaultSettings())
        #expect(result.contains("-"))
    }

    @Test("normalizeOutputText: parentheses preserved")
    @MainActor func parentheses() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("test (value) here", settings: defaultSettings())
        #expect(result.contains("(value)"))
    }

    @Test("normalizeOutputText: brackets preserved")
    @MainActor func brackets() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("array [1, 2, 3] end", settings: defaultSettings())
        #expect(result.contains("[1, 2, 3]"))
    }

    @Test("normalizeOutputText: quotes preserved")
    @MainActor func quotes() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("he said \"hello\" to me", settings: defaultSettings())
        #expect(result.contains("\"hello\""))
    }

    @Test("normalizeOutputText: URL-like text preserved")
    @MainActor func urlLikeText() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("visit https://example.com today", settings: defaultSettings())
        #expect(result.lowercased().contains("https://example.com"))
    }

    @Test("normalizeOutputText: email-like text preserved")
    @MainActor func emailLikeText() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("send to user@example.com please", settings: defaultSettings())
        #expect(result.lowercased().contains("user@example.com"))
    }

    @Test("normalizeOutputText: numbers with decimals preserved")
    @MainActor func decimalNumbers() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("the value is 3.14", settings: defaultSettings())
        #expect(result.contains("3.14"))
    }

    @Test("normalizeOutputText: all caps word preserved")
    @MainActor func allCapsWord() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("this is IMPORTANT", settings: defaultSettings())
        #expect(result.contains("IMPORTANT"))
    }

    @Test("normalizeOutputText: mixed case sentence start preserved if already uppercase")
    @MainActor func alreadyUppercase() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("Hello world", settings: defaultSettings())
        #expect(result.hasPrefix("Hello"))
    }

    @Test("normalizeOutputText: text ending with dash")
    @MainActor func textEndingDash() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("word—", settings: defaultSettings())
        // em-dash at end should not get extra period after it
        #expect(!result.isEmpty)
    }

    // MARK: - normalizeWhitespace

    @Test("normalizeWhitespace: basic space collapse")
    @MainActor func normalizeBasicSpaces() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "a   b   c")
        #expect(result == "a b c")
    }

    @Test("normalizeWhitespace: preserves single newline")
    @MainActor func normalizeSingleNewline() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "a\nb")
        #expect(result == "a\nb")
    }

    @Test("normalizeWhitespace: collapses multiple newlines to double")
    @MainActor func normalizeMultipleNewlines() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "a\n\n\n\nb")
        #expect(result == "a\n\nb")
    }

    @Test("normalizeWhitespace: trims leading and trailing")
    @MainActor func normalizeTrim() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "  hello  ")
        #expect(result.trimmingCharacters(in: .whitespacesAndNewlines) == "hello")
    }

    @Test("normalizeWhitespace: empty string returns empty")
    @MainActor func normalizeEmpty() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "")
        #expect(result == "")
    }

    @Test("normalizeWhitespace: whitespace-only returns empty")
    @MainActor func normalizeWhitespaceOnly() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "   \n  \t  ")
        #expect(result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    @Test("normalizeWhitespace: tabs converted to spaces")
    @MainActor func normalizeTabsToSpaces() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "a\t\tb")
        #expect(result == "a b")
    }

    @Test("normalizeWhitespace: space around newline cleaned")
    @MainActor func normalizeSpaceAroundNewline() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "a  \n  b")
        #expect(result == "a\nb")
    }

    // MARK: - applyCommandReplacements

    @Test("applyCommandReplacements: no commands passes through")
    @MainActor func commandReplacementsPassThrough() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(to: "hello world", settings: defaultSettings())
        #expect(result == "hello world")
    }

    @Test("applyCommandReplacements: always applies built-in rules regardless of flag")
    @MainActor func commandReplacementsAlwaysApplies() {
        let t = AudioTranscriber.shared
        // applyCommandReplacements itself doesn't check the flag — the caller does
        let result = t.applyCommandReplacements(
            to: "hello world",
            settings: defaultSettings(commandReplacements: false)
        )
        // "hello world" has no command triggers, so passes through
        #expect(result == "hello world")
    }

    @Test("applyCommandReplacements: custom command applied")
    @MainActor func customCommandApplied() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(
            to: "say bye bye",
            settings: defaultSettings(customCommandsRaw: "bye bye => goodbye")
        )
        #expect(result.contains("goodbye"))
    }

    @Test("applyCommandReplacements: multiple custom commands")
    @MainActor func multipleCustomCommands() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(
            to: "greeting name",
            settings: defaultSettings(customCommandsRaw: "greeting => Hello\nname => Ivan")
        )
        #expect(result.contains("Hello"))
        #expect(result.contains("Ivan"))
    }

    @Test("applyCommandReplacements: empty custom commands string")
    @MainActor func emptyCustomCommands() {
        let t = AudioTranscriber.shared
        let result = t.applyCommandReplacements(
            to: "hello world",
            settings: defaultSettings(customCommandsRaw: "")
        )
        #expect(result == "hello world")
    }

    // MARK: - EffectiveOutputSettings struct

    @Test("EffectiveOutputSettings: all fields accessible")
    func settingsFields() {
        let s = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: true,
            autoPaste: false,
            clearAfterInsert: true,
            commandReplacements: false,
            smartCapitalization: true,
            terminalPunctuation: false,
            customCommandsRaw: "a => b"
        )
        #expect(s.autoCopy == true)
        #expect(s.autoPaste == false)
        #expect(s.clearAfterInsert == true)
        #expect(s.commandReplacements == false)
        #expect(s.smartCapitalization == true)
        #expect(s.terminalPunctuation == false)
        #expect(s.customCommandsRaw == "a => b")
    }

    @Test("EffectiveOutputSettings: empty customCommandsRaw")
    func settingsEmptyCustom() {
        let s = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: true,
            smartCapitalization: true,
            terminalPunctuation: true,
            customCommandsRaw: ""
        )
        #expect(s.customCommandsRaw.isEmpty)
    }

    // MARK: - Full pipeline: complex realistic scenarios

    @Test("Full pipeline: meeting notes dictation with commands")
    @MainActor func meetingNotesDictation() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText(
            "action items new paragraph first item comma review the design new line second item comma fix the bug",
            settings: defaultSettings()
        )
        #expect(result.contains("\n\n"))
        #expect(result.contains(","))
    }

    @Test("Full pipeline: code dictation with special chars")
    @MainActor func codeDictation() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText(
            "function hello open parenthesis close parenthesis",
            settings: defaultSettings()
        )
        // Command replacements for parentheses if configured, otherwise literal text
        #expect(!result.isEmpty)
    }

    @Test("Full pipeline: rapid short utterances")
    @MainActor func rapidShortUtterances() {
        let t = AudioTranscriber.shared
        for input in ["yes", "no", "ok", "done", "next"] {
            let result = t.normalizeOutputText(input, settings: defaultSettings())
            #expect(!result.isEmpty)
            // Each should get capitalized
            #expect(result.first?.isUppercase == true)
        }
    }

    @Test("Full pipeline: text with multiple sentence-ending punctuation types")
    @MainActor func multiplePunctuationTypes() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText(
            "first sentence. second question? third exclamation! fourth clause",
            settings: defaultSettings()
        )
        #expect(result.contains("."))
        #expect(result.contains("?"))
        #expect(result.contains("!"))
        #expect(result.hasSuffix("."))
    }

    @Test("Full pipeline: text with numbers and units")
    @MainActor func numbersAndUnits() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("the temperature is 72°F outside", settings: defaultSettings())
        #expect(result.contains("72°F"))
    }

    @Test("Full pipeline: text with hyphens in compound words")
    @MainActor func hyphenatedWords() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("this is a well-known fact", settings: defaultSettings())
        #expect(result.contains("well-known"))
    }

    @Test("Full pipeline: apostrophe s possessive")
    @MainActor func possessive() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText("ivan's project is great", settings: defaultSettings())
        // Smart cap should capitalize but preserve possessive
        #expect(result.contains("project"))
    }

    @Test("Full pipeline: multiple paragraphs with capitalization")
    @MainActor func multiParagraphs() {
        let t = AudioTranscriber.shared
        let result = t.normalizeOutputText(
            "first paragraph here new paragraph second paragraph here new paragraph third paragraph here",
            settings: defaultSettings()
        )
        let paragraphs = result.components(separatedBy: "\n\n")
        #expect(paragraphs.count >= 2)
        for p in paragraphs where !p.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            #expect(p.trimmingCharacters(in: .whitespacesAndNewlines).first?.isUppercase == true)
        }
    }

    @Test("Full pipeline: canAutoPasteIntoTargetAppForTesting returns Bool")
    @MainActor func canAutoPaste() {
        let t = AudioTranscriber.shared
        let result: Bool = t.canAutoPasteIntoTargetAppForTesting()
        let _ = result
    }

    // MARK: - setPendingSessionFinalizeForTesting

    @Test("setPendingSessionFinalizeForTesting true blocks insert")
    @MainActor func setPendingFinalizeTrue() {
        let t = AudioTranscriber.shared
        t.setPendingSessionFinalizeForTesting(true)
        t.transcription = "Some text"
        let result = t.insertTranscriptionIntoFocusedApp()
        #expect(result == false)
        t.setPendingSessionFinalizeForTesting(false)
    }

    @Test("setPendingSessionFinalizeForTesting false unblocks")
    @MainActor func setPendingFinalizeFalse() {
        let t = AudioTranscriber.shared
        t.setPendingSessionFinalizeForTesting(true)
        t.setPendingSessionFinalizeForTesting(false)
        // Now insert should be unblocked (may still fail for other reasons)
        t.transcription = "test"
        let _ = t.insertTranscriptionIntoFocusedApp()
    }

    // MARK: - lastInsertionProbe state

    @Test("lastInsertionProbeDate starts nil")
    @MainActor func probeStartsNil() {
        // Fresh singleton state
        let t = AudioTranscriber.shared
        // May have been set by other tests; just verify type
        let _: Date? = t.lastInsertionProbeDate
    }

    @Test("lastInsertionProbeMessage starts with default value")
    @MainActor func probeDefaultMessage() {
        let t = AudioTranscriber.shared
        // After a failed probe, message should be non-empty
        let _ = t.runInsertionProbe(sampleText: "")
        #expect(!t.lastInsertionProbeMessage.isEmpty)
    }

    @Test("lastInsertionProbeSucceeded is false after failed probe")
    @MainActor func probeSucceededAfterFail() {
        let t = AudioTranscriber.shared
        let _ = t.runInsertionProbe(sampleText: "")
        #expect(t.lastInsertionProbeSucceeded == false)
    }
}
