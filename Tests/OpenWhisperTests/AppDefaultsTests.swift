import XCTest
@testable import OpenWhisper

final class AppDefaultsTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "AppDefaultsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        addTeardownBlock {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
        return defaults
    }

    func testRegisterSetsHotkeyDefaults() {
        let defaults = makeDefaults()
        AppDefaults.register(into: defaults)
        XCTAssertEqual(defaults.string(forKey: AppDefaults.Keys.hotkeyKey), "space")
        XCTAssertEqual(defaults.string(forKey: AppDefaults.Keys.hotkeyMode), HotkeyMode.toggle.rawValue)
        XCTAssertTrue(defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredCommand))
        XCTAssertTrue(defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredShift))
    }

    func testRegisterSetsOutputDefaults() {
        let defaults = makeDefaults()
        AppDefaults.register(into: defaults)
        XCTAssertTrue(defaults.bool(forKey: AppDefaults.Keys.outputAutoCopy))
        XCTAssertFalse(defaults.bool(forKey: AppDefaults.Keys.outputAutoPaste))
        XCTAssertTrue(defaults.bool(forKey: AppDefaults.Keys.outputSmartCapitalization))
    }

    func testRegisterSetsModelDefaults() {
        let defaults = makeDefaults()
        AppDefaults.register(into: defaults)
        XCTAssertEqual(defaults.string(forKey: AppDefaults.Keys.modelSource), ModelSource.bundledTiny.rawValue)
        XCTAssertEqual(defaults.string(forKey: AppDefaults.Keys.modelCustomPath), "")
    }
}
