import Testing
import Foundation
@testable import OpenWhisper

// MARK: - shouldCopyBecauseTargetUnknown

@Suite("shouldCopyBecauseTargetUnknown")
struct ShouldCopyBecauseTargetUnknownTests {

    @Test("false when cannot insert directly")
    func falseWhenCannotInsert() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: false,
            hasResolvableInsertTarget: false,
            hasExternalFrontApp: false
        ) == false)
    }

    @Test("false when has resolvable insert target")
    func falseWhenHasTarget() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true,
            hasResolvableInsertTarget: true,
            hasExternalFrontApp: false
        ) == false)
    }

    @Test("false when has external front app")
    func falseWhenHasFrontApp() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true,
            hasResolvableInsertTarget: false,
            hasExternalFrontApp: true
        ) == false)
    }

    @Test("true when can insert, no target, no front app")
    func trueWhenNoTargetNoFrontApp() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(
            canInsertDirectly: true,
            hasResolvableInsertTarget: false,
            hasExternalFrontApp: false
        ) == true)
    }
}

// MARK: - insertionProbeSampleTextWillTruncate

@Suite("insertionProbeSampleTextWillTruncate")
struct InsertionProbeSampleTextWillTruncateTests {

    @Test("false for short text")
    func shortText() {
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate("hello") == false)
    }

    @Test("false for exactly max length")
    func exactlyMax() {
        let text = String(repeating: "a", count: ViewHelpers.insertionProbeMaxCharacters)
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate(text) == false)
    }

    @Test("true for over max length")
    func overMax() {
        let text = String(repeating: "a", count: ViewHelpers.insertionProbeMaxCharacters + 1)
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate(text) == true)
    }

    @Test("false for empty text")
    func emptyText() {
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate("") == false)
    }
}

// MARK: - enforceInsertionProbeSampleTextLimit

@Suite("enforceInsertionProbeSampleTextLimit")
struct EnforceInsertionProbeSampleTextLimitTests {

    @Test("short text unchanged")
    func shortUnchanged() {
        #expect(ViewHelpers.enforceInsertionProbeSampleTextLimit("hello") == "hello")
    }

    @Test("long text truncated to max")
    func longTruncated() {
        let text = String(repeating: "x", count: ViewHelpers.insertionProbeMaxCharacters + 50)
        let result = ViewHelpers.enforceInsertionProbeSampleTextLimit(text)
        #expect(result.count == ViewHelpers.insertionProbeMaxCharacters)
    }

    @Test("empty text stays empty")
    func emptyStaysEmpty() {
        #expect(ViewHelpers.enforceInsertionProbeSampleTextLimit("") == "")
    }
}

// MARK: - insertionProbeSampleTextForRun

@Suite("insertionProbeSampleTextForRun")
struct InsertionProbeSampleTextForRunTests {

    @Test("trims whitespace and limits")
    func trimsAndLimits() {
        let result = ViewHelpers.insertionProbeSampleTextForRun("  hello  ")
        #expect(result == "hello")
    }

    @Test("long text is trimmed then limited")
    func longTrimmedAndLimited() {
        let long = "  " + String(repeating: "z", count: 300) + "  "
        let result = ViewHelpers.insertionProbeSampleTextForRun(long)
        #expect(result.count == ViewHelpers.insertionProbeMaxCharacters)
    }

    @Test("whitespace only returns empty")
    func whitespaceOnly() {
        #expect(ViewHelpers.insertionProbeSampleTextForRun("   ") == "")
    }

    @Test("newlines stripped")
    func newlinesStripped() {
        #expect(ViewHelpers.insertionProbeSampleTextForRun("\nhello\n") == "hello")
    }
}

// MARK: - insertionProbeStatus

@Suite("insertionProbeStatus")
struct InsertionProbeStatusTests {

    @Test("true maps to success")
    func trueIsSuccess() {
        #expect(ViewHelpers.insertionProbeStatus(succeeded: true) == .success)
    }

    @Test("false maps to failure")
    func falseIsFailure() {
        #expect(ViewHelpers.insertionProbeStatus(succeeded: false) == .failure)
    }

    @Test("nil maps to unknown")
    func nilIsUnknown() {
        #expect(ViewHelpers.insertionProbeStatus(succeeded: nil) == .unknown)
    }
}

// MARK: - hasHotkeyDraftEdits

@Suite("hasHotkeyDraftEdits")
struct HasHotkeyDraftEditsTests {

    @Test("same key no modifiers parsed returns false")
    func sameKeyNoMods() {
        #expect(ViewHelpers.hasHotkeyDraftEdits(
            draft: "f5",
            currentKey: "f5",
            currentModifiers: [.control]
        ) == false)
    }

    @Test("different key returns true")
    func differentKey() {
        #expect(ViewHelpers.hasHotkeyDraftEdits(
            draft: "f6",
            currentKey: "f5",
            currentModifiers: []
        ) == true)
    }

    @Test("same key different modifiers returns true")
    func sameKeyDiffMods() {
        #expect(ViewHelpers.hasHotkeyDraftEdits(
            draft: "ctrl+f5",
            currentKey: "f5",
            currentModifiers: [.option]
        ) == true)
    }

    @Test("same key same modifiers returns false")
    func sameKeySameMods() {
        #expect(ViewHelpers.hasHotkeyDraftEdits(
            draft: "ctrl+f5",
            currentKey: "f5",
            currentModifiers: [.control]
        ) == false)
    }

    @Test("empty draft treated as space key, differs from f5")
    func emptyDraft() {
        // Empty draft sanitizes to "space", which differs from "f5"
        #expect(ViewHelpers.hasHotkeyDraftEdits(
            draft: "",
            currentKey: "f5",
            currentModifiers: []
        ) == true)
    }

    @Test("empty draft matches space key")
    func emptyDraftMatchesSpace() {
        #expect(ViewHelpers.hasHotkeyDraftEdits(
            draft: "",
            currentKey: "space",
            currentModifiers: []
        ) == false)
    }
}

// MARK: - effectiveHotkeyRiskContext

@Suite("effectiveHotkeyRiskContext")
struct EffectiveHotkeyRiskContextTests {

    @Test("valid draft overrides current key and modifiers")
    func validDraftOverrides() {
        let result = ViewHelpers.effectiveHotkeyRiskContext(
            draft: "ctrl+f6",
            currentKey: "f5",
            currentModifiers: [.option]
        )
        #expect(result.key == "f6")
        #expect(result.requiredModifiers == [.control])
    }

    @Test("invalid draft falls back to current")
    func invalidDraftFallsBack() {
        let result = ViewHelpers.effectiveHotkeyRiskContext(
            draft: "",
            currentKey: "f5",
            currentModifiers: [.option]
        )
        #expect(result.key == "f5")
        #expect(result.requiredModifiers == [.option])
    }

    @Test("draft with key only inherits current modifiers")
    func draftKeyOnlyInheritsModifiers() {
        let result = ViewHelpers.effectiveHotkeyRiskContext(
            draft: "f7",
            currentKey: "f5",
            currentModifiers: [.command]
        )
        #expect(result.key == "f7")
        #expect(result.requiredModifiers == [.command])
    }

    @Test("unsupported key in draft falls back")
    func unsupportedKeyFallsBack() {
        let result = ViewHelpers.effectiveHotkeyRiskContext(
            draft: "ctrl+nonsensekey12345",
            currentKey: "f5",
            currentModifiers: [.option]
        )
        // Should fall back since the key is not supported
        #expect(result.key == "f5")
        #expect(result.requiredModifiers == [.option])
    }
}
