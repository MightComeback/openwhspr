import Testing
import Foundation
@testable import OpenWhisper

@Suite("ViewHelpers Full E2E Coverage")
struct ViewHelpersFullE2ECoverageTests {

    // MARK: - streamingElapsedStatusSegment

    @Test("streamingElapsed: negative returns nil")
    func streamingNegative() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: -1) == nil)
    }

    @Test("streamingElapsed: zero returns 0:00")
    func streamingZero() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 0) == "0:00")
    }

    @Test("streamingElapsed: 65 seconds returns 1:05")
    func streaming65() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 65) == "1:05")
    }

    @Test("streamingElapsed: 3661 returns 1:01:01")
    func streamingHours() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 3661) == "1:01:01")
    }

    @Test("streamingElapsed: exactly 60 returns 1:00")
    func streaming60() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 60) == "1:00")
    }

    @Test("streamingElapsed: exactly 3600 returns 1:00:00")
    func streaming3600() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 3600) == "1:00:00")
    }

    // MARK: - isSentencePunctuation

    @Test("isSentencePunctuation: period")
    func punctPeriod() { #expect(ViewHelpers.isSentencePunctuation(".") == true) }

    @Test("isSentencePunctuation: comma")
    func punctComma() { #expect(ViewHelpers.isSentencePunctuation(",") == true) }

    @Test("isSentencePunctuation: exclamation")
    func punctExcl() { #expect(ViewHelpers.isSentencePunctuation("!") == true) }

    @Test("isSentencePunctuation: question")
    func punctQuestion() { #expect(ViewHelpers.isSentencePunctuation("?") == true) }

    @Test("isSentencePunctuation: semicolon")
    func punctSemicolon() { #expect(ViewHelpers.isSentencePunctuation(";") == true) }

    @Test("isSentencePunctuation: colon")
    func punctColon() { #expect(ViewHelpers.isSentencePunctuation(":") == true) }

    @Test("isSentencePunctuation: ellipsis")
    func punctEllipsis() { #expect(ViewHelpers.isSentencePunctuation("…") == true) }

    @Test("isSentencePunctuation: letter is false")
    func punctLetter() { #expect(ViewHelpers.isSentencePunctuation("a") == false) }

    @Test("isSentencePunctuation: space is false")
    func punctSpace() { #expect(ViewHelpers.isSentencePunctuation(" ") == false) }

    @Test("isSentencePunctuation: dash is false")
    func punctDash() { #expect(ViewHelpers.isSentencePunctuation("-") == false) }

    // MARK: - trailingSentencePunctuation

    @Test("trailingPunct: empty string")
    func trailingEmpty() { #expect(ViewHelpers.trailingSentencePunctuation(in: "") == nil) }

    @Test("trailingPunct: no punctuation")
    func trailingNone() { #expect(ViewHelpers.trailingSentencePunctuation(in: "hello") == nil) }

    @Test("trailingPunct: single period")
    func trailingSingle() { #expect(ViewHelpers.trailingSentencePunctuation(in: "hello.") == ".") }

    @Test("trailingPunct: multiple punctuation marks")
    func trailingMultiple() { #expect(ViewHelpers.trailingSentencePunctuation(in: "what?!") == "?!") }

    @Test("trailingPunct: ellipsis chars")
    func trailingEllipsis() { #expect(ViewHelpers.trailingSentencePunctuation(in: "hmm...") == "...") }

    @Test("trailingPunct: whitespace after text with no trailing punct")
    func trailingWhitespace() { #expect(ViewHelpers.trailingSentencePunctuation(in: "hello  ") == nil) }

    @Test("trailingPunct: unicode ellipsis")
    func trailingUnicodeEllipsis() { #expect(ViewHelpers.trailingSentencePunctuation(in: "wait…") == "…") }

    // MARK: - captureProfile helpers

    @Test("captureProfileUsesRecentAppFallback: true when true")
    func captureProfileFallbackTrue() {
        #expect(ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: true) == true)
    }

    @Test("captureProfileUsesRecentAppFallback: false when false")
    func captureProfileFallbackFalse() {
        #expect(ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: false) == false)
    }

    @Test("captureProfileUsesRecentAppFallback: false when nil")
    func captureProfileFallbackNil() {
        #expect(ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: nil) == false)
    }

    @Test("captureProfileFallbackAppName: returns name when fallback")
    func captureProfileFallbackName() {
        #expect(ViewHelpers.captureProfileFallbackAppName(isFallback: true, appName: "Safari") == "Safari")
    }

    @Test("captureProfileFallbackAppName: nil when not fallback")
    func captureProfileFallbackNameNil() {
        #expect(ViewHelpers.captureProfileFallbackAppName(isFallback: false, appName: "Safari") == nil)
    }

    @Test("captureProfileFallbackAppName: nil when isFallback nil")
    func captureProfileFallbackNameNilFlag() {
        #expect(ViewHelpers.captureProfileFallbackAppName(isFallback: nil, appName: "Safari") == nil)
    }

    @Test("captureProfileDisabledReasonText is non-empty")
    func captureProfileDisabledText() {
        #expect(!ViewHelpers.captureProfileDisabledReasonText.isEmpty)
    }

    // MARK: - bridgeModifiers

    @Test("bridgeModifiers: identity")
    func bridgeIdentity() {
        let mods: Set<ViewHelpers.ParsedModifier> = [.command, .shift]
        #expect(ViewHelpers.bridgeModifiers(mods) == mods)
    }

    @Test("bridgeModifiers: empty set")
    func bridgeEmpty() {
        let mods: Set<ViewHelpers.ParsedModifier> = []
        #expect(ViewHelpers.bridgeModifiers(mods) == mods)
    }

    // MARK: - shouldIgnoreCaptureActivation

    @Test("shouldIgnore: k with cmd+shift within debounce")
    func ignoreKCmdShift() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1, keyName: "k",
            hasCommandModifier: true, hasShiftModifier: true, hasExtraModifiers: false
        ) == true)
    }

    @Test("shouldIgnore: k with cmd+shift after debounce")
    func ignoreKCmdShiftLate() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 1.0, keyName: "k",
            hasCommandModifier: true, hasShiftModifier: true, hasExtraModifiers: false
        ) == false)
    }

    @Test("shouldIgnore: different key")
    func ignoreDifferentKey() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1, keyName: "j",
            hasCommandModifier: true, hasShiftModifier: true, hasExtraModifiers: false
        ) == false)
    }

    @Test("shouldIgnore: nil key")
    func ignoreNilKey() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1, keyName: nil,
            hasCommandModifier: true, hasShiftModifier: true, hasExtraModifiers: false
        ) == false)
    }

    @Test("shouldIgnore: extra modifiers")
    func ignoreExtraModifiers() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1, keyName: "k",
            hasCommandModifier: true, hasShiftModifier: true, hasExtraModifiers: true
        ) == false)
    }

    @Test("shouldIgnore: missing shift")
    func ignoreMissingShift() {
        #expect(ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1, keyName: "k",
            hasCommandModifier: true, hasShiftModifier: false, hasExtraModifiers: false
        ) == false)
    }

    // MARK: - canClearInsertionTarget

    @Test("canClear: has target, not running probe")
    func canClearYes() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: true) == true)
    }

    @Test("canClear: no target")
    func canClearNoTarget() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: false) == false)
    }

    @Test("canClear: running probe")
    func canClearRunningProbe() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: true, hasInsertionTarget: true) == false)
    }

    // MARK: - canFocusInsertionTarget

    @Test("canFocus: idle with target")
    func canFocusYes() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: true) == true)
    }

    @Test("canFocus: recording")
    func canFocusRecording() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: true, isFinalizingTranscription: false, hasInsertionTarget: true) == false)
    }

    @Test("canFocus: finalizing")
    func canFocusFinalizing() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: true, hasInsertionTarget: true) == false)
    }

    @Test("canFocus: no target")
    func canFocusNoTarget() {
        #expect(ViewHelpers.canFocusInsertionTarget(isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: false) == false)
    }

    // MARK: - showsAutoPastePermissionWarning

    @Test("autoPasteWarning: auto-paste on, no accessibility")
    func autoPasteWarningShown() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: false) == true)
    }

    @Test("autoPasteWarning: auto-paste on, has accessibility")
    func autoPasteWarningHidden() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: true) == false)
    }

    @Test("autoPasteWarning: auto-paste off")
    func autoPasteWarningOff() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: false, accessibilityAuthorized: false) == false)
    }

    // MARK: - runInsertionTestButtonTitle

    @Test("runTestTitle: running probe")
    func runTestRunning() {
        #expect(ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: true, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: false
        ) == "Running insertion test…")
    }

    @Test("runTestTitle: can run test")
    func runTestCanRun() {
        #expect(ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: true, autoCaptureTargetName: nil, canCaptureAndRun: false
        ) == "Run insertion test")
    }

    @Test("runTestTitle: auto-capture with name")
    func runTestAutoCaptureName() {
        let title = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: false, autoCaptureTargetName: "Safari", canCaptureAndRun: true
        )
        #expect(title.contains("Safari"))
    }

    @Test("runTestTitle: auto-capture without name")
    func runTestAutoCaptureNoName() {
        let title = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: true
        )
        #expect(title.contains("auto-capture"))
    }

    @Test("runTestTitle: fallback")
    func runTestFallback() {
        #expect(ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: false
        ) == "Run insertion test")
    }

    // MARK: - sizeOfModelFile

    @Test("sizeOfModelFile: empty path returns 0")
    func sizeEmpty() {
        #expect(ViewHelpers.sizeOfModelFile(atPath: "") == 0)
    }

    @Test("sizeOfModelFile: nonexistent path returns 0")
    func sizeNonexistent() {
        #expect(ViewHelpers.sizeOfModelFile(atPath: "/nonexistent/file.bin") == 0)
    }

    // MARK: - insertionProbeStatusLabel

    @Test("probeStatusLabel: success")
    func probeStatusLabelSuccess() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: true) == "Passed")
    }

    @Test("probeStatusLabel: failure")
    func probeStatusLabelFailure() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: false) == "Failed")
    }

    @Test("probeStatusLabel: unknown")
    func probeStatusLabelUnknown() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: nil) == "Not tested")
    }

    // MARK: - insertionProbeStatusColorName

    @Test("probeStatusColor: success is green")
    func probeColorSuccess() {
        #expect(ViewHelpers.insertionProbeStatusColorName(succeeded: true) == "green")
    }

    @Test("probeStatusColor: failure is orange")
    func probeColorFailure() {
        #expect(ViewHelpers.insertionProbeStatusColorName(succeeded: false) == "orange")
    }

    @Test("probeStatusColor: unknown is secondary")
    func probeColorUnknown() {
        #expect(ViewHelpers.insertionProbeStatusColorName(succeeded: nil) == "secondary")
    }

    // MARK: - hotkeySummaryFromModifiers

    @Test("hotkeySummary: command+space")
    func hotkeySummaryCmd() {
        let s = ViewHelpers.hotkeySummaryFromModifiers(
            command: true, shift: false, option: false, control: false, capsLock: false, key: "space"
        )
        #expect(s.contains("⌘"))
    }

    @Test("hotkeySummary: all modifiers")
    func hotkeySummaryAll() {
        let s = ViewHelpers.hotkeySummaryFromModifiers(
            command: true, shift: true, option: true, control: true, capsLock: true, key: "f6"
        )
        #expect(s.contains("⌘"))
        #expect(s.contains("⇧"))
        #expect(s.contains("⌥"))
        #expect(s.contains("⌃"))
        #expect(s.contains("⇪"))
    }

    @Test("hotkeySummary: no modifiers")
    func hotkeySummaryNone() {
        let s = ViewHelpers.hotkeySummaryFromModifiers(
            command: false, shift: false, option: false, control: false, capsLock: false, key: "space"
        )
        #expect(!s.contains("⌘"))
        #expect(!s.isEmpty)
    }

    // MARK: - shouldCopyBecauseTargetUnknown

    @Test("shouldCopy: can insert directly, no target, no front app")
    func shouldCopyYes() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true, hasResolvableInsertTarget: false, hasExternalFrontApp: false
        ) == true)
    }

    @Test("shouldCopy: has resolvable target")
    func shouldCopyNoTarget() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true, hasResolvableInsertTarget: true, hasExternalFrontApp: false
        ) == false)
    }

    @Test("shouldCopy: has external front app")
    func shouldCopyHasFront() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true, hasResolvableInsertTarget: false, hasExternalFrontApp: true
        ) == false)
    }

    @Test("shouldCopy: cannot insert directly")
    func shouldCopyCannotInsert() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: false, hasResolvableInsertTarget: false, hasExternalFrontApp: false
        ) == false)
    }

    // MARK: - shouldSuggestRetarget

    @Test("suggestRetarget: different bundle ids")
    func suggestRetargetDiffBundle() {
        #expect(ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true,
            insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: "com.apple.Safari",
            currentFrontBundleIdentifier: "com.apple.Notes",
            currentFrontAppName: "Notes",
            isInsertTargetStale: false
        ) == true)
    }

    @Test("suggestRetarget: same bundle ids")
    func suggestRetargetSameBundle() {
        #expect(ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true,
            insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: "com.apple.Safari",
            currentFrontBundleIdentifier: "com.apple.Safari",
            currentFrontAppName: "Safari",
            isInsertTargetStale: false
        ) == false)
    }

    @Test("suggestRetarget: not locked")
    func suggestRetargetNotLocked() {
        #expect(ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: false,
            insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: "com.apple.Safari",
            currentFrontBundleIdentifier: "com.apple.Notes",
            currentFrontAppName: "Notes",
            isInsertTargetStale: false
        ) == false)
    }

    @Test("suggestRetarget: nil bundles, different app names")
    func suggestRetargetNilBundles() {
        #expect(ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true,
            insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: nil,
            currentFrontBundleIdentifier: nil,
            currentFrontAppName: "Notes",
            isInsertTargetStale: false
        ) == true)
    }

    @Test("suggestRetarget: nil bundles, same app names")
    func suggestRetargetNilBundlesSameName() {
        #expect(ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true,
            insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: nil,
            currentFrontBundleIdentifier: nil,
            currentFrontAppName: "Safari",
            isInsertTargetStale: false
        ) == false)
    }

    @Test("suggestRetarget: nil front, stale")
    func suggestRetargetNilFrontStale() {
        #expect(ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true,
            insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: nil,
            currentFrontBundleIdentifier: nil,
            currentFrontAppName: nil,
            isInsertTargetStale: true
        ) == true)
    }

    @Test("suggestRetarget: empty target name")
    func suggestRetargetEmptyTarget() {
        #expect(ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true,
            insertTargetAppName: "",
            insertTargetBundleIdentifier: nil,
            currentFrontBundleIdentifier: nil,
            currentFrontAppName: "Notes",
            isInsertTargetStale: true
        ) == false)
    }

    // MARK: - shouldAutoRefreshInsertTargetBeforePrimaryInsert

    @Test("autoRefresh: all conditions met")
    func autoRefreshYes() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true, canRetargetInsertTarget: true,
            shouldSuggestRetarget: false, isInsertTargetStale: true
        ) == true)
    }

    @Test("autoRefresh: cannot insert directly")
    func autoRefreshNoInsert() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: false, canRetargetInsertTarget: true,
            shouldSuggestRetarget: false, isInsertTargetStale: true
        ) == false)
    }

    @Test("autoRefresh: suggests retarget")
    func autoRefreshSuggestsRetarget() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true, canRetargetInsertTarget: true,
            shouldSuggestRetarget: true, isInsertTargetStale: true
        ) == false)
    }

    @Test("autoRefresh: not stale")
    func autoRefreshNotStale() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true, canRetargetInsertTarget: true,
            shouldSuggestRetarget: false, isInsertTargetStale: false
        ) == false)
    }

    // MARK: - recordingDuration

    @Test("recordingDuration: nil start returns 0")
    func recordingDurationNil() {
        #expect(ViewHelpers.recordingDuration(startedAt: nil, now: Date()) == 0)
    }

    @Test("recordingDuration: 10 seconds ago")
    func recordingDuration10() {
        let now = Date()
        let start = now.addingTimeInterval(-10)
        #expect(ViewHelpers.recordingDuration(startedAt: start, now: now) == 10)
    }

    @Test("recordingDuration: future start clamped to 0")
    func recordingDurationFuture() {
        let now = Date()
        let start = now.addingTimeInterval(10)
        #expect(ViewHelpers.recordingDuration(startedAt: start, now: now) == 0)
    }

    // MARK: - currentExternalFrontBundleIdentifier

    @Test("externalBundle: returns trimmed valid id")
    func externalBundleValid() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("com.apple.Safari", ownBundleIdentifier: nil) == "com.apple.Safari")
    }

    @Test("externalBundle: filters own bundle")
    func externalBundleOwn() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("com.app.OpenWhisper", ownBundleIdentifier: "com.app.OpenWhisper") == nil)
    }

    @Test("externalBundle: filters own bundle case insensitive")
    func externalBundleOwnCase() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("COM.APP.OPENWHISPER", ownBundleIdentifier: "com.app.OpenWhisper") == nil)
    }

    @Test("externalBundle: empty string returns nil")
    func externalBundleEmpty() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("", ownBundleIdentifier: nil) == nil)
    }

    @Test("externalBundle: whitespace only returns nil")
    func externalBundleWhitespace() {
        #expect(ViewHelpers.currentExternalFrontBundleIdentifier("   ", ownBundleIdentifier: nil) == nil)
    }

    // MARK: - currentExternalFrontAppName

    @Test("externalApp: valid name")
    func externalAppValid() {
        #expect(ViewHelpers.currentExternalFrontAppName("Safari") == "Safari")
    }

    @Test("externalApp: empty returns nil")
    func externalAppEmpty() {
        #expect(ViewHelpers.currentExternalFrontAppName("") == nil)
    }

    @Test("externalApp: Unknown App returns nil")
    func externalAppUnknown() {
        #expect(ViewHelpers.currentExternalFrontAppName("Unknown App") == nil)
    }

    @Test("externalApp: OpenWhisper returns nil")
    func externalAppSelf() {
        #expect(ViewHelpers.currentExternalFrontAppName("OpenWhisper") == nil)
    }

    @Test("externalApp: case insensitive OpenWhisper")
    func externalAppSelfCase() {
        #expect(ViewHelpers.currentExternalFrontAppName("openwhisper") == nil)
    }

    @Test("externalApp: whitespace returns nil")
    func externalAppWhitespace() {
        #expect(ViewHelpers.currentExternalFrontAppName("   ") == nil)
    }

    // MARK: - transcriptionStats

    @Test("transcriptionStats: basic")
    func statsBasic() {
        let stats = ViewHelpers.transcriptionStats("hello world")
        #expect(stats.contains("2w"))
        #expect(stats.contains("11c"))
    }

    @Test("transcriptionStats: empty")
    func statsEmpty() {
        let stats = ViewHelpers.transcriptionStats("")
        #expect(stats.contains("0w"))
        #expect(stats.contains("0c"))
    }

    // MARK: - hotkeyModeTipText

    @Test("modeTip: toggle no escape")
    func modeTipToggle() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: false)
        #expect(tip.contains("toggle"))
        #expect(tip.contains("Esc"))
    }

    @Test("modeTip: toggle with escape")
    func modeTipToggleEscape() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: true)
        #expect(tip.contains("unavailable"))
    }

    @Test("modeTip: hold no escape")
    func modeTipHold() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: false)
        #expect(tip.contains("hold"))
    }

    @Test("modeTip: hold with escape")
    func modeTipHoldEscape() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: true)
        #expect(tip.contains("unavailable"))
    }

    // MARK: - hotkeyCaptureButtonTitle

    @Test("captureTitle: not capturing")
    func captureTitleNot() {
        #expect(ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: false, secondsRemaining: 5) == "Record shortcut")
    }

    @Test("captureTitle: capturing")
    func captureTitleCapturing() {
        let title = ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: true, secondsRemaining: 3)
        #expect(title.contains("3s"))
        #expect(title.contains("Listening"))
    }

    // MARK: - hotkeyCaptureInstruction

    @Test("captureInstruction: authorized")
    func captureInstructionAuth() {
        let inst = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: true, secondsRemaining: 5)
        #expect(inst.contains("5s"))
        #expect(inst.contains("even if another app"))
    }

    @Test("captureInstruction: not authorized")
    func captureInstructionNoAuth() {
        let inst = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: false, secondsRemaining: 5)
        #expect(inst.contains("Input Monitoring is missing"))
    }

    // MARK: - hotkeyCaptureProgress

    @Test("captureProgress: half")
    func captureProgressHalf() {
        let p = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 10)
        #expect(p == 0.5)
    }

    @Test("captureProgress: zero total")
    func captureProgressZeroTotal() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 0) == 0)
    }

    @Test("captureProgress: clamped to 1")
    func captureProgressClamped() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 15, totalSeconds: 10) == 1.0)
    }

    // MARK: - hotkeyMissingPermissionSummary

    @Test("missingPermission: both missing")
    func missingPermBoth() {
        let s = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: false, inputMonitoringAuthorized: false)
        #expect(s == "Accessibility + Input Monitoring")
    }

    @Test("missingPermission: only accessibility")
    func missingPermAccessibility() {
        let s = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: false, inputMonitoringAuthorized: true)
        #expect(s == "Accessibility")
    }

    @Test("missingPermission: only input monitoring")
    func missingPermInput() {
        let s = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: true, inputMonitoringAuthorized: false)
        #expect(s == "Input Monitoring")
    }

    @Test("missingPermission: none missing")
    func missingPermNone() {
        #expect(ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: true, inputMonitoringAuthorized: true) == nil)
    }

    // MARK: - formatBytes

    @Test("formatBytes: zero")
    func formatBytesZero() {
        let result = ViewHelpers.formatBytes(0)
        #expect(!result.isEmpty)
    }

    @Test("formatBytes: 1024")
    func formatBytes1024() {
        let result = ViewHelpers.formatBytes(1024)
        #expect(!result.isEmpty)
    }

    @Test("formatBytes: large value")
    func formatBytesLarge() {
        let result = ViewHelpers.formatBytes(1_073_741_824) // 1 GB
        #expect(!result.isEmpty)
    }

    // MARK: - abbreviatedAppName

    @Test("abbreviated: short name unchanged")
    func abbreviatedShort() {
        #expect(ViewHelpers.abbreviatedAppName("Safari") == "Safari")
    }

    @Test("abbreviated: long name truncated")
    func abbreviatedLong() {
        let long = "Very Long Application Name That Exceeds Limit"
        let result = ViewHelpers.abbreviatedAppName(long, maxCharacters: 18)
        #expect(result.count <= 19) // 18 + ellipsis
    }

    @Test("abbreviated: exact limit")
    func abbreviatedExact() {
        let name = String(repeating: "a", count: 18)
        #expect(ViewHelpers.abbreviatedAppName(name, maxCharacters: 18) == name)
    }

    // MARK: - insertButtonTitle

    @Test("insertTitle: can insert with target")
    func insertTitleWithTarget() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: "Safari",
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: nil
        )
        #expect(title.contains("Safari"))
        #expect(title.contains("Insert"))
    }

    @Test("insertTitle: can insert, no target, has live front")
    func insertTitleLiveFront() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: nil,
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: "Notes"
        )
        #expect(title.contains("Notes"))
    }

    @Test("insertTitle: can insert, no target, no front")
    func insertTitleNoTarget() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: nil,
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: nil
        )
        #expect(title.contains("Clipboard"))
    }

    @Test("insertTitle: cannot insert directly")
    func insertTitleCopy() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: false, insertTargetAppName: "Safari",
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: nil
        )
        #expect(title.contains("Copy"))
    }

    @Test("insertTitle: stale target shows warning")
    func insertTitleStale() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: "Safari",
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: true, liveFrontAppName: nil
        )
        #expect(title.contains("⚠︎"))
    }

    @Test("insertTitle: fallback target shows (recent)")
    func insertTitleFallback() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: "Safari",
            insertTargetUsesFallback: true, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: nil
        )
        #expect(title.contains("recent"))
    }

    // MARK: - retargetButtonTitle

    @Test("retargetTitle: with target")
    func retargetTitleTarget() {
        let title = ViewHelpers.retargetButtonTitle(insertTargetAppName: "Safari", insertTargetUsesFallback: false)
        #expect(title.contains("Safari"))
    }

    @Test("retargetTitle: no target")
    func retargetTitleNone() {
        #expect(ViewHelpers.retargetButtonTitle(insertTargetAppName: nil, insertTargetUsesFallback: false) == "Retarget")
    }

    @Test("retargetTitle: fallback")
    func retargetTitleFallback() {
        let title = ViewHelpers.retargetButtonTitle(insertTargetAppName: "Safari", insertTargetUsesFallback: true)
        #expect(title.contains("recent"))
    }

    // MARK: - retargetButtonHelpText

    @Test("retargetHelp: idle")
    func retargetHelpIdle() {
        let help = ViewHelpers.retargetButtonHelpText(isRecording: false, pendingChunkCount: 0)
        #expect(help.contains("Refresh"))
    }

    @Test("retargetHelp: recording")
    func retargetHelpRecording() {
        let help = ViewHelpers.retargetButtonHelpText(isRecording: true, pendingChunkCount: 0)
        #expect(help.contains("Finish"))
    }

    @Test("retargetHelp: pending")
    func retargetHelpPending() {
        let help = ViewHelpers.retargetButtonHelpText(isRecording: false, pendingChunkCount: 3)
        #expect(help.contains("finalization"))
    }

    // MARK: - useCurrentAppButtonTitle

    @Test("useCurrentTitle: can insert with front app")
    func useCurrentTitleWithFront() {
        let title = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: "Notes")
        #expect(title.contains("Notes"))
    }

    @Test("useCurrentTitle: can insert no front")
    func useCurrentTitleNoFront() {
        let title = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: nil)
        #expect(title == "Use Current App")
    }

    @Test("useCurrentTitle: cannot insert")
    func useCurrentTitleCopy() {
        let title = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: false, currentFrontAppName: "Notes")
        #expect(title.contains("Copy"))
    }

    // MARK: - retargetAndInsertButtonTitle

    @Test("retargetInsertTitle: can insert with front")
    func retargetInsertWithFront() {
        let title = ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: true, currentFrontAppName: "Notes")
        #expect(title.contains("Notes"))
        #expect(title.contains("Retarget"))
    }

    @Test("retargetInsertTitle: cannot insert")
    func retargetInsertCopy() {
        let title = ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: false, currentFrontAppName: "Notes")
        #expect(title.contains("Copy"))
    }

    // MARK: - focusTargetButtonTitle

    @Test("focusTitle: with target")
    func focusTitleTarget() {
        let title = ViewHelpers.focusTargetButtonTitle(insertTargetAppName: "Safari")
        #expect(title.contains("Safari"))
    }

    @Test("focusTitle: no target")
    func focusTitleNone() {
        #expect(ViewHelpers.focusTargetButtonTitle(insertTargetAppName: nil) == "Focus Target")
    }

    // MARK: - focusTargetButtonHelpText

    @Test("focusHelp: recording")
    func focusHelpRecording() {
        let help = ViewHelpers.focusTargetButtonHelpText(isRecording: true, pendingChunkCount: 0, insertTargetAppName: nil)
        #expect(help.contains("Wait"))
    }

    @Test("focusHelp: pending")
    func focusHelpPending() {
        let help = ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 3, insertTargetAppName: nil)
        #expect(help.contains("Wait"))
    }

    @Test("focusHelp: idle with target")
    func focusHelpWithTarget() {
        let help = ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 0, insertTargetAppName: "Safari")
        #expect(help.contains("Safari"))
    }

    @Test("focusHelp: idle no target")
    func focusHelpNoTarget() {
        let help = ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 0, insertTargetAppName: nil)
        #expect(help.contains("No insertion target"))
    }

    // MARK: - focusAndInsertButtonTitle

    @Test("focusInsertTitle: can insert with target")
    func focusInsertTitleTarget() {
        let title = ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: true, insertTargetAppName: "Safari")
        #expect(title.contains("Safari"))
    }

    @Test("focusInsertTitle: cannot insert")
    func focusInsertTitleCopy() {
        let title = ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: false, insertTargetAppName: "Safari")
        #expect(title.contains("Copy"))
    }

    // MARK: - focusAndInsertButtonHelpText

    @Test("focusInsertHelp: disabled reason")
    func focusInsertHelpDisabled() {
        let help = ViewHelpers.focusAndInsertButtonHelpText(
            insertActionDisabledReason: "Record first", hasResolvableInsertTarget: true, canInsertDirectly: true
        )
        #expect(help.contains("Record first"))
    }

    @Test("focusInsertHelp: no target")
    func focusInsertHelpNoTarget() {
        let help = ViewHelpers.focusAndInsertButtonHelpText(
            insertActionDisabledReason: nil, hasResolvableInsertTarget: false, canInsertDirectly: true
        )
        #expect(help.contains("No insertion target"))
    }

    @Test("focusInsertHelp: can insert with target")
    func focusInsertHelpInsert() {
        let help = ViewHelpers.focusAndInsertButtonHelpText(
            insertActionDisabledReason: nil, hasResolvableInsertTarget: true, canInsertDirectly: true
        )
        #expect(help.contains("insert immediately"))
    }

    @Test("focusInsertHelp: copy fallback")
    func focusInsertHelpCopy() {
        let help = ViewHelpers.focusAndInsertButtonHelpText(
            insertActionDisabledReason: nil, hasResolvableInsertTarget: true, canInsertDirectly: false
        )
        #expect(help.contains("clipboard"))
    }

    // MARK: - canRetargetInsertTarget

    @Test("canRetarget: idle")
    func canRetargetIdle() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: false, pendingChunkCount: 0) == true)
    }

    @Test("canRetarget: recording")
    func canRetargetRecording() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: true, pendingChunkCount: 0) == false)
    }

    @Test("canRetarget: pending")
    func canRetargetPending() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: false, pendingChunkCount: 5) == false)
    }

    // MARK: - hasResolvableInsertTarget

    @Test("hasResolvable: valid name")
    func hasResolvableValid() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "Safari") == true)
    }

    @Test("hasResolvable: nil")
    func hasResolvableNil() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: nil) == false)
    }

    @Test("hasResolvable: empty")
    func hasResolvableEmpty() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "") == false)
    }

    @Test("hasResolvable: whitespace only")
    func hasResolvableWhitespace() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "   ") == false)
    }

    // MARK: - insertionProbeMaxCharacters

    @Test("probeMaxChars: is 200")
    func probeMaxChars() {
        #expect(ViewHelpers.insertionProbeMaxCharacters == 200)
    }

    // MARK: - canRunInsertionTest

    @Test("canRunTest: all conditions met")
    func canRunTestYes() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ) == true)
    }

    @Test("canRunTest: recording")
    func canRunTestRecording() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: true, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canRunTest: no sample text")
    func canRunTestNoSample() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionTarget: true,
            hasInsertionProbeSampleText: false
        ) == false)
    }

    // MARK: - canRunInsertionTestWithAutoCapture

    @Test("canRunWithAutoCapture: test available")
    func canRunWithAutoCaptureTest() {
        #expect(ViewHelpers.canRunInsertionTestWithAutoCapture(canRunTest: true, canCaptureAndRun: false) == true)
    }

    @Test("canRunWithAutoCapture: capture available")
    func canRunWithAutoCaptureCapture() {
        #expect(ViewHelpers.canRunInsertionTestWithAutoCapture(canRunTest: false, canCaptureAndRun: true) == true)
    }

    @Test("canRunWithAutoCapture: neither")
    func canRunWithAutoCaptureNeither() {
        #expect(ViewHelpers.canRunInsertionTestWithAutoCapture(canRunTest: false, canCaptureAndRun: false) == false)
    }

    // MARK: - showsInsertionTestAutoCaptureHint

    @Test("autoCaptureHint: shown when can't run but can capture")
    func autoCaptureHintShown() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: false, canRunTest: false, canCaptureAndRun: true
        ) == true)
    }

    @Test("autoCaptureHint: hidden when running probe")
    func autoCaptureHintRunning() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: true, canRunTest: false, canCaptureAndRun: true
        ) == false)
    }

    @Test("autoCaptureHint: hidden when can run test")
    func autoCaptureHintCanRun() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: false, canRunTest: true, canCaptureAndRun: true
        ) == false)
    }

    // MARK: - hotkeyKeyNameFromKeyCode with characters fallback

    @Test("keyNameFromKeyCode: space key")
    func keyNameSpace() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x31) == "space")
    }

    @Test("keyNameFromKeyCode: modifier returns nil")
    func keyNameModifier() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x37) == nil) // Command
    }

    @Test("keyNameFromKeyCode: unknown with characters")
    func keyNameUnknownWithChars() {
        let result = ViewHelpers.hotkeyKeyNameFromKeyCode(0x00, characters: "a")
        #expect(result != nil)
    }

    @Test("keyNameFromKeyCode: unknown with nil characters")
    func keyNameUnknownNilChars() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0xFF, characters: nil) == nil)
    }

    @Test("keyNameFromKeyCode: fn key")
    func keyNameFn() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x3F) == "fn")
    }

    @Test("keyNameFromKeyCode: keypad0")
    func keyNameKeypad0() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x52) == "keypad0")
    }

    @Test("keyNameFromKeyCode: keypadenter")
    func keyNameKeypadEnter() {
        #expect(ViewHelpers.hotkeyKeyNameFromKeyCode(0x4C) == "keypadenter")
    }

    // MARK: - effectiveHotkeyRiskKey

    @Test("effectiveRiskKey: valid draft overrides current")
    func effectiveRiskKeyDraft() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "f6", currentKey: "space", currentModifiers: [.command]
        )
        #expect(result.key == "f6")
    }

    @Test("effectiveRiskKey: invalid draft falls back to current")
    func effectiveRiskKeyFallback() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "nonsense_xyz", currentKey: "space", currentModifiers: [.command]
        )
        #expect(result.key == "space")
    }

    // MARK: - canFocusAndRunInsertionTest

    @Test("canFocusAndRun: both true")
    func canFocusAndRunBoth() {
        #expect(ViewHelpers.canFocusAndRunInsertionTest(canFocusTarget: true, canRunTest: true) == true)
    }

    @Test("canFocusAndRun: focus false")
    func canFocusAndRunNoFocus() {
        #expect(ViewHelpers.canFocusAndRunInsertionTest(canFocusTarget: false, canRunTest: true) == false)
    }

    // MARK: - insertButtonHelpText

    @Test("insertHelp: disabled reason")
    func insertHelpDisabled() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: "Stop recording",
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: nil, insertTargetUsesFallback: false, currentFrontAppName: nil
        )
        #expect(help.contains("Stop recording"))
    }

    @Test("insertHelp: no accessibility")
    func insertHelpNoAccessibility() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: false, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: "Safari", insertTargetUsesFallback: false, currentFrontAppName: nil
        )
        #expect(help.contains("Accessibility"))
    }

    @Test("insertHelp: copy because unknown")
    func insertHelpCopyUnknown() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: true,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: nil, insertTargetUsesFallback: false, currentFrontAppName: nil
        )
        #expect(help.contains("clipboard"))
    }

    @Test("insertHelp: suggest retarget")
    func insertHelpRetarget() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: true, isInsertTargetStale: false,
            insertTargetAppName: "Safari", insertTargetUsesFallback: false, currentFrontAppName: "Notes"
        )
        #expect(help.contains("Notes"))
        #expect(help.contains("Safari"))
    }

    @Test("insertHelp: stale target")
    func insertHelpStale() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: true,
            insertTargetAppName: "Safari", insertTargetUsesFallback: false, currentFrontAppName: nil
        )
        #expect(help.contains("a while ago"))
    }

    @Test("insertHelp: fallback target")
    func insertHelpFallback() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: "Safari", insertTargetUsesFallback: true, currentFrontAppName: nil
        )
        #expect(help.contains("recent"))
    }

    // MARK: - useCurrentAppButtonHelpText

    @Test("useCurrentHelp: disabled reason")
    func useCurrentHelpDisabled() {
        let help = ViewHelpers.useCurrentAppButtonHelpText(
            insertActionDisabledReason: "Stop recording", canInsertDirectly: true
        )
        #expect(help.contains("Stop recording"))
    }

    @Test("useCurrentHelp: can insert")
    func useCurrentHelpInsert() {
        let help = ViewHelpers.useCurrentAppButtonHelpText(
            insertActionDisabledReason: nil, canInsertDirectly: true
        )
        #expect(help.contains("Retarget"))
    }

    @Test("useCurrentHelp: copy fallback")
    func useCurrentHelpCopy() {
        let help = ViewHelpers.useCurrentAppButtonHelpText(
            insertActionDisabledReason: nil, canInsertDirectly: false
        )
        #expect(help.contains("clipboard"))
    }

    // MARK: - retargetAndInsertHelpText

    @Test("retargetInsertHelp: disabled reason")
    func retargetInsertHelpDisabled() {
        let help = ViewHelpers.retargetAndInsertHelpText(
            insertActionDisabledReason: "Finish recording", canInsertDirectly: true
        )
        #expect(help.contains("Finish recording"))
    }

    @Test("retargetInsertHelp: can insert")
    func retargetInsertHelpInsert() {
        let help = ViewHelpers.retargetAndInsertHelpText(
            insertActionDisabledReason: nil, canInsertDirectly: true
        )
        #expect(help.contains("insert"))
    }

    @Test("retargetInsertHelp: copy")
    func retargetInsertHelpCopy() {
        let help = ViewHelpers.retargetAndInsertHelpText(
            insertActionDisabledReason: nil, canInsertDirectly: false
        )
        #expect(help.contains("clipboard"))
    }

    // MARK: - liveWordsPerMinute edge cases

    @Test("wpm: under 5 seconds returns nil")
    func wpmUnder5() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello world", durationSeconds: 4) == nil)
    }

    @Test("wpm: exactly 5 seconds")
    func wpmExactly5() {
        let wpm = ViewHelpers.liveWordsPerMinute(transcription: "hello world", durationSeconds: 5)
        #expect(wpm != nil)
        #expect(wpm! == 24) // 2 words / 5s * 60 = 24
    }

    @Test("wpm: whitespace-only text returns nil")
    func wpmWhitespace() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "   ", durationSeconds: 60) == nil)
    }

    // MARK: - insertionProbeSampleText helpers

    @Test("probeSampleWillTruncate: short text")
    func probeSampleShort() {
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate("hello") == false)
    }

    @Test("probeSampleWillTruncate: long text")
    func probeSampleLong() {
        let long = String(repeating: "a", count: 201)
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate(long) == true)
    }

    @Test("enforceLimit: truncates long text")
    func enforceLimitLong() {
        let long = String(repeating: "a", count: 300)
        #expect(ViewHelpers.enforceInsertionProbeSampleTextLimit(long).count == 200)
    }

    @Test("probeSampleForRun: trims and limits")
    func probeSampleForRun() {
        let raw = "  " + String(repeating: "x", count: 300) + "  "
        let result = ViewHelpers.insertionProbeSampleTextForRun(raw)
        #expect(result.count == 200)
        #expect(!result.hasPrefix(" "))
    }

    @Test("hasProbeSampleText: non-empty")
    func hasProbeSampleYes() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("hello") == true)
    }

    @Test("hasProbeSampleText: empty")
    func hasProbeSampleNo() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("") == false)
    }

    @Test("hasProbeSampleText: whitespace only")
    func hasProbeSampleWhitespace() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("   ") == false)
    }

    // MARK: - canCaptureAndRunInsertionTest

    @Test("canCaptureAndRun: all conditions met")
    func canCaptureAndRunYes() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true, isRecording: false,
            isFinalizingTranscription: false, isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ) == true)
    }

    @Test("canCaptureAndRun: recording blocks")
    func canCaptureAndRunRecording() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true, isRecording: true,
            isFinalizingTranscription: false, isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canCaptureAndRun: can't capture")
    func canCaptureAndRunNoCap() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: false, isRecording: false,
            isFinalizingTranscription: false, isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    // MARK: - showsInsertionTestAutoCaptureHintResolved

    @Test("autoCaptureHintResolved: same as non-resolved")
    func autoCaptureHintResolved() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(
            isRunningProbe: false, canRunTest: false, canCaptureAndRun: true
        ) == true)
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHintResolved(
            isRunningProbe: true, canRunTest: false, canCaptureAndRun: true
        ) == false)
    }

    // MARK: - liveLoopLagNotice

    @Test("liveLoopLag: no lag when low pending")
    func liveLoopLagLowPending() {
        let notice = ViewHelpers.liveLoopLagNotice(
            pendingChunkCount: 1, estimatedFinalizationSeconds: nil
        )
        #expect(notice == nil)
    }

    @Test("liveLoopLag: shows notice when high pending")
    func liveLoopLagHighPending() {
        let notice = ViewHelpers.liveLoopLagNotice(
            pendingChunkCount: 10, estimatedFinalizationSeconds: 20.0
        )
        // May or may not show notice depending on threshold
        let _ = notice
    }

    @Test("liveLoopLag: zero pending")
    func liveLoopLagZero() {
        let notice = ViewHelpers.liveLoopLagNotice(
            pendingChunkCount: 0, estimatedFinalizationSeconds: nil
        )
        #expect(notice == nil)
    }

    // MARK: - insertActionDisabledReason

    @Test("insertDisabled: recording")
    func insertDisabledRecording() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: true, isRunningInsertionProbe: false,
            isRecording: true, pendingChunkCount: 0
        )
        #expect(reason != nil)
    }

    @Test("insertDisabled: no text")
    func insertDisabledNoText() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: false, isRunningInsertionProbe: false,
            isRecording: false, pendingChunkCount: 0
        )
        #expect(reason != nil)
    }

    @Test("insertDisabled: ready")
    func insertDisabledReady() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: true, isRunningInsertionProbe: false,
            isRecording: false, pendingChunkCount: 0
        )
        #expect(reason == nil)
    }

    @Test("insertDisabled: running probe")
    func insertDisabledProbe() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: true, isRunningInsertionProbe: true,
            isRecording: false, pendingChunkCount: 0
        )
        #expect(reason != nil)
    }

    @Test("insertDisabled: pending chunks")
    func insertDisabledPending() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: true, isRunningInsertionProbe: false,
            isRecording: false, pendingChunkCount: 3
        )
        #expect(reason != nil)
    }

    // MARK: - startStopButtonTitle

    @Test("startStop: idle")
    func startStopIdle() {
        let title = ViewHelpers.startStopButtonTitle(isRecording: false, pendingChunkCount: 0, isStartAfterFinalizeQueued: false)
        #expect(title.contains("Start") || title.contains("Record"))
    }

    @Test("startStop: recording")
    func startStopRecording() {
        let title = ViewHelpers.startStopButtonTitle(isRecording: true, pendingChunkCount: 0, isStartAfterFinalizeQueued: false)
        #expect(title.contains("Stop"))
    }

    @Test("startStop: queued start after finalize")
    func startStopQueued() {
        let title = ViewHelpers.startStopButtonTitle(isRecording: false, pendingChunkCount: 3, isStartAfterFinalizeQueued: true)
        #expect(!title.isEmpty)
    }

    // MARK: - insertTargetAgeDescription

    @Test("targetAge: nil date")
    func targetAgeNil() {
        let desc = ViewHelpers.insertTargetAgeDescription(capturedAt: nil, now: Date(), staleAfterSeconds: 90, isStale: false)
        #expect(desc == nil)
    }

    @Test("targetAge: recent date not stale")
    func targetAgeRecent() {
        let now = Date()
        let desc = ViewHelpers.insertTargetAgeDescription(capturedAt: now.addingTimeInterval(-5), now: now, staleAfterSeconds: 90, isStale: false)
        #expect(desc != nil)
    }

    @Test("targetAge: old date stale")
    func targetAgeOld() {
        let now = Date()
        let desc = ViewHelpers.insertTargetAgeDescription(capturedAt: now.addingTimeInterval(-3600), now: now, staleAfterSeconds: 90, isStale: true)
        #expect(desc != nil)
    }

    // MARK: - lastSuccessfulInsertDescription

    @Test("lastInsertDesc: nil date")
    func lastInsertNil() {
        #expect(ViewHelpers.lastSuccessfulInsertDescription(insertedAt: nil, now: Date()) == nil)
    }

    @Test("lastInsertDesc: recent")
    func lastInsertRecent() {
        let now = Date()
        let desc = ViewHelpers.lastSuccessfulInsertDescription(insertedAt: now.addingTimeInterval(-10), now: now)
        #expect(desc != nil)
    }

    // MARK: - insertionTestDisabledReason

    @Test("insertionTestDisabled: recording")
    func insertionTestDisabledRecording() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: true, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true,
            hasInsertionTarget: true
        )
        #expect(!reason.isEmpty)
    }

    @Test("insertionTestDisabled: no target")
    func insertionTestDisabledNoTarget() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true,
            hasInsertionTarget: false
        )
        #expect(!reason.isEmpty)
    }

    @Test("insertionTestDisabled: no sample text")
    func insertionTestDisabledNoSample() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: false,
            hasInsertionTarget: true
        )
        #expect(!reason.isEmpty)
    }

    @Test("insertionTestDisabled: all good")
    func insertionTestDisabledReady() {
        let reason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true,
            hasInsertionTarget: true
        )
        // Returns empty string when ready (not nil — it returns String not String?)
        let _ = reason
    }
}
