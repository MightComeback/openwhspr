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
        case "space", "spacebar", "tab", "return", "enter", "escape", "esc", "delete", "backspace", "forwarddelete", "left", "right", "up", "down", "home", "end", "pageup", "pgup", "pagedown", "pgdn", "minus", "hyphen", "equals", "equal", "plus", "openbracket", "leftbracket", "closebracket", "rightbracket", "semicolon", "apostrophe", "quote", "comma", "period", "dot", "slash", "forwardslash", "backslash", "backtick", "grave":
            return true
        case "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20":
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
        switch normalized {
        case "spacebar", "␣": return "space"
        case "enter", "↩", "⏎": return "return"
        case "esc", "⎋": return "escape"
        case "backspace", "⌫": return "delete"
        case "⌦": return "forwarddelete"
        case "←": return "left"
        case "→": return "right"
        case "↑": return "up"
        case "↓": return "down"
        case "hyphen": return "minus"
        case "equal", "plus": return "equals"
        case "leftbracket": return "openbracket"
        case "rightbracket": return "closebracket"
        case "quote": return "apostrophe"
        case "dot": return "period"
        case "forwardslash": return "slash"
        case "grave": return "backtick"
        case "pgup": return "pageup"
        case "pgdn": return "pagedown"
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
        case "return", "enter": return "Return"
        case "escape", "esc": return "Esc"
        case "delete", "backspace": return "Delete"
        case "forwarddelete": return "FwdDelete"
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
        case "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20":
            return normalized.uppercased()
        default:
            if normalized.count == 1 {
                return normalized.uppercased()
            }
            return normalized.capitalized
        }
    }

    private static func normalizeKey(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.count > 1 else {
            return trimmed
        }

        let separators = CharacterSet(charactersIn: " -_")
        let collapsed = trimmed.components(separatedBy: separators).joined()
        return collapsed.isEmpty ? trimmed : collapsed
    }
}
