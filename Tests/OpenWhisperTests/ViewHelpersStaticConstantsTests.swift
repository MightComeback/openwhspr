import Testing
@testable import OpenWhisper

@Suite("ViewHelpers static constants and data coverage")
struct ViewHelpersStaticConstantsTests {

    // MARK: - commonHotkeyKeySections

    @Test("commonHotkeyKeySections returns five sections")
    func sectionsCount() {
        let sections = ViewHelpers.commonHotkeyKeySections
        #expect(sections.count == 5)
    }

    @Test("commonHotkeyKeySections section titles are correct")
    func sectionTitles() {
        let titles = ViewHelpers.commonHotkeyKeySections.map(\.title)
        #expect(titles == ["Basic", "Navigation", "Function", "Punctuation", "Keypad"])
    }

    @Test("Basic section contains space key")
    func basicSectionContainsSpace() {
        let basic = ViewHelpers.commonHotkeyKeySections.first { $0.title == "Basic" }
        #expect(basic != nil)
        #expect(basic!.keys.contains("space"))
    }

    @Test("Navigation section contains arrow keys")
    func navigationSectionContainsArrows() {
        let nav = ViewHelpers.commonHotkeyKeySections.first { $0.title == "Navigation" }
        #expect(nav != nil)
        for key in ["left", "right", "up", "down"] {
            #expect(nav!.keys.contains(key))
        }
    }

    @Test("Function section contains f1 through f24")
    func functionSectionRange() {
        let fn = ViewHelpers.commonHotkeyKeySections.first { $0.title == "Function" }
        #expect(fn != nil)
        #expect(fn!.keys.count == 24)
        #expect(fn!.keys.first == "f1")
        #expect(fn!.keys.last == "f24")
    }

    @Test("Punctuation section contains common punctuation keys")
    func punctuationSection() {
        let punct = ViewHelpers.commonHotkeyKeySections.first { $0.title == "Punctuation" }
        #expect(punct != nil)
        for key in ["minus", "equals", "comma", "period", "slash"] {
            #expect(punct!.keys.contains(key))
        }
    }

    @Test("Keypad section contains keypad0 through keypad9")
    func keypadSectionDigits() {
        let kp = ViewHelpers.commonHotkeyKeySections.first { $0.title == "Keypad" }
        #expect(kp != nil)
        for i in 0...9 {
            #expect(kp!.keys.contains("keypad\(i)"))
        }
    }

    @Test("Keypad section contains keypadenter and keypadequals")
    func keypadSectionSpecialKeys() {
        let kp = ViewHelpers.commonHotkeyKeySections.first { $0.title == "Keypad" }
        #expect(kp != nil)
        #expect(kp!.keys.contains("keypadenter"))
        #expect(kp!.keys.contains("keypadequals"))
    }

    @Test("All section keys are non-empty strings")
    func allKeysNonEmpty() {
        for section in ViewHelpers.commonHotkeyKeySections {
            #expect(!section.keys.isEmpty)
            for key in section.keys {
                #expect(!key.isEmpty)
            }
        }
    }

    @Test("No duplicate keys across all sections")
    func noDuplicateKeys() {
        var seen = Set<String>()
        for section in ViewHelpers.commonHotkeyKeySections {
            for key in section.keys {
                #expect(!seen.contains(key), "Duplicate key: \(key)")
                seen.insert(key)
            }
        }
    }

    // MARK: - insertionProbeMaxCharacters

    @Test("insertionProbeMaxCharacters is 200")
    func maxCharactersValue() {
        #expect(ViewHelpers.insertionProbeMaxCharacters == 200)
    }

    @Test("insertionProbeMaxCharacters used consistently by truncation check")
    func maxCharactersConsistentWithTruncation() {
        let exactText = String(repeating: "a", count: ViewHelpers.insertionProbeMaxCharacters)
        #expect(!ViewHelpers.insertionProbeSampleTextWillTruncate(exactText))
        let overText = String(repeating: "a", count: ViewHelpers.insertionProbeMaxCharacters + 1)
        #expect(ViewHelpers.insertionProbeSampleTextWillTruncate(overText))
    }

    @Test("insertionProbeMaxCharacters used consistently by enforce limit")
    func maxCharactersConsistentWithEnforce() {
        let overText = String(repeating: "b", count: ViewHelpers.insertionProbeMaxCharacters + 50)
        let enforced = ViewHelpers.enforceInsertionProbeSampleTextLimit(overText)
        #expect(enforced.count == ViewHelpers.insertionProbeMaxCharacters)
    }

    // MARK: - captureProfileDisabledReasonText

    @Test("captureProfileDisabledReasonText is a non-empty string")
    func disabledReasonNonEmpty() {
        #expect(!ViewHelpers.captureProfileDisabledReasonText.isEmpty)
    }

    @Test("captureProfileDisabledReasonText mentions Refresh frontmost app")
    func disabledReasonMentionsRefresh() {
        #expect(ViewHelpers.captureProfileDisabledReasonText.contains("Refresh frontmost app"))
    }

    @Test("captureProfileDisabledReasonText mentions target app")
    func disabledReasonMentionsTarget() {
        #expect(ViewHelpers.captureProfileDisabledReasonText.contains("target app"))
    }

    // MARK: - bridgeModifiers identity

    @Test("bridgeModifiers returns same set unchanged")
    func bridgeModifiersIdentity() {
        let mods: Set<ViewHelpers.ParsedModifier> = [.command, .shift]
        #expect(ViewHelpers.bridgeModifiers(mods) == mods)
    }

    @Test("bridgeModifiers with empty set returns empty")
    func bridgeModifiersEmpty() {
        let empty: Set<ViewHelpers.ParsedModifier> = []
        #expect(ViewHelpers.bridgeModifiers(empty).isEmpty)
    }

    @Test("bridgeModifiers with all modifiers")
    func bridgeModifiersAll() {
        let all: Set<ViewHelpers.ParsedModifier> = [.command, .shift, .option, .control, .capsLock]
        #expect(ViewHelpers.bridgeModifiers(all) == all)
        #expect(ViewHelpers.bridgeModifiers(all).count == 5)
    }
}
