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
        XCTAssertFalse(HotkeyDisplay.isSupportedKey(""))
        XCTAssertFalse(HotkeyDisplay.isSupportedKey("capslock"))
        XCTAssertFalse(HotkeyDisplay.isSupportedKey("foo"))
    }
}