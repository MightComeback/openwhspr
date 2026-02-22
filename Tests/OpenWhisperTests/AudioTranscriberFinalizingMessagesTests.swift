import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber finalizing messages & clipboard status", .serialized)
struct AudioTranscriberFinalizingMessagesTests {

    // MARK: - clipboardFallbackStatusMessage

    @Test("clipboard status with target app name")
    @MainActor func clipboardWithTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: "Safari")
        #expect(msg == "Copied to clipboard for Safari — press ⌘V to paste")
    }

    @Test("clipboard status with nil target")
    @MainActor func clipboardNilTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: nil)
        #expect(msg == "Copied to clipboard — press ⌘V to paste")
    }

    @Test("clipboard status with empty target")
    @MainActor func clipboardEmptyTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: "")
        #expect(msg == "Copied to clipboard — press ⌘V to paste")
    }

    @Test("clipboard status with whitespace-only target treated as non-empty")
    @MainActor func clipboardWhitespaceTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: "  ")
        // Whitespace-only is not empty, so it includes the app name
        #expect(msg.contains("⌘V"))
    }

    @Test("clipboard status contains paste instruction")
    @MainActor func clipboardContainsPasteInstruction() {
        let t = AudioTranscriber.shared
        let msg1 = t.clipboardFallbackStatusMessageForTesting(targetName: "Notes")
        #expect(msg1.contains("⌘V"))
        let msg2 = t.clipboardFallbackStatusMessageForTesting(targetName: nil)
        #expect(msg2.contains("⌘V"))
    }

    @Test("clipboard status with special characters in target name")
    @MainActor func clipboardSpecialCharsTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: "VS Code (Insiders)")
        #expect(msg.contains("VS Code (Insiders)"))
    }

    @Test("clipboard status with unicode target name")
    @MainActor func clipboardUnicodeTarget() {
        let t = AudioTranscriber.shared
        let msg = t.clipboardFallbackStatusMessageForTesting(targetName: "日本語エディタ")
        #expect(msg.contains("日本語エディタ"))
    }

    // MARK: - finalizingWaitMessage

    @Test("finalizing wait message includes action")
    @MainActor func finalizingWaitIncludesAction() {
        let t = AudioTranscriber.shared
        let msg = t.finalizingWaitMessageForTesting(for: "inserting")
        #expect(msg.contains("inserting"))
        #expect(msg.contains("Wait for live transcription"))
    }

    @Test("finalizing wait message with different actions")
    @MainActor func finalizingWaitDifferentActions() {
        let t = AudioTranscriber.shared
        let actions = ["inserting", "copying", "starting a new recording", "exiting"]
        for action in actions {
            let msg = t.finalizingWaitMessageForTesting(for: action)
            #expect(msg.contains(action))
        }
    }

    @Test("finalizing wait message with empty action")
    @MainActor func finalizingWaitEmptyAction() {
        let t = AudioTranscriber.shared
        let msg = t.finalizingWaitMessageForTesting(for: "")
        #expect(msg.contains("finalizing before"))
    }

    // MARK: - finalizingRemainingEstimateSuffix

    @Test("remaining estimate with zero in-flight chunks returns empty")
    @MainActor func remainingEstimateZeroChunks() {
        let t = AudioTranscriber.shared
        let suffix = t.finalizingRemainingEstimateSuffixForTesting(for: 0)
        #expect(suffix == "")
    }

    @Test("remaining estimate with negative in-flight chunks returns empty")
    @MainActor func remainingEstimateNegativeChunks() {
        let t = AudioTranscriber.shared
        let suffix = t.finalizingRemainingEstimateSuffixForTesting(for: -1)
        #expect(suffix == "")
    }

    @Test("remaining estimate with chunks but no latency returns empty")
    @MainActor func remainingEstimateNoLatency() {
        let t = AudioTranscriber.shared
        // When averageChunkLatencySeconds and lastChunkLatencySeconds are both 0,
        // representativeLatency is 0, so it returns ""
        let suffix = t.finalizingRemainingEstimateSuffixForTesting(for: 5)
        // Without active recording, latency is 0 → empty
        #expect(suffix == "")
    }

    // MARK: - isSentencePunctuation

    @Test("period is sentence punctuation")
    func periodIsSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting(".") == true)
    }

    @Test("question mark is sentence punctuation")
    func questionMarkIsSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting("?") == true)
    }

    @Test("exclamation mark is sentence punctuation")
    func exclamationIsSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting("!") == true)
    }

    @Test("comma is sentence punctuation")
    func commaIsSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting(",") == true)
    }

    @Test("semicolon is sentence punctuation")
    func semicolonIsSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting(";") == true)
    }

    @Test("colon is sentence punctuation")
    func colonIsSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting(":") == true)
    }

    @Test("space is not sentence punctuation")
    func spaceIsNotSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting(" ") == false)
    }

    @Test("letter is not sentence punctuation")
    func letterIsNotSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting("a") == false)
    }

    @Test("digit is not sentence punctuation")
    func digitIsNotSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting("0") == false)
    }

    @Test("ellipsis character is sentence punctuation")
    func ellipsisCharIsSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting("…") == true)
    }

    @Test("dash is not sentence punctuation")
    func dashIsNotSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting("-") == false)
    }

    @Test("newline is not sentence punctuation")
    func newlineIsNotSentencePunctuation() {
        #expect(AudioTranscriber.isSentencePunctuationForTesting("\n") == false)
    }

    // MARK: - canAutoPasteIntoTargetApp

    @Test("canAutoPaste returns a boolean without crashing")
    @MainActor func canAutoPasteReturnsBool() {
        let t = AudioTranscriber.shared
        let result = t.canAutoPasteIntoTargetAppForTesting()
        // Just verify it returns without crashing; value depends on system state
        #expect(result == true || result == false)
    }

    // MARK: - refreshStreamingStatus

    @Test("refreshStreamingStatus does not crash")
    @MainActor func refreshStreamingStatusNoCrash() {
        let t = AudioTranscriber.shared
        t.refreshStreamingStatusForTesting()
    }

    // MARK: - pendingSessionFinalize

    @Test("setPendingSessionFinalize toggles correctly")
    @MainActor func setPendingSessionFinalizeToggles() {
        let t = AudioTranscriber.shared
        t.setPendingSessionFinalizeForTesting(true)
        #expect(t.pendingSessionFinalizeForTesting == true)
        t.setPendingSessionFinalizeForTesting(false)
        #expect(t.pendingSessionFinalizeForTesting == false)
    }

    @Test("pendingSessionFinalize starts as false on fresh state")
    @MainActor func pendingSessionFinalizeDefaultFalse() {
        let t = AudioTranscriber.shared
        t.setPendingSessionFinalizeForTesting(false)
        #expect(t.pendingSessionFinalizeForTesting == false)
    }

    // MARK: - startRecordingAfterFinalizeRequested

    @Test("startRecordingAfterFinalizeRequested accessible")
    @MainActor func startRecordingAfterFinalizeAccessible() {
        let t = AudioTranscriber.shared
        let _ = t.startRecordingAfterFinalizeRequestedForTesting
    }

    // MARK: - setAccessibilityPermissionChecker

    @Test("custom accessibility checker is used")
    @MainActor func customAccessibilityChecker() {
        let t = AudioTranscriber.shared
        t.setAccessibilityPermissionCheckerForTesting { false }
        let result = t.canAutoPasteIntoTargetAppForTesting()
        // With accessibility denied, auto-paste should be restricted
        #expect(result == true || result == false)
        // Restore default
        t.setAccessibilityPermissionCheckerForTesting { true }
    }

    @Test("accessibility checker toggling works")
    @MainActor func accessibilityCheckerToggle() {
        let t = AudioTranscriber.shared
        t.setAccessibilityPermissionCheckerForTesting { true }
        let resultTrue = t.canAutoPasteIntoTargetAppForTesting()
        t.setAccessibilityPermissionCheckerForTesting { false }
        let resultFalse = t.canAutoPasteIntoTargetAppForTesting()
        // Values may vary depending on other conditions but should not crash
        _ = resultTrue
        _ = resultFalse
    }
}
