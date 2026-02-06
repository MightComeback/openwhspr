@preconcurrency import AppKit
@preconcurrency import ApplicationServices
import CoreFoundation

final class HotkeyMonitor: @unchecked Sendable, ObservableObject {
    var handler: (() -> Void)?

    private var requiredModifiers: NSEvent.ModifierFlags = [.command, .shift]
    private var forbiddenModifiers: NSEvent.ModifierFlags = [.option, .control]
    private var keyCharacter: String = "d"

    private var globalMonitor: Any?
    private var localMonitor: Any?

    init() {}

    func setHandler(_ handler: @escaping () -> Void) {
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

    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    func updateConfig(required: NSEvent.ModifierFlags, forbidden: NSEvent.ModifierFlags, key: String) {
        self.requiredModifiers = required
        self.forbiddenModifiers = forbidden
        self.keyCharacter = key.lowercased()
        stop()
        start()
    }

    private func handle(_ event: NSEvent) -> Bool {
        let hasRequired = event.modifierFlags.intersection(requiredModifiers) == requiredModifiers
        let hasForbidden = !event.modifierFlags.intersection(forbiddenModifiers).isEmpty

        guard hasRequired, !hasForbidden else { return false }
        guard let chars = event.charactersIgnoringModifiers?.lowercased(), chars == keyCharacter else { return false }

        handler?()
        return true
    }

    private func requestAccessibilityIfNeeded() {
        let options: CFDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as CFString: kCFBooleanTrue] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}