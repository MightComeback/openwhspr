import Testing
import Foundation
@testable import OpenWhisper

// MARK: - insertionProbeStatusColorName

@Suite("ViewHelpers.insertionProbeStatusColorName")
struct InsertionProbeStatusColorNameTests {

    @Test("succeeded true returns green")
    func succeededTrue() {
        #expect(ViewHelpers.insertionProbeStatusColorName(succeeded: true) == "green")
    }

    @Test("succeeded false returns orange")
    func succeededFalse() {
        #expect(ViewHelpers.insertionProbeStatusColorName(succeeded: false) == "orange")
    }

    @Test("succeeded nil returns secondary")
    func succeededNil() {
        #expect(ViewHelpers.insertionProbeStatusColorName(succeeded: nil) == "secondary")
    }
}

// MARK: - captureProfileDisabledReasonText

@Suite("ViewHelpers.captureProfileDisabledReasonText")
struct CaptureProfileDisabledReasonTests {

    @Test("returns non-empty string")
    func notEmpty() {
        #expect(!ViewHelpers.captureProfileDisabledReasonText.isEmpty)
    }

    @Test("mentions target app")
    func mentionsTargetApp() {
        #expect(ViewHelpers.captureProfileDisabledReasonText.contains("target app"))
    }
}

// MARK: - captureProfileUsesRecentAppFallback

@Suite("ViewHelpers.captureProfileUsesRecentAppFallback")
struct CaptureProfileUsesRecentAppFallbackTests {

    @Test("true when isFallback is true")
    func trueWhenTrue() {
        #expect(ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: true))
    }

    @Test("false when isFallback is false")
    func falseWhenFalse() {
        #expect(!ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: false))
    }

    @Test("false when isFallback is nil")
    func falseWhenNil() {
        #expect(!ViewHelpers.captureProfileUsesRecentAppFallback(isFallback: nil))
    }
}

// MARK: - captureProfileFallbackAppName

@Suite("ViewHelpers.captureProfileFallbackAppName")
struct CaptureProfileFallbackAppNameTests {

    @Test("returns name when isFallback is true")
    func returnsNameWhenFallback() {
        #expect(ViewHelpers.captureProfileFallbackAppName(isFallback: true, appName: "Safari") == "Safari")
    }

    @Test("returns nil when isFallback is false")
    func nilWhenNotFallback() {
        #expect(ViewHelpers.captureProfileFallbackAppName(isFallback: false, appName: "Safari") == nil)
    }

    @Test("returns nil when isFallback is nil")
    func nilWhenNilFallback() {
        #expect(ViewHelpers.captureProfileFallbackAppName(isFallback: nil, appName: "Safari") == nil)
    }

    @Test("returns nil when isFallback is true but appName is nil")
    func nilNameWhenFallback() {
        #expect(ViewHelpers.captureProfileFallbackAppName(isFallback: true, appName: nil) == nil)
    }
}

// MARK: - bridgeModifiers

@Suite("ViewHelpers.bridgeModifiers")
struct BridgeModifiersTests {

    @Test("empty set passes through")
    func emptySet() {
        let result = ViewHelpers.bridgeModifiers(Set<ViewHelpers.ParsedModifier>())
        #expect(result.isEmpty)
    }

    @Test("single modifier passes through")
    func singleModifier() {
        let input: Set<ViewHelpers.ParsedModifier> = [.command]
        let result = ViewHelpers.bridgeModifiers(input)
        #expect(result == [.command])
    }

    @Test("all modifiers pass through")
    func allModifiers() {
        let all: Set<ViewHelpers.ParsedModifier> = [.command, .shift, .option, .control, .capsLock]
        let result = ViewHelpers.bridgeModifiers(all)
        #expect(result == all)
        #expect(result.count == 5)
    }
}

// MARK: - Edge cases for existing functions with lower test density

@Suite("ViewHelpers additional edge cases")
struct ViewHelpersAdditionalEdgeCaseTests {

    // MARK: - formatDuration edge cases

    @Test("formatDuration: exactly 3600 seconds is 1:00:00")
    func formatDuration3600() {
        #expect(ViewHelpers.formatDuration(3600) == "1:00:00")
    }

    @Test("formatDuration: 86399 seconds (just under 24h)")
    func formatDuration86399() {
        #expect(ViewHelpers.formatDuration(86399) == "23:59:59")
    }

    @Test("formatDuration: 0.4 rounds to 0:00")
    func formatDurationFractionalRoundsDown() {
        #expect(ViewHelpers.formatDuration(0.4) == "0:00")
    }

    @Test("formatDuration: 0.6 rounds to 0:01")
    func formatDurationFractionalRoundsUp() {
        #expect(ViewHelpers.formatDuration(0.6) == "0:01")
    }

    @Test("formatDuration: negative clamped to 0:00")
    func formatDurationNegative() {
        #expect(ViewHelpers.formatDuration(-100) == "0:00")
    }

    // MARK: - formatShortDuration edge cases

    @Test("formatShortDuration: exactly 60 seconds")
    func formatShortDuration60() {
        #expect(ViewHelpers.formatShortDuration(60) == "1m 0s")
    }

    @Test("formatShortDuration: 59 seconds is 59s")
    func formatShortDuration59() {
        #expect(ViewHelpers.formatShortDuration(59) == "59s")
    }

    @Test("formatShortDuration: 0 seconds is 0s")
    func formatShortDuration0() {
        #expect(ViewHelpers.formatShortDuration(0) == "0s")
    }

    @Test("formatShortDuration: 3661 seconds (1h 1m 1s)")
    func formatShortDurationLong() {
        let result = ViewHelpers.formatShortDuration(3661)
        #expect(result == "61m 1s")
    }

    @Test("formatShortDuration: negative clamped")
    func formatShortDurationNegative() {
        #expect(ViewHelpers.formatShortDuration(-5) == "0s")
    }

    // MARK: - transcriptionStats edge cases

    @Test("transcriptionStats: empty text")
    func transcriptionStatsEmpty() {
        let result = ViewHelpers.transcriptionStats("")
        #expect(result.contains("0"))
    }

    @Test("transcriptionStats: single word")
    func transcriptionStatsSingleWord() {
        let result = ViewHelpers.transcriptionStats("hello")
        #expect(result.contains("1"))
    }

    @Test("transcriptionStats: whitespace only")
    func transcriptionStatsWhitespace() {
        let result = ViewHelpers.transcriptionStats("   \n  ")
        #expect(result.contains("0"))
    }

    // MARK: - liveWordsPerMinute edge cases

    @Test("liveWordsPerMinute: zero duration returns nil")
    func liveWPMZeroDuration() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello world", durationSeconds: 0) == nil)
    }

    @Test("liveWordsPerMinute: empty text returns nil or 0")
    func liveWPMEmptyText() {
        let result = ViewHelpers.liveWordsPerMinute(transcription: "", durationSeconds: 60)
        #expect(result == nil || result == 0)
    }

    @Test("liveWordsPerMinute: normal calculation")
    func liveWPMNormal() {
        let text = (0..<60).map { "word\($0)" }.joined(separator: " ")
        let result = ViewHelpers.liveWordsPerMinute(transcription: text, durationSeconds: 60)
        #expect(result == 60)
    }

    @Test("liveWordsPerMinute: short duration may return nil or positive")
    func liveWPMShortDuration() {
        let result = ViewHelpers.liveWordsPerMinute(transcription: "hello world", durationSeconds: 10)
        // With 10 seconds and 2 words, WPM = 12
        #expect(result == nil || result! > 0)
    }

    // MARK: - hotkeySummaryFromModifiers edge cases

    @Test("hotkeySummaryFromModifiers: all modifiers active")
    func hotkeySummaryAllModifiers() {
        let result = ViewHelpers.hotkeySummaryFromModifiers(
            command: true, shift: true, option: true, control: true, capsLock: true,
            key: "space"
        )
        #expect(result.contains("⌘"))
        #expect(result.contains("⇧"))
        #expect(result.contains("⌥"))
        #expect(result.contains("⌃"))
    }

    @Test("hotkeySummaryFromModifiers: no modifiers")
    func hotkeySummaryNoModifiers() {
        let result = ViewHelpers.hotkeySummaryFromModifiers(
            command: false, shift: false, option: false, control: false, capsLock: false,
            key: "f5"
        )
        #expect(!result.isEmpty)
        #expect(!result.contains("⌘"))
    }

    @Test("hotkeySummaryFromModifiers: single modifier")
    func hotkeySummarySingleModifier() {
        let result = ViewHelpers.hotkeySummaryFromModifiers(
            command: true, shift: false, option: false, control: false, capsLock: false,
            key: "space"
        )
        #expect(result.contains("⌘"))
        #expect(!result.contains("⇧"))
    }

    // MARK: - effectiveHotkeyRiskContext edge cases

    @Test("effectiveHotkeyRiskContext: valid draft overrides current key")
    func effectiveRiskContextWithDraft() {
        let result = ViewHelpers.effectiveHotkeyRiskContext(
            draft: "f5",
            currentKey: "space",
            currentModifiers: [.command]
        )
        #expect(result.key == "f5")
    }

    @Test("effectiveHotkeyRiskContext: empty draft falls back to current")
    func effectiveRiskContextEmptyDraft() {
        let result = ViewHelpers.effectiveHotkeyRiskContext(
            draft: "",
            currentKey: "space",
            currentModifiers: [.command]
        )
        #expect(result.key == "space")
        #expect(result.requiredModifiers.contains(.command))
    }

    @Test("effectiveHotkeyRiskContext: draft with modifiers uses draft modifiers")
    func effectiveRiskContextDraftWithModifiers() {
        let result = ViewHelpers.effectiveHotkeyRiskContext(
            draft: "cmd+shift+f6",
            currentKey: "space",
            currentModifiers: [.option]
        )
        #expect(result.key == "f6")
        #expect(result.requiredModifiers.contains(.command))
        #expect(result.requiredModifiers.contains(.shift))
    }
}
