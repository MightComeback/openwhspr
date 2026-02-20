import Testing
import Foundation
@testable import OpenWhisper

@Suite("AppProfile")
struct AppProfileTests {
    @Test
    func codableRoundTrip() throws {
        let profile = AppProfile(
            bundleIdentifier: "com.example.app",
            appName: "Example",
            autoCopy: true,
            autoPaste: false,
            clearAfterInsert: true,
            commandReplacements: true,
            smartCapitalization: false,
            terminalPunctuation: true,
            customCommands: "custom"
        )
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(AppProfile.self, from: data)
        #expect(decoded == profile)
    }

    @Test
    func codableDefaultsMissingCustomCommands() throws {
        let json = """
        {
          "bundleIdentifier": "com.example.app",
          "appName": "Example",
          "autoCopy": true,
          "autoPaste": false,
          "clearAfterInsert": true,
          "commandReplacements": false,
          "smartCapitalization": true,
          "terminalPunctuation": false
        }
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AppProfile.self, from: data)
        #expect(decoded.customCommands == "")
    }

    @Test
    func profileResolutionMergesCustomCommands() {
        let transcriber = AudioTranscriber.shared
        let defaults = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: true,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: true,
            smartCapitalization: true,
            terminalPunctuation: true,
            customCommandsRaw: "default"
        )
        let profile = AppProfile(
            bundleIdentifier: "com.example.app",
            appName: "Example",
            autoCopy: false,
            autoPaste: true,
            clearAfterInsert: true,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommands: "profile"
        )

        let resolved = transcriber.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(resolved.customCommandsRaw == "default\nprofile")
        #expect(resolved.autoPaste)
        #expect(!resolved.commandReplacements)
    }
}
