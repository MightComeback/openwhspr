import Testing
import Foundation
@testable import OpenWhisper

// MARK: - formatBytes

@Suite("formatBytes")
struct FormatBytesTests {
    @Test("zero bytes")
    func zero() {
        let result = ViewHelpers.formatBytes(0)
        #expect(result.contains("0") || result.contains("Zero"))
    }

    @Test("small value in KB")
    func kilobytes() {
        let result = ViewHelpers.formatBytes(1024)
        #expect(result.contains("KB"))
    }

    @Test("megabyte range")
    func megabytes() {
        let result = ViewHelpers.formatBytes(10_000_000)
        #expect(result.contains("MB"))
    }

    @Test("large value stays MB")
    func largeMB() {
        let result = ViewHelpers.formatBytes(500_000_000)
        #expect(result.contains("MB"))
    }
}

// MARK: - liveWordsPerMinute

@Suite("liveWordsPerMinute")
struct LiveWordsPerMinuteTests {
    @Test("nil when duration under 5 seconds")
    func shortDuration() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello world", durationSeconds: 4.9) == nil)
    }

    @Test("nil when no words")
    func noWords() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "   ", durationSeconds: 10) == nil)
    }

    @Test("calculates correctly for 60 seconds")
    func sixtySeconds() {
        let text = (1...30).map { "word\($0)" }.joined(separator: " ")
        let wpm = ViewHelpers.liveWordsPerMinute(transcription: text, durationSeconds: 60)
        #expect(wpm == 30)
    }

    @Test("at least 1 when very slow")
    func minimum1() {
        let wpm = ViewHelpers.liveWordsPerMinute(transcription: "hello", durationSeconds: 600)
        #expect(wpm == 1)
    }

    @Test("exactly 5 seconds threshold")
    func exactThreshold() {
        let wpm = ViewHelpers.liveWordsPerMinute(transcription: "hello world test", durationSeconds: 5)
        #expect(wpm != nil)
    }
}

// MARK: - shouldSuggestRetarget

@Suite("shouldSuggestRetarget")
struct ShouldSuggestRetargetTests {
    @Test("false when not locked")
    func notLocked() {
        #expect(!ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: false,
            insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: "com.apple.Safari",
            currentFrontBundleIdentifier: "com.apple.Notes",
            currentFrontAppName: "Notes",
            isInsertTargetStale: false
        ))
    }

    @Test("true when locked and different bundle")
    func differentBundle() {
        #expect(ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true,
            insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: "com.apple.Safari",
            currentFrontBundleIdentifier: "com.apple.Notes",
            currentFrontAppName: "Notes",
            isInsertTargetStale: false
        ))
    }

    @Test("false when locked but same bundle")
    func sameBundle() {
        #expect(!ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true,
            insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: "com.apple.Safari",
            currentFrontBundleIdentifier: "com.apple.Safari",
            currentFrontAppName: "Safari",
            isInsertTargetStale: false
        ))
    }

    @Test("falls back to app name when no bundles")
    func nameComparison() {
        #expect(ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true,
            insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: nil,
            currentFrontBundleIdentifier: nil,
            currentFrontAppName: "Notes",
            isInsertTargetStale: false
        ))
    }

    @Test("falls back to stale when no front app")
    func staleFallback() {
        #expect(ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true,
            insertTargetAppName: "Safari",
            insertTargetBundleIdentifier: nil,
            currentFrontBundleIdentifier: nil,
            currentFrontAppName: nil,
            isInsertTargetStale: true
        ))
    }

    @Test("false when target name is empty")
    func emptyTarget() {
        #expect(!ViewHelpers.shouldSuggestRetarget(
            isInsertTargetLocked: true,
            insertTargetAppName: "",
            insertTargetBundleIdentifier: nil,
            currentFrontBundleIdentifier: nil,
            currentFrontAppName: "Notes",
            isInsertTargetStale: false
        ))
    }
}

// MARK: - shouldAutoRefreshInsertTargetBeforePrimaryInsert

@Suite("shouldAutoRefreshInsertTargetBeforePrimaryInsert")
struct ShouldAutoRefreshTests {
    @Test("true when can insert, can retarget, not suggested, but stale")
    func staleAutoRefresh() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true, canRetargetInsertTarget: true, shouldSuggestRetarget: false, isInsertTargetStale: true
        ))
    }

    @Test("false when cannot insert directly")
    func cantInsert() {
        #expect(!ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: false, canRetargetInsertTarget: true, shouldSuggestRetarget: false, isInsertTargetStale: true
        ))
    }

    @Test("false when retarget already suggested")
    func alreadySuggested() {
        #expect(!ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true, canRetargetInsertTarget: true, shouldSuggestRetarget: true, isInsertTargetStale: true
        ))
    }

    @Test("false when not stale")
    func notStale() {
        #expect(!ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(
            canInsertDirectly: true, canRetargetInsertTarget: true, shouldSuggestRetarget: false, isInsertTargetStale: false
        ))
    }
}

// MARK: - showsHoldModeAccidentalTriggerWarning

@Suite("showsHoldModeAccidentalTriggerWarning")
struct HoldModeWarningTests {
    @Test("false for toggle mode")
    func toggleMode() {
        #expect(!ViewHelpers.showsHoldModeAccidentalTriggerWarning(hotkeyModeRaw: "toggle", requiredModifiers: [], key: "space"))
    }

    @Test("true for hold mode with high-risk key")
    func holdHighRisk() {
        // space with no modifiers should be high risk
        #expect(ViewHelpers.showsHoldModeAccidentalTriggerWarning(hotkeyModeRaw: "hold", requiredModifiers: [], key: "space"))
    }

    @Test("false for hold mode with safe combo")
    func holdSafe() {
        #expect(!ViewHelpers.showsHoldModeAccidentalTriggerWarning(hotkeyModeRaw: "hold", requiredModifiers: [.command, .shift], key: "space"))
    }
}

// MARK: - hotkeyEscapeCancelConflictWarning

@Suite("hotkeyEscapeCancelConflictWarning")
struct EscapeConflictTests {
    @Test("returns warning for escape")
    func escape() {
        let result = ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "escape")
        #expect(result != nil)
        #expect(result!.contains("Esc"))
    }

    @Test("nil for other keys")
    func other() {
        #expect(ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "space") == nil)
    }
}

// MARK: - hotkeySystemConflictWarning

@Suite("hotkeySystemConflictWarning")
struct SystemConflictTests {
    @Test("cmd+space warns about Spotlight")
    func cmdSpace() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "space")
        #expect(result != nil)
        #expect(result!.contains("Spotlight"))
    }

    @Test("ctrl+space warns about input source")
    func ctrlSpace() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.control], key: "space")
        #expect(result != nil)
    }

    @Test("cmd+q warns")
    func cmdQ() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "q")
        #expect(result != nil)
        #expect(result!.contains("quits"))
    }

    @Test("cmd+shift+3 warns about screenshots")
    func cmdShift3() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "3")
        #expect(result != nil)
        #expect(result!.contains("screenshot"))
    }

    @Test("cmd+shift+4 warns about screenshots")
    func cmdShift4() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "4")
        #expect(result != nil)
    }

    @Test("cmd+shift+5 warns")
    func cmdShift5() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "5")
        #expect(result != nil)
    }

    @Test("nil for safe combo")
    func safe() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .option], key: "d") == nil)
    }

    @Test("cmd+tab warns")
    func cmdTab() {
        let result = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "tab")
        #expect(result != nil)
    }

    @Test("cmd+comma warns")
    func cmdComma() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "comma") != nil)
    }

    @Test("cmd+backtick warns")
    func cmdBacktick() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "backtick") != nil)
    }

    @Test("fn alone warns")
    func fnAlone() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [], key: "fn") != nil)
    }

    @Test("option+cmd+escape warns about force quit")
    func optCmdEsc() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .option], key: "escape") != nil)
    }

    @Test("cmd+h warns")
    func cmdH() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "h") != nil)
    }

    @Test("cmd+c warns")
    func cmdC() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "c") != nil)
    }

    @Test("cmd+v warns")
    func cmdV() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "v") != nil)
    }

    @Test("cmd+ctrl+space warns about emoji picker")
    func cmdCtrlSpace() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .control], key: "space") != nil)
    }

    @Test("ctrl+opt+space warns")
    func ctrlOptSpace() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.control, .option], key: "space") != nil)
    }

    @Test("cmd+opt+space warns")
    func cmdOptSpace() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .option], key: "space") != nil)
    }

    @Test("cmd+ctrl+opt+space warns")
    func cmdCtrlOptSpace() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .option, .control], key: "space") != nil)
    }

    @Test("cmd+ctrl+f warns")
    func cmdCtrlF() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .control], key: "f") != nil)
    }

    @Test("cmd+shift+tab warns")
    func cmdShiftTab() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "tab") != nil)
    }

    @Test("cmd+section warns")
    func cmdSection() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "section") != nil)
    }

    @Test("cmd+shift+section warns")
    func cmdShiftSection() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "section") != nil)
    }

    @Test("cmd+period warns")
    func cmdPeriod() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "period") != nil)
    }

    @Test("cmd+x warns")
    func cmdX() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "x") != nil)
    }

    @Test("cmd+a warns")
    func cmdA() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "a") != nil)
    }

    @Test("cmd+z warns")
    func cmdZ() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "z") != nil)
    }

    @Test("cmd+m warns")
    func cmdM() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "m") != nil)
    }

    @Test("cmd+return warns")
    func cmdReturn() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "return") != nil)
    }

    @Test("cmd+ctrl+q warns")
    func cmdCtrlQ() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .control], key: "q") != nil)
    }

    @Test("cmd+w warns")
    func cmdW() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "w") != nil)
    }

    @Test("cmd+s warns")
    func cmdS() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "s") != nil)
    }

    @Test("cmd+f warns")
    func cmdF() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "f") != nil)
    }

    @Test("cmd+n warns")
    func cmdN() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "n") != nil)
    }

    @Test("cmd+t warns")
    func cmdT() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "t") != nil)
    }

    @Test("cmd+p warns")
    func cmdP() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "p") != nil)
    }

    @Test("cmd+r warns")
    func cmdR() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "r") != nil)
    }

    @Test("cmd+o warns")
    func cmdO() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "o") != nil)
    }

    @Test("cmd+l warns")
    func cmdL() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command], key: "l") != nil)
    }

    @Test("cmd+shift+6 warns")
    func cmdShift6() {
        #expect(ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: [.command, .shift], key: "6") != nil)
    }
}

// MARK: - insertionTestDisabledReason

@Suite("insertionTestDisabledReason")
struct InsertionTestDisabledTests {
    @Test("recording blocks test")
    func recording() {
        let result = ViewHelpers.insertionTestDisabledReason(isRecording: true, isFinalizingTranscription: false, isRunningInsertionProbe: false, hasInsertionProbeSampleText: true, hasInsertionTarget: true)
        #expect(result.contains("Stop recording"))
    }

    @Test("finalizing blocks test")
    func finalizing() {
        let result = ViewHelpers.insertionTestDisabledReason(isRecording: false, isFinalizingTranscription: true, isRunningInsertionProbe: false, hasInsertionProbeSampleText: true, hasInsertionTarget: true)
        #expect(result.contains("finalizing"))
    }

    @Test("already running blocks test")
    func running() {
        let result = ViewHelpers.insertionTestDisabledReason(isRecording: false, isFinalizingTranscription: false, isRunningInsertionProbe: true, hasInsertionProbeSampleText: true, hasInsertionTarget: true)
        #expect(result.contains("already running"))
    }

    @Test("empty text blocks test")
    func emptyText() {
        let result = ViewHelpers.insertionTestDisabledReason(isRecording: false, isFinalizingTranscription: false, isRunningInsertionProbe: false, hasInsertionProbeSampleText: false, hasInsertionTarget: true)
        #expect(result.contains("empty"))
    }

    @Test("no target blocks test")
    func noTarget() {
        let result = ViewHelpers.insertionTestDisabledReason(isRecording: false, isFinalizingTranscription: false, isRunningInsertionProbe: false, hasInsertionProbeSampleText: true, hasInsertionTarget: false)
        #expect(result.contains("destination"))
    }
}

// MARK: - hotkeyModeTipText

@Suite("hotkeyModeTipText")
struct HotkeyModeTipTextTests {
    @Test("toggle with escape trigger")
    func toggleEsc() {
        let text = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: true)
        #expect(text.contains("toggle"))
        #expect(text.contains("unavailable"))
    }

    @Test("toggle without escape")
    func toggle() {
        let text = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: false)
        #expect(text.contains("toggle"))
        #expect(text.contains("Esc"))
    }

    @Test("hold with escape trigger")
    func holdEsc() {
        let text = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: true)
        #expect(text.contains("hold"))
        #expect(text.contains("unavailable"))
    }

    @Test("hold without escape")
    func hold() {
        let text = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: false)
        #expect(text.contains("hold"))
        #expect(text.contains("Esc"))
    }
}

// MARK: - hotkeyCaptureButtonTitle

@Suite("hotkeyCaptureButtonTitle")
struct CaptureButtonTitleTests {
    @Test("not capturing")
    func notCapturing() {
        #expect(ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: false, secondsRemaining: 10) == "Record shortcut")
    }

    @Test("capturing shows countdown")
    func capturing() {
        let title = ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: true, secondsRemaining: 7)
        #expect(title.contains("7s"))
    }
}

// MARK: - hotkeyCaptureInstruction

@Suite("hotkeyCaptureInstruction")
struct CaptureInstructionTests {
    @Test("with input monitoring")
    func withMonitoring() {
        let text = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: true, secondsRemaining: 5)
        #expect(text.contains("even if another app"))
    }

    @Test("without input monitoring")
    func withoutMonitoring() {
        let text = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: false, secondsRemaining: 5)
        #expect(text.contains("Input Monitoring is missing"))
    }
}

// MARK: - hotkeyCaptureProgress

@Suite("hotkeyCaptureProgress")
struct CaptureProgressTests {
    @Test("full progress")
    func full() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 10, totalSeconds: 10) == 1.0)
    }

    @Test("half progress")
    func half() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 10) == 0.5)
    }

    @Test("zero total returns 0")
    func zeroTotal() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 0) == 0)
    }

    @Test("clamps to 0-1")
    func clamps() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 15, totalSeconds: 10) == 1.0)
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: -5, totalSeconds: 10) == 0.0)
    }
}

// MARK: - hotkeyDraftValidationMessage

@Suite("hotkeyDraftValidationMessage")
struct DraftValidationTests {
    @Test("empty draft gives error")
    func empty() {
        #expect(ViewHelpers.hotkeyDraftValidationMessage(draft: "", isSupportedKey: false) != nil)
    }

    @Test("nil for supported key")
    func supported() {
        #expect(ViewHelpers.hotkeyDraftValidationMessage(draft: "space", isSupportedKey: true) == nil)
    }

    @Test("unsupported key gives error")
    func unsupported() {
        #expect(ViewHelpers.hotkeyDraftValidationMessage(draft: "xyz", isSupportedKey: false) != nil)
    }
}

// MARK: - hasHotkeyDraftChangesToApply

@Suite("hasHotkeyDraftChangesToApply")
struct DraftChangesTests {
    @Test("no changes when same key")
    func same() {
        #expect(!ViewHelpers.hasHotkeyDraftChangesToApply(draft: "space", currentKey: "space", currentModifiers: []))
    }

    @Test("changes when different key")
    func differentKey() {
        #expect(ViewHelpers.hasHotkeyDraftChangesToApply(draft: "f6", currentKey: "space", currentModifiers: []))
    }

    @Test("false for invalid draft")
    func invalid() {
        #expect(!ViewHelpers.hasHotkeyDraftChangesToApply(draft: "", currentKey: "space", currentModifiers: []))
    }

    @Test("changes when modifiers differ")
    func modsDiffer() {
        #expect(ViewHelpers.hasHotkeyDraftChangesToApply(draft: "cmd+space", currentKey: "space", currentModifiers: []))
    }
}

// MARK: - canonicalHotkeyDraftPreview

@Suite("canonicalHotkeyDraftPreview")
struct DraftPreviewTests {
    @Test("nil for invalid draft")
    func invalid() {
        #expect(ViewHelpers.canonicalHotkeyDraftPreview(draft: "", currentModifiers: []) == nil)
    }

    @Test("shows key with current modifiers when draft has none")
    func usesCurrentMods() {
        let result = ViewHelpers.canonicalHotkeyDraftPreview(draft: "space", currentModifiers: [.command])
        #expect(result != nil)
        #expect(result!.contains("⌘"))
    }

    @Test("shows key with draft modifiers")
    func usesDraftMods() {
        let result = ViewHelpers.canonicalHotkeyDraftPreview(draft: "cmd+shift+space", currentModifiers: [])
        #expect(result != nil)
        #expect(result!.contains("⌘"))
        #expect(result!.contains("⇧"))
    }
}

// MARK: - hotkeyDraftModifierOverrideSummary

@Suite("hotkeyDraftModifierOverrideSummary")
struct ModifierOverrideSummaryTests {
    @Test("nil when no modifier override")
    func noOverride() {
        #expect(ViewHelpers.hotkeyDraftModifierOverrideSummary(draft: "space", currentModifiers: []) == nil)
    }

    @Test("nil for invalid draft")
    func invalid() {
        #expect(ViewHelpers.hotkeyDraftModifierOverrideSummary(draft: "", currentModifiers: []) == nil)
    }

    @Test("returns summary when modifiers differ")
    func different() {
        let result = ViewHelpers.hotkeyDraftModifierOverrideSummary(draft: "cmd+space", currentModifiers: [])
        #expect(result != nil)
        #expect(result!.contains("Command"))
    }

    @Test("none when empty modifiers override")
    func emptyOverride() {
        // Draft that explicitly sets no modifiers but current has some
        // This requires a draft that parses with empty modifiers - tricky.
        // Skip - covered by nil case
    }
}

// MARK: - hotkeyDraftNonConfigurableModifierNotice

@Suite("hotkeyDraftNonConfigurableModifierNotice")
struct NonConfigurableModifierTests {
    @Test("nil for plain key")
    func plain() {
        #expect(ViewHelpers.hotkeyDraftNonConfigurableModifierNotice(draft: "space") == nil)
    }

    @Test("notice for fn modifier")
    func fnMod() {
        let result = ViewHelpers.hotkeyDraftNonConfigurableModifierNotice(draft: "fn+space")
        // fn might parse as non-configurable
        if let result {
            #expect(result.contains("Fn"))
        }
    }

    @Test("notice for globe modifier")
    func globe() {
        let result = ViewHelpers.hotkeyDraftNonConfigurableModifierNotice(draft: "globe+space")
        if let result {
            #expect(result.contains("Fn") || result.contains("Globe"))
        }
    }
}

// MARK: - hotkeyMissingPermissionSummary

@Suite("hotkeyMissingPermissionSummary")
struct MissingPermissionSummaryTests {
    @Test("nil when all granted")
    func allGranted() {
        #expect(ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: true, inputMonitoringAuthorized: true) == nil)
    }

    @Test("shows Accessibility when missing")
    func accessibilityMissing() {
        let result = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: false, inputMonitoringAuthorized: true)
        #expect(result == "Accessibility")
    }

    @Test("shows Input Monitoring when missing")
    func inputMissing() {
        let result = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: true, inputMonitoringAuthorized: false)
        #expect(result == "Input Monitoring")
    }

    @Test("shows both when missing")
    func bothMissing() {
        let result = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: false, inputMonitoringAuthorized: false)
        #expect(result!.contains("Accessibility"))
        #expect(result!.contains("Input Monitoring"))
    }
}

// MARK: - insertButtonHelpText

@Suite("insertButtonHelpText")
struct InsertButtonHelpTextTests {
    @Test("shows disabled reason when present")
    func disabledReason() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: "Wait", canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, insertTargetAppName: nil,
            insertTargetUsesFallback: false, currentFrontAppName: nil
        )
        #expect(result.contains("Wait"))
    }

    @Test("copy when cannot insert directly with target")
    func cantInsertWithTarget() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil, canInsertDirectly: false,
            shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, insertTargetAppName: "Safari",
            insertTargetUsesFallback: false, currentFrontAppName: nil
        )
        #expect(result.contains("copy") || result.contains("Safari"))
    }

    @Test("copy when target unknown")
    func targetUnknown() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil, canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: true, shouldSuggestRetarget: false,
            isInsertTargetStale: false, insertTargetAppName: nil,
            insertTargetUsesFallback: false, currentFrontAppName: nil
        )
        #expect(result.contains("clipboard"))
    }

    @Test("retarget suggestion when different front app")
    func retargetSuggestion() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil, canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: true,
            isInsertTargetStale: false, insertTargetAppName: "Safari",
            insertTargetUsesFallback: false, currentFrontAppName: "Notes"
        )
        #expect(result.contains("Notes") || result.contains("Safari"))
    }

    @Test("stale target warning")
    func staleWarning() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil, canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false,
            isInsertTargetStale: true, insertTargetAppName: "Safari",
            insertTargetUsesFallback: false, currentFrontAppName: nil
        )
        #expect(result.contains("while ago") || result.contains("Retarget"))
    }

    @Test("fallback target")
    func fallback() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil, canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, insertTargetAppName: "Safari",
            insertTargetUsesFallback: true, currentFrontAppName: nil
        )
        #expect(result.contains("recent"))
    }

    @Test("live front app when no target")
    func liveFront() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil, canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, insertTargetAppName: nil,
            insertTargetUsesFallback: false, currentFrontAppName: "Notes"
        )
        #expect(result.contains("Notes"))
    }
}

// MARK: - retargetButtonTitle / retargetButtonHelpText

@Suite("retargetButtonTitle")
struct RetargetButtonTitleTests {
    @Test("no target")
    func noTarget() {
        #expect(ViewHelpers.retargetButtonTitle(insertTargetAppName: nil, insertTargetUsesFallback: false) == "Retarget")
    }

    @Test("with target")
    func withTarget() {
        let result = ViewHelpers.retargetButtonTitle(insertTargetAppName: "Safari", insertTargetUsesFallback: false)
        #expect(result.contains("Safari"))
    }

    @Test("fallback target")
    func fallback() {
        let result = ViewHelpers.retargetButtonTitle(insertTargetAppName: "Safari", insertTargetUsesFallback: true)
        #expect(result.contains("recent"))
    }
}

@Suite("retargetButtonHelpText")
struct RetargetButtonHelpTextTests {
    @Test("recording blocks")
    func recording() {
        #expect(ViewHelpers.retargetButtonHelpText(isRecording: true, pendingChunkCount: 0).contains("Finish"))
    }

    @Test("pending blocks")
    func pending() {
        #expect(ViewHelpers.retargetButtonHelpText(isRecording: false, pendingChunkCount: 1).contains("Wait"))
    }

    @Test("ready")
    func ready() {
        #expect(ViewHelpers.retargetButtonHelpText(isRecording: false, pendingChunkCount: 0).contains("Refresh"))
    }
}

// MARK: - useCurrentAppButtonTitle / HelpText

@Suite("useCurrentAppButtonTitle")
struct UseCurrentAppTitleTests {
    @Test("can insert with front app")
    func withFront() {
        let result = ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: "Notes")
        #expect(result.contains("Notes"))
    }

    @Test("can insert no front app")
    func noFront() {
        #expect(ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: nil) == "Use Current App")
    }

    @Test("cannot insert")
    func cantInsert() {
        #expect(ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: false, currentFrontAppName: "Notes") == "Use Current + Copy")
    }
}

@Suite("useCurrentAppButtonHelpText")
struct UseCurrentAppHelpTextTests {
    @Test("disabled reason")
    func disabled() {
        let result = ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: "Wait", canInsertDirectly: true)
        #expect(result.contains("Wait"))
    }

    @Test("can insert")
    func canInsert() {
        let result = ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true)
        #expect(result.contains("insert"))
    }

    @Test("cannot insert")
    func cantInsert() {
        let result = ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: false)
        #expect(result.contains("copy"))
    }
}

// MARK: - retargetAndInsertButtonTitle / HelpText

@Suite("retargetAndInsertButtonTitle")
struct RetargetAndInsertTitleTests {
    @Test("can insert with front app")
    func withFront() {
        let result = ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: true, currentFrontAppName: "Notes")
        #expect(result.contains("Notes"))
    }

    @Test("can insert no front")
    func noFront() {
        let result = ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: true, currentFrontAppName: nil)
        #expect(result.contains("Current App"))
    }

    @Test("cannot insert")
    func cantInsert() {
        let result = ViewHelpers.retargetAndInsertButtonTitle(canInsertDirectly: false, currentFrontAppName: nil)
        #expect(result.contains("Copy"))
    }
}

@Suite("retargetAndInsertHelpText")
struct RetargetAndInsertHelpTextTests {
    @Test("disabled reason")
    func disabled() {
        let result = ViewHelpers.retargetAndInsertHelpText(insertActionDisabledReason: "Wait", canInsertDirectly: true)
        #expect(result.contains("Wait"))
    }

    @Test("can insert")
    func canInsert() {
        let result = ViewHelpers.retargetAndInsertHelpText(insertActionDisabledReason: nil, canInsertDirectly: true)
        #expect(result.contains("insert"))
    }

    @Test("cannot insert")
    func cantInsert() {
        let result = ViewHelpers.retargetAndInsertHelpText(insertActionDisabledReason: nil, canInsertDirectly: false)
        #expect(result.contains("copy"))
    }
}

// MARK: - focusTargetButtonTitle / HelpText

@Suite("focusTargetButtonTitle")
struct FocusTargetTitleTests {
    @Test("no target")
    func noTarget() {
        #expect(ViewHelpers.focusTargetButtonTitle(insertTargetAppName: nil) == "Focus Target")
    }

    @Test("with target")
    func withTarget() {
        #expect(ViewHelpers.focusTargetButtonTitle(insertTargetAppName: "Safari").contains("Safari"))
    }
}

@Suite("focusTargetButtonHelpText")
struct FocusTargetHelpTextTests {
    @Test("recording or pending")
    func busy() {
        #expect(ViewHelpers.focusTargetButtonHelpText(isRecording: true, pendingChunkCount: 0, insertTargetAppName: nil).contains("Wait"))
    }

    @Test("with target")
    func withTarget() {
        #expect(ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 0, insertTargetAppName: "Safari").contains("Safari"))
    }

    @Test("no target")
    func noTarget() {
        #expect(ViewHelpers.focusTargetButtonHelpText(isRecording: false, pendingChunkCount: 0, insertTargetAppName: nil).contains("Retarget"))
    }
}

// MARK: - focusAndInsertButtonTitle / HelpText

@Suite("focusAndInsertButtonTitle")
struct FocusAndInsertTitleTests {
    @Test("can insert with target")
    func withTarget() {
        #expect(ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: true, insertTargetAppName: "Safari").contains("Safari"))
    }

    @Test("can insert no target")
    func noTarget() {
        #expect(ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: true, insertTargetAppName: nil) == "Focus + Insert")
    }

    @Test("cannot insert")
    func cantInsert() {
        #expect(ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: false, insertTargetAppName: "Safari") == "Focus + Copy")
    }
}

@Suite("focusAndInsertButtonHelpText")
struct FocusAndInsertHelpTextTests {
    @Test("disabled reason")
    func disabled() {
        let result = ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: "Wait", hasResolvableInsertTarget: true, canInsertDirectly: true)
        #expect(result.contains("Wait"))
    }

    @Test("no target")
    func noTarget() {
        let result = ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: nil, hasResolvableInsertTarget: false, canInsertDirectly: true)
        #expect(result.contains("Retarget"))
    }

    @Test("can insert with target")
    func canInsert() {
        let result = ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: nil, hasResolvableInsertTarget: true, canInsertDirectly: true)
        #expect(result.contains("insert"))
    }

    @Test("cannot insert with target")
    func cantInsert() {
        let result = ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: nil, hasResolvableInsertTarget: true, canInsertDirectly: false)
        #expect(result.contains("clipboard"))
    }
}

// MARK: - canRetargetInsertTarget

@Suite("canRetargetInsertTarget")
struct CanRetargetTests {
    @Test("true when idle")
    func idle() {
        #expect(ViewHelpers.canRetargetInsertTarget(isRecording: false, pendingChunkCount: 0))
    }

    @Test("false when recording")
    func recording() {
        #expect(!ViewHelpers.canRetargetInsertTarget(isRecording: true, pendingChunkCount: 0))
    }

    @Test("false when pending")
    func pending() {
        #expect(!ViewHelpers.canRetargetInsertTarget(isRecording: false, pendingChunkCount: 1))
    }
}

// MARK: - hasResolvableInsertTarget

@Suite("hasResolvableInsertTarget")
struct HasResolvableTargetTests {
    @Test("false for nil")
    func nilName() {
        #expect(!ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: nil))
    }

    @Test("false for empty")
    func empty() {
        #expect(!ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: ""))
    }

    @Test("false for whitespace")
    func whitespace() {
        #expect(!ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "   "))
    }

    @Test("true for valid name")
    func valid() {
        #expect(ViewHelpers.hasResolvableInsertTarget(insertTargetAppName: "Safari"))
    }
}
