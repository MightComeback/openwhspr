import Testing
@testable import OpenWhisper

@Suite("CommandRule")
struct CommandRuleTests {
    @Test
    func builtInCommandRulesContainNewLine() {
        let hasNewLine = BuiltInCommandRules.all.contains { rule in
            rule.phrase == "new line" && rule.replacement == "\n"
        }
        #expect(hasNewLine)
    }

    @Test
    func commandRuleParserParsesArrow() {
        let rules = CommandRuleParser.parse(raw: "Hello => world")
        #expect(rules.count == 1)
        #expect(rules.first?.phrase == "hello")
        #expect(rules.first?.replacement == "world")
    }

    @Test
    func commandRuleParserParsesEquals() {
        let rules = CommandRuleParser.parse(raw: "Foo=bar")
        #expect(rules.count == 1)
        #expect(rules.first?.phrase == "foo")
        #expect(rules.first?.replacement == "bar")
    }

    @Test
    func commandRuleParserIgnoresCommentsAndEmptyLines() {
        let rules = CommandRuleParser.parse(raw: "# comment\n\n  \n")
        #expect(rules.isEmpty)
    }

    @Test
    func commandRuleParserDecodesEscapes() {
        let rules = CommandRuleParser.parse(raw: "line => first\\nsecond")
        #expect(rules.count == 1)
        #expect(rules.first?.replacement == "first\nsecond")
    }
}
