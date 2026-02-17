import Testing
@testable import OpenWhisper

@Suite("ViewHelpers – Missing Coverage")
struct ViewHelpersMissingCoverageTests {

    // MARK: - hotkeyCaptureInstruction

    @Test("hotkeyCaptureInstruction: with input monitoring")
    func captureInstructionWithIM() {
        let result = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: true, secondsRemaining: 10)
        #expect(result.contains("Listening for the next key press"))
        #expect(result.contains("works even if another app"))
        #expect(result.contains("10s left"))
    }

    @Test("hotkeyCaptureInstruction: without input monitoring")
    func captureInstructionWithoutIM() {
        let result = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: false, secondsRemaining: 5)
        #expect(result.contains("in OpenWhisper only"))
        #expect(result.contains("Input Monitoring is missing"))
        #expect(result.contains("5s left"))
    }

    @Test("hotkeyCaptureInstruction: zero seconds remaining")
    func captureInstructionZeroSeconds() {
        let result = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: true, secondsRemaining: 0)
        #expect(result.contains("0s left"))
    }

    @Test("hotkeyCaptureInstruction: both paths mention Esc to cancel")
    func captureInstructionEscCancel() {
        let withIM = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: true, secondsRemaining: 3)
        let withoutIM = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: false, secondsRemaining: 3)
        #expect(withIM.contains("Esc to cancel"))
        #expect(withoutIM.contains("Esc to cancel"))
    }

    // MARK: - hotkeyModeTipText

    @Test("hotkeyModeTipText: toggle mode normal")
    func modeTipToggleNormal() {
        let result = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: false)
        #expect(result.contains("toggle mode"))
        #expect(result.contains("starts recording on the first press"))
        #expect(result.contains("Press Esc while recording to discard"))
    }

    @Test("hotkeyModeTipText: toggle mode with escape trigger")
    func modeTipToggleEscape() {
        let result = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: true)
        #expect(result.contains("toggle mode"))
        #expect(result.contains("Escape quick-cancel is unavailable"))
    }

    @Test("hotkeyModeTipText: hold mode normal")
    func modeTipHoldNormal() {
        let result = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: false)
        #expect(result.contains("hold-to-talk"))
        #expect(result.contains("stops on release"))
        #expect(result.contains("Press Esc while recording to discard"))
    }

    @Test("hotkeyModeTipText: hold mode with escape trigger")
    func modeTipHoldEscape() {
        let result = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: true)
        #expect(result.contains("hold-to-talk"))
        #expect(result.contains("Escape quick-cancel is unavailable"))
    }

    // MARK: - insertionTestDisabledReason

    @Test("insertionTestDisabledReason: recording")
    func insertionTestRecording() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: true, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true,
            hasInsertionTarget: true)
        #expect(reason.contains("Stop recording"))
    }

    @Test("insertionTestDisabledReason: finalizing")
    func insertionTestFinalizing() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: true,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true,
            hasInsertionTarget: true)
        #expect(reason.contains("finalizing"))
    }

    @Test("insertionTestDisabledReason: already running")
    func insertionTestAlreadyRunning() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: true, hasInsertionProbeSampleText: true,
            hasInsertionTarget: true)
        #expect(reason.contains("already running"))
    }

    @Test("insertionTestDisabledReason: no sample text")
    func insertionTestNoSampleText() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: false,
            hasInsertionTarget: true)
        #expect(reason.contains("empty"))
    }

    @Test("insertionTestDisabledReason: no target")
    func insertionTestNoTarget() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true,
            hasInsertionTarget: false)
        #expect(reason.contains("No destination app"))
    }

    @Test("insertionTestDisabledReason: priority order — recording takes precedence")
    func insertionTestPriority() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: true, isFinalizingTranscription: true,
            isRunningInsertionProbe: true, hasInsertionProbeSampleText: false,
            hasInsertionTarget: false)
        #expect(reason.contains("Stop recording"))
    }
}
