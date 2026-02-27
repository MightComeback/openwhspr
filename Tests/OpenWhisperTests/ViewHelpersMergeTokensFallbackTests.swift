import Testing
import Foundation
@testable import OpenWhisper

@Suite("ViewHelpers merge tokens fallback paths")
struct ViewHelpersMergeTokensFallbackTests {

    // MARK: - Space-separated merge fallback (line ~185)

    @Test("Space-separated hotkey with multi-word key triggers merge fallback")
    func spaceSeparatedMerge() {
        // "cmd right arrow" splits to ["cmd", "right", "arrow"]
        // parseHotkeyTokens fails (two non-modifier tokens), merge joins trailing → ["cmd", "right arrow"]
        let result = ViewHelpers.parseHotkeyDraft("cmd right arrow")
        #expect(result != nil)
        #expect(result?.key == "right arrow")
        #expect(result?.requiredModifiers?.contains(.command) == true)
    }

    @Test("Space-separated hotkey with three-word key triggers merge fallback")
    func spaceSeparatedMergeThreeWords() {
        let result = ViewHelpers.parseHotkeyDraft("shift page up key")
        #expect(result != nil)
        #expect(result?.key == "page up key")
        #expect(result?.requiredModifiers?.contains(.shift) == true)
    }

    @Test("Space-separated hotkey single key does not need merge")
    func spaceSeparatedNoMergeNeeded() {
        let result = ViewHelpers.parseHotkeyDraft("cmd space")
        #expect(result != nil)
        #expect(result?.key == "space")
    }

    // MARK: - Generic separator merge fallback (line ~214)

    @Test("Generic separator hotkey with multi-word key triggers merge fallback")
    func genericSeparatorMerge() {
        // Using underscore separator: "cmd_right_arrow" splits to ["cmd", "right", "arrow"]
        // parseHotkeyTokens fails, merge joins trailing → succeeds
        let result = ViewHelpers.parseHotkeyDraft("cmd_right_arrow")
        #expect(result != nil)
        #expect(result?.key == "right arrow")
        #expect(result?.requiredModifiers?.contains(.command) == true)
    }

    @Test("Underscore separator single key no merge needed")
    func underscoreSeparatorNoMerge() {
        let result = ViewHelpers.parseHotkeyDraft("cmd_a")
        #expect(result != nil)
        #expect(result?.key == "a")
    }

    @Test("Underscore separator with two modifiers and multi-word key")
    func underscoreTwoModsMerge() {
        let result = ViewHelpers.parseHotkeyDraft("cmd_shift_right_arrow")
        #expect(result != nil)
        #expect(result?.key == "right arrow")
        #expect(result?.requiredModifiers?.contains(.command) == true)
        #expect(result?.requiredModifiers?.contains(.shift) == true)
    }
}
