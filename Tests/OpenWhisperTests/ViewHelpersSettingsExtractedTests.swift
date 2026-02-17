import Testing
import Foundation
@testable import OpenWhisper

@Suite("ViewHelpers — Settings-extracted coverage")
struct ViewHelpersSettingsExtractedTests {

    // MARK: - commonHotkeyKeySections

    @Test("commonHotkeyKeySections has 5 categories")
    func sectionsCount() {
        let sections = ViewHelpers.commonHotkeyKeySections
        #expect(sections.count == 5)
    }

    @Test("commonHotkeyKeySections titles are correct")
    func sectionsTitles() {
        let titles = ViewHelpers.commonHotkeyKeySections.map(\.title)
        #expect(titles == ["Basic", "Navigation", "Function", "Punctuation", "Keypad"])
    }

    @Test("Basic section contains expected keys")
    func basicSectionKeys() {
        let basic = ViewHelpers.commonHotkeyKeySections.first!
        #expect(basic.keys.contains("space"))
        #expect(basic.keys.contains("escape"))
        #expect(basic.keys.contains("return"))
        #expect(basic.keys.contains("tab"))
        #expect(basic.keys.contains("fn"))
        #expect(basic.keys.contains("globe"))
    }

    @Test("Navigation section has 8 keys")
    func navigationSectionCount() {
        let nav = ViewHelpers.commonHotkeyKeySections[1]
        #expect(nav.keys.count == 8)
        #expect(nav.keys.contains("left"))
        #expect(nav.keys.contains("pagedown"))
    }

    @Test("Function section has F1-F24")
    func functionSectionKeys() {
        let fn = ViewHelpers.commonHotkeyKeySections[2]
        #expect(fn.keys.count == 24)
        #expect(fn.keys.first == "f1")
        #expect(fn.keys.last == "f24")
    }

    @Test("Punctuation section contains expected keys")
    func punctuationSectionKeys() {
        let punct = ViewHelpers.commonHotkeyKeySections[3]
        #expect(punct.keys.contains("minus"))
        #expect(punct.keys.contains("slash"))
        #expect(punct.keys.contains("backtick"))
        #expect(punct.keys.contains("section"))
    }

    @Test("Keypad section contains keypad keys")
    func keypadSectionKeys() {
        let kp = ViewHelpers.commonHotkeyKeySections[4]
        #expect(kp.keys.contains("keypad0"))
        #expect(kp.keys.contains("keypad9"))
        #expect(kp.keys.contains("keypadenter"))
        #expect(kp.keys.contains("keypadequals"))
        #expect(kp.keys.count == 19)
    }

    @Test("All section keys are non-empty strings")
    func allKeysNonEmpty() {
        for section in ViewHelpers.commonHotkeyKeySections {
            #expect(!section.title.isEmpty)
            for key in section.keys {
                #expect(!key.isEmpty)
            }
        }
    }

    @Test("No duplicate keys across all sections")
    func noDuplicateKeys() {
        var allKeys: [String] = []
        for section in ViewHelpers.commonHotkeyKeySections {
            allKeys.append(contentsOf: section.keys)
        }
        #expect(Set(allKeys).count == allKeys.count)
    }

    // MARK: - insertionProbeMaxCharacters

    @Test("insertionProbeMaxCharacters is 200")
    func maxCharacters() {
        #expect(ViewHelpers.insertionProbeMaxCharacters == 200)
    }

    // MARK: - insertionProbeSampleTextWillTruncate

    @Test("text within limit does not truncate")
    func withinLimit() {
        let text = String(repeating: "a", count: 200)
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate(text) == false)
    }

    @Test("text exceeding limit truncates")
    func exceedsLimit() {
        let text = String(repeating: "a", count: 201)
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate(text) == true)
    }

    @Test("empty text does not truncate")
    func emptyText() {
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate("") == false)
    }

    // MARK: - enforceInsertionProbeSampleTextLimit

    @Test("enforce limit truncates long text")
    func enforceLimitTruncates() {
        let text = String(repeating: "x", count: 300)
        let result = ViewHelpers.enforceInsertionProbeSampleTextLimit(text)
        #expect(result.count == 200)
    }

    @Test("enforce limit keeps short text intact")
    func enforceLimitKeepsShort() {
        let text = "hello"
        let result = ViewHelpers.enforceInsertionProbeSampleTextLimit(text)
        #expect(result == "hello")
    }

    @Test("enforce limit handles exactly max characters")
    func enforceLimitExact() {
        let text = String(repeating: "z", count: 200)
        let result = ViewHelpers.enforceInsertionProbeSampleTextLimit(text)
        #expect(result.count == 200)
    }

    // MARK: - insertionProbeSampleTextForRun

    @Test("forRun trims whitespace and limits")
    func forRunTrimsAndLimits() {
        let text = "  hello world  "
        let result = ViewHelpers.insertionProbeSampleTextForRun(text)
        #expect(result == "hello world")
    }

    @Test("forRun truncates after trimming")
    func forRunTruncatesAfterTrim() {
        let text = "  " + String(repeating: "a", count: 250) + "  "
        let result = ViewHelpers.insertionProbeSampleTextForRun(text)
        #expect(result.count == 200)
    }

    @Test("forRun returns empty for whitespace-only")
    func forRunWhitespaceOnly() {
        let result = ViewHelpers.insertionProbeSampleTextForRun("   ")
        #expect(result.isEmpty)
    }

    // MARK: - hasInsertionProbeSampleText

    @Test("hasInsertionProbeSampleText true for non-empty")
    func hasSampleTextTrue() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("test") == true)
    }

    @Test("hasInsertionProbeSampleText false for empty")
    func hasSampleTextEmpty() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("") == false)
    }

    @Test("hasInsertionProbeSampleText false for whitespace-only")
    func hasSampleTextWhitespace() {
        #expect(ViewHelpers.hasInsertionProbeSampleText("   \n\t  ") == false)
    }

    // MARK: - hasHotkeyDraftEdits

    @Test("no edits when draft matches current key")
    func noEditsWhenMatching() {
        let result = ViewHelpers.hasHotkeyDraftEdits(
            draft: "space",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(result == false)
    }

    @Test("has edits when draft key differs")
    func editsWhenKeyDiffers() {
        let result = ViewHelpers.hasHotkeyDraftEdits(
            draft: "f6",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(result == true)
    }

    @Test("has edits when draft includes different modifiers")
    func editsWhenModifiersDiffer() {
        let result = ViewHelpers.hasHotkeyDraftEdits(
            draft: "cmd+option+space",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(result == true)
    }

    @Test("no edits for empty draft")
    func noEditsEmptyDraft() {
        let result = ViewHelpers.hasHotkeyDraftEdits(
            draft: "",
            currentKey: "space",
            currentModifiers: [.command]
        )
        #expect(result == false)
    }

    // MARK: - effectiveHotkeyRiskContext

    @Test("falls back to current key when draft is empty")
    func riskContextFallback() {
        let ctx = ViewHelpers.effectiveHotkeyRiskContext(
            draft: "",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(ctx.key == "space")
        #expect(ctx.requiredModifiers == [.command, .shift])
    }

    @Test("uses draft key when valid")
    func riskContextUsesDraft() {
        let ctx = ViewHelpers.effectiveHotkeyRiskContext(
            draft: "f6",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(ctx.key == "f6")
        #expect(ctx.requiredModifiers == [.command, .shift])
    }

    @Test("uses draft modifiers when present")
    func riskContextUsesDraftModifiers() {
        let ctx = ViewHelpers.effectiveHotkeyRiskContext(
            draft: "cmd+option+f6",
            currentKey: "space",
            currentModifiers: [.command, .shift]
        )
        #expect(ctx.key == "f6")
        #expect(ctx.requiredModifiers.contains(.command))
        #expect(ctx.requiredModifiers.contains(.option))
    }

    @Test("falls back when draft key is unsupported")
    func riskContextUnsupportedDraft() {
        let ctx = ViewHelpers.effectiveHotkeyRiskContext(
            draft: "invalidkey999",
            currentKey: "escape",
            currentModifiers: [.control]
        )
        #expect(ctx.key == "escape")
        #expect(ctx.requiredModifiers == [.control])
    }

    // MARK: - insertionProbeStatus

    @Test("success maps correctly")
    func probeStatusSuccess() {
        let status = ViewHelpers.insertionProbeStatus(succeeded: true)
        #expect(status == .success)
    }

    @Test("failure maps correctly")
    func probeStatusFailure() {
        let status = ViewHelpers.insertionProbeStatus(succeeded: false)
        #expect(status == .failure)
    }

    @Test("nil maps to unknown")
    func probeStatusUnknown() {
        let status = ViewHelpers.insertionProbeStatus(succeeded: nil)
        #expect(status == .unknown)
    }

    // MARK: - InsertionProbeStatus equatable

    @Test("InsertionProbeStatus cases are distinct")
    func probeStatusDistinct() {
        #expect(ViewHelpers.InsertionProbeStatus.success != .failure)
        #expect(ViewHelpers.InsertionProbeStatus.success != .unknown)
        #expect(ViewHelpers.InsertionProbeStatus.failure != .unknown)
    }
}
