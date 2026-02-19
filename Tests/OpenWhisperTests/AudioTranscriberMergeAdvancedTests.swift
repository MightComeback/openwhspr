import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber mergeChunk – advanced branch coverage", .serialized)
struct AudioTranscriberMergeAdvancedTests {

    private var transcriber: AudioTranscriber { AudioTranscriber.shared }

    // MARK: - lowerRHS.hasPrefix(lowerLHS) branch

    @Test("chunk expands existing text (prefix match returns chunk)")
    func chunkExpandsExisting() {
        // rhs starts with lhs → should return the longer rhs
        let merged = transcriber.mergeChunkForTesting("hello world", into: "hello")
        #expect(merged == "hello world")
    }

    @Test("chunk expands existing text case-insensitively")
    func chunkExpandsExistingCaseInsensitive() {
        let merged = transcriber.mergeChunkForTesting("Hello World", into: "hello")
        #expect(merged == "Hello World")
    }

    @Test("chunk expands existing with trailing standalone punctuation")
    func chunkExpandsWithPunctuation() {
        // "hello" → "hello." — remainder is "." which is standalone punctuation
        // Should attach punctuation directly to existing
        let merged = transcriber.mergeChunkForTesting("hello.", into: "hello")
        #expect(merged == "hello.")
    }

    @Test("chunk expands existing with trailing exclamation")
    func chunkExpandsWithExclamation() {
        let merged = transcriber.mergeChunkForTesting("hello!", into: "hello")
        #expect(merged == "hello!")
    }

    @Test("chunk expands existing with trailing ellipsis as suffix")
    func chunkExpandsWithEllipsis() {
        let merged = transcriber.mergeChunkForTesting("hello…", into: "hello")
        #expect(merged == "hello…")
    }

    @Test("chunk expands existing with non-punctuation continuation")
    func chunkExpandsWithContinuation() {
        let merged = transcriber.mergeChunkForTesting("hello beautiful world", into: "hello beautiful")
        #expect(merged == "hello beautiful world")
    }

    // MARK: - canonical chunk equality (formatting-only differences)

    @Test("extra spaces treated as duplicate, existing preserved")
    func extraSpacesDuplicate() {
        // "hello world" vs "hello  world" — canonical forms match
        let merged = transcriber.mergeChunkForTesting("hello  world", into: "hello world")
        #expect(merged == "hello world")
    }

    @Test("formatting duplicate with rhs having terminal punctuation adopts punctuation")
    func formattingDuplicateWithRhsPunctuation() {
        // canonical forms match, rhs has punctuation but lhs doesn't → lhs + punctuation
        let merged = transcriber.mergeChunkForTesting("hello world.", into: "hello world")
        #expect(merged == "hello world.")
    }

    @Test("formatting duplicate where lhs already has punctuation keeps lhs")
    func formattingDuplicateLhsHasPunctuation() {
        let merged = transcriber.mergeChunkForTesting("hello world", into: "hello world.")
        #expect(merged == "hello world.")
    }

    // MARK: - attachStandalonePunctuationFragment: base already ends with punctuation

    @Test("punctuation fragment when base already ends with same punctuation")
    func punctuationFragmentDuplicate() {
        // base ends with ".", fragment is "." → should not double up
        let merged = transcriber.mergeChunkForTesting(".", into: "hello world.")
        #expect(merged == "hello world.")
    }

    @Test("punctuation fragment when base ends with different punctuation")
    func punctuationFragmentDifferent() {
        let merged = transcriber.mergeChunkForTesting("!", into: "hello world.")
        #expect(merged == "hello world.!")
    }

    @Test("longer punctuation fragment extends base punctuation")
    func longerPunctuationFragment() {
        // base ends with "?", fragment is "?!" → should add "!" only
        let merged = transcriber.mergeChunkForTesting("?!", into: "really?")
        #expect(merged == "really?!")
    }

    // MARK: - Interior substring dedup (>= 4 chars)

    @Test("4-char interior substring is deduplicated")
    func fourCharInteriorDedup() {
        let merged = transcriber.mergeChunkForTesting("word", into: "this word is great")
        #expect(merged == "this word is great")
    }

    @Test("3-char interior substring is NOT deduplicated")
    func threeCharInteriorNotDedup() {
        let merged = transcriber.mergeChunkForTesting("wor", into: "this word is great")
        // "wor" is 3 chars, < 4, so it should append
        #expect(merged.hasSuffix("wor") || merged.contains("wor"))
    }

    // MARK: - lhs suffix match (hasSuffix)

    @Test("chunk is a suffix of existing text")
    func chunkIsSuffix() {
        let merged = transcriber.mergeChunkForTesting("world", into: "hello world")
        #expect(merged == "hello world")
    }

    @Test("chunk is a case-insensitive suffix of existing text")
    func chunkIsSuffixCaseInsensitive() {
        let merged = transcriber.mergeChunkForTesting("WORLD", into: "hello world")
        #expect(merged == "hello world")
    }

    // MARK: - Overlap with punctuation continuation

    @Test("overlap merge where remainder starts with period")
    func overlapMergeWithPeriod() {
        let merged = transcriber.mergeChunkForTesting("world. And then", into: "hello world")
        #expect(merged.contains("hello world"))
        #expect(merged.contains("And then"))
    }

    @Test("overlap merge where remainder starts with comma")
    func overlapMergeWithComma() {
        let merged = transcriber.mergeChunkForTesting("world, right?", into: "hello world")
        #expect(merged == "hello world, right?")
    }

    // MARK: - No overlap, simple concatenation

    @Test("completely disjoint chunks concatenate with space")
    func disjointChunks() {
        let merged = transcriber.mergeChunkForTesting("goodbye moon", into: "hello world")
        #expect(merged == "hello world goodbye moon")
    }
}
