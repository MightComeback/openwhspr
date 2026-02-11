import Foundation

/// Shared formatting helpers for displaying the current hotkey configuration.
enum HotkeyDisplay {
    static func summary(defaults: UserDefaults = .standard) -> String {
        comboSummary(defaults: defaults)
    }

    static func isSupportedKey(_ raw: String) -> Bool {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.isEmpty {
            return false
        }

        switch normalized {
        case "space", "spacebar", "tab", "return", "enter", "escape", "esc", "delete", "backspace", "forwarddelete", "left", "right", "up", "down":
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

    private static func comboSummary(defaults: UserDefaults) -> String {
        var parts: [String] = []

        if defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredCommand) { parts.append("⌘") }
        if defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredShift) { parts.append("⇧") }
        if defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredOption) { parts.append("⌥") }
        if defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredControl) { parts.append("⌃") }
        if defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredCapsLock) { parts.append("⇪") }

        let key = defaults.string(forKey: AppDefaults.Keys.hotkeyKey) ?? "space"
        parts.append(displayKey(key))

        return parts.joined(separator: "+")
    }

    static func displayKey(_ raw: String) -> String {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "space", "spacebar": return "Space"
        case "tab": return "Tab"
        case "return", "enter": return "Return"
        case "escape", "esc": return "Esc"
        case "delete", "backspace": return "Delete"
        case "forwarddelete": return "FwdDelete"
        case "left": return "←"
        case "right": return "→"
        case "up": return "↑"
        case "down": return "↓"
        case "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20":
            return normalized.uppercased()
        default:
            if normalized.count == 1 {
                return normalized.uppercased()
            }
            return normalized.capitalized
        }
    }
}
