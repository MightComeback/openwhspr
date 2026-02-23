import Testing
import Foundation
@testable import OpenWhisper

@Suite("AppDefaults Full Registration")
struct AppDefaultsFullRegistrationTests {

    private func freshSuite(_ name: String) -> UserDefaults {
        let suite = UserDefaults(suiteName: "test.fullReg.\(name)")!
        suite.removePersistentDomain(forName: "test.fullReg.\(name)")
        return suite
    }

    // MARK: - Hotkey defaults

    @Test("register sets hotkeyMode to toggle")
    func hotkeyModeDefault() {
        let s = freshSuite("hotkeyMode")
        defer { s.removePersistentDomain(forName: "test.fullReg.hotkeyMode") }
        AppDefaults.register(into: s)
        #expect(s.string(forKey: AppDefaults.Keys.hotkeyMode) == HotkeyMode.toggle.rawValue)
    }

    @Test("register sets hotkeyKey to space")
    func hotkeyKeyDefault() {
        let s = freshSuite("hotkeyKey")
        defer { s.removePersistentDomain(forName: "test.fullReg.hotkeyKey") }
        AppDefaults.register(into: s)
        #expect(s.string(forKey: AppDefaults.Keys.hotkeyKey) == "space")
    }

    @Test("register sets required modifiers: command=true, shift=true, option=false, control=false, capsLock=false")
    func requiredModifierDefaults() {
        let s = freshSuite("reqMod")
        defer { s.removePersistentDomain(forName: "test.fullReg.reqMod") }
        AppDefaults.register(into: s)
        #expect(s.bool(forKey: AppDefaults.Keys.hotkeyRequiredCommand) == true)
        #expect(s.bool(forKey: AppDefaults.Keys.hotkeyRequiredShift) == true)
        #expect(s.bool(forKey: AppDefaults.Keys.hotkeyRequiredOption) == false)
        #expect(s.bool(forKey: AppDefaults.Keys.hotkeyRequiredControl) == false)
        #expect(s.bool(forKey: AppDefaults.Keys.hotkeyRequiredCapsLock) == false)
    }

    @Test("register sets forbidden modifiers: command=false, shift=false, option=true, control=true, capsLock=false")
    func forbiddenModifierDefaults() {
        let s = freshSuite("forbMod")
        defer { s.removePersistentDomain(forName: "test.fullReg.forbMod") }
        AppDefaults.register(into: s)
        #expect(s.bool(forKey: AppDefaults.Keys.hotkeyForbiddenCommand) == false)
        #expect(s.bool(forKey: AppDefaults.Keys.hotkeyForbiddenShift) == false)
        #expect(s.bool(forKey: AppDefaults.Keys.hotkeyForbiddenOption) == true)
        #expect(s.bool(forKey: AppDefaults.Keys.hotkeyForbiddenControl) == true)
        #expect(s.bool(forKey: AppDefaults.Keys.hotkeyForbiddenCapsLock) == false)
    }

    // MARK: - Output defaults

    @Test("register sets outputAutoCopy to true")
    func outputAutoCopy() {
        let s = freshSuite("autoCopy")
        defer { s.removePersistentDomain(forName: "test.fullReg.autoCopy") }
        AppDefaults.register(into: s)
        #expect(s.bool(forKey: AppDefaults.Keys.outputAutoCopy) == true)
    }

    @Test("register sets outputAutoPaste to false")
    func outputAutoPaste() {
        let s = freshSuite("autoPaste")
        defer { s.removePersistentDomain(forName: "test.fullReg.autoPaste") }
        AppDefaults.register(into: s)
        #expect(s.bool(forKey: AppDefaults.Keys.outputAutoPaste) == false)
    }

    @Test("register sets outputClearAfterInsert to false")
    func outputClearAfterInsert() {
        let s = freshSuite("clearAfter")
        defer { s.removePersistentDomain(forName: "test.fullReg.clearAfter") }
        AppDefaults.register(into: s)
        #expect(s.bool(forKey: AppDefaults.Keys.outputClearAfterInsert) == false)
    }

    @Test("register sets outputCommandReplacements to true")
    func outputCommandReplacements() {
        let s = freshSuite("cmdReplace")
        defer { s.removePersistentDomain(forName: "test.fullReg.cmdReplace") }
        AppDefaults.register(into: s)
        #expect(s.bool(forKey: AppDefaults.Keys.outputCommandReplacements) == true)
    }

    @Test("register sets outputSmartCapitalization to true")
    func outputSmartCapitalization() {
        let s = freshSuite("smartCap")
        defer { s.removePersistentDomain(forName: "test.fullReg.smartCap") }
        AppDefaults.register(into: s)
        #expect(s.bool(forKey: AppDefaults.Keys.outputSmartCapitalization) == true)
    }

    @Test("register sets outputTerminalPunctuation to true")
    func outputTerminalPunctuation() {
        let s = freshSuite("termPunct")
        defer { s.removePersistentDomain(forName: "test.fullReg.termPunct") }
        AppDefaults.register(into: s)
        #expect(s.bool(forKey: AppDefaults.Keys.outputTerminalPunctuation) == true)
    }

    @Test("register sets outputCustomCommands to empty string")
    func outputCustomCommands() {
        let s = freshSuite("customCmds")
        defer { s.removePersistentDomain(forName: "test.fullReg.customCmds") }
        AppDefaults.register(into: s)
        #expect(s.string(forKey: AppDefaults.Keys.outputCustomCommands) == "")
    }

    // MARK: - Transcription defaults

    @Test("register sets transcriptionReplacements to empty string")
    func transcriptionReplacements() {
        let s = freshSuite("transReplace")
        defer { s.removePersistentDomain(forName: "test.fullReg.transReplace") }
        AppDefaults.register(into: s)
        #expect(s.string(forKey: AppDefaults.Keys.transcriptionReplacements) == "")
    }

    @Test("register sets transcriptionHistoryLimit to 25")
    func transcriptionHistoryLimit() {
        let s = freshSuite("histLimit")
        defer { s.removePersistentDomain(forName: "test.fullReg.histLimit") }
        AppDefaults.register(into: s)
        #expect(s.integer(forKey: AppDefaults.Keys.transcriptionHistoryLimit) == 25)
    }

    @Test("register sets appProfiles to empty JSON array")
    func appProfiles() {
        let s = freshSuite("profiles")
        defer { s.removePersistentDomain(forName: "test.fullReg.profiles") }
        AppDefaults.register(into: s)
        #expect(s.string(forKey: AppDefaults.Keys.appProfiles) == "[]")
    }

    @Test("register sets transcriptionLanguage to auto")
    func transcriptionLanguage() {
        let s = freshSuite("transLang")
        defer { s.removePersistentDomain(forName: "test.fullReg.transLang") }
        AppDefaults.register(into: s)
        #expect(s.string(forKey: AppDefaults.Keys.transcriptionLanguage) == "auto")
    }

    @Test("register sets transcriptionHistory to empty JSON array")
    func transcriptionHistory() {
        let s = freshSuite("transHist")
        defer { s.removePersistentDomain(forName: "test.fullReg.transHist") }
        AppDefaults.register(into: s)
        #expect(s.string(forKey: AppDefaults.Keys.transcriptionHistory) == "[]")
    }

    // MARK: - Model defaults

    @Test("register sets modelSource to bundledTiny")
    func modelSource() {
        let s = freshSuite("modelSrc")
        defer { s.removePersistentDomain(forName: "test.fullReg.modelSrc") }
        AppDefaults.register(into: s)
        #expect(s.string(forKey: AppDefaults.Keys.modelSource) == ModelSource.bundledTiny.rawValue)
    }

    @Test("register sets modelCustomPath to empty string")
    func modelCustomPath() {
        let s = freshSuite("modelPath")
        defer { s.removePersistentDomain(forName: "test.fullReg.modelPath") }
        AppDefaults.register(into: s)
        #expect(s.string(forKey: AppDefaults.Keys.modelCustomPath) == "")
    }

    // MARK: - App defaults

    @Test("register sets onboardingCompleted to false")
    func onboardingCompleted() {
        let s = freshSuite("onboard")
        defer { s.removePersistentDomain(forName: "test.fullReg.onboard") }
        AppDefaults.register(into: s)
        #expect(s.bool(forKey: AppDefaults.Keys.onboardingCompleted) == false)
    }

    @Test("register sets insertionProbeSampleText to default")
    func insertionProbeSampleText() {
        let s = freshSuite("probeTxt")
        defer { s.removePersistentDomain(forName: "test.fullReg.probeTxt") }
        AppDefaults.register(into: s)
        #expect(s.string(forKey: AppDefaults.Keys.insertionProbeSampleText) == "OpenWhisper insertion test")
    }

    @Test("register sets audioFeedbackEnabled to true")
    func audioFeedbackEnabled() {
        let s = freshSuite("audioFb")
        defer { s.removePersistentDomain(forName: "test.fullReg.audioFb") }
        AppDefaults.register(into: s)
        #expect(s.bool(forKey: AppDefaults.Keys.audioFeedbackEnabled) == true)
    }

    @Test("register sets launchAtLogin to false")
    func launchAtLogin() {
        let s = freshSuite("launchLogin")
        defer { s.removePersistentDomain(forName: "test.fullReg.launchLogin") }
        AppDefaults.register(into: s)
        #expect(s.bool(forKey: AppDefaults.Keys.launchAtLogin) == false)
    }

    // MARK: - User overrides preserved

    @Test("register preserves user-set hotkeyKey")
    func preserveHotkeyKey() {
        let s = freshSuite("preserveKey")
        defer { s.removePersistentDomain(forName: "test.fullReg.preserveKey") }
        s.set("escape", forKey: AppDefaults.Keys.hotkeyKey)
        AppDefaults.register(into: s)
        #expect(s.string(forKey: AppDefaults.Keys.hotkeyKey) == "escape")
    }

    @Test("register preserves user-set outputAutoPaste")
    func preserveAutoPaste() {
        let s = freshSuite("preservePaste")
        defer { s.removePersistentDomain(forName: "test.fullReg.preservePaste") }
        s.set(true, forKey: AppDefaults.Keys.outputAutoPaste)
        AppDefaults.register(into: s)
        #expect(s.bool(forKey: AppDefaults.Keys.outputAutoPaste) == true)
    }

    @Test("register preserves user-set transcriptionLanguage")
    func preserveTranscriptionLanguage() {
        let s = freshSuite("preserveLang")
        defer { s.removePersistentDomain(forName: "test.fullReg.preserveLang") }
        s.set("en", forKey: AppDefaults.Keys.transcriptionLanguage)
        AppDefaults.register(into: s)
        #expect(s.string(forKey: AppDefaults.Keys.transcriptionLanguage) == "en")
    }

    @Test("register preserves user-set historyLimit")
    func preserveHistoryLimit() {
        let s = freshSuite("preserveHist")
        defer { s.removePersistentDomain(forName: "test.fullReg.preserveHist") }
        s.set(50, forKey: AppDefaults.Keys.transcriptionHistoryLimit)
        AppDefaults.register(into: s)
        #expect(s.integer(forKey: AppDefaults.Keys.transcriptionHistoryLimit) == 50)
    }

    @Test("register preserves user-set modelSource")
    func preserveModelSource() {
        let s = freshSuite("preserveModel")
        defer { s.removePersistentDomain(forName: "test.fullReg.preserveModel") }
        s.set(ModelSource.customPath.rawValue, forKey: AppDefaults.Keys.modelSource)
        AppDefaults.register(into: s)
        #expect(s.string(forKey: AppDefaults.Keys.modelSource) == ModelSource.customPath.rawValue)
    }

    @Test("register preserves all forbidden modifier overrides")
    func preserveForbiddenModifiers() {
        let s = freshSuite("preserveForbid")
        defer { s.removePersistentDomain(forName: "test.fullReg.preserveForbid") }
        s.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenCommand)
        s.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenShift)
        s.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenOption)
        s.set(false, forKey: AppDefaults.Keys.hotkeyForbiddenControl)
        s.set(true, forKey: AppDefaults.Keys.hotkeyForbiddenCapsLock)
        AppDefaults.register(into: s)
        #expect(s.bool(forKey: AppDefaults.Keys.hotkeyForbiddenCommand) == true)
        #expect(s.bool(forKey: AppDefaults.Keys.hotkeyForbiddenShift) == true)
        #expect(s.bool(forKey: AppDefaults.Keys.hotkeyForbiddenOption) == false)
        #expect(s.bool(forKey: AppDefaults.Keys.hotkeyForbiddenControl) == false)
        #expect(s.bool(forKey: AppDefaults.Keys.hotkeyForbiddenCapsLock) == true)
    }

    // MARK: - All keys are unique

    @Test("All 30 AppDefaults keys are unique")
    func allKeysUnique() {
        let keys = [
            AppDefaults.Keys.hotkeyMode,
            AppDefaults.Keys.hotkeyKey,
            AppDefaults.Keys.hotkeyRequiredCommand,
            AppDefaults.Keys.hotkeyRequiredShift,
            AppDefaults.Keys.hotkeyRequiredOption,
            AppDefaults.Keys.hotkeyRequiredControl,
            AppDefaults.Keys.hotkeyRequiredCapsLock,
            AppDefaults.Keys.hotkeyForbiddenCommand,
            AppDefaults.Keys.hotkeyForbiddenShift,
            AppDefaults.Keys.hotkeyForbiddenOption,
            AppDefaults.Keys.hotkeyForbiddenControl,
            AppDefaults.Keys.hotkeyForbiddenCapsLock,
            AppDefaults.Keys.outputAutoCopy,
            AppDefaults.Keys.outputAutoPaste,
            AppDefaults.Keys.outputClearAfterInsert,
            AppDefaults.Keys.outputCommandReplacements,
            AppDefaults.Keys.outputSmartCapitalization,
            AppDefaults.Keys.outputTerminalPunctuation,
            AppDefaults.Keys.outputCustomCommands,
            AppDefaults.Keys.transcriptionReplacements,
            AppDefaults.Keys.transcriptionHistoryLimit,
            AppDefaults.Keys.appProfiles,
            AppDefaults.Keys.modelSource,
            AppDefaults.Keys.modelCustomPath,
            AppDefaults.Keys.onboardingCompleted,
            AppDefaults.Keys.insertionProbeSampleText,
            AppDefaults.Keys.audioFeedbackEnabled,
            AppDefaults.Keys.launchAtLogin,
            AppDefaults.Keys.transcriptionLanguage,
            AppDefaults.Keys.transcriptionHistory,
        ]
        let unique = Set(keys)
        #expect(unique.count == keys.count, "Duplicate keys found")
    }

    // MARK: - Parameterless register() calls register(into: .standard)

    @Test("register() without arguments does not crash")
    func parameterlessRegister() {
        AppDefaults.register()
        // Should not crash and should set defaults in .standard
        let mode = UserDefaults.standard.string(forKey: AppDefaults.Keys.hotkeyMode)
        #expect(mode != nil)
    }
}
