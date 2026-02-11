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
        case "space", "spacebar", "tab", "return", "enter", "escape", "esc", "delete", "del", "backspace", "bksp", "forwarddelete", "left", "right", "up", "down", "home", "end", "pageup", "pgup", "pagedown", "pgdn", "minus", "hyphen", "equals", "equal", "plus", "openbracket", "leftbracket", "closebracket", "rightbracket", "semicolon", "apostrophe", "quote", "comma", "period", "dot", "slash", "forwardslash", "backslash", "backtick", "grave", "keypad0", "numpad0", "keypad1", "numpad1", "keypad2", "numpad2", "keypad3", "numpad3", "keypad4", "numpad4", "keypad5", "numpad5", "keypad6", "numpad6", "keypad7", "numpad7", "keypad8", "numpad8", "keypad9", "numpad9", "keypaddecimal", "numpaddecimal", "keypadmultiply", "numpadmultiply", "keypadplus", "numpadplus", "keypadclear", "numpadclear", "keypaddivide", "numpaddivide", "keypadenter", "numpadenter", "keypadminus", "numpadminus", "keypadequals", "numpadequals":
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
        switch normalized {
        case "spacebar", "␣": return "space"
        case "enter", "↩", "⏎": return "return"
        case "esc", "⎋": return "escape"
        case "del", "backspace", "bksp", "⌫": return "delete"
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
        case "pgdn", "pgdown": return "pagedown"
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
        case "numpaddecimal": return "keypaddecimal"
        case "numpadmultiply": return "keypadmultiply"
        case "numpadplus": return "keypadplus"
        case "numpadclear": return "keypadclear"
        case "numpaddivide": return "keypaddivide"
        case "numpadenter": return "keypadenter"
        case "numpadminus": return "keypadminus"
        case "numpadequals": return "keypadequals"
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
