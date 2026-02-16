// ViewHelpers.swift
// OpenWhisper
//
// Pure utility functions extracted from ContentView / SettingsView for testability.

import Foundation

/// Pure helper functions used by views, extracted for testability.
enum ViewHelpers {

    // MARK: - Duration formatting

    /// Formats a duration in seconds as "H:MM:SS" or "M:SS".
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let remainder = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainder)
        }

        return String(format: "%d:%02d", minutes, remainder)
    }

    /// Formats a duration as compact "Xs" or "Xm Ys".
    static func formatShortDuration(_ seconds: TimeInterval) -> String {
        let rounded = Int(max(0, seconds.rounded()))
        if rounded < 60 {
            return "\(rounded)s"
        }

        let minutes = rounded / 60
        let remainder = rounded % 60
        return "\(minutes)m \(remainder)s"
    }

    // MARK: - App name abbreviation

    /// Abbreviates an app name to `maxCharacters`, appending "…" if truncated.
    static func abbreviatedAppName(_ name: String, maxCharacters: Int = 18) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxCharacters else { return trimmed }

        let prefixLength = max(1, maxCharacters - 1)
        let endIndex = trimmed.index(trimmed.startIndex, offsetBy: prefixLength)
        return String(trimmed[..<endIndex]) + "…"
    }

    // MARK: - Byte formatting

    /// Formats byte counts using ByteCountFormatter (MB/KB).
    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - History entry stats

    /// Returns a compact stats string like "12w · 45s" for a transcription entry.
    static func historyEntryStats(text: String, durationSeconds: Double?) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = trimmed.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).count
        var parts = ["\(words)w"]
        if let duration = durationSeconds, duration > 0 {
            let total = Int(duration.rounded())
            if total < 60 {
                parts.append("\(total)s")
            } else {
                let minutes = total / 60
                let seconds = total % 60
                parts.append(String(format: "%d:%02d", minutes, seconds))
            }
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Status title

    /// Computes the status title for the menu bar popover.
    static func statusTitle(isRecording: Bool, recordingDuration: TimeInterval, pendingChunkCount: Int) -> String {
        if isRecording {
            if recordingDuration >= 1 {
                return "Recording • \(formatDuration(recordingDuration))"
            }
            return "Recording"
        }
        if pendingChunkCount > 0 {
            return "Finalizing • \(pendingChunkCount) chunk\(pendingChunkCount == 1 ? "" : "s")"
        }
        return "Ready"
    }

    // MARK: - Finalization progress

    /// Computes finalization progress as a fraction [0, 1], or nil if not finalizing.
    static func finalizationProgress(pendingChunkCount: Int, initialPendingChunks: Int?, isRecording: Bool) -> Double? {
        guard !isRecording,
              pendingChunkCount > 0,
              let initialPending = initialPendingChunks,
              initialPending > 0 else {
            return nil
        }

        let completed = max(0, initialPending - pendingChunkCount)
        let rawProgress = Double(completed) / Double(initialPending)
        return min(max(rawProgress, 0), 1)
    }

    // MARK: - Hotkey parsing (from SettingsView)

    /// Parsed modifier flags for hotkey combos.
    enum ParsedModifier: Hashable {
        case command
        case shift
        case option
        case control
        case capsLock
    }

    /// Result of parsing a hotkey draft string.
    struct ParsedHotkeyDraft: Equatable {
        var key: String
        var requiredModifiers: Set<ParsedModifier>?
        var containsNonConfigurableModifiers: Bool
    }

    /// Parses a hotkey draft string into key + modifiers.
    static func parseHotkeyDraft(_ raw: String) -> ParsedHotkeyDraft? {
        let loweredRaw = raw.lowercased()
        if loweredRaw == " " {
            return ParsedHotkeyDraft(key: "space", requiredModifiers: nil, containsNonConfigurableModifiers: false)
        }

        let normalized = loweredRaw
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else {
            return nil
        }

        let normalizedAsWholeKey = HotkeyDisplay.canonicalKey(normalized)
        if !looksLikeModifierComboInput(normalized),
           HotkeyDisplay.isSupportedKey(normalizedAsWholeKey) {
            return ParsedHotkeyDraft(key: normalizedAsWholeKey, requiredModifiers: nil, containsNonConfigurableModifiers: false)
        }

        if normalized.contains("+") || normalized.contains(",") {
            let tokens = splitPlusCommaHotkeyTokens(normalized)
            return parseHotkeyTokens(tokens)
        }

        if normalized.contains("/"), !normalized.hasSuffix("/") {
            let tokens = normalized
                .split(separator: "/")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            if tokens.contains(where: { parseModifierToken($0) != nil }) {
                return parseHotkeyTokens(tokens)
            }
        }

        if normalized.contains(" ") {
            let tokens = normalized
                .split(whereSeparator: { $0.isWhitespace })
                .map(String.init)
                .filter { !$0.isEmpty }

            if tokens.contains(where: { parseModifierToken($0) != nil }) {
                if let parsed = parseHotkeyTokens(tokens) {
                    return parsed
                }

                let mergedTokens = mergeSpaceSeparatedKeyTokens(tokens)
                if mergedTokens != tokens {
                    return parseHotkeyTokens(mergedTokens)
                }
            }
        }

        if normalized.contains("-") {
            let tokens = normalized
                .split(separator: "-")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            if tokens.contains(where: { parseModifierToken($0) != nil }) {
                return parseHotkeyTokens(tokens)
            }
        }

        if normalized.contains(where: { $0 == "+" || $0 == "-" || $0 == "_" || $0 == "," || $0 == "/" || $0.isWhitespace }) {
            let tokens = normalized
                .components(separatedBy: CharacterSet(charactersIn: "+-_,/ "))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            if tokens.contains(where: { parseModifierToken($0) != nil }) {
                if let parsed = parseHotkeyTokens(tokens) {
                    return parsed
                }

                let mergedTokens = mergeSpaceSeparatedKeyTokens(tokens)
                if mergedTokens != tokens {
                    return parseHotkeyTokens(mergedTokens)
                }
            }
        }

        let expandedCompactTokens = expandCompactModifierToken(normalized)
        if expandedCompactTokens.count > 1,
           expandedCompactTokens.contains(where: { parseModifierToken($0) != nil }) {
            return parseHotkeyTokens(expandedCompactTokens)
        }

        return ParsedHotkeyDraft(key: normalized, requiredModifiers: nil, containsNonConfigurableModifiers: false)
    }

    /// Checks if a string looks like a modifier+key combo (contains modifier symbols or tokens).
    static func looksLikeModifierComboInput(_ raw: String) -> Bool {
        if raw.contains("⌘") || raw.contains("⇧") || raw.contains("⌥") || raw.contains("⌃") || raw.contains("⇪") {
            return true
        }

        let tokens = raw
            .components(separatedBy: CharacterSet(charactersIn: "+-_,/ "))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return tokens.contains { parseModifierToken($0) != nil }
    }

    /// Splits a hotkey string by `+` or `,`, handling trailing plus/comma as literal keys.
    static func splitPlusCommaHotkeyTokens(_ raw: String) -> [String] {
        var tokens = raw
            .split(whereSeparator: { $0 == "+" || $0 == "," })
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if raw.hasSuffix("+") {
            tokens.append("plus")
        } else if raw.hasSuffix(",") {
            tokens.append("comma")
        }

        return tokens
    }

    /// Merges trailing non-modifier tokens into a single key (e.g. "page down" → "page down").
    static func mergeSpaceSeparatedKeyTokens(_ tokens: [String]) -> [String] {
        guard !tokens.isEmpty else {
            return tokens
        }

        guard let firstNonModifierIndex = tokens.firstIndex(where: { parseModifierToken($0) == nil }) else {
            return tokens
        }

        guard firstNonModifierIndex < tokens.count - 1 else {
            return tokens
        }

        let trailingTokens = Array(tokens[(firstNonModifierIndex + 1)...])
        if trailingTokens.contains(where: { parseModifierToken($0) != nil }) {
            return tokens
        }

        let mergedKey = tokens[firstNonModifierIndex...].joined(separator: " ")
        var merged = Array(tokens[..<firstNonModifierIndex])
        merged.append(mergedKey)
        return merged
    }

    /// Parses modifier token to a `ParsedModifier`, or nil if not a modifier.
    static func parseModifierToken(_ token: String) -> ParsedModifier? {
        switch token {
        case "cmd", "command", "meta", "super", "win", "windows", "commandorcontrol", "controlorcommand", "cmdorctrl", "ctrlorcmd", "⌘", "@": return .command
        case "shift", "⇧", "$": return .shift
        case "opt", "option", "alt", "⌥", "~": return .option
        case "ctrl", "control", "ctl", "⌃", "^": return .control
        case "caps", "capslock", "⇪": return .capsLock
        default: return nil
        }
    }

    /// Whether a token is a non-configurable modifier (fn/globe).
    static func isNonConfigurableModifierToken(_ token: String) -> Bool {
        switch token {
        case "fn", "function", "globe", "globekey", "🌐":
            return true
        default:
            return false
        }
    }

    /// Expands compact modifier+key strings like "⌘⇧space" into ["cmd", "shift", "space"].
    static func expandCompactModifierToken(_ token: String) -> [String] {
        let normalized = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return []
        }

        var remainder = normalized
        var expanded: [String] = []

        let modifierPrefixes: [(symbol: String, token: String)] = [
            ("⌘", "cmd"),
            ("@", "cmd"),
            ("⇧", "shift"),
            ("$", "shift"),
            ("⌥", "opt"),
            ("~", "opt"),
            ("⌃", "ctrl"),
            ("^", "ctrl"),
            ("⇪", "caps"),
            ("🌐", "globe")
        ]

        while remainder.count > 1 {
            var matchedPrefix = false

            for prefix in modifierPrefixes {
                if remainder.hasPrefix(prefix.symbol) {
                    expanded.append(prefix.token)
                    remainder.removeFirst(prefix.symbol.count)
                    matchedPrefix = true
                    break
                }
            }

            if !matchedPrefix {
                break
            }
        }

        if !remainder.isEmpty {
            expanded.append(remainder)
        }

        return expanded
    }

    /// Parses a list of tokens into a `ParsedHotkeyDraft`.
    static func parseHotkeyTokens(_ tokens: [String]) -> ParsedHotkeyDraft? {
        guard !tokens.isEmpty else {
            return nil
        }

        var modifiers = Set<ParsedModifier>()
        var keyToken: String?
        var sawConfigurableModifier = false
        var sawNonConfigurableModifier = false

        for token in tokens {
            let expandedTokens = expandCompactModifierToken(token)

            for expandedToken in expandedTokens {
                if let modifier = parseModifierToken(expandedToken) {
                    modifiers.insert(modifier)
                    sawConfigurableModifier = true
                    continue
                }

                if isNonConfigurableModifierToken(expandedToken) {
                    sawNonConfigurableModifier = true
                    continue
                }

                if keyToken != nil {
                    return nil
                }
                keyToken = expandedToken
            }
        }

        guard let keyToken else {
            return nil
        }

        let parsedRequiredModifiers: Set<ParsedModifier>? =
            (sawConfigurableModifier || !sawNonConfigurableModifier) ? modifiers : nil

        return ParsedHotkeyDraft(
            key: keyToken,
            requiredModifiers: parsedRequiredModifiers,
            containsNonConfigurableModifiers: sawNonConfigurableModifier
        )
    }

    // MARK: - Insert action disabled reason

    /// Returns the reason the insert action is disabled, or nil if it can proceed.
    static func insertActionDisabledReason(
        hasTranscriptionText: Bool,
        isRunningInsertionProbe: Bool,
        isRecording: Bool,
        pendingChunkCount: Int
    ) -> String? {
        if !hasTranscriptionText {
            return "No transcription to insert yet"
        }
        if isRunningInsertionProbe {
            return "Wait for the insertion probe to finish"
        }
        if isRecording || pendingChunkCount > 0 {
            return "Stop recording and wait for pending chunks"
        }
        return nil
    }

    // MARK: - Start/Stop button

    /// Returns the start/stop button title.
    static func startStopButtonTitle(
        isRecording: Bool,
        pendingChunkCount: Int,
        isStartAfterFinalizeQueued: Bool
    ) -> String {
        if isRecording { return "Stop" }
        if pendingChunkCount > 0 {
            return isStartAfterFinalizeQueued ? "Cancel queued start" : "Queue start"
        }
        return "Start"
    }

    /// Returns the start/stop button help text.
    static func startStopButtonHelpText(
        isRecording: Bool,
        pendingChunkCount: Int,
        isStartAfterFinalizeQueued: Bool,
        microphoneAuthorized: Bool
    ) -> String {
        if isRecording { return "Stop recording" }
        if pendingChunkCount > 0 {
            if isStartAfterFinalizeQueued {
                return "Cancel queued recording start while finalization finishes"
            }
            return "Queue the next recording to start after finalization"
        }
        if !microphoneAuthorized {
            return "Microphone permission is required before recording can start"
        }
        return "Start recording"
    }

    // MARK: - Estimated finalization

    /// Estimates seconds remaining for finalization.
    static func estimatedFinalizationSeconds(
        pendingChunkCount: Int,
        averageChunkLatency: Double,
        lastChunkLatency: Double
    ) -> TimeInterval? {
        guard pendingChunkCount > 0 else { return nil }
        let latency = averageChunkLatency > 0 ? averageChunkLatency : lastChunkLatency
        guard latency > 0 else { return nil }
        return Double(pendingChunkCount) * latency
    }

    // MARK: - Live loop lag notice

    /// Returns a lag notice string if the live loop is falling behind, else nil.
    static func liveLoopLagNotice(
        pendingChunkCount: Int,
        estimatedFinalizationSeconds: TimeInterval?
    ) -> String? {
        let lagWarningThresholdSeconds: TimeInterval = 6

        if let remaining = estimatedFinalizationSeconds,
           remaining >= lagWarningThresholdSeconds {
            return "Live loop is falling behind (~\(formatShortDuration(remaining)) queued). Pause briefly to let transcription catch up."
        }

        guard pendingChunkCount >= 3 else { return nil }

        return "Live loop is falling behind (\(pendingChunkCount) chunks queued). Pause briefly to let transcription catch up."
    }

    // MARK: - Insert target age description

    /// Returns a human-readable description of how old the insert target is.
    static func insertTargetAgeDescription(
        capturedAt: Date?,
        now: Date,
        staleAfterSeconds: TimeInterval,
        isStale: Bool
    ) -> String? {
        guard let capturedAt else { return nil }

        let elapsed = max(0, now.timeIntervalSince(capturedAt))
        let remaining = max(0, staleAfterSeconds - elapsed)

        let ageLabel: String
        if elapsed < 1 {
            ageLabel = "just now"
        } else {
            ageLabel = "\(formatShortDuration(elapsed)) ago"
        }

        if isStale {
            return "Target captured \(ageLabel) • stale"
        }

        if remaining <= 10 {
            return "Target captured \(ageLabel) • stale in ~\(formatShortDuration(remaining))"
        }

        return "Target captured \(ageLabel)"
    }

    // MARK: - Last successful insert description

    /// Returns a human-readable description of the last successful insert time.
    static func lastSuccessfulInsertDescription(insertedAt: Date?, now: Date) -> String? {
        guard let insertedAt else { return nil }
        let elapsed = max(0, now.timeIntervalSince(insertedAt))
        if elapsed < 1 {
            return "Last insert succeeded just now"
        }
        return "Last insert succeeded \(formatShortDuration(elapsed)) ago"
    }

    /// Determines whether a captured hotkey key should auto-add safe
    /// required modifiers (⌘+⇧). Function-row keys, arrows, etc. are
    /// safe to press without modifiers; single characters need them.
    static func shouldAutoApplySafeCaptureModifiers(for key: String) -> Bool {
        if key.count == 1 {
            return true
        }

        switch key {
        case "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12",
             "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20", "f21", "f22", "f23", "f24",
             "escape", "tab", "return", "enter", "keypadenter", "numpadenter", "space", "insert", "ins", "help",
             "delete", "del", "backspace", "bksp", "forwarddelete", "fwddelete", "fwddel",
             "left", "right", "up", "down", "home", "end", "pageup", "pagedown",
             "fn", "function", "globe", "globekey", "caps", "capslock":
            return false
        default:
            return true
        }
    }

    /// Sanitizes a raw key value to its canonical form.
    static func sanitizeKeyValue(_ raw: String) -> String {
        let normalized = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if normalized.isEmpty { return "space" }
        if normalized == " " { return "space" }
        return HotkeyDisplay.canonicalKey(normalized)
    }

    // MARK: - Hotkey risk / conflict warnings (extracted from SettingsView)

    /// Returns `true` when the hotkey combo has no required modifiers and uses a
    /// character or common navigation key, making accidental activation likely.
    static func isHighRiskHotkey(requiredModifiers: Set<ParsedModifier>, key: String) -> Bool {
        guard requiredModifiers.isEmpty else { return false }

        if key.count == 1 { return true }

        switch key {
        case "space", "tab", "return", "delete", "forwarddelete", "escape",
             "fn", "left", "right", "up", "down", "home", "end", "pageup", "pagedown":
            return true
        default:
            return false
        }
    }

    /// Returns `true` when Hold mode is active and the hotkey is high-risk.
    static func showsHoldModeAccidentalTriggerWarning(hotkeyModeRaw: String, requiredModifiers: Set<ParsedModifier>, key: String) -> Bool {
        guard hotkeyModeRaw == HotkeyMode.hold.rawValue else { return false }
        return isHighRiskHotkey(requiredModifiers: requiredModifiers, key: key)
    }

    /// Returns a warning if Escape is the trigger key (conflicts with discard).
    static func hotkeyEscapeCancelConflictWarning(key: String) -> String? {
        guard key == "escape" else { return nil }
        return "Esc is also used to discard an active recording. Using Esc as the trigger key disables that quick-cancel behavior."
    }

    /// Returns a human-readable warning when the chosen hotkey combo conflicts
    /// with a well-known macOS or app shortcut, or `nil` when no conflict is known.
    static func hotkeySystemConflictWarning(requiredModifiers: Set<ParsedModifier>, key: String) -> String? {
        let modifiers = requiredModifiers

        if key == "space" && modifiers == Set([.command]) {
            return "⌘+Space usually opens Spotlight and can block your hotkey."
        }
        if key == "space" && modifiers == Set([.control]) {
            return "⌃+Space is often used for input source switching on macOS."
        }
        if key == "space" && modifiers == Set([.control, .option]) {
            return "⌃+⌥+Space is commonly bound to previous input source on macOS and can steal your hotkey press."
        }
        if key == "space" && modifiers == Set([.command, .control]) {
            return "⌃+⌘+Space usually opens the emoji/symbol picker on macOS and can block dictation trigger behavior."
        }
        if key == "space" && modifiers == Set([.command, .option]) {
            return "⌥+⌘+Space usually opens Finder search on macOS, so it's unreliable for dictation triggering."
        }
        if key == "space" && modifiers == Set([.command, .option, .control]) {
            return "⌃+⌥+⌘+Space is commonly used by app launchers/snippet tools and often gets intercepted before OpenWhisper."
        }
        if key == "f" && modifiers == Set([.command, .control]) {
            return "⌃+⌘+F toggles full-screen in many macOS apps and is a bad dictation hotkey."
        }
        if key == "tab" && modifiers == Set([.command]) {
            return "⌘+Tab is reserved for app switching and won't behave as a reliable dictation hotkey."
        }
        if key == "fn" && modifiers.isEmpty {
            return "Fn/Globe alone is usually reserved by macOS (emoji picker, dictation, or input switching) and is unreliable as a trigger key."
        }
        if key == "tab" && modifiers == Set([.command, .shift]) {
            return "⌘+⇧+Tab is reserved for reverse app switching on macOS."
        }
        if ["3", "4", "5", "6"].contains(key),
           modifiers.contains(.command),
           modifiers.contains(.shift),
           modifiers.isSubset(of: Set([.command, .shift, .control])) {
            switch key {
            case "3": return "⌘+⇧+3 is reserved for macOS screenshots (entire screen), so it will conflict with dictation trigger behavior."
            case "4": return "⌘+⇧+4 is reserved for macOS screenshots (selection/window), so it will conflict with dictation trigger behavior."
            case "5": return "⌘+⇧+5 opens the macOS screenshot/recording panel and is a bad dictation hotkey choice."
            default: return "⌘+⇧+6 toggles floating thumbnail behavior in the macOS screenshot tool and can conflict with dictation hotkeys."
            }
        }
        if key == "backtick" && modifiers == Set([.command]) {
            return "⌘+` is reserved for cycling windows in the front app on macOS."
        }
        if key == "section" && modifiers == Set([.command]) {
            return "⌘+§ usually cycles windows in the front app on ISO keyboards and can steal your dictation hotkey."
        }
        if key == "section" && modifiers == Set([.command, .shift]) {
            return "⌘+⇧+§ usually cycles windows in reverse on ISO keyboards and can steal your dictation hotkey."
        }
        if key == "comma" && modifiers == Set([.command]) {
            return "⌘+, usually opens app settings/preferences and is a frustrating dictation trigger."
        }
        if key == "period" && modifiers == Set([.command]) {
            return "⌘+. is commonly used as Cancel/Stop in macOS apps and is easy to trigger accidentally."
        }
        if key == "escape" && modifiers == Set([.command, .option]) {
            return "⌥+⌘+Esc opens Force Quit on macOS, so it's a terrible hotkey choice."
        }
        if key == "h" && modifiers == Set([.command]) {
            return "⌘+H hides the current app on macOS and makes a poor dictation hotkey."
        }
        if key == "c" && modifiers == Set([.command]) {
            return "⌘+C copies selected text in most apps, so it collides with normal editing constantly."
        }
        if key == "v" && modifiers == Set([.command]) {
            return "⌘+V pastes in most apps and will fight your normal editing flow."
        }
        if key == "x" && modifiers == Set([.command]) {
            return "⌘+X cuts selected text in most apps and is a risky dictation trigger."
        }
        if key == "a" && modifiers == Set([.command]) {
            return "⌘+A selects all text in most apps and is too disruptive for dictation."
        }
        if key == "z" && modifiers == Set([.command]) {
            return "⌘+Z is undo in most apps and will cause accidental reversions while typing."
        }
        if key == "m" && modifiers == Set([.command]) {
            return "⌘+M minimizes the front window on macOS and can interrupt your flow."
        }
        if key == "return" && modifiers == Set([.command]) {
            return "⌘+Return often sends messages/submits forms in chat and email apps, so it's risky for dictation."
        }
        if key == "q" && modifiers == Set([.command]) {
            return "⌘+Q quits the current app on macOS and is a brutal hotkey choice for dictation."
        }
        if key == "q" && modifiers == Set([.command, .control]) {
            return "⌃+⌘+Q locks your Mac on macOS and is an awful choice for a dictation hotkey."
        }
        if key == "w" && modifiers == Set([.command]) {
            return "⌘+W closes the current window/tab on macOS and can kill focus mid-dictation."
        }
        if key == "s" && modifiers == Set([.command]) {
            return "⌘+S saves in most apps and will trigger constantly during normal editing."
        }
        if key == "f" && modifiers == Set([.command]) {
            return "⌘+F opens Find in most apps and is a noisy dictation trigger."
        }
        if key == "n" && modifiers == Set([.command]) {
            return "⌘+N creates a new document/window in many apps and is too disruptive for dictation."
        }
        if key == "t" && modifiers == Set([.command]) {
            return "⌘+T opens a new tab in many apps and browsers, so it collides with normal workflow."
        }
        if key == "p" && modifiers == Set([.command]) {
            return "⌘+P opens Print in most apps and is a brutal accidental trigger."
        }
        if key == "r" && modifiers == Set([.command]) {
            return "⌘+R refreshes/reloads in browsers and many apps, so it's a noisy dictation trigger."
        }
        if key == "o" && modifiers == Set([.command]) {
            return "⌘+O opens files/documents in many apps and will interrupt normal workflow."
        }
        if key == "l" && modifiers == Set([.command]) {
            return "⌘+L often focuses location/search fields (especially in browsers), making it a disruptive dictation hotkey."
        }

        return nil
    }

    /// Returns a human-readable reason why the insertion test is disabled.
    static func insertionTestDisabledReason(
        isRecording: Bool,
        isFinalizingTranscription: Bool,
        isRunningInsertionProbe: Bool,
        hasInsertionProbeSampleText: Bool,
        hasInsertionTarget: Bool
    ) -> String {
        if isRecording {
            return "Stop recording before running an insertion test."
        }
        if isFinalizingTranscription {
            return "Wait for live transcription to finish finalizing before running an insertion test."
        }
        if isRunningInsertionProbe {
            return "Insertion test is already running."
        }
        if !hasInsertionProbeSampleText {
            return "Insertion test text is empty. Enter a short phrase first."
        }
        return "No destination app is available for insertion yet. Switch to your target app, then refresh."
    }
}
