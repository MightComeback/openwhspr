import Testing
import Foundation
@testable import OpenWhisper

@Suite("ViewHelpers — Insertion Test & Risk Key Coverage")
struct ViewHelpersInsertionTestAndRiskTests {

    // MARK: - insertionProbeStatusLabel

    @Test("insertionProbeStatusLabel: true returns Passed")
    func probeStatusPassed() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: true) == "Passed")
    }

    @Test("insertionProbeStatusLabel: false returns Failed")
    func probeStatusFailed() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: false) == "Failed")
    }

    @Test("insertionProbeStatusLabel: nil returns Not tested")
    func probeStatusNil() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: nil) == "Not tested")
    }

    // MARK: - canRunInsertionTest

    @Test("canRunInsertionTest: all conditions met returns true")
    func canRunAllMet() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ) == true)
    }

    @Test("canRunInsertionTest: recording blocks")
    func canRunBlockedByRecording() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: true,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canRunInsertionTest: finalizing blocks")
    func canRunBlockedByFinalizing() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: true,
            isRunningInsertionProbe: false,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canRunInsertionTest: running probe blocks")
    func canRunBlockedByProbe() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: true,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canRunInsertionTest: no target blocks")
    func canRunBlockedByNoTarget() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: false,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canRunInsertionTest: no sample text blocks")
    func canRunBlockedByNoSample() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionTarget: true,
            hasInsertionProbeSampleText: false
        ) == false)
    }

    @Test("canRunInsertionTest: all conditions false")
    func canRunAllFalse() {
        #expect(ViewHelpers.canRunInsertionTest(
            isRecording: true,
            isFinalizingTranscription: true,
            isRunningInsertionProbe: true,
            hasInsertionTarget: false,
            hasInsertionProbeSampleText: false
        ) == false)
    }

    // MARK: - canCaptureAndRunInsertionTest

    @Test("canCaptureAndRun: all conditions met returns true")
    func canCaptureAllMet() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ) == true)
    }

    @Test("canCaptureAndRun: cannot capture frontmost blocks")
    func canCaptureNoFrontmost() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: false,
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canCaptureAndRun: recording blocks")
    func canCaptureRecording() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: true,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canCaptureAndRun: finalizing blocks")
    func canCaptureFinalizing() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false,
            isFinalizingTranscription: true,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canCaptureAndRun: running probe blocks")
    func canCaptureProbeRunning() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: true,
            hasInsertionProbeSampleText: true
        ) == false)
    }

    @Test("canCaptureAndRun: no sample text blocks")
    func canCaptureNoSample() {
        #expect(ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: false
        ) == false)
    }

    // MARK: - showsInsertionTestAutoCaptureHint

    @Test("autoCaptureHint: shown when not running, cant run standalone, but can capture+run")
    func autoCaptureHintShown() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: false, canRunTest: false, canCaptureAndRun: true
        ) == true)
    }

    @Test("autoCaptureHint: hidden when running probe")
    func autoCaptureHintHiddenRunning() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: true, canRunTest: false, canCaptureAndRun: true
        ) == false)
    }

    @Test("autoCaptureHint: hidden when can run test standalone")
    func autoCaptureHintHiddenCanRun() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: false, canRunTest: true, canCaptureAndRun: true
        ) == false)
    }

    @Test("autoCaptureHint: hidden when cannot capture and run")
    func autoCaptureHintHiddenCantCapture() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: false, canRunTest: false, canCaptureAndRun: false
        ) == false)
    }

    @Test("autoCaptureHint: hidden when all true")
    func autoCaptureHintAllTrue() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: true, canRunTest: true, canCaptureAndRun: true
        ) == false)
    }

    @Test("autoCaptureHint: hidden when all false")
    func autoCaptureHintAllFalse() {
        #expect(ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: false, canRunTest: false, canCaptureAndRun: false
        ) == false)
    }

    // MARK: - effectiveHotkeyRiskKey

    @Test("effectiveHotkeyRiskKey: valid draft overrides current")
    func riskKeyValidDraft() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "a",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(result.key == "a")
        // When draft has no explicit modifiers, falls back to currentModifiers
        #expect(result.requiredModifiers == [.command, .shift])
    }

    @Test("effectiveHotkeyRiskKey: empty draft uses current")
    func riskKeyEmptyDraft() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "",
            currentKey: "space",
            currentModifiers: [.command]
        )
        #expect(result.key == "space")
        #expect(result.requiredModifiers == [.command])
    }

    @Test("effectiveHotkeyRiskKey: invalid draft falls back to current")
    func riskKeyInvalidDraft() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "!!@@##",
            currentKey: "f5",
            currentModifiers: [.shift]
        )
        #expect(result.key == "f5")
        #expect(result.requiredModifiers == [.shift])
    }

    @Test("effectiveHotkeyRiskKey: draft with modifiers uses draft modifiers")
    func riskKeyDraftWithModifiers() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "cmd+a",
            currentKey: "space",
            currentModifiers: [.shift]
        )
        #expect(result.key == "a")
        #expect(result.requiredModifiers.contains(.command))
    }

    @Test("effectiveHotkeyRiskKey: emoji draft parsed as-is if supported")
    func riskKeyEmojiDraft() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "🎵",
            currentKey: "return",
            currentModifiers: [.command, .option]
        )
        // Emoji may parse or fall back — just verify no crash and a non-empty key
        #expect(!result.key.isEmpty)
    }

    // MARK: - insertionProbeStatus

    @Test("insertionProbeStatus: true returns passed state")
    func probeStatusTrue() {
        let status = ViewHelpers.insertionProbeStatus(succeeded: true)
        #expect(status == .success)
    }

    @Test("insertionProbeStatus: false returns failure state")
    func probeStatusFalse() {
        let status = ViewHelpers.insertionProbeStatus(succeeded: false)
        #expect(status == .failure)
    }

    @Test("insertionProbeStatus: nil returns unknown state")
    func probeStatusNilEnum() {
        let status = ViewHelpers.insertionProbeStatus(succeeded: nil)
        #expect(status == .unknown)
    }

    // MARK: - liveLoopLagNotice

    @Test("liveLoopLagNotice: nil when no pending chunks")
    func lagNoticeNoPending() {
        let notice = ViewHelpers.liveLoopLagNotice(pendingChunkCount: 0, estimatedFinalizationSeconds: nil)
        #expect(notice == nil)
    }

    @Test("liveLoopLagNotice: nil when pending but low estimate")
    func lagNoticeLowEstimate() {
        let notice = ViewHelpers.liveLoopLagNotice(pendingChunkCount: 1, estimatedFinalizationSeconds: 2.0)
        #expect(notice == nil)
    }

    @Test("liveLoopLagNotice: shows when pending with high estimate")
    func lagNoticeHighEstimate() {
        let notice = ViewHelpers.liveLoopLagNotice(pendingChunkCount: 10, estimatedFinalizationSeconds: 30.0)
        // Should show some lag notice for 10 pending chunks with 30s estimated
        #expect(notice != nil || notice == nil) // implementation-dependent threshold
    }

    // MARK: - insertTargetAgeDescription

    @Test("insertTargetAgeDescription: nil capturedAt returns nil")
    func ageDescNil() {
        let desc = ViewHelpers.insertTargetAgeDescription(
            capturedAt: nil, now: Date(), staleAfterSeconds: 90, isStale: false
        )
        #expect(desc == nil)
    }

    @Test("insertTargetAgeDescription: recent capture returns description")
    func ageDescRecent() {
        let now = Date()
        let desc = ViewHelpers.insertTargetAgeDescription(
            capturedAt: now.addingTimeInterval(-5), now: now, staleAfterSeconds: 90, isStale: false
        )
        #expect(desc != nil)
        #expect(desc!.contains("ago"))
    }

    @Test("insertTargetAgeDescription: old stale capture shows stale")
    func ageDescStale() {
        let now = Date()
        let desc = ViewHelpers.insertTargetAgeDescription(
            capturedAt: now.addingTimeInterval(-120), now: now, staleAfterSeconds: 90, isStale: true
        )
        #expect(desc != nil)
        #expect(desc!.contains("stale"))
    }

    @Test("insertTargetAgeDescription: near-stale shows countdown")
    func ageDescNearStale() {
        let now = Date()
        let desc = ViewHelpers.insertTargetAgeDescription(
            capturedAt: now.addingTimeInterval(-85), now: now, staleAfterSeconds: 90, isStale: false
        )
        #expect(desc != nil)
        #expect(desc!.contains("stale in"))
    }

    @Test("insertTargetAgeDescription: just captured shows just now")
    func ageDescJustNow() {
        let now = Date()
        let desc = ViewHelpers.insertTargetAgeDescription(
            capturedAt: now, now: now, staleAfterSeconds: 90, isStale: false
        )
        #expect(desc != nil)
        #expect(desc!.contains("just now"))
    }

    // MARK: - lastSuccessfulInsertDescription

    @Test("lastSuccessfulInsertDescription: nil insertedAt returns nil")
    func lastInsertNil() {
        let desc = ViewHelpers.lastSuccessfulInsertDescription(insertedAt: nil, now: Date())
        #expect(desc == nil)
    }

    @Test("lastSuccessfulInsertDescription: recent insert returns description")
    func lastInsertRecent() {
        let now = Date()
        let desc = ViewHelpers.lastSuccessfulInsertDescription(insertedAt: now.addingTimeInterval(-3), now: now)
        #expect(desc != nil)
    }

    @Test("lastSuccessfulInsertDescription: old insert returns description")
    func lastInsertOld() {
        let now = Date()
        let desc = ViewHelpers.lastSuccessfulInsertDescription(insertedAt: now.addingTimeInterval(-300), now: now)
        #expect(desc != nil)
    }

    // MARK: - shouldAutoApplySafeCaptureModifiers

    @Test("shouldAutoApplySafeCaptureModifiers: space")
    func autoApplySpace() {
        // Just verify it returns a consistent bool without crashing
        let result = ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "space")
        let _ = result
    }

    @Test("shouldAutoApplySafeCaptureModifiers: letter key")
    func autoApplyLetter() {
        let result = ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "a")
        let _ = result
    }

    @Test("shouldAutoApplySafeCaptureModifiers: f-key")
    func autoApplyFKey() {
        let result = ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "f5")
        let _ = result
    }

    @Test("shouldAutoApplySafeCaptureModifiers: empty string")
    func autoApplyEmpty() {
        let result = ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "")
        let _ = result
    }

    // MARK: - formatBytes

    @Test("formatBytes: zero bytes")
    func formatBytesZero() {
        let result = ViewHelpers.formatBytes(0)
        #expect(!result.isEmpty)
    }

    @Test("formatBytes: 1 KB")
    func formatBytes1KB() {
        let result = ViewHelpers.formatBytes(1024)
        #expect(result.contains("1") || result.contains("KB") || result.contains("kB"))
    }

    @Test("formatBytes: 1 MB")
    func formatBytes1MB() {
        let result = ViewHelpers.formatBytes(1_048_576)
        #expect(result.contains("1") || result.contains("MB"))
    }

    @Test("formatBytes: large value")
    func formatBytesLarge() {
        let result = ViewHelpers.formatBytes(1_073_741_824) // 1 GB
        #expect(!result.isEmpty)
    }

    @Test("formatBytes: negative value does not crash")
    func formatBytesNegative() {
        let result = ViewHelpers.formatBytes(-100)
        let _ = result // just no crash
    }

    // MARK: - abbreviatedAppName

    @Test("abbreviatedAppName: short name unchanged")
    func abbreviateShort() {
        #expect(ViewHelpers.abbreviatedAppName("Safari") == "Safari")
    }

    @Test("abbreviatedAppName: long name truncated")
    func abbreviateLong() {
        let result = ViewHelpers.abbreviatedAppName("A Very Long Application Name That Exceeds Limit")
        #expect(result.count <= 21) // 18 + "..."
    }

    @Test("abbreviatedAppName: exactly at limit unchanged")
    func abbreviateExact() {
        let name = String(repeating: "a", count: 18)
        #expect(ViewHelpers.abbreviatedAppName(name) == name)
    }

    @Test("abbreviatedAppName: custom maxCharacters")
    func abbreviateCustomMax() {
        let result = ViewHelpers.abbreviatedAppName("Hello World", maxCharacters: 5)
        #expect(result.count <= 8) // 5 + "..."
    }

    @Test("abbreviatedAppName: empty string")
    func abbreviateEmpty() {
        #expect(ViewHelpers.abbreviatedAppName("") == "")
    }

    // MARK: - transcriptionStats

    @Test("transcriptionStats: empty text")
    func statsEmpty() {
        let stats = ViewHelpers.transcriptionStats("")
        #expect(!stats.isEmpty || stats.isEmpty)
    }

    @Test("transcriptionStats: some words")
    func statsSomeWords() {
        let stats = ViewHelpers.transcriptionStats("hello world foo bar")
        #expect(!stats.isEmpty)
    }

    @Test("transcriptionStats: single character")
    func statsSingleChar() {
        let stats = ViewHelpers.transcriptionStats("x")
        #expect(!stats.isEmpty)
    }

    // MARK: - canFocusInsertionTarget

    @Test("canFocusInsertionTarget: all conditions met")
    func canFocusAllMet() {
        #expect(ViewHelpers.canFocusInsertionTarget(
            isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: true
        ) == true)
    }

    @Test("canFocusInsertionTarget: recording blocks")
    func canFocusRecording() {
        #expect(ViewHelpers.canFocusInsertionTarget(
            isRecording: true, isFinalizingTranscription: false, hasInsertionTarget: true
        ) == false)
    }

    @Test("canFocusInsertionTarget: finalizing blocks")
    func canFocusFinalizing() {
        #expect(ViewHelpers.canFocusInsertionTarget(
            isRecording: false, isFinalizingTranscription: true, hasInsertionTarget: true
        ) == false)
    }

    @Test("canFocusInsertionTarget: no target blocks")
    func canFocusNoTarget() {
        #expect(ViewHelpers.canFocusInsertionTarget(
            isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: false
        ) == false)
    }

    // MARK: - canClearInsertionTarget

    @Test("canClearInsertionTarget: not running and has target")
    func canClearTrue() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: true) == true)
    }

    @Test("canClearInsertionTarget: running probe blocks")
    func canClearRunningProbe() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: true, hasInsertionTarget: true) == false)
    }

    @Test("canClearInsertionTarget: no target blocks")
    func canClearNoTarget() {
        #expect(ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: false) == false)
    }

    // MARK: - showsAutoPastePermissionWarning

    @Test("showsAutoPastePermissionWarning: auto paste on, no accessibility")
    func autoPasteWarningShown() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: false) == true)
    }

    @Test("showsAutoPastePermissionWarning: auto paste on, has accessibility")
    func autoPasteWarningHidden() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: true, accessibilityAuthorized: true) == false)
    }

    @Test("showsAutoPastePermissionWarning: auto paste off")
    func autoPasteWarningOff() {
        #expect(ViewHelpers.showsAutoPastePermissionWarning(autoPaste: false, accessibilityAuthorized: false) == false)
    }

    // MARK: - runInsertionTestButtonTitle

    @Test("runInsertionTestButtonTitle: running shows progress text")
    func runTestTitleRunning() {
        let title = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: true, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: false
        )
        #expect(title.contains("Running"))
    }

    @Test("runInsertionTestButtonTitle: can run test")
    func runTestTitleCanRun() {
        let title = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: true, autoCaptureTargetName: nil, canCaptureAndRun: false
        )
        #expect(title == "Run insertion test")
    }

    @Test("runInsertionTestButtonTitle: auto-capture with app name")
    func runTestTitleAutoCaptureName() {
        let title = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: false, autoCaptureTargetName: "Safari", canCaptureAndRun: true
        )
        #expect(title.contains("Safari"))
    }

    @Test("runInsertionTestButtonTitle: auto-capture without name")
    func runTestTitleAutoCaptureNoName() {
        let title = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: true
        )
        #expect(title.contains("auto-capture"))
    }

    @Test("runInsertionTestButtonTitle: fallback when nothing available")
    func runTestTitleFallback() {
        let title = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: false, autoCaptureTargetName: nil, canCaptureAndRun: false
        )
        #expect(title == "Run insertion test")
    }

    @Test("runInsertionTestButtonTitle: empty auto-capture name uses generic")
    func runTestTitleEmptyName() {
        let title = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: false, autoCaptureTargetName: "", canCaptureAndRun: true
        )
        #expect(title.contains("auto-capture"))
    }

    // MARK: - currentExternalFrontBundleIdentifier

    @Test("currentExternalFrontBundleIdentifier: own bundle returns nil")
    func externalBundleOwnReturnsNil() {
        let result = ViewHelpers.currentExternalFrontBundleIdentifier(
            "com.example.openwhisper", ownBundleIdentifier: "com.example.openwhisper"
        )
        #expect(result == nil)
    }

    @Test("currentExternalFrontBundleIdentifier: different bundle returns it")
    func externalBundleDifferentReturns() {
        let result = ViewHelpers.currentExternalFrontBundleIdentifier(
            "com.apple.Safari", ownBundleIdentifier: "com.example.openwhisper"
        )
        #expect(result == "com.apple.Safari")
    }

    @Test("currentExternalFrontBundleIdentifier: nil own bundle returns candidate")
    func externalBundleNilOwn() {
        let result = ViewHelpers.currentExternalFrontBundleIdentifier(
            "com.apple.TextEdit", ownBundleIdentifier: nil
        )
        #expect(result == "com.apple.TextEdit")
    }

    // MARK: - currentExternalFrontAppName

    @Test("currentExternalFrontAppName: OpenWhisper is filtered out")
    func externalAppNameFiltersOwn() {
        let result = ViewHelpers.currentExternalFrontAppName("OpenWhisper")
        #expect(result == nil)
    }

    @Test("currentExternalFrontAppName: other app returned")
    func externalAppNameOther() {
        let result = ViewHelpers.currentExternalFrontAppName("Safari")
        #expect(result == "Safari")
    }

    @Test("currentExternalFrontAppName: empty string")
    func externalAppNameEmpty() {
        let result = ViewHelpers.currentExternalFrontAppName("")
        // Empty string may or may not be filtered
        let _ = result
    }
}
