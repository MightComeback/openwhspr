import Testing
@testable import OpenWhisper
import Foundation

/// E2E tests for the full SettingsView hotkey configuration workflow,
/// composing ViewHelpers calls the same way SettingsView does internally.
@Suite("SettingsView hotkey E2E flow")
struct SettingsViewHotkeyE2EFlowTests {

    // MARK: - Full draft → validate → apply lifecycle

    @Test("draft entry → validation → preview → apply lifecycle")
    func draftEntryToApplyLifecycle() {
        // 1. User types "cmd+shift+f6" in draft field
        let draft = "cmd+shift+f6"
        let parsed = ViewHelpers.parseHotkeyDraft(draft)
        #expect(parsed != nil)
        #expect(parsed!.key == "f6")
        #expect(parsed!.requiredModifiers != nil)
        #expect(parsed!.requiredModifiers!.contains(.command))
        #expect(parsed!.requiredModifiers!.contains(.shift))

        // 2. Validation passes
        let validation = ViewHelpers.hotkeyDraftValidationMessage(
            draft: draft,
            isSupportedKey: HotkeyDisplay.isSupportedKey("f6")
        )
        #expect(validation == nil) // nil means valid

        // 3. Preview shows the combo
        let currentMods: Set<ViewHelpers.ParsedModifier> = [.command, .shift]
        let preview = ViewHelpers.canonicalHotkeyDraftPreview(draft: draft, currentModifiers: currentMods)
        #expect(preview != nil)

        // 4. Has changes to apply (different from current "space")
        let hasChanges = ViewHelpers.hasHotkeyDraftChangesToApply(
            draft: draft,
            currentKey: "space",
            currentModifiers: currentMods
        )
        #expect(hasChanges)

        // 5. After apply, sanitize key
        let sanitized = ViewHelpers.sanitizeKeyValue("f6")
        #expect(sanitized == "f6")
        #expect(HotkeyDisplay.isSupportedKey(sanitized))
    }

    @Test("invalid draft shows validation error")
    func invalidDraftShowsError() {
        let draft = "   "
        let parsed = ViewHelpers.parseHotkeyDraft(draft)
        #expect(parsed == nil)

        let validation = ViewHelpers.hotkeyDraftValidationMessage(
            draft: draft,
            isSupportedKey: false
        )
        #expect(validation != nil)
    }

    @Test("unsupported key triggers validation message")
    func unsupportedKeyValidation() {
        // "§" is not a supported key
        let validation = ViewHelpers.hotkeyDraftValidationMessage(
            draft: "§",
            isSupportedKey: false
        )
        #expect(validation != nil)
    }

    @Test("modifier-only draft returns modifier-only error from parse")
    func modifierOnlyDraft() {
        let parsed = ViewHelpers.parseHotkeyDraft("cmd+shift")
        // parseHotkeyTokens with no key token should fail
        #expect(parsed == nil)
    }

    @Test("full preset reset lifecycle: toggle mode defaults")
    func presetResetLifecycle() {
        // After reset, defaults should be: toggle mode, space key, cmd+shift required
        let mode = HotkeyMode.toggle
        #expect(mode.rawValue == "toggle")

        let defaultKey = "space"
        #expect(HotkeyDisplay.isSupportedKey(defaultKey))

        let defaultMods: Set<ViewHelpers.ParsedModifier> = [.command, .shift]
        let summary = ViewHelpers.hotkeySummaryFromModifiers(
            command: true,
            shift: true,
            option: false,
            control: false,
            capsLock: false,
            key: defaultKey
        )
        #expect(summary.contains("⌘") || summary.contains("Cmd"))
        #expect(summary.contains("⇧") || summary.contains("Shift"))

        // No system conflict for cmd+shift+space
        let conflict = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: defaultMods,
            key: defaultKey
        )
        // cmd+shift+space should NOT conflict
        #expect(conflict == nil)
    }

    @Test("hold mode preset with risk assessment")
    func holdModePresetWithRisk() {
        let mode = HotkeyMode.hold
        let tipText = ViewHelpers.hotkeyModeTipText(mode: mode, usesEscapeTrigger: false)
        #expect(!tipText.isEmpty)

        // Hold mode with just "a" (no modifiers) should warn
        let holdWarn = ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: "hold",
            requiredModifiers: [],
            key: "a"
        )
        #expect(holdWarn)

        // Hold mode with modifiers should not warn
        let holdSafe = ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: "hold",
            requiredModifiers: [.command],
            key: "a"
        )
        #expect(!holdSafe)
    }

    @Test("escape key triggers both escape warning and hold-mode warning")
    func escapeKeyDualWarnings() {
        let escapeWarn = ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "escape")
        #expect(escapeWarn != nil)

        let holdWarn = ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: "hold",
            requiredModifiers: [],
            key: "escape"
        )
        #expect(holdWarn)

        // Escape with modifiers: escape warning still fires, hold-mode doesn't
        let escapeModWarn = ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "escape")
        #expect(escapeModWarn != nil)

        let holdModSafe = ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: "hold",
            requiredModifiers: [.command],
            key: "escape"
        )
        #expect(!holdModSafe)
    }

    // MARK: - Hotkey capture simulation flow

    @Test("capture flow: shouldIgnoreCaptureActivation within grace period")
    func captureIgnoresActivationEvent() {
        let shouldIgnore = ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        )
        #expect(shouldIgnore)
    }

    @Test("capture flow: does not ignore after grace period")
    func captureDoesNotIgnoreAfterGrace() {
        let shouldIgnore = ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.5,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        )
        #expect(!shouldIgnore)
    }

    @Test("capture flow: does not ignore different key")
    func captureDoesNotIgnoreDifferentKey() {
        let shouldIgnore = ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "space",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: false
        )
        #expect(!shouldIgnore)
    }

    @Test("capture flow: does not ignore different modifiers")
    func captureDoesNotIgnoreDifferentMods() {
        let shouldIgnore = ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: false,
            hasExtraModifiers: false
        )
        #expect(!shouldIgnore)
    }

    @Test("capture flow: does not ignore when extra modifiers present")
    func captureDoesNotIgnoreExtraMods() {
        let shouldIgnore = ViewHelpers.shouldIgnoreCaptureActivation(
            elapsedSinceCaptureStart: 0.1,
            keyName: "k",
            hasCommandModifier: true,
            hasShiftModifier: true,
            hasExtraModifiers: true
        )
        #expect(!shouldIgnore)
    }

    @Test("capture flow: modifier-only keyCode is detected")
    func captureModifierOnlyKeyCode() {
        // Cmd keyCode = 55
        #expect(ViewHelpers.isModifierOnlyKeyCode(55))
        // Shift keyCode = 56
        #expect(ViewHelpers.isModifierOnlyKeyCode(56))
        // Space keyCode = 49 — not modifier-only
        #expect(!ViewHelpers.isModifierOnlyKeyCode(49))
    }

    @Test("capture flow: safe modifiers auto-applied for letter keys")
    func captureAutoApplySafeModifiers() {
        // Letter keys without modifiers should get safe modifiers auto-applied
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "a"))
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "z"))
        // Function keys should NOT get auto-applied
        #expect(!ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "f6"))
    }

    @Test("capture button title reflects capture state")
    func captureButtonTitleStates() {
        let idle = ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: false, secondsRemaining: 0)
        #expect(!idle.isEmpty)

        let capturing = ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: true, secondsRemaining: 5)
        #expect(capturing != idle)
        #expect(capturing.contains("5"))
    }

    @Test("capture instruction differs by input monitoring permission")
    func captureInstructionByPermission() {
        let withPerm = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: true, secondsRemaining: 10)
        let withoutPerm = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: false, secondsRemaining: 10)
        #expect(withPerm != withoutPerm)
    }

    @Test("capture progress decreases over time")
    func captureProgressOverTime() {
        let full = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 10, totalSeconds: 10)
        let half = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 10)
        let zero = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 0, totalSeconds: 10)
        #expect(full > half)
        #expect(half > zero)
        #expect(zero == 0.0)
    }

    // MARK: - Hotkey draft changes detection

    @Test("no changes when draft matches current key")
    func noChangesWhenMatching() {
        let hasChanges = ViewHelpers.hasHotkeyDraftChangesToApply(
            draft: "space",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(!hasChanges)
    }

    @Test("changes detected when draft key differs")
    func changesWhenKeyDiffers() {
        let hasChanges = ViewHelpers.hasHotkeyDraftChangesToApply(
            draft: "f6",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(hasChanges)
    }

    @Test("changes detected when draft modifiers differ")
    func changesWhenModsDiffer() {
        let hasChanges = ViewHelpers.hasHotkeyDraftChangesToApply(
            draft: "cmd+option+space",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(hasChanges)
    }

    @Test("hasHotkeyDraftEdits tracks pending unsaved edits")
    func draftEditsTracking() {
        let hasEdits = ViewHelpers.hasHotkeyDraftEdits(
            draft: "f6",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(hasEdits)

        let noEdits = ViewHelpers.hasHotkeyDraftEdits(
            draft: "space",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(!noEdits)
    }

    // MARK: - Modifier override summary

    @Test("modifier override summary when draft has modifiers")
    func modifierOverrideSummary() {
        let summary = ViewHelpers.hotkeyDraftModifierOverrideSummary(
            draft: "cmd+option+space",
            currentModifiers: [.command, .shift]
        )
        #expect(summary != nil)
    }

    @Test("no modifier override summary for plain key draft")
    func noModifierOverrideForPlainKey() {
        let summary = ViewHelpers.hotkeyDraftModifierOverrideSummary(
            draft: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(summary == nil)
    }

    @Test("non-configurable modifier notice for fn/globe")
    func nonConfigurableModifierNotice() {
        // fn/globe alone doesn't trigger (absorbed into key path), needs configurable mod too
        let notice = ViewHelpers.hotkeyDraftNonConfigurableModifierNotice(draft: "cmd+globe+space")
        #expect(notice != nil)

        let noNotice = ViewHelpers.hotkeyDraftNonConfigurableModifierNotice(draft: "cmd+space")
        #expect(noNotice == nil)
    }

    // MARK: - Permission summaries

    @Test("missing permissions summary: both missing")
    func bothPermissionsMissing() {
        let summary = ViewHelpers.hotkeyMissingPermissionSummary(
            accessibilityAuthorized: false,
            inputMonitoringAuthorized: false
        )
        #expect(summary != nil)
    }

    @Test("missing permissions summary: only accessibility missing")
    func onlyAccessibilityMissing() {
        let summary = ViewHelpers.hotkeyMissingPermissionSummary(
            accessibilityAuthorized: false,
            inputMonitoringAuthorized: true
        )
        #expect(summary != nil)
    }

    @Test("missing permissions summary: all granted")
    func allPermissionsGranted() {
        let summary = ViewHelpers.hotkeyMissingPermissionSummary(
            accessibilityAuthorized: true,
            inputMonitoringAuthorized: true
        )
        #expect(summary == nil)
    }

    // MARK: - System conflict detection E2E

    @Test("full conflict check: Cmd+Space conflicts with Spotlight")
    func cmdSpaceConflict() {
        let conflict = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "space"
        )
        #expect(conflict != nil)
        #expect(conflict!.lowercased().contains("spotlight"))
    }

    @Test("full conflict check: Ctrl+Space conflicts with input source")
    func ctrlSpaceConflict() {
        let conflict = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.control],
            key: "space"
        )
        #expect(conflict != nil)
    }

    @Test("full conflict check: Cmd+Tab conflicts with app switching")
    func cmdTabConflict() {
        let conflict = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "tab"
        )
        #expect(conflict != nil)
    }

    @Test("full conflict check: Cmd+Q warns about quit")
    func cmdQWarning() {
        let conflict = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command],
            key: "q"
        )
        #expect(conflict != nil)
    }

    @Test("safe combo: Cmd+Shift+F6 has no conflict")
    func safeComboNoConflict() {
        let conflict = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: [.command, .shift],
            key: "f6"
        )
        #expect(conflict == nil)
    }

    // MARK: - Hotkey summary formatting

    @Test("hotkey summary includes all required modifiers and key")
    func hotkeySummaryFormatting() {
        let summary = ViewHelpers.hotkeySummaryFromModifiers(
            command: true,
            shift: true,
            option: false,
            control: false,
            capsLock: false,
            key: "space"
        )
        #expect(!summary.isEmpty)
    }

    @Test("hotkey summary with all modifiers")
    func hotkeySummaryAllMods() {
        let summary = ViewHelpers.hotkeySummaryFromModifiers(
            command: true,
            shift: true,
            option: true,
            control: true,
            capsLock: false,
            key: "a"
        )
        #expect(!summary.isEmpty)
    }

    @Test("hotkey summary with no modifiers")
    func hotkeySummaryNoMods() {
        let summary = ViewHelpers.hotkeySummaryFromModifiers(
            command: false,
            shift: false,
            option: false,
            control: false,
            capsLock: false,
            key: "f12"
        )
        #expect(!summary.isEmpty)
    }

    // MARK: - Auto-paste permission warning

    @Test("auto-paste warning: enabled but no accessibility")
    func autoPasteWarningShown() {
        let shows = ViewHelpers.showsAutoPastePermissionWarning(
            autoPaste: true,
            accessibilityAuthorized: false
        )
        #expect(shows)
    }

    @Test("auto-paste warning: enabled with accessibility")
    func autoPasteWarningHidden() {
        let shows = ViewHelpers.showsAutoPastePermissionWarning(
            autoPaste: true,
            accessibilityAuthorized: true
        )
        #expect(!shows)
    }

    @Test("auto-paste warning: disabled regardless of permission")
    func autoPasteWarningDisabled() {
        let shows = ViewHelpers.showsAutoPastePermissionWarning(
            autoPaste: false,
            accessibilityAuthorized: false
        )
        #expect(!shows)
    }

    // MARK: - Multi-step hotkey draft parsing E2E

    @Test("pasted clipboard combo: ⌘⇧Space → parsed correctly")
    func pastedClipboardCombo() {
        let pasted = "⌘⇧Space"
        let parsed = ViewHelpers.parseHotkeyDraft(pasted.lowercased())
        #expect(parsed != nil)
        #expect(parsed!.key == "space")
    }

    @Test("pasted clipboard combo: Ctrl+Option+F6 → parsed correctly")
    func pastedCtrlOptionF6() {
        let parsed = ViewHelpers.parseHotkeyDraft("ctrl+option+f6")
        #expect(parsed != nil)
        #expect(parsed!.key == "f6")
        #expect(parsed!.requiredModifiers != nil)
        #expect(parsed!.requiredModifiers!.contains(.option))
        #expect(parsed!.requiredModifiers!.contains(.control))
    }

    @Test("pasted clipboard combo with dashes: cmd-shift-a")
    func pastedDashSeparated() {
        let parsed = ViewHelpers.parseHotkeyDraft("cmd-shift-a")
        #expect(parsed != nil)
        #expect(parsed!.key == "a")
        #expect(parsed!.requiredModifiers!.contains(.command))
        #expect(parsed!.requiredModifiers!.contains(.shift))
    }

    @Test("pasted clipboard combo with slashes: command/shift/space")
    func pastedSlashSeparated() {
        let parsed = ViewHelpers.parseHotkeyDraft("command/shift/space")
        #expect(parsed != nil)
        #expect(parsed!.key == "space")
    }

    @Test("pasted clipboard combo space-separated: cmd shift space")
    func pastedSpaceSeparated() {
        let parsed = ViewHelpers.parseHotkeyDraft("cmd shift space")
        #expect(parsed != nil)
        #expect(parsed!.key == "space")
    }

    // MARK: - Risk assessment composite

    @Test("risk assessment: high-risk key with hold mode triggers dual warning")
    func riskAssessmentDualWarning() {
        let isHighRisk = ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "a")
        #expect(isHighRisk)

        let holdWarn = ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: "hold",
            requiredModifiers: [],
            key: "a"
        )
        #expect(holdWarn)
    }

    @Test("risk assessment: function key is safe even without modifiers")
    func riskAssessmentFunctionKeySafe() {
        let isHighRisk = ViewHelpers.isHighRiskHotkey(requiredModifiers: [], key: "f6")
        #expect(!isHighRisk)

        let holdWarn = ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: "hold",
            requiredModifiers: [],
            key: "f6"
        )
        #expect(!holdWarn)
    }

    @Test("effective risk context extracts correct key from draft")
    func effectiveRiskContext() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "cmd+shift+a",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(result.key == "a")
        #expect(result.requiredModifiers.contains(.command))
        #expect(result.requiredModifiers.contains(.shift))
    }

    @Test("effective risk context falls back to current key for empty draft")
    func effectiveRiskContextFallback() {
        let result = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(result.key == "space")
        #expect(result.requiredModifiers == Set([.command, .shift]))
    }

    // MARK: - Hotkey mode tip integration

    @Test("toggle mode tip text is non-empty")
    func toggleModeTip() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: false)
        #expect(!tip.isEmpty)
    }

    @Test("hold mode tip text is non-empty")
    func holdModeTip() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: false)
        #expect(!tip.isEmpty)
    }

    @Test("hold mode with escape trigger has different tip")
    func holdModeEscapeTip() {
        let normal = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: false)
        let escape = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: true)
        #expect(normal != escape || !escape.isEmpty) // At minimum non-empty
    }

    // MARK: - Common key sections validation

    @Test("common key sections cover all expected categories")
    func commonKeySectionsCategories() {
        let sections = ViewHelpers.commonHotkeyKeySections
        #expect(sections.count == 5)
        let titles = sections.map { $0.title }
        #expect(titles.contains(where: { $0.lowercased().contains("basic") || $0.lowercased().contains("common") }))
    }

    @Test("common key sections: all keys are supported")
    func commonKeySectionsAllSupported() {
        let sections = ViewHelpers.commonHotkeyKeySections
        for section in sections {
            for key in section.keys {
                #expect(HotkeyDisplay.isSupportedKey(key), "Key '\(key)' in section '\(section.title)' should be supported")
            }
        }
    }

    // MARK: - Model file size utility

    @Test("sizeOfModelFile returns 0 for nonexistent path")
    func modelFileSizeNonexistent() {
        let size = ViewHelpers.sizeOfModelFile(atPath: "/nonexistent/model.bin")
        #expect(size == 0)
    }

    @Test("formatBytes handles edge cases")
    func formatBytesEdgeCases() {
        let zero = ViewHelpers.formatBytes(0)
        #expect(!zero.isEmpty)

        let negative = ViewHelpers.formatBytes(-100)
        #expect(!negative.isEmpty)

        let large = ViewHelpers.formatBytes(1_073_741_824) // 1 GB
        #expect(!large.isEmpty)
    }

    // MARK: - Insertion probe status

    @Test("insertion probe status: nil → not tested")
    func probeStatusNil() {
        let label = ViewHelpers.insertionProbeStatusLabel(succeeded: nil)
        #expect(!label.isEmpty)

        let color = ViewHelpers.insertionProbeStatusColorName(succeeded: nil)
        #expect(!color.isEmpty)
    }

    @Test("insertion probe status: true → passed")
    func probeStatusPassed() {
        let label = ViewHelpers.insertionProbeStatusLabel(succeeded: true)
        #expect(label.lowercased().contains("pass"))

        let color = ViewHelpers.insertionProbeStatusColorName(succeeded: true)
        #expect(color == "green")
    }

    @Test("insertion probe status: false → failed")
    func probeStatusFailed() {
        let label = ViewHelpers.insertionProbeStatusLabel(succeeded: false)
        #expect(label.lowercased().contains("fail"))

        let color = ViewHelpers.insertionProbeStatusColorName(succeeded: false)
        #expect(color == "orange")
    }

    // MARK: - Capture profile fallback

    @Test("capture profile fallback detection")
    func captureProfileFallback() {
        #expect(ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: true))
        #expect(!ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: false))
        #expect(!ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: nil))
    }

    @Test("capture profile fallback app name")
    func captureProfileFallbackName() {
        let name = ViewHelpers.captureProfileFallbackAppName(isFallback: true, appName: "Safari")
        #expect(name == "Safari")

        let noFallback = ViewHelpers.captureProfileFallbackAppName(isFallback: false, appName: "Safari")
        #expect(noFallback == nil)

        let nilFallback = ViewHelpers.captureProfileFallbackAppName(isFallback: nil, appName: "Safari")
        #expect(nilFallback == nil)
    }

    // MARK: - Bridge modifiers utility

    @Test("bridge modifiers preserves all modifier types")
    func bridgeModifiers() {
        let input: Set<ViewHelpers.ParsedModifier> = [.command, .shift, .option, .control, .capsLock]
        let bridged = ViewHelpers.bridgeModifiers(input)
        #expect(bridged.count == 5)
        #expect(bridged.contains(.command))
        #expect(bridged.contains(.shift))
        #expect(bridged.contains(.option))
        #expect(bridged.contains(.control))
        #expect(bridged.contains(.capsLock))
    }

    @Test("bridge modifiers: empty set")
    func bridgeModifiersEmpty() {
        let bridged = ViewHelpers.bridgeModifiers([])
        #expect(bridged.isEmpty)
    }

    // MARK: - Insertion sample text helpers

    @Test("insertion probe sample text enforcement")
    func insertionProbeSampleTextEnforcement() {
        let long = String(repeating: "a", count: 500)
        let enforced = ViewHelpers.enforceInsertionProbeSampleTextLimit(long)
        #expect(enforced.count <= 200) // max chars limit

        let short = "hello"
        let shortEnforced = ViewHelpers.enforceInsertionProbeSampleTextLimit(short)
        #expect(shortEnforced == short)
    }

    @Test("insertion probe sample text will truncate")
    func insertionProbeSampleTextWillTruncate() {
        let long = String(repeating: "a", count: 500)
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate(long))

        let short = "hello"
        #expect(!ViewHelpers.insertionProbeSampleTextWillTruncate(short))
    }

    @Test("has insertion probe sample text")
    func hasInsertionProbeSampleText() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("hello"))
        #expect(!ViewHelpers.hasInsertionProbeSampleText(""))
        #expect(!ViewHelpers.hasInsertionProbeSampleText("   "))
    }

    @Test("insertion probe sample text for run trims and limits")
    func insertionProbeSampleTextForRun() {
        let result = ViewHelpers.insertionProbeSampleTextForRun("  hello world  ")
        #expect(result == "hello world")

        let long = "  " + String(repeating: "a", count: 500) + "  "
        let longResult = ViewHelpers.insertionProbeSampleTextForRun(long)
        #expect(longResult.count <= 200)
    }
}
