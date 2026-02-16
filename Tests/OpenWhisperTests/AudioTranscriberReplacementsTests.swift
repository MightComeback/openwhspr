import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber applyTextReplacements", .serialized)
struct AudioTranscriberReplacementsTests {

    private let key = AppDefaults.Keys.transcriptionReplacements

    // MARK: - replacementPairs parsing

    @Test("replacementPairs: empty string returns no pairs")
    @MainActor func emptyString() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("", forKey: key)
        let pairs = AudioTranscriber.shared.replacementPairs()
        #expect(pairs.isEmpty)
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs: single arrow pair")
    @MainActor func singleArrowPair() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("hello => world", forKey: key)
        let pairs = AudioTranscriber.shared.replacementPairs()
        #expect(pairs.count == 1)
        #expect(pairs[0].from == "hello")
        #expect(pairs[0].to == "world")
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs: single equals pair")
    @MainActor func singleEqualsPair() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("foo = bar", forKey: key)
        let pairs = AudioTranscriber.shared.replacementPairs()
        #expect(pairs.count == 1)
        #expect(pairs[0].from == "foo")
        #expect(pairs[0].to == "bar")
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs: arrow takes precedence over equals")
    @MainActor func arrowPrecedence() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("a=>b = c", forKey: key)
        let pairs = AudioTranscriber.shared.replacementPairs()
        #expect(pairs.count == 1)
        #expect(pairs[0].from == "a")
        #expect(pairs[0].to == "b = c")
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs: multiple lines")
    @MainActor func multipleLines() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("a => b\nc => d\ne = f", forKey: key)
        let pairs = AudioTranscriber.shared.replacementPairs()
        #expect(pairs.count == 3)
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs: comment lines ignored")
    @MainActor func commentLinesIgnored() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("# comment\na => b\n# another", forKey: key)
        let pairs = AudioTranscriber.shared.replacementPairs()
        #expect(pairs.count == 1)
        #expect(pairs[0].from == "a")
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs: empty lines ignored")
    @MainActor func emptyLinesIgnored() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("\n\na => b\n\n", forKey: key)
        let pairs = AudioTranscriber.shared.replacementPairs()
        #expect(pairs.count == 1)
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs: empty from side skipped")
    @MainActor func emptyFromSkipped() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set(" => something", forKey: key)
        let pairs = AudioTranscriber.shared.replacementPairs()
        #expect(pairs.isEmpty)
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs: empty to side is valid (deletion)")
    @MainActor func emptyToValid() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("remove =>", forKey: key)
        let pairs = AudioTranscriber.shared.replacementPairs()
        #expect(pairs.count == 1)
        #expect(pairs[0].from == "remove")
        #expect(pairs[0].to == "")
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs: trims whitespace")
    @MainActor func trimsWhitespace() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("  hello  =>  world  ", forKey: key)
        let pairs = AudioTranscriber.shared.replacementPairs()
        #expect(pairs.count == 1)
        #expect(pairs[0].from == "hello")
        #expect(pairs[0].to == "world")
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    // MARK: - applyTextReplacements

    @Test("applyTextReplacements: no replacements returns original")
    @MainActor func noReplacements() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("", forKey: key)
        #expect(AudioTranscriber.shared.applyTextReplacements(to: "hello world") == "hello world")
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("applyTextReplacements: single replacement applied")
    @MainActor func singleReplacement() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("hello => goodbye", forKey: key)
        #expect(AudioTranscriber.shared.applyTextReplacements(to: "hello world") == "goodbye world")
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("applyTextReplacements: multiple replacements applied in order")
    @MainActor func multipleReplacements() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("a => b\nc => d", forKey: key)
        #expect(AudioTranscriber.shared.applyTextReplacements(to: "a c") == "b d")
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("applyTextReplacements: deletion replacement")
    @MainActor func deletionReplacement() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("remove =>", forKey: key)
        #expect(AudioTranscriber.shared.applyTextReplacements(to: "please remove this") == "please  this")
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("applyTextReplacements: case-sensitive")
    @MainActor func caseSensitive() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("Hello => Goodbye", forKey: key)
        #expect(AudioTranscriber.shared.applyTextReplacements(to: "Hello hello") == "Goodbye hello")
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("applyTextReplacements: replaces all occurrences")
    @MainActor func replacesAll() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("x => y", forKey: key)
        #expect(AudioTranscriber.shared.applyTextReplacements(to: "x and x and x") == "y and y and y")
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("applyTextReplacements: chained replacements")
    @MainActor func chainedReplacements() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("a => b\nb => c", forKey: key)
        #expect(AudioTranscriber.shared.applyTextReplacements(to: "a") == "c")
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("applyTextReplacements: empty input returns empty")
    @MainActor func emptyInput() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("a => b", forKey: key)
        #expect(AudioTranscriber.shared.applyTextReplacements(to: "") == "")
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("applyTextReplacements: no match returns original")
    @MainActor func noMatch() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("xyz => abc", forKey: key)
        #expect(AudioTranscriber.shared.applyTextReplacements(to: "hello world") == "hello world")
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs: whitespace-only from with equals skipped")
    @MainActor func whitespaceFromEquals() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("   = something", forKey: key)
        let pairs = AudioTranscriber.shared.replacementPairs()
        #expect(pairs.isEmpty)
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs: no separator returns no pair")
    @MainActor func noSeparator() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.set("just some text", forKey: key)
        let pairs = AudioTranscriber.shared.replacementPairs()
        #expect(pairs.isEmpty)
        if let old { UserDefaults.standard.set(old, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }

    @Test("replacementPairs: nil defaults returns empty")
    @MainActor func nilDefaults() {
        let old = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.removeObject(forKey: key)
        let pairs = AudioTranscriber.shared.replacementPairs()
        #expect(pairs.isEmpty)
        if let old { UserDefaults.standard.set(old, forKey: key) }
    }
}
