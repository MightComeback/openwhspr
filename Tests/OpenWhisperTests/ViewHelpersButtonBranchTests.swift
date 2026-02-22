import Testing
import Foundation
@testable import OpenWhisper

/// Exhaustive branch coverage for button title/help text helpers in ViewHelpers.
/// Targets every conditional path in insert, retarget, focus, and use-current-app helpers.
@Suite("ViewHelpers Button Branch Coverage")
struct ViewHelpersButtonBranchTests {

    // MARK: - insertButtonTitle branches

    @Test("insertButtonTitle: canInsertDirectly + nil target + liveFront present")
    func insertButtonTitleLiveFrontFallback() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: "Safari"
        )
        #expect(title == "Insert → Safari")
    }

    @Test("insertButtonTitle: canInsertDirectly + nil target + nil liveFront")
    func insertButtonTitleNoTargetNoLiveFront() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(title == "Copy → Clipboard")
    }

    @Test("insertButtonTitle: canInsertDirectly + empty target + empty liveFront")
    func insertButtonTitleEmptyStrings() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: ""
        )
        #expect(title == "Copy → Clipboard")
    }

    @Test("insertButtonTitle: canInsertDirectly + target with fallback")
    func insertButtonTitleFallbackTarget() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "Notes",
            insertTargetUsesFallback: true,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(title == "Insert → Notes (recent)")
    }

    @Test("insertButtonTitle: canInsertDirectly + target + shouldSuggestRetarget")
    func insertButtonTitleSuggestRetarget() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "Slack",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: true,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(title == "Insert → Slack ⚠︎")
    }

    @Test("insertButtonTitle: canInsertDirectly + target + isStale")
    func insertButtonTitleStale() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "Xcode",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: true,
            liveFrontAppName: nil
        )
        #expect(title == "Insert → Xcode ⚠︎")
    }

    @Test("insertButtonTitle: canInsertDirectly + target + fallback + stale shows warning")
    func insertButtonTitleFallbackAndStale() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "Notes",
            insertTargetUsesFallback: true,
            shouldSuggestRetarget: false,
            isInsertTargetStale: true,
            liveFrontAppName: nil
        )
        #expect(title == "Insert → Notes (recent) ⚠︎")
    }

    @Test("insertButtonTitle: canInsertDirectly + normal target")
    func insertButtonTitleNormalTarget() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "TextEdit",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(title == "Insert → TextEdit")
    }

    @Test("insertButtonTitle: cannot insert directly")
    func insertButtonTitleCannotInsert() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: false,
            insertTargetAppName: "Xcode",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: "Finder"
        )
        #expect(title == "Copy → Clipboard")
    }

    @Test("insertButtonTitle: long app name gets abbreviated")
    func insertButtonTitleLongAppName() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "A Very Long Application Name That Exceeds Limit",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(title.contains("…") || title.count < 60)
    }

    // MARK: - insertButtonHelpText branches

    @Test("insertButtonHelpText: disabled reason present")
    func insertButtonHelpDisabledReason() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: "Record something",
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(help == "Record something before inserting")
    }

    @Test("insertButtonHelpText: cannot insert + has target")
    func insertButtonHelpCannotInsertWithTarget() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: false,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: "Slack",
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(help.contains("Accessibility permission") && help.contains("Slack"))
    }

    @Test("insertButtonHelpText: cannot insert + no target")
    func insertButtonHelpCannotInsertNoTarget() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: false,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(help.contains("Accessibility permission") && help.contains("clipboard"))
    }

    @Test("insertButtonHelpText: copy because target unknown")
    func insertButtonHelpCopyBecauseUnknown() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: true,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(help.contains("No destination app"))
    }

    @Test("insertButtonHelpText: suggest retarget with both apps")
    func insertButtonHelpSuggestRetarget() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: true,
            isInsertTargetStale: false,
            insertTargetAppName: "Notes",
            insertTargetUsesFallback: false,
            currentFrontAppName: "Safari"
        )
        #expect(help.contains("Safari") && help.contains("Notes") && help.contains("Retarget"))
    }

    @Test("insertButtonHelpText: stale target")
    func insertButtonHelpStaleTarget() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: true,
            insertTargetAppName: "Xcode",
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(help.contains("Xcode") && help.contains("captured a while ago"))
    }

    @Test("insertButtonHelpText: normal with no target + liveFront")
    func insertButtonHelpNoTargetLiveFront() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            currentFrontAppName: "Terminal"
        )
        #expect(help == "Insert into Terminal")
    }

    @Test("insertButtonHelpText: normal with no target + no liveFront")
    func insertButtonHelpNoTargetNoLiveFront() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(help == "Insert into the last active app")
    }

    @Test("insertButtonHelpText: fallback target")
    func insertButtonHelpFallbackTarget() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: "Notes",
            insertTargetUsesFallback: true,
            currentFrontAppName: nil
        )
        #expect(help.contains("Notes") && help.contains("recent app context"))
    }

    @Test("insertButtonHelpText: normal target direct")
    func insertButtonHelpNormalTarget() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: "Xcode",
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(help == "Insert into Xcode")
    }

    // MARK: - retargetButtonTitle branches

    @Test("retargetButtonTitle: no target")
    func retargetTitleNoTarget() {
        let title = ViewHelpers.retargetButtonTitle(insertTargetAppName: nil, insertTargetUsesFallback: false)
        #expect(title == "Retarget")
    }

    @Test("retargetButtonTitle: empty target")
    func retargetTitleEmptyTarget() {
        let title = ViewHelpers.retargetButtonTitle(insertTargetAppName: "", insertTargetUsesFallback: false)
        #expect(title == "Retarget")
    }

    @Test("retargetButtonTitle: fallback target")
    func retargetTitleFallback() {
        let title = ViewHelpers.retargetButtonTitle(insertTargetAppName: "Safari", insertTargetUsesFallback: true)
        #expect(title == "Retarget → Safari (recent)")
    }

    @Test("retargetButtonTitle: normal target")
    func retargetTitleNormal() {
        let title = ViewHelpers.retargetButtonTitle(insertTargetAppName: "Xcode", insertTargetUsesFallback: false)
        #expect(title == "Retarget → Xcode")
    }

    // MARK: - retargetButtonHelpText branches

    @Test("retargetButtonHelpText: recording")
    func retargetHelpRecording() {
        let help = ViewHelpers.retargetButtonHelpText(isRecording: true, pendingChunkCount: 0)
        #expect(help.contains("Finish recording"))
    }

    @Test("retargetButtonHelpText: pending chunks")
    func retargetHelpPending() {
        let help = ViewHelpers.retargetButtonHelpText(isRecording: false, pendingChunkCount: 3)
        #expect(help.contains("Wait for finalization"))
    }

    @Test("retargetButtonHelpText: ready")
    func retargetHelpReady() {
        let help = ViewHelpers.retargetButtonHelpText(isRecording: false, pendingChunkCount: 0)
        #expect(help.contains("Refresh insertion target"))
    }

    // MARK: - useCurrentAppButtonTitle branches

    @Test("useCurrentAppButtonTitle: can insert + has front app")
    func useCurrentTitleWithFront() {
        let title = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: "Safari")
        #expect(title == "Use Current → Safari")
    }

    @Test("useCurrentAppButtonTitle: can insert + no front app")
    func useCurrentTitleNoFront() {
        let title = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: nil)
        #expect(title == "Use Current App")
    }

    @Test("useCurrentAppButtonTitle: can insert + empty front app")
    func useCurrentTitleEmptyFront() {
        let title = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: "")
        #expect(title == "Use Current App")
    }

    @Test("useCurrentAppButtonTitle: cannot insert")
    func useCurrentTitleCannotInsert() {
        let title = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: false, currentFrontAppName: "Safari")
        #expect(title == "Use Current + Copy")
    }

    // MARK: - useCurrentAppButtonHelpText branches

    @Test("useCurrentAppButtonHelpText: disabled reason")
    func useCurrentHelpDisabled() {
        let help = ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: "Wait", canInsertDirectly: true)
        #expect(help == "Wait before using current app")
    }

    @Test("useCurrentAppButtonHelpText: can insert")
    func useCurrentHelpCanInsert() {
        let help = ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true)
        #expect(help.contains("insert immediately"))
    }

    @Test("useCurrentAppButtonHelpText: cannot insert")
    func useCurrentHelpCannotInsert() {
        let help = ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: false)
        #expect(help.contains("copy to clipboard"))
    }

    // MARK: - retargetAndInsertButtonTitle branches

    @Test("retargetAndInsertButtonTitle: can insert + front app")
    func retargetAndInsertTitleWithFront() {
        let title = ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: true, currentFrontAppName: "Notes")
        #expect(title == "Retarget + Insert → Notes")
    }

    @Test("retargetAndInsertButtonTitle: can insert + no front app")
    func retargetAndInsertTitleNoFront() {
        let title = ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: true, currentFrontAppName: nil)
        #expect(title == "Retarget + Insert → Current App")
    }

    @Test("retargetAndInsertButtonTitle: cannot insert")
    func retargetAndInsertTitleCannotInsert() {
        let title = ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: false, currentFrontAppName: "Safari")
        #expect(title == "Retarget + Copy → Clipboard")
    }

    // MARK: - retargetAndInsertHelpText branches

    @Test("retargetAndInsertHelpText: disabled reason")
    func retargetAndInsertHelpDisabled() {
        let help = ViewHelpers.retargetAndInsertHelpText(insertActionDisabledReason: "Transcribe first", canInsertDirectly: true)
        #expect(help == "Transcribe first before retargeting and inserting")
    }

    @Test("retargetAndInsertHelpText: cannot insert")
    func retargetAndInsertHelpCannotInsert() {
        let help = ViewHelpers.retargetAndInsertHelpText(insertActionDisabledReason: nil, canInsertDirectly: false)
        #expect(help.contains("copy transcription to clipboard"))
    }

    @Test("retargetAndInsertHelpText: can insert")
    func retargetAndInsertHelpCanInsert() {
        let help = ViewHelpers.retargetAndInsertHelpText(insertActionDisabledReason: nil, canInsertDirectly: true)
        #expect(help.contains("Refresh target app") && help.contains("then insert"))
    }

    // MARK: - focusTargetButtonTitle branches

    @Test("focusTargetButtonTitle: no target")
    func focusTargetTitleNoTarget() {
        let title = ViewHelpers.focusTargetButtonTitle(insertTargetAppName: nil)
        #expect(title == "Focus Target")
    }

    @Test("focusTargetButtonTitle: empty target")
    func focusTargetTitleEmpty() {
        let title = ViewHelpers.focusTargetButtonTitle(insertTargetAppName: "")
        #expect(title == "Focus Target")
    }

    @Test("focusTargetButtonTitle: with target")
    func focusTargetTitleWithTarget() {
        let title = ViewHelpers.focusTargetButtonTitle(insertTargetAppName: "Terminal")
        #expect(title == "Focus → Terminal")
    }

    // MARK: - focusTargetButtonHelpText branches

    @Test("focusTargetButtonHelpText: recording")
    func focusTargetHelpRecording() {
        let help = ViewHelpers.focusTargetButtonHelpText(isRecording: true, pendingChunkCount: 0, insertTargetAppName: "Xcode")
        #expect(help.contains("Wait for recording/finalization"))
    }

    @Test("focusTargetButtonHelpText: pending chunks")
    func focusTargetHelpPending() {
        let help = ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 2, insertTargetAppName: "Xcode")
        #expect(help.contains("Wait for recording/finalization"))
    }

    @Test("focusTargetButtonHelpText: with target ready")
    func focusTargetHelpWithTarget() {
        let help = ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 0, insertTargetAppName: "Xcode")
        #expect(help.contains("Bring Xcode to the front"))
    }

    @Test("focusTargetButtonHelpText: no target")
    func focusTargetHelpNoTarget() {
        let help = ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 0, insertTargetAppName: nil)
        #expect(help.contains("No insertion target yet"))
    }

    @Test("focusTargetButtonHelpText: empty target")
    func focusTargetHelpEmptyTarget() {
        let help = ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 0, insertTargetAppName: "")
        #expect(help.contains("No insertion target yet"))
    }

    // MARK: - focusAndInsertButtonTitle branches

    @Test("focusAndInsertButtonTitle: can insert + target")
    func focusAndInsertTitleWithTarget() {
        let title = ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: true, insertTargetAppName: "Xcode")
        #expect(title == "Focus + Insert → Xcode")
    }

    @Test("focusAndInsertButtonTitle: can insert + no target")
    func focusAndInsertTitleNoTarget() {
        let title = ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: true, insertTargetAppName: nil)
        #expect(title == "Focus + Insert")
    }

    @Test("focusAndInsertButtonTitle: cannot insert")
    func focusAndInsertTitleCannotInsert() {
        let title = ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: false, insertTargetAppName: "Xcode")
        #expect(title == "Focus + Copy")
    }

    // MARK: - focusAndInsertButtonHelpText branches

    @Test("focusAndInsertButtonHelpText: disabled reason")
    func focusAndInsertHelpDisabled() {
        let help = ViewHelpers.focusAndInsertButtonHelpText(
            insertActionDisabledReason: "Wait", hasResolvableInsertTarget: true, canInsertDirectly: true)
        #expect(help == "Wait before focusing and inserting")
    }

    @Test("focusAndInsertButtonHelpText: no resolvable target")
    func focusAndInsertHelpNoTarget() {
        let help = ViewHelpers.focusAndInsertButtonHelpText(
            insertActionDisabledReason: nil, hasResolvableInsertTarget: false, canInsertDirectly: true)
        #expect(help.contains("No insertion target yet"))
    }

    @Test("focusAndInsertButtonHelpText: can insert")
    func focusAndInsertHelpCanInsert() {
        let help = ViewHelpers.focusAndInsertButtonHelpText(
            insertActionDisabledReason: nil, hasResolvableInsertTarget: true, canInsertDirectly: true)
        #expect(help.contains("insert immediately"))
    }

    @Test("focusAndInsertButtonHelpText: cannot insert")
    func focusAndInsertHelpCannotInsert() {
        let help = ViewHelpers.focusAndInsertButtonHelpText(
            insertActionDisabledReason: nil, hasResolvableInsertTarget: true, canInsertDirectly: false)
        #expect(help.contains("copy to clipboard"))
    }

    // MARK: - runInsertionTestButtonTitle branches

    @Test("runInsertionTestButtonTitle: running probe")
    func runTestTitleRunning() {
        let title = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: true, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: false)
        #expect(title == "Running insertion test…")
    }

    @Test("runInsertionTestButtonTitle: can run test")
    func runTestTitleCanRun() {
        let title = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: true, autoCaptureTargetName: nil, canCaptureAndRun: false)
        #expect(title == "Run insertion test")
    }

    @Test("runInsertionTestButtonTitle: auto-capture with name")
    func runTestTitleAutoCaptureName() {
        let title = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: false, autoCaptureTargetName: "Safari", canCaptureAndRun: false)
        #expect(title == "Run insertion test (capture Safari)")
    }

    @Test("runInsertionTestButtonTitle: auto-capture with empty name")
    func runTestTitleAutoCaptureEmptyName() {
        let title = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: false, autoCaptureTargetName: "", canCaptureAndRun: true)
        #expect(title == "Run insertion test (auto-capture)")
    }

    @Test("runInsertionTestButtonTitle: can capture and run")
    func runTestTitleCanCaptureAndRun() {
        let title = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: true)
        #expect(title == "Run insertion test (auto-capture)")
    }

    @Test("runInsertionTestButtonTitle: fallback")
    func runTestTitleFallback() {
        let title = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: false)
        #expect(title == "Run insertion test")
    }

    // MARK: - Computed helpers

    @Test("canRetargetInsertTarget: not recording + no chunks")
    func canRetargetReady() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: false, pendingChunkCount: 0) == true)
    }

    @Test("canRetargetInsertTarget: recording blocks")
    func canRetargetRecording() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: true, pendingChunkCount: 0) == false)
    }

    @Test("canRetargetInsertTarget: pending chunks blocks")
    func canRetargetPending() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: false, pendingChunkCount: 1) == false)
    }

    @Test("hasResolvableInsertTarget: nil")
    func hasResolvableNil() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: nil) == false)
    }

    @Test("hasResolvableInsertTarget: empty")
    func hasResolvableEmpty() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "") == false)
    }

    @Test("hasResolvableInsertTarget: whitespace only")
    func hasResolvableWhitespace() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "   ") == false)
    }

    @Test("hasResolvableInsertTarget: valid")
    func hasResolvableValid() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "Xcode") == true)
    }

    // MARK: - canFocusInsertionTarget

    @Test("canFocusInsertionTarget: recording blocks")
    func canFocusRecording() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: true, isFinalizingTranscription: false, hasInsertionTarget: true) == false)
    }

    @Test("canFocusInsertionTarget: finalizing blocks")
    func canFocusFinalizing() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: true, hasInsertionTarget: true) == false)
    }

    @Test("canFocusInsertionTarget: no target blocks")
    func canFocusNoTarget() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: false) == false)
    }

    @Test("canFocusInsertionTarget: all clear")
    func canFocusAllClear() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: true) == true)
    }

    // MARK: - canClearInsertionTarget

    @Test("canClearInsertionTarget: running probe blocks")
    func canClearProbeRunning() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: true, hasInsertionTarget: true) == false)
    }

    @Test("canClearInsertionTarget: no target blocks")
    func canClearNoTarget() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: false) == false)
    }

    @Test("canClearInsertionTarget: clear")
    func canClearReady() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: true) == true)
    }

    // MARK: - shouldIgnoreCaptureActivation

    @Test("shouldIgnoreCaptureActivation: within debounce + cmd+shift+k")
    func ignoreCaptureWithinDebounce() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1, keyName: "k",
            hasCommandModifier: true, hasShiftModifier: true, hasExtraModifiers: false) == true)
    }

    @Test("shouldIgnoreCaptureActivation: past debounce")
    func ignoreCapturePassedDebounce() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.5, keyName: "k",
            hasCommandModifier: true, hasShiftModifier: true, hasExtraModifiers: false) == false)
    }

    @Test("shouldIgnoreCaptureActivation: wrong key")
    func ignoreCaptureWrongKey() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1, keyName: "j",
            hasCommandModifier: true, hasShiftModifier: true, hasExtraModifiers: false) == false)
    }

    @Test("shouldIgnoreCaptureActivation: extra modifiers")
    func ignoreCaptureExtraModifiers() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1, keyName: "k",
            hasCommandModifier: true, hasShiftModifier: true, hasExtraModifiers: true) == false)
    }

    @Test("shouldIgnoreCaptureActivation: no command modifier")
    func ignoreCaptureNoCommand() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1, keyName: "k",
            hasCommandModifier: false, hasShiftModifier: true, hasExtraModifiers: false) == false)
    }

    // MARK: - showsAutoPastePermissionWarning

    @Test("showsAutoPastePermissionWarning: auto paste on + no accessibility")
    func autoPasteWarningShown() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: false) == true)
    }

    @Test("showsAutoPastePermissionWarning: auto paste on + has accessibility")
    func autoPasteWarningNotShown() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: true) == false)
    }

    @Test("showsAutoPastePermissionWarning: auto paste off")
    func autoPasteWarningOff() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: false, accessibilityAuthorized: false) == false)
    }

    // MARK: - hotkeySummaryFromModifiers

    @Test("hotkeySummaryFromModifiers: all modifiers")
    func hotkeySummaryAllModifiers() {
        let result = ViewHelpers.hotkeySummaryFromModifiers(
            command: true, shift: true, option: true, control: true, capsLock: true, key: "k")
        #expect(result.contains("⌘"))
        #expect(result.contains("⇧"))
        #expect(result.contains("⌥"))
        #expect(result.contains("⌃"))
        #expect(result.contains("⇪"))
    }

    @Test("hotkeySummaryFromModifiers: no modifiers")
    func hotkeySummaryNoModifiers() {
        let result = ViewHelpers.hotkeySummaryFromModifiers(
            command: false, shift: false, option: false, control: false, capsLock: false, key: "space")
        #expect(!result.contains("⌘"))
        #expect(!result.contains("⇧"))
    }

    // MARK: - hotkeyKeyNameFromKeyCode (extended)

    @Test("hotkeyKeyNameFromKeyCode: keypad keys")
    func keyNameKeypad() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x52) == "keypad0")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x53) == "keypad1")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x5C) == "keypad9")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x41) == "keypaddecimal")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x43) == "keypadmultiply")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x45) == "keypadplus")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x47) == "keypadclear")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x4B) == "keypaddivide")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x4C) == "keypadenter")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x4E) == "keypadminus")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x51) == "keypadequals")
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x5F) == "keypadcomma")
    }

    @Test("hotkeyKeyNameFromKeyCode: characters fallback for letter key")
    func keyNameCharactersFallback() {
        let result = ViewHelpers.hotkeyKeyNameFromKeyCode(0x00, characters: "A")
        #expect(result != nil)
    }

    @Test("hotkeyKeyNameFromKeyCode: nil characters + unknown keycode")
    func keyNameUnknownNoChars() {
        let result = ViewHelpers.hotkeyKeyNameFromKeyCode(0xFF, characters: nil)
        #expect(result == nil)
    }

    @Test("hotkeyKeyNameFromKeyCode: whitespace character maps to space")
    func keyNameWhitespaceCharacter() {
        let result = ViewHelpers.hotkeyKeyNameFromKeyCode(0xFF, characters: " ")
        #expect(result == "space")
    }

    // MARK: - shouldShowUseCurrentAppQuickAction

    @Test("shouldShowUseCurrentAppQuickAction: suggest retarget true")
    func showUseCurrentSuggestRetarget() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: true, isInsertTargetStale: false) == true)
    }

    @Test("shouldShowUseCurrentAppQuickAction: stale true")
    func showUseCurrentStale() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: false, isInsertTargetStale: true) == true)
    }

    @Test("shouldShowUseCurrentAppQuickAction: both false")
    func showUseCurrentBothFalse() {
        #expect(ViewHelpers.shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: false, isInsertTargetStale: false) == false)
    }

    // MARK: - hasHotkeyDraftEdits

    @Test("hasHotkeyDraftEdits: same key no modifiers")
    func draftEditsNoChange() {
        #expect(ViewHelpers.hasHotkeyDraftEdits(draft: "k", currentKey: "k", currentModifiers: []) == false)
    }

    @Test("hasHotkeyDraftEdits: different key")
    func draftEditsDifferentKey() {
        #expect(ViewHelpers.hasHotkeyDraftEdits(draft: "j", currentKey: "k", currentModifiers: []) == true)
    }

    // MARK: - effectiveHotkeyRiskContext

    @Test("effectiveHotkeyRiskContext: valid draft overrides current")
    func riskContextDraftOverrides() {
        let context = ViewHelpers.effectiveHotkeyRiskContext(
            draft: "cmd+space", currentKey: "k", currentModifiers: [])
        #expect(context.key == "space")
    }

    @Test("effectiveHotkeyRiskContext: invalid draft falls back to current")
    func riskContextInvalidDraft() {
        let context = ViewHelpers.effectiveHotkeyRiskContext(
            draft: "???invalid???", currentKey: "k", currentModifiers: [.command])
        #expect(context.key == "k")
        #expect(context.requiredModifiers == [.command])
    }

    // MARK: - insertionProbeStatus

    @Test("insertionProbeStatus: true → success")
    func probeStatusSuccess() {
        #expect(ViewHelpers.insertionProbeStatus(succeeded: true) == .success)
    }

    @Test("insertionProbeStatus: false → failure")
    func probeStatusFailure() {
        #expect(ViewHelpers.insertionProbeStatus(succeeded: false) == .failure)
    }

    @Test("insertionProbeStatus: nil → unknown")
    func probeStatusUnknown() {
        #expect(ViewHelpers.insertionProbeStatus(succeeded: nil) == .unknown)
    }

    // MARK: - hotkeyModeTipText

    @Test("hotkeyModeTipText: toggle mode")
    func modeTipToggle() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: false)
        #expect(!tip.isEmpty)
    }

    @Test("hotkeyModeTipText: hold mode")
    func modeTipHold() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: false)
        #expect(!tip.isEmpty)
    }

    @Test("hotkeyModeTipText: toggle mode with escape trigger")
    func modeTipToggleEscape() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: true)
        #expect(!tip.isEmpty)
    }

    // MARK: - hotkeyCaptureButtonTitle

    @Test("hotkeyCaptureButtonTitle: capturing")
    func captureButtonCapturing() {
        let title = ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: true, secondsRemaining: 3)
        #expect(title.contains("3"))
    }

    @Test("hotkeyCaptureButtonTitle: not capturing")
    func captureButtonNotCapturing() {
        let title = ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: false, secondsRemaining: 5)
        #expect(!title.contains("5"))
    }

    // MARK: - hotkeyCaptureProgress

    @Test("hotkeyCaptureProgress: no time remaining")
    func captureProgressNoRemaining() {
        let progress = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 0, totalSeconds: 5)
        #expect(progress == 0.0)
    }

    @Test("hotkeyCaptureProgress: half remaining")
    func captureProgressHalf() {
        let progress = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 10)
        #expect(progress == 0.5)
    }

    @Test("hotkeyCaptureProgress: full remaining")
    func captureProgressFull() {
        let progress = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 10, totalSeconds: 10)
        #expect(progress == 1.0)
    }

    @Test("hotkeyCaptureProgress: zero total returns 0")
    func captureProgressZeroTotal() {
        let progress = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 0, totalSeconds: 0)
        #expect(progress == 0.0)
    }
}
