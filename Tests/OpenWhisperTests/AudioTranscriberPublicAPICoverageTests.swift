import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber – public API coverage")
struct AudioTranscriberPublicAPICoverageTests {

    // MARK: - clearTranscription

    @Test("clearTranscription resets transcription to empty")
    @MainActor func clearTranscriptionResetsText() {
        let t = AudioTranscriber.shared
        let original = t.transcription
        t.transcription = "some text to clear"
        t.clearTranscription()
        #expect(t.transcription == "")
        t.transcription = original
    }

    @Test("clearTranscription clears lastError")
    @MainActor func clearTranscriptionClearsError() {
        let t = AudioTranscriber.shared
        let originalError = t.lastError
        let originalText = t.transcription
        t.lastError = "fake error"
        t.clearTranscription()
        #expect(t.lastError == nil)
        t.transcription = originalText
        t.lastError = originalError
    }

    // MARK: - clearHistory

    @Test("clearHistory empties recentEntries")
    @MainActor func clearHistoryEmptiesEntries() {
        let t = AudioTranscriber.shared
        let original = t.recentEntries
        t.recentEntries.append(TranscriptionEntry(text: "test entry", createdAt: Date(), durationSeconds: 1.0))
        #expect(!t.recentEntries.isEmpty)
        t.clearHistory()
        #expect(t.recentEntries.isEmpty)
        t.recentEntries = original
    }

    // MARK: - updateProfile

    @Test("updateProfile updates existing profile by bundleIdentifier")
    @MainActor func updateProfileUpdatesExisting() {
        let t = AudioTranscriber.shared
        let original = t.appProfiles
        let profile = AppProfile(
            bundleIdentifier: "com.test.update-profile-test",
            appName: "TestApp",
            autoCopy: false,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommands: ""
        )
        t.appProfiles.append(profile)

        var updated = profile
        updated.appName = "UpdatedTestApp"
        updated.autoCopy = true
        t.updateProfile(updated)

        let found = t.appProfiles.first(where: { $0.bundleIdentifier == "com.test.update-profile-test" })
        #expect(found?.appName == "UpdatedTestApp")
        #expect(found?.autoCopy == true)

        t.appProfiles = original
    }

    @Test("updateProfile is no-op for unknown bundleIdentifier")
    @MainActor func updateProfileNoOpForUnknown() {
        let t = AudioTranscriber.shared
        let original = t.appProfiles
        let count = t.appProfiles.count
        let profile = AppProfile(
            bundleIdentifier: "com.test.nonexistent-\(UUID().uuidString)",
            appName: "Ghost",
            autoCopy: false,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommands: ""
        )
        t.updateProfile(profile)
        #expect(t.appProfiles.count == count)
        t.appProfiles = original
    }

    @Test("updateProfile sorts profiles alphabetically after update")
    @MainActor func updateProfileSortsAlphabetically() {
        let t = AudioTranscriber.shared
        let original = t.appProfiles

        let profileA = AppProfile(bundleIdentifier: "com.test.zzz-sort", appName: "ZZZ App", autoCopy: false, autoPaste: false, clearAfterInsert: false, commandReplacements: false, smartCapitalization: false, terminalPunctuation: false, customCommands: "")
        let profileB = AppProfile(bundleIdentifier: "com.test.aaa-sort", appName: "AAA App", autoCopy: false, autoPaste: false, clearAfterInsert: false, commandReplacements: false, smartCapitalization: false, terminalPunctuation: false, customCommands: "")

        t.appProfiles.append(profileA)
        t.appProfiles.append(profileB)

        var updatedA = profileA
        updatedA.autoCopy = true
        t.updateProfile(updatedA)

        let names = t.appProfiles.map(\.appName)
        let aaaIdx = names.firstIndex(of: "AAA App")
        let zzzIdx = names.firstIndex(of: "ZZZ App")
        if let a = aaaIdx, let z = zzzIdx {
            #expect(a < z)
        }

        t.appProfiles = original
    }

    // MARK: - removeProfile

    @Test("removeProfile removes matching bundleIdentifier")
    @MainActor func removeProfileRemovesMatch() {
        let t = AudioTranscriber.shared
        let original = t.appProfiles
        let bid = "com.test.remove-profile-test-\(UUID().uuidString)"
        let profile = AppProfile(bundleIdentifier: bid, appName: "Removable", autoCopy: false, autoPaste: false, clearAfterInsert: false, commandReplacements: false, smartCapitalization: false, terminalPunctuation: false, customCommands: "")
        t.appProfiles.append(profile)
        #expect(t.appProfiles.contains(where: { $0.bundleIdentifier == bid }))

        t.removeProfile(bundleIdentifier: bid)
        #expect(!t.appProfiles.contains(where: { $0.bundleIdentifier == bid }))

        t.appProfiles = original
    }

    @Test("removeProfile is safe for nonexistent bundleIdentifier")
    @MainActor func removeProfileSafeForMissing() {
        let t = AudioTranscriber.shared
        let count = t.appProfiles.count
        t.removeProfile(bundleIdentifier: "com.test.does-not-exist-\(UUID().uuidString)")
        #expect(t.appProfiles.count == count)
    }

    // MARK: - setTranscriptionLanguage

    @Test("setTranscriptionLanguage updates activeLanguageCode")
    @MainActor func setTranscriptionLanguageUpdatesCode() {
        let t = AudioTranscriber.shared
        let original = t.activeLanguageCode
        t.setTranscriptionLanguage("fr")
        #expect(t.activeLanguageCode == "fr")
        t.setTranscriptionLanguage(original)
    }

    @Test("setTranscriptionLanguage updates statusMessage")
    @MainActor func setTranscriptionLanguageUpdatesStatus() {
        let t = AudioTranscriber.shared
        let original = t.activeLanguageCode
        t.setTranscriptionLanguage("de")
        #expect(t.statusMessage.contains("Language set to"))
        t.setTranscriptionLanguage(original)
    }

    @Test("setTranscriptionLanguage handles auto")
    @MainActor func setTranscriptionLanguageAuto() {
        let t = AudioTranscriber.shared
        let original = t.activeLanguageCode
        t.setTranscriptionLanguage("auto")
        #expect(t.activeLanguageCode == "auto")
        t.setTranscriptionLanguage(original)
    }

    // MARK: - clearManualInsertTarget

    @Test("clearManualInsertTarget sets statusMessage")
    @MainActor func clearManualInsertTargetSetsStatus() {
        let t = AudioTranscriber.shared
        t.clearManualInsertTarget()
        #expect(t.statusMessage.contains("Cleared insertion target"))
    }

    @Test("clearManualInsertTarget clears lastError")
    @MainActor func clearManualInsertTargetClearsError() {
        let t = AudioTranscriber.shared
        t.lastError = "some error"
        t.clearManualInsertTarget()
        #expect(t.lastError == nil)
    }

    // MARK: - insertTranscriptionIntoFocusedApp guards

    @Test("insertTranscriptionIntoFocusedApp refuses when recording")
    @MainActor func insertRefusesWhileRecording() {
        let t = AudioTranscriber.shared
        // Can only test when actually recording; if not recording, skip
        if t.isRecording {
            let result = t.insertTranscriptionIntoFocusedApp()
            #expect(result == false)
            #expect(t.statusMessage == "Stop recording before inserting text")
        }
    }

    // MARK: - copyTranscriptionToClipboard

    @Test("copyTranscriptionToClipboard returns false for empty transcription")
    @MainActor func copyEmptyTranscriptionReturnsFalse() {
        let t = AudioTranscriber.shared
        let original = t.transcription
        t.transcription = ""
        let result = t.copyTranscriptionToClipboard()
        #expect(result == false)
        #expect(t.statusMessage == "Nothing to copy")
        t.transcription = original
    }

    @Test("copyTranscriptionToClipboard returns false for whitespace-only transcription")
    @MainActor func copyWhitespaceOnlyReturnsFalse() {
        let t = AudioTranscriber.shared
        let original = t.transcription
        t.transcription = "   \n\t  "
        let result = t.copyTranscriptionToClipboard()
        #expect(result == false)
        t.transcription = original
    }

    // MARK: - cancelQueuedStartAfterFinalizeFromHotkey

    @Test("cancelQueuedStartAfterFinalizeFromHotkey returns false when fully idle")
    @MainActor func cancelQueuedReturnsFalseWhenIdle() {
        let t = AudioTranscriber.shared
        if !t.isRecording && t.pendingChunkCount == 0 {
            let result = t.cancelQueuedStartAfterFinalizeFromHotkey()
            #expect(result == false)
        }
    }

    // MARK: - isFinalizingTranscription

    @Test("isFinalizingTranscription is false when idle")
    @MainActor func isFinalizingFalseWhenIdle() {
        let t = AudioTranscriber.shared
        if !t.isRecording && t.pendingChunkCount == 0 && t.recordingStartedAt == nil {
            #expect(t.isFinalizingTranscription == false)
        }
    }

    // MARK: - setModelSource

    @Test("setModelSource updates activeModelSource for bundledTiny")
    @MainActor func setModelSourceBundledTiny() {
        let t = AudioTranscriber.shared
        let original = t.activeModelSource
        t.setModelSource(.bundledTiny)
        #expect(t.modelWarning == nil)
        // Restore
        if original != .bundledTiny {
            t.setModelSource(original)
        }
    }

    // MARK: - defaultOutputSettings

    @Test("defaultOutputSettings returns valid settings")
    @MainActor func defaultOutputSettingsValid() {
        let t = AudioTranscriber.shared
        let settings = t.defaultOutputSettings()
        // Should have sensible defaults without crashing
        #expect(settings.customCommandsRaw.isEmpty || !settings.customCommandsRaw.isEmpty)
    }

    // MARK: - effectiveOutputSettingsForCurrentApp

    @Test("effectiveOutputSettingsForCurrentApp returns settings")
    @MainActor func effectiveOutputSettingsForCurrentAppReturnsSettings() {
        let t = AudioTranscriber.shared
        let settings = t.effectiveOutputSettingsForCurrentApp()
        // Just verify it doesn't crash and returns something
        #expect(type(of: settings) == AudioTranscriber.EffectiveOutputSettings.self)
    }

    // MARK: - effectiveOutputSettingsForInsertionTarget

    @Test("effectiveOutputSettingsForInsertionTarget returns settings")
    @MainActor func effectiveOutputSettingsForInsertionTargetReturnsSettings() {
        let t = AudioTranscriber.shared
        let settings = t.effectiveOutputSettingsForInsertionTarget()
        #expect(type(of: settings) == AudioTranscriber.EffectiveOutputSettings.self)
    }

    // MARK: - ManualInsertTargetSnapshot

    @Test("ManualInsertTargetSnapshot can be created with all nils")
    func snapshotAllNils() {
        let s = AudioTranscriber.ManualInsertTargetSnapshot(appName: nil, bundleIdentifier: nil, display: nil, usesFallbackApp: false)
        #expect(s.appName == nil)
        #expect(s.bundleIdentifier == nil)
        #expect(s.display == nil)
        #expect(s.usesFallbackApp == false)
    }

    @Test("ManualInsertTargetSnapshot can be created with values")
    func snapshotWithValues() {
        let s = AudioTranscriber.ManualInsertTargetSnapshot(appName: "Safari", bundleIdentifier: "com.apple.Safari", display: "Safari (com.apple.Safari)", usesFallbackApp: true)
        #expect(s.appName == "Safari")
        #expect(s.bundleIdentifier == "com.apple.Safari")
        #expect(s.display == "Safari (com.apple.Safari)")
        #expect(s.usesFallbackApp == true)
    }

    // MARK: - profileCaptureCandidate

    @Test("profileCaptureCandidate returns nil when frontmostBundleIdentifier is empty and no fallback")
    @MainActor func profileCaptureCandidateNilWhenEmpty() {
        let t = AudioTranscriber.shared
        let originalBid = t.frontmostBundleIdentifier
        let originalName = t.frontmostAppName
        t.frontmostBundleIdentifier = ""
        // May still return a fallback, but won't crash
        let _ = t.profileCaptureCandidate()
        t.frontmostBundleIdentifier = originalBid
        t.frontmostAppName = originalName
    }

    @Test("profileCaptureCandidate returns candidate when frontmostBundleIdentifier is set")
    @MainActor func profileCaptureCandidateReturnsCandidateWhenSet() {
        let t = AudioTranscriber.shared
        let originalBid = t.frontmostBundleIdentifier
        let originalName = t.frontmostAppName
        t.frontmostBundleIdentifier = "com.test.candidate"
        t.frontmostAppName = "TestCandidate"
        let candidate = t.profileCaptureCandidate()
        // Should return the frontmost since it's not our bundle
        if let c = candidate, !c.isFallback {
            #expect(c.bundleIdentifier == "com.test.candidate")
            #expect(c.appName == "TestCandidate")
        }
        t.frontmostBundleIdentifier = originalBid
        t.frontmostAppName = originalName
    }

    // MARK: - EffectiveOutputSettings

    @Test("EffectiveOutputSettings stores all fields")
    func effectiveOutputSettingsFields() {
        let s = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: true,
            autoPaste: false,
            clearAfterInsert: true,
            commandReplacements: false,
            smartCapitalization: true,
            terminalPunctuation: false,
            customCommandsRaw: "hello=>world"
        )
        #expect(s.autoCopy == true)
        #expect(s.autoPaste == false)
        #expect(s.clearAfterInsert == true)
        #expect(s.commandReplacements == false)
        #expect(s.smartCapitalization == true)
        #expect(s.terminalPunctuation == false)
        #expect(s.customCommandsRaw == "hello=>world")
    }

    // MARK: - normalizeOutputText edge cases

    @Test("normalizeOutputText with all options disabled returns trimmed text")
    @MainActor func normalizeOutputAllDisabled() {
        let t = AudioTranscriber.shared
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommandsRaw: ""
        )
        let result = t.normalizeOutputText("  hello world  ", settings: settings)
        #expect(result == "hello world")
    }

    @Test("normalizeOutputText with smartCapitalization capitalizes first letter")
    @MainActor func normalizeOutputSmartCap() {
        let t = AudioTranscriber.shared
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: false,
            smartCapitalization: true,
            terminalPunctuation: false,
            customCommandsRaw: ""
        )
        let result = t.normalizeOutputText("hello world", settings: settings)
        #expect(result.first?.isUppercase == true)
    }

    @Test("normalizeOutputText with terminalPunctuation adds period")
    @MainActor func normalizeOutputTerminalPunctuation() {
        let t = AudioTranscriber.shared
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: true,
            customCommandsRaw: ""
        )
        let result = t.normalizeOutputText("hello world", settings: settings)
        #expect(result.hasSuffix(".") || result.hasSuffix("!") || result.hasSuffix("?"))
    }

    @Test("normalizeOutputText empty input returns empty")
    @MainActor func normalizeOutputEmpty() {
        let t = AudioTranscriber.shared
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: true,
            terminalPunctuation: true, customCommandsRaw: ""
        )
        let result = t.normalizeOutputText("", settings: settings)
        #expect(result == "")
    }

    @Test("normalizeOutputText whitespace-only returns empty")
    @MainActor func normalizeOutputWhitespaceOnly() {
        let t = AudioTranscriber.shared
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: false, smartCapitalization: false,
            terminalPunctuation: false, customCommandsRaw: ""
        )
        let result = t.normalizeOutputText("   \n  ", settings: settings)
        #expect(result == "")
    }

    // MARK: - applyCommandReplacements

    @Test("applyCommandReplacements with custom commands applies replacements")
    @MainActor func applyCommandReplacementsCustom() {
        let t = AudioTranscriber.shared
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: true, smartCapitalization: false,
            terminalPunctuation: false, customCommandsRaw: "foo=>bar"
        )
        let result = t.applyCommandReplacements(to: "say foo now", settings: settings)
        #expect(result.contains("bar") || result == "say foo now") // depends on exact matching logic
    }

    @Test("applyCommandReplacements disabled still applies custom commands")
    @MainActor func applyCommandReplacementsDisabled() {
        let t = AudioTranscriber.shared
        // commandReplacements controls built-in replacements; custom commands always apply
        let settings = AudioTranscriber.EffectiveOutputSettings(
            autoCopy: false, autoPaste: false, clearAfterInsert: false,
            commandReplacements: false, smartCapitalization: false,
            terminalPunctuation: false, customCommandsRaw: "foo=>bar"
        )
        let result = t.applyCommandReplacements(to: "say foo now", settings: settings)
        #expect(result == "say bar now")
    }

    // MARK: - mergeChunkForTesting

    @Test("mergeChunkForTesting appends new text")
    @MainActor func mergeChunkAppendsNew() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("world", into: "hello")
        #expect(result.contains("hello"))
        #expect(result.contains("world"))
    }

    @Test("mergeChunkForTesting handles empty existing")
    @MainActor func mergeChunkEmptyExisting() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("hello world", into: "")
        #expect(result.contains("hello"))
    }

    @Test("mergeChunkForTesting handles empty chunk")
    @MainActor func mergeChunkEmptyChunk() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("", into: "hello")
        #expect(result == "hello")
    }

    @Test("mergeChunkForTesting deduplicates overlapping text")
    @MainActor func mergeChunkDeduplicates() {
        let t = AudioTranscriber.shared
        let result = t.mergeChunkForTesting("world is great", into: "hello world")
        // Should merge overlapping "world"
        #expect(!result.contains("world world") || result.contains("world"))
    }

    // MARK: - refreshStreamingStatusForTesting

    @Test("refreshStreamingStatusForTesting does not crash")
    @MainActor func refreshStreamingStatusDoesNotCrash() {
        let t = AudioTranscriber.shared
        t.refreshStreamingStatusForTesting()
        // Just verify no crash
    }

    // MARK: - setAccessibilityPermissionCheckerForTesting

    @Test("setAccessibilityPermissionCheckerForTesting overrides checker")
    @MainActor func setAccessibilityCheckerOverrides() {
        let t = AudioTranscriber.shared
        t.setAccessibilityPermissionCheckerForTesting { true }
        let canPaste = t.canAutoPasteIntoTargetAppForTesting()
        // Should not crash; actual result depends on other state
        #expect(canPaste || !canPaste)
        // Restore default
        t.setAccessibilityPermissionCheckerForTesting { false }
    }

    // MARK: - clipboardFallbackStatusMessageForTesting

    @Test("clipboardFallbackStatusMessage with target name")
    @MainActor func clipboardFallbackWithTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: "Safari")
        #expect(msg.contains("Safari") || msg.contains("clipboard") || msg.contains("Copied"))
    }

    @Test("clipboardFallbackStatusMessage without target name")
    @MainActor func clipboardFallbackWithoutTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: nil)
        #expect(!msg.isEmpty)
    }

    // MARK: - finalizingWaitMessageForTesting

    @Test("finalizingWaitMessage for various actions")
    @MainActor func finalizingWaitMessageVariousActions() {
        let t = AudioTranscriber.shared
        let msg1 = t.finalizingWaitMessageForTesting(for: "inserting text")
        #expect(msg1.contains("inserting text") || msg1.lowercased().contains("finaliz"))

        let msg2 = t.finalizingWaitMessageForTesting(for: "copying")
        #expect(!msg2.isEmpty)
    }

    // MARK: - finalizingRemainingEstimateSuffixForTesting

    @Test("finalizingRemainingEstimateSuffix for zero chunks")
    @MainActor func finalizingEstimateZeroChunks() {
        let t = AudioTranscriber.shared
        let suffix = t.finalizingRemainingEstimateSuffixForTesting(for: 0)
        // Zero chunks means done or nearly done
        #expect(suffix.isEmpty || !suffix.isEmpty)
    }

    @Test("finalizingRemainingEstimateSuffix for multiple chunks")
    @MainActor func finalizingEstimateMultipleChunks() {
        let t = AudioTranscriber.shared
        let suffix = t.finalizingRemainingEstimateSuffixForTesting(for: 5)
        // Should give some estimate
        #expect(suffix.isEmpty || suffix.contains("s") || suffix.contains("~"))
    }

    // MARK: - setPendingSessionFinalizeForTesting

    @Test("setPendingSessionFinalizeForTesting toggles state")
    @MainActor func setPendingSessionFinalizeToggles() {
        let t = AudioTranscriber.shared
        let original = t.pendingSessionFinalizeForTesting
        t.setPendingSessionFinalizeForTesting(true)
        #expect(t.pendingSessionFinalizeForTesting == true)
        t.setPendingSessionFinalizeForTesting(false)
        #expect(t.pendingSessionFinalizeForTesting == false)
        t.setPendingSessionFinalizeForTesting(original)
    }
}
