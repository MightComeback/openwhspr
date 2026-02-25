import Testing
import Foundation
@testable import OpenWhisper

@Suite("LaunchAtLogin")
struct LaunchAtLoginTests {

    @Test("isEnabled returns a Bool without crashing")
    func isEnabledReturnsValue() {
        // SMAppService.mainApp.status may not be .enabled in test env,
        // but accessing it must not crash.
        let _ = LaunchAtLogin.isEnabled
    }

    @Test("setEnabled false syncs UserDefaults")
    func setEnabledFalseSyncsDefaults() {
        // In test/CI the SMAppService call may fail, but the method
        // must still update UserDefaults to reflect actual state.
        let key = AppDefaults.Keys.launchAtLogin
        UserDefaults.standard.removeObject(forKey: key)

        // Attempt to disable – success or failure, defaults must be set.
        let _ = LaunchAtLogin.setEnabled(false)
        // After the call, the key should exist (set to actual isEnabled state or false).
        let stored = UserDefaults.standard.object(forKey: key)
        #expect(stored != nil, "UserDefaults key must be set after setEnabled call")
    }

    @Test("setEnabled true syncs UserDefaults")
    func setEnabledTrueSyncsDefaults() {
        let key = AppDefaults.Keys.launchAtLogin
        UserDefaults.standard.removeObject(forKey: key)

        let _ = LaunchAtLogin.setEnabled(true)
        let stored = UserDefaults.standard.object(forKey: key)
        #expect(stored != nil, "UserDefaults key must be set after setEnabled(true)")
    }

    @Test("setEnabled returns Bool indicating success")
    func setEnabledReturnsBool() {
        // Just verify return type is Bool (compiles = passes).
        let result: Bool = LaunchAtLogin.setEnabled(false)
        // In CI, register/unregister likely fails → false
        // Either way it's a valid Bool.
        let _ = result
    }

    @Test("setEnabled false then true does not crash")
    func toggleDoesNotCrash() {
        let _ = LaunchAtLogin.setEnabled(false)
        let _ = LaunchAtLogin.setEnabled(true)
        let _ = LaunchAtLogin.setEnabled(false)
    }

    @Test("UserDefaults reflects actual state on failure path")
    func defaultsReflectsActualOnFailure() {
        let key = AppDefaults.Keys.launchAtLogin
        // Pre-set to opposite of actual
        let actual = LaunchAtLogin.isEnabled
        UserDefaults.standard.set(!actual, forKey: key)

        // Call setEnabled — on failure path it sets defaults to isEnabled
        let result = LaunchAtLogin.setEnabled(true)
        let stored = UserDefaults.standard.bool(forKey: key)
        if result {
            // Success: stored should reflect requested value
            #expect(stored == true)
        } else {
            // Failure: stored should reflect actual system state
            #expect(stored == LaunchAtLogin.isEnabled)
        }
    }
}
