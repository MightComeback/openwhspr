import Testing
@testable import OpenWhisper

@Suite("AudioTranscriber status message and punctuation helpers")
struct AudioTranscriberStatusMessageTests {

    // MARK: - isSentencePunctuation

    @Test("period is sentence punctuation")
    func periodIsSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting("."))
    }

    @Test("comma is sentence punctuation")
    func commaIsSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting(","))
    }

    @Test("exclamation is sentence punctuation")
    func exclamationIsSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting("!"))
    }

    @Test("question mark is sentence punctuation")
    func questionIsSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting("?"))
    }

    @Test("semicolon is sentence punctuation")
    func semicolonIsSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting(";"))
    }

    @Test("colon is sentence punctuation")
    func colonIsSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting(":"))
    }

    @Test("ellipsis is sentence punctuation")
    func ellipsisIsSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting("…"))
    }

    @Test("letter is not sentence punctuation")
    func letterIsNotSentencePunctuation() {
        #expect(!AudioTranscriber.isSentencePunctuationForTesting("a"))
    }

    @Test("digit is not sentence punctuation")
    func digitIsNotSentencePunctuation() {
        #expect(!AudioTranscriber.isSentencePunctuationForTesting("5"))
    }

    @Test("space is not sentence punctuation")
    func spaceIsNotSentencePunctuation() {
        #expect(!AudioTranscriber.isSentencePunctuationForTesting(" "))
    }

    @Test("dash is not sentence punctuation")
    func dashIsNotSentencePunctuation() {
        #expect(!AudioTranscriber.isSentencePunctuationForTesting("-"))
    }

    @Test("at sign is not sentence punctuation")
    func atSignIsNotSentencePunctuation() {
        #expect(!AudioTranscriber.isSentencePunctuationForTesting("@"))
    }

    // MARK: - clipboardFallbackStatusMessage

    @Test("clipboard fallback with target name")
    func clipboardFallbackWithTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: "Safari")
        #expect(msg.contains("Safari"))
        #expect(msg.contains("⌘V"))
    }

    @Test("clipboard fallback with nil target")
    func clipboardFallbackNilTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: nil)
        #expect(!msg.contains("for "))
        #expect(msg.contains("clipboard"))
        #expect(msg.contains("⌘V"))
    }

    @Test("clipboard fallback with empty target")
    func clipboardFallbackEmptyTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: "")
        #expect(!msg.contains("for "))
        #expect(msg.contains("clipboard"))
    }

    @Test("clipboard fallback with long app name")
    func clipboardFallbackLongName() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: "Very Long Application Name Here")
        #expect(msg.contains("Very Long Application Name Here"))
    }

    // MARK: - finalizingWaitMessage

    @Test("finalizing wait message basic action")
    @MainActor func finalizingWaitBasic() {
        let t = AudioTranscriber.shared
        let msg = t.finalizingWaitMessageForTesting(for: "inserting")
        #expect(msg.contains("inserting"))
        #expect(msg.contains("finalizing"))
    }

    @Test("finalizing wait message with different action")
    @MainActor func finalizingWaitDifferentAction() {
        let t = AudioTranscriber.shared
        let msg = t.finalizingWaitMessageForTesting(for: "copying")
        #expect(msg.contains("copying"))
    }

    @Test("finalizing wait message contains Wait prefix")
    @MainActor func finalizingWaitPrefix() {
        let t = AudioTranscriber.shared
        let msg = t.finalizingWaitMessageForTesting(for: "starting")
        #expect(msg.hasPrefix("Wait"))
    }

    // MARK: - finalizingRemainingEstimateSuffix

    @Test("estimate suffix with zero chunks returns empty")
    @MainActor func estimateSuffixZeroChunks() {
        let t = AudioTranscriber.shared
        let suffix = t.finalizingRemainingEstimateSuffixForTesting(for: 0)
        #expect(suffix.isEmpty)
    }

    @Test("estimate suffix with negative chunks returns empty")
    @MainActor func estimateSuffixNegativeChunks() {
        let t = AudioTranscriber.shared
        let suffix = t.finalizingRemainingEstimateSuffixForTesting(for: -1)
        #expect(suffix.isEmpty)
    }
}
