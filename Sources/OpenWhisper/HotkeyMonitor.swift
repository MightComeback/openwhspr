@preconcurrency import AppKit
@preconcurrency import ApplicationServices
import Carbon.HIToolbox
import CoreFoundation

final class HotkeyMonitor: @unchecked Sendable, ObservableObject {
    weak var transcriber: AudioTranscriber?

    private var requiredModifiers: CGEventFlags = [.maskCommand, .maskShift]
    private var forbiddenModifiers: CGEventFlags = [.maskAlternate, .maskControl]
    private var keyCharacter: String = " "
    private var keyCode: CGKeyCode? = CGKeyCode(kVK_Space)

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init() {
        loadConfig()
        start()
        NotificationCenter.default.addObserver(self, selector: #selector(configChanged), name: UserDefaults.didChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stop()
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
        let key = defaults.string(forKey: "hotkey.key") ?? "space"
        updateConfig(required: parseModifiers(requiredRaw), forbidden: parseModifiers(forbiddenRaw), key: key)
    }

    private func parseModifiers(_ raw: String) -> CGEventFlags {
        var flags: CGEventFlags = []
        for part in raw.components(separatedBy: ",") {
            let trimmed = part.trimmingCharacters(in: .whitespaces).lowercased()
            switch trimmed {
            case "command", "cmd": flags.insert(.maskCommand)
            case "shift": flags.insert(.maskShift)
            case "option", "alt": flags.insert(.maskAlternate)
            case "control", "ctrl": flags.insert(.maskControl)
            case "capslock": flags.insert(.maskAlphaShift)
            default: break
            }
        }
        return flags
    }

    func start() {
        requestAccessibilityIfNeeded()

        guard eventTap == nil else { return }
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: HotkeyMonitor.eventTapCallback,
            userInfo: refcon
        ) else {
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        runLoopSource = nil
        eventTap = nil
    }

    func updateConfig(required: CGEventFlags, forbidden: CGEventFlags, key: String) {
        self.requiredModifiers = required
        self.forbiddenModifiers = forbidden
        let normalized = normalizeKeyString(key)
        self.keyCharacter = normalized.character
        self.keyCode = normalized.keyCode
        stop()
        start()
    }

    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, refcon in
        guard let refcon else { return Unmanaged.passUnretained(event) }
        let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(refcon).takeUnretainedValue()

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = monitor.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let handled = monitor.handle(event)
        return handled ? nil : Unmanaged.passUnretained(event)
    }

    private func handle(_ event: CGEvent) -> Bool {
        let flags = event.flags
        let hasRequired = flags.intersection(requiredModifiers) == requiredModifiers
        let hasForbidden = !flags.intersection(forbiddenModifiers).isEmpty

        guard hasRequired, !hasForbidden else { return false }
        if let keyCode {
            let eventKeyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            guard eventKeyCode == keyCode else { return false }
        } else {
            guard let nsEvent = NSEvent(cgEvent: event),
                  let chars = nsEvent.charactersIgnoringModifiers?.lowercased(),
                  chars == keyCharacter else { return false }
        }

        Task { @MainActor [weak transcriber] in
            transcriber?.toggleRecording()
        }
        return true
    }

    private func requestAccessibilityIfNeeded() {
        let options: CFDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as CFString: kCFBooleanTrue] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private func normalizeKeyString(_ raw: String) -> (character: String, keyCode: CGKeyCode?) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let keyCode = keyCodeForKeyString(trimmed) {
            return (trimmed, keyCode)
        }

        switch trimmed {
        case "space": return (" ", nil)
        case "tab": return ("\t", nil)
        case "return", "enter": return ("\r", nil)
        case "escape", "esc": return ("\u{1B}", nil)
        default: break
        }

        if trimmed.count == 1 {
            return (trimmed, nil)
        }
        return (trimmed, nil)
    }

    private func keyCodeForKeyString(_ key: String) -> CGKeyCode? {
        switch key {
        case "space": return CGKeyCode(kVK_Space)
        case "return", "enter": return CGKeyCode(kVK_Return)
        case "tab": return CGKeyCode(kVK_Tab)
        case "escape", "esc": return CGKeyCode(kVK_Escape)
        case "delete", "backspace": return CGKeyCode(kVK_Delete)
        case "forwarddelete": return CGKeyCode(kVK_ForwardDelete)
        case "left": return CGKeyCode(kVK_LeftArrow)
        case "right": return CGKeyCode(kVK_RightArrow)
        case "up": return CGKeyCode(kVK_UpArrow)
        case "down": return CGKeyCode(kVK_DownArrow)
        default: break
        }

        if key.count == 1, let scalar = key.unicodeScalars.first {
            switch scalar {
            case "a"..."z":
                return letterKeyCode(for: Character(scalar))
            case "0"..."9":
                return digitKeyCode(for: Character(scalar))
            default:
                break
            }
        }

        return nil
    }

    private func letterKeyCode(for char: Character) -> CGKeyCode? {
        switch char {
        case "a": return CGKeyCode(kVK_ANSI_A)
        case "b": return CGKeyCode(kVK_ANSI_B)
        case "c": return CGKeyCode(kVK_ANSI_C)
        case "d": return CGKeyCode(kVK_ANSI_D)
        case "e": return CGKeyCode(kVK_ANSI_E)
        case "f": return CGKeyCode(kVK_ANSI_F)
        case "g": return CGKeyCode(kVK_ANSI_G)
        case "h": return CGKeyCode(kVK_ANSI_H)
        case "i": return CGKeyCode(kVK_ANSI_I)
        case "j": return CGKeyCode(kVK_ANSI_J)
        case "k": return CGKeyCode(kVK_ANSI_K)
        case "l": return CGKeyCode(kVK_ANSI_L)
        case "m": return CGKeyCode(kVK_ANSI_M)
        case "n": return CGKeyCode(kVK_ANSI_N)
        case "o": return CGKeyCode(kVK_ANSI_O)
        case "p": return CGKeyCode(kVK_ANSI_P)
        case "q": return CGKeyCode(kVK_ANSI_Q)
        case "r": return CGKeyCode(kVK_ANSI_R)
        case "s": return CGKeyCode(kVK_ANSI_S)
        case "t": return CGKeyCode(kVK_ANSI_T)
        case "u": return CGKeyCode(kVK_ANSI_U)
        case "v": return CGKeyCode(kVK_ANSI_V)
        case "w": return CGKeyCode(kVK_ANSI_W)
        case "x": return CGKeyCode(kVK_ANSI_X)
        case "y": return CGKeyCode(kVK_ANSI_Y)
        case "z": return CGKeyCode(kVK_ANSI_Z)
        default: return nil
        }
    }

    private func digitKeyCode(for char: Character) -> CGKeyCode? {
        switch char {
        case "0": return CGKeyCode(kVK_ANSI_0)
        case "1": return CGKeyCode(kVK_ANSI_1)
        case "2": return CGKeyCode(kVK_ANSI_2)
        case "3": return CGKeyCode(kVK_ANSI_3)
        case "4": return CGKeyCode(kVK_ANSI_4)
        case "5": return CGKeyCode(kVK_ANSI_5)
        case "6": return CGKeyCode(kVK_ANSI_6)
        case "7": return CGKeyCode(kVK_ANSI_7)
        case "8": return CGKeyCode(kVK_ANSI_8)
        case "9": return CGKeyCode(kVK_ANSI_9)
        default: return nil
        }
    }
}
