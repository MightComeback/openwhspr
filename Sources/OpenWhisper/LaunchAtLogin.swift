@preconcurrency import ServiceManagement
import Foundation

/// Manages Launch at Login state via SMAppService (macOS 13+).
enum LaunchAtLogin {
    nonisolated(unsafe) private static let service = SMAppService.mainApp

    /// Whether the app is currently registered to launch at login.
    static var isEnabled: Bool {
        service.status == .enabled
    }

    /// Register or unregister the app for launch at login.
    /// Updates the UserDefaults key to stay in sync with the actual state.
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            UserDefaults.standard.set(enabled, forKey: AppDefaults.Keys.launchAtLogin)
            return true
        } catch {
            UserDefaults.standard.set(isEnabled, forKey: AppDefaults.Keys.launchAtLogin)
            return false
        }
    }
}
