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
    var customCommands: String

    var id: String { bundleIdentifier }

    private enum CodingKeys: String, CodingKey {
        case bundleIdentifier
        case appName
        case autoCopy
        case autoPaste
        case clearAfterInsert
        case commandReplacements
        case smartCapitalization
        case terminalPunctuation
        case customCommands
    }

    init(
        bundleIdentifier: String,
        appName: String,
        autoCopy: Bool,
        autoPaste: Bool,
        clearAfterInsert: Bool,
        commandReplacements: Bool,
        smartCapitalization: Bool,
        terminalPunctuation: Bool,
        customCommands: String = ""
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.autoCopy = autoCopy
        self.autoPaste = autoPaste
        self.clearAfterInsert = clearAfterInsert
        self.commandReplacements = commandReplacements
        self.smartCapitalization = smartCapitalization
        self.terminalPunctuation = terminalPunctuation
        self.customCommands = customCommands
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        appName = try container.decode(String.self, forKey: .appName)
        autoCopy = try container.decode(Bool.self, forKey: .autoCopy)
        autoPaste = try container.decode(Bool.self, forKey: .autoPaste)
        clearAfterInsert = try container.decode(Bool.self, forKey: .clearAfterInsert)
        commandReplacements = try container.decode(Bool.self, forKey: .commandReplacements)
        smartCapitalization = try container.decode(Bool.self, forKey: .smartCapitalization)
        terminalPunctuation = try container.decode(Bool.self, forKey: .terminalPunctuation)
        customCommands = try container.decodeIfPresent(String.self, forKey: .customCommands) ?? ""
    }
}
