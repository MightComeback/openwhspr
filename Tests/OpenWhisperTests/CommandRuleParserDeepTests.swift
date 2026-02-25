import Testing
import Foundation
@testable import OpenWhisper

@Suite("CommandRuleParser deep coverage")
struct CommandRuleParserDeepTests {

    // MARK: - parse edge cases

    @Test("Empty string returns no rules")
    func parseEmpty() {
        let rules = CommandRuleParser.parse(raw: "")
        #expect(rules.isEmpty)
    }

    @Test("Whitespace-only returns no rules")
    func parseWhitespaceOnly() {
        let rules = CommandRuleParser.parse(raw: "   \n  \n   ")
        #expect(rules.isEmpty)
    }

    @Test("Comment lines are skipped")
    func parseComments() {
        let rules = CommandRuleParser.parse(raw: "# this is a comment\n# another")
        #expect(rules.isEmpty)
    }

    @Test("Mixed comments and rules")
    func parseMixedCommentsAndRules() {
        let raw = """
        # Header comment
        hello = world
        # Middle comment
        foo => bar
        """
        let rules = CommandRuleParser.parse(raw: raw)
        #expect(rules.count == 2)
        #expect(rules[0].phrase == "hello")
        #expect(rules[0].replacement == "world")
        #expect(rules[1].phrase == "foo")
        #expect(rules[1].replacement == "bar")
    }

    @Test("=> separator takes priority over =")
    func parseDoubleArrowPriority() {
        let rules = CommandRuleParser.parse(raw: "a=>b=c")
        #expect(rules.count == 1)
        #expect(rules[0].phrase == "a")
        #expect(rules[0].replacement == "b=c")
    }

    @Test("Simple = separator")
    func parseEqualsSeparator() {
        let rules = CommandRuleParser.parse(raw: "hello = world")
        #expect(rules.count == 1)
        #expect(rules[0].phrase == "hello")
        #expect(rules[0].replacement == "world")
    }

    @Test("Phrase is lowercased")
    func parseLowercasesPhrase() {
        let rules = CommandRuleParser.parse(raw: "HELLO = world")
        #expect(rules[0].phrase == "hello")
    }

    @Test("Replacement preserves case")
    func parsePreservesReplacementCase() {
        let rules = CommandRuleParser.parse(raw: "test = HeLLo WoRLd")
        #expect(rules[0].replacement == "HeLLo WoRLd")
    }

    @Test("Empty left side is skipped")
    func parseEmptyLeftSide() {
        let rules = CommandRuleParser.parse(raw: " = something")
        #expect(rules.isEmpty)
    }

    @Test("Empty right side produces empty replacement")
    func parseEmptyRightSide() {
        let rules = CommandRuleParser.parse(raw: "delete this = ")
        #expect(rules.count == 1)
        #expect(rules[0].replacement == "")
    }

    @Test("Line with no separator is skipped")
    func parseNoSeparator() {
        let rules = CommandRuleParser.parse(raw: "just some text")
        #expect(rules.isEmpty)
    }

    @Test("Escape \\n decoded to newline")
    func parseEscapeNewline() {
        let rules = CommandRuleParser.parse(raw: "br = \\n")
        #expect(rules[0].replacement == "\n")
    }

    @Test("Escape \\t decoded to tab")
    func parseEscapeTab() {
        let rules = CommandRuleParser.parse(raw: "indent = \\t")
        #expect(rules[0].replacement == "\t")
    }

    @Test("Escape \\s decoded to space")
    func parseEscapeSpace() {
        let rules = CommandRuleParser.parse(raw: "sp = \\s")
        #expect(rules[0].replacement == " ")
    }

    @Test("Escape \\\\ decoded to backslash")
    func parseEscapeBackslash() {
        let rules = CommandRuleParser.parse(raw: "bs = \\\\")
        #expect(rules[0].replacement == "\\")
    }

    @Test("Multiple escapes in one replacement")
    func parseMultipleEscapes() {
        let rules = CommandRuleParser.parse(raw: "multi = \\n\\t\\s\\\\")
        #expect(rules[0].replacement == "\n\t \\")
    }

    @Test("Multiple rules parsed in order")
    func parseMultipleRules() {
        let raw = "a = 1\nb = 2\nc = 3"
        let rules = CommandRuleParser.parse(raw: raw)
        #expect(rules.count == 3)
        #expect(rules[0].phrase == "a")
        #expect(rules[1].phrase == "b")
        #expect(rules[2].phrase == "c")
    }

    @Test("Trailing whitespace trimmed from phrase and replacement")
    func parseTrimsWhitespace() {
        let rules = CommandRuleParser.parse(raw: "  hello   =   world   ")
        #expect(rules[0].phrase == "hello")
        #expect(rules[0].replacement == "world")
    }

    @Test("=> with spaces around it")
    func parseArrowWithSpaces() {
        let rules = CommandRuleParser.parse(raw: "foo  =>  bar baz")
        #expect(rules[0].phrase == "foo")
        #expect(rules[0].replacement == "bar baz")
    }

    @Test("Rule with multiple = uses first =")
    func parseMultipleEquals() {
        let rules = CommandRuleParser.parse(raw: "a = b = c")
        #expect(rules[0].phrase == "a")
        // First = is separator, rest is replacement
        #expect(rules[0].replacement == "b = c")
    }

    // MARK: - BuiltInCommandRules

    @Test("BuiltInCommandRules.all is non-empty")
    func builtInRulesNonEmpty() {
        #expect(!BuiltInCommandRules.all.isEmpty)
    }

    @Test("BuiltInCommandRules has at least 50 rules")
    func builtInRulesCount() {
        #expect(BuiltInCommandRules.all.count >= 50)
    }

    @Test("All built-in phrases are non-empty")
    func builtInPhrasesNonEmpty() {
        for rule in BuiltInCommandRules.all {
            #expect(!rule.phrase.isEmpty, "Found empty phrase")
        }
    }

    @Test("All built-in phrases are unique")
    func builtInPhrasesUnique() {
        let phrases = BuiltInCommandRules.all.map(\.phrase)
        let unique = Set(phrases)
        #expect(unique.count == phrases.count, "Duplicate phrase found")
    }

    @Test("new line maps to \\n")
    func builtInNewLine() {
        let rule = BuiltInCommandRules.all.first { $0.phrase == "new line" }
        #expect(rule?.replacement == "\n")
    }

    @Test("new paragraph maps to double \\n")
    func builtInNewParagraph() {
        let rule = BuiltInCommandRules.all.first { $0.phrase == "new paragraph" }
        #expect(rule?.replacement == "\n\n")
    }

    @Test("comma maps to ,")
    func builtInComma() {
        let rule = BuiltInCommandRules.all.first { $0.phrase == "comma" }
        #expect(rule?.replacement == ",")
    }

    @Test("period and full stop both map to .")
    func builtInPeriodAndFullStop() {
        let period = BuiltInCommandRules.all.first { $0.phrase == "period" }
        let fullStop = BuiltInCommandRules.all.first { $0.phrase == "full stop" }
        #expect(period?.replacement == ".")
        #expect(fullStop?.replacement == ".")
    }

    @Test("question mark maps to ?")
    func builtInQuestionMark() {
        let rule = BuiltInCommandRules.all.first { $0.phrase == "question mark" }
        #expect(rule?.replacement == "?")
    }

    @Test("exclamation mark and exclamation point both map to !")
    func builtInExclamation() {
        let mark = BuiltInCommandRules.all.first { $0.phrase == "exclamation mark" }
        let point = BuiltInCommandRules.all.first { $0.phrase == "exclamation point" }
        #expect(mark?.replacement == "!")
        #expect(point?.replacement == "!")
    }

    @Test("open/close parenthesis")
    func builtInParenthesis() {
        let open = BuiltInCommandRules.all.first { $0.phrase == "open parenthesis" }
        let close = BuiltInCommandRules.all.first { $0.phrase == "close parenthesis" }
        #expect(open?.replacement == "(")
        #expect(close?.replacement == ")")
    }

    @Test("open/close bracket")
    func builtInBracket() {
        let open = BuiltInCommandRules.all.first { $0.phrase == "open bracket" }
        let close = BuiltInCommandRules.all.first { $0.phrase == "close bracket" }
        #expect(open?.replacement == "[")
        #expect(close?.replacement == "]")
    }

    @Test("open/close brace")
    func builtInBrace() {
        let open = BuiltInCommandRules.all.first { $0.phrase == "open brace" }
        let close = BuiltInCommandRules.all.first { $0.phrase == "close brace" }
        #expect(open?.replacement == "{")
        #expect(close?.replacement == "}")
    }

    @Test("em dash")
    func builtInEmDash() {
        let rule = BuiltInCommandRules.all.first { $0.phrase == "em dash" }
        #expect(rule?.replacement == "—")
    }

    @Test("ellipsis and dot dot dot")
    func builtInEllipsis() {
        let ellipsis = BuiltInCommandRules.all.first { $0.phrase == "ellipsis" }
        let dotDotDot = BuiltInCommandRules.all.first { $0.phrase == "dot dot dot" }
        #expect(ellipsis?.replacement == "…")
        #expect(dotDotDot?.replacement == "…")
    }

    @Test("programming operators: arrow, fat arrow, double/triple equals, not equals")
    func builtInProgrammingOps() {
        let arrow = BuiltInCommandRules.all.first { $0.phrase == "right arrow" }
        let fatArrow = BuiltInCommandRules.all.first { $0.phrase == "fat arrow" }
        let doubleEq = BuiltInCommandRules.all.first { $0.phrase == "double equals" }
        let tripleEq = BuiltInCommandRules.all.first { $0.phrase == "triple equals" }
        let notEq = BuiltInCommandRules.all.first { $0.phrase == "not equals" }
        #expect(arrow?.replacement == "->")
        #expect(fatArrow?.replacement == "=>")
        #expect(doubleEq?.replacement == "==")
        #expect(tripleEq?.replacement == "===")
        #expect(notEq?.replacement == "!=")
    }

    @Test("Swift-specific: null coalescing, optional chaining, force unwrap")
    func builtInSwiftOps() {
        let nullCoal = BuiltInCommandRules.all.first { $0.phrase == "null coalescing" }
        let optChain = BuiltInCommandRules.all.first { $0.phrase == "optional chaining" }
        let forceUnwrap = BuiltInCommandRules.all.first { $0.phrase == "force unwrap" }
        #expect(nullCoal?.replacement == "??")
        #expect(optChain?.replacement == "?.")
        #expect(forceUnwrap?.replacement == "!")
    }

    @Test("bullet point includes newline prefix")
    func builtInBulletPoint() {
        let rule = BuiltInCommandRules.all.first { $0.phrase == "bullet point" }
        #expect(rule?.replacement == "\n- ")
    }

    @Test("tab character maps to \\t")
    func builtInTabCharacter() {
        let rule = BuiltInCommandRules.all.first { $0.phrase == "tab character" }
        #expect(rule?.replacement == "\t")
    }

    @Test("degree sign and copyright sign")
    func builtInSpecialSymbols() {
        let degree = BuiltInCommandRules.all.first { $0.phrase == "degree sign" }
        let copyright = BuiltInCommandRules.all.first { $0.phrase == "copyright sign" }
        #expect(degree?.replacement == "°")
        #expect(copyright?.replacement == "©")
    }

    // MARK: - CommandRule Hashable conformance

    @Test("CommandRule equality: same phrase and replacement")
    func commandRuleEquality() {
        let a = CommandRule(phrase: "hello", replacement: "world")
        let b = CommandRule(phrase: "hello", replacement: "world")
        #expect(a == b)
    }

    @Test("CommandRule inequality: different phrase")
    func commandRuleInequalityPhrase() {
        let a = CommandRule(phrase: "hello", replacement: "world")
        let b = CommandRule(phrase: "hi", replacement: "world")
        #expect(a != b)
    }

    @Test("CommandRule inequality: different replacement")
    func commandRuleInequalityReplacement() {
        let a = CommandRule(phrase: "hello", replacement: "world")
        let b = CommandRule(phrase: "hello", replacement: "earth")
        #expect(a != b)
    }

    @Test("CommandRule hashable: equal rules have same hash")
    func commandRuleHash() {
        let a = CommandRule(phrase: "hello", replacement: "world")
        let b = CommandRule(phrase: "hello", replacement: "world")
        #expect(a.hashValue == b.hashValue)
    }

    @Test("CommandRule can be stored in a Set")
    func commandRuleInSet() {
        let a = CommandRule(phrase: "hello", replacement: "world")
        let b = CommandRule(phrase: "hello", replacement: "world")
        let c = CommandRule(phrase: "foo", replacement: "bar")
        let set: Set<CommandRule> = [a, b, c]
        #expect(set.count == 2)
    }

    // MARK: - Parser stress tests

    @Test("Very long rule text")
    func parseLongText() {
        let longPhrase = String(repeating: "word ", count: 100).trimmingCharacters(in: .whitespaces)
        let longReplacement = String(repeating: "x", count: 1000)
        let rules = CommandRuleParser.parse(raw: "\(longPhrase) = \(longReplacement)")
        #expect(rules.count == 1)
        #expect(rules[0].replacement == longReplacement)
    }

    @Test("Many rules parsed correctly")
    func parseManyRules() {
        let raw = (0..<100).map { "rule\($0) = value\($0)" }.joined(separator: "\n")
        let rules = CommandRuleParser.parse(raw: raw)
        #expect(rules.count == 100)
    }

    @Test("Windows-style line endings (\\r\\n)")
    func parseWindowsLineEndings() {
        let raw = "a = 1\r\nb = 2\r\nc = 3"
        let rules = CommandRuleParser.parse(raw: raw)
        #expect(rules.count == 3)
    }

    @Test("Unicode in phrase and replacement")
    func parseUnicode() {
        let rules = CommandRuleParser.parse(raw: "привет = мир")
        #expect(rules.count == 1)
        #expect(rules[0].phrase == "привет")
        #expect(rules[0].replacement == "мир")
    }

    @Test("Emoji in replacement")
    func parseEmoji() {
        let rules = CommandRuleParser.parse(raw: "smile = 😊")
        #expect(rules[0].replacement == "😊")
    }

    @Test("Only # character on a line is treated as comment")
    func parseHashOnlyLine() {
        let rules = CommandRuleParser.parse(raw: "#")
        #expect(rules.isEmpty)
    }

    @Test("Rule with # in replacement (not a comment)")
    func parseHashInReplacement() {
        let rules = CommandRuleParser.parse(raw: "tag = #hashtag")
        #expect(rules[0].replacement == "#hashtag")
    }
}
