import Foundation

struct CommandRule: Hashable {
    let phrase: String
    let replacement: String
}

enum BuiltInCommandRules {
    static let all: [CommandRule] = [
        CommandRule(phrase: "new line", replacement: "\n"),
        CommandRule(phrase: "new paragraph", replacement: "\n\n"),
        CommandRule(phrase: "comma", replacement: ","),
        CommandRule(phrase: "period", replacement: "."),
        CommandRule(phrase: "full stop", replacement: "."),
        CommandRule(phrase: "question mark", replacement: "?"),
        CommandRule(phrase: "exclamation mark", replacement: "!"),
        CommandRule(phrase: "exclamation point", replacement: "!"),
        CommandRule(phrase: "colon", replacement: ":"),
        CommandRule(phrase: "semicolon", replacement: ";"),
        CommandRule(phrase: "open quote", replacement: "\""),
        CommandRule(phrase: "close quote", replacement: "\""),
        CommandRule(phrase: "open parenthesis", replacement: "("),
        CommandRule(phrase: "close parenthesis", replacement: ")"),
        CommandRule(phrase: "open bracket", replacement: "["),
        CommandRule(phrase: "close bracket", replacement: "]"),
        CommandRule(phrase: "open brace", replacement: "{"),
        CommandRule(phrase: "close brace", replacement: "}"),
        CommandRule(phrase: "dash", replacement: "-"),
        CommandRule(phrase: "bullet point", replacement: "\n- ")
    ]
}

enum CommandRuleParser {
    static func parse(raw: String) -> [CommandRule] {
        var rules: [CommandRule] = []
        for line in raw.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            let separator: String
            if trimmed.contains("=>") {
                separator = "=>"
            } else if trimmed.contains("=") {
                separator = "="
            } else {
                continue
            }

            guard let range = trimmed.range(of: separator) else { continue }
            let left = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let rightRaw = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !left.isEmpty else { continue }

            let phrase = left.lowercased()
            let replacement = decodeEscapes(in: rightRaw)
            rules.append(CommandRule(phrase: phrase, replacement: replacement))
        }
        return rules
    }

    private static func decodeEscapes(in value: String) -> String {
        var output = value
        output = output.replacingOccurrences(of: "\\n", with: "\n")
        output = output.replacingOccurrences(of: "\\t", with: "\t")
        output = output.replacingOccurrences(of: "\\s", with: " ")
        output = output.replacingOccurrences(of: "\\\\", with: "\\")
        return output
    }
}
