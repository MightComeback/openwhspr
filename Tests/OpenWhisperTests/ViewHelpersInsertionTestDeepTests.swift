import Testing
import Foundation
@testable import OpenWhisper

@Suite("ViewHelpers — Insertion Test Deep Coverage")
struct ViewHelpersInsertionTestDeepTests {

    // MARK: - canRunInsertionTestWithAutoCapture

    @Test("canRunInsertionTestWithAutoCapture: both false → false")
    func autoCaptBothFalse() {
        #expect(ViewHelpers.canRunInsertionTestWithAutoCapture(canRunTest: false, canCaptureAndRun: false) == false)
    }

    @Test("canRunInsertionTestWithAutoCapture: canRunTest true only → true")
    func autoCaptRunOnly() {
        #expect(ViewHelpers.canRunInsertionTestWithAutoCapture(canRunTest: true, canCaptureAndRun: false) == true)
    }

    @Test("canRunInsertionTestWithAutoCapture: canCaptureAndRun true only → true")
    func autoCaptCaptureOnly() {
        #expect(ViewHelpers.canRunInsertionTestWithAutoCapture(canRunTest: false, canCaptureAndRun: true) == true)
    }

    @Test("canRunInsertionTestWithAutoCapture: both true → true")
    func autoCaptBothTrue() {
        #expect(ViewHelpers.canRunInsertionTestWithAutoCapture(canRunTest: true, canCaptureAndRun: true) == true)
    }

    // MARK: - canFocusAndRunInsertionTest

    @Test("canFocusAndRunInsertionTest: both true → true")
    func focusAndRunBothTrue() {
        #expect(ViewHelpers.canFocusAndRunInsertionTest(canFocusTarget: true, canRunTest: true) == true)
    }

    @Test("canFocusAndRunInsertionTest: canFocusTarget false → false")
    func focusAndRunNoFocus() {
        #expect(ViewHelpers.canFocusAndRunInsertionTest(canFocusTarget: false, canRunTest: true) == false)
    }

    @Test("canFocusAndRunInsertionTest: canRunTest false → false")
    func focusAndRunNoRun() {
        #expect(ViewHelpers.canFocusAndRunInsertionTest(canFocusTarget: true, canRunTest: false) == false)
    }

    @Test("canFocusAndRunInsertionTest: both false → false")
    func focusAndRunBothFalse() {
        #expect(ViewHelpers.canFocusAndRunInsertionTest(canFocusTarget: false, canRunTest: false) == false)
    }

    // MARK: - showsInsertionTestAutoCaptureHintResolved

    @Test("autoCaptureHintResolved: not running, can't run, can capture → true")
    func hintResolvedShowsHint() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(isRunningProbe: false, canRunTest: false, canCaptureAndRun: true) == true)
    }

    @Test("autoCaptureHintResolved: running probe → false")
    func hintResolvedRunningProbe() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(isRunningProbe: true, canRunTest: false, canCaptureAndRun: true) == false)
    }

    @Test("autoCaptureHintResolved: canRunTest true → false")
    func hintResolvedCanRun() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(isRunningProbe: false, canRunTest: true, canCaptureAndRun: true) == false)
    }

    @Test("autoCaptureHintResolved: can't capture → false")
    func hintResolvedCantCapture() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(isRunningProbe: false, canRunTest: false, canCaptureAndRun: false) == false)
    }

    @Test("autoCaptureHintResolved: all false → false")
    func hintResolvedAllFalse() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(isRunningProbe: false, canRunTest: false, canCaptureAndRun: false) == false)
    }

    @Test("autoCaptureHintResolved: all true → false")
    func hintResolvedAllTrue() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(isRunningProbe: true, canRunTest: true, canCaptureAndRun: true) == false)
    }

    // MARK: - showsInsertionTestAutoCaptureHint (duplicate logic, same contract)

    @Test("autoCaptureHint: shows when not running, can't run standalone, can auto-capture")
    func hintShows() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHint(isRunningProbe: false, canRunTest: false, canCaptureAndRun: true) == true)
    }

    @Test("autoCaptureHint: hidden when running probe")
    func hintHiddenRunning() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHint(isRunningProbe: true, canRunTest: false, canCaptureAndRun: true) == false)
    }

    @Test("autoCaptureHint: hidden when can run standalone")
    func hintHiddenCanRun() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHint(isRunningProbe: false, canRunTest: true, canCaptureAndRun: false) == false)
    }

    // MARK: - canCaptureAndRunInsertionTest

    @Test("canCaptureAndRun: all conditions met → true")
    func captureAndRunAllMet() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ) == true)
    }

    @Test("canCaptureAndRun: can't capture frontmost → false")
    func captureAndRunNoCaptureProfile() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: false,
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canCaptureAndRun: recording → false")
    func captureAndRunRecording() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: true,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canCaptureAndRun: finalizing → false")
    func captureAndRunFinalizing() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false,
            isFinalizingTranscription: true,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canCaptureAndRun: probe running → false")
    func captureAndRunProbeRunning() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: true,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canCaptureAndRun: no sample text → false")
    func captureAndRunNoSampleText() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: false
        ) == false)
    }

    // MARK: - canRunInsertionTest

    @Test("canRunInsertionTest: all conditions met → true")
    func runTestAllMet() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ) == true)
    }

    @Test("canRunInsertionTest: recording → false")
    func runTestRecording() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: true,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canRunInsertionTest: finalizing → false")
    func runTestFinalizing() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: true,
            isRunningInsertionProbe: false,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canRunInsertionTest: probe running → false")
    func runTestProbeRunning() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: true,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canRunInsertionTest: no insertion target → false")
    func runTestNoTarget() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: false,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canRunInsertionTest: no sample text → false")
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

    @Test("canFocusInsertionTarget: idle with target → true")
    func focusTargetIdle() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: true) == true)
    }

    @Test("canFocusInsertionTarget: recording → false")
    func focusTargetRecording() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: true, isFinalizingTranscription: false, hasInsertionTarget: true) == false)
    }

    @Test("canFocusInsertionTarget: finalizing → false")
    func focusTargetFinalizing() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: true, hasInsertionTarget: true) == false)
    }

    @Test("canFocusInsertionTarget: no target → false")
    func focusTargetNoTarget() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: false) == false)
    }

    // MARK: - canClearInsertionTarget

    @Test("canClearInsertionTarget: not probing with target → true")
    func clearTargetOk() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: true) == true)
    }

    @Test("canClearInsertionTarget: probing → false")
    func clearTargetProbing() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: true, hasInsertionTarget: true) == false)
    }

    @Test("canClearInsertionTarget: no target → false")
    func clearTargetNoTarget() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: false) == false)
    }

    // MARK: - shouldIgnoreCaptureActivation

    @Test("shouldIgnoreCaptureActivation: ⌘⇧K within threshold → true")
    func ignoreCaptureDebounce() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            debounceThreshold: 0.35,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == true)
    }

    @Test("shouldIgnoreCaptureActivation: past threshold → false")
    func ignoreCapturePassedThreshold() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.5,
            debounceThreshold: 0.35,
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
            debounceThreshold: 0.35,
            keyName: "space",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == false)
    }

    @Test("shouldIgnoreCaptureActivation: missing command modifier → false")
    func ignoreCaptureNoCommand() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            debounceThreshold: 0.35,
            keyName: "k",
            hasCommandModifier: false,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == false)
    }

    @Test("shouldIgnoreCaptureActivation: has extra modifiers → false")
    func ignoreCaptureExtraModifiers() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            debounceThreshold: 0.35,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: true
        ) == false)
    }

    @Test("shouldIgnoreCaptureActivation: nil keyName → false")
    func ignoreCaptureNilKey() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            debounceThreshold: 0.35,
            keyName: nil,
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == false)
    }

    @Test("shouldIgnoreCaptureActivation: exactly at threshold (inclusive) → true")
    func ignoreCaptureExactThreshold() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.35,
            debounceThreshold: 0.35,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        ) == true)
    }

    // MARK: - sizeOfModelFile

    @Test("sizeOfModelFile: empty path → 0")
    func sizeOfModelFileEmpty() {
        #expect(ViewHelpers.sizeOfModelFile(atPath: "") == 0)
    }

    @Test("sizeOfModelFile: nonexistent path → 0")
    func sizeOfModelFileNonexistent() {
        #expect(ViewHelpers.sizeOfModelFile(atPath: "/tmp/nonexistent-model-\(UUID().uuidString).bin") == 0)
    }

    @Test("sizeOfModelFile: existing file returns positive size")
    func sizeOfModelFileExisting() {
        let tmpFile = "/tmp/test-model-\(UUID().uuidString).bin"
        FileManager.default.createFile(atPath: tmpFile, contents: Data(repeating: 0, count: 1024))
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }
        let size = ViewHelpers.sizeOfModelFile(atPath: tmpFile)
        #expect(size == 1024)
    }

    // MARK: - insertionProbeStatusLabel

    @Test("insertionProbeStatusLabel: true → Passed")
    func probeStatusPassed() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: true) == "Passed")
    }

    @Test("insertionProbeStatusLabel: false → Failed")
    func probeStatusFailed() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: false) == "Failed")
    }

    @Test("insertionProbeStatusLabel: nil → Not tested")
    func probeStatusNil() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: nil) == "Not tested")
    }

    // MARK: - isSentencePunctuation

    @Test("isSentencePunctuation: period → true")
    func sentencePuncPeriod() {
        #expect(ViewHelpers.isSentencePunctuation(".") == true)
    }

    @Test("isSentencePunctuation: comma → true")
    func sentencePuncComma() {
        #expect(ViewHelpers.isSentencePunctuation(",") == true)
    }

    @Test("isSentencePunctuation: exclamation → true")
    func sentencePuncExclamation() {
        #expect(ViewHelpers.isSentencePunctuation("!") == true)
    }

    @Test("isSentencePunctuation: question mark → true")
    func sentencePuncQuestion() {
        #expect(ViewHelpers.isSentencePunctuation("?") == true)
    }

    @Test("isSentencePunctuation: semicolon → true")
    func sentencePuncSemicolon() {
        #expect(ViewHelpers.isSentencePunctuation(";") == true)
    }

    @Test("isSentencePunctuation: colon → true")
    func sentencePuncColon() {
        #expect(ViewHelpers.isSentencePunctuation(":") == true)
    }

    @Test("isSentencePunctuation: ellipsis → true")
    func sentencePuncEllipsis() {
        #expect(ViewHelpers.isSentencePunctuation("…") == true)
    }

    @Test("isSentencePunctuation: letter → false")
    func sentencePuncLetter() {
        #expect(ViewHelpers.isSentencePunctuation("a") == false)
    }

    @Test("isSentencePunctuation: space → false")
    func sentencePuncSpace() {
        #expect(ViewHelpers.isSentencePunctuation(" ") == false)
    }

    @Test("isSentencePunctuation: number → false")
    func sentencePuncNumber() {
        #expect(ViewHelpers.isSentencePunctuation("5") == false)
    }

    // MARK: - trailingSentencePunctuation

    @Test("trailingSentencePunctuation: text ending in period → '.'")
    func trailingPuncPeriod() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "Hello.") == ".")
    }

    @Test("trailingSentencePunctuation: text ending in '!?' → '!?'")
    func trailingPuncMultiple() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "What!?") == "!?")
    }

    @Test("trailingSentencePunctuation: text ending in ellipsis dots → '...'")
    func trailingPuncDots() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "Wait...") == "...")
    }

    @Test("trailingSentencePunctuation: no trailing punctuation → nil")
    func trailingPuncNone() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "Hello") == nil)
    }

    @Test("trailingSentencePunctuation: empty string → nil")
    func trailingPuncEmpty() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "") == nil)
    }

    @Test("trailingSentencePunctuation: whitespace only → nil")
    func trailingPuncWhitespace() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "   ") == nil)
    }

    @Test("trailingSentencePunctuation: trailing whitespace after punctuation")
    func trailingPuncWithWhitespace() {
        let result = ViewHelpers.trailingSentencePunctuation(in: "Hello.  ")
        #expect(result == ".")
    }

    @Test("trailingSentencePunctuation: single punctuation char → that char")
    func trailingPuncSingleChar() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "!") == "!")
    }

    // MARK: - streamingElapsedStatusSegment

    @Test("streamingElapsedStatusSegment: 0 seconds → '0:00'")
    func streamingElapsedZero() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 0) == "0:00")
    }

    @Test("streamingElapsedStatusSegment: 65 seconds → '1:05'")
    func streamingElapsed65() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 65) == "1:05")
    }

    @Test("streamingElapsedStatusSegment: 3661 seconds → '1:01:01'")
    func streamingElapsedHours() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 3661) == "1:01:01")
    }

    @Test("streamingElapsedStatusSegment: negative → nil")
    func streamingElapsedNegative() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: -1) == nil)
    }

    @Test("streamingElapsedStatusSegment: 59 seconds → '0:59'")
    func streamingElapsed59() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 59) == "0:59")
    }

    @Test("streamingElapsedStatusSegment: 3600 seconds → '1:00:00'")
    func streamingElapsedExactHour() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 3600) == "1:00:00")
    }

    // MARK: - effectiveHotkeyRiskKey

    @Test("effectiveHotkeyRiskKey: valid draft overrides current")
    func riskKeyValidDraft() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "f6",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(result.key == "f6")
    }

    @Test("effectiveHotkeyRiskKey: invalid draft falls back to current")
    func riskKeyInvalidDraft() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "not-a-key-!!!",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(result.key == "space")
    }

    @Test("effectiveHotkeyRiskKey: empty draft falls back to current")
    func riskKeyEmptyDraft() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "",
            currentKey: "tab",
            currentModifiers: [.option]
        )
        #expect(result.key == "tab")
    }

    @Test("effectiveHotkeyRiskKey: draft with modifiers overrides current modifiers")
    func riskKeyDraftWithModifiers() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "ctrl+space",
            currentKey: "tab",
            currentModifiers: [.command, .shift]
        )
        #expect(result.key == "space")
        #expect(result.requiredModifiers.contains(.control))
    }

    // MARK: - activeLanguageLabel

    @Test("activeLanguageLabel: 'auto' returns Auto-detect label")
    func langLabelAuto() {
        let label = ViewHelpers.activeLanguageLabel(for: "auto")
        #expect(label.lowercased().contains("auto"))
    }

    @Test("activeLanguageLabel: 'en' returns English label")
    func langLabelEn() {
        let label = ViewHelpers.activeLanguageLabel(for: "en")
        #expect(label.lowercased().contains("english") || label.contains("en"))
    }

    @Test("activeLanguageLabel: empty returns something")
    func langLabelEmpty() {
        let label = ViewHelpers.activeLanguageLabel(for: "")
        #expect(!label.isEmpty)
    }

    // MARK: - showsAutoPastePermissionWarning

    @Test("showsAutoPastePermissionWarning: autoPaste on, no accessibility → true")
    func autoPasteWarningShown() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: false) == true)
    }

    @Test("showsAutoPastePermissionWarning: autoPaste on, has accessibility → false")
    func autoPasteWarningNotShown() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: true) == false)
    }

    @Test("showsAutoPastePermissionWarning: autoPaste off → false")
    func autoPasteWarningOff() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: false, accessibilityAuthorized: false) == false)
    }
}
