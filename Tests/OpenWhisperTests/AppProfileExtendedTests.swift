import Testing
import Foundation
@testable import OpenWhisper

@Suite("AppProfile – extended coverage")
struct AppProfileExtendedTests {

    private func makeProfile(
        bundleIdentifier: String = "com.test.app",
        appName: String = "Test",
        autoCopy: Bool = true,
        autoPaste: Bool = false,
        clearAfterInsert: Bool = false,
        commandReplacements: Bool = true,
        smartCapitalization: Bool = true,
        terminalPunctuation: Bool = true,
        customCommands: String = ""
    ) -> AppProfile {
        AppProfile(
            bundleIdentifier: bundleIdentifier,
            appName: appName,
            autoCopy: autoCopy,
            autoPaste: autoPaste,
            clearAfterInsert: clearAfterInsert,
            commandReplacements: commandReplacements,
            smartCapitalization: smartCapitalization,
            terminalPunctuation: terminalPunctuation,
            customCommands: customCommands
        )
    }

    // MARK: - Identifiable

    @Test("id is bundleIdentifier")
    func identifiable() {
        let p = makeProfile(bundleIdentifier: "com.example.foo")
        #expect(p.id == "com.example.foo")
    }

    // MARK: - Hashable / Equatable

    @Test("identical profiles are equal")
    func equality() {
        let a = makeProfile()
        let b = makeProfile()
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("different bundleIdentifier makes unequal")
    func differentBundle() {
        let a = makeProfile(bundleIdentifier: "com.a")
        let b = makeProfile(bundleIdentifier: "com.b")
        #expect(a != b)
    }

    @Test("different appName makes unequal")
    func differentName() {
        let a = makeProfile(appName: "A")
        let b = makeProfile(appName: "B")
        #expect(a != b)
    }

    @Test("different boolean flags make unequal")
    func differentFlags() {
        let a = makeProfile(autoPaste: false)
        let b = makeProfile(autoPaste: true)
        #expect(a != b)
    }

    @Test("different customCommands makes unequal")
    func differentCustomCommands() {
        let a = makeProfile(customCommands: "a")
        let b = makeProfile(customCommands: "b")
        #expect(a != b)
    }

    // MARK: - Codable round-trips

    @Test("full Codable round-trip preserves all fields")
    func fullRoundTrip() throws {
        let original = makeProfile(
            bundleIdentifier: "com.round.trip",
            appName: "RoundTrip",
            autoCopy: false,
            autoPaste: true,
            clearAfterInsert: true,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommands: "hello => world"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppProfile.self, from: data)
        #expect(decoded == original)
    }

    @Test("missing customCommands defaults to empty string")
    func missingCustomCommandsDefaults() throws {
        let json = """
        {
          "bundleIdentifier": "com.test",
          "appName": "Test",
          "autoCopy": true,
          "autoPaste": false,
          "clearAfterInsert": false,
          "commandReplacements": true,
          "smartCapitalization": true,
          "terminalPunctuation": true
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(AppProfile.self, from: data)
        #expect(decoded.customCommands == "")
        #expect(decoded.bundleIdentifier == "com.test")
        #expect(decoded.appName == "Test")
        #expect(decoded.autoCopy == true)
    }

    @Test("empty customCommands encodes as empty string")
    func emptyCustomCommandsEncodes() throws {
        let profile = makeProfile(customCommands: "")
        let data = try JSONEncoder().encode(profile)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"customCommands\":\"\""))
    }

    @Test("unicode in appName and customCommands round-trips")
    func unicodeRoundTrip() throws {
        let profile = makeProfile(appName: "Тест 🚀", customCommands: "ñ => ñ")
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(AppProfile.self, from: data)
        #expect(decoded.appName == "Тест 🚀")
        #expect(decoded.customCommands == "ñ => ñ")
    }

    // MARK: - Mutability

    @Test("mutable fields can be changed")
    func mutability() {
        var p = makeProfile(appName: "Old", autoCopy: true)
        p.autoCopy = false
        p.appName = "New"
        p.customCommands = "updated"
        #expect(p.autoCopy == false)
        #expect(p.appName == "New")
        #expect(p.customCommands == "updated")
    }

    // MARK: - Set/Dictionary usage

    @Test("profiles work in Set")
    func setUsage() {
        let a = makeProfile(bundleIdentifier: "com.a")
        let b = makeProfile(bundleIdentifier: "com.b")
        let c = makeProfile(bundleIdentifier: "com.a") // same as a
        var set: Set<AppProfile> = [a, b, c]
        #expect(set.count == 2)
        set.remove(a)
        #expect(set.count == 1)
    }
}
