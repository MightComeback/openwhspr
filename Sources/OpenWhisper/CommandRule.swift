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
        CommandRule(phrase: "hyphen", replacement: "-"),
        CommandRule(phrase: "em dash", replacement: "—"),
        CommandRule(phrase: "ellipsis", replacement: "…"),
        CommandRule(phrase: "dot dot dot", replacement: "…"),
        CommandRule(phrase: "ampersand", replacement: "&"),
        CommandRule(phrase: "at sign", replacement: "@"),
        CommandRule(phrase: "hashtag", replacement: "#"),
        CommandRule(phrase: "hash sign", replacement: "#"),
        CommandRule(phrase: "dollar sign", replacement: "$"),
        CommandRule(phrase: "percent sign", replacement: "%"),
        CommandRule(phrase: "slash", replacement: "/"),
        CommandRule(phrase: "backslash", replacement: "\\"),
        CommandRule(phrase: "underscore", replacement: "_"),
        CommandRule(phrase: "single quote", replacement: "'"),
        CommandRule(phrase: "apostrophe", replacement: "'"),
        CommandRule(phrase: "bullet point", replacement: "\n- "),
        CommandRule(phrase: "tab character", replacement: "\t"),
        CommandRule(phrase: "plus sign", replacement: "+"),
        CommandRule(phrase: "equals sign", replacement: "="),
        CommandRule(phrase: "asterisk", replacement: "*"),
        CommandRule(phrase: "pipe", replacement: "|"),
        CommandRule(phrase: "tilde", replacement: "~")
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
