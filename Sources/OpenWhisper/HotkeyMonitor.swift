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
    private var triggerKeyToken: String = "space"
    private var hasValidTriggerKey: Bool = true
    private var invalidTriggerKeyInput: String? = nil
    private var holdSessionArmed: Bool = false
    private var toggleKeyDownConsumed: Bool = false
    private var isListening: Bool = false
    private var comboMismatchResetTask: Task<Void, Never>? = nil

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

        guard hasValidTriggerKey else {
            setStatus(active: false, message: unsupportedTriggerKeyMessage())
            isListening = false
            return
        }

        guard hasSafeModifierConfig() else {
            setStatus(active: false, message: unsafeModifierConfigurationMessage())
            isListening = false
            return
        }

        let missingPermissions = Self.missingHotkeyPermissionNames()
        if !missingPermissions.isEmpty {
            setStatus(active: false, message: missingPermissionStatusMessage(missingPermissions))
            isListening = false
            return
        }

        guard eventTap == nil else {
            isListening = true
            setStatus(active: true, message: standbyStatusMessage())
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
        setStatus(active: true, message: standbyStatusMessage())
    }

    func stop() {
        isListening = false
        comboMismatchResetTask?.cancel()
        comboMismatchResetTask = nil
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
        toggleKeyDownConsumed = false

        setStatus(active: false, message: "Hotkey stopped")
    }

    func updateConfig(required: CGEventFlags, forbidden: CGEventFlags, key: String, mode: HotkeyMode) {
        self.requiredModifiers = required
        self.forbiddenModifiers = forbidden
        self.mode = mode

        let normalized = normalizeKeyString(key)
        self.keyCharacter = normalized.character
        self.keyCode = normalized.keyCode
        self.triggerKeyToken = normalized.token
        self.hasValidTriggerKey = normalized.isValid
        self.invalidTriggerKeyInput = normalized.isValid ? nil : key

        holdSessionArmed = false
        toggleKeyDownConsumed = false
        comboMismatchResetTask?.cancel()
        comboMismatchResetTask = nil

        if !normalized.isValid {
            if isListening {
                stop()
            }
            setStatus(active: false, message: unsupportedTriggerKeyMessage())
            return
        }

        if !hasSafeModifierConfig() {
            if isListening {
                stop()
            }
            setStatus(active: false, message: unsafeModifierConfigurationMessage())
            return
        }

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
            monitor.toggleKeyDownConsumed = false
            Task { @MainActor [weak transcriber = monitor.transcriber] in
                transcriber?.stopRecordingFromHotkey()
            }

            monitor.setStatus(active: false, message: "Hotkey temporarily disabled by the system; attempting to re-enable")

            if let tap = monitor.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
                monitor.setStatus(active: true, message: monitor.standbyStatusMessage())
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
            if type == .keyUp {
                if toggleKeyDownConsumed {
                    toggleKeyDownConsumed = false
                    return true
                }
                return false
            }

            // Edge-trigger behavior: once we handle a key down, ignore further
            // key-down events for that trigger until key up arrives. This keeps
            // recording stable on hardware/layouts that may emit repeated key
            // down events without a reliable auto-repeat flag.
            if toggleKeyDownConsumed {
                return true
            }

            guard comboMatches else {
                showComboMismatchHintIfNeeded(type: type, flags: flags)
                return false
            }

            // Prevent key repeat from rapidly toggling recording while the hotkey is held.
            let isAutoRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            if isAutoRepeat {
                return true
            }

            toggleKeyDownConsumed = true
            Task { @MainActor [weak self, weak transcriber] in
                transcriber?.toggleRecording()
                guard let self else { return }
                self.setStatus(active: true, message: self.toggleFeedbackMessage(transcriber: transcriber))
            }
            return true

        case .hold:
            if type == .keyDown {
                guard comboMatches else {
                    showComboMismatchHintIfNeeded(type: type, flags: flags)
                    return false
                }
                if !holdSessionArmed {
                    holdSessionArmed = true
                    setStatus(active: true, message: holdActiveStatusMessage())
                    Task { @MainActor [weak transcriber] in
                        transcriber?.startRecordingFromHotkey()
                    }
                }
                return true
            }

            if holdSessionArmed {
                holdSessionArmed = false
                setStatus(active: true, message: standbyStatusMessage())
                Task { @MainActor [weak transcriber] in
                    if transcriber?.cancelQueuedStartAfterFinalizeFromHotkey() == true {
                        return
                    }
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

    func refreshStatusFromRuntimeState() {
        guard isListening else { return }

        if mode == .hold, holdSessionArmed {
            setStatus(active: true, message: holdActiveStatusMessage())
            return
        }

        setStatus(active: true, message: standbyStatusMessage())
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

    private func currentComboSummary() -> String {
        HotkeyDisplay.summaryIncludingMode(defaults: defaults)
    }

    private func standbyStatusMessage() -> String {
        if mode == .toggle {
            if let transcriber, !transcriber.isRecording, transcriber.pendingChunkCount > 0 {
                if transcriber.isStartAfterFinalizeQueued {
                    return "Hotkey active (\(currentComboSummary())) — next recording queued"
                }
                return "Hotkey active (\(currentComboSummary())) — finalizing previous recording"
            }
            return toggleStatusMessage(isRecording: transcriber?.isRecording ?? false)
        }
        return "Hotkey active (\(currentComboSummary())) — hold to record"
    }

    private func toggleStatusMessage(isRecording: Bool) -> String {
        let combo = currentComboSummary()
        if isRecording {
            return "Hotkey active (\(combo)) — press again to stop"
        }
        return "Hotkey active (\(combo)) — press to record"
    }

    private func toggleFeedbackMessage(transcriber: AudioTranscriber?) -> String {
        guard let transcriber else {
            return toggleStatusMessage(isRecording: false)
        }

        if !transcriber.isRecording, transcriber.pendingChunkCount > 0 {
            if transcriber.isStartAfterFinalizeQueued {
                return "Hotkey active (\(currentComboSummary())) — next recording queued"
            }
            return "Hotkey active (\(currentComboSummary())) — finalizing previous recording"
        }

        return toggleStatusMessage(isRecording: transcriber.isRecording)
    }

    private func showComboMismatchHintIfNeeded(type: CGEventType, flags: CGEventFlags) {
        guard type == .keyDown else { return }

        comboMismatchResetTask?.cancel()
        let priorStatus = statusMessage

        let expectedCombo = currentComboSummary()
        let pressedModifiers = modifierGlyphSummary(from: flags)
        let mismatchMessage: String
        if pressedModifiers.isEmpty {
            mismatchMessage = "Hotkey not triggered: no modifiers held. Use \(expectedCombo)"
        } else {
            mismatchMessage = "Hotkey not triggered: held \(pressedModifiers). Use \(expectedCombo)"
        }

        setStatus(active: isHotkeyActive, message: mismatchMessage)

        guard isListening else { return }

        comboMismatchResetTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard let self, !Task.isCancelled else { return }

            if self.statusMessage == mismatchMessage {
                self.setStatus(active: self.isHotkeyActive, message: priorStatus)
            }
        }
    }

    private func modifierGlyphSummary(from flags: CGEventFlags) -> String {
        var glyphs: [String] = []
        if flags.contains(.maskCommand) { glyphs.append("⌘") }
        if flags.contains(.maskShift) { glyphs.append("⇧") }
        if flags.contains(.maskAlternate) { glyphs.append("⌥") }
        if flags.contains(.maskControl) { glyphs.append("⌃") }
        if flags.contains(.maskAlphaShift) { glyphs.append("⇪") }
        return glyphs.joined(separator: "+")
    }

    private func holdActiveStatusMessage() -> String {
        "Hold active: recording while pressed (\(currentComboSummary()))"
    }

    private func unsupportedTriggerKeyMessage() -> String {
        if let invalidTriggerKeyInput {
            let trimmed = invalidTriggerKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return "Hotkey disabled: trigger key is empty. Enter one key like space, f6, or /."
            }
            if looksLikeModifierOnlyInput(trimmed) {
                return "Hotkey disabled: trigger key cannot be only a modifier ‘\(trimmed)’. Choose one key like space or f6, then set modifiers with the toggles above."
            }
            if looksLikeShortcutCombo(trimmed) {
                return "Hotkey disabled: key field expects one trigger key (like space or f6), not a full shortcut ‘\(trimmed)’. Set modifiers with the toggles above."
            }
            return "Hotkey disabled: unsupported trigger key ‘\(trimmed)’. Use one key like space, f6, or /."
        }
        return "Hotkey disabled: unsupported trigger key. Use one key like space, f6, or /."
    }

    private func hasSafeModifierConfig() -> Bool {
        if !requiredModifiers.isEmpty {
            return true
        }
        return allowsNoModifierTrigger(triggerKeyToken)
    }

    private func unsafeModifierConfigurationMessage() -> String {
        "Hotkey disabled: add at least one required modifier for this trigger key to avoid accidental activation while typing."
    }

    private func allowsNoModifierTrigger(_ key: String) -> Bool {
        let normalized = key.lowercased()

        if normalized.hasPrefix("f"), let functionIndex = Int(normalized.dropFirst()) {
            return (1...24).contains(functionIndex)
        }

        switch normalized {
        case "escape", "tab", "return", "space", "left", "right", "up", "down", "home", "end", "pageup", "pagedown":
            return true
        default:
            return false
        }
    }

    private func looksLikeShortcutCombo(_ raw: String) -> Bool {
        let normalized = raw.lowercased()
        if normalized.contains("+") {
            return true
        }

        let tokens = expandedShortcutTokens(from: normalized)
        let modifierWords = shortcutModifierWords()
        let modifierCount = tokens.filter { modifierWords.contains($0) }.count
        return modifierCount >= 1 && tokens.count >= 2
    }

    private func looksLikeModifierOnlyInput(_ raw: String) -> Bool {
        let tokens = expandedShortcutTokens(from: raw.lowercased())
        guard !tokens.isEmpty else { return false }
        let modifierWords = shortcutModifierWords()
        return tokens.allSatisfy { modifierWords.contains($0) }
    }

    private func expandedShortcutTokens(from raw: String) -> [String] {
        let expanded = raw
            .replacingOccurrences(of: "⌘", with: " command ")
            .replacingOccurrences(of: "⇧", with: " shift ")
            .replacingOccurrences(of: "⌃", with: " control ")
            .replacingOccurrences(of: "⌥", with: " option ")
            .replacingOccurrences(of: "🌐", with: " globe ")

        return expanded
            .replacingOccurrences(of: "-", with: " ")
            .split(whereSeparator: { $0.isWhitespace || $0 == "+" || $0 == "," })
            .map(String.init)
    }

    private func shortcutModifierWords() -> Set<String> {
        [
            "cmd", "command", "meta", "super", "win", "windows",
            "shift",
            "ctrl", "control",
            "opt", "option", "alt",
            "fn", "function", "globe"
        ]
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

    func missingPermissionStatusMessage(_ missingPermissions: [String]) -> String {
        let missingList = Self.humanList(missingPermissions)
        if missingPermissions.count == 1, let permission = missingPermissions.first {
            return "Hotkey disabled: missing \(permission) permission. Open System Settings → Privacy & Security → \(permission) and enable OpenWhisper."
        }
        return "Hotkey disabled: missing \(missingList) permission. Open System Settings → Privacy & Security and enable OpenWhisper in both sections."
    }

    private func normalizeKeyString(_ raw: String) -> (character: String, keyCode: CGKeyCode?, token: String, isValid: Bool) {
        let normalized = normalizeNamedKey(raw)
        if let keyCode = keyCodeForKeyString(normalized) {
            return (normalized, keyCode, normalized, true)
        }

        switch normalized {
        case "space", "spacebar": return (" ", nil, "space", true)
        case "tab": return ("\t", nil, "tab", true)
        case "return", "enter": return ("\r", nil, "return", true)
        case "escape", "esc": return ("\u{1B}", nil, "escape", true)
        default: break
        }

        if normalized.count == 1 {
            return (normalized, nil, normalized, true)
        }
        return (normalized, nil, normalized, false)
    }

    private func normalizeNamedKey(_ raw: String) -> String {
        HotkeyDisplay.canonicalKey(raw)
    }

    private func keyCodeForKeyString(_ key: String) -> CGKeyCode? {
        switch key {
        case "space", "spacebar": return CGKeyCode(kVK_Space)
        case "return", "enter": return CGKeyCode(kVK_Return)
        case "tab": return CGKeyCode(kVK_Tab)
        case "escape", "esc": return CGKeyCode(kVK_Escape)
        case "delete", "del", "backspace", "bksp": return CGKeyCode(kVK_Delete)
        case "forwarddelete", "fwddelete", "fwddel": return CGKeyCode(kVK_ForwardDelete)
        case "insert", "ins", "help": return CGKeyCode(kVK_Help)
        case "caps", "capslock": return CGKeyCode(kVK_CapsLock)
        case "fn", "function", "globe", "globekey": return CGKeyCode(kVK_Function)
        case "-", "minus", "hyphen", "_": return CGKeyCode(kVK_ANSI_Minus)
        case "=", "equals", "equal", "plus", "+": return CGKeyCode(kVK_ANSI_Equal)
        case "[", "openbracket", "leftbracket", "{": return CGKeyCode(kVK_ANSI_LeftBracket)
        case "]", "closebracket", "rightbracket", "}": return CGKeyCode(kVK_ANSI_RightBracket)
        case ";", "semicolon", ":": return CGKeyCode(kVK_ANSI_Semicolon)
        case "'", "apostrophe", "quote", "\"": return CGKeyCode(kVK_ANSI_Quote)
        case ",", "comma", "<": return CGKeyCode(kVK_ANSI_Comma)
        case ".", "period", "dot", ">": return CGKeyCode(kVK_ANSI_Period)
        case "/", "slash", "forwardslash", "?": return CGKeyCode(kVK_ANSI_Slash)
        case "\\", "backslash", "|": return CGKeyCode(kVK_ANSI_Backslash)
        case "`", "grave", "backtick", "~": return CGKeyCode(kVK_ANSI_Grave)
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
        // Carbon doesn't expose kVK_F21...kVK_F24 in all SDKs. Use stable
        // virtual keycode values from Events.h for extended function keys.
        case "f21": return CGKeyCode(0x6E)
        case "f22": return CGKeyCode(0x6F)
        case "f23": return CGKeyCode(0x70)
        case "f24": return CGKeyCode(0x71)
        case "keypad0", "numpad0": return CGKeyCode(kVK_ANSI_Keypad0)
        case "keypad1", "numpad1": return CGKeyCode(kVK_ANSI_Keypad1)
        case "keypad2", "numpad2": return CGKeyCode(kVK_ANSI_Keypad2)
        case "keypad3", "numpad3": return CGKeyCode(kVK_ANSI_Keypad3)
        case "keypad4", "numpad4": return CGKeyCode(kVK_ANSI_Keypad4)
        case "keypad5", "numpad5": return CGKeyCode(kVK_ANSI_Keypad5)
        case "keypad6", "numpad6": return CGKeyCode(kVK_ANSI_Keypad6)
        case "keypad7", "numpad7": return CGKeyCode(kVK_ANSI_Keypad7)
        case "keypad8", "numpad8": return CGKeyCode(kVK_ANSI_Keypad8)
        case "keypad9", "numpad9": return CGKeyCode(kVK_ANSI_Keypad9)
        case "keypaddecimal", "numpaddecimal": return CGKeyCode(kVK_ANSI_KeypadDecimal)
        case "keypadmultiply", "numpadmultiply": return CGKeyCode(kVK_ANSI_KeypadMultiply)
        case "keypadplus", "numpadplus": return CGKeyCode(kVK_ANSI_KeypadPlus)
        case "keypadclear", "numpadclear": return CGKeyCode(kVK_ANSI_KeypadClear)
        case "keypaddivide", "numpaddivide": return CGKeyCode(kVK_ANSI_KeypadDivide)
        case "keypadenter", "numpadenter": return CGKeyCode(kVK_ANSI_KeypadEnter)
        case "keypadminus", "numpadminus": return CGKeyCode(kVK_ANSI_KeypadMinus)
        case "keypadequals", "numpadequals": return CGKeyCode(kVK_ANSI_KeypadEquals)
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
