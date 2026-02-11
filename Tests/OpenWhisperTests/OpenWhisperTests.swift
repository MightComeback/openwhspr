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
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("page down"))
        XCTAssertTrue(HotkeyDisplay.isSupportedKey("page-up"))
        XCTAssertFalse(HotkeyDisplay.isSupportedKey(""))
        XCTAssertFalse(HotkeyDisplay.isSupportedKey("capslock"))
        XCTAssertFalse(HotkeyDisplay.isSupportedKey("foo"))
    }

    func testHotkeyCanonicalAliases() throws {
        XCTAssertEqual(HotkeyDisplay.canonicalKey("spacebar"), "space")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("␣"), "space")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("enter"), "return")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("↩"), "return")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("⏎"), "return")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("esc"), "escape")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("⎋"), "escape")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("backspace"), "delete")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("⌫"), "delete")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("⌦"), "forwarddelete")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("←"), "left")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("→"), "right")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("↑"), "up")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("↓"), "down")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("page-up"), "pageup")
        XCTAssertEqual(HotkeyDisplay.canonicalKey("page down"), "pagedown")
    }
}