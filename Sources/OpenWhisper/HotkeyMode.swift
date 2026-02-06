import Foundation

enum HotkeyMode: String, CaseIterable, Identifiable {
    case toggle
    case hold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .toggle:
            return "Toggle"
        case .hold:
            return "Hold to talk"
        }
    }
}
