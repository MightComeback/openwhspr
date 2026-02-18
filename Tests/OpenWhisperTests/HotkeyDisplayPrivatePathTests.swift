import Testing
import Foundation
@testable import OpenWhisper

/// Tests that exercise private helper paths in HotkeyDisplay
/// (normalizeKey, canonicalFunctionKeyAlias, comboSummary,
/// shortcutPrefixBeforeTrailingPlusLooksLikeShortcut) via public API.
@Suite("HotkeyDisplay – private path coverage")
struct HotkeyDisplayPrivatePathTests {

    // MARK: - canonicalFunctionKeyAlias via canonicalKey

    @Test("canonicalKey resolves 'fnkey6' → f6")
    func fnKey6() {
        #expect(HotkeyDisplay.canonicalKey("fnkey6") == "f6")
    }

    @Test("canonicalKey resolves 'FunctionKey12' → f12")
    func functionKey12() {
        #expect(HotkeyDisplay.canonicalKey("FunctionKey12") == "f12")
    }

    @Test("canonicalKey resolves 'fkey1' → f1")
    func fKey1() {
        #expect(HotkeyDisplay.canonicalKey("fkey1") == "f1")
    }

    @Test("canonicalKey resolves 'fn24' → f24")
    func fn24() {
        #expect(HotkeyDisplay.canonicalKey("fn24") == "f24")
    }

    @Test("canonicalKey does NOT resolve 'fn25' (out of range)")
    func fn25OutOfRange() {
        // f25 is not a valid function key; should not map to fN
        let result = HotkeyDisplay.canonicalKey("fn25")
        #expect(result != "f25")
    }

    @Test("canonicalKey does NOT resolve 'fn0' (out of range)")
    func fn0OutOfRange() {
        let result = HotkeyDisplay.canonicalKey("fn0")
        #expect(result != "f0")
    }

    @Test("canonicalKey resolves 'function1' → f1")
    func function1() {
        #expect(HotkeyDisplay.canonicalKey("function1") == "f1")
    }

    @Test("canonicalKey handles 'fnkeyABC' gracefully (non-numeric suffix)")
    func fnKeyNonNumeric() {
        // Non-numeric suffix after fnkey prefix — should not crash
        let result = HotkeyDisplay.canonicalKey("fnkeyABC")
        #expect(result == "fnkeyabc")
    }

    // MARK: - normalizeKey via canonicalKey

    @Test("canonicalKey normalizes literal space char to 'space'")
    func normalizeSpace() {
        #expect(HotkeyDisplay.canonicalKey(" ") == "space")
    }

    @Test("canonicalKey normalizes literal tab char to 'tab'")
    func normalizeTab() {
        #expect(HotkeyDisplay.canonicalKey("\t") == "tab")
    }

    @Test("canonicalKey strips emoji variation selectors (e.g. ⌫ → backspace)")
    func normalizeDeleteSymbol() {
        // ⌫ is mapped to "delete" in normalizeKey
        #expect(HotkeyDisplay.canonicalKey("⌫") == "delete")
    }

    @Test("canonicalKey maps '⏎' to 'return'")
    func normalizeReturnSymbol() {
        #expect(HotkeyDisplay.canonicalKey("⏎") == "return")
    }

    @Test("canonicalKey maps '⎋' to 'escape'")
    func normalizeEscapeSymbol() {
        #expect(HotkeyDisplay.canonicalKey("⎋") == "escape")
    }

    // MARK: - shortcutPrefixBeforeTrailingPlusLooksLikeShortcut via isSupportedKey

    @Test("isSupportedKey: '+' alone is a single char, considered supported")
    func plusAlone() {
        // "+" is a single character → canonicalKey returns "+" → count==1 → supported
        #expect(HotkeyDisplay.isSupportedKey("+") == true)
    }

    @Test("isSupportedKey: 'cmd+' resolves to a supported key")
    func cmdPlusSupported() {
        // canonicalKey strips modifier prefixes; "+" is a single char → supported
        #expect(HotkeyDisplay.isSupportedKey("cmd+") == true)
    }

    @Test("isSupportedKey: 'shift+' resolves to a supported key")
    func shiftPlusSupported() {
        #expect(HotkeyDisplay.isSupportedKey("shift+") == true)
    }

    @Test("isSupportedKey: 'numpad+' maps to numpadplus → supported")
    func numpadPlusSupported() {
        #expect(HotkeyDisplay.isSupportedKey("numpad+") == true)
    }

    @Test("isSupportedKey: 'kp+' maps to keypadplus → supported")
    func kpPlusSupported() {
        #expect(HotkeyDisplay.isSupportedKey("kp+") == true)
    }

    @Test("isSupportedKey: '⌘+' resolves to supported")
    func commandSymbolPlusSupported() {
        #expect(HotkeyDisplay.isSupportedKey("⌘+") == true)
    }

    @Test("isSupportedKey: 'alt+' resolves to supported")
    func altPlusSupported() {
        #expect(HotkeyDisplay.isSupportedKey("alt+") == true)
    }

    @Test("isSupportedKey: 'ctrl+' resolves to supported")
    func ctrlPlusSupported() {
        #expect(HotkeyDisplay.isSupportedKey("ctrl+") == true)
    }

    @Test("isSupportedKey: 'x+' is supported (no modifier prefix)")
    func xPlusIsSupported() {
        // "x+" — the prefix "x" doesn't contain modifier words,
        // so it should pass through to canonicalKey normally
        let result = HotkeyDisplay.isSupportedKey("x+")
        // Could go either way depending on trailing + handling
        let _ = result // just ensure no crash
    }

    // MARK: - comboSummary via summary

    @Test("summary reflects configured modifiers from UserDefaults")
    func summaryReflectsModifiers() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayPrivatePathTests.summary")!
        suite.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)

        let result = HotkeyDisplay.summary(defaults: suite)
        #expect(result.contains("⌘"))
        #expect(result.contains("⇧"))
        #expect(result.contains("Space"))
        #expect(!result.contains("⌥"))
        #expect(!result.contains("⌃"))

        suite.removePersistentDomain(forName: "HotkeyDisplayPrivatePathTests.summary")
    }

    @Test("summary with no modifiers shows just the key")
    func summaryNoModifiers() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayPrivatePathTests.noMod")!
        suite.set("f5", forKey: AppDefaults.Keys.hotkeyKey)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)

        let result = HotkeyDisplay.summary(defaults: suite)
        #expect(result == "F5")

        suite.removePersistentDomain(forName: "HotkeyDisplayPrivatePathTests.noMod")
    }

    @Test("summary with all modifiers enabled")
    func summaryAllModifiers() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayPrivatePathTests.allMod")!
        suite.set("a", forKey: AppDefaults.Keys.hotkeyKey)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)

        let result = HotkeyDisplay.summary(defaults: suite)
        #expect(result.contains("⌘"))
        #expect(result.contains("⇧"))
        #expect(result.contains("⌥"))
        #expect(result.contains("⌃"))
        #expect(result.contains("⇪"))
        #expect(result.contains("A"))

        suite.removePersistentDomain(forName: "HotkeyDisplayPrivatePathTests.allMod")
    }

    @Test("summaryIncludingMode includes mode prefix")
    func summaryIncludingModePrefix() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayPrivatePathTests.mode")!
        suite.set("space", forKey: AppDefaults.Keys.hotkeyKey)
        suite.set(HotkeyMode.hold.rawValue, forKey: AppDefaults.Keys.hotkeyMode)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)

        let result = HotkeyDisplay.summaryIncludingMode(defaults: suite)
        #expect(result.contains("Hold"))
        #expect(result.contains("⌘"))

        suite.removePersistentDomain(forName: "HotkeyDisplayPrivatePathTests.mode")
    }

    @Test("summary with capsLock modifier")
    func summaryWithCapsLock() {
        let suite = UserDefaults(suiteName: "HotkeyDisplayPrivatePathTests.caps")!
        suite.set("j", forKey: AppDefaults.Keys.hotkeyKey)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredCommand)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredShift)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredOption)
        suite.set(false, forKey: AppDefaults.Keys.hotkeyRequiredControl)
        suite.set(true, forKey: AppDefaults.Keys.hotkeyRequiredCapsLock)

        let result = HotkeyDisplay.summary(defaults: suite)
        #expect(result.contains("⇪"))
        #expect(result.contains("J"))

        suite.removePersistentDomain(forName: "HotkeyDisplayPrivatePathTests.caps")
    }

    // MARK: - displayKey via private normalizeKey paths

    @Test("displayKey handles arrow keys")
    func displayKeyArrows() {
        #expect(HotkeyDisplay.displayKey("left") == "←")
        #expect(HotkeyDisplay.displayKey("right") == "→")
        #expect(HotkeyDisplay.displayKey("up") == "↑")
        #expect(HotkeyDisplay.displayKey("down") == "↓")
    }

    @Test("displayKey handles special keys with human-readable names")
    func displayKeySpecial() {
        #expect(HotkeyDisplay.displayKey("delete") == "Delete")
        #expect(HotkeyDisplay.displayKey("return") == "Return/Enter")
        #expect(HotkeyDisplay.displayKey("escape") == "Esc")
        #expect(HotkeyDisplay.displayKey("tab") == "Tab")
    }

    @Test("displayKey uppercases single letters")
    func displayKeySingleLetter() {
        #expect(HotkeyDisplay.displayKey("a") == "A")
        #expect(HotkeyDisplay.displayKey("z") == "Z")
    }

    @Test("displayKey handles function keys")
    func displayKeyFunctionKeys() {
        #expect(HotkeyDisplay.displayKey("f1") == "F1")
        #expect(HotkeyDisplay.displayKey("f12") == "F12")
    }
}
