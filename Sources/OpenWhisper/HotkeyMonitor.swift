import AppKit
import ApplicationServices

final class HotkeyMonitor: ObservableObject {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    func start() {
        requestAccessibilityIfNeeded()

        if globalMonitor == nil {
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                _ = self?.handle(event)
            }
        }

        if localMonitor == nil {
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self else { return event }
                return self.handle(event) ? nil : event
            }
        }
    }

    private func handle(_ event: NSEvent) -> Bool {
        let required: NSEvent.ModifierFlags = [.command, .shift]
        let hasRequired = event.modifierFlags.intersection(required) == required
        let hasForbidden = event.modifierFlags.contains(.option) || event.modifierFlags.contains(.control)

        guard hasRequired, !hasForbidden else { return false }
        guard event.charactersIgnoringModifiers?.lowercased() == "d" else { return false }

        handler()
        return true
    }

    private func requestAccessibilityIfNeeded() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
