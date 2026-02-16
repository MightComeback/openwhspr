import Testing
@testable import OpenWhisper

@Suite("SettingsView extracted logic")
struct SettingsViewLogicTests {

    // MARK: - isHighRiskHotkey

    @Test("single character key with no modifiers is high risk")
    func singleCharNoModifiers() {
        #expect(ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "a"))
        #expect(ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "z"))
        #expect(ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "1"))
    }

    @Test("navigation keys with no modifiers are high risk")
    func navKeysHighRisk() {
        for key in ["space", "tab", "return", "delete", "forwarddelete", "escape",
                     "fn", "left", "right", "up", "down", "home", "end", "pageup", "pagedown"] {
            #expect(ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: key), "Expected \(key) to be high risk")
        }
    }

    @Test("any modifier present makes it not high risk")
    func modifierMakesNotHighRisk() {
        #expect(!ViewHelpers.isHighRiskHotkey(requiredModifiers: [.command], key: "a"))
        #expect(!ViewHelpers.isHighRiskHotkey(requiredModifiers: [.control], key: "space"))
        #expect(!ViewHelpers.isHighRiskHotkey(requiredModifiers: [.option, .command], key: "return"))
    }

    @Test("function key names with no modifiers are not high risk")
    func fKeyNotHighRisk() {
        #expect(!ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "f1"))
        #expect(!ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "f12"))
    }

    // MARK: - showsHoldModeAccidentalTriggerWarning

    @Test("hold mode with high risk key warns")
    func holdModeWarns() {
        #expect(ViewHelpers.showsHoldModeAccidentalTriggerWarning(hotkeyModeRaw: HotkeyMode.hold.rawValue, requiredModifiers: [], key: "space"))
    }

    @Test("toggle mode does not warn even with high risk")
    func toggleModeNoWarn() {
        #expect(!ViewHelpers.showsHoldModeAccidentalTriggerWarning(hotkeyModeRaw: HotkeyMode.toggle.rawValue, requiredModifiers: [], key: "space"))
    }

    @Test("hold mode with modifiers does not warn")
    func holdModeWithModifiersNoWarn() {
        #expect(!ViewHelpers.showsHoldModeAccidentalTriggerWarning(hotkeyModeRaw: HotkeyMode.hold.rawValue, requiredModifiers: [.command], key: "space"))
    }

    // MARK: - hotkeyEscapeCancelConflictWarning

    @Test("escape key triggers conflict warning")
    func escapeConflict() {
        let warning = ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "escape")
        #expect(warning != nil)
        #expect(warning!.contains("discard"))
    }

    @Test("non-escape key returns nil")
    func nonEscapeNoConflict() {
        #expect(ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "space") == nil)
        #expect(ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "f6") == nil)
    }

    // MARK: - hotkeySystemConflictWarning

    @Test("Cmd+Space conflicts with Spotlight")
    func cmdSpaceConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "space")
        #expect(w != nil)
        #expect(w!.contains("Spotlight"))
    }

    @Test("Ctrl+Space conflicts with input source")
    func ctrlSpaceConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.control], key: "space")
        #expect(w != nil)
        #expect(w!.contains("input source"))
    }

    @Test("Cmd+Tab conflicts with app switching")
    func cmdTabConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "tab")
        #expect(w != nil)
        #expect(w!.contains("app switching"))
    }

    @Test("Fn alone conflicts with macOS")
    func fnAloneConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [], key: "fn")
        #expect(w != nil)
        #expect(w!.contains("macOS"))
    }

    @Test("Cmd+Q warns about quit")
    func cmdQConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "q")
        #expect(w != nil)
        #expect(w!.contains("quits"))
    }

    @Test("Cmd+Shift+3 warns about screenshots")
    func cmdShift3Conflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "3")
        #expect(w != nil)
        #expect(w!.contains("screenshots"))
    }

    @Test("Cmd+Shift+4 warns about screenshots")
    func cmdShift4Conflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "4")
        #expect(w != nil)
        #expect(w!.contains("screenshots"))
    }

    @Test("Cmd+Shift+5 warns about screenshot panel")
    func cmdShift5Conflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "5")
        #expect(w != nil)
        #expect(w!.contains("screenshot"))
    }

    @Test("Cmd+backtick warns about window cycling")
    func cmdBacktickConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "backtick")
        #expect(w != nil)
        #expect(w!.contains("cycling windows"))
    }

    @Test("Cmd+comma warns about settings")
    func cmdCommaConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "comma")
        #expect(w != nil)
        #expect(w!.contains("settings"))
    }

    @Test("Cmd+Option+Esc warns about Force Quit")
    func cmdOptEscConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .option], key: "escape")
        #expect(w != nil)
        #expect(w!.contains("Force Quit"))
    }

    @Test("Cmd+H warns about hide")
    func cmdHConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "h")
        #expect(w != nil)
        #expect(w!.contains("hides"))
    }

    @Test("common editing shortcuts warn: C, V, X, A, Z")
    func editingShortcutsConflict() {
        for (key, substr) in [("c", "copies"), ("v", "pastes"), ("x", "cuts"), ("a", "selects all"), ("z", "undo")] {
            let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: key)
            #expect(w != nil, "Expected warning for Cmd+\(key)")
            #expect(w!.contains(substr), "Expected '\(substr)' in warning for Cmd+\(key)")
        }
    }

    @Test("Cmd+S warns about save")
    func cmdSConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "s")
        #expect(w != nil)
        #expect(w!.contains("saves"))
    }

    @Test("Cmd+W warns about close")
    func cmdWConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "w")
        #expect(w != nil)
        #expect(w!.contains("closes"))
    }

    @Test("safe combo returns nil")
    func safeComboNoWarning() {
        // Cmd+Shift+D is not a known system combo
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "d") == nil)
    }

    @Test("Ctrl+Cmd+Space warns about emoji picker")
    func ctrlCmdSpaceConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .control], key: "space")
        #expect(w != nil)
        #expect(w!.contains("emoji"))
    }

    @Test("Ctrl+Cmd+F warns about fullscreen")
    func ctrlCmdFConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .control], key: "f")
        #expect(w != nil)
        #expect(w!.contains("full-screen"))
    }

    @Test("Ctrl+Cmd+Q warns about lock")
    func ctrlCmdQConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .control], key: "q")
        #expect(w != nil)
        #expect(w!.contains("locks"))
    }

    @Test("all Cmd+letter shortcuts covered: f, n, t, p, r, o, l, m")
    func cmdLetterShortcuts() {
        let checks: [(String, String)] = [
            ("f", "Find"), ("n", "new"), ("t", "new tab"),
            ("p", "Print"), ("r", "refreshes"), ("o", "opens"),
            ("l", "location"), ("m", "minimizes")
        ]
        for (key, substr) in checks {
            let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: key)
            #expect(w != nil, "Expected warning for Cmd+\(key)")
            #expect(w!.lowercased().contains(substr.lowercased()), "Expected '\(substr)' in warning for Cmd+\(key), got: \(w!)")
        }
    }

    @Test("Cmd+Return warns about send/submit")
    func cmdReturnConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "return")
        #expect(w != nil)
        #expect(w!.contains("sends"))
    }

    @Test("Cmd+period warns about cancel")
    func cmdPeriodConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "period")
        #expect(w != nil)
        #expect(w!.contains("Cancel"))
    }

    @Test("Cmd+section warns about window cycling (ISO)")
    func cmdSectionConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "section")
        #expect(w != nil)
        #expect(w!.contains("ISO"))
    }

    @Test("Cmd+Shift+Tab warns about reverse app switching")
    func cmdShiftTabConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "tab")
        #expect(w != nil)
        #expect(w!.contains("reverse"))
    }

    @Test("Option+Cmd+Space warns about Finder search")
    func optCmdSpaceConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .option], key: "space")
        #expect(w != nil)
        #expect(w!.contains("Finder"))
    }

    @Test("Ctrl+Option+Space warns about input source")
    func ctrlOptSpaceConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.control, .option], key: "space")
        #expect(w != nil)
        #expect(w!.contains("input source"))
    }

    @Test("Ctrl+Option+Cmd+Space warns about app launchers")
    func ctrlOptCmdSpaceConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .option, .control], key: "space")
        #expect(w != nil)
        #expect(w!.contains("app launchers"))
    }

    @Test("Cmd+Shift+Section warns about reverse ISO cycling")
    func cmdShiftSectionConflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "section")
        #expect(w != nil)
        #expect(w!.contains("reverse"))
    }

    @Test("Cmd+Shift+6 warns about screenshot tool")
    func cmdShift6Conflict() {
        let w = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "6")
        #expect(w != nil)
        #expect(w!.contains("screenshot"))
    }

    // MARK: - insertionTestDisabledReason

    @Test("recording blocks insertion test")
    func insertionDisabledRecording() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: true, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true, hasInsertionTarget: true
        )
        #expect(reason.contains("Stop recording"))
    }

    @Test("finalizing blocks insertion test")
    func insertionDisabledFinalizing() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: true,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true, hasInsertionTarget: true
        )
        #expect(reason.contains("finalizing"))
    }

    @Test("already running blocks insertion test")
    func insertionDisabledRunning() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: true, hasInsertionProbeSampleText: true, hasInsertionTarget: true
        )
        #expect(reason.contains("already running"))
    }

    @Test("empty sample text blocks insertion test")
    func insertionDisabledEmptyText() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: false, hasInsertionTarget: true
        )
        #expect(reason.contains("empty"))
    }

    @Test("no target shows destination message")
    func insertionDisabledNoTarget() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true, hasInsertionTarget: false
        )
        #expect(reason.contains("destination"))
    }

    @Test("priority: recording beats finalizing")
    func insertionDisabledPriority() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: true, isFinalizingTranscription: true,
            isRunningInsertionProbe: true, hasInsertionProbeSampleText: false, hasInsertionTarget: false
        )
        #expect(reason.contains("Stop recording"))
    }
}
