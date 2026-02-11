import Foundation

/// Shared formatting helpers for displaying the current hotkey configuration.
enum HotkeyDisplay {
    static func summary(defaults: UserDefaults = .standard) -> String {
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
        default:
            if normalized.count == 1 {
                return normalized.uppercased()
            }
            return normalized.capitalized
        }
    }
}
