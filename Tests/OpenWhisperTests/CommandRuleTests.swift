import XCTest
@testable import OpenWhisper

final class CommandRuleTests: XCTestCase {
    func testBuiltInCommandRulesContainNewLine() {
        let hasNewLine = BuiltInCommandRules.all.contains { rule in
            rule.phrase == "new line" && rule.replacement == "\n"
        }
        XCTAssertTrue(hasNewLine)
    }

    func testCommandRuleParserParsesArrow() {
        let rules = CommandRuleParser.parse(raw: "Hello => world")
        XCTAssertEqual(rules.count, 1)
        XCTAssertEqual(rules.first?.phrase, "hello")
        XCTAssertEqual(rules.first?.replacement, "world")
    }

    func testCommandRuleParserParsesEquals() {
        let rules = CommandRuleParser.parse(raw: "Foo=bar")
        XCTAssertEqual(rules.count, 1)
        XCTAssertEqual(rules.first?.phrase, "foo")
        XCTAssertEqual(rules.first?.replacement, "bar")
    }

    func testCommandRuleParserIgnoresCommentsAndEmptyLines() {
        let rules = CommandRuleParser.parse(raw: "# comment\n\n  \n")
        XCTAssertTrue(rules.isEmpty)
    }

    func testCommandRuleParserDecodesEscapes() {
        let rules = CommandRuleParser.parse(raw: "line => first\\nsecond")
        XCTAssertEqual(rules.count, 1)
        XCTAssertEqual(rules.first?.replacement, "first\nsecond")
    }
}
