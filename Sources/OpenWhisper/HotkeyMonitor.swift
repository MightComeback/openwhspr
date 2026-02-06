@preconcurrency import AppKit
@preconcurrency import ApplicationServices
import CoreFoundation

final class HotkeyMonitor: @unchecked Sendable, ObservableObject {
    weak var transcriber: AudioTranscriber?

    private var requiredModifiers: NSEvent.ModifierFlags = [.command, .shift]
    private var forbiddenModifiers: NSEvent.ModifierFlags = [.option, .control]
    private var keyCharacter: String = "d"

    private var globalMonitor: Any?
    private var localMonitor: Any?

    init() {
        loadConfig()
        start()
        NotificationCenter.default.addObserver(self, selector: #selector(configChanged), name: UserDefaults.didChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setTranscriber(_ transcriber: AudioTranscriber) {
        self.transcriber = transcriber
    }

    @objc private func configChanged() {
        loadConfig()
    }

    private func loadConfig() {
        let defaults = UserDefaults.standard
        let requiredRaw = defaults.string(forKey: "hotkey.required") ?? "command,shift"
        let forbiddenRaw = defaults.string(forKey: "hotkey.forbidden") ?? "option,control"
        let key = defaults.string(forKey: "hotkey.key") ?? "d"
        updateConfig(required: parseModifiers(requiredRaw), forbidden: parseModifiers(forbiddenRaw), key: key)
    }

    private func parseModifiers(_ raw: String) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        for part in raw.components(separatedBy: ",") {
            let trimmed = part.trimmingCharacters(in: .whitespaces).lowercased()
            switch trimmed {
            case "command", "cmd": flags.insert(.command)
            case "shift": flags.insert(.shift)
            case "option", "alt": flags.insert(.option)
            case "control", "ctrl": flags.insert(.control)
            case "capslock": flags.insert(.capsLock)
            default: break
            }
        }
        return flags
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

        transcriber?.toggleRecording()
        return true
    }

    private func requestAccessibilityIfNeeded() {
        let options: CFDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as CFString: kCFBooleanTrue] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}