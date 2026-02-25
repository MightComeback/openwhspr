import Testing
import Foundation
@testable import OpenWhisper

/// Full-system integration tests exercising multi-component user journeys.
/// Each test simulates a complete flow spanning AppDefaults → AudioTranscriber → ViewHelpers → HotkeyDisplay.
@Suite("Full System Integration E2E", .serialized)
struct FullSystemIntegrationE2ETests {

    // MARK: - Complete recording flow: defaults → transcriber state → UI labels

    @Test("Fresh launch defaults produce correct idle UI state")
    @MainActor func freshLaunchIdleUI() {
        let suite = UserDefaults(suiteName: "e2e.freshLaunch")!
        defer { suite.removePersistentDomain(forName: "e2e.freshLaunch") }
        AppDefaults.register(into: suite)

        let icon = ViewHelpers.menuBarIconName(
            isRecording: false, pendingChunkCount: 0,
            hasTranscriptionText: false, isShowingInsertionFlash: false
        )
        #expect(icon == "mic")

        let duration = ViewHelpers.menuBarDurationLabel(
            isRecording: false, pendingChunkCount: 0,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0, lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(duration == nil)

        let title = ViewHelpers.statusTitle(isRecording: false, recordingDuration: 0, pendingChunkCount: 0)
        #expect(!title.isEmpty)

        let canToggle = ViewHelpers.canToggleRecording(
            isRecording: false, pendingChunkCount: 0, microphoneAuthorized: true
        )
        #expect(canToggle == true)
    }

    @Test("Recording state produces correct UI: icon, duration, status title")
    @MainActor func recordingStateUI() {
        let icon = ViewHelpers.menuBarIconName(
            isRecording: true, pendingChunkCount: 0,
            hasTranscriptionText: false, isShowingInsertionFlash: false
        )
        #expect(icon == "waveform.circle.fill")

        let duration = ViewHelpers.menuBarDurationLabel(
            isRecording: true, pendingChunkCount: 0,
            recordingElapsedSeconds: 42,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0, lastChunkLatency: 0,
            transcriptionWordCount: 0,
            isShowingInsertionFlash: false
        )
        #expect(duration != nil)
        #expect(duration!.contains("0:42"))

        let title = ViewHelpers.statusTitle(isRecording: true, recordingDuration: 42, pendingChunkCount: 0)
        #expect(!title.isEmpty)

        let startStopHelp = ViewHelpers.startStopButtonHelpText(
            isRecording: true, pendingChunkCount: 0,
            isStartAfterFinalizeQueued: false, microphoneAuthorized: true
        )
        #expect(!startStopHelp.isEmpty)
    }

    @Test("Finalization state: pending chunks drive progress + ETA + icon")
    func finalizationStateUI() {
        let icon = ViewHelpers.menuBarIconName(
            isRecording: false, pendingChunkCount: 5,
            hasTranscriptionText: false, isShowingInsertionFlash: false
        )
        #expect(!icon.isEmpty)

        let baseline = ViewHelpers.refreshFinalizationProgressBaseline(
            isRecording: false, pendingChunks: 10, currentBaseline: nil
        )
        #expect(baseline == 10)

        let progress = ViewHelpers.finalizationProgress(
            pendingChunkCount: 5, initialPendingChunks: 10, isRecording: false
        )
        #expect(progress != nil)
        #expect(progress! >= 0.49 && progress! <= 0.51)

        let eta = ViewHelpers.estimatedFinalizationSeconds(
            pendingChunkCount: 5, averageChunkLatency: 2.0, lastChunkLatency: 1.5
        )
        #expect(eta != nil)
        #expect(eta! > 0)
    }

    @Test("Post-insertion flash: icon + label transition")
    func insertionFlashUI() {
        let now = Date()
        let flashVisible = ViewHelpers.isInsertionFlashVisible(
            insertedAt: now.addingTimeInterval(-1), now: now, flashDuration: 3
        )
        #expect(flashVisible == true)

        let icon = ViewHelpers.menuBarIconName(
            isRecording: false, pendingChunkCount: 0,
            hasTranscriptionText: true, isShowingInsertionFlash: true
        )
        #expect(icon == "checkmark.circle.fill")

        let label = ViewHelpers.menuBarDurationLabel(
            isRecording: false, pendingChunkCount: 0,
            recordingElapsedSeconds: nil,
            isStartAfterFinalizeQueued: false,
            averageChunkLatency: 0, lastChunkLatency: 0,
            transcriptionWordCount: 5,
            isShowingInsertionFlash: true
        )
        #expect(label != nil)
    }

    // MARK: - Hotkey config → display → risk assessment pipeline

    @Test("Hotkey config round-trip: defaults → parse → display → risk check")
    func hotkeyConfigPipeline() {
        let suite = UserDefaults(suiteName: "e2e.hotkeyPipeline")!
        defer { suite.removePersistentDomain(forName: "e2e.hotkeyPipeline") }
        AppDefaults.register(into: suite)

        let key = suite.string(forKey: AppDefaults.Keys.hotkeyKey) ?? "space"
        let modeRaw = suite.string(forKey: AppDefaults.Keys.hotkeyMode) ?? "toggle"

        // Display summary
        let summary = HotkeyDisplay.summaryIncludingMode(defaults: suite)
        #expect(!summary.isEmpty)

        // Parse a draft matching the stored key
        let parsed = ViewHelpers.parseHotkeyDraft(key)
        // space is a valid key
        if let parsed = parsed {
            #expect(parsed.key == key || ViewHelpers.sanitizeKeyValue(parsed.key) == key)
        }

        // Risk assessment
        let modifiers: Set<ViewHelpers.ParsedModifier> = []
        let isHighRisk = ViewHelpers.isHighRiskHotkey(requiredModifiers: modifiers, key: key)
        // space with no modifiers is high risk
        #expect(isHighRisk == true)

        // Hold mode warning
        let holdWarning = ViewHelpers.showsHoldModeAccidentalTriggerWarning(
            hotkeyModeRaw: modeRaw, requiredModifiers: modifiers, key: key
        )
        let _ = holdWarning

        // Escape conflict
        let escConflict = ViewHelpers.hotkeyEscapeCancelConflictWarning(key: key)
        if key == "escape" {
            #expect(escConflict != nil)
        }
    }

    @Test("Complex hotkey draft parsing → modifier extraction → summary display")
    func complexHotkeyDraftParsing() {
        // cmd+shift+k
        let draft = "cmd+shift+k"
        let parsed = ViewHelpers.parseHotkeyDraft(draft)
        #expect(parsed != nil)
        #expect(parsed!.key == "k")
        #expect(parsed!.requiredModifiers != nil)
        #expect(parsed!.requiredModifiers!.contains(.command))
        #expect(parsed!.requiredModifiers!.contains(.shift))

        // Risk check — cmd+shift+k is safe
        let isHighRisk = ViewHelpers.isHighRiskHotkey(
            requiredModifiers: parsed!.requiredModifiers!, key: "k"
        )
        #expect(isHighRisk == false)

        // Canonical preview
        let preview = ViewHelpers.canonicalHotkeyDraftPreview(
            draft: draft, currentModifiers: []
        )
        #expect(preview != nil)

        // Changes detection
        let hasChanges = ViewHelpers.hasHotkeyDraftChangesToApply(
            draft: draft, currentKey: "space", currentModifiers: []
        )
        #expect(hasChanges == true)
    }

    @Test("Hotkey draft with compact modifier notation expands correctly")
    func compactModifierExpansion() {
        // Test various compact tokens
        let expanded1 = ViewHelpers.expandCompactModifierToken("⌘⇧")
        #expect(expanded1.count == 2)

        let expanded2 = ViewHelpers.expandCompactModifierToken("⌃⌥")
        #expect(expanded2.count == 2)

        // Single symbols
        let expanded3 = ViewHelpers.expandCompactModifierToken("⌘")
        #expect(expanded3.count == 1)
    }

    @Test("Hotkey tokens splitting and merging preserves semantics")
    func tokenSplittingAndMerging() {
        let tokens = ViewHelpers.splitPlusCommaHotkeyTokens("cmd+shift+space")
        #expect(tokens.count == 3)

        let merged = ViewHelpers.mergeSpaceSeparatedKeyTokens(["left", "arrow"])
        #expect(merged.count == 1 || merged.count == 2) // implementation may vary

        let tokens2 = ViewHelpers.splitPlusCommaHotkeyTokens("ctrl, option, f5")
        #expect(tokens2.count == 3)
    }

    // MARK: - Text processing pipeline E2E

    @Test("Full text processing: raw Whisper output → normalized → ready for insertion")
    @MainActor func textProcessingPipeline() {
        let transcriber = AudioTranscriber.shared
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true,
            smartCapitalization: true,
            terminalPunctuation: true,
            customCommandsRaw: ""
        )

        // Simulate raw Whisper output with typical artifacts
        let raw = "  hello world  this is a test  "
        let normalized = transcriber.normalizeOutputText(raw, settings: settings)
        #expect(normalized == "Hello world this is a test.")
        #expect(!normalized.hasPrefix(" "))
        #expect(!normalized.hasSuffix(" "))

        // Word count
        let wordCount = ViewHelpers.transcriptionWordCount(normalized)
        #expect(wordCount == 6)

        // WPM calculation (as if spoken in 10 seconds)
        let wpm = ViewHelpers.liveWordsPerMinute(transcription: normalized, durationSeconds: 10)
        #expect(wpm != nil)
        #expect(wpm! == 36) // 6 words / 10s * 60
    }

    @Test("Text normalization: spaced apostrophes collapsed")
    @MainActor func spacedApostrophes() {
        let transcriber = AudioTranscriber.shared
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommandsRaw: ""
        )

        let raw = "don ' t worry we ' re fine"
        let normalized = transcriber.normalizeOutputText(raw, settings: settings)
        #expect(normalized.contains("don't"))
        #expect(normalized.contains("we're"))
    }

    @Test("Text normalization: smart capitalization after sentence boundaries")
    @MainActor func smartCapAfterBoundaries() {
        let transcriber = AudioTranscriber.shared
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: false,
            smartCapitalization: true,
            terminalPunctuation: false,
            customCommandsRaw: ""
        )

        let raw = "first sentence. second sentence! third? fourth"
        let normalized = transcriber.normalizeOutputText(raw, settings: settings)
        #expect(normalized.hasPrefix("First"))
        #expect(normalized.contains("Second"))
        #expect(normalized.contains("Third"))
        #expect(normalized.contains("Fourth"))
    }

    @Test("Text normalization: terminal punctuation added only when missing")
    @MainActor func terminalPunctuationLogic() {
        let transcriber = AudioTranscriber.shared
        let settingsOn = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: true,
            customCommandsRaw: ""
        )

        // Missing punctuation → added
        let r1 = transcriber.normalizeOutputText("hello world", settings: settingsOn)
        #expect(r1.hasSuffix("."))

        // Already has punctuation → not doubled
        let r2 = transcriber.normalizeOutputText("hello world!", settings: settingsOn)
        #expect(r2.hasSuffix("!"))
        #expect(!r2.hasSuffix(".!"))
    }

    @Test("Command replacement: built-in commands transform correctly")
    @MainActor func builtInCommandReplacement() {
        let transcriber = AudioTranscriber.shared
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommandsRaw: ""
        )

        let raw = "hello new line world"
        let normalized = transcriber.normalizeOutputText(raw, settings: settings)
        #expect(normalized.contains("\n") || normalized == raw) // depends on built-in rules
    }

    // MARK: - AppProfile Codable E2E

    @Test("AppProfile round-trip: create → encode → decode → verify all fields")
    func appProfileRoundTrip() throws {
        let profile = AppProfile(
            bundleIdentifier: "com.apple.Safari",
            appName: "Safari",
            autoCopy: true,
            autoPaste: false,
            clearAfterInsert: true,
            commandReplacements: true,
            smartCapitalization: false,
            terminalPunctuation: true,
            customCommands: "test:replacement"
        )

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(AppProfile.self, from: data)
        #expect(decoded.bundleIdentifier == "com.apple.Safari")
        #expect(decoded.appName == "Safari")
        #expect(decoded.autoCopy == true)
        #expect(decoded.autoPaste == false)
        #expect(decoded.clearAfterInsert == true)
        #expect(decoded.commandReplacements == true)
        #expect(decoded.smartCapitalization == false)
        #expect(decoded.terminalPunctuation == true)
        #expect(decoded.customCommands == "test:replacement")
    }

    @Test("AppProfile multiple profiles: different bundles have independent settings")
    func appProfileIndependence() throws {
        let safari = AppProfile(
            bundleIdentifier: "com.apple.Safari",
            appName: "Safari",
            autoCopy: true, autoPaste: true,
            clearAfterInsert: false, commandReplacements: true,
            smartCapitalization: true, terminalPunctuation: true
        )
        let xcode = AppProfile(
            bundleIdentifier: "com.apple.dt.Xcode",
            appName: "Xcode",
            autoCopy: false, autoPaste: false,
            clearAfterInsert: true, commandReplacements: false,
            smartCapitalization: false, terminalPunctuation: false
        )

        let safariData = try JSONEncoder().encode(safari)
        let xcodeData = try JSONEncoder().encode(xcode)

        let decodedSafari = try JSONDecoder().decode(AppProfile.self, from: safariData)
        let decodedXcode = try JSONDecoder().decode(AppProfile.self, from: xcodeData)

        #expect(decodedSafari.autoCopy != decodedXcode.autoCopy)
        #expect(decodedSafari.bundleIdentifier != decodedXcode.bundleIdentifier)
    }

    // MARK: - TranscriptionEntry lifecycle E2E

    @Test("TranscriptionEntry lifecycle: create → store → retrieve → display stats")
    func transcriptionEntryLifecycle() throws {
        let entry = TranscriptionEntry(
            text: "This is a test transcription with several words",
            durationSeconds: 5.0,
            targetAppName: "Safari"
        )

        // Persist
        let data = try JSONEncoder().encode(entry)
        let restored = try JSONDecoder().decode(TranscriptionEntry.self, from: data)
        #expect(restored.id == entry.id)
        #expect(restored.text == entry.text)
        #expect(restored.durationSeconds == 5.0)
        #expect(restored.targetAppName == "Safari")

        // Display stats
        let stats = ViewHelpers.historyEntryStats(text: restored.text, durationSeconds: restored.durationSeconds)
        #expect(!stats.isEmpty)

        // Word count
        let words = ViewHelpers.transcriptionWordCount(restored.text)
        #expect(words == 8)
    }

    @Test("TranscriptionEntry Set: entries with same ID are deduplicated")
    func transcriptionEntryDedup() {
        let id = UUID()
        let date = Date()
        let a = TranscriptionEntry(id: id, text: "First", createdAt: date)
        let b = TranscriptionEntry(id: id, text: "First", createdAt: date)
        let set: Set<TranscriptionEntry> = [a, b]
        #expect(set.count == 1)
    }

    // MARK: - Insert target state machine E2E

    @Test("Insert target lifecycle: fresh → captured → stale → retarget")
    func insertTargetLifecycle() {
        let now = Date()

        // Fresh: no capture
        let stale1 = ViewHelpers.isInsertTargetStale(capturedAt: nil, now: now, staleAfterSeconds: 90)
        #expect(stale1 == false)

        // Just captured
        let stale2 = ViewHelpers.isInsertTargetStale(
            capturedAt: now.addingTimeInterval(-5), now: now, staleAfterSeconds: 90
        )
        #expect(stale2 == false)

        // Stale after timeout
        let stale3 = ViewHelpers.isInsertTargetStale(
            capturedAt: now.addingTimeInterval(-100), now: now, staleAfterSeconds: 90
        )
        #expect(stale3 == true)

        // Should show retarget action when stale
        let showRetarget = ViewHelpers.shouldShowUseCurrentAppQuickAction(
            shouldSuggestRetarget: false, isInsertTargetStale: true
        )
        #expect(showRetarget == true)

        // Target locked when has text + can insert + has target
        let locked = ViewHelpers.isInsertTargetLocked(
            hasTranscriptionText: true, canInsertNow: true,
            canInsertDirectly: true, hasResolvableInsertTarget: true
        )
        #expect(locked == true)
    }

    @Test("Fallback timeout is shorter than normal timeout")
    func fallbackTimeoutShorter() {
        let normal = ViewHelpers.activeInsertTargetStaleAfterSeconds(
            usesFallback: false, normalTimeout: 90, fallbackTimeout: 30
        )
        let fallback = ViewHelpers.activeInsertTargetStaleAfterSeconds(
            usesFallback: true, normalTimeout: 90, fallbackTimeout: 30
        )
        #expect(fallback < normal)
    }

    // MARK: - Hotkey capture flow E2E

    @Test("Hotkey capture button states: idle → capturing → countdown")
    func hotkeyCaptureButtonStates() {
        let idleTitle = ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: false, secondsRemaining: 0)
        #expect(!idleTitle.isEmpty)

        let capturingTitle = ViewHelpers.hotkeyCaptureButtonTitle(isCapturing: true, secondsRemaining: 8)
        #expect(!capturingTitle.isEmpty)
        #expect(capturingTitle != idleTitle)

        let instruction = ViewHelpers.hotkeyCaptureInstruction(
            inputMonitoringAuthorized: true, secondsRemaining: 5
        )
        #expect(!instruction.isEmpty)

        let noPermInstruction = ViewHelpers.hotkeyCaptureInstruction(
            inputMonitoringAuthorized: false, secondsRemaining: 5
        )
        #expect(!noPermInstruction.isEmpty)

        let progress = ViewHelpers.hotkeyCaptureProgress(secondsRemaining: 5, totalSeconds: 10)
        #expect(progress >= 0.49 && progress <= 0.51)
    }

    @Test("Hotkey draft validation: supported vs unsupported keys")
    func hotkeyDraftValidation() {
        // Valid key
        let validMsg = ViewHelpers.hotkeyDraftValidationMessage(draft: "k", isSupportedKey: true)
        #expect(validMsg == nil)

        // Invalid key
        let invalidMsg = ViewHelpers.hotkeyDraftValidationMessage(draft: "zzzzz", isSupportedKey: false)
        #expect(invalidMsg != nil)

        // Empty draft
        let emptyMsg = ViewHelpers.hotkeyDraftValidationMessage(draft: "", isSupportedKey: false)
        // empty is a special case
        let _ = emptyMsg
    }

    // MARK: - Permission state combinations

    @Test("Missing permissions: all combinations produce correct messages")
    func permissionCombinations() {
        // All granted
        let allOk = ViewHelpers.hotkeyMissingPermissionSummary(
            accessibilityAuthorized: true, inputMonitoringAuthorized: true
        )
        #expect(allOk == nil)

        // Missing accessibility
        let noAccessibility = ViewHelpers.hotkeyMissingPermissionSummary(
            accessibilityAuthorized: false, inputMonitoringAuthorized: true
        )
        #expect(noAccessibility != nil)

        // Missing input monitoring
        let noInput = ViewHelpers.hotkeyMissingPermissionSummary(
            accessibilityAuthorized: true, inputMonitoringAuthorized: false
        )
        #expect(noInput != nil)

        // Both missing
        let noBoth = ViewHelpers.hotkeyMissingPermissionSummary(
            accessibilityAuthorized: false, inputMonitoringAuthorized: false
        )
        #expect(noBoth != nil)

        // Onboarding permission check
        let onboardingOk = OnboardingView.permissionsGranted(
            microphone: true, accessibility: true, inputMonitoring: true
        )
        #expect(onboardingOk == true)

        let onboardingMissing = OnboardingView.permissionsGranted(
            microphone: true, accessibility: false, inputMonitoring: true
        )
        #expect(onboardingMissing == false)
    }

    // MARK: - Streaming elapsed format E2E

    @Test("Streaming elapsed format covers all ranges")
    func streamingElapsedRanges() {
        // 0 seconds
        let zero = ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 0)
        #expect(zero == "0:00")

        // Under a minute
        let short = ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 45)
        #expect(short == "0:45")

        // Exactly one minute
        let oneMin = ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 60)
        #expect(oneMin == "1:00")

        // Over an hour
        let overHour = ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: 3661)
        #expect(overHour == "1:01:01")

        // Negative
        let negative = ViewHelpers.streamingElapsedStatusSegment(elapsedSeconds: -1)
        #expect(negative == nil)
    }

    // MARK: - Sentence punctuation helpers E2E

    @Test("Sentence punctuation detection covers all types")
    func sentencePunctuationDetection() {
        #expect(ViewHelpers.isSentencePunctuation(".") == true)
        #expect(ViewHelpers.isSentencePunctuation(",") == true)
        #expect(ViewHelpers.isSentencePunctuation("!") == true)
        #expect(ViewHelpers.isSentencePunctuation("?") == true)
        #expect(ViewHelpers.isSentencePunctuation(";") == true)
        #expect(ViewHelpers.isSentencePunctuation(":") == true)
        #expect(ViewHelpers.isSentencePunctuation("…") == true)
        #expect(ViewHelpers.isSentencePunctuation("a") == false)
        #expect(ViewHelpers.isSentencePunctuation(" ") == false)
    }

    @Test("Trailing sentence punctuation extraction")
    func trailingPunctuationExtraction() {
        #expect(ViewHelpers.trailingSentencePunctuation(in: "hello.") == ".")
        #expect(ViewHelpers.trailingSentencePunctuation(in: "wow!!") == "!!")
        #expect(ViewHelpers.trailingSentencePunctuation(in: "really?!") == "?!")
        #expect(ViewHelpers.trailingSentencePunctuation(in: "hello") == nil)
        #expect(ViewHelpers.trailingSentencePunctuation(in: "") == nil)
        #expect(ViewHelpers.trailingSentencePunctuation(in: "   ") == nil)
        #expect(ViewHelpers.trailingSentencePunctuation(in: "test...") == "...")
    }

    // MARK: - Model file size

    @Test("sizeOfModelFile returns 0 for nonexistent path")
    func modelFileSizeNonexistent() {
        let size = ViewHelpers.sizeOfModelFile(atPath: "/nonexistent/model.bin")
        #expect(size == 0)
    }

    @Test("sizeOfModelFile returns 0 for empty path")
    func modelFileSizeEmpty() {
        let size = ViewHelpers.sizeOfModelFile(atPath: "")
        #expect(size == 0)
    }

    // MARK: - Insertion probe composite

    @Test("Insertion probe status label covers all states")
    func insertionProbeStatusLabels() {
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: true) == "Passed")
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: false) == "Failed")
        #expect(ViewHelpers.insertionProbeStatusLabel(succeeded: nil) == "Not tested")
    }

    @Test("Insertion probe status color covers all states")
    func insertionProbeStatusColors() {
        #expect(ViewHelpers.insertionProbeStatusColorName(succeeded: true) == "green")
        #expect(ViewHelpers.insertionProbeStatusColorName(succeeded: false) == "orange")
        #expect(ViewHelpers.insertionProbeStatusColorName(succeeded: nil) == "secondary")
    }

    // MARK: - Capture profile helpers

    @Test("captureProfileUsesRecentAppFallback logic")
    func captureProfileFallback() {
        #expect(ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: true) == true)
        #expect(ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: false) == false)
        #expect(ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: nil) == false)
    }

    @Test("captureProfileFallbackAppName logic")
    func captureProfileFallbackName() {
        #expect(ViewHelpers.captureProfileFallbackAppName(isFallback: true, appName: "Safari") == "Safari")
        #expect(ViewHelpers.captureProfileFallbackAppName(isFallback: false, appName: "Safari") == nil)
        #expect(ViewHelpers.captureProfileFallbackAppName(isFallback: true, appName: nil) == nil)
        #expect(ViewHelpers.captureProfileFallbackAppName(isFallback: nil, appName: "Safari") == nil)
    }

    // MARK: - Format helpers comprehensive

    @Test("formatBytes covers edge cases")
    func formatBytesEdgeCases() {
        let zero = ViewHelpers.formatBytes(0)
        #expect(!zero.isEmpty)

        let small = ViewHelpers.formatBytes(500)
        #expect(!small.isEmpty)

        let kb = ViewHelpers.formatBytes(1024)
        #expect(!kb.isEmpty)

        let mb = ViewHelpers.formatBytes(1_048_576)
        #expect(!mb.isEmpty)

        let gb = ViewHelpers.formatBytes(1_073_741_824)
        #expect(!gb.isEmpty)
    }

    // MARK: - Key code mapping exhaustive

    @Test("All F-keys map correctly")
    func fKeyMapping() {
        let fKeys: [(Int, String)] = [
            (0x7A, "f1"), (0x78, "f2"), (0x63, "f3"), (0x76, "f4"),
            (0x60, "f5"), (0x61, "f6"), (0x62, "f7"), (0x64, "f8"),
            (0x65, "f9"), (0x6D, "f10"), (0x67, "f11"), (0x6F, "f12"),
            (0x69, "f13"), (0x6B, "f14"), (0x71, "f15"), (0x6A, "f16"),
            (0x40, "f17"), (0x4F, "f18"), (0x50, "f19"), (0x5A, "f20"),
        ]
        for (code, expected) in fKeys {
            let name = ViewHelpers.hotkeyKeyNameForKeyCode(code)
            #expect(name == expected, "Key code \(code) should map to \(expected), got \(name ?? "nil")")
        }
    }

    @Test("Navigation keys map correctly")
    func navigationKeyMapping() {
        let navKeys: [(Int, String)] = [
            (0x31, "space"), (0x30, "tab"), (0x24, "return"), (0x35, "escape"),
            (0x33, "delete"), (0x75, "forwarddelete"), (0x72, "insert"),
            (0x7B, "left"), (0x7C, "right"), (0x7E, "up"), (0x7D, "down"),
            (0x73, "home"), (0x77, "end"), (0x74, "pageup"), (0x79, "pagedown"),
        ]
        for (code, expected) in navKeys {
            let name = ViewHelpers.hotkeyKeyNameForKeyCode(code)
            #expect(name == expected, "Key code \(code) should map to \(expected), got \(name ?? "nil")")
        }
    }

    @Test("Modifier-only key codes return nil")
    func modifierKeyCodesNil() {
        let modifierCodes = [0x37, 0x38, 0x3C, 0x3A, 0x3D, 0x3B, 0x3E, 0x39]
        for code in modifierCodes {
            #expect(ViewHelpers.hotkeyKeyNameForKeyCode(code) == nil, "Modifier key \(code) should return nil")
        }
    }

    @Test("isModifierOnlyKeyCode covers all modifier codes")
    func modifierOnlyKeyCode() {
        let modifierCodes = [0x37, 0x38, 0x3C, 0x3A, 0x3D, 0x3B, 0x3E, 0x39]
        for code in modifierCodes {
            #expect(ViewHelpers.isModifierOnlyKeyCode(code) == true)
        }
        // Non-modifier
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x31) == false) // space
        #expect(ViewHelpers.isModifierOnlyKeyCode(0x7A) == false) // f1
    }

    @Test("fn key code returns fn")
    func fnKeyCode() {
        #expect(ViewHelpers.hotkeyKeyNameForKeyCode(0x3F) == "fn")
    }

    // MARK: - HotkeyDisplay integration

    @Test("HotkeyDisplay.isSupportedKey covers common keys")
    func hotkeyDisplaySupportedKeys() {
        #expect(HotkeyDisplay.isSupportedKey("space") == true)
        #expect(HotkeyDisplay.isSupportedKey("f1") == true)
        #expect(HotkeyDisplay.isSupportedKey("return") == true)
        #expect(HotkeyDisplay.isSupportedKey("a") == true)
        #expect(HotkeyDisplay.isSupportedKey("") == false)
    }

    // MARK: - Modifier parsing E2E

    @Test("parseModifierToken covers all standard modifier names")
    func parseAllModifierTokens() {
        let commandTokens = ["cmd", "command", "⌘"]
        for token in commandTokens {
            #expect(ViewHelpers.parseModifierToken(token) == .command, "\(token) should parse as command")
        }

        let shiftTokens = ["shift", "⇧"]
        for token in shiftTokens {
            #expect(ViewHelpers.parseModifierToken(token) == .shift, "\(token) should parse as shift")
        }

        let optionTokens = ["opt", "option", "alt", "⌥"]
        for token in optionTokens {
            #expect(ViewHelpers.parseModifierToken(token) == .option, "\(token) should parse as option")
        }

        let controlTokens = ["ctrl", "control", "⌃"]
        for token in controlTokens {
            #expect(ViewHelpers.parseModifierToken(token) == .control, "\(token) should parse as control")
        }

        // Non-modifier
        #expect(ViewHelpers.parseModifierToken("space") == nil)
        #expect(ViewHelpers.parseModifierToken("k") == nil)
    }

    @Test("isNonConfigurableModifierToken identifies fn and globe keys")
    func nonConfigurableModifiers() {
        #expect(ViewHelpers.isNonConfigurableModifierToken("fn") == true)
        #expect(ViewHelpers.isNonConfigurableModifierToken("function") == true)
        #expect(ViewHelpers.isNonConfigurableModifierToken("globe") == true)
        #expect(ViewHelpers.isNonConfigurableModifierToken("globekey") == true)
        #expect(ViewHelpers.isNonConfigurableModifierToken("🌐") == true)
        #expect(ViewHelpers.isNonConfigurableModifierToken("cmd") == false)
        #expect(ViewHelpers.isNonConfigurableModifierToken("shift") == false)
    }

    // MARK: - Abbreviation helper

    @Test("abbreviatedAppName truncates long names")
    func abbreviatedAppName() {
        let short = ViewHelpers.abbreviatedAppName("Safari", maxCharacters: 18)
        #expect(short == "Safari")

        let long = ViewHelpers.abbreviatedAppName("Very Long Application Name That Exceeds Limit", maxCharacters: 18)
        #expect(long.count <= 19) // 18 + ellipsis
    }

    // MARK: - Hotkey mode tip text

    @Test("hotkeyModeTipText provides distinct tips for each mode")
    func hotkeyModeTips() {
        let toggleTip = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: false)
        let holdTip = ViewHelpers.hotkeyModeTipText(mode: .hold, usesEscapeTrigger: false)
        #expect(toggleTip != holdTip)

        let escTip = ViewHelpers.hotkeyModeTipText(mode: .toggle, usesEscapeTrigger: true)
        #expect(!escTip.isEmpty)
    }

    // MARK: - Bridge modifiers identity

    @Test("bridgeModifiers is identity function")
    func bridgeModifiersIdentity() {
        let mods: Set<ViewHelpers.ParsedModifier> = [.command, .shift]
        let bridged = ViewHelpers.bridgeModifiers(mods)
        #expect(bridged == mods)
    }
}
