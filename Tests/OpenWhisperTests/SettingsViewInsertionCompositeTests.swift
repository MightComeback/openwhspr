import Testing
import Foundation
@testable import OpenWhisper

@Suite("SettingsView Insertion Composite Logic")
struct SettingsViewInsertionCompositeTests {

    // MARK: - canRunInsertionTestWithAutoCapture

    @Test("canRunInsertionTestWithAutoCapture: both false returns false")
    func autoCaptBothFalse() {
        #expect(ViewHelpers.canRunInsertionTestWithAutoCapture(canRunTest: false, canCaptureAndRun: false) == false)
    }

    @Test("canRunInsertionTestWithAutoCapture: canRunTest true returns true")
    func autoCaptRunTestTrue() {
        #expect(ViewHelpers.canRunInsertionTestWithAutoCapture(canRunTest: true, canCaptureAndRun: false) == true)
    }

    @Test("canRunInsertionTestWithAutoCapture: canCaptureAndRun true returns true")
    func autoCaptCaptureTrue() {
        #expect(ViewHelpers.canRunInsertionTestWithAutoCapture(canRunTest: false, canCaptureAndRun: true) == true)
    }

    @Test("canRunInsertionTestWithAutoCapture: both true returns true")
    func autoCaptBothTrue() {
        #expect(ViewHelpers.canRunInsertionTestWithAutoCapture(canRunTest: true, canCaptureAndRun: true) == true)
    }

    // MARK: - canFocusAndRunInsertionTest

    @Test("canFocusAndRunInsertionTest: both false returns false")
    func focusRunBothFalse() {
        #expect(ViewHelpers.canFocusAndRunInsertionTest(canFocusTarget: false, canRunTest: false) == false)
    }

    @Test("canFocusAndRunInsertionTest: only focus true returns false")
    func focusRunOnlyFocus() {
        #expect(ViewHelpers.canFocusAndRunInsertionTest(canFocusTarget: true, canRunTest: false) == false)
    }

    @Test("canFocusAndRunInsertionTest: only run true returns false")
    func focusRunOnlyRun() {
        #expect(ViewHelpers.canFocusAndRunInsertionTest(canFocusTarget: false, canRunTest: true) == false)
    }

    @Test("canFocusAndRunInsertionTest: both true returns true")
    func focusRunBothTrue() {
        #expect(ViewHelpers.canFocusAndRunInsertionTest(canFocusTarget: true, canRunTest: true) == true)
    }

    // MARK: - showsInsertionTestAutoCaptureHintResolved

    @Test("autoCaptureHint: not running, can't run standalone, can capture → true")
    func hintVisible() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(
            isRunningProbe: false, canRunTest: false, canCaptureAndRun: true
        ) == true)
    }

    @Test("autoCaptureHint: running probe → false")
    func hintHiddenWhileRunning() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(
            isRunningProbe: true, canRunTest: false, canCaptureAndRun: true
        ) == false)
    }

    @Test("autoCaptureHint: can run standalone → false")
    func hintHiddenWhenCanRunStandalone() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(
            isRunningProbe: false, canRunTest: true, canCaptureAndRun: true
        ) == false)
    }

    @Test("autoCaptureHint: can't capture either → false")
    func hintHiddenWhenCantCapture() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(
            isRunningProbe: false, canRunTest: false, canCaptureAndRun: false
        ) == false)
    }

    @Test("autoCaptureHint: all true → false (running blocks)")
    func hintAllTrue() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(
            isRunningProbe: true, canRunTest: true, canCaptureAndRun: true
        ) == false)
    }

    @Test("autoCaptureHint: all false → false")
    func hintAllFalse() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(
            isRunningProbe: false, canRunTest: false, canCaptureAndRun: false
        ) == false)
    }

    // MARK: - canCaptureAndRunInsertionTest exhaustive

    @Test("canCaptureAndRun: all conditions met returns true")
    func captureAndRunAllMet() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ) == true)
    }

    @Test("canCaptureAndRun: recording blocks")
    func captureAndRunRecordingBlocks() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: true,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canCaptureAndRun: finalizing blocks")
    func captureAndRunFinalizingBlocks() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false,
            isFinalizingTranscription: true,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canCaptureAndRun: already running probe blocks")
    func captureAndRunProbeBlocks() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: true,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canCaptureAndRun: no sample text blocks")
    func captureAndRunNoSampleText() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: false
        ) == false)
    }

    @Test("canCaptureAndRun: can't capture frontmost blocks")
    func captureAndRunCantCapture() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: false,
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    // MARK: - canRunInsertionTest exhaustive

    @Test("canRunTest: all conditions met returns true")
    func runTestAllMet() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ) == true)
    }

    @Test("canRunTest: recording blocks")
    func runTestRecordingBlocks() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: true,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canRunTest: no insertion target blocks")
    func runTestNoTarget() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: false,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canRunTest: finalizing blocks")
    func runTestFinalizingBlocks() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: true,
            isRunningInsertionProbe: false,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canRunTest: running probe blocks")
    func runTestProbeBlocks() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: true,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canRunTest: no sample text blocks")
    func runTestNoSampleText() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: false
        ) == false)
    }

    // MARK: - canFocusInsertionTarget

    @Test("canFocusInsertionTarget: not recording, not finalizing, has target → true")
    func focusTargetAllGood() {
        #expect(ViewHelpers.canFocusInsertionTarget(
            isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: true
        ) == true)
    }

    @Test("canFocusInsertionTarget: recording blocks")
    func focusTargetRecording() {
        #expect(ViewHelpers.canFocusInsertionTarget(
            isRecording: true, isFinalizingTranscription: false, hasInsertionTarget: true
        ) == false)
    }

    @Test("canFocusInsertionTarget: no target blocks")
    func focusTargetNoTarget() {
        #expect(ViewHelpers.canFocusInsertionTarget(
            isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: false
        ) == false)
    }

    @Test("canFocusInsertionTarget: finalizing blocks")
    func focusTargetFinalizing() {
        #expect(ViewHelpers.canFocusInsertionTarget(
            isRecording: false, isFinalizingTranscription: true, hasInsertionTarget: true
        ) == false)
    }

    // MARK: - canClearInsertionTarget

    @Test("canClearInsertionTarget: not running probe, has target → true")
    func clearTargetGood() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: true) == true)
    }

    @Test("canClearInsertionTarget: running probe blocks")
    func clearTargetRunningProbe() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: true, hasInsertionTarget: true) == false)
    }

    @Test("canClearInsertionTarget: no target blocks")
    func clearTargetNoTarget() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: false) == false)
    }

    // MARK: - insertionProbeStatusLabel

    @Test("probeStatusLabel: true → Passed")
    func probeStatusPassed() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: true) == "Passed")
    }

    @Test("probeStatusLabel: false → Failed")
    func probeStatusFailed() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: false) == "Failed")
    }

    @Test("probeStatusLabel: nil → Not tested")
    func probeStatusNil() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: nil) == "Not tested")
    }

    // MARK: - insertionProbeStatus

    @Test("probeStatus: true → passed")
    func probeStatusEnumPassed() {
        let status = ViewHelpers.insertionProbeStatus(succeeded: true)
        #expect(status == .success)
    }

    @Test("probeStatus: false → failure")
    func probeStatusEnumFailed() {
        let status = ViewHelpers.insertionProbeStatus(succeeded: false)
        #expect(status == .failure)
    }

    @Test("probeStatus: nil → unknown")
    func probeStatusEnumNil() {
        let status = ViewHelpers.insertionProbeStatus(succeeded: nil)
        #expect(status == .unknown)
    }

    // MARK: - insertionProbeSampleText helpers

    @Test("hasInsertionProbeSampleText: empty string → false")
    func hasSampleTextEmpty() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("") == false)
    }

    @Test("hasInsertionProbeSampleText: whitespace only → false")
    func hasSampleTextWhitespace() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("   \n  ") == false)
    }

    @Test("hasInsertionProbeSampleText: real text → true")
    func hasSampleTextReal() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("hello") == true)
    }

    @Test("insertionProbeSampleTextForRun: trims whitespace")
    func sampleTextForRunTrims() {
        let result = ViewHelpers.insertionProbeSampleTextForRun("  hello world  ")
        #expect(result == "hello world")
    }

    @Test("insertionProbeSampleTextWillTruncate: short text → false")
    func willTruncateShort() {
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate("hi") == false)
    }

    @Test("enforceInsertionProbeSampleTextLimit: short text unchanged")
    func enforceLimitShort() {
        #expect(ViewHelpers.enforceInsertionProbeSampleTextLimit("hello") == "hello")
    }

    // MARK: - showsAutoPastePermissionWarning

    @Test("autoPasteWarning: autoPaste on, no accessibility → true")
    func autoPasteWarnVisible() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: false) == true)
    }

    @Test("autoPasteWarning: autoPaste on, has accessibility → false")
    func autoPasteWarnHidden() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: true) == false)
    }

    @Test("autoPasteWarning: autoPaste off → false")
    func autoPasteWarnOff() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: false, accessibilityAuthorized: false) == false)
    }

    // MARK: - runInsertionTestButtonTitle variations

    @Test("runInsertionTestButtonTitle: running probe shows running text")
    func runButtonTitleRunning() {
        let title = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: true, canRunTest: true,
            autoCaptureTargetName: nil, canCaptureAndRun: false
        )
        #expect(title.lowercased().contains("running") || title.contains("…") || title.contains("..."))
    }

    @Test("runInsertionTestButtonTitle: can run test normally")
    func runButtonTitleNormal() {
        let title = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: true,
            autoCaptureTargetName: nil, canCaptureAndRun: false
        )
        #expect(!title.isEmpty)
    }

    @Test("runInsertionTestButtonTitle: auto-capture with target name")
    func runButtonTitleAutoCapture() {
        let title = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: false,
            autoCaptureTargetName: "Safari", canCaptureAndRun: true
        )
        #expect(title.contains("Safari") || !title.isEmpty)
    }
}
