import XCTest
@testable import OpenWhisper

final class OpenWhisperTests: XCTestCase {
    func testModelSourceTitles() throws {
        XCTAssertEqual(ModelSource.bundledTiny.title, "Bundled tiny model")
        XCTAssertEqual(ModelSource.customPath.title, "Custom local model")
    }

    func testModelSourceAllCases() throws {
        let allCases = ModelSource.allCases.map { $0.title }
        XCTAssertFalse(allCases.isEmpty)
    }

    func testHotkeySupportedKeyValidation() throws {
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("space"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("F12"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("z"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("home"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("pgdn"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("pg down"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("page down"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("f24"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("page-up"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("left arrow"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("left key"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("return key"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("space key"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("tab key"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("home key"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("numpad0"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("keypadenter"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("cmd+shift+space"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("cmd shift space"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("command-shift-page-down"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("⌘ + ⇧ + f6"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("⌘⇧space"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("⌃⌥return"))
        XCTAssertFalse(HotkeyDisplay.isSupportedKey(""))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("capslock"))
        XCTAssertFalse(HotkeyDisplay.isSupportedKey("foo"))
    }

    func testHotkeyCanonicalAliases() throws {
        XCTAssertEqual(HotkeyDisplay.canonicalKey("spacebar"), "space")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("space key"), "space")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("tab key"), "tab")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("␣"), "space")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("enter"), "return")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("return key"), "return")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("↩"), "return")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("⏎"), "return")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("esc"), "escape")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("⎋"), "escape")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("delete key"), "delete")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("backspace"), "delete")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("⌫"), "delete")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("⌦"), "forwarddelete")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("caps"), "capslock")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("←"), "left")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("left arrow"), "left")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("→"), "right")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("right arrow"), "right")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("↑"), "up")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("↓"), "down")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("left key"), "left")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("home key"), "home")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("end key"), "end")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("page-up"), "pageup")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("pg down"), "pagedown")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("page down"), "pagedown")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("numpad0"), "keypad0")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("numpad enter"), "keypadenter")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("cmd+shift+space"), "space")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("cmd shift space"), "space")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("command-shift-page-down"), "pagedown")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("⌘ + ⇧ + f6"), "f6")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("⌘⇧space"), "space")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("⌃⌥return"), "return")
    }

    func testHotkeyDisplayForKeypadKeys() throws {
        XCTAssertEqual(HotkeyDisplay.displayKey("keypad0"), "Num0")
        XCTAssertEqual(HotkeyDisplay.displayKey("numpadplus"), "Num+")
        XCTAssertEqual(HotkeyDisplay.displayKey("keypadenter"), "NumEnter")
    }
}