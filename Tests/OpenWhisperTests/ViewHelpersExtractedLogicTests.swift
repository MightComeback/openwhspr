import Testing
import Foundation
@testable import OpenWhisper

@Suite("ViewHelpers Extracted Logic")
struct ViewHelpersExtractedLogicTests {

    // MARK: - isSentencePunctuation

    @Test("isSentencePunctuation: period")
    func sentencePunctuationPeriod() {
        #expect(ViewHelpers.isSentencePunctuation("."))
    }

    @Test("isSentencePunctuation: comma")
    func sentencePunctuationComma() {
        #expect(ViewHelpers.isSentencePunctuation(","))
    }

    @Test("isSentencePunctuation: exclamation")
    func sentencePunctuationExclamation() {
        #expect(ViewHelpers.isSentencePunctuation("!"))
    }

    @Test("isSentencePunctuation: question mark")
    func sentencePunctuationQuestion() {
        #expect(ViewHelpers.isSentencePunctuation("?"))
    }

    @Test("isSentencePunctuation: semicolon")
    func sentencePunctuationSemicolon() {
        #expect(ViewHelpers.isSentencePunctuation(";"))
    }

    @Test("isSentencePunctuation: colon")
    func sentencePunctuationColon() {
        #expect(ViewHelpers.isSentencePunctuation(":"))
    }

    @Test("isSentencePunctuation: ellipsis")
    func sentencePunctuationEllipsis() {
        #expect(ViewHelpers.isSentencePunctuation("…"))
    }

    @Test("isSentencePunctuation: letter is not punctuation")
    func sentencePunctuationLetter() {
        #expect(!ViewHelpers.isSentencePunctuation("a"))
    }

    @Test("isSentencePunctuation: digit is not punctuation")
    func sentencePunctuationDigit() {
        #expect(!ViewHelpers.isSentencePunctuation("0"))
    }

    @Test("isSentencePunctuation: space is not punctuation")
    func sentencePunctuationSpace() {
        #expect(!ViewHelpers.isSentencePunctuation(" "))
    }

    @Test("isSentencePunctuation: dash is not punctuation")
    func sentencePunctuationDash() {
        #expect(!ViewHelpers.isSentencePunctuation("-"))
    }

    @Test("isSentencePunctuation: at sign is not punctuation")
    func sentencePunctuationAt() {
        #expect(!ViewHelpers.isSentencePunctuation("@"))
    }

    // MARK: - trailingSentencePunctuation

    @Test("trailingSentencePunctuation: empty string returns nil")
    func trailingPunctuationEmpty() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "") == nil)
    }

    @Test("trailingSentencePunctuation: whitespace only returns nil")
    func trailingPunctuationWhitespace() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "   ") == nil)
    }

    @Test("trailingSentencePunctuation: no trailing punctuation returns nil")
    func trailingPunctuationNone() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "hello") == nil)
    }

    @Test("trailingSentencePunctuation: single period")
    func trailingPunctuationSinglePeriod() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "hello.") == ".")
    }

    @Test("trailingSentencePunctuation: multiple punctuation")
    func trailingPunctuationMultiple() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "hello...") == "...")
    }

    @Test("trailingSentencePunctuation: exclamation question combo")
    func trailingPunctuationExclamationQuestion() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "what?!") == "?!")
    }

    @Test("trailingSentencePunctuation: trailing whitespace is trimmed")
    func trailingPunctuationWithWhitespace() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "hello.  ") == ".")
    }

    @Test("trailingSentencePunctuation: ellipsis character")
    func trailingPunctuationEllipsisChar() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "wait…") == "…")
    }

    @Test("trailingSentencePunctuation: mixed text with period")
    func trailingPunctuationMixed() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "Hello, world.") == ".")
    }

    @Test("trailingSentencePunctuation: comma at end")
    func trailingPunctuationCommaAtEnd() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "one, two,") == ",")
    }

    @Test("trailingSentencePunctuation: semicolon at end")
    func trailingPunctuationSemicolon() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "done;") == ";")
    }

    @Test("trailingSentencePunctuation: colon at end")
    func trailingPunctuationColon() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "note:") == ":")
    }

    @Test("trailingSentencePunctuation: punctuation in middle only returns nil")
    func trailingPunctuationMiddleOnly() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "hello. world") == nil)
    }

    // MARK: - streamingElapsedStatusSegment

    @Test("streamingElapsedStatusSegment: 0 seconds")
    func streamingElapsed0() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 0) == "0:00")
    }

    @Test("streamingElapsedStatusSegment: 5 seconds")
    func streamingElapsed5() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 5) == "0:05")
    }

    @Test("streamingElapsedStatusSegment: 59 seconds")
    func streamingElapsed59() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 59) == "0:59")
    }

    @Test("streamingElapsedStatusSegment: 60 seconds = 1 minute")
    func streamingElapsed60() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 60) == "1:00")
    }

    @Test("streamingElapsedStatusSegment: 90 seconds")
    func streamingElapsed90() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 90) == "1:30")
    }

    @Test("streamingElapsedStatusSegment: 3599 seconds (just under 1 hour)")
    func streamingElapsed3599() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 3599) == "59:59")
    }

    @Test("streamingElapsedStatusSegment: 3600 seconds = 1 hour")
    func streamingElapsed3600() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 3600) == "1:00:00")
    }

    @Test("streamingElapsedStatusSegment: 3661 seconds = 1:01:01")
    func streamingElapsed3661() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 3661) == "1:01:01")
    }

    @Test("streamingElapsedStatusSegment: 7384 seconds = 2:03:04")
    func streamingElapsed7384() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 7384) == "2:03:04")
    }

    @Test("streamingElapsedStatusSegment: negative returns nil")
    func streamingElapsedNegative() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: -1) == nil)
    }

    // MARK: - sizeOfModelFile

    @Test("sizeOfModelFile: empty path returns 0")
    func sizeOfModelEmptyPath() {
        #expect(ViewHelpers.sizeOfModelFile(atPath: "") == 0)
    }

    @Test("sizeOfModelFile: nonexistent path returns 0")
    func sizeOfModelNonexistentPath() {
        #expect(ViewHelpers.sizeOfModelFile(atPath: "/nonexistent/path/model.bin") == 0)
    }

    @Test("sizeOfModelFile: real file returns positive size")
    func sizeOfModelRealFile() throws {
        let tmpDir = FileManager.default.temporaryDirectory
        let tmpFile = tmpDir.appendingPathComponent("test_model_\(UUID().uuidString).bin")
        let data = Data(repeating: 0xAB, count: 1024)
        try data.write(to: tmpFile)
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        let size = ViewHelpers.sizeOfModelFile(atPath: tmpFile.path)
        #expect(size == 1024)
    }

    @Test("sizeOfModelFile: directory path returns 0 or directory size")
    func sizeOfModelDirectory() {
        // /tmp exists but is a directory; attributesOfItem still works for dirs
        let size = ViewHelpers.sizeOfModelFile(atPath: "/tmp")
        // Directories have a non-negative size on macOS
        #expect(size >= 0)
    }
}
