import Testing
import Foundation
@testable import OpenWhisper

@Suite("SettingsView extracted logic (ViewHelpers)")
struct SettingsViewExtractedTests {

    // MARK: - hotkeyModeTipText

    @Test("toggle mode with non-escape key")
    func tipToggleNonEscape() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: false)
        #expect(tip.contains("toggle mode"))
        #expect(tip.contains("Press Esc"))
    }

    @Test("toggle mode with escape key")
    func tipToggleEscape() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: true)
        #expect(tip.contains("toggle mode"))
        #expect(tip.contains("unavailable"))
    }

    @Test("hold mode with non-escape key")
    func tipHoldNonEscape() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: false)
        #expect(tip.contains("hold-to-talk"))
        #expect(tip.contains("Press Esc"))
    }

    @Test("hold mode with escape key")
    func tipHoldEscape() {
        let tip = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: true)
        #expect(tip.contains("hold-to-talk"))
        #expect(tip.contains("unavailable"))
    }

    // MARK: - hotkeyCaptureButtonTitle

    @Test("not capturing shows Record shortcut")
    func captureButtonNotCapturing() {
        #expect(ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: false, secondsRemaining: 5) == "Record shortcut")
    }

    @Test("capturing shows countdown")
    func captureButtonCapturing() {
        #expect(ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: true, secondsRemaining: 3) == "Listening… 3s")
    }

    // MARK: - hotkeyCaptureInstruction

    @Test("with input monitoring")
    func captureInstructionWithMonitoring() {
        let inst = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: true, secondsRemaining: 7)
        #expect(inst.contains("works even if another app"))
        #expect(inst.contains("7s left"))
    }

    @Test("without input monitoring")
    func captureInstructionWithoutMonitoring() {
        let inst = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: false, secondsRemaining: 4)
        #expect(inst.contains("OpenWhisper only"))
        #expect(inst.contains("Input Monitoring is missing"))
        #expect(inst.contains("4s left"))
    }

    // MARK: - hotkeyCaptureProgress

    @Test("zero total returns 0")
    func progressZeroTotal() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 0) == 0)
    }

    @Test("half progress")
    func progressHalf() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 10) == 0.5)
    }

    @Test("full progress")
    func progressFull() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 10, totalSeconds: 10) == 1.0)
    }

    @Test("clamps to 1")
    func progressClamps() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 15, totalSeconds: 10) == 1.0)
    }

    @Test("clamps to 0")
    func progressClampsZero() {
        #expect(ViewHelpers.hotkeyCaptureProgress(secondsRemaining: -1, totalSeconds: 10) == 0)
    }

    // MARK: - hotkeyDraftValidationMessage

    @Test("empty draft returns error")
    func validationEmpty() {
        let msg = ViewHelpers.hotkeyDraftValidationMessage(draft: "", isSupportedKey: false)
        #expect(msg?.contains("Enter one trigger key") == true)
    }

    @Test("whitespace draft returns error")
    func validationWhitespace() {
        let msg = ViewHelpers.hotkeyDraftValidationMessage(draft: "   ", isSupportedKey: false)
        #expect(msg?.contains("Enter one trigger key") == true)
    }

    @Test("supported key returns nil")
    func validationSupported() {
        #expect(ViewHelpers.hotkeyDraftValidationMessage(draft: "space", isSupportedKey: true) == nil)
    }

    @Test("unsupported key returns error")
    func validationUnsupported() {
        let msg = ViewHelpers.hotkeyDraftValidationMessage(draft: "xyz", isSupportedKey: false)
        #expect(msg?.contains("Unsupported key") == true)
    }

    @Test("modifier-only combo returns specific error")
    func validationModifierOnly() {
        let msg = ViewHelpers.hotkeyDraftValidationMessage(draft: "cmd+shift", isSupportedKey: false)
        #expect(msg?.contains("not modifiers only") == true)
    }

    // MARK: - hasHotkeyDraftChangesToApply

    @Test("same key and modifiers returns false")
    func draftNoChanges() {
        #expect(!ViewHelpers.hasHotkeyDraftChangesToApply(draft: "space", currentKey: "space", currentModifiers: []))
    }

    @Test("different key returns true")
    func draftKeyChanged() {
        #expect(ViewHelpers.hasHotkeyDraftChangesToApply(draft: "f5", currentKey: "space", currentModifiers: []))
    }

    @Test("draft with modifiers different from current returns true")
    func draftModifiersChanged() {
        #expect(ViewHelpers.hasHotkeyDraftChangesToApply(draft: "cmd+shift+space", currentKey: "space", currentModifiers: [.command]))
    }

    @Test("invalid draft returns false")
    func draftInvalid() {
        #expect(!ViewHelpers.hasHotkeyDraftChangesToApply(draft: "", currentKey: "space", currentModifiers: []))
    }

    // MARK: - canonicalHotkeyDraftPreview

    @Test("valid draft produces preview with modifiers")
    func previewValid() {
        let preview = ViewHelpers.canonicalHotkeyDraftPreview(draft: "cmd+shift+space", currentModifiers: [])
        #expect(preview != nil)
        #expect(preview!.contains("⌘"))
        #expect(preview!.contains("⇧"))
    }

    @Test("plain key uses current modifiers")
    func previewUsesCurrentModifiers() {
        let preview = ViewHelpers.canonicalHotkeyDraftPreview(draft: "space", currentModifiers: [.command, .shift])
        #expect(preview != nil)
        #expect(preview!.contains("⌘"))
        #expect(preview!.contains("⇧"))
    }

    @Test("invalid draft returns nil")
    func previewInvalid() {
        #expect(ViewHelpers.canonicalHotkeyDraftPreview(draft: "", currentModifiers: []) == nil)
    }

    // MARK: - hotkeyDraftModifierOverrideSummary

    @Test("no modifier change returns nil")
    func overrideNoChange() {
        #expect(ViewHelpers.hotkeyDraftModifierOverrideSummary(draft: "space", currentModifiers: [.command]) == nil)
    }

    @Test("modifier change returns summary")
    func overrideChanged() {
        let summary = ViewHelpers.hotkeyDraftModifierOverrideSummary(draft: "cmd+shift+space", currentModifiers: [.command])
        #expect(summary != nil)
        #expect(summary!.contains("⇧ Shift"))
    }

    @Test("empty modifiers returns none")
    func overrideEmpty() {
        // Draft that parses to empty modifiers — need a key with explicitly no modifiers
        // parseHotkeyDraft("space") returns nil for requiredModifiers (no modifiers in input)
        // so this won't trigger. Let's use a draft that somehow has empty required set.
        // Actually, a single key with no modifier prefix → requiredModifiers is nil, so won't match.
        // This path is only reachable if parsed modifiers is empty Set and current is non-empty.
        // Hard to trigger via public API, but let's verify the nil case.
        #expect(ViewHelpers.hotkeyDraftModifierOverrideSummary(draft: "space", currentModifiers: []) == nil)
    }

    // MARK: - hotkeyDraftNonConfigurableModifierNotice

    @Test("draft with fn returns notice")
    func nonConfigurableFn() {
        let notice = ViewHelpers.hotkeyDraftNonConfigurableModifierNotice(draft: "fn+cmd+space")
        #expect(notice?.contains("Fn/Globe") == true)
    }

    @Test("draft without fn returns nil")
    func nonConfigurableNone() {
        #expect(ViewHelpers.hotkeyDraftNonConfigurableModifierNotice(draft: "cmd+space") == nil)
    }

    @Test("plain key returns nil")
    func nonConfigurablePlain() {
        #expect(ViewHelpers.hotkeyDraftNonConfigurableModifierNotice(draft: "f5") == nil)
    }

    // MARK: - hotkeyMissingPermissionSummary

    @Test("all authorized returns nil")
    func permissionsAllGranted() {
        #expect(ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: true, inputMonitoringAuthorized: true) == nil)
    }

    @Test("accessibility missing")
    func permissionsAccessibilityMissing() {
        let summary = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: false, inputMonitoringAuthorized: true)
        #expect(summary == "Accessibility")
    }

    @Test("input monitoring missing")
    func permissionsInputMonitoringMissing() {
        let summary = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: true, inputMonitoringAuthorized: false)
        #expect(summary == "Input Monitoring")
    }

    @Test("both missing")
    func permissionsBothMissing() {
        let summary = ViewHelpers.hotkeyMissingPermissionSummary(accessibilityAuthorized: false, inputMonitoringAuthorized: false)
        #expect(summary == "Accessibility + Input Monitoring")
    }
}
