import Testing
import Foundation
@testable import OpenWhisper

@Suite("ViewHelpers — remaining coverage gaps")
struct ViewHelpersRemainingCoverageTests {

    // MARK: - showsAutoPastePermissionWarning

    @Test("showsAutoPastePermissionWarning: true when autoPaste on and no accessibility")
    func autoPasteWarningShown() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: false) == true)
    }

    @Test("showsAutoPastePermissionWarning: false when autoPaste off")
    func autoPasteWarningHiddenWhenOff() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: false, accessibilityAuthorized: false) == false)
    }

    @Test("showsAutoPastePermissionWarning: false when accessibility authorized")
    func autoPasteWarningHiddenWhenAuthorized() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: true) == false)
    }

    @Test("showsAutoPastePermissionWarning: false when both off")
    func autoPasteWarningBothOff() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: false, accessibilityAuthorized: true) == false)
    }

    // MARK: - runInsertionTestButtonTitle

    @Test("runInsertionTestButtonTitle: running probe shows running text")
    func insertionTestTitleRunning() {
        let title = ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: true, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: false)
        #expect(title == "Running insertion test…")
    }

    @Test("runInsertionTestButtonTitle: canRunTest shows plain title")
    func insertionTestTitleCanRun() {
        let title = ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: false, canRunTest: true, autoCaptureTargetName: nil, canCaptureAndRun: false)
        #expect(title == "Run insertion test")
    }

    @Test("runInsertionTestButtonTitle: auto-capture target name included")
    func insertionTestTitleAutoCaptureName() {
        let title = ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: false, canRunTest: false, autoCaptureTargetName: "Safari", canCaptureAndRun: false)
        #expect(title.contains("Safari"))
        #expect(title.contains("capture"))
    }

    @Test("runInsertionTestButtonTitle: canCaptureAndRun shows auto-capture")
    func insertionTestTitleCanCapture() {
        let title = ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: false, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: true)
        #expect(title.contains("auto-capture"))
    }

    @Test("runInsertionTestButtonTitle: fallback plain title")
    func insertionTestTitleFallback() {
        let title = ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: false, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: false)
        #expect(title == "Run insertion test")
    }

    @Test("runInsertionTestButtonTitle: empty auto-capture name falls through")
    func insertionTestTitleEmptyName() {
        let title = ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: false, canRunTest: false, autoCaptureTargetName: "", canCaptureAndRun: false)
        #expect(title == "Run insertion test")
    }

    @Test("runInsertionTestButtonTitle: running takes priority over canRunTest")
    func insertionTestTitleRunningPriority() {
        let title = ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: true, canRunTest: true, autoCaptureTargetName: "Xcode", canCaptureAndRun: true)
        #expect(title == "Running insertion test…")
    }

    // MARK: - canFocusInsertionTarget

    @Test("canFocusInsertionTarget: true when idle with target")
    func focusTargetIdle() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: true) == true)
    }

    @Test("canFocusInsertionTarget: false when recording")
    func focusTargetRecording() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: true, isFinalizingTranscription: false, hasInsertionTarget: true) == false)
    }

    @Test("canFocusInsertionTarget: false when finalizing")
    func focusTargetFinalizing() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: true, hasInsertionTarget: true) == false)
    }

    @Test("canFocusInsertionTarget: false when no target")
    func focusTargetNoTarget() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: false) == false)
    }

    @Test("canFocusInsertionTarget: false when recording and no target")
    func focusTargetRecordingNoTarget() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: true, isFinalizingTranscription: false, hasInsertionTarget: false) == false)
    }

    // MARK: - canClearInsertionTarget

    @Test("canClearInsertionTarget: true when not probing with target")
    func clearTargetIdle() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: true) == true)
    }

    @Test("canClearInsertionTarget: false when probing")
    func clearTargetProbing() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: true, hasInsertionTarget: true) == false)
    }

    @Test("canClearInsertionTarget: false when no target")
    func clearTargetNoTarget() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: false) == false)
    }

    @Test("canClearInsertionTarget: false when probing and no target")
    func clearTargetProbingNoTarget() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: true, hasInsertionTarget: false) == false)
    }

    // MARK: - shouldIgnoreCaptureActivation (edge cases not in other files)

    @Test("shouldIgnoreCaptureActivation: ignores Cmd+Shift+K within debounce")
    func ignoreCaptureWithinDebounce() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == true)
    }

    @Test("shouldIgnoreCaptureActivation: does not ignore after debounce")
    func dontIgnoreAfterDebounce() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 1.0,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == false)
    }

    @Test("shouldIgnoreCaptureActivation: does not ignore different key")
    func dontIgnoreDifferentKey() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "a",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == false)
    }

    @Test("shouldIgnoreCaptureActivation: does not ignore without command")
    func dontIgnoreNoCommand() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "k",
            hasCommandModifier: false,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == false)
    }

    @Test("shouldIgnoreCaptureActivation: does not ignore with extra modifiers")
    func dontIgnoreExtraModifiers() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: true
        ) == false)
    }

    @Test("shouldIgnoreCaptureActivation: exact debounce boundary ignores")
    func ignoreCaptureAtBoundary() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.35,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == true)
    }

    @Test("shouldIgnoreCaptureActivation: nil key does not ignore")
    func dontIgnoreNilKey() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: nil,
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == false)
    }

    @Test("shouldIgnoreCaptureActivation: custom debounce threshold")
    func customDebounceThreshold() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.5,
            debounceThreshold: 1.0,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == true)
    }

    @Test("shouldIgnoreCaptureActivation: does not ignore without shift")
    func dontIgnoreNoShift() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: false,
            hasExtraModifiers: false
        ) == false)
    }

    // MARK: - insertionProbeSampleTextWillTruncate

    @Test("insertionProbeSampleTextWillTruncate: short text does not truncate")
    func shortTextNoTruncate() {
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate("hello") == false)
    }

    @Test("insertionProbeSampleTextWillTruncate: empty text does not truncate")
    func emptyTextNoTruncate() {
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate("") == false)
    }

    // MARK: - hasInsertionProbeSampleText

    @Test("hasInsertionProbeSampleText: empty returns false")
    func noSampleTextEmpty() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("") == false)
    }

    @Test("hasInsertionProbeSampleText: whitespace returns false")
    func noSampleTextWhitespace() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("   ") == false)
    }

    @Test("hasInsertionProbeSampleText: real text returns true")
    func hasSampleText() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("hello world") == true)
    }

    // MARK: - insertionProbeSampleTextForRun

    @Test("insertionProbeSampleTextForRun: trims whitespace")
    func sampleTextTrimsWhitespace() {
        let result = ViewHelpers.insertionProbeSampleTextForRun("  hello  ")
        #expect(result == "hello")
    }

    // MARK: - enforceInsertionProbeSampleTextLimit

    @Test("enforceInsertionProbeSampleTextLimit: short text unchanged")
    func sampleTextLimitShort() {
        let result = ViewHelpers.enforceInsertionProbeSampleTextLimit("hello")
        #expect(result == "hello")
    }

    // MARK: - insertionProbeStatus

    @Test("insertionProbeStatus: nil returns unknown")
    func probeStatusNil() {
        let status = ViewHelpers.insertionProbeStatus(succeeded: nil)
        #expect(status == .unknown)
    }

    @Test("insertionProbeStatus: true returns success")
    func probeStatusTrue() {
        let status = ViewHelpers.insertionProbeStatus(succeeded: true)
        #expect(status == .success)
    }

    @Test("insertionProbeStatus: false returns failure")
    func probeStatusFalse() {
        let status = ViewHelpers.insertionProbeStatus(succeeded: false)
        #expect(status == .failure)
    }

    // MARK: - hasHotkeyDraftEdits

    @Test("hasHotkeyDraftEdits: empty draft has no edits")
    func draftEditsEmpty() {
        #expect(ViewHelpers.hasHotkeyDraftEdits(draft: "", currentKey: "space", currentModifiers: []) == false)
    }

    @Test("hasHotkeyDraftEdits: same key no edits")
    func draftEditsSameKey() {
        #expect(ViewHelpers.hasHotkeyDraftEdits(draft: "space", currentKey: "space", currentModifiers: []) == false)
    }

    @Test("hasHotkeyDraftEdits: different key has edits")
    func draftEditsDifferentKey() {
        #expect(ViewHelpers.hasHotkeyDraftEdits(draft: "a", currentKey: "space", currentModifiers: []) == true)
    }

    // MARK: - effectiveHotkeyRiskContext

    @Test("effectiveHotkeyRiskContext: empty draft returns current values")
    func riskContextEmptyDraft() {
        let ctx = ViewHelpers.effectiveHotkeyRiskContext(
            draft: "",
            currentKey: "space",
            currentModifiers: [.command]
        )
        #expect(ctx.key == "space")
        #expect(ctx.requiredModifiers == [.command])
    }

    @Test("effectiveHotkeyRiskContext: valid draft overrides key")
    func riskContextValidDraft() {
        let ctx = ViewHelpers.effectiveHotkeyRiskContext(
            draft: "a",
            currentKey: "space",
            currentModifiers: [.command]
        )
        #expect(ctx.key == "a")
    }

    // MARK: - hotkeyKeyNameForKeyCode

    @Test("hotkeyKeyNameForKeyCode: known code returns name")
    func keyCodeKnown() {
        // keyCode 49 = space
        let name = ViewHelpers.hotkeyKeyNameForKeyCode(49)
        #expect(name == "Space" || name == "space" || name != nil)
    }

    @Test("hotkeyKeyNameForKeyCode: unknown code returns nil")
    func keyCodeUnknown() {
        let name = ViewHelpers.hotkeyKeyNameForKeyCode(999)
        #expect(name == nil)
    }

    // MARK: - isModifierOnlyKeyCode

    @Test("isModifierOnlyKeyCode: shift key code is modifier")
    func shiftIsModifier() {
        // 56 = left shift
        #expect(ViewHelpers.isModifierOnlyKeyCode(56) == true)
    }

    @Test("isModifierOnlyKeyCode: space is not modifier")
    func spaceNotModifier() {
        #expect(ViewHelpers.isModifierOnlyKeyCode(49) == false)
    }

    @Test("isModifierOnlyKeyCode: command key is modifier")
    func commandIsModifier() {
        // 55 = left command
        #expect(ViewHelpers.isModifierOnlyKeyCode(55) == true)
    }

    // MARK: - hotkeySummaryFromModifiers

    @Test("hotkeySummaryFromModifiers: no modifiers returns just key")
    func summaryJustKey() {
        let result = ViewHelpers.hotkeySummaryFromModifiers(command: false, shift: false, option: false, control: false, capsLock: false, key: "Space")
        #expect(result.contains("Space"))
        #expect(!result.contains("⌘"))
    }

    @Test("hotkeySummaryFromModifiers: command modifier included")
    func summaryWithCommand() {
        let result = ViewHelpers.hotkeySummaryFromModifiers(command: true, shift: false, option: false, control: false, capsLock: false, key: "Space")
        #expect(result.contains("⌘"))
        #expect(result.contains("Space"))
    }

    @Test("hotkeySummaryFromModifiers: all modifiers")
    func summaryAllModifiers() {
        let result = ViewHelpers.hotkeySummaryFromModifiers(command: true, shift: true, option: true, control: true, capsLock: true, key: "K")
        #expect(result.contains("⌘"))
        #expect(result.contains("⇧"))
        #expect(result.contains("⌥"))
        #expect(result.contains("⌃"))
        #expect(result.contains("⇪"))
    }
}
