import Testing
@testable import OpenWhisper

@Suite("ViewHelpers – Hotkey Warnings")
struct ViewHelpersHotkeyWarningsTests {

    // MARK: - showsHoldModeAccidentalTriggerWarning

    @Test("holdWarning: false in toggle mode")
    func holdWarningFalseInToggle() {
        let result = ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: HotkeyMode.toggle.rawValue,
            requiredModifiers: [],
            key: "space"
        )
        #expect(result == false)
    }

    @Test("holdWarning: true in hold mode with no modifiers and common key")
    func holdWarningTrueNoModifiers() {
        let result = ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: HotkeyMode.hold.rawValue,
            requiredModifiers: [],
            key: "space"
        )
        #expect(result == true)
    }

    @Test("holdWarning: false in hold mode with modifiers")
    func holdWarningFalseWithModifiers() {
        let result = ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: HotkeyMode.hold.rawValue,
            requiredModifiers: [.command],
            key: "space"
        )
        #expect(result == false)
    }

    @Test("holdWarning: true for single character key without modifiers")
    func holdWarningSingleChar() {
        let result = ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: HotkeyMode.hold.rawValue,
            requiredModifiers: [],
            key: "a"
        )
        #expect(result == true)
    }

    @Test("holdWarning: false for function key without modifiers (not high risk)")
    func holdWarningFunctionKey() {
        // F-keys are NOT in the high-risk list, so should be false
        let result = ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: HotkeyMode.hold.rawValue,
            requiredModifiers: [],
            key: "f6"
        )
        #expect(result == false)
    }

    @Test("holdWarning: true for escape without modifiers in hold mode")
    func holdWarningEscape() {
        let result = ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: HotkeyMode.hold.rawValue,
            requiredModifiers: [],
            key: "escape"
        )
        #expect(result == true)
    }

    @Test("holdWarning: true for all navigation keys")
    func holdWarningNavigationKeys() {
        for key in ["left", "right", "up", "down", "home", "end", "pageup", "pagedown"] {
            let result = ViewHelpers.showsHoldModeAccidentalTriggerWarning(
                hotkeyModeRaw: HotkeyMode.hold.rawValue,
                requiredModifiers: [],
                key: key
            )
            #expect(result == true, "Expected true for \(key)")
        }
    }

    @Test("holdWarning: false for invalid mode raw value")
    func holdWarningInvalidMode() {
        let result = ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: "invalid",
            requiredModifiers: [],
            key: "space"
        )
        #expect(result == false)
    }

    // MARK: - hotkeyEscapeCancelConflictWarning

    @Test("escapeConflict: returns warning for escape key")
    func escapeConflictWarning() {
        let result = ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "escape")
        #expect(result != nil)
        #expect(result!.contains("Esc"))
    }

    @Test("escapeConflict: nil for non-escape key")
    func escapeConflictNilForSpace() {
        #expect(ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "space") == nil)
    }

    @Test("escapeConflict: nil for empty key")
    func escapeConflictNilForEmpty() {
        #expect(ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "") == nil)
    }

    @Test("escapeConflict: case sensitive - Escape uppercase returns nil")
    func escapeConflictCaseSensitive() {
        #expect(ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "Escape") == nil)
    }

    // MARK: - hotkeySystemConflictWarning

    @Test("systemConflict: cmd+space warns about Spotlight")
    func systemConflictCmdSpace() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "space"
        )
        #expect(result != nil)
        #expect(result!.contains("Spotlight"))
    }

    @Test("systemConflict: ctrl+space warns about input source")
    func systemConflictCtrlSpace() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.control],
            key: "space"
        )
        #expect(result != nil)
        #expect(result!.contains("input source"))
    }

    @Test("systemConflict: cmd+tab warns about app switching")
    func systemConflictCmdTab() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "tab"
        )
        #expect(result != nil)
        #expect(result!.contains("app switching"))
    }

    @Test("systemConflict: cmd+q warns about quit")
    func systemConflictCmdQ() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "q"
        )
        #expect(result != nil)
        #expect(result!.contains("quits"))
    }

    @Test("systemConflict: cmd+w warns about close")
    func systemConflictCmdW() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "w"
        )
        #expect(result != nil)
        #expect(result!.contains("closes"))
    }

    @Test("systemConflict: cmd+shift+3 warns about screenshot")
    func systemConflictScreenshot3() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command, .shift],
            key: "3"
        )
        #expect(result != nil)
        #expect(result!.contains("screenshot"))
    }

    @Test("systemConflict: cmd+shift+4 warns about screenshot")
    func systemConflictScreenshot4() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command, .shift],
            key: "4"
        )
        #expect(result != nil)
        #expect(result!.contains("screenshot"))
    }

    @Test("systemConflict: cmd+shift+5 warns about screenshot panel")
    func systemConflictScreenshot5() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command, .shift],
            key: "5"
        )
        #expect(result != nil)
        #expect(result!.contains("screenshot"))
    }

    @Test("systemConflict: fn alone warns about macOS reservation")
    func systemConflictFnAlone() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [],
            key: "fn"
        )
        #expect(result != nil)
        #expect(result!.contains("Fn"))
    }

    @Test("systemConflict: cmd+comma warns about preferences")
    func systemConflictCmdComma() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "comma"
        )
        #expect(result != nil)
        #expect(result!.contains("settings") || result!.contains("preferences"))
    }

    @Test("systemConflict: cmd+option+escape warns about Force Quit")
    func systemConflictForceQuit() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command, .option],
            key: "escape"
        )
        #expect(result != nil)
        #expect(result!.contains("Force Quit"))
    }

    @Test("systemConflict: cmd+ctrl+q warns about lock")
    func systemConflictLock() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command, .control],
            key: "q"
        )
        #expect(result != nil)
        #expect(result!.contains("lock"))
    }

    @Test("systemConflict: cmd+backtick warns about window cycling")
    func systemConflictBacktick() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "backtick"
        )
        #expect(result != nil)
        #expect(result!.contains("cycling windows"))
    }

    @Test("systemConflict: nil for safe combo like cmd+shift+space")
    func systemConflictNilForSafeCombo() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command, .shift],
            key: "space"
        )
        #expect(result == nil)
    }

    @Test("systemConflict: nil for f6 with modifiers")
    func systemConflictNilForF6() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command, .shift],
            key: "f6"
        )
        #expect(result == nil)
    }

    @Test("systemConflict: cmd+c warns about copy")
    func systemConflictCmdC() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "c"
        )
        #expect(result != nil)
        #expect(result!.contains("copies"))
    }

    @Test("systemConflict: cmd+v warns about paste")
    func systemConflictCmdV() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "v"
        )
        #expect(result != nil)
        #expect(result!.contains("pastes"))
    }

    @Test("systemConflict: cmd+x warns about cut")
    func systemConflictCmdX() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "x"
        )
        #expect(result != nil)
        #expect(result!.contains("cuts"))
    }

    @Test("systemConflict: cmd+z warns about undo")
    func systemConflictCmdZ() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "z"
        )
        #expect(result != nil)
        #expect(result!.contains("undo"))
    }

    @Test("systemConflict: cmd+a warns about select all")
    func systemConflictCmdA() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "a"
        )
        #expect(result != nil)
        #expect(result!.contains("selects all"))
    }

    @Test("systemConflict: cmd+m warns about minimize")
    func systemConflictCmdM() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "m"
        )
        #expect(result != nil)
        #expect(result!.contains("minimizes"))
    }

    @Test("systemConflict: cmd+h warns about hide")
    func systemConflictCmdH() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "h"
        )
        #expect(result != nil)
        #expect(result!.contains("hides"))
    }

    @Test("systemConflict: cmd+s warns about save")
    func systemConflictCmdS() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "s"
        )
        #expect(result != nil)
        #expect(result!.contains("saves"))
    }

    @Test("systemConflict: cmd+f warns about find")
    func systemConflictCmdF() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "f"
        )
        #expect(result != nil)
        #expect(result!.contains("Find"))
    }

    @Test("systemConflict: cmd+n warns about new")
    func systemConflictCmdN() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "n"
        )
        #expect(result != nil)
        #expect(result!.contains("new"))
    }

    @Test("systemConflict: cmd+t warns about new tab")
    func systemConflictCmdT() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "t"
        )
        #expect(result != nil)
        #expect(result!.contains("tab"))
    }

    @Test("systemConflict: cmd+p warns about print")
    func systemConflictCmdP() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "p"
        )
        #expect(result != nil)
        #expect(result!.contains("Print"))
    }

    @Test("systemConflict: cmd+r warns about reload")
    func systemConflictCmdR() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "r"
        )
        #expect(result != nil)
        #expect(result!.contains("refresh") || result!.contains("reload"))
    }

    @Test("systemConflict: cmd+o warns about open")
    func systemConflictCmdO() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "o"
        )
        #expect(result != nil)
        #expect(result!.contains("open"))
    }

    @Test("systemConflict: cmd+l warns about location/search")
    func systemConflictCmdL() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "l"
        )
        #expect(result != nil)
        #expect(result!.contains("location") || result!.contains("search"))
    }

    @Test("systemConflict: cmd+return warns about send/submit")
    func systemConflictCmdReturn() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "return"
        )
        #expect(result != nil)
        #expect(result!.contains("send") || result!.contains("submit"))
    }

    @Test("systemConflict: cmd+ctrl+f warns about fullscreen")
    func systemConflictFullscreen() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command, .control],
            key: "f"
        )
        #expect(result != nil)
        #expect(result!.contains("full-screen"))
    }

    @Test("systemConflict: cmd+shift+tab warns about reverse switching")
    func systemConflictReverseTab() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command, .shift],
            key: "tab"
        )
        #expect(result != nil)
        #expect(result!.contains("reverse"))
    }

    @Test("systemConflict: ctrl+option+space warns about input source")
    func systemConflictCtrlOptSpace() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.control, .option],
            key: "space"
        )
        #expect(result != nil)
        #expect(result!.contains("input source"))
    }

    @Test("systemConflict: cmd+ctrl+space warns about emoji picker")
    func systemConflictEmojiPicker() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command, .control],
            key: "space"
        )
        #expect(result != nil)
        #expect(result!.contains("emoji"))
    }

    @Test("systemConflict: cmd+option+space warns about Finder search")
    func systemConflictFinderSearch() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command, .option],
            key: "space"
        )
        #expect(result != nil)
        #expect(result!.contains("Finder"))
    }

    @Test("systemConflict: cmd+section warns about window cycling ISO")
    func systemConflictSection() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "section"
        )
        #expect(result != nil)
        #expect(result!.contains("windows"))
    }

    @Test("systemConflict: cmd+period warns about cancel/stop")
    func systemConflictCmdPeriod() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "period"
        )
        #expect(result != nil)
        #expect(result!.contains("Cancel") || result!.contains("Stop"))
    }

    @Test("systemConflict: cmd+shift+6 warns about screenshot tool")
    func systemConflictScreenshot6() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command, .shift],
            key: "6"
        )
        #expect(result != nil)
        #expect(result!.contains("screenshot"))
    }

    @Test("systemConflict: cmd+opt+ctrl+space warns about launchers")
    func systemConflictTripleModSpace() {
        let result = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command, .option, .control],
            key: "space"
        )
        #expect(result != nil)
        #expect(result!.contains("launcher") || result!.contains("snippet"))
    }
}
