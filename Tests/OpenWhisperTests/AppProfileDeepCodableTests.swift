import Testing
import Foundation
@testable import OpenWhisper

@Suite("AppProfile Deep Codable & Identity")
struct AppProfileDeepCodableTests {

    // MARK: - Codable round-trip

    @Test("Full round-trip encode → decode preserves all fields")
    func fullRoundTrip() throws {
        let original = AppProfile(
            bundleIdentifier: "com.test.app",
            appName: "Test App",
            autoCopy: true,
            autoPaste: false,
            clearAfterInsert: true,
            commandReplacements: false,
            smartCapitalization: true,
            terminalPunctuation: false,
            customCommands: "hello => world"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppProfile.self, from: data)
        #expect(decoded.bundleIdentifier == "com.test.app")
        #expect(decoded.appName == "Test App")
        #expect(decoded.autoCopy == true)
        #expect(decoded.autoPaste == false)
        #expect(decoded.clearAfterInsert == true)
        #expect(decoded.commandReplacements == false)
        #expect(decoded.smartCapitalization == true)
        #expect(decoded.terminalPunctuation == false)
        #expect(decoded.customCommands == "hello => world")
    }

    @Test("Decoding without customCommands key defaults to empty string")
    func missingCustomCommandsKey() throws {
        let json = """
        {
            "bundleIdentifier": "com.legacy.app",
            "appName": "Legacy",
            "autoCopy": true,
            "autoPaste": true,
            "clearAfterInsert": false,
            "commandReplacements": true,
            "smartCapitalization": true,
            "terminalPunctuation": true
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AppProfile.self, from: json)
        #expect(decoded.customCommands == "")
        #expect(decoded.bundleIdentifier == "com.legacy.app")
    }

    @Test("Decoding with empty customCommands preserves empty")
    func emptyCustomCommands() throws {
        let json = """
        {
            "bundleIdentifier": "com.empty.cmds",
            "appName": "Empty",
            "autoCopy": false,
            "autoPaste": false,
            "clearAfterInsert": false,
            "commandReplacements": false,
            "smartCapitalization": false,
            "terminalPunctuation": false,
            "customCommands": ""
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AppProfile.self, from: json)
        #expect(decoded.customCommands == "")
    }

    @Test("Decoding with multiline customCommands")
    func multilineCustomCommands() throws {
        let profile = AppProfile(
            bundleIdentifier: "com.multi.cmds",
            appName: "Multi",
            autoCopy: true, autoPaste: true, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: true, terminalPunctuation: true,
            customCommands: "hello => hi\nbye => ciao"
        )
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(AppProfile.self, from: data)
        #expect(decoded.customCommands.contains("hello => hi"))
        #expect(decoded.customCommands.contains("bye => ciao"))
    }

    // MARK: - Identifiable & Hashable

    @Test("id equals bundleIdentifier")
    func idEquality() {
        let profile = AppProfile(
            bundleIdentifier: "com.id.test",
            appName: "ID Test",
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: false, smartCapitalization: false, terminalPunctuation: false
        )
        #expect(profile.id == "com.id.test")
    }

    @Test("Two profiles with same bundleIdentifier and fields are equal")
    func equalProfiles() {
        let a = AppProfile(
            bundleIdentifier: "com.eq.test", appName: "Eq",
            autoCopy: true, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: true, terminalPunctuation: true
        )
        let b = AppProfile(
            bundleIdentifier: "com.eq.test", appName: "Eq",
            autoCopy: true, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: true, terminalPunctuation: true
        )
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Two profiles with different bundleIdentifier are not equal")
    func differentBundleIds() {
        let a = AppProfile(
            bundleIdentifier: "com.a", appName: "A",
            autoCopy: true, autoPaste: true, clearAfterInsert: true,
            commandReplacements: true, smartCapitalization: true, terminalPunctuation: true
        )
        let b = AppProfile(
            bundleIdentifier: "com.b", appName: "A",
            autoCopy: true, autoPaste: true, clearAfterInsert: true,
            commandReplacements: true, smartCapitalization: true, terminalPunctuation: true
        )
        #expect(a != b)
    }

    @Test("Same bundleId but different settings are not equal")
    func sameIdDifferentSettings() {
        let a = AppProfile(
            bundleIdentifier: "com.diff", appName: "D",
            autoCopy: true, autoPaste: true, clearAfterInsert: true,
            commandReplacements: true, smartCapitalization: true, terminalPunctuation: true
        )
        let b = AppProfile(
            bundleIdentifier: "com.diff", appName: "D",
            autoCopy: false, autoPaste: true, clearAfterInsert: true,
            commandReplacements: true, smartCapitalization: true, terminalPunctuation: true
        )
        #expect(a != b)
    }

    @Test("Profiles work in a Set")
    func profileInSet() {
        let profile = AppProfile(
            bundleIdentifier: "com.set.test", appName: "Set",
            autoCopy: true, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: true, terminalPunctuation: true
        )
        var s: Set<AppProfile> = []
        s.insert(profile)
        s.insert(profile)
        #expect(s.count == 1)
    }

    @Test("Mutating appName changes the profile")
    func mutateAppName() {
        var profile = AppProfile(
            bundleIdentifier: "com.mut", appName: "Original",
            autoCopy: true, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: true, terminalPunctuation: true
        )
        profile.appName = "Changed"
        #expect(profile.appName == "Changed")
        #expect(profile.bundleIdentifier == "com.mut")
    }

    // MARK: - JSON with extra keys (future-proofing)

    @Test("Decoding with unknown extra keys does not crash")
    func extraKeysIgnored() throws {
        let json = """
        {
            "bundleIdentifier": "com.extra",
            "appName": "Extra",
            "autoCopy": true,
            "autoPaste": false,
            "clearAfterInsert": false,
            "commandReplacements": true,
            "smartCapitalization": true,
            "terminalPunctuation": true,
            "customCommands": "",
            "unknownFutureField": 42
        }
        """.data(using: .utf8)!
        // Should not throw — extra keys are silently ignored by default Codable
        let decoded = try JSONDecoder().decode(AppProfile.self, from: json)
        #expect(decoded.bundleIdentifier == "com.extra")
    }

    @Test("Encoding produces valid JSON with all keys")
    func encodingAllKeys() throws {
        let profile = AppProfile(
            bundleIdentifier: "com.encode", appName: "Enc",
            autoCopy: true, autoPaste: true, clearAfterInsert: true,
            commandReplacements: true, smartCapitalization: true, terminalPunctuation: true,
            customCommands: "test => ok"
        )
        let data = try JSONEncoder().encode(profile)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(dict["bundleIdentifier"] as? String == "com.encode")
        #expect(dict["customCommands"] as? String == "test => ok")
        #expect(dict.keys.count == 9) // all 9 CodingKeys
    }

    @Test("Decoding with missing required field throws")
    func missingRequiredFieldThrows() {
        let json = """
        {
            "bundleIdentifier": "com.missing",
            "autoCopy": true,
            "autoPaste": false,
            "clearAfterInsert": false,
            "commandReplacements": true,
            "smartCapitalization": true,
            "terminalPunctuation": true
        }
        """.data(using: .utf8)!
        #expect(throws: (any Error).self) {
            _ = try JSONDecoder().decode(AppProfile.self, from: json)
        }
    }

    // MARK: - Default customCommands in init

    @Test("Init without customCommands defaults to empty string")
    func initDefaultCustomCommands() {
        let profile = AppProfile(
            bundleIdentifier: "com.default", appName: "Default",
            autoCopy: true, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: true, terminalPunctuation: true
        )
        #expect(profile.customCommands == "")
    }

    // MARK: - Array encoding/decoding

    @Test("Array of profiles round-trips correctly")
    func arrayRoundTrip() throws {
        let profiles = [
            AppProfile(bundleIdentifier: "com.a", appName: "A", autoCopy: true, autoPaste: false, clearAfterInsert: false, commandReplacements: true, smartCapitalization: true, terminalPunctuation: true),
            AppProfile(bundleIdentifier: "com.b", appName: "B", autoCopy: false, autoPaste: true, clearAfterInsert: true, commandReplacements: false, smartCapitalization: false, terminalPunctuation: false, customCommands: "x => y"),
        ]
        let data = try JSONEncoder().encode(profiles)
        let decoded = try JSONDecoder().decode([AppProfile].self, from: data)
        #expect(decoded.count == 2)
        #expect(decoded[0].bundleIdentifier == "com.a")
        #expect(decoded[1].customCommands == "x => y")
    }
}
