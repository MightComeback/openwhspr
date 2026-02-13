import Foundation

/// Shared formatting helpers for displaying the current hotkey configuration.
enum HotkeyDisplay {
    static func summary(defaults: UserDefaults = .standard) -> String {
        comboSummary(defaults: defaults)
    }

    static func isSupportedKey(_ raw: String) -> Bool {
        let normalized = canonicalKey(raw)
        if normalized.isEmpty {
            return false
        }

        switch normalized {
        case "space", "spacebar", "tab", "return", "enter", "escape", "esc", "delete", "del", "backspace", "bksp", "forwarddelete", "insert", "ins", "help", "caps", "capslock", "fn", "function", "globe", "globekey", "left", "right", "up", "down", "home", "end", "pageup", "pgup", "pagedown", "pgdn", "minus", "hyphen", "equals", "equal", "plus", "openbracket", "leftbracket", "closebracket", "rightbracket", "semicolon", "apostrophe", "quote", "comma", "period", "dot", "slash", "forwardslash", "backslash", "backtick", "grave", "keypad0", "numpad0", "keypad1", "numpad1", "keypad2", "numpad2", "keypad3", "numpad3", "keypad4", "numpad4", "keypad5", "numpad5", "keypad6", "numpad6", "keypad7", "numpad7", "keypad8", "numpad8", "keypad9", "numpad9", "keypaddecimal", "numpaddecimal", "keypadmultiply", "numpadmultiply", "keypadplus", "numpadplus", "keypadclear", "numpadclear", "keypaddivide", "numpaddivide", "keypadenter", "numpadenter", "keypadminus", "numpadminus", "keypadequals", "numpadequals":
            return true
        case "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20", "f21", "f22", "f23", "f24":
            return true
        default:
            return normalized.count == 1
        }
    }

    /// Returns a short, user-facing string including the configured hotkey mode.
    /// Example: `Toggle • ⌘+⇧+Space` or `Hold • ⌘+⇧+Space`.
    static func summaryIncludingMode(defaults: UserDefaults = .standard) -> String {
        let modeRaw = defaults.string(forKey: AppDefaults.Keys.hotkeyMode) ?? HotkeyMode.toggle.rawValue
        let mode = HotkeyMode(rawValue: modeRaw) ?? .toggle
        return "\(mode.title) • \(comboSummary(defaults: defaults))"
    }

    /// Converts aliases like `enter`, `spacebar`, `page up`, and `page-up` into the
    /// canonical key value stored in user defaults.
    static func canonicalKey(_ raw: String) -> String {
        let normalized = normalizeKey(raw)

        if let functionAlias = canonicalFunctionKeyAlias(normalized) {
            return functionAlias
        }

        switch normalized {
        case "spacebar", "spacekey", "␣", "␠", "⎵": return "space"
        case "tabkey", "⇥", "⇤": return "tab"
        case "enter", "enterkey", "returnkey", "return/enter", "enter/return", "↩", "↵", "⏎": return "return"
        case "esc", "escapekey", "escape/esc", "esc/escape", "⎋": return "escape"
        case "del", "deletekey", "backspace", "backspacekey", "delete/backspace", "backspace/delete", "bksp", "⌫": return "delete"
        case "⌦", "␡", "forwarddeletekey", "fwddelete", "fwddel": return "forwarddelete"
        case "insertkey", "ins": return "insert"
        case "help", "helpkey": return "help"
        case "caps", "capskey": return "capslock"
        case "function", "fnkey", "globe", "globekey", "fn/globe", "globe/fn", "🌐": return "fn"
        case "←", "leftarrow", "leftkey": return "left"
        case "→", "rightarrow", "rightkey": return "right"
        case "↑", "uparrow", "upkey": return "up"
        case "↓", "downarrow", "downkey": return "down"
        case "hyphen", "_": return "minus"
        case "equal", "plus", "+": return "equals"
        case "leftbracket", "{": return "openbracket"
        case "rightbracket", "}": return "closebracket"
        case "quote", "\"": return "apostrophe"
        case "dot", ">": return "period"
        case "forwardslash", "?": return "slash"
        case "grave", "graveaccent", "tilde", "~": return "backtick"
        case ":": return "semicolon"
        case "<": return "comma"
        case "|": return "backslash"
        case "!": return "1"
        case "@": return "2"
        case "#": return "3"
        case "$": return "4"
        case "%": return "5"
        case "^": return "6"
        case "&": return "7"
        case "*": return "8"
        case "(": return "9"
        case ")": return "0"
        case "homekey": return "home"
        case "endkey": return "end"
        case "pgup", "pgupkey", "pageupkey", "⇞": return "pageup"
        case "pgdn", "pgdnkey", "pgdown", "pagedownkey", "⇟": return "pagedown"
        case "numpad0": return "keypad0"
        case "numpad1": return "keypad1"
        case "numpad2": return "keypad2"
        case "numpad3": return "keypad3"
        case "numpad4": return "keypad4"
        case "numpad5": return "keypad5"
        case "numpad6": return "keypad6"
        case "numpad7": return "keypad7"
        case "numpad8": return "keypad8"
        case "numpad9": return "keypad9"
        case "numpad.", "keypad.": return "keypaddecimal"
        case "numpad+", "keypad+": return "keypadplus"
        case "numpad-", "keypad-": return "keypadminus"
        case "numpad*", "keypad*", "numpadx", "keypadx": return "keypadmultiply"
        case "numpad/", "keypad/": return "keypaddivide"
        case "numpad=", "keypad=": return "keypadequals"
        case "numpaddecimal", "numdecimal", "numdot", "numperiod", "kpdecimal", "kpdot": return "keypaddecimal"
        case "numpadmultiply", "nummultiply", "numtimes", "kpmultiply", "kptimes": return "keypadmultiply"
        case "numpadplus", "numplus", "kpplus": return "keypadplus"
        case "numpadclear", "numclear", "kpclear": return "keypadclear"
        case "numpaddivide", "numdivide", "kpdivide": return "keypaddivide"
        case "numpadenter", "numenter", "kpenter", "keypadenterkey", "⌤": return "keypadenter"
        case "numpadminus", "numminus", "kpminus": return "keypadminus"
        case "numpadequals", "numequals", "kpequals": return "keypadequals"
        default: return normalized
        }
    }

    private static func comboSummary(defaults: UserDefaults) -> String {
        var parts: [String] = []

        if defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredCommand) { parts.append("⌘") }
        if defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredShift) { parts.append("⇧") }
        if defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredOption) { parts.append("⌥") }
        if defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredControl) { parts.append("⌃") }
        if defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredCapsLock) { parts.append("⇪") }

        let key = canonicalKey(defaults.string(forKey: AppDefaults.Keys.hotkeyKey) ?? "space")
        parts.append(displayKey(key))

        return parts.joined(separator: "+")
    }

    static func displayKey(_ raw: String) -> String {
        let normalized = canonicalKey(raw)
        switch normalized {
        case "space", "spacebar": return "Space"
        case "tab": return "Tab"
        case "return", "enter": return "Return/Enter"
        case "escape", "esc": return "Esc"
        case "delete", "backspace": return "Delete"
        case "forwarddelete": return "FwdDelete"
        case "insert", "ins": return "Insert"
        case "help": return "Help"
        case "caps", "capslock": return "CapsLock"
        case "fn", "function", "globe", "globekey": return "Fn/Globe"
        case "minus", "hyphen": return "-"
        case "equals", "equal", "plus": return "="
        case "openbracket", "leftbracket": return "["
        case "closebracket", "rightbracket": return "]"
        case "semicolon": return ";"
        case "apostrophe", "quote": return "'"
        case "comma": return ","
        case "period", "dot": return "."
        case "slash", "forwardslash": return "/"
        case "backslash": return "\\"
        case "backtick", "grave": return "`"
        case "left": return "←"
        case "right": return "→"
        case "up": return "↑"
        case "down": return "↓"
        case "home": return "Home"
        case "end": return "End"
        case "pageup", "pgup": return "PgUp"
        case "pagedown", "pgdn": return "PgDn"
        case "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20", "f21", "f22", "f23", "f24":
            return normalized.uppercased()
        case "keypad0": return "Num0"
        case "keypad1": return "Num1"
        case "keypad2": return "Num2"
        case "keypad3": return "Num3"
        case "keypad4": return "Num4"
        case "keypad5": return "Num5"
        case "keypad6": return "Num6"
        case "keypad7": return "Num7"
        case "keypad8": return "Num8"
        case "keypad9": return "Num9"
        case "keypaddecimal": return "Num."
        case "keypadmultiply": return "Num*"
        case "keypadplus": return "Num+"
        case "keypadclear": return "NumClear"
        case "keypaddivide": return "Num/"
        case "keypadenter": return "NumEnter"
        case "keypadminus": return "Num-"
        case "keypadequals": return "Num="
        default:
            if normalized.count == 1 {
                return normalized.uppercased()
            }
            return normalized.capitalized
        }
    }

    private static func canonicalFunctionKeyAlias(_ normalized: String) -> String? {
        let prefixes = ["fn", "function", "f"]

        for prefix in prefixes {
            guard normalized.hasPrefix(prefix), normalized.count > prefix.count else {
                continue
            }

            let suffix = String(normalized.dropFirst(prefix.count))
            guard let value = Int(suffix), (1...24).contains(value) else {
                continue
            }

            return "f\(value)"
        }

        return nil
    }

    private static func normalizeKey(_ raw: String) -> String {
        // When users press a literal key in the trigger field, we can receive
        // control characters instead of aliases (e.g. " " for Space).
        // Preserve those common raw-key inputs before trimming.
        if raw == " " { return "space" }
        if raw == "\t" { return "tab" }
        if raw == "\r" || raw == "\n" { return "return" }

        let normalizedWhitespace = raw
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{2007}", with: " ")
            .replacingOccurrences(of: "\u{202F}", with: " ")

        let trimmed = normalizedWhitespace
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\u{FE0E}", with: "")
            .replacingOccurrences(of: "\u{FE0F}", with: "")

        switch trimmed {
        case "⌘": return "command"
        case "⇧": return "shift"
        case "⌥": return "option"
        case "⌃": return "control"
        case "⇪": return "capslock"
        default: break
        }

        switch trimmed {
        case "numpad +", "keypad +": return "numpad+"
        case "numpad -", "keypad -": return "numpad-"
        case "numpad *", "keypad *", "numpad x", "keypad x": return "numpad*"
        case "numpad /", "keypad /": return "numpad/"
        case "numpad .", "keypad .": return "numpad."
        case "numpad =", "keypad =": return "numpad="
        default: break
        }

        guard trimmed.count > 1 else {
            return trimmed
        }

        // Common keypad shorthand like "num+" / "kp*" should map to
        // supported keypad trigger keys instead of being split apart.
        let compact = trimmed
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
        switch compact {
        case "num+", "kp+", "numpad+", "keypad+": return "numpadplus"
        case "num-", "kp-", "numpad-", "keypad-": return "numpadminus"
        case "num*", "kp*", "numx", "kpx", "numpad*", "keypad*": return "numpadmultiply"
        case "num/", "kp/", "numpad/", "keypad/": return "numpaddivide"
        case "num.", "kp.", "numpad.", "keypad.": return "numpaddecimal"
        case "num=", "kp=", "numpad=", "keypad=": return "numpadequals"
        case "capslock", "capslockkey": return "capslock"
        case "fnglobe", "globefn", "functionglobe", "globefunction": return "fn"
        default: break
        }

        // Some apps/docs collapse shortcuts without separators, e.g.
        // "commandshiftspace" or "ctrlaltdelete". Strip known modifier
        // prefixes greedily and keep the trailing key token.
        if compact.range(of: "^[a-z0-9]+$", options: .regularExpression) != nil {
            let compactModifierPrefixes = [
                "command", "cmd", "control", "ctrl", "option", "opt", "alt",
                "shift", "capslock", "caps", "meta", "super", "win", "windows"
            ]
            var compactRemainder = compact
            var strippedCompactModifier = false

            while !compactRemainder.isEmpty {
                guard let prefix = compactModifierPrefixes.first(where: { compactRemainder.hasPrefix($0) }) else {
                    break
                }
                compactRemainder.removeFirst(prefix.count)
                strippedCompactModifier = true
            }

            if strippedCompactModifier, !compactRemainder.isEmpty {
                return compactRemainder
            }
        }

        // Users also paste symbol-only shortcuts like "⌘⇧space".
        // Expand common modifier glyphs into tokenizable words first.
        let expanded = trimmed
            .replacingOccurrences(of: "⌘", with: " command ")
            .replacingOccurrences(of: "⇧", with: " shift ")
            .replacingOccurrences(of: "⌥", with: " option ")
            .replacingOccurrences(of: "⌃", with: " control ")
            .replacingOccurrences(of: "⇪", with: " capslock ")
            .replacingOccurrences(of: "🌐", with: " globe ")

        // UX guardrail: users often paste full shortcuts like "cmd+shift+space"
        // or "command-shift-page-down" into the trigger-key field. We only store
        // the trigger key, so strip known modifier tokens first and keep the
        // remaining key tokens joined.
        let shortcutTokens = expanded
            .components(separatedBy: CharacterSet(charactersIn: "+ -_,/"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let modifierTokens: Set<String> = [
            "cmd", "command", "meta", "super", "win", "windows",
            "shift", "option", "opt", "alt", "control", "ctrl",
            "caps", "capslock", "fn", "function", "fnkey", "globe", "globekey", "🌐"
        ]

        if shortcutTokens.contains(where: { modifierTokens.contains($0) }) {
            let keyTokens = shortcutTokens.filter { !modifierTokens.contains($0) }
            if !keyTokens.isEmpty {
                return keyTokens.joined()
            }
        }

        // Fallback for classic + separated combo pastes.
        let comboTail = trimmed
            .split(omittingEmptySubsequences: true, whereSeparator: { $0 == "+" || $0 == "," })
            .last
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        let candidate = (comboTail?.isEmpty == false) ? comboTail! : trimmed

        let separators = CharacterSet(charactersIn: " -_,")
        let collapsed = candidate.components(separatedBy: separators).joined()
        return collapsed.isEmpty ? candidate : collapsed
    }
}
