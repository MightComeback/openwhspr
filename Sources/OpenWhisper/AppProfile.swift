import Foundation

struct AppProfile: Codable, Identifiable, Hashable {
    let bundleIdentifier: String
    var appName: String

    var autoCopy: Bool
    var autoPaste: Bool
    var clearAfterInsert: Bool
    var commandReplacements: Bool
    var smartCapitalization: Bool
    var terminalPunctuation: Bool

    var id: String { bundleIdentifier }
}
