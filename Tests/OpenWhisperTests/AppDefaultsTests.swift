import Testing
import Foundation
@testable import OpenWhisper

@Suite("AppDefaults")
struct AppDefaultsTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "AppDefaultsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test
    func registerSetsHotkeyDefaults() {
        let defaults = makeDefaults()
        AppDefaults.register(into: defaults)
        #expect(defaults.string(forKey: AppDefaults.Keys.hotkeyKey) == "space")
        #expect(defaults.string(forKey: AppDefaults.Keys.hotkeyMode) == HotkeyMode.toggle.rawValue)
        #expect(defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredCommand))
        #expect(defaults.bool(forKey: AppDefaults.Keys.hotkeyRequiredShift))
    }

    @Test
    func registerSetsOutputDefaults() {
        let defaults = makeDefaults()
        AppDefaults.register(into: defaults)
        #expect(defaults.bool(forKey: AppDefaults.Keys.outputAutoCopy))
        #expect(!defaults.bool(forKey: AppDefaults.Keys.outputAutoPaste))
        #expect(defaults.bool(forKey: AppDefaults.Keys.outputSmartCapitalization))
    }

    @Test
    func registerSetsModelDefaults() {
        let defaults = makeDefaults()
        AppDefaults.register(into: defaults)
        #expect(defaults.string(forKey: AppDefaults.Keys.modelSource) == ModelSource.bundledTiny.rawValue)
        #expect(defaults.string(forKey: AppDefaults.Keys.modelCustomPath) == "")
    }
}
