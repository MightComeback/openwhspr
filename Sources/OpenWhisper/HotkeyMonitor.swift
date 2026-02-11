@preconcurrency import AppKit
@preconcurrency import ApplicationServices
import Carbon.HIToolbox
import CoreFoundation

final class HotkeyMonitor: @unchecked Sendable, ObservableObject {
    weak var transcriber: AudioTranscriber?

    @Published private(set) var isHotkeyActive: Bool = false
    @Published private(set) var statusMessage: String = "Not started"

    private let defaults: UserDefaults
    private let observesDefaults: Bool
    private var mode: HotkeyMode = .toggle
    private var requiredModifiers: CGEventFlags = [.maskCommand, .maskShift]
    private var forbiddenModifiers: CGEventFlags = [.maskAlternate, .maskControl]
    private var keyCharacter: String = " "
    private var keyCode: CGKeyCode? = CGKeyCode(kVK_Space)
    private var holdSessionArmed: Bool = false
    private var isListening: Bool = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(defaults: UserDefaults = .standard, startListening: Bool = true, observeDefaults: Bool = true) {
        self.defaults = defaults
        self.observesDefaults = observeDefaults

        // Load configuration without side effects.
        reloadConfig()

        if startListening {
            start()
        }

        if observeDefaults {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(configChanged),
                name: UserDefaults.didChangeNotification,
                object: nil
            )
        }
    }

    deinit {
        if observesDefaults {
            NotificationCenter.default.removeObserver(self)
        }
        stop()
    }

    func setTranscriber(_ transcriber: AudioTranscriber) {
        self.transcriber = transcriber
    }

    @objc private func configChanged() {
        reloadConfig()
    }

    func reloadConfig() {
        let required = parseModifierSettings(
            defaults: defaults,
            commandKey: AppDefaults.Keys.hotkeyRequiredCommand,
            shiftKey: AppDefaults.Keys.hotkeyRequiredShift,
            optionKey: AppDefaults.Keys.hotkeyRequiredOption,
            controlKey: AppDefaults.Keys.hotkeyRequiredControl,
            capsLockKey: AppDefaults.Keys.hotkeyRequiredCapsLock
        )

        var forbidden = parseModifierSettings(
            defaults: defaults,
            commandKey: AppDefaults.Keys.hotkeyForbiddenCommand,
            shiftKey: AppDefaults.Keys.hotkeyForbiddenShift,
            optionKey: AppDefaults.Keys.hotkeyForbiddenOption,
            controlKey: AppDefaults.Keys.hotkeyForbiddenControl,
            capsLockKey: AppDefaults.Keys.hotkeyForbiddenCapsLock
        )
        forbidden.subtract(required)

        let key = defaults.string(forKey: AppDefaults.Keys.hotkeyKey) ?? "space"
        let modeRaw = defaults.string(forKey: AppDefaults.Keys.hotkeyMode) ?? HotkeyMode.toggle.rawValue
        let parsedMode = HotkeyMode(rawValue: modeRaw) ?? .toggle

        updateConfig(required: required, forbidden: forbidden, key: key, mode: parsedMode)
    }

    private func parseModifierSettings(
        defaults: UserDefaults,
        commandKey: String,
        shiftKey: String,
        optionKey: String,
        controlKey: String,
        capsLockKey: String
    ) -> CGEventFlags {
        var flags: CGEventFlags = []
        if defaults.bool(forKey: commandKey) { flags.insert(.maskCommand) }
        if defaults.bool(forKey: shiftKey) { flags.insert(.maskShift) }
        if defaults.bool(forKey: optionKey) { flags.insert(.maskAlternate) }
        if defaults.bool(forKey: controlKey) { flags.insert(.maskControl) }
        if defaults.bool(forKey: capsLockKey) { flags.insert(.maskAlphaShift) }
        return flags
    }

    func start() {
        requestAccessibilityIfNeeded()
        requestInputMonitoringIfNeeded()

        let missingPermissions = Self.missingHotkeyPermissionNames()
        if !missingPermissions.isEmpty {
            let missingList = Self.humanList(missingPermissions)
            setStatus(active: false, message: "Hotkey disabled: missing \(missingList) permission")
            isListening = false
            return
        }

        guard eventTap == nil else {
            isListening = true
            setStatus(active: true, message: "Hotkey active")
            return
        }

        let mask = CGEventMask((1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue))

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: HotkeyMonitor.eventTapCallback,
            userInfo: refcon
        ) else {
            isListening = false
            setStatus(active: false, message: "Hotkey disabled: failed to create event tap")
            return
        }

        eventTap = tap
        isListening = true
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
        setStatus(active: true, message: "Hotkey active")
    }

    func stop() {
        isListening = false
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        runLoopSource = nil
        eventTap = nil
        holdSessionArmed = false

        setStatus(active: false, message: "Hotkey stopped")
    }

    func updateConfig(required: CGEventFlags, forbidden: CGEventFlags, key: String, mode: HotkeyMode) {
        self.requiredModifiers = required
        self.forbiddenModifiers = forbidden
        self.mode = mode

        let normalized = normalizeKeyString(key)
        self.keyCharacter = normalized.character
        self.keyCode = normalized.keyCode

        holdSessionArmed = false

        // Only restart the event tap if we're actively listening.
        if isListening {
            stop()
            start()
        }
    }

    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, refcon in
        guard let refcon else { return Unmanaged.passUnretained(event) }
        let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(refcon).takeUnretainedValue()

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            monitor.holdSessionArmed = false
            Task { @MainActor [weak transcriber = monitor.transcriber] in
                transcriber?.stopRecordingFromHotkey()
            }

            monitor.setStatus(active: false, message: "Hotkey temporarily disabled by the system; attempting to re-enable")

            if let tap = monitor.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
                monitor.setStatus(active: true, message: "Hotkey active")
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }

        let handled = monitor.handle(event, type: type)
        return handled ? nil : Unmanaged.passUnretained(event)
    }

    private func handle(_ event: CGEvent, type: CGEventType) -> Bool {
        if let keyCode {
            let eventKeyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            guard eventKeyCode == keyCode else { return false }
        } else {
            guard let nsEvent = NSEvent(cgEvent: event),
                  let chars = nsEvent.charactersIgnoringModifiers?.lowercased(),
                  chars == keyCharacter else { return false }
        }

        let flags = event.flags
        let hasRequired = flags.intersection(requiredModifiers) == requiredModifiers
        let hasForbidden = !flags.intersection(forbiddenModifiers).isEmpty
        let comboMatches = hasRequired && !hasForbidden

        switch mode {
        case .toggle:
            guard type == .keyDown, comboMatches else { return false }

            // Prevent key repeat from rapidly toggling recording while the hotkey is held.
            let isAutoRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            if isAutoRepeat {
                return true
            }

            Task { @MainActor [weak transcriber] in
                transcriber?.toggleRecording()
            }
            return true

        case .hold:
            if type == .keyDown {
                guard comboMatches else { return false }
                if !holdSessionArmed {
                    holdSessionArmed = true
                    Task { @MainActor [weak transcriber] in
                        transcriber?.startRecordingFromHotkey()
                    }
                }
                return true
            }

            if holdSessionArmed {
                holdSessionArmed = false
                Task { @MainActor [weak transcriber] in
                    transcriber?.stopRecordingFromHotkey()
                }
                return true
            }

            return false
        }
    }

    func handleForTesting(_ event: CGEvent, type: CGEventType) -> Bool {
        handle(event, type: type)
    }

    var holdSessionArmedForTesting: Bool {
        holdSessionArmed
    }

    private func setStatus(active: Bool, message: String) {
        if Thread.isMainThread {
            isHotkeyActive = active
            statusMessage = message
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isHotkeyActive = active
            self.statusMessage = message
        }
    }

    private func requestAccessibilityIfNeeded() {
        guard !Self.hasAccessibilityPermission() else { return }
        let options: CFDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as CFString: kCFBooleanTrue
        ] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private func requestInputMonitoringIfNeeded() {
        guard !Self.hasInputMonitoringPermission() else { return }
        _ = CGRequestListenEventAccess()
    }

    static func hasAccessibilityPermission() -> Bool {
        AXIsProcessTrusted()
    }

    static func requestAccessibilityPermissionPrompt() {
        let options: CFDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as CFString: kCFBooleanTrue
        ] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static func hasInputMonitoringPermission() -> Bool {
        CGPreflightListenEventAccess()
    }

    static func requestInputMonitoringPermissionPrompt() {
        _ = CGRequestListenEventAccess()
    }

    private static func missingHotkeyPermissionNames() -> [String] {
        var missing: [String] = []
        if !hasAccessibilityPermission() { missing.append("Accessibility") }
        if !hasInputMonitoringPermission() { missing.append("Input Monitoring") }
        return missing
    }

    private static func humanList(_ items: [String]) -> String {
        switch items.count {
        case 0:
            return ""
        case 1:
            return items[0]
        case 2:
            return "\(items[0]) and \(items[1])"
        default:
            let head = items.dropLast().joined(separator: ", ")
            return "\(head), and \(items[items.count - 1])"
        }
    }

    private func normalizeKeyString(_ raw: String) -> (character: String, keyCode: CGKeyCode?) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let keyCode = keyCodeForKeyString(trimmed) {
            return (trimmed, keyCode)
        }

        switch trimmed {
        case "space", "spacebar": return (" ", nil)
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
        case "space", "spacebar": return CGKeyCode(kVK_Space)
        case "return", "enter": return CGKeyCode(kVK_Return)
        case "tab": return CGKeyCode(kVK_Tab)
        case "escape", "esc": return CGKeyCode(kVK_Escape)
        case "delete", "backspace": return CGKeyCode(kVK_Delete)
        case "forwarddelete": return CGKeyCode(kVK_ForwardDelete)
        case "left": return CGKeyCode(kVK_LeftArrow)
        case "right": return CGKeyCode(kVK_RightArrow)
        case "up": return CGKeyCode(kVK_UpArrow)
        case "down": return CGKeyCode(kVK_DownArrow)
        case "home": return CGKeyCode(kVK_Home)
        case "end": return CGKeyCode(kVK_End)
        case "pageup", "pgup": return CGKeyCode(kVK_PageUp)
        case "pagedown", "pgdn": return CGKeyCode(kVK_PageDown)
        case "f1": return CGKeyCode(kVK_F1)
        case "f2": return CGKeyCode(kVK_F2)
        case "f3": return CGKeyCode(kVK_F3)
        case "f4": return CGKeyCode(kVK_F4)
        case "f5": return CGKeyCode(kVK_F5)
        case "f6": return CGKeyCode(kVK_F6)
        case "f7": return CGKeyCode(kVK_F7)
        case "f8": return CGKeyCode(kVK_F8)
        case "f9": return CGKeyCode(kVK_F9)
        case "f10": return CGKeyCode(kVK_F10)
        case "f11": return CGKeyCode(kVK_F11)
        case "f12": return CGKeyCode(kVK_F12)
        case "f13": return CGKeyCode(kVK_F13)
        case "f14": return CGKeyCode(kVK_F14)
        case "f15": return CGKeyCode(kVK_F15)
        case "f16": return CGKeyCode(kVK_F16)
        case "f17": return CGKeyCode(kVK_F17)
        case "f18": return CGKeyCode(kVK_F18)
        case "f19": return CGKeyCode(kVK_F19)
        case "f20": return CGKeyCode(kVK_F20)
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
