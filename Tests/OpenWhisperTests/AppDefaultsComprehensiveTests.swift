import Testing
import Foundation
@testable import OpenWhisper

@Suite("AppDefaults Comprehensive")
struct AppDefaultsComprehensiveTests {

    private func makeDefaults() -> (UserDefaults, String) {
        let suiteName = "AppDefaultsComprehensiveTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    private func cleanup(_ suiteName: String) {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    // MARK: - Key string stability

    @Test("Keys.hotkeyMode is hotkey.mode")
    func hotkeyModeKey() {
        #expect(AppDefaults.Keys.hotkeyMode == "hotkey.mode")
    }

    @Test("Keys.hotkeyKey is hotkey.key")
    func hotkeyKeyKey() {
        #expect(AppDefaults.Keys.hotkeyKey == "hotkey.key")
    }

    @Test("Keys.hotkeyRequiredCommand is hotkey.required.command")
    func hotkeyRequiredCommandKey() {
        #expect(AppDefaults.Keys.hotkeyRequiredCommand == "hotkey.required.command")
    }

    @Test("Keys.hotkeyRequiredShift is hotkey.required.shift")
    func hotkeyRequiredShiftKey() {
        #expect(AppDefaults.Keys.hotkeyRequiredShift == "hotkey.required.shift")
    }

    @Test("Keys.hotkeyRequiredOption is hotkey.required.option")
    func hotkeyRequiredOptionKey() {
        #expect(AppDefaults.Keys.hotkeyRequiredOption == "hotkey.required.option")
    }

    @Test("Keys.hotkeyRequiredControl is hotkey.required.control")
    func hotkeyRequiredControlKey() {
        #expect(AppDefaults.Keys.hotkeyRequiredControl == "hotkey.required.control")
    }

    @Test("Keys.hotkeyRequiredCapsLock is hotkey.required.capslock")
    func hotkeyRequiredCapsLockKey() {
        #expect(AppDefaults.Keys.hotkeyRequiredCapsLock == "hotkey.required.capslock")
    }

    @Test("Keys.hotkeyForbiddenCommand is hotkey.forbidden.command")
    func hotkeyForbiddenCommandKey() {
        #expect(AppDefaults.Keys.hotkeyForbiddenCommand == "hotkey.forbidden.command")
    }

    @Test("Keys.hotkeyForbiddenShift is hotkey.forbidden.shift")
    func hotkeyForbiddenShiftKey() {
        #expect(AppDefaults.Keys.hotkeyForbiddenShift == "hotkey.forbidden.shift")
    }

    @Test("Keys.hotkeyForbiddenOption is hotkey.forbidden.option")
    func hotkeyForbiddenOptionKey() {
        #expect(AppDefaults.Keys.hotkeyForbiddenOption == "hotkey.forbidden.option")
    }

    @Test("Keys.hotkeyForbiddenControl is hotkey.forbidden.control")
    func hotkeyForbiddenControlKey() {
        #expect(AppDefaults.Keys.hotkeyForbiddenControl == "hotkey.forbidden.control")
    }

    @Test("Keys.hotkeyForbiddenCapsLock is hotkey.forbidden.capslock")
    func hotkeyForbiddenCapsLockKey() {
        #expect(AppDefaults.Keys.hotkeyForbiddenCapsLock == "hotkey.forbidden.capslock")
    }

    @Test("Keys.outputAutoCopy is output.autoCopy")
    func outputAutoCopyKey() {
        #expect(AppDefaults.Keys.outputAutoCopy == "output.autoCopy")
    }

    @Test("Keys.outputAutoPaste is output.autoPaste")
    func outputAutoPasteKey() {
        #expect(AppDefaults.Keys.outputAutoPaste == "output.autoPaste")
    }

    @Test("Keys.outputClearAfterInsert is output.clearAfterInsert")
    func outputClearAfterInsertKey() {
        #expect(AppDefaults.Keys.outputClearAfterInsert == "output.clearAfterInsert")
    }

    @Test("Keys.outputCommandReplacements is output.commandReplacements")
    func outputCommandReplacementsKey() {
        #expect(AppDefaults.Keys.outputCommandReplacements == "output.commandReplacements")
    }

    @Test("Keys.outputSmartCapitalization is output.smartCapitalization")
    func outputSmartCapitalizationKey() {
        #expect(AppDefaults.Keys.outputSmartCapitalization == "output.smartCapitalization")
    }

    @Test("Keys.outputTerminalPunctuation is output.terminalPunctuation")
    func outputTerminalPunctuationKey() {
        #expect(AppDefaults.Keys.outputTerminalPunctuation == "output.terminalPunctuation")
    }

    @Test("Keys.outputCustomCommands is output.customCommands")
    func outputCustomCommandsKey() {
        #expect(AppDefaults.Keys.outputCustomCommands == "output.customCommands")
    }

    @Test("Keys.transcriptionReplacements is transcription.replacements")
    func transcriptionReplacementsKey() {
        #expect(AppDefaults.Keys.transcriptionReplacements == "transcription.replacements")
    }

    @Test("Keys.transcriptionHistoryLimit is transcription.historyLimit")
    func transcriptionHistoryLimitKey() {
        #expect(AppDefaults.Keys.transcriptionHistoryLimit == "transcription.historyLimit")
    }

    @Test("Keys.appProfiles is profiles.appOutput")
    func appProfilesKey() {
        #expect(AppDefaults.Keys.appProfiles == "profiles.appOutput")
    }

    @Test("Keys.modelSource is model.source")
    func modelSourceKey() {
        #expect(AppDefaults.Keys.modelSource == "model.source")
    }

    @Test("Keys.modelCustomPath is model.customPath")
    func modelCustomPathKey() {
        #expect(AppDefaults.Keys.modelCustomPath == "model.customPath")
    }

    @Test("Keys.onboardingCompleted is onboarding.completed")
    func onboardingCompletedKey() {
        #expect(AppDefaults.Keys.onboardingCompleted == "onboarding.completed")
    }

    @Test("Keys.insertionProbeSampleText is insertion.probeSampleText")
    func insertionProbeSampleTextKey() {
        #expect(AppDefaults.Keys.insertionProbeSampleText == "insertion.probeSampleText")
    }

    @Test("Keys.audioFeedbackEnabled is audio.feedbackEnabled")
    func audioFeedbackEnabledKey() {
        #expect(AppDefaults.Keys.audioFeedbackEnabled == "audio.feedbackEnabled")
    }

    @Test("Keys.launchAtLogin is app.launchAtLogin")
    func launchAtLoginKey() {
        #expect(AppDefaults.Keys.launchAtLogin == "app.launchAtLogin")
    }

    @Test("Keys.transcriptionLanguage is transcription.language")
    func transcriptionLanguageKey() {
        #expect(AppDefaults.Keys.transcriptionLanguage == "transcription.language")
    }

    @Test("Keys.transcriptionHistory is transcription.history")
    func transcriptionHistoryKey() {
        #expect(AppDefaults.Keys.transcriptionHistory == "transcription.history")
    }

    // MARK: - Register default values (exhaustive)

    @Test("register sets hotkeyMode to toggle")
    func registerHotkeyMode() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.string(forKey: AppDefaults.Keys.hotkeyMode) == HotkeyMode.toggle.rawValue)
    }

    @Test("register sets hotkeyKey to space")
    func registerHotkeyKey() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.string(forKey: AppDefaults.Keys.hotkeyKey) == "space")
    }

    @Test("register sets required command to true")
    func registerRequiredCommand() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.hotkeyRequiredCommand) == true)
    }

    @Test("register sets required shift to true")
    func registerRequiredShift() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.hotkeyRequiredShift) == true)
    }

    @Test("register sets required option to false")
    func registerRequiredOption() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.hotkeyRequiredOption) == false)
    }

    @Test("register sets required control to false")
    func registerRequiredControl() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.hotkeyRequiredControl) == false)
    }

    @Test("register sets required capslock to false")
    func registerRequiredCapsLock() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.hotkeyRequiredCapsLock) == false)
    }

    @Test("register sets forbidden command to false")
    func registerForbiddenCommand() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.hotkeyForbiddenCommand) == false)
    }

    @Test("register sets forbidden shift to false")
    func registerForbiddenShift() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.hotkeyForbiddenShift) == false)
    }

    @Test("register sets forbidden option to true")
    func registerForbiddenOption() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.hotkeyForbiddenOption) == true)
    }

    @Test("register sets forbidden control to true")
    func registerForbiddenControl() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.hotkeyForbiddenControl) == true)
    }

    @Test("register sets forbidden capslock to false")
    func registerForbiddenCapsLock() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.hotkeyForbiddenCapsLock) == false)
    }

    @Test("register sets outputAutoCopy to true")
    func registerOutputAutoCopy() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.outputAutoCopy) == true)
    }

    @Test("register sets outputAutoPaste to false")
    func registerOutputAutoPaste() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.outputAutoPaste) == false)
    }

    @Test("register sets outputClearAfterInsert to false")
    func registerOutputClearAfterInsert() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.outputClearAfterInsert) == false)
    }

    @Test("register sets outputCommandReplacements to true")
    func registerOutputCommandReplacements() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.outputCommandReplacements) == true)
    }

    @Test("register sets outputSmartCapitalization to true")
    func registerOutputSmartCapitalization() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.outputSmartCapitalization) == true)
    }

    @Test("register sets outputTerminalPunctuation to true")
    func registerOutputTerminalPunctuation() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.outputTerminalPunctuation) == true)
    }

    @Test("register sets outputCustomCommands to empty string")
    func registerOutputCustomCommands() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.string(forKey: AppDefaults.Keys.outputCustomCommands) == "")
    }

    @Test("register sets transcriptionReplacements to empty string")
    func registerTranscriptionReplacements() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.string(forKey: AppDefaults.Keys.transcriptionReplacements) == "")
    }

    @Test("register sets transcriptionHistoryLimit to 25")
    func registerTranscriptionHistoryLimit() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.integer(forKey: AppDefaults.Keys.transcriptionHistoryLimit) == 25)
    }

    @Test("register sets appProfiles to empty JSON array")
    func registerAppProfiles() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.string(forKey: AppDefaults.Keys.appProfiles) == "[]")
    }

    @Test("register sets modelSource to bundledTiny")
    func registerModelSource() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.string(forKey: AppDefaults.Keys.modelSource) == ModelSource.bundledTiny.rawValue)
    }

    @Test("register sets modelCustomPath to empty string")
    func registerModelCustomPath() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.string(forKey: AppDefaults.Keys.modelCustomPath) == "")
    }

    @Test("register sets onboardingCompleted to false")
    func registerOnboardingCompleted() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.onboardingCompleted) == false)
    }

    @Test("register sets insertionProbeSampleText")
    func registerInsertionProbeSampleText() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.string(forKey: AppDefaults.Keys.insertionProbeSampleText) == "OpenWhisper insertion test")
    }

    @Test("register sets audioFeedbackEnabled to true")
    func registerAudioFeedbackEnabled() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.audioFeedbackEnabled) == true)
    }

    @Test("register sets launchAtLogin to false")
    func registerLaunchAtLogin() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.launchAtLogin) == false)
    }

    @Test("register sets transcriptionLanguage to auto")
    func registerTranscriptionLanguage() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.string(forKey: AppDefaults.Keys.transcriptionLanguage) == "auto")
    }

    @Test("register sets transcriptionHistory to empty JSON array")
    func registerTranscriptionHistory() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        #expect(d.string(forKey: AppDefaults.Keys.transcriptionHistory) == "[]")
    }

    // MARK: - Idempotency & non-overwrite

    @Test("register is idempotent")
    func registerIdempotent() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        AppDefaults.register(into: d)
        let first = d.string(forKey: AppDefaults.Keys.hotkeyKey)
        AppDefaults.register(into: d)
        let second = d.string(forKey: AppDefaults.Keys.hotkeyKey)
        #expect(first == second)
    }

    @Test("register does not overwrite user-set string values")
    func registerDoesNotOverwriteString() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        d.set("escape", forKey: AppDefaults.Keys.hotkeyKey)
        AppDefaults.register(into: d)
        #expect(d.string(forKey: AppDefaults.Keys.hotkeyKey) == "escape")
    }

    @Test("register does not overwrite user-set bool values")
    func registerDoesNotOverwriteBool() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        d.set(true, forKey: AppDefaults.Keys.outputAutoPaste)
        AppDefaults.register(into: d)
        #expect(d.bool(forKey: AppDefaults.Keys.outputAutoPaste) == true)
    }

    @Test("register does not overwrite user-set int values")
    func registerDoesNotOverwriteInt() {
        let (d, s) = makeDefaults()
        defer { cleanup(s) }
        d.set(50, forKey: AppDefaults.Keys.transcriptionHistoryLimit)
        AppDefaults.register(into: d)
        #expect(d.integer(forKey: AppDefaults.Keys.transcriptionHistoryLimit) == 50)
    }

    // MARK: - register() convenience calls register(into: .standard)

    @Test("register convenience does not crash")
    func registerConvenience() {
        AppDefaults.register()
        // If it didn't crash, it called register(into: .standard) successfully
        #expect(UserDefaults.standard.string(forKey: AppDefaults.Keys.hotkeyKey) != nil)
    }

    // MARK: - All keys are unique

    @Test("All key strings are unique")
    func allKeysUnique() {
        let allKeys = [
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
        let uniqueKeys = Set(allKeys)
        #expect(uniqueKeys.count == allKeys.count, "Duplicate key strings detected")
    }
}
