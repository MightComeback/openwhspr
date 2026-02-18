import Testing
import Foundation
@testable import OpenWhisper

@Suite("SettingsView extracted helpers")
struct SettingsViewExtractedHelpersTests {

    // MARK: - hotkeyModeTipText

    @Test("toggle mode normal tip")
    func toggleModeNormal() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: false)
        #expect(tip.contains("toggle mode"))
        #expect(tip.contains("Press Esc"))
    }

    @Test("toggle mode with escape trigger")
    func toggleModeEscape() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: true)
        #expect(tip.contains("toggle mode"))
        #expect(tip.contains("Escape quick-cancel is unavailable"))
    }

    @Test("hold mode normal tip")
    func holdModeNormal() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: false)
        #expect(tip.contains("hold-to-talk"))
        #expect(tip.contains("Press Esc"))
    }

    @Test("hold mode with escape trigger")
    func holdModeEscape() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: true)
        #expect(tip.contains("hold-to-talk"))
        #expect(tip.contains("Escape quick-cancel is unavailable"))
    }

    // MARK: - hotkeyCaptureButtonTitle

    @Test("not capturing shows Record shortcut")
    func captureButtonNotCapturing() {
        #expect(ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: false, secondsRemaining: 10) == "Record shortcut")
    }

    @Test("capturing shows countdown")
    func captureButtonCapturing() {
        let title = ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: true, secondsRemaining: 7)
        #expect(title == "Listening… 7s")
    }

    @Test("capturing at zero")
    func captureButtonZero() {
        #expect(ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: true, secondsRemaining: 0) == "Listening… 0s")
    }

    // MARK: - hotkeyCaptureInstruction

    @Test("instruction with input monitoring")
    func instructionWithMonitoring() {
        let text = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: true, secondsRemaining: 5)
        #expect(text.contains("works even if another app is focused"))
        #expect(text.contains("5s left"))
    }

    @Test("instruction without input monitoring")
    func instructionWithoutMonitoring() {
        let text = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: false, secondsRemaining: 3)
        #expect(text.contains("Input Monitoring is missing"))
        #expect(text.contains("3s left"))
    }

    // MARK: - hotkeyCaptureProgress

    @Test("progress with zero total returns 0")
    func progressZeroTotal() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 0) == 0)
    }

    @Test("progress at full returns 1")
    func progressFull() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 10, totalSeconds: 10) == 1)
    }

    @Test("progress at half")
    func progressHalf() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 10) == 0.5)
    }

    @Test("progress clamps to 0")
    func progressClampsLow() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: -1, totalSeconds: 10) == 0)
    }

    @Test("progress clamps to 1")
    func progressClampsHigh() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 20, totalSeconds: 10) == 1)
    }

    // MARK: - hotkeyMissingPermissionSummary

    @Test("all authorized returns nil")
    func permissionsAllGranted() {
        #expect(ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: true, inputMonitoringAuthorized: true) == nil)
    }

    @Test("accessibility only missing")
    func permissionsAccessibilityMissing() {
        #expect(ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: false, inputMonitoringAuthorized: true) == "Accessibility")
    }

    @Test("input monitoring only missing")
    func permissionsInputMissing() {
        #expect(ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: true, inputMonitoringAuthorized: false) == "Input Monitoring")
    }

    @Test("both missing joined with plus")
    func permissionsBothMissing() {
        #expect(ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: false, inputMonitoringAuthorized: false) == "Accessibility + Input Monitoring")
    }

    // MARK: - showsAutoPastePermissionWarning

    @Test("auto paste off = no warning")
    func autoPasteOff() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: false, accessibilityAuthorized: false) == false)
    }

    @Test("auto paste on + accessibility = no warning")
    func autoPasteOnWithAccessibility() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: true) == false)
    }

    @Test("auto paste on + no accessibility = warning")
    func autoPasteOnNoAccessibility() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: false) == true)
    }

    // MARK: - insertionProbeStatus

    @Test("probe success")
    func probeSuccess() {
        #expect(ViewHelpers.insertionProbeStatus(succeeded: true) == .success)
    }

    @Test("probe failure")
    func probeFailure() {
        #expect(ViewHelpers.insertionProbeStatus(succeeded: false) == .failure)
    }

    @Test("probe unknown")
    func probeUnknown() {
        #expect(ViewHelpers.insertionProbeStatus(succeeded: nil) == .unknown)
    }

    // MARK: - runInsertionTestButtonTitle

    @Test("already running shows running text")
    func insertionTestRunning() {
        #expect(ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: true, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: false) == "Running insertion test…")
    }

    @Test("can run shows simple title")
    func insertionTestCanRun() {
        #expect(ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: false, canRunTest: true, autoCaptureTargetName: nil, canCaptureAndRun: false) == "Run insertion test")
    }

    @Test("auto-capture with target name")
    func insertionTestAutoCaptureName() {
        let title = ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: false, canRunTest: false, autoCaptureTargetName: "Safari", canCaptureAndRun: true)
        #expect(title == "Run insertion test (capture Safari)")
    }

    @Test("auto-capture without name")
    func insertionTestAutoCaptureNoName() {
        let title = ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: false, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: true)
        #expect(title == "Run insertion test (auto-capture)")
    }

    @Test("fallback title when nothing available")
    func insertionTestFallback() {
        #expect(ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: false, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: false) == "Run insertion test")
    }

    @Test("empty target name falls through to auto-capture")
    func insertionTestEmptyName() {
        let title = ViewHelpers.runInsertionTestButtonTitle(isRunningProbe: false, canRunTest: false, autoCaptureTargetName: "", canCaptureAndRun: true)
        #expect(title == "Run insertion test (auto-capture)")
    }

    // MARK: - canFocusInsertionTarget

    @Test("can focus when not recording and has target")
    func canFocusHappy() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: true) == true)
    }

    @Test("cannot focus when recording")
    func cannotFocusRecording() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: true, isFinalizingTranscription: false, hasInsertionTarget: true) == false)
    }

    @Test("cannot focus when finalizing")
    func cannotFocusFinalizing() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: true, hasInsertionTarget: true) == false)
    }

    @Test("cannot focus without target")
    func cannotFocusNoTarget() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: false) == false)
    }

    // MARK: - canClearInsertionTarget

    @Test("can clear when not probing and has target")
    func canClearHappy() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: true) == true)
    }

    @Test("cannot clear when probing")
    func cannotClearProbing() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: true, hasInsertionTarget: true) == false)
    }

    @Test("cannot clear without target")
    func cannotClearNoTarget() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: false) == false)
    }
}
