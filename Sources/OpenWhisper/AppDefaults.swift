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

        static let transcriptionReplacements = "transcription.replacements"
        static let transcriptionHistoryLimit = "transcription.historyLimit"

        static let modelSource = "model.source"
        static let modelCustomPath = "model.customPath"

        static let onboardingCompleted = "onboarding.completed"
    }

    static func register() {
        let defaults: [String: Any] = [
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

            Keys.transcriptionReplacements: "",
            Keys.transcriptionHistoryLimit: 25,

            Keys.modelSource: ModelSource.bundledTiny.rawValue,
            Keys.modelCustomPath: "",

            Keys.onboardingCompleted: false
        ]
        UserDefaults.standard.register(defaults: defaults)
    }
}
