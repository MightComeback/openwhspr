import Testing
import Foundation
@testable import OpenWhisper

@Suite("ContentView button helpers (ViewHelpers)")
struct ContentViewButtonTests {

    // MARK: - retargetButtonTitle

    @Test("retargetButtonTitle: no target returns Retarget")
    func retargetTitleNoTarget() {
        #expect(ViewHelpers.retargetButtonTitle(insertTargetAppName: nil, insertTargetUsesFallback: false) == "Retarget")
    }

    @Test("retargetButtonTitle: empty target returns Retarget")
    func retargetTitleEmptyTarget() {
        #expect(ViewHelpers.retargetButtonTitle(insertTargetAppName: "", insertTargetUsesFallback: false) == "Retarget")
    }

    @Test("retargetButtonTitle: with target shows arrow")
    func retargetTitleWithTarget() {
        #expect(ViewHelpers.retargetButtonTitle(insertTargetAppName: "Safari", insertTargetUsesFallback: false) == "Retarget → Safari")
    }

    @Test("retargetButtonTitle: fallback shows (recent)")
    func retargetTitleFallback() {
        let title = ViewHelpers.retargetButtonTitle(insertTargetAppName: "Safari", insertTargetUsesFallback: true)
        #expect(title.contains("(recent)"))
        #expect(title.contains("Safari"))
    }

    @Test("retargetButtonTitle: long name truncated")
    func retargetTitleLongName() {
        let longName = "A Very Long Application Name That Exceeds Limit"
        let title = ViewHelpers.retargetButtonTitle(insertTargetAppName: longName, insertTargetUsesFallback: false)
        #expect(title.contains("…"))
    }

    // MARK: - retargetButtonHelpText

    @Test("retargetButtonHelpText: recording")
    func retargetHelpRecording() {
        #expect(ViewHelpers.retargetButtonHelpText(isRecording: true, pendingChunkCount: 0) == "Finish recording before retargeting insertion")
    }

    @Test("retargetButtonHelpText: pending chunks")
    func retargetHelpPending() {
        #expect(ViewHelpers.retargetButtonHelpText(isRecording: false, pendingChunkCount: 3) == "Wait for finalization before retargeting insertion")
    }

    @Test("retargetButtonHelpText: ready")
    func retargetHelpReady() {
        #expect(ViewHelpers.retargetButtonHelpText(isRecording: false, pendingChunkCount: 0) == "Refresh insertion target from your current front app")
    }

    // MARK: - useCurrentAppButtonTitle

    @Test("useCurrentAppButtonTitle: cannot insert directly")
    func useCurrentCopyOnly() {
        #expect(ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: false, currentFrontAppName: "Safari") == "Use Current + Copy")
    }

    @Test("useCurrentAppButtonTitle: can insert with front app")
    func useCurrentWithFront() {
        let title = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: "Safari")
        #expect(title == "Use Current → Safari")
    }

    @Test("useCurrentAppButtonTitle: can insert no front app")
    func useCurrentNoFront() {
        #expect(ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: nil) == "Use Current App")
    }

    @Test("useCurrentAppButtonTitle: can insert empty front app")
    func useCurrentEmptyFront() {
        #expect(ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: "") == "Use Current App")
    }

    // MARK: - useCurrentAppButtonHelpText

    @Test("useCurrentAppButtonHelpText: disabled reason")
    func useCurrentHelpDisabled() {
        let help = ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: "Recording", canInsertDirectly: true)
        #expect(help == "Recording before using current app")
    }

    @Test("useCurrentAppButtonHelpText: can insert")
    func useCurrentHelpInsert() {
        #expect(ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true) == "Retarget to the current front app and insert immediately")
    }

    @Test("useCurrentAppButtonHelpText: cannot insert")
    func useCurrentHelpCopy() {
        #expect(ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: false) == "Retarget to the current front app and copy to clipboard")
    }

    // MARK: - retargetAndInsertButtonTitle

    @Test("retargetAndInsertButtonTitle: cannot insert directly")
    func retargetInsertCopy() {
        #expect(ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: false, currentFrontAppName: "Safari") == "Retarget + Copy → Clipboard")
    }

    @Test("retargetAndInsertButtonTitle: can insert with front app")
    func retargetInsertWithFront() {
        let title = ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: true, currentFrontAppName: "Safari")
        #expect(title == "Retarget + Insert → Safari")
    }

    @Test("retargetAndInsertButtonTitle: can insert no front app")
    func retargetInsertNoFront() {
        #expect(ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: true, currentFrontAppName: nil) == "Retarget + Insert → Current App")
    }

    // MARK: - retargetAndInsertHelpText

    @Test("retargetAndInsertHelpText: disabled reason")
    func retargetInsertHelpDisabled() {
        let help = ViewHelpers.retargetAndInsertHelpText(insertActionDisabledReason: "Recording", canInsertDirectly: true)
        #expect(help == "Recording before retargeting and inserting")
    }

    @Test("retargetAndInsertHelpText: cannot insert")
    func retargetInsertHelpCopy() {
        #expect(ViewHelpers.retargetAndInsertHelpText(insertActionDisabledReason: nil, canInsertDirectly: false) == "Refresh target app, then copy transcription to clipboard")
    }

    @Test("retargetAndInsertHelpText: can insert")
    func retargetInsertHelpInsert() {
        #expect(ViewHelpers.retargetAndInsertHelpText(insertActionDisabledReason: nil, canInsertDirectly: true) == "Refresh target app from the current front app, then insert")
    }

    // MARK: - focusTargetButtonTitle

    @Test("focusTargetButtonTitle: no target")
    func focusTitleNoTarget() {
        #expect(ViewHelpers.focusTargetButtonTitle(insertTargetAppName: nil) == "Focus Target")
    }

    @Test("focusTargetButtonTitle: empty target")
    func focusTitleEmptyTarget() {
        #expect(ViewHelpers.focusTargetButtonTitle(insertTargetAppName: "") == "Focus Target")
    }

    @Test("focusTargetButtonTitle: with target")
    func focusTitleWithTarget() {
        #expect(ViewHelpers.focusTargetButtonTitle(insertTargetAppName: "Notes") == "Focus → Notes")
    }

    // MARK: - focusTargetButtonHelpText

    @Test("focusTargetButtonHelpText: recording")
    func focusHelpRecording() {
        #expect(ViewHelpers.focusTargetButtonHelpText(isRecording: true, pendingChunkCount: 0, insertTargetAppName: "Safari") == "Wait for recording/finalization to finish before focusing the target app")
    }

    @Test("focusTargetButtonHelpText: pending chunks")
    func focusHelpPending() {
        #expect(ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 2, insertTargetAppName: "Safari") == "Wait for recording/finalization to finish before focusing the target app")
    }

    @Test("focusTargetButtonHelpText: with target")
    func focusHelpWithTarget() {
        #expect(ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 0, insertTargetAppName: "Safari") == "Bring Safari to the front before inserting")
    }

    @Test("focusTargetButtonHelpText: no target")
    func focusHelpNoTarget() {
        #expect(ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 0, insertTargetAppName: nil) == "No insertion target yet. Switch to your destination app, then click Retarget.")
    }

    // MARK: - focusAndInsertButtonTitle

    @Test("focusAndInsertButtonTitle: cannot insert")
    func focusInsertCopy() {
        #expect(ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: false, insertTargetAppName: "Safari") == "Focus + Copy")
    }

    @Test("focusAndInsertButtonTitle: can insert with target")
    func focusInsertWithTarget() {
        #expect(ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: true, insertTargetAppName: "Safari") == "Focus + Insert → Safari")
    }

    @Test("focusAndInsertButtonTitle: can insert no target")
    func focusInsertNoTarget() {
        #expect(ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: true, insertTargetAppName: nil) == "Focus + Insert")
    }

    // MARK: - focusAndInsertButtonHelpText

    @Test("focusAndInsertButtonHelpText: disabled reason")
    func focusInsertHelpDisabled() {
        let help = ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: "Recording", hasResolvableInsertTarget: true, canInsertDirectly: true)
        #expect(help == "Recording before focusing and inserting")
    }

    @Test("focusAndInsertButtonHelpText: no target")
    func focusInsertHelpNoTarget() {
        #expect(ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: nil, hasResolvableInsertTarget: false, canInsertDirectly: true) == "No insertion target yet. Switch to your destination app, then click Retarget.")
    }

    @Test("focusAndInsertButtonHelpText: can insert")
    func focusInsertHelpInsert() {
        #expect(ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: nil, hasResolvableInsertTarget: true, canInsertDirectly: true) == "Focus the saved insert target and insert immediately")
    }

    @Test("focusAndInsertButtonHelpText: cannot insert")
    func focusInsertHelpCopy() {
        #expect(ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: nil, hasResolvableInsertTarget: true, canInsertDirectly: false) == "Focus the saved insert target and copy to clipboard")
    }

    // MARK: - canRetargetInsertTarget

    @Test("canRetargetInsertTarget: not recording no pending")
    func canRetargetTrue() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: false, pendingChunkCount: 0) == true)
    }

    @Test("canRetargetInsertTarget: recording")
    func canRetargetRecording() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: true, pendingChunkCount: 0) == false)
    }

    @Test("canRetargetInsertTarget: pending chunks")
    func canRetargetPending() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: false, pendingChunkCount: 3) == false)
    }

    // MARK: - hasResolvableInsertTarget

    @Test("hasResolvableInsertTarget: nil")
    func resolvableNil() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: nil) == false)
    }

    @Test("hasResolvableInsertTarget: empty")
    func resolvableEmpty() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "") == false)
    }

    @Test("hasResolvableInsertTarget: whitespace only")
    func resolvableWhitespace() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "   ") == false)
    }

    @Test("hasResolvableInsertTarget: valid name")
    func resolvableValid() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "Safari") == true)
    }
}
