import Foundation

enum ModelSource: String, CaseIterable, Identifiable {
    case bundledTiny
    case customPath

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bundledTiny:
            return "Bundled tiny model"
        case .customPath:
            return "Custom local model"
        }
    }
}
