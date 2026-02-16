import Testing
import Foundation
@testable import OpenWhisper

@Suite("CommandRule – extended coverage")
struct CommandRuleExtendedTests {

    // MARK: - BuiltInCommandRules

    @Test("all built-in rules have non-empty phrase")
    func builtInPhrasesNonEmpty() {
        for rule in BuiltInCommandRules.all {
            #expect(!rule.phrase.isEmpty, "Built-in rule has empty phrase")
        }
    }

    @Test("all built-in rules have non-empty replacement")
    func builtInReplacementsNonEmpty() {
        for rule in BuiltInCommandRules.all {
            #expect(!rule.replacement.isEmpty, "Built-in rule '\(rule.phrase)' has empty replacement")
        }
    }

    @Test("built-in rules have no duplicate phrases")
    func builtInNoDuplicates() {
        var seen = Set<String>()
        for rule in BuiltInCommandRules.all {
            #expect(!seen.contains(rule.phrase), "Duplicate built-in phrase: \(rule.phrase)")
            seen.insert(rule.phrase)
        }
    }

    @Test("built-in count is at least 60")
    func builtInCount() {
        #expect(BuiltInCommandRules.all.count >= 60)
    }

    @Test("specific built-in rules exist")
    func specificBuiltIns() {
        let phrases = Set(BuiltInCommandRules.all.map(\.phrase))
        let expected = ["new line", "new paragraph", "comma", "period", "question mark",
                        "exclamation mark", "colon", "semicolon", "open quote", "close quote",
                        "dash", "em dash", "ellipsis", "bullet point", "tab character"]
        for p in expected {
            #expect(phrases.contains(p), "Missing built-in: \(p)")
        }
    }

    // MARK: - CommandRule Hashable

    @Test("identical rules are equal")
    func equalRules() {
        let a = CommandRule(phrase: "hello", replacement: "world")
        let b = CommandRule(phrase: "hello", replacement: "world")
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("different phrases are not equal")
    func differentPhrase() {
        let a = CommandRule(phrase: "hello", replacement: "world")
        let b = CommandRule(phrase: "hi", replacement: "world")
        #expect(a != b)
    }

    @Test("different replacements are not equal")
    func differentReplacement() {
        let a = CommandRule(phrase: "hello", replacement: "world")
        let b = CommandRule(phrase: "hello", replacement: "earth")
        #expect(a != b)
    }

    // MARK: - Parser: arrow separator

    @Test("arrow separator with spaces")
    func arrowWithSpaces() {
        let rules = CommandRuleParser.parse(raw: "  greeting  =>  hi there  ")
        #expect(rules.count == 1)
        #expect(rules[0].phrase == "greeting")
        #expect(rules[0].replacement == "hi there")
    }

    @Test("arrow separator preserves replacement casing")
    func arrowPreservesReplacementCase() {
        let rules = CommandRuleParser.parse(raw: "Name => OpenWhisper")
        #expect(rules[0].replacement == "OpenWhisper")
    }

    @Test("phrase is lowercased")
    func phraseLowercased() {
        let rules = CommandRuleParser.parse(raw: "HELLO => world")
        #expect(rules[0].phrase == "hello")
    }

    // MARK: - Parser: equals separator

    @Test("equals with no spaces")
    func equalsNoSpaces() {
        let rules = CommandRuleParser.parse(raw: "a=b")
        #expect(rules.count == 1)
        #expect(rules[0].phrase == "a")
        #expect(rules[0].replacement == "b")
    }

    @Test("equals prefers arrow when both present")
    func arrowPreferredOverEquals() {
        // "x => y=z" should split at => first
        let rules = CommandRuleParser.parse(raw: "x => y=z")
        #expect(rules.count == 1)
        #expect(rules[0].phrase == "x")
        #expect(rules[0].replacement == "y=z")
    }

    // MARK: - Parser: escape sequences

    @Test("tab escape")
    func tabEscape() {
        let rules = CommandRuleParser.parse(raw: "indent => \\t\\t")
        #expect(rules[0].replacement == "\t\t")
    }

    @Test("space escape")
    func spaceEscape() {
        let rules = CommandRuleParser.parse(raw: "sp => \\s")
        #expect(rules[0].replacement == " ")
    }

    @Test("backslash escape")
    func backslashEscape() {
        let rules = CommandRuleParser.parse(raw: "bs => \\\\")
        #expect(rules[0].replacement == "\\")
    }

    @Test("multiple escapes in one replacement")
    func multipleEscapes() {
        let rules = CommandRuleParser.parse(raw: "mix => a\\nb\\tc\\\\d")
        #expect(rules[0].replacement == "a\nb\tc\\d")
    }

    // MARK: - Parser: edge cases

    @Test("empty input")
    func emptyInput() {
        #expect(CommandRuleParser.parse(raw: "").isEmpty)
    }

    @Test("whitespace only input")
    func whitespaceOnlyInput() {
        #expect(CommandRuleParser.parse(raw: "   \n  \n  ").isEmpty)
    }

    @Test("line without separator is skipped")
    func noSeparatorSkipped() {
        let rules = CommandRuleParser.parse(raw: "no separator here")
        #expect(rules.isEmpty)
    }

    @Test("empty left side is skipped")
    func emptyLeftSkipped() {
        let rules = CommandRuleParser.parse(raw: " => value")
        #expect(rules.isEmpty)
    }

    @Test("empty right side is allowed")
    func emptyRightAllowed() {
        let rules = CommandRuleParser.parse(raw: "key => ")
        #expect(rules.count == 1)
        #expect(rules[0].replacement == "")
    }

    @Test("comment lines with leading spaces")
    func commentWithLeadingSpaces() {
        let rules = CommandRuleParser.parse(raw: "  # this is a comment")
        #expect(rules.isEmpty)
    }

    @Test("multiple rules parsed in order")
    func multipleRulesInOrder() {
        let input = """
        first => 1
        second => 2
        third => 3
        """
        let rules = CommandRuleParser.parse(raw: input)
        #expect(rules.count == 3)
        #expect(rules[0].phrase == "first")
        #expect(rules[1].phrase == "second")
        #expect(rules[2].phrase == "third")
    }

    @Test("mixed valid, invalid, and comment lines")
    func mixedLines() {
        let input = """
        # header
        valid => yes
        no separator
        also valid = true
        
        # another comment
        last => done
        """
        let rules = CommandRuleParser.parse(raw: input)
        #expect(rules.count == 3)
        #expect(rules[0].phrase == "valid")
        #expect(rules[1].phrase == "also valid")
        #expect(rules[2].phrase == "last")
    }

    @Test("replacement with arrow characters")
    func replacementWithArrow() {
        let rules = CommandRuleParser.parse(raw: "arrow => ->")
        #expect(rules[0].replacement == "->")
    }

    @Test("phrase with multiple words")
    func multiWordPhrase() {
        let rules = CommandRuleParser.parse(raw: "open curly brace => {")
        #expect(rules[0].phrase == "open curly brace")
        #expect(rules[0].replacement == "{")
    }
}
