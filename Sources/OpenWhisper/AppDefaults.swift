import Foundation

enum AppDefaults {
    enum Keys {
        static let hotkeyMode = "hotkey.mode"
        static let hotkeyKey = "hotkey.key"

        static let hotkeyRequiredCommand = "hotkey.required.command"
        static let hotkeyRequiredShift = "hotkey.required.shift"
        static let hotkeyRequiredOption = "hotkey.required.option"
        static let hotkeyRequiredControl = "hotkey.required.control"
        static let hotkeyRequiredCapsLock = "hotkey.required.capslock"

        static let hotkeyForbiddenCommand = "hotkey.forbidden.command"
        static let hotkeyForbiddenShift = "hotkey.forbidden.shift"
        static let hotkeyForbiddenOption = "hotkey.forbidden.option"
        static let hotkeyForbiddenControl = "hotkey.forbidden.control"
        static let hotkeyForbiddenCapsLock = "hotkey.forbidden.capslock"

        static let outputAutoCopy = "output.autoCopy"
        static let outputAutoPaste = "output.autoPaste"
        static let outputClearAfterInsert = "output.clearAfterInsert"
        static let outputCommandReplacements = "output.commandReplacements"
        static let outputSmartCapitalization = "output.smartCapitalization"
        static let outputTerminalPunctuation = "output.terminalPunctuation"
        static let outputCustomCommands = "output.customCommands"

        static let transcriptionReplacements = "transcription.replacements"
        static let transcriptionHistoryLimit = "transcription.historyLimit"
        static let appProfiles = "profiles.appOutput"

        static let modelSource = "model.source"
        static let modelCustomPath = "model.customPath"

        static let onboardingCompleted = "onboarding.completed"
        static let insertionProbeSampleText = "insertion.probeSampleText"
        static let audioFeedbackEnabled = "audio.feedbackEnabled"
    }

    static func register() {
        register(into: .standard)
    }

    static func register(into defaults: UserDefaults) {
        let values: [String: Any] = [
            Keys.hotkeyMode: HotkeyMode.toggle.rawValue,
            Keys.hotkeyKey: "space",

            Keys.hotkeyRequiredCommand: true,
            Keys.hotkeyRequiredShift: true,
            Keys.hotkeyRequiredOption: false,
            Keys.hotkeyRequiredControl: false,
            Keys.hotkeyRequiredCapsLock: false,

            Keys.hotkeyForbiddenCommand: false,
            Keys.hotkeyForbiddenShift: false,
            Keys.hotkeyForbiddenOption: true,
            Keys.hotkeyForbiddenControl: true,
            Keys.hotkeyForbiddenCapsLock: false,

            Keys.outputAutoCopy: true,
            Keys.outputAutoPaste: false,
            Keys.outputClearAfterInsert: false,
            Keys.outputCommandReplacements: true,
            Keys.outputSmartCapitalization: true,
            Keys.outputTerminalPunctuation: true,
            Keys.outputCustomCommands: "",

            Keys.transcriptionReplacements: "",
            Keys.transcriptionHistoryLimit: 25,
            Keys.appProfiles: "[]",

            Keys.modelSource: ModelSource.bundledTiny.rawValue,
            Keys.modelCustomPath: "",

            Keys.onboardingCompleted: false,
            Keys.insertionProbeSampleText: "OpenWhisper insertion test",
            Keys.audioFeedbackEnabled: true
        ]
        defaults.register(defaults: values)
    }
}
