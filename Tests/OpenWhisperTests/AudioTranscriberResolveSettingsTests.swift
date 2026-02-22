import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber – resolveOutputSettings comprehensive", .serialized)
struct AudioTranscriberResolveSettingsTests {

    private func makeDefaults(
        autoCopy: Bool = true,
        autoPaste: Bool = false,
        clearAfterInsert: Bool = false,
        commandReplacements: Bool = true,
        smartCapitalization: Bool = true,
        terminalPunctuation: Bool = true,
        customCommandsRaw: String = ""
    ) -> AudioTranscriber.EffectiveOutputSettings {
        AudioTranscriber.EffectiveOutputSettings(
            autoCopy: autoCopy,
            autoPaste: autoPaste,
            clearAfterInsert: clearAfterInsert,
            commandReplacements: commandReplacements,
            smartCapitalization: smartCapitalization,
            terminalPunctuation: terminalPunctuation,
            customCommandsRaw: customCommandsRaw
        )
    }

    private func makeProfile(
        bundleIdentifier: String = "com.test",
        appName: String = "Test",
        autoCopy: Bool = false,
        autoPaste: Bool = true,
        clearAfterInsert: Bool = true,
        commandReplacements: Bool = false,
        smartCapitalization: Bool = false,
        terminalPunctuation: Bool = false,
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

    // MARK: - nil profile returns defaults

    @Test("nil profile returns defaults unchanged")
    @MainActor func nilProfileReturnsDefaults() {
        let t = AudioTranscriber.shared
        let defaults = makeDefaults(autoCopy: false, customCommandsRaw: "hello")
        let result = t.resolveOutputSettings(defaults: defaults, profile: nil)
        #expect(result.autoCopy == false)
        #expect(result.customCommandsRaw == "hello")
    }

    // MARK: - Profile overrides all boolean fields

    @Test("profile overrides autoCopy")
    @MainActor func profileOverridesAutoCopy() {
        let t = AudioTranscriber.shared
        let result = t.resolveOutputSettings(defaults: makeDefaults(autoCopy: true), profile: makeProfile(autoCopy: false))
        #expect(result.autoCopy == false)
    }

    @Test("profile overrides autoPaste")
    @MainActor func profileOverridesAutoPaste() {
        let t = AudioTranscriber.shared
        let result = t.resolveOutputSettings(defaults: makeDefaults(autoPaste: false), profile: makeProfile(autoPaste: true))
        #expect(result.autoPaste == true)
    }

    @Test("profile overrides clearAfterInsert")
    @MainActor func profileOverridesClearAfterInsert() {
        let t = AudioTranscriber.shared
        let result = t.resolveOutputSettings(defaults: makeDefaults(clearAfterInsert: false), profile: makeProfile(clearAfterInsert: true))
        #expect(result.clearAfterInsert == true)
    }

    @Test("profile overrides commandReplacements")
    @MainActor func profileOverridesCommandReplacements() {
        let t = AudioTranscriber.shared
        let result = t.resolveOutputSettings(defaults: makeDefaults(commandReplacements: true), profile: makeProfile(commandReplacements: false))
        #expect(result.commandReplacements == false)
    }

    @Test("profile overrides smartCapitalization")
    @MainActor func profileOverridesSmartCapitalization() {
        let t = AudioTranscriber.shared
        let result = t.resolveOutputSettings(defaults: makeDefaults(smartCapitalization: true), profile: makeProfile(smartCapitalization: false))
        #expect(result.smartCapitalization == false)
    }

    @Test("profile overrides terminalPunctuation")
    @MainActor func profileOverridesTerminalPunctuation() {
        let t = AudioTranscriber.shared
        let result = t.resolveOutputSettings(defaults: makeDefaults(terminalPunctuation: true), profile: makeProfile(terminalPunctuation: false))
        #expect(result.terminalPunctuation == false)
    }

    // MARK: - Custom commands merging

    @Test("both empty custom commands yields empty")
    @MainActor func bothEmptyCustomCommands() {
        let t = AudioTranscriber.shared
        let result = t.resolveOutputSettings(defaults: makeDefaults(customCommandsRaw: ""), profile: makeProfile(customCommands: ""))
        #expect(result.customCommandsRaw == "")
    }

    @Test("defaults-only custom commands preserved when profile empty")
    @MainActor func defaultsOnlyCustomCommands() {
        let t = AudioTranscriber.shared
        let result = t.resolveOutputSettings(defaults: makeDefaults(customCommandsRaw: "go => go"), profile: makeProfile(customCommands: ""))
        #expect(result.customCommandsRaw == "go => go")
    }

    @Test("profile-only custom commands preserved when defaults empty")
    @MainActor func profileOnlyCustomCommands() {
        let t = AudioTranscriber.shared
        let result = t.resolveOutputSettings(defaults: makeDefaults(customCommandsRaw: ""), profile: makeProfile(customCommands: "stop => halt"))
        #expect(result.customCommandsRaw == "stop => halt")
    }

    @Test("both non-empty custom commands are merged with newline")
    @MainActor func mergedCustomCommands() {
        let t = AudioTranscriber.shared
        let result = t.resolveOutputSettings(defaults: makeDefaults(customCommandsRaw: "a => b"), profile: makeProfile(customCommands: "c => d"))
        #expect(result.customCommandsRaw == "a => b\nc => d")
    }

    @Test("whitespace-only defaults treated as empty for custom commands")
    @MainActor func whitespaceOnlyDefaultsCustomCommands() {
        let t = AudioTranscriber.shared
        let result = t.resolveOutputSettings(defaults: makeDefaults(customCommandsRaw: "   \n  "), profile: makeProfile(customCommands: "x => y"))
        #expect(result.customCommandsRaw == "x => y")
    }

    @Test("whitespace-only profile treated as empty for custom commands")
    @MainActor func whitespaceOnlyProfileCustomCommands() {
        let t = AudioTranscriber.shared
        let result = t.resolveOutputSettings(defaults: makeDefaults(customCommandsRaw: "x => y"), profile: makeProfile(customCommands: "  \n  "))
        #expect(result.customCommandsRaw == "x => y")
    }

    @Test("multiline custom commands merged correctly")
    @MainActor func multilineCustomCommandsMerge() {
        let t = AudioTranscriber.shared
        let defaults = makeDefaults(customCommandsRaw: "a => b\nc => d")
        let profile = makeProfile(customCommands: "e => f\ng => h")
        let result = t.resolveOutputSettings(defaults: defaults, profile: profile)
        #expect(result.customCommandsRaw == "a => b\nc => d\ne => f\ng => h")
    }

    // MARK: - All flags false

    @Test("all false flags preserved through profile")
    @MainActor func allFalseFlags() {
        let t = AudioTranscriber.shared
        let profile = makeProfile(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: false, smartCapitalization: false, terminalPunctuation: false
        )
        let result = t.resolveOutputSettings(defaults: makeDefaults(), profile: profile)
        #expect(result.autoCopy == false)
        #expect(result.autoPaste == false)
        #expect(result.clearAfterInsert == false)
        #expect(result.commandReplacements == false)
        #expect(result.smartCapitalization == false)
        #expect(result.terminalPunctuation == false)
    }

    // MARK: - All flags true

    @Test("all true flags preserved through profile")
    @MainActor func allTrueFlags() {
        let t = AudioTranscriber.shared
        let profile = makeProfile(
            autoCopy: true, autoPaste: true, clearAfterInsert: true,
            commandReplacements: true, smartCapitalization: true, terminalPunctuation: true
        )
        let result = t.resolveOutputSettings(defaults: makeDefaults(), profile: profile)
        #expect(result.autoCopy == true)
        #expect(result.autoPaste == true)
        #expect(result.clearAfterInsert == true)
        #expect(result.commandReplacements == true)
        #expect(result.smartCapitalization == true)
        #expect(result.terminalPunctuation == true)
    }

    // MARK: - EffectiveOutputSettings struct

    @Test("EffectiveOutputSettings stores all fields")
    func effectiveOutputSettingsFields() {
        let s = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: true, autoPaste: true, clearAfterInsert: true,
            commandReplacements: true, smartCapitalization: true,
            terminalPunctuation: true, customCommandsRaw: "test"
        )
        #expect(s.autoCopy == true)
        #expect(s.autoPaste == true)
        #expect(s.clearAfterInsert == true)
        #expect(s.commandReplacements == true)
        #expect(s.smartCapitalization == true)
        #expect(s.terminalPunctuation == true)
        #expect(s.customCommandsRaw == "test")
    }

    @Test("EffectiveOutputSettings is mutable")
    func effectiveOutputSettingsMutable() {
        var s = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: true, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: true,
            terminalPunctuation: true, customCommandsRaw: ""
        )
        s.autoCopy = false
        s.customCommandsRaw = "changed"
        #expect(s.autoCopy == false)
        #expect(s.customCommandsRaw == "changed")
    }

    // MARK: - Unicode and special characters in custom commands

    @Test("unicode custom commands preserved")
    @MainActor func unicodeCustomCommands() {
        let t = AudioTranscriber.shared
        let result = t.resolveOutputSettings(
            defaults: makeDefaults(customCommandsRaw: "привет => мир"),
            profile: makeProfile(customCommands: "🎤 => 🔇")
        )
        #expect(result.customCommandsRaw == "привет => мир\n🎤 => 🔇")
    }

    @Test("newlines within custom commands are preserved")
    @MainActor func newlinesWithinCustomCommands() {
        let t = AudioTranscriber.shared
        let result = t.resolveOutputSettings(
            defaults: makeDefaults(customCommandsRaw: "line1\nline2"),
            profile: makeProfile(customCommands: "line3")
        )
        #expect(result.customCommandsRaw == "line1\nline2\nline3")
    }
}
