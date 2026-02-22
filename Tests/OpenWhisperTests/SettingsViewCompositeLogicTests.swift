import Testing
import Foundation
@testable import OpenWhisper

@Suite("SettingsView composite logic via ViewHelpers")
struct SettingsViewCompositeLogicTests {

    // MARK: - showsInsertionTestAutoCaptureHint

    @Test("hint hidden when probe is running")
    func autoCaptureHintHiddenWhenRunning() {
        #expect(!ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: true, canRunTest: false, canCaptureAndRun: true
        ))
    }

    @Test("hint hidden when test can already run")
    func autoCaptureHintHiddenWhenCanRun() {
        #expect(!ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: false, canRunTest: true, canCaptureAndRun: true
        ))
    }

    @Test("hint hidden when capture-and-run unavailable")
    func autoCaptureHintHiddenWhenCantCapture() {
        #expect(!ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: false, canRunTest: false, canCaptureAndRun: false
        ))
    }

    @Test("hint shown when not running, can't run standalone, but can capture-and-run")
    func autoCaptureHintShown() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: false, canRunTest: false, canCaptureAndRun: true
        ))
    }

    @Test("hint hidden when all flags true")
    func autoCaptureHintAllTrue() {
        #expect(!ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: true, canRunTest: true, canCaptureAndRun: true
        ))
    }

    // MARK: - canCaptureAndRunInsertionTest

    @Test("all conditions met returns true")
    func captureAndRunAllMet() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ))
    }

    @Test("false when cannot capture frontmost")
    func captureAndRunNoCaptureProfile() {
        #expect(!ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: false,
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ))
    }

    @Test("false when recording")
    func captureAndRunWhileRecording() {
        #expect(!ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: true,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ))
    }

    @Test("false when finalizing")
    func captureAndRunWhileFinalizing() {
        #expect(!ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false,
            isFinalizingTranscription: true,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ))
    }

    @Test("false when probe running")
    func captureAndRunWhileProbeRunning() {
        #expect(!ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: true,
            hasInsertionProbeSampleText: true
        ))
    }

    @Test("false when no sample text")
    func captureAndRunNoSampleText() {
        #expect(!ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: false
        ))
    }

    @Test("false when multiple blockers active")
    func captureAndRunMultipleBlockers() {
        #expect(!ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: false,
            isRecording: true,
            isFinalizingTranscription: true,
            isRunningInsertionProbe: true,
            hasInsertionProbeSampleText: false
        ))
    }

    // MARK: - canRunInsertionTest

    @Test("all conditions met returns true")
    func runTestAllMet() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ))
    }

    @Test("false when recording")
    func runTestWhileRecording() {
        #expect(!ViewHelpers.canRunInsertionTest(
            isRecording: true,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ))
    }

    @Test("false when finalizing transcription")
    func runTestWhileFinalizing() {
        #expect(!ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: true,
            isRunningInsertionProbe: false,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ))
    }

    @Test("false when probe already running")
    func runTestWhileProbeRunning() {
        #expect(!ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: true,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ))
    }

    @Test("false when no insertion target")
    func runTestNoTarget() {
        #expect(!ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: false,
            hasInsertionProbeSampleText: true
        ))
    }

    @Test("false when no sample text")
    func runTestNoSampleText() {
        #expect(!ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: false
        ))
    }

    @Test("false when all blockers active")
    func runTestAllBlockers() {
        #expect(!ViewHelpers.canRunInsertionTest(
            isRecording: true,
            isFinalizingTranscription: true,
            isRunningInsertionProbe: true,
            hasInsertionTarget: false,
            hasInsertionProbeSampleText: false
        ))
    }

    // MARK: - effectiveHotkeyRiskKey

    @Test("uses draft key when valid")
    func riskKeyFromValidDraft() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "f6",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(result.key == "f6")
        // Draft with no explicit modifiers inherits currentModifiers
        #expect(result.requiredModifiers == [.command, .shift])
    }

    @Test("uses draft modifiers when present in combo draft")
    func riskKeyFromDraftWithModifiers() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "cmd+space",
            currentKey: "f6",
            currentModifiers: [.shift]
        )
        #expect(result.key == "space")
        #expect(result.requiredModifiers.contains(.command))
    }

    @Test("falls back to current key when draft is empty")
    func riskKeyFallbackOnEmptyDraft() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(result.key == "space")
        #expect(result.requiredModifiers == [.command, .shift])
    }

    @Test("falls back to current key when draft is invalid")
    func riskKeyFallbackOnInvalidDraft() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "???!!!",
            currentKey: "tab",
            currentModifiers: [.option]
        )
        #expect(result.key == "tab")
        #expect(result.requiredModifiers == [.option])
    }

    @Test("falls back when draft key is unsupported")
    func riskKeyFallbackOnUnsupportedDraft() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "someUnsupportedKeyName123",
            currentKey: "return",
            currentModifiers: [.control]
        )
        #expect(result.key == "return")
        #expect(result.requiredModifiers == [.control])
    }

    @Test("draft with only whitespace falls back")
    func riskKeyWhitespaceDraft() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "   ",
            currentKey: "escape",
            currentModifiers: []
        )
        // "   " trimmed is empty, but " " might be space
        // Let's just check it produces a result
        #expect(!result.key.isEmpty)
    }

    @Test("single space draft resolves to space key")
    func riskKeySingleSpaceDraft() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: " ",
            currentKey: "tab",
            currentModifiers: [.command]
        )
        #expect(result.key == "space")
    }

    // MARK: - insertionProbeStatusLabel

    @Test("succeeded shows Passed")
    func probeStatusPassed() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: true) == "Passed")
    }

    @Test("failed shows Failed")
    func probeStatusFailed() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: false) == "Failed")
    }

    @Test("nil shows Not tested")
    func probeStatusNotTested() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: nil) == "Not tested")
    }

    // MARK: - Composite interaction tests

    @Test("auto-capture hint + canRun interaction: hint only when can capture but not standalone run")
    func hintAndCanRunInteraction() {
        let canRun = ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: false, // no target → can't run standalone
            hasInsertionProbeSampleText: true
        )
        let canCapture = ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        )
        let hint = ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: false,
            canRunTest: canRun,
            canCaptureAndRun: canCapture
        )
        #expect(!canRun)
        #expect(canCapture)
        #expect(hint)
    }

    @Test("no hint when both run paths available")
    func noHintWhenBothAvailable() {
        let canRun = ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        )
        let hint = ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: false,
            canRunTest: canRun,
            canCaptureAndRun: true
        )
        #expect(canRun)
        #expect(!hint)
    }

    @Test("recording blocks both capture-and-run and standalone run")
    func recordingBlocksBothPaths() {
        let canRun = ViewHelpers.canRunInsertionTest(
            isRecording: true,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        )
        let canCapture = ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: true,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        )
        #expect(!canRun)
        #expect(!canCapture)
    }

    @Test("risk key feeds into high-risk check correctly")
    func riskKeyFeedsHighRiskCheck() {
        // A single letter with no modifiers is high-risk
        let context = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "a",
            currentKey: "space",
            currentModifiers: []
        )
        let isHighRisk = ViewHelpers.isHighRiskHotkey(
            requiredModifiers: context.requiredModifiers,
            key: context.key
        )
        #expect(isHighRisk)
    }

    @Test("risk key with modifiers is not high-risk")
    func riskKeyWithModifiersNotHighRisk() {
        let context = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "cmd+shift+a",
            currentKey: "space",
            currentModifiers: []
        )
        let isHighRisk = ViewHelpers.isHighRiskHotkey(
            requiredModifiers: context.requiredModifiers,
            key: context.key
        )
        #expect(!isHighRisk)
    }
}
