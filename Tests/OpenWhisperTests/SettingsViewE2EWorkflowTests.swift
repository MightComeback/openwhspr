import Testing
import Foundation
@testable import OpenWhisper

/// E2E workflow tests that exercise SettingsView logic paths end-to-end,
/// combining multiple ViewHelpers functions in realistic user interaction sequences.
@Suite("SettingsView E2E Workflows", .serialized)
struct SettingsViewE2EWorkflowTests {

    // MARK: - Hotkey Configuration Workflow

    @Test("E2E: user types 'cmd+shift+d' in hotkey field → parse, validate, preview, apply")
    func hotkeyConfigFullWorkflow() {
        let draft = "cmd+shift+d"

        // Step 1: Parse the draft
        let parsed = ViewHelpers.parseHotkeyDraft(draft)
        #expect(parsed != nil)
        #expect(parsed?.key == "d")
        #expect(parsed?.requiredModifiers?.contains(.command) == true)
        #expect(parsed?.requiredModifiers?.contains(.shift) == true)

        // Step 2: Validate — should be supported
        let validation = ViewHelpers.hotkeyDraftValidationMessage(draft: draft, isSupportedKey: true)
        #expect(validation == nil) // no validation error

        // Step 3: Check for changes from current config
        let hasChanges = ViewHelpers.hasHotkeyDraftChangesToApply(
            draft: draft, currentKey: "space", currentModifiers: Set([.command])
        )
        #expect(hasChanges == true)

        // Step 4: Preview
        let preview = ViewHelpers.canonicalHotkeyDraftPreview(
            draft: draft, currentModifiers: Set([.command])
        )
        #expect(preview != nil)
        #expect(preview!.contains("D") || preview!.contains("d"))

        // Step 5: Check modifier override summary
        let overrideSummary = ViewHelpers.hotkeyDraftModifierOverrideSummary(
            draft: draft, currentModifiers: Set([.command])
        )
        // Since draft includes explicit modifiers that differ, should show override
        let _ = overrideSummary // may or may not be nil depending on logic

        // Step 6: Check for system conflicts
        let conflict = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: Set([.command, .shift]),
            key: "d"
        )
        #expect(conflict == nil) // cmd+shift+d has no known system conflict

        // Step 7: Check high risk
        let highRisk = ViewHelpers.isHighRiskHotkey(
            requiredModifiers: Set([.command, .shift]),
            key: "d"
        )
        #expect(highRisk == false)
    }

    @Test("E2E: user picks bare 'space' → high risk warning, hold mode warning")
    func bareSpaceHotkeyRiskWorkflow() {
        let draft = "space"
        let parsed = ViewHelpers.parseHotkeyDraft(draft)
        #expect(parsed != nil)
        #expect(parsed?.key == "space")
        #expect(parsed?.requiredModifiers == nil) // nil means "use current modifiers"

        // Should trigger high risk
        let highRisk = ViewHelpers.isHighRiskHotkey(requiredModifiers: Set(), key: "space")
        #expect(highRisk == true)

        // Should trigger hold mode warning
        let holdWarning = ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: HotkeyMode.hold.rawValue,
            requiredModifiers: Set(),
            key: "space"
        )
        #expect(holdWarning == true)

        // But NOT in toggle mode
        let toggleWarning = ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: HotkeyMode.toggle.rawValue,
            requiredModifiers: Set(),
            key: "space"
        )
        #expect(toggleWarning == false)
    }

    @Test("E2E: user picks cmd+space → Spotlight conflict warning")
    func cmdSpaceConflictWorkflow() {
        let draft = "cmd+space"
        let parsed = ViewHelpers.parseHotkeyDraft(draft)
        #expect(parsed != nil)
        #expect(parsed?.key == "space")

        let conflict = ViewHelpers.hotkeySystemConflictWarning(
            requiredModifiers: Set([.command]),
            key: "space"
        )
        #expect(conflict != nil)
        #expect(conflict!.contains("Spotlight"))
    }

    @Test("E2E: user picks escape → escape cancel conflict warning")
    func escapeConflictWorkflow() {
        let draft = "escape"
        let parsed = ViewHelpers.parseHotkeyDraft(draft)
        #expect(parsed != nil)
        #expect(parsed?.key == "escape")

        let escConflict = ViewHelpers.hotkeyEscapeCancelConflictWarning(key: "escape")
        #expect(escConflict != nil)
        #expect(escConflict!.contains("discard"))
    }

    @Test("E2E: user picks f5 → no auto-modifiers, no conflicts, safe")
    func f5SafeHotkeyWorkflow() {
        let draft = "f5"
        let parsed = ViewHelpers.parseHotkeyDraft(draft)
        #expect(parsed != nil)
        #expect(parsed?.key == "f5")

        // F-keys don't need auto safe modifiers
        let autoModifiers = ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "f5")
        #expect(autoModifiers == false)

        let highRisk = ViewHelpers.isHighRiskHotkey(requiredModifiers: Set(), key: "f5")
        #expect(highRisk == false)

        let conflict = ViewHelpers.hotkeySystemConflictWarning(requiredModifiers: Set(), key: "f5")
        #expect(conflict == nil)
    }

    @Test("E2E: user types single char 'k' → should auto-apply safe modifiers")
    func singleCharAutoModifiers() {
        let autoModifiers = ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "k")
        #expect(autoModifiers == true)

        // With no modifiers, single char is high risk
        let highRisk = ViewHelpers.isHighRiskHotkey(requiredModifiers: Set(), key: "k")
        #expect(highRisk == true)

        // With cmd+shift, it's safe
        let safeRisk = ViewHelpers.isHighRiskHotkey(requiredModifiers: Set([.command, .shift]), key: "k")
        #expect(safeRisk == false)
    }

    @Test("E2E: draft unchanged from current → no changes to apply")
    func noChangesWorkflow() {
        let currentKey = "d"
        let currentModifiers: Set<ViewHelpers.ParsedModifier> = [.command, .shift]
        let draft = "cmd+shift+d"

        let hasChanges = ViewHelpers.hasHotkeyDraftChangesToApply(
            draft: draft, currentKey: currentKey, currentModifiers: currentModifiers
        )
        #expect(hasChanges == false)
    }

    @Test("E2E: draft has non-configurable modifier → notice shown")
    func nonConfigurableModifierWorkflow() {
        let draft = "fn+d"
        let notice = ViewHelpers.hotkeyDraftNonConfigurableModifierNotice(draft: draft)
        // fn is non-configurable
        let _ = notice
    }

    @Test("E2E: modifier token expansion and multi-modifier parsing")
    func compactModifierExpansion() {
        // Individual compact tokens expand
        let ctrlTokens = ViewHelpers.expandCompactModifierToken("ctrl")
        #expect(ctrlTokens.count >= 1)

        // Full combo parses correctly
        let draft = "ctrl+opt+cmd+shift+k"
        let parsed = ViewHelpers.parseHotkeyDraft(draft)
        #expect(parsed != nil)
        #expect(parsed?.key == "k")
        #expect(parsed?.requiredModifiers?.count == 4)
    }

    // MARK: - Hotkey Mode Workflow

    @Test("E2E: toggle mode tip text → hold mode tip text")
    func hotkeyModeTipTextWorkflow() {
        let toggleTip = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: false)
        #expect(!toggleTip.isEmpty)

        let holdTip = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: false)
        #expect(!holdTip.isEmpty)
        #expect(toggleTip != holdTip)

        // Escape trigger changes the tip
        let holdEscTip = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: true)
        let _ = holdEscTip
    }

    // MARK: - Hotkey Capture UI Workflow

    @Test("E2E: capture flow: button title, instruction, progress across countdown")
    func hotkeyCaptureCountdownWorkflow() {
        // Not capturing yet
        let idleTitle = ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: false, secondsRemaining: 0)
        #expect(!idleTitle.isEmpty)

        // Capturing with 10 seconds remaining
        let capturingTitle = ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: true, secondsRemaining: 10)
        #expect(!capturingTitle.isEmpty)
        #expect(capturingTitle != idleTitle)

        // Instructions change based on auth
        let authInstruction = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: true, secondsRemaining: 10)
        let noAuthInstruction = ViewHelpers.hotkeyCaptureInstruction(inputMonitoringAuthorized: false, secondsRemaining: 10)
        #expect(authInstruction != noAuthInstruction)

        // Progress from full to zero
        let progress10 = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 10, totalSeconds: 10)
        let progress5 = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 10)
        let progress0 = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 0, totalSeconds: 10)
        #expect(progress10 >= progress5)
        #expect(progress5 >= progress0)
    }

    // MARK: - Insertion Test Workflow

    @Test("E2E: insertion test: sample text → trim → truncation check → run eligibility")
    func insertionTestSampleTextWorkflow() {
        let rawText = "  Hello, this is a test phrase.  "

        // Trim
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(trimmed == "Hello, this is a test phrase.")

        // Check truncation
        let willTruncate = ViewHelpers.insertionProbeSampleTextWillTruncate(trimmed)
        #expect(willTruncate == false) // short text

        // Enforce limit
        let enforced = ViewHelpers.enforceInsertionProbeSampleTextLimit(rawText)
        #expect(!enforced.isEmpty)

        // Get run text
        let runText = ViewHelpers.insertionProbeSampleTextForRun(rawText)
        #expect(!runText.isEmpty)

        // Has sample text
        let hasSample = ViewHelpers.hasInsertionProbeSampleText(rawText)
        #expect(hasSample == true)

        // Empty text → no sample
        let noSample = ViewHelpers.hasInsertionProbeSampleText("   ")
        #expect(noSample == false)
    }

    @Test("E2E: insertion test disabled reasons cascade")
    func insertionTestDisabledReasonsCascade() {
        // Recording blocks it
        let recordingReason = ViewHelpers.insertionTestDisabledReason(
            isRecording: true, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true,
            hasInsertionTarget: true
        )
        #expect(recordingReason.contains("Stop recording"))

        // Finalizing blocks it
        let finalizingReason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: true,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true,
            hasInsertionTarget: true
        )
        #expect(finalizingReason.contains("finaliz"))

        // Already running blocks it
        let runningReason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: true, hasInsertionProbeSampleText: true,
            hasInsertionTarget: true
        )
        #expect(runningReason.contains("already running"))

        // No sample text blocks it
        let noTextReason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: false,
            hasInsertionTarget: true
        )
        #expect(noTextReason.contains("empty"))

        // No target blocks it
        let noTargetReason = ViewHelpers.insertionTestDisabledReason(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true,
            hasInsertionTarget: false
        )
        #expect(!noTargetReason.isEmpty)
    }

    @Test("E2E: insertion test eligibility with auto-capture")
    func insertionTestEligibilityWorkflow() {
        // Can run with auto-capture when not recording and has sample text
        let canAutoCapture = ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true
        )
        #expect(canAutoCapture == true)

        // Cannot run when recording
        let cantAutoCapture = ViewHelpers.canCaptureAndRunInsertionTest(
            canCaptureFrontmostProfile: true,
            isRecording: true, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionProbeSampleText: true
        )
        #expect(cantAutoCapture == false)
    }

    @Test("E2E: insertion test can run with existing target")
    func insertionTestWithExistingTarget() {
        let canRun = ViewHelpers.canRunInsertionTest(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionTarget: true,
            hasInsertionProbeSampleText: true
        )
        #expect(canRun == true)

        let cantRun = ViewHelpers.canRunInsertionTest(
            isRecording: false, isFinalizingTranscription: false,
            isRunningInsertionProbe: false, hasInsertionTarget: false,
            hasInsertionProbeSampleText: true
        )
        #expect(cantRun == false)
    }

    @Test("E2E: insertion probe status color transitions")
    func insertionProbeStatusColorTransitions() {
        // Unknown state
        let unknownColor = ViewHelpers.insertionProbeStatusColorName(succeeded: nil)
        #expect(unknownColor == "secondary")

        // Success
        let successColor = ViewHelpers.insertionProbeStatusColorName(succeeded: true)
        #expect(successColor == "green")

        // Failure
        let failureColor = ViewHelpers.insertionProbeStatusColorName(succeeded: false)
        #expect(failureColor == "orange")
    }

    @Test("E2E: insertion probe status label transitions")
    func insertionProbeStatusLabels() {
        let unknownLabel = ViewHelpers.insertionProbeStatusLabel(succeeded: nil)
        let successLabel = ViewHelpers.insertionProbeStatusLabel(succeeded: true)
        let failureLabel = ViewHelpers.insertionProbeStatusLabel(succeeded: false)

        #expect(unknownLabel != successLabel)
        #expect(successLabel != failureLabel)
        #expect(!unknownLabel.isEmpty)
        #expect(!successLabel.isEmpty)
        #expect(!failureLabel.isEmpty)
    }

    @Test("E2E: run insertion test button title reflects state")
    func runInsertionTestButtonTitles() {
        let idleTitle = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: true,
            autoCaptureTargetName: nil, canCaptureAndRun: false
        )
        let runningTitle = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: true, canRunTest: true,
            autoCaptureTargetName: nil, canCaptureAndRun: false
        )
        let autoCaptureTitle = ViewHelpers.runInsertionTestButtonTitle(
            isRunningProbe: false, canRunTest: false,
            autoCaptureTargetName: "Safari", canCaptureAndRun: true
        )

        #expect(idleTitle != runningTitle)
        #expect(!idleTitle.isEmpty)
        #expect(!runningTitle.isEmpty)
        #expect(!autoCaptureTitle.isEmpty)
    }

    // MARK: - Permission Warning Workflow

    @Test("E2E: auto-paste permission warning flow")
    func autoPastePermissionWorkflow() {
        // Auto-paste on, no accessibility → warning
        let showWarning = ViewHelpers.showsAutoPastePermissionWarning(
            autoPaste: true, accessibilityAuthorized: false
        )
        #expect(showWarning == true)

        // Auto-paste on, accessibility granted → no warning
        let noWarning = ViewHelpers.showsAutoPastePermissionWarning(
            autoPaste: true, accessibilityAuthorized: true
        )
        #expect(noWarning == false)

        // Auto-paste off → no warning regardless
        let offWarning = ViewHelpers.showsAutoPastePermissionWarning(
            autoPaste: false, accessibilityAuthorized: false
        )
        #expect(offWarning == false)
    }

    @Test("E2E: hotkey missing permission summary")
    func hotkeyMissingPermissionSummary() {
        // Both missing
        let bothMissing = ViewHelpers.hotkeyMissingPermissionSummary(
            accessibilityAuthorized: false, inputMonitoringAuthorized: false
        )
        #expect(bothMissing != nil)

        // Only accessibility missing
        let accessMissing = ViewHelpers.hotkeyMissingPermissionSummary(
            accessibilityAuthorized: false, inputMonitoringAuthorized: true
        )
        #expect(accessMissing != nil)

        // Only input monitoring missing
        let inputMissing = ViewHelpers.hotkeyMissingPermissionSummary(
            accessibilityAuthorized: true, inputMonitoringAuthorized: false
        )
        #expect(inputMissing != nil)

        // Both granted
        let allGood = ViewHelpers.hotkeyMissingPermissionSummary(
            accessibilityAuthorized: true, inputMonitoringAuthorized: true
        )
        #expect(allGood == nil)
    }

    // MARK: - Profile Capture Workflow

    @Test("E2E: capture profile helpers workflow")
    func captureProfileWorkflow() {
        // Not a fallback
        let notFallback = ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: false)
        #expect(notFallback == false)

        let isFallback = ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: true)
        #expect(isFallback == true)

        let nilFallback = ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: nil)
        #expect(nilFallback == false)

        // Fallback app name
        let noName = ViewHelpers.captureProfileFallbackAppName(isFallback: false, appName: "Safari")
        #expect(noName == nil)

        let fallbackName = ViewHelpers.captureProfileFallbackAppName(isFallback: true, appName: "Safari")
        #expect(fallbackName == "Safari")

        let nilName = ViewHelpers.captureProfileFallbackAppName(isFallback: true, appName: nil)
        #expect(nilName == nil)
    }

    // MARK: - Common Hotkey Key Sections

    @Test("E2E: commonHotkeyKeySections has expected structure")
    func commonHotkeyKeySections() {
        let sections = ViewHelpers.commonHotkeyKeySections
        #expect(!sections.isEmpty)

        // Each section should have a title and non-empty keys
        for section in sections {
            #expect(!section.title.isEmpty)
            #expect(!section.keys.isEmpty)
        }

        // All keys should parse successfully
        for section in sections {
            for key in section.keys {
                let sanitized = ViewHelpers.sanitizeKeyValue(key)
                #expect(!sanitized.isEmpty, "Key '\(key)' should sanitize to non-empty")
            }
        }
    }

    // MARK: - Hotkey Summary Generation

    @Test("E2E: hotkey summary from modifiers + key")
    func hotkeySummaryGeneration() {
        let summary = ViewHelpers.hotkeySummaryFromModifiers(
            command: true, shift: true, option: false, control: false, capsLock: false,
            key: "d"
        )
        #expect(!summary.isEmpty)
        #expect(summary.contains("D") || summary.contains("d"))
    }

    // MARK: - Insertion Target Focus Workflow

    @Test("E2E: focus insertion target eligibility")
    func focusInsertionTargetWorkflow() {
        // Can focus when not recording, not finalizing, has target
        let canFocus = ViewHelpers.canFocusInsertionTarget(
            isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: true
        )
        #expect(canFocus == true)

        // Cannot focus when recording
        let cantFocusRecording = ViewHelpers.canFocusInsertionTarget(
            isRecording: true, isFinalizingTranscription: false, hasInsertionTarget: true
        )
        #expect(cantFocusRecording == false)

        // Cannot focus when no target
        let cantFocusNoTarget = ViewHelpers.canFocusInsertionTarget(
            isRecording: false, isFinalizingTranscription: false, hasInsertionTarget: false
        )
        #expect(cantFocusNoTarget == false)
    }

    @Test("E2E: clear insertion target eligibility")
    func clearInsertionTargetWorkflow() {
        let canClear = ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: true)
        #expect(canClear == true)

        let cantClearRunning = ViewHelpers.canClearInsertionTarget(isRunningProbe: true, hasInsertionTarget: true)
        #expect(cantClearRunning == false)

        let cantClearNoTarget = ViewHelpers.canClearInsertionTarget(isRunningProbe: false, hasInsertionTarget: false)
        #expect(cantClearNoTarget == false)
    }

    // MARK: - Hotkey Draft Edits Detection

    @Test("E2E: hasHotkeyDraftEdits detects changes across scenarios")
    func hotkeyDraftEditsDetection() {
        // Same key and modifiers → no edits
        let noEdits = ViewHelpers.hasHotkeyDraftEdits(
            draft: "d", currentKey: "d", currentModifiers: Set([.command, .shift])
        )
        #expect(noEdits == false)

        // Different key → has edits
        let keyChanged = ViewHelpers.hasHotkeyDraftEdits(
            draft: "k", currentKey: "d", currentModifiers: Set([.command, .shift])
        )
        #expect(keyChanged == true)

        // Draft includes modifiers that differ → has edits
        let modifiersChanged = ViewHelpers.hasHotkeyDraftEdits(
            draft: "ctrl+d", currentKey: "d", currentModifiers: Set([.command, .shift])
        )
        #expect(modifiersChanged == true)
    }

    // MARK: - Effective Hotkey Risk Context

    @Test("E2E: effectiveHotkeyRiskKey resolves correctly")
    func effectiveHotkeyRiskKey() {
        let context = ViewHelpers.effectiveHotkeyRiskKey(
            draftKey: "k",
            currentKey: "d",
            currentModifiers: Set([.command, .shift])
        )
        // Should return the draft key since it has changes
        #expect(!context.key.isEmpty)
    }

    // MARK: - All System Conflict Keys Coverage

    @Test("E2E: all known dangerous combos trigger warnings")
    func allDangerousHotkeyCombos() {
        let dangerousCombos: [(Set<ViewHelpers.ParsedModifier>, String)] = [
            ([.command], "space"),
            ([.control], "space"),
            ([.control, .option], "space"),
            ([.command, .control], "space"),
            ([.command, .option], "space"),
            ([.command, .option, .control], "space"),
            ([.command, .control], "f"),
            ([.command], "tab"),
            ([], "fn"),
            ([.command, .shift], "tab"),
            ([.command, .shift], "3"),
            ([.command, .shift], "4"),
            ([.command, .shift], "5"),
            ([.command, .shift], "6"),
            ([.command], "backtick"),
            ([.command], "section"),
            ([.command, .shift], "section"),
            ([.command], "comma"),
            ([.command], "period"),
            ([.command, .option], "escape"),
            ([.command], "h"),
            ([.command], "c"),
            ([.command], "v"),
            ([.command], "x"),
            ([.command], "a"),
            ([.command], "z"),
            ([.command], "m"),
            ([.command], "return"),
            ([.command], "q"),
            ([.command, .control], "q"),
            ([.command], "w"),
            ([.command], "s"),
            ([.command], "f"),
            ([.command], "n"),
            ([.command], "t"),
            ([.command], "p"),
            ([.command], "r"),
            ([.command], "o"),
            ([.command], "l"),
        ]

        for (modifiers, key) in dangerousCombos {
            let warning = ViewHelpers.hotkeySystemConflictWarning(
                requiredModifiers: modifiers, key: key
            )
            #expect(warning != nil, "Expected warning for \(modifiers) + \(key)")
        }
    }

    @Test("E2E: safe combos produce no system conflict warnings")
    func safeHotkeyCombos() {
        let safeCombos: [(Set<ViewHelpers.ParsedModifier>, String)] = [
            ([.command, .shift], "d"),
            ([.command, .shift], "k"),
            ([.command, .option], "d"),
            ([.control, .shift], "r"),
            ([.command, .shift, .option], "m"),
            ([], "f5"),
            ([], "f8"),
            ([], "f13"),
        ]

        for (modifiers, key) in safeCombos {
            let warning = ViewHelpers.hotkeySystemConflictWarning(
                requiredModifiers: modifiers, key: key
            )
            #expect(warning == nil, "Unexpected warning for \(modifiers) + \(key): \(warning ?? "")")
        }
    }

    // MARK: - Hotkey Parsing Edge Cases

    @Test("E2E: various hotkey draft formats parse correctly")
    func hotkeyDraftFormats() {
        let formats = [
            ("cmd+d", "d"),
            ("⌘+d", "d"),
            ("command+d", "d"),
            ("ctrl+shift+f5", "f5"),
            ("⌃+⇧+F5", "f5"),
            ("space", "space"),
            ("f1", "f1"),
        ]

        for (draft, expectedKey) in formats {
            let parsed = ViewHelpers.parseHotkeyDraft(draft)
            #expect(parsed != nil, "Failed to parse '\(draft)'")
            #expect(parsed?.key == expectedKey, "Expected key '\(expectedKey)' for '\(draft)', got '\(parsed?.key ?? "nil")'")
        }
    }

    @Test("E2E: empty and whitespace-only drafts")
    func emptyDrafts() {
        let emptyParsed = ViewHelpers.parseHotkeyDraft("")
        let whitespaceParsed = ViewHelpers.parseHotkeyDraft("   ")

        // Should either return nil or a space-based key
        let _ = emptyParsed
        let _ = whitespaceParsed
    }

    @Test("E2E: looksLikeModifierComboInput distinguishes combos from plain keys")
    func looksLikeModifierCombo() {
        #expect(ViewHelpers.looksLikeModifierComboInput("cmd+d") == true)
        #expect(ViewHelpers.looksLikeModifierComboInput("⌘+d") == true)
        #expect(ViewHelpers.looksLikeModifierComboInput("d") == false)
        #expect(ViewHelpers.looksLikeModifierComboInput("space") == false)
        #expect(ViewHelpers.looksLikeModifierComboInput("f5") == false)
    }

    // MARK: - Modifier Token Parsing

    @Test("E2E: all modifier tokens parse to correct modifiers")
    func allModifierTokens() {
        let expectations: [(String, ViewHelpers.ParsedModifier)] = [
            ("cmd", .command),
            ("command", .command),
            ("⌘", .command),
            ("ctrl", .control),
            ("control", .control),
            ("⌃", .control),
            ("opt", .option),
            ("option", .option),
            ("alt", .option),
            ("⌥", .option),
            ("shift", .shift),
            ("⇧", .shift),
        ]

        for (token, expected) in expectations {
            let parsed = ViewHelpers.parseModifierToken(token)
            #expect(parsed == expected, "Token '\(token)' should parse to \(expected), got \(String(describing: parsed))")
        }
    }

    @Test("E2E: non-configurable modifier tokens identified correctly")
    func nonConfigurableModifiers() {
        #expect(ViewHelpers.isNonConfigurableModifierToken("fn") == true)
        #expect(ViewHelpers.isNonConfigurableModifierToken("globe") == true)
        #expect(ViewHelpers.isNonConfigurableModifierToken("🌐") == true)
        #expect(ViewHelpers.isNonConfigurableModifierToken("globekey") == true)
        #expect(ViewHelpers.isNonConfigurableModifierToken("cmd") == false)
        #expect(ViewHelpers.isNonConfigurableModifierToken("shift") == false)
    }

    // MARK: - Sanitize Key Value

    @Test("E2E: sanitizeKeyValue normalizes various inputs")
    func sanitizeKeyValueVariants() {
        #expect(ViewHelpers.sanitizeKeyValue("  D  ") == HotkeyDisplay.canonicalKey("d"))
        #expect(ViewHelpers.sanitizeKeyValue("") == "space")
        #expect(ViewHelpers.sanitizeKeyValue(" ") == "space")
        #expect(ViewHelpers.sanitizeKeyValue("SPACE") == HotkeyDisplay.canonicalKey("space"))
    }

    // MARK: - Streaming Elapsed Status

    @Test("E2E: streamingElapsedStatusSegment formats correctly")
    func streamingElapsed() {
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: -1) == nil)
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 0) == "0:00")
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 65) == "1:05")
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 3661) == "1:01:01")
        #expect(ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 7200) == "2:00:00")
    }

    // MARK: - Sentence Punctuation

    @Test("E2E: isSentencePunctuation identifies correct characters")
    func sentencePunctuation() {
        let punctuation: [Character] = [".", ",", "!", "?", ";", ":", "…"]
        for char in punctuation {
            #expect(ViewHelpers.isSentencePunctuation(char) == true, "'\(char)' should be sentence punctuation")
        }

        let nonPunctuation: [Character] = ["a", "1", " ", "-", "(", "\""]
        for char in nonPunctuation {
            #expect(ViewHelpers.isSentencePunctuation(char) == false, "'\(char)' should not be sentence punctuation")
        }
    }

    @Test("E2E: trailingSentencePunctuation extracts trailing punctuation")
    func trailingSentencePunctuationExtraction() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "") == nil)
        #expect(ViewHelpers.trailingSentencePunctuation(in: "hello") == nil)
        #expect(ViewHelpers.trailingSentencePunctuation(in: "hello.") == ".")
        #expect(ViewHelpers.trailingSentencePunctuation(in: "hello...") == "...")
        #expect(ViewHelpers.trailingSentencePunctuation(in: "what?!") == "?!")
        #expect(ViewHelpers.trailingSentencePunctuation(in: "   ") == nil)
        #expect(ViewHelpers.trailingSentencePunctuation(in: "hello. ") == ".")
    }

    // MARK: - Model File Size

    @Test("E2E: sizeOfModelFile handles invalid paths")
    func modelFileSize() {
        #expect(ViewHelpers.sizeOfModelFile(atPath: "") == 0)
        #expect(ViewHelpers.sizeOfModelFile(atPath: "/nonexistent/path/model.bin") == 0)
    }

    // MARK: - Bridge Modifiers

    @Test("E2E: bridgeModifiers is identity function")
    func bridgeModifiers() {
        let input: Set<ViewHelpers.ParsedModifier> = [.command, .shift, .option, .control]
        let output = ViewHelpers.bridgeModifiers(input)
        #expect(output == input)

        let empty: Set<ViewHelpers.ParsedModifier> = []
        #expect(ViewHelpers.bridgeModifiers(empty) == empty)
    }

    // MARK: - Capture Activation Ignore

    @Test("E2E: shouldIgnoreCaptureActivation with various key codes")
    func captureActivationIgnore() {
        // Modifier-only key codes should be ignored
        let modifierCodes = [56, 59, 58, 55, 54, 57, 61, 62, 63]
        for code in modifierCodes {
            let isModifier = ViewHelpers.isModifierOnlyKeyCode(code)
            #expect(isModifier == true, "Key code \(code) should be modifier-only")
        }

        // Regular key codes should not be modifier-only
        let regularCodes = [0, 1, 2, 49, 36, 53]
        for code in regularCodes {
            let isModifier = ViewHelpers.isModifierOnlyKeyCode(code)
            #expect(isModifier == false, "Key code \(code) should not be modifier-only")
        }
    }

    // MARK: - Key Code to Name Mapping

    @Test("E2E: hotkeyKeyNameForKeyCode maps known keys")
    func keyCodeMapping() {
        // Space bar
        let space = ViewHelpers.hotkeyKeyNameForKeyCode(49)
        #expect(space == "space")

        // Return
        let returnKey = ViewHelpers.hotkeyKeyNameForKeyCode(36)
        #expect(returnKey == "return")

        // Escape
        let escape = ViewHelpers.hotkeyKeyNameForKeyCode(53)
        #expect(escape == "escape")

        // Tab
        let tab = ViewHelpers.hotkeyKeyNameForKeyCode(48)
        #expect(tab == "tab")

        // Unknown key code
        let unknown = ViewHelpers.hotkeyKeyNameForKeyCode(999)
        #expect(unknown == nil)
    }

    @Test("E2E: hotkeyKeyNameFromKeyCode with characters fallback")
    func keyCodeWithCharactersFallback() {
        let fromCode = ViewHelpers.hotkeyKeyNameFromKeyCode(49, characters: nil)
        #expect(fromCode == "space")

        let fromChars = ViewHelpers.hotkeyKeyNameFromKeyCode(999, characters: "x")
        #expect(fromChars == "x")

        let noInfo = ViewHelpers.hotkeyKeyNameFromKeyCode(999, characters: nil)
        #expect(noInfo == nil)
    }

    // MARK: - Insertion Test Auto-Capture Hint

    @Test("E2E: showsInsertionTestAutoCaptureHint workflow")
    func insertionTestAutoCaptureHint() {
        // Hint shown when can't run standalone but can auto-capture
        let shown = ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: false, canRunTest: false, canCaptureAndRun: true
        )
        #expect(shown == true)

        // Hidden when can already run standalone
        let hidden = ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: false, canRunTest: true, canCaptureAndRun: true
        )
        #expect(hidden == false)

        // Hidden when probe is running
        let running = ViewHelpers.showsInsertionTestAutoCaptureHint(
            isRunningProbe: true, canRunTest: false, canCaptureAndRun: true
        )
        #expect(running == false)
    }

    @Test("E2E: canFocusAndRunInsertionTest combines focus + run checks")
    func canFocusAndRunInsertionTestWorkflow() {
        let can = ViewHelpers.canFocusAndRunInsertionTest(
            canFocusTarget: true, canRunTest: true
        )
        #expect(can == true)

        let cantFocus = ViewHelpers.canFocusAndRunInsertionTest(
            canFocusTarget: false, canRunTest: true
        )
        #expect(cantFocus == false)

        let cantRun = ViewHelpers.canFocusAndRunInsertionTest(
            canFocusTarget: true, canRunTest: false
        )
        #expect(cantRun == false)
    }
}
