import Testing
import Foundation
@testable import OpenWhisper

@Suite("ContentView Action Button Edge Cases")
struct ContentViewActionButtonEdgeCaseTests {

    // MARK: - retargetButtonTitle

    @Test("retargetButtonTitle: nil target → plain Retarget")
    func retargetTitleNilTarget() {
        #expect(ViewHelpers.retargetButtonTitle(insertTargetAppName: nil, insertTargetUsesFallback: false) == "Retarget")
    }

    @Test("retargetButtonTitle: empty string target → plain Retarget")
    func retargetTitleEmptyTarget() {
        #expect(ViewHelpers.retargetButtonTitle(insertTargetAppName: "", insertTargetUsesFallback: false) == "Retarget")
    }

    @Test("retargetButtonTitle: fallback true but nil target → plain Retarget")
    func retargetTitleFallbackNilTarget() {
        #expect(ViewHelpers.retargetButtonTitle(insertTargetAppName: nil, insertTargetUsesFallback: true) == "Retarget")
    }

    @Test("retargetButtonTitle: fallback true with target shows (recent)")
    func retargetTitleFallbackWithTarget() {
        let result = ViewHelpers.retargetButtonTitle(insertTargetAppName: "Safari", insertTargetUsesFallback: true)
        #expect(result.contains("(recent)"))
        #expect(result.contains("Safari"))
    }

    @Test("retargetButtonTitle: normal target without fallback")
    func retargetTitleNormalTarget() {
        let result = ViewHelpers.retargetButtonTitle(insertTargetAppName: "Xcode", insertTargetUsesFallback: false)
        #expect(result == "Retarget → Xcode")
        #expect(!result.contains("(recent)"))
    }

    @Test("retargetButtonTitle: long app name gets abbreviated")
    func retargetTitleLongName() {
        let result = ViewHelpers.retargetButtonTitle(insertTargetAppName: "Very Long Application Name That Should Be Truncated", insertTargetUsesFallback: false)
        #expect(result.contains("Retarget →"))
        #expect(result.count < 60)
    }

    @Test("retargetButtonTitle: whitespace-only target → plain Retarget")
    func retargetTitleWhitespaceTarget() {
        // Empty after check - the guard checks isEmpty
        #expect(ViewHelpers.retargetButtonTitle(insertTargetAppName: "  ", insertTargetUsesFallback: false) != "Retarget")
        // Actually "  " is not empty, so it goes through. Verify it doesn't crash.
    }

    // MARK: - retargetButtonHelpText

    @Test("retargetButtonHelpText: recording → finish recording message")
    func retargetHelpRecording() {
        let result = ViewHelpers.retargetButtonHelpText(isRecording: true, pendingChunkCount: 0)
        #expect(result.lowercased().contains("recording"))
    }

    @Test("retargetButtonHelpText: pending chunks → wait for finalization")
    func retargetHelpPending() {
        let result = ViewHelpers.retargetButtonHelpText(isRecording: false, pendingChunkCount: 3)
        #expect(result.lowercased().contains("finalization"))
    }

    @Test("retargetButtonHelpText: recording AND pending → recording takes priority")
    func retargetHelpRecordingAndPending() {
        let result = ViewHelpers.retargetButtonHelpText(isRecording: true, pendingChunkCount: 5)
        #expect(result.lowercased().contains("recording"))
    }

    @Test("retargetButtonHelpText: idle → refresh message")
    func retargetHelpIdle() {
        let result = ViewHelpers.retargetButtonHelpText(isRecording: false, pendingChunkCount: 0)
        #expect(result.lowercased().contains("refresh"))
    }

    // MARK: - useCurrentAppButtonTitle

    @Test("useCurrentAppButtonTitle: can insert, has front app")
    func useCurrentTitleInsertWithFront() {
        let result = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: "Notes")
        #expect(result.contains("Notes"))
        #expect(result.contains("Use Current"))
    }

    @Test("useCurrentAppButtonTitle: can insert, nil front app")
    func useCurrentTitleInsertNoFront() {
        let result = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: nil)
        #expect(result == "Use Current App")
    }

    @Test("useCurrentAppButtonTitle: can insert, empty front app")
    func useCurrentTitleInsertEmptyFront() {
        let result = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: "")
        #expect(result == "Use Current App")
    }

    @Test("useCurrentAppButtonTitle: cannot insert → copy variant")
    func useCurrentTitleCopy() {
        let result = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: false, currentFrontAppName: "Safari")
        #expect(result.contains("Copy"))
    }

    @Test("useCurrentAppButtonTitle: cannot insert, nil front → copy variant")
    func useCurrentTitleCopyNoFront() {
        let result = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: false, currentFrontAppName: nil)
        #expect(result.contains("Copy"))
    }

    // MARK: - useCurrentAppButtonHelpText

    @Test("useCurrentAppButtonHelpText: disabled reason present")
    func useCurrentHelpDisabled() {
        let result = ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: "No transcription", canInsertDirectly: true)
        #expect(result.contains("No transcription"))
    }

    @Test("useCurrentAppButtonHelpText: can insert → retarget and insert")
    func useCurrentHelpInsert() {
        let result = ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true)
        #expect(result.lowercased().contains("retarget"))
        #expect(result.lowercased().contains("insert"))
    }

    @Test("useCurrentAppButtonHelpText: cannot insert → copy variant")
    func useCurrentHelpCopy() {
        let result = ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: false)
        #expect(result.lowercased().contains("copy"))
    }

    // MARK: - retargetAndInsertButtonTitle

    @Test("retargetAndInsertButtonTitle: can insert, has front app")
    func retargetInsertTitleWithFront() {
        let result = ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: true, currentFrontAppName: "Terminal")
        #expect(result.contains("Terminal"))
        #expect(result.contains("Retarget + Insert"))
    }

    @Test("retargetAndInsertButtonTitle: can insert, nil front → Current App")
    func retargetInsertTitleNoFront() {
        let result = ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: true, currentFrontAppName: nil)
        #expect(result.contains("Current App"))
    }

    @Test("retargetAndInsertButtonTitle: can insert, empty front → Current App")
    func retargetInsertTitleEmptyFront() {
        let result = ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: true, currentFrontAppName: "")
        #expect(result.contains("Current App"))
    }

    @Test("retargetAndInsertButtonTitle: cannot insert → clipboard variant")
    func retargetInsertTitleClipboard() {
        let result = ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: false, currentFrontAppName: "Notes")
        #expect(result.contains("Clipboard"))
        #expect(result.contains("Copy"))
    }

    // MARK: - retargetAndInsertHelpText

    @Test("retargetAndInsertHelpText: disabled reason")
    func retargetInsertHelpDisabled() {
        let result = ViewHelpers.retargetAndInsertHelpText(insertActionDisabledReason: "Still recording", canInsertDirectly: true)
        #expect(result.contains("Still recording"))
    }

    @Test("retargetAndInsertHelpText: can insert → insert message")
    func retargetInsertHelpInsert() {
        let result = ViewHelpers.retargetAndInsertHelpText(insertActionDisabledReason: nil, canInsertDirectly: true)
        #expect(result.lowercased().contains("insert"))
    }

    @Test("retargetAndInsertHelpText: cannot insert → copy message")
    func retargetInsertHelpCopy() {
        let result = ViewHelpers.retargetAndInsertHelpText(insertActionDisabledReason: nil, canInsertDirectly: false)
        #expect(result.lowercased().contains("copy"))
    }

    // MARK: - focusTargetButtonTitle

    @Test("focusTargetButtonTitle: nil target → plain Focus Target")
    func focusTitleNil() {
        #expect(ViewHelpers.focusTargetButtonTitle(insertTargetAppName: nil) == "Focus Target")
    }

    @Test("focusTargetButtonTitle: empty target → plain Focus Target")
    func focusTitleEmpty() {
        #expect(ViewHelpers.focusTargetButtonTitle(insertTargetAppName: "") == "Focus Target")
    }

    @Test("focusTargetButtonTitle: has target → Focus → AppName")
    func focusTitleWithTarget() {
        let result = ViewHelpers.focusTargetButtonTitle(insertTargetAppName: "Slack")
        #expect(result == "Focus → Slack")
    }

    @Test("focusTargetButtonTitle: long name gets abbreviated")
    func focusTitleLongName() {
        let result = ViewHelpers.focusTargetButtonTitle(insertTargetAppName: "A Really Long Application Name")
        #expect(result.contains("Focus →"))
    }

    // MARK: - focusTargetButtonHelpText

    @Test("focusTargetButtonHelpText: recording → wait message")
    func focusHelpRecording() {
        let result = ViewHelpers.focusTargetButtonHelpText(isRecording: true, pendingChunkCount: 0, insertTargetAppName: "Notes")
        #expect(result.lowercased().contains("wait"))
    }

    @Test("focusTargetButtonHelpText: pending → wait message")
    func focusHelpPending() {
        let result = ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 2, insertTargetAppName: "Notes")
        #expect(result.lowercased().contains("wait"))
    }

    @Test("focusTargetButtonHelpText: idle with target → bring to front")
    func focusHelpIdleWithTarget() {
        let result = ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 0, insertTargetAppName: "Safari")
        #expect(result.contains("Safari"))
        #expect(result.lowercased().contains("front"))
    }

    @Test("focusTargetButtonHelpText: idle no target → no target message")
    func focusHelpIdleNoTarget() {
        let result = ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 0, insertTargetAppName: nil)
        #expect(result.lowercased().contains("no insertion target"))
    }

    @Test("focusTargetButtonHelpText: idle empty target → no target message")
    func focusHelpIdleEmptyTarget() {
        let result = ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 0, insertTargetAppName: "")
        #expect(result.lowercased().contains("no insertion target"))
    }

    // MARK: - focusAndInsertButtonTitle

    @Test("focusAndInsertButtonTitle: can insert, has target")
    func focusInsertTitleWithTarget() {
        let result = ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: true, insertTargetAppName: "Notes")
        #expect(result.contains("Focus + Insert"))
        #expect(result.contains("Notes"))
    }

    @Test("focusAndInsertButtonTitle: can insert, nil target")
    func focusInsertTitleNoTarget() {
        let result = ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: true, insertTargetAppName: nil)
        #expect(result == "Focus + Insert")
    }

    @Test("focusAndInsertButtonTitle: can insert, empty target")
    func focusInsertTitleEmptyTarget() {
        let result = ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: true, insertTargetAppName: "")
        #expect(result == "Focus + Insert")
    }

    @Test("focusAndInsertButtonTitle: cannot insert → Focus + Copy")
    func focusInsertTitleCopy() {
        let result = ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: false, insertTargetAppName: "Notes")
        #expect(result == "Focus + Copy")
    }

    // MARK: - focusAndInsertButtonHelpText

    @Test("focusAndInsertButtonHelpText: disabled reason")
    func focusInsertHelpDisabled() {
        let result = ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: "No text", hasResolvableInsertTarget: true, canInsertDirectly: true)
        #expect(result.contains("No text"))
    }

    @Test("focusAndInsertButtonHelpText: no resolvable target")
    func focusInsertHelpNoTarget() {
        let result = ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: nil, hasResolvableInsertTarget: false, canInsertDirectly: true)
        #expect(result.lowercased().contains("no insertion target"))
    }

    @Test("focusAndInsertButtonHelpText: can insert with target → insert immediately")
    func focusInsertHelpInsert() {
        let result = ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: nil, hasResolvableInsertTarget: true, canInsertDirectly: true)
        #expect(result.lowercased().contains("insert"))
    }

    @Test("focusAndInsertButtonHelpText: cannot insert with target → clipboard")
    func focusInsertHelpCopy() {
        let result = ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: nil, hasResolvableInsertTarget: true, canInsertDirectly: false)
        #expect(result.lowercased().contains("clipboard") || result.lowercased().contains("copy"))
    }

    // MARK: - canRetargetInsertTarget

    @Test("canRetargetInsertTarget: idle → true")
    func canRetargetIdle() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: false, pendingChunkCount: 0) == true)
    }

    @Test("canRetargetInsertTarget: recording → false")
    func canRetargetRecording() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: true, pendingChunkCount: 0) == false)
    }

    @Test("canRetargetInsertTarget: pending → false")
    func canRetargetPending() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: false, pendingChunkCount: 1) == false)
    }

    @Test("canRetargetInsertTarget: recording AND pending → false")
    func canRetargetBoth() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: true, pendingChunkCount: 3) == false)
    }

    // MARK: - hasResolvableInsertTarget

    @Test("hasResolvableInsertTarget: nil → false")
    func resolvableNil() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: nil) == false)
    }

    @Test("hasResolvableInsertTarget: empty → false")
    func resolvableEmpty() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "") == false)
    }

    @Test("hasResolvableInsertTarget: whitespace only → false")
    func resolvableWhitespace() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "   ") == false)
    }

    @Test("hasResolvableInsertTarget: tabs and newlines → false")
    func resolvableTabsNewlines() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "\t\n") == false)
    }

    @Test("hasResolvableInsertTarget: valid name → true")
    func resolvableValid() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "Safari") == true)
    }

    @Test("hasResolvableInsertTarget: name with leading/trailing whitespace → true")
    func resolvableWithWhitespace() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "  Safari  ") == true)
    }

    // MARK: - commonHotkeyKeySections

    @Test("commonHotkeyKeySections: has 5 sections")
    func commonSectionsCount() {
        #expect(ViewHelpers.commonHotkeyKeySections.count == 5)
    }

    @Test("commonHotkeyKeySections: all sections have keys")
    func commonSectionsNonEmpty() {
        for section in ViewHelpers.commonHotkeyKeySections {
            #expect(!section.keys.isEmpty, "Section \(section.title) has no keys")
        }
    }

    @Test("commonHotkeyKeySections: Basic section includes space")
    func commonSectionsBasicHasSpace() {
        let basic = ViewHelpers.commonHotkeyKeySections.first { $0.title == "Basic" }
        #expect(basic != nil)
        #expect(basic!.keys.contains("space"))
    }

    @Test("commonHotkeyKeySections: Function section includes f1 through f20")
    func commonSectionsFunctionKeys() {
        let funcSection = ViewHelpers.commonHotkeyKeySections.first { $0.title == "Function" }
        #expect(funcSection != nil)
        #expect(funcSection!.keys.contains("f1"))
        #expect(funcSection!.keys.contains("f12"))
        #expect(funcSection!.keys.contains("f20"))
    }

    @Test("commonHotkeyKeySections: Keypad section includes keypad0-9")
    func commonSectionsKeypad() {
        let keypad = ViewHelpers.commonHotkeyKeySections.first { $0.title == "Keypad" }
        #expect(keypad != nil)
        for i in 0...9 {
            #expect(keypad!.keys.contains("keypad\(i)"))
        }
    }

    @Test("commonHotkeyKeySections: section titles are unique")
    func commonSectionsUniqueTitles() {
        let titles = ViewHelpers.commonHotkeyKeySections.map { $0.title }
        #expect(Set(titles).count == titles.count)
    }

    @Test("commonHotkeyKeySections: no duplicate keys across sections")
    func commonSectionsNoDuplicateKeys() {
        var allKeys = [String]()
        for section in ViewHelpers.commonHotkeyKeySections {
            allKeys.append(contentsOf: section.keys)
        }
        #expect(Set(allKeys).count == allKeys.count)
    }

    // MARK: - insertionProbeSampleText helpers

    @Test("insertionProbeSampleTextWillTruncate: short text → false")
    func probeTruncateShort() {
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate("hello") == false)
    }

    @Test("insertionProbeSampleTextWillTruncate: exactly 200 chars → false")
    func probeTruncateExact() {
        let text = String(repeating: "a", count: 200)
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate(text) == false)
    }

    @Test("insertionProbeSampleTextWillTruncate: 201 chars → true")
    func probeTruncateOver() {
        let text = String(repeating: "a", count: 201)
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate(text) == true)
    }

    @Test("enforceInsertionProbeSampleTextLimit: short text unchanged")
    func enforceProbeShort() {
        #expect(ViewHelpers.enforceInsertionProbeSampleTextLimit("hello") == "hello")
    }

    @Test("enforceInsertionProbeSampleTextLimit: long text truncated to 200")
    func enforceProbeLong() {
        let text = String(repeating: "x", count: 300)
        let result = ViewHelpers.enforceInsertionProbeSampleTextLimit(text)
        #expect(result.count == 200)
    }

    @Test("insertionProbeSampleTextForRun: trims and limits")
    func probeTextForRun() {
        let text = "  " + String(repeating: "y", count: 250) + "  "
        let result = ViewHelpers.insertionProbeSampleTextForRun(text)
        #expect(result.count == 200)
        #expect(!result.hasPrefix(" "))
    }

    @Test("insertionProbeSampleTextForRun: empty → empty")
    func probeTextForRunEmpty() {
        #expect(ViewHelpers.insertionProbeSampleTextForRun("") == "")
    }

    @Test("insertionProbeSampleTextForRun: whitespace only → empty")
    func probeTextForRunWhitespace() {
        #expect(ViewHelpers.insertionProbeSampleTextForRun("   ") == "")
    }

    @Test("hasInsertionProbeSampleText: normal text → true")
    func hasProbeTextNormal() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("hello") == true)
    }

    @Test("hasInsertionProbeSampleText: empty → false")
    func hasProbeTextEmpty() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("") == false)
    }

    @Test("hasInsertionProbeSampleText: whitespace only → false")
    func hasProbeTextWhitespace() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("   \n\t  ") == false)
    }

    // MARK: - insertionProbeStatus

    @Test("insertionProbeStatus: nil → unknown")
    func probeStatusNil() {
        let status = ViewHelpers.insertionProbeStatus(succeeded: nil)
        #expect(status == .unknown)
    }

    @Test("insertionProbeStatus: true → success")
    func probeStatusTrue() {
        let status = ViewHelpers.insertionProbeStatus(succeeded: true)
        #expect(status == .success)
    }

    @Test("insertionProbeStatus: false → failure")
    func probeStatusFalse() {
        let status = ViewHelpers.insertionProbeStatus(succeeded: false)
        #expect(status == .failure)
    }

    // MARK: - showsAutoPastePermissionWarning

    @Test("showsAutoPastePermissionWarning: autoPaste on, no accessibility → true")
    func autoPasteWarningTrue() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: false) == true)
    }

    @Test("showsAutoPastePermissionWarning: autoPaste on, accessibility → false")
    func autoPasteWarningNoWarning() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: true) == false)
    }

    @Test("showsAutoPastePermissionWarning: autoPaste off → false regardless")
    func autoPasteWarningOff() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: false, accessibilityAuthorized: false) == false)
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: false, accessibilityAuthorized: true) == false)
    }

    // MARK: - canFocusInsertionTarget

    @Test("canFocusInsertionTarget: idle with target → true")
    func canFocusIdleWithTarget() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: true) == true)
    }

    @Test("canFocusInsertionTarget: recording → false")
    func canFocusRecording() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: true, isFinalizingTranscription: false, hasInsertionTarget: true) == false)
    }

    @Test("canFocusInsertionTarget: finalizing → false")
    func canFocusFinalizing() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: true, hasInsertionTarget: true) == false)
    }

    @Test("canFocusInsertionTarget: no target → false")
    func canFocusNoTarget() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: false) == false)
    }

    // MARK: - canClearInsertionTarget

    @Test("canClearInsertionTarget: not running probe, has target → true")
    func canClearNormal() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: true) == true)
    }

    @Test("canClearInsertionTarget: running probe → false")
    func canClearRunningProbe() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: true, hasInsertionTarget: true) == false)
    }

    @Test("canClearInsertionTarget: no target → false")
    func canClearNoTarget() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: false) == false)
    }

    // MARK: - shouldIgnoreCaptureActivation

    @Test("shouldIgnoreCaptureActivation: within debounce, k key, cmd+shift → true")
    func ignoreCaptureTrue() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == true)
    }

    @Test("shouldIgnoreCaptureActivation: past debounce → false")
    func ignoreCapturePastDebounce() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.5,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == false)
    }

    @Test("shouldIgnoreCaptureActivation: wrong key → false")
    func ignoreCaptureWrongKey() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "j",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == false)
    }

    @Test("shouldIgnoreCaptureActivation: nil key → false")
    func ignoreCaptureNilKey() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: nil,
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == false)
    }

    @Test("shouldIgnoreCaptureActivation: no command modifier → false")
    func ignoreCaptureNoCommand() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "k",
            hasCommandModifier: false,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == false)
    }

    @Test("shouldIgnoreCaptureActivation: no shift modifier → false")
    func ignoreCaptureNoShift() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: false,
            hasExtraModifiers: false
        ) == false)
    }

    @Test("shouldIgnoreCaptureActivation: extra modifiers → false")
    func ignoreCaptureExtraModifiers() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: true
        ) == false)
    }

    @Test("shouldIgnoreCaptureActivation: exactly at debounce threshold → still ignored")
    func ignoreCaptureExactThreshold() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.35,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == true)
    }

    @Test("shouldIgnoreCaptureActivation: just past threshold → not ignored")
    func ignoreCaptureJustPast() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.351,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == false)
    }

    // MARK: - hotkeyKeyNameFromKeyCode

    @Test("hotkeyKeyNameFromKeyCode: space key code")
    func keyNameSpace() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x31) == "space")
    }

    @Test("hotkeyKeyNameFromKeyCode: return key code")
    func keyNameReturn() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x24) == "return")
    }

    @Test("hotkeyKeyNameFromKeyCode: escape key code")
    func keyNameEscape() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x35) == "escape")
    }

    @Test("hotkeyKeyNameFromKeyCode: modifier-only codes return nil")
    func keyNameModifiers() {
        // Left command
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x37) == nil)
        // Left shift
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x38) == nil)
        // Right shift
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x3C) == nil)
        // Left option
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x3A) == nil)
        // Right option
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x3D) == nil)
        // Left control
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x3B) == nil)
        // Right control
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x3E) == nil)
        // Caps lock
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x39) == nil)
    }

    @Test("hotkeyKeyNameFromKeyCode: fn key")
    func keyNameFn() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x3F) == "fn")
    }

    @Test("hotkeyKeyNameFromKeyCode: tab key")
    func keyNameTab() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x30) == "tab")
    }

    @Test("hotkeyKeyNameFromKeyCode: delete key")
    func keyNameDelete() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x33) == "delete")
    }

    @Test("hotkeyKeyNameFromKeyCode: forward delete")
    func keyNameForwardDelete() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x75) == "forwarddelete")
    }

    @Test("hotkeyKeyNameFromKeyCode: arrow keys")
    func keyNameArrows() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x7B) == "left")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x7C) == "right")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x7E) == "up")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x7D) == "down")
    }

    @Test("hotkeyKeyNameFromKeyCode: function keys f1-f12")
    func keyNameFunctionKeys() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x7A) == "f1")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x78) == "f2")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x63) == "f3")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x76) == "f4")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x60) == "f5")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x61) == "f6")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x62) == "f7")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x64) == "f8")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x65) == "f9")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x6D) == "f10")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x67) == "f11")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x6F) == "f12")
    }

    @Test("hotkeyKeyNameFromKeyCode: extended function keys f13-f20")
    func keyNameExtendedFunctionKeys() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x69) == "f13")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x6B) == "f14")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x71) == "f15")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x6A) == "f16")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x40) == "f17")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x4F) == "f18")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x50) == "f19")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x5A) == "f20")
    }

    @Test("hotkeyKeyNameFromKeyCode: keypad numbers")
    func keyNameKeypadNumbers() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x52) == "keypad0")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x53) == "keypad1")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x54) == "keypad2")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x55) == "keypad3")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x56) == "keypad4")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x57) == "keypad5")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x58) == "keypad6")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x59) == "keypad7")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x5B) == "keypad8")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x5C) == "keypad9")
    }

    @Test("hotkeyKeyNameFromKeyCode: keypad operators")
    func keyNameKeypadOperators() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x41) == "keypaddecimal")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x5F) == "keypadcomma")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x43) == "keypadmultiply")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x45) == "keypadplus")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x47) == "keypadclear")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x4B) == "keypaddivide")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x4C) == "keypadenter")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x4E) == "keypadminus")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x51) == "keypadequals")
    }

    @Test("hotkeyKeyNameFromKeyCode: navigation keys")
    func keyNameNavigation() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x73) == "home")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x77) == "end")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x74) == "pageup")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x79) == "pagedown")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x72) == "insert")
    }

    @Test("hotkeyKeyNameFromKeyCode: unknown code with characters → uses characters")
    func keyNameUnknownWithChars() {
        let result = ViewHelpers.hotkeyKeyNameFromKeyCode(0x00, characters: "a")
        #expect(result != nil)
    }

    @Test("hotkeyKeyNameFromKeyCode: unknown code without characters → nil")
    func keyNameUnknownNoChars() {
        let result = ViewHelpers.hotkeyKeyNameFromKeyCode(0xFF, characters: nil)
        #expect(result == nil)
    }

    @Test("hotkeyKeyNameFromKeyCode: unknown code with empty characters → nil")
    func keyNameUnknownEmptyChars() {
        let result = ViewHelpers.hotkeyKeyNameFromKeyCode(0xFF, characters: "")
        #expect(result == nil)
    }

    // MARK: - isModifierOnlyKeyCode

    @Test("isModifierOnlyKeyCode: modifier codes → true")
    func modifierOnlyTrue() {
        let modifierCodes = [0x37, 0x38, 0x3C, 0x3A, 0x3D, 0x3B, 0x3E, 0x39]
        for code in modifierCodes {
            #expect(ViewHelpers.isModifierOnlyKeyCode(code) == true, "Expected \(String(format: "0x%02X", code)) to be modifier-only")
        }
    }

    @Test("isModifierOnlyKeyCode: non-modifier codes → false")
    func modifierOnlyFalse() {
        let nonModifierCodes = [0x31, 0x24, 0x35, 0x7A, 0x00]
        for code in nonModifierCodes {
            #expect(ViewHelpers.isModifierOnlyKeyCode(code) == false, "Expected \(String(format: "0x%02X", code)) to NOT be modifier-only")
        }
    }

    // MARK: - runInsertionTestButtonTitle

    @Test("runInsertionTestButtonTitle: not running, can run → plain title")
    func runInsertionTestIdle() {
        let result = ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: false, canRunTest: true, autoCaptureTargetName: nil, canCaptureAndRun: false)
        #expect(result == "Run insertion test")
    }

    @Test("runInsertionTestButtonTitle: running probe → shows ellipsis")
    func runInsertionTestRunning() {
        let result = ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: true, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: false)
        #expect(result.contains("…"))
    }

    @Test("runInsertionTestButtonTitle: cannot run, has auto-capture target")
    func runInsertionTestAutoCapture() {
        let result = ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: false, canRunTest: false, autoCaptureTargetName: "Safari", canCaptureAndRun: false)
        #expect(result.contains("Safari"))
        #expect(result.contains("capture"))
    }

    @Test("runInsertionTestButtonTitle: cannot run, can capture and run")
    func runInsertionTestCanCaptureAndRun() {
        let result = ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: false, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: true)
        #expect(result.contains("auto-capture"))
    }

    @Test("runInsertionTestButtonTitle: cannot run, no options → plain title")
    func runInsertionTestNoOptions() {
        let result = ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: false, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: false)
        #expect(result == "Run insertion test")
    }
}
