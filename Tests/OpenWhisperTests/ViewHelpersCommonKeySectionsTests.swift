import Testing
import Foundation
@testable import OpenWhisper

@Suite("ViewHelpers commonHotkeyKeySections")
struct ViewHelpersCommonKeySectionsTests {

    @Test("returns non-empty sections array")
    func nonEmpty() {
        let sections = ViewHelpers.commonHotkeyKeySections
        #expect(!sections.isEmpty)
    }

    @Test("each section has a non-empty title")
    func sectionTitles() {
        for section in ViewHelpers.commonHotkeyKeySections {
            #expect(!section.title.isEmpty)
        }
    }

    @Test("each section has at least one key")
    func sectionKeysNonEmpty() {
        for section in ViewHelpers.commonHotkeyKeySections {
            #expect(!section.keys.isEmpty)
        }
    }

    @Test("all keys are non-empty strings")
    func allKeysNonEmpty() {
        for section in ViewHelpers.commonHotkeyKeySections {
            for key in section.keys {
                #expect(!key.isEmpty)
            }
        }
    }

    @Test("contains expected section titles")
    func expectedTitles() {
        let titles = ViewHelpers.commonHotkeyKeySections.map(\.title)
        #expect(titles.contains("Basic"))
        #expect(titles.contains("Navigation"))
        #expect(titles.contains("Function"))
        #expect(titles.contains("Punctuation"))
        #expect(titles.contains("Keypad"))
    }

    @Test("Basic section contains space key")
    func basicHasSpace() {
        let basic = ViewHelpers.commonHotkeyKeySections.first { $0.title == "Basic" }
        #expect(basic != nil)
        #expect(basic!.keys.contains("space"))
    }

    @Test("Function section contains f1 through f12")
    func functionKeysPresent() {
        let funcSection = ViewHelpers.commonHotkeyKeySections.first { $0.title == "Function" }
        #expect(funcSection != nil)
        for i in 1...12 {
            #expect(funcSection!.keys.contains("f\(i)"))
        }
    }

    @Test("Navigation section contains arrow keys")
    func navigationArrowKeys() {
        let nav = ViewHelpers.commonHotkeyKeySections.first { $0.title == "Navigation" }
        #expect(nav != nil)
        for key in ["left", "right", "up", "down"] {
            #expect(nav!.keys.contains(key))
        }
    }

    @Test("no duplicate keys across all sections")
    func noDuplicateKeys() {
        var seen = Set<String>()
        for section in ViewHelpers.commonHotkeyKeySections {
            for key in section.keys {
                #expect(!seen.contains(key), "Duplicate key: \(key)")
                seen.insert(key)
            }
        }
    }

    @Test("section count is 5")
    func sectionCount() {
        #expect(ViewHelpers.commonHotkeyKeySections.count == 5)
    }
}
