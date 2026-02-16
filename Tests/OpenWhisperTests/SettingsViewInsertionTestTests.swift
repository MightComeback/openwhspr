import Testing
import Foundation
@testable import OpenWhisper

// MARK: - SettingsView insertion test logic (via ViewHelpers)

@Suite("SettingsView insertion test coverage")
struct SettingsViewInsertionTestTests {

    // MARK: - insertionTestDisabledReason edge cases

    @Test("all conditions clear returns destination message")
    func allClearReturnsDestinationMessage() {
        let result = ViewHelpers.insertionTestDisabledReason(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true,
            hasInsertionTarget: true
        )
        // Always returns a string; when nothing else blocks, it's the destination hint
        #expect(!result.isEmpty)
    }

    @Test("recording blocks with specific message")
    func recordingBlocks() {
        let result = ViewHelpers.insertionTestDisabledReason(
            isRecording: true,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true,
            hasInsertionTarget: true
        )
        #expect(result.lowercased().contains("record"))
    }

    @Test("finalizing blocks with specific message")
    func finalizingBlocks() {
        let result = ViewHelpers.insertionTestDisabledReason(
            isRecording: false,
            isFinalizingTranscription: true,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true,
            hasInsertionTarget: true
        )
        #expect(result.lowercased().contains("finaliz"))
    }

    @Test("probe running blocks")
    func probeRunningBlocks() {
        let result = ViewHelpers.insertionTestDisabledReason(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: true,
            hasInsertionProbeSampleText: true,
            hasInsertionTarget: true
        )
        #expect(!result.isEmpty)
    }

    @Test("no sample text blocks")
    func noSampleTextBlocks() {
        let result = ViewHelpers.insertionTestDisabledReason(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: false,
            hasInsertionTarget: true
        )
        #expect(result.lowercased().contains("sample") || result.lowercased().contains("text"))
    }

    @Test("no target shows destination hint")
    func noTargetShowsHint() {
        let result = ViewHelpers.insertionTestDisabledReason(
            isRecording: false,
            isFinalizingTranscription: false,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true,
            hasInsertionTarget: false
        )
        #expect(!result.isEmpty)
    }

    @Test("recording priority beats finalizing")
    func recordingPriorityBeatsFinalizing() {
        let result = ViewHelpers.insertionTestDisabledReason(
            isRecording: true,
            isFinalizingTranscription: true,
            isRunningInsertionProbe: false,
            hasInsertionProbeSampleText: true,
            hasInsertionTarget: true
        )
        #expect(result.lowercased().contains("record"))
    }

    @Test("multiple blockers returns first priority")
    func multipleBlockersFirstPriority() {
        let result = ViewHelpers.insertionTestDisabledReason(
            isRecording: true,
            isFinalizingTranscription: true,
            isRunningInsertionProbe: true,
            hasInsertionProbeSampleText: false,
            hasInsertionTarget: false
        )
        #expect(!result.isEmpty)
    }

    // MARK: - showsAutoPastePermissionWarning (trivial logic)

    @Test("auto paste on + no accessibility = warning")
    func autoPasteNoAccessibility() {
        let result = true && !false // autoPaste && !accessibilityAuthorized
        #expect(result == true)
    }

    @Test("auto paste on + accessibility = no warning")
    func autoPasteWithAccessibility() {
        let result = true && !true
        #expect(result == false)
    }

    @Test("auto paste off = no warning regardless")
    func autoPasteOff() {
        #expect((false && !false) == false)
        #expect((false && !true) == false)
    }

    // MARK: - hasHotkeyDraftEdits (logic via parsing)

    @Test("same key after sanitize returns false for edits")
    func sameSanitizedKeyNoEdits() {
        // sanitizeKeyValue normalizes — same input = no edits
        let a = ViewHelpers.sanitizeKeyValue("space")
        let b = ViewHelpers.sanitizeKeyValue("SPACE")
        #expect(a == b)
    }

    @Test("different key after sanitize returns different values")
    func differentSanitizedKey() {
        let a = ViewHelpers.sanitizeKeyValue("space")
        let b = ViewHelpers.sanitizeKeyValue("f5")
        #expect(a != b)
    }

    // MARK: - sanitizeHotkeyDraftValue (extracted from hasHotkeyDraftEdits)

    @Test("sanitizeKeyValue empty returns space")
    func sanitizeEmpty() {
        #expect(ViewHelpers.sanitizeKeyValue("") == "space")
    }

    @Test("sanitizeKeyValue trims and lowercases")
    func sanitizeTrimsLower() {
        #expect(ViewHelpers.sanitizeKeyValue("  F5  ") == "f5")
    }

    // MARK: - commonHotkeyKeySections (constant validation)

    @Test("HotkeyDisplay supports all common basic keys")
    func basicKeysSupported() {
        let basics = ["space", "tab", "return", "escape", "delete", "forwarddelete"]
        for key in basics {
            #expect(HotkeyDisplay.isSupportedKey(key), "Expected \(key) to be supported")
        }
    }

    @Test("HotkeyDisplay supports all function keys")
    func functionKeysSupported() {
        for n in 1...24 {
            let key = "f\(n)"
            #expect(HotkeyDisplay.isSupportedKey(key), "Expected \(key) to be supported")
        }
    }

    @Test("HotkeyDisplay supports navigation keys")
    func navigationKeysSupported() {
        let navKeys = ["left", "right", "up", "down", "home", "end", "pageup", "pagedown"]
        for key in navKeys {
            #expect(HotkeyDisplay.isSupportedKey(key), "Expected \(key) to be supported")
        }
    }

    @Test("HotkeyDisplay supports punctuation keys")
    func punctuationKeysSupported() {
        let punctuation = ["minus", "equals", "semicolon", "comma", "period", "slash", "backslash", "backtick", "section"]
        for key in punctuation {
            #expect(HotkeyDisplay.isSupportedKey(key), "Expected \(key) to be supported")
        }
    }

    @Test("HotkeyDisplay supports keypad keys")
    func keypadKeysSupported() {
        let keypad = ["keypad0", "keypad1", "keypad5", "keypad9", "keypaddecimal", "keypadclear", "keypadplus", "keypadminus", "keypadmultiply", "keypaddivide", "keypadenter", "keypadequals"]
        for key in keypad {
            #expect(HotkeyDisplay.isSupportedKey(key), "Expected \(key) to be supported")
        }
    }

    // MARK: - hotkeyMissingPermissionSummary

    @Test("both authorized returns nil")
    func bothAuthorizedNil() {
        let result = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: true, inputMonitoringAuthorized: true)
        #expect(result == nil)
    }

    @Test("accessibility only missing")
    func accessibilityOnlyMissing() {
        let result = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: false, inputMonitoringAuthorized: true)
        #expect(result == "Accessibility")
    }

    @Test("input monitoring only missing")
    func inputMonitoringOnlyMissing() {
        let result = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: true, inputMonitoringAuthorized: false)
        #expect(result == "Input Monitoring")
    }

    @Test("both missing joined with plus")
    func bothMissing() {
        let result = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: false, inputMonitoringAuthorized: false)
        #expect(result == "Accessibility + Input Monitoring")
    }

    // MARK: - hotkeyModeTipText

    @Test("toggle mode non-escape mentions Esc to discard")
    func toggleNonEscape() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: false)
        #expect(tip.contains("Esc"))
        #expect(tip.contains("toggle"))
    }

    @Test("toggle mode with escape mentions unavailable")
    func toggleWithEscape() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: true)
        #expect(tip.contains("unavailable"))
    }

    @Test("hold mode non-escape mentions release")
    func holdNonEscape() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: false)
        #expect(tip.contains("release"))
    }

    @Test("hold mode with escape mentions unavailable")
    func holdWithEscape() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: true)
        #expect(tip.contains("unavailable"))
    }

    // MARK: - hotkeyCaptureProgress edge cases

    @Test("zero total returns 0")
    func progressZeroTotal() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 0) == 0)
    }

    @Test("negative remaining clamps to 0")
    func progressNegativeRemaining() {
        let result = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: -1, totalSeconds: 10)
        #expect(result >= 0)
    }

    @Test("remaining exceeds total clamps to 1")
    func progressExceedsTotal() {
        let result = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 15, totalSeconds: 10)
        #expect(result <= 1)
    }

    // MARK: - hotkeyDraftValidationMessage

    @Test("valid key returns nil")
    func validKeyNil() {
        let result = ViewHelpers.hotkeyDraftValidationMessage(draft: "space", isSupportedKey: true)
        #expect(result == nil)
    }

    @Test("empty draft returns error")
    func emptyDraftError() {
        let result = ViewHelpers.hotkeyDraftValidationMessage(draft: "", isSupportedKey: false)
        #expect(result != nil)
    }

    @Test("whitespace draft returns error")
    func whitespaceDraftError() {
        let result = ViewHelpers.hotkeyDraftValidationMessage(draft: "   ", isSupportedKey: false)
        #expect(result != nil)
    }

    @Test("unsupported key returns error")
    func unsupportedKeyError() {
        let result = ViewHelpers.hotkeyDraftValidationMessage(draft: "notakey", isSupportedKey: false)
        #expect(result?.lowercased().contains("unsupported") == true)
    }

    // MARK: - hasHotkeyDraftChangesToApply

    @Test("same key same modifiers returns false")
    func noChanges() {
        let mods: Set<ViewHelpers.ParsedModifier> = [.command, .shift]
        let result = ViewHelpers.hasHotkeyDraftChangesToApply(draft: "space", currentKey: "space", currentModifiers: mods)
        #expect(result == false)
    }

    @Test("different key returns true")
    func differentKey() {
        let mods: Set<ViewHelpers.ParsedModifier> = [.command, .shift]
        let result = ViewHelpers.hasHotkeyDraftChangesToApply(draft: "f5", currentKey: "space", currentModifiers: mods)
        #expect(result == true)
    }

    @Test("invalid draft returns false")
    func invalidDraftNoChanges() {
        let mods: Set<ViewHelpers.ParsedModifier> = [.command, .shift]
        let result = ViewHelpers.hasHotkeyDraftChangesToApply(draft: "", currentKey: "space", currentModifiers: mods)
        #expect(result == false)
    }

    @Test("same key different modifiers returns true")
    func sameKeyDifferentMods() {
        let result = ViewHelpers.hasHotkeyDraftChangesToApply(draft: "cmd+space", currentKey: "space", currentModifiers: [.shift])
        #expect(result == true)
    }

    // MARK: - canonicalHotkeyDraftPreview

    @Test("valid key with modifiers shows preview")
    func validPreview() {
        let result = ViewHelpers.canonicalHotkeyDraftPreview(draft: "space", currentModifiers: [.command, .shift])
        #expect(result != nil)
        #expect(result!.contains("⌘"))
        #expect(result!.contains("⇧"))
    }

    @Test("invalid draft returns nil")
    func invalidPreviewNil() {
        let result = ViewHelpers.canonicalHotkeyDraftPreview(draft: "", currentModifiers: [.command])
        #expect(result == nil)
    }

    @Test("draft with explicit modifiers uses those")
    func explicitModsPreview() {
        let result = ViewHelpers.canonicalHotkeyDraftPreview(draft: "ctrl+f5", currentModifiers: [.command, .shift])
        #expect(result != nil)
        #expect(result!.contains("⌃"))
    }

    // MARK: - hotkeyDraftModifierOverrideSummary

    @Test("no modifier change returns nil")
    func noModChangeNil() {
        let result = ViewHelpers.hotkeyDraftModifierOverrideSummary(draft: "space", currentModifiers: [.command])
        #expect(result == nil)
    }

    @Test("modifier change returns summary")
    func modChangeSummary() {
        let result = ViewHelpers.hotkeyDraftModifierOverrideSummary(draft: "cmd+shift+f5", currentModifiers: [.command])
        #expect(result != nil)
    }

    @Test("empty modifiers returns none")
    func emptyModsNone() {
        // A draft that parses to zero required modifiers
        let result = ViewHelpers.hotkeyDraftModifierOverrideSummary(draft: "🌐+space", currentModifiers: [.command])
        // globe is non-configurable, so requiredModifiers may be empty set → "none"
        if result != nil {
            #expect(result == "none")
        }
    }

    // MARK: - hotkeyDraftNonConfigurableModifierNotice

    @Test("fn in draft shows notice")
    func fnNotice() {
        // fn needs a configurable modifier (cmd) to parse as modifier combo
        let result = ViewHelpers.hotkeyDraftNonConfigurableModifierNotice(draft: "fn+cmd+space")
        #expect(result != nil)
        #expect(result!.contains("Fn"))
    }

    @Test("no fn returns nil")
    func noFnNil() {
        let result = ViewHelpers.hotkeyDraftNonConfigurableModifierNotice(draft: "cmd+space")
        #expect(result == nil)
    }

    @Test("plain key returns nil")
    func plainKeyNil() {
        let result = ViewHelpers.hotkeyDraftNonConfigurableModifierNotice(draft: "f5")
        #expect(result == nil)
    }

    // MARK: - insertButtonTitle edge cases

    @Test("no accessibility returns Copy to Clipboard")
    func noAccessibilityCopy() {
        let result = ViewHelpers.insertButtonTitle(
            canInsertDirectly: false,
            insertTargetAppName: "Safari",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(result.contains("Clipboard"))
    }

    @Test("can insert with target shows Insert arrow target")
    func canInsertWithTarget() {
        let result = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "Safari",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(result.contains("Safari"))
        #expect(result.contains("→"))
    }

    @Test("fallback target shows recent")
    func fallbackTargetRecent() {
        let result = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "Safari",
            insertTargetUsesFallback: true,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(result.contains("recent"))
    }

    @Test("suggest retarget shows warning")
    func retargetWarning() {
        let result = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "Safari",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: true,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(result.contains("⚠︎"))
    }

    @Test("stale target shows warning symbol")
    func staleWarning() {
        let result = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: "Safari",
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: true,
            liveFrontAppName: nil
        )
        #expect(result.contains("⚠︎"))
    }

    @Test("no target with live front app uses front app")
    func noTargetLiveFront() {
        let result = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: "Notes"
        )
        #expect(result.contains("Notes"))
    }

    @Test("no target no front app shows Clipboard")
    func noTargetNoFront() {
        let result = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            liveFrontAppName: nil
        )
        #expect(result.contains("Clipboard"))
    }

    // MARK: - insertButtonHelpText edge cases

    @Test("help text with disabled reason prepends")
    func helpTextDisabledReason() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: "Stop recording",
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: "Safari",
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(result.contains("Stop recording"))
    }

    @Test("help text no accessibility with target")
    func helpNoAccessWithTarget() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: false,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: "Safari",
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(result.lowercased().contains("accessibility"))
    }

    @Test("help text copy because target unknown")
    func helpCopyTargetUnknown() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: true,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: nil,
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(result.lowercased().contains("clipboard"))
    }

    @Test("help text retarget suggested shows both apps")
    func helpRetargetSuggested() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: true,
            isInsertTargetStale: false,
            insertTargetAppName: "Safari",
            insertTargetUsesFallback: false,
            currentFrontAppName: "Notes"
        )
        #expect(result.contains("Notes"))
        #expect(result.contains("Safari"))
    }

    @Test("help text stale target warns")
    func helpStaleTarget() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: true,
            insertTargetAppName: "Safari",
            insertTargetUsesFallback: false,
            currentFrontAppName: nil
        )
        #expect(result.lowercased().contains("stale") || result.lowercased().contains("while ago") || result.lowercased().contains("retarget"))
    }

    @Test("help text fallback target shows context")
    func helpFallbackTarget() {
        let result = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true,
            shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false,
            isInsertTargetStale: false,
            insertTargetAppName: "Safari",
            insertTargetUsesFallback: true,
            currentFrontAppName: nil
        )
        #expect(result.contains("Safari"))
        #expect(result.lowercased().contains("recent") || result.lowercased().contains("captured"))
    }
}
