// ViewHelpers.swift
// OpenWhisper
//
// Pure utility functions extracted from ContentView / SettingsView for testability.

import Foundation
import SwiftWhisper

/// Pure helper functions used by views, extracted for testability.
enum ViewHelpers {

    /// Human-readable language label for the given Whisper language code.
    static func activeLanguageLabel(for code: String) -> String {
        let language = WhisperLanguage(rawValue: code) ?? .auto
        return language.displayName
    }

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

    // MARK: - Menu bar label logic

    /// The SF Symbol name for the menu bar icon.
    static func menuBarIconName(
        isRecording: Bool,
        pendingChunkCount: Int,
        hasTranscriptionText: Bool,
        isShowingInsertionFlash: Bool
    ) -> String {
        if isShowingInsertionFlash {
            return "checkmark.circle.fill"
        }
        if isRecording {
            return "waveform.circle.fill"
        }
        if pendingChunkCount > 0 {
            return "ellipsis.circle"
        }
        if hasTranscriptionText {
            return "doc.text"
        }
        return "mic"
    }

    /// The text label shown next to the menu bar icon, or `nil` for the default "OpenWhisper" label.
    static func menuBarDurationLabel(
        isRecording: Bool,
        pendingChunkCount: Int,
        recordingElapsedSeconds: Int?,
        isStartAfterFinalizeQueued: Bool,
        averageChunkLatency: TimeInterval,
        lastChunkLatency: TimeInterval,
        transcriptionWordCount: Int,
        isShowingInsertionFlash: Bool
    ) -> String? {
        if isShowingInsertionFlash {
            return "Inserted"
        }

        if isRecording, let elapsed = recordingElapsedSeconds {
            let minutes = elapsed / 60
            let seconds = elapsed % 60
            return String(format: "%d:%02d", minutes, seconds)
        }

        if !isRecording, pendingChunkCount > 0 {
            let queuedStartSuffix = isStartAfterFinalizeQueued ? "→●" : ""
            let latency = averageChunkLatency > 0 ? averageChunkLatency : lastChunkLatency
            if latency > 0 {
                let remaining = Int((Double(pendingChunkCount) * latency).rounded())
                return "\(pendingChunkCount)⏳\(remaining)s\(queuedStartSuffix)"
            }
            return "\(pendingChunkCount) left\(queuedStartSuffix)"
        }

        if transcriptionWordCount > 0 {
            return "\(transcriptionWordCount)w"
        }

        return nil
    }

    /// Whether the insertion flash should still be visible.
    static func isInsertionFlashVisible(
        insertedAt: Date?,
        now: Date,
        flashDuration: TimeInterval = 3
    ) -> Bool {
        guard let insertedAt else { return false }
        return now.timeIntervalSince(insertedAt) < flashDuration
    }

    /// Compute transcription word count from trimmed text.
    static func transcriptionWordCount(_ text: String) -> Int {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        return trimmed.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).count
    }

    /// Compute transcription stats string (e.g. "5w · 23c").
    static func transcriptionStats(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = trimmed.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).count
        let chars = trimmed.count
        return "\(words)w · \(chars)c"
    }

    /// Compute live words-per-minute from transcription text and recording duration.
    /// Returns nil when duration is under 5 seconds or text has no words.
    static func liveWordsPerMinute(transcription: String, durationSeconds: TimeInterval) -> Int? {
        guard durationSeconds >= 5 else { return nil }
        let words = transcription
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .count
        guard words > 0 else { return nil }
        let perMinute = Double(words) * 60 / durationSeconds
        return max(1, Int(perMinute.rounded()))
    }

    /// Whether the insert action should fall back to clipboard copy because
    /// no target app is identifiable.
    static func shouldCopyBecauseTargetUnknown(
        canInsertDirectly: Bool,
        hasResolvableInsertTarget: Bool,
        hasExternalFrontApp: Bool
    ) -> Bool {
        guard canInsertDirectly else { return false }
        if hasResolvableInsertTarget { return false }
        return !hasExternalFrontApp
    }

    /// Whether to suggest the user retarget the insert destination.
    static func shouldSuggestRetarget(
        isInsertTargetLocked: Bool,
        insertTargetAppName: String?,
        insertTargetBundleIdentifier: String?,
        currentFrontBundleIdentifier: String?,
        currentFrontAppName: String?,
        isInsertTargetStale: Bool
    ) -> Bool {
        guard isInsertTargetLocked else { return false }
        guard let target = insertTargetAppName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !target.isEmpty else { return false }

        if let targetBundle = insertTargetBundleIdentifier,
           let frontBundle = currentFrontBundleIdentifier {
            return targetBundle.caseInsensitiveCompare(frontBundle) != .orderedSame
        }

        if let front = currentFrontAppName {
            return target.caseInsensitiveCompare(front) != .orderedSame
        }

        return isInsertTargetStale
    }

    /// Whether to auto-refresh the insert target before primary insert action.
    static func shouldAutoRefreshInsertTargetBeforePrimaryInsert(
        canInsertDirectly: Bool,
        canRetargetInsertTarget: Bool,
        shouldSuggestRetarget: Bool,
        isInsertTargetStale: Bool
    ) -> Bool {
        guard canInsertDirectly else { return false }
        guard canRetargetInsertTarget else { return false }
        guard !shouldSuggestRetarget else { return false }
        return isInsertTargetStale
    }

    /// Compute recording duration from an optional start date and current time.
    static func recordingDuration(startedAt: Date?, now: Date) -> TimeInterval {
        guard let startedAt else { return 0 }
        return max(0, now.timeIntervalSince(startedAt))
    }

    // MARK: - Front-app filtering

    /// Filters a raw frontmost bundle identifier, returning `nil` when blank or
    /// matching the host app's own bundle id.
    static func currentExternalFrontBundleIdentifier(_ candidate: String, ownBundleIdentifier: String?) -> String? {
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let own = ownBundleIdentifier,
           trimmed.caseInsensitiveCompare(own) == .orderedSame {
            return nil
        }
        return trimmed
    }

    /// Filters a raw frontmost app name, returning `nil` when blank, "Unknown App",
    /// or matching the host app name ("OpenWhisper").
    static func currentExternalFrontAppName(_ candidate: String) -> String? {
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.caseInsensitiveCompare("Unknown App") != .orderedSame else { return nil }
        guard trimmed.caseInsensitiveCompare("OpenWhisper") != .orderedSame else { return nil }
        return trimmed
    }

    /// Updates the finalization progress baseline.
    ///
    /// Returns the new value for `finalizationInitialPendingChunks`.
    static func refreshFinalizationProgressBaseline(
        isRecording: Bool,
        pendingChunks: Int,
        currentBaseline: Int?
    ) -> Int? {
        if isRecording { return nil }
        guard pendingChunks > 0 else { return nil }
        if let current = currentBaseline {
            return max(current, pendingChunks)
        }
        return pendingChunks
    }

    /// Whether recording can be toggled given the current state.
    static func canToggleRecording(isRecording: Bool, pendingChunkCount: Int, microphoneAuthorized: Bool) -> Bool {
        if isRecording || pendingChunkCount > 0 { return true }
        return microphoneAuthorized
    }

    /// Whether the insert target is currently stale.
    static func isInsertTargetStale(capturedAt: Date?, now: Date, staleAfterSeconds: TimeInterval) -> Bool {
        guard let capturedAt else { return false }
        return now.timeIntervalSince(capturedAt) >= staleAfterSeconds
    }

    /// The active staleness threshold based on whether the target is a fallback.
    static func activeInsertTargetStaleAfterSeconds(
        usesFallback: Bool,
        normalTimeout: TimeInterval = 90,
        fallbackTimeout: TimeInterval = 30
    ) -> TimeInterval {
        usesFallback ? fallbackTimeout : normalTimeout
    }

    /// Whether the insert target is locked (compound condition).
    static func isInsertTargetLocked(
        hasTranscriptionText: Bool,
        canInsertNow: Bool,
        canInsertDirectly: Bool,
        hasResolvableInsertTarget: Bool
    ) -> Bool {
        hasTranscriptionText && canInsertNow && canInsertDirectly && hasResolvableInsertTarget
    }

    /// Whether to show the "use current app" quick action.
    static func shouldShowUseCurrentAppQuickAction(shouldSuggestRetarget: Bool, isInsertTargetStale: Bool) -> Bool {
        shouldSuggestRetarget || isInsertTargetStale
    }

    // MARK: - SettingsView extracted logic

    /// Tip text for the current hotkey mode.
    static func hotkeyModeTipText(mode: HotkeyMode, usesEscapeTrigger: Bool) -> String {
        switch mode {
        case .toggle:
            if usesEscapeTrigger {
                return "Tip: toggle mode starts recording on the first press and stops on the next press. Escape quick-cancel is unavailable while Escape is the trigger key."
            }
            return "Tip: toggle mode starts recording on the first press and stops on the next press. Press Esc while recording to discard."
        case .hold:
            if usesEscapeTrigger {
                return "Tip: hold-to-talk records while the combo is pressed and stops on release. Escape quick-cancel is unavailable while Escape is the trigger key."
            }
            return "Tip: hold-to-talk records while the combo is pressed and stops on release. Press Esc while recording to discard."
        }
    }

    /// Title for the hotkey capture button.
    static func hotkeyCaptureButtonTitle(isCapturing: Bool, secondsRemaining: Int) -> String {
        guard isCapturing else { return "Record shortcut" }
        return "Listening… \(secondsRemaining)s"
    }

    /// Instruction text during hotkey capture.
    static func hotkeyCaptureInstruction(inputMonitoringAuthorized: Bool, secondsRemaining: Int) -> String {
        if inputMonitoringAuthorized {
            return "Listening for the next key press (works even if another app is focused). Hold modifiers and press your trigger key once. Press Esc to cancel. (\(secondsRemaining)s left)"
        }
        return "Listening for the next key press in OpenWhisper only. Input Monitoring is missing, so shortcut capture from other apps is unavailable until permission is granted. Press Esc to cancel. (\(secondsRemaining)s left)"
    }

    /// Capture progress as 0…1.
    static func hotkeyCaptureProgress(secondsRemaining: Int, totalSeconds: Int) -> Double {
        guard totalSeconds > 0 else { return 0 }
        return min(max(Double(secondsRemaining) / Double(totalSeconds), 0), 1)
    }

    /// Validation message for the hotkey draft, nil when valid.
    static func hotkeyDraftValidationMessage(draft: String, isSupportedKey: Bool) -> String? {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Enter one trigger key like space, f6, or /."
        }
        if !isSupportedKey {
            if looksLikeModifierComboInput(trimmed),
               parseHotkeyDraft(trimmed)?.requiredModifiers == nil {
                return "Trigger key expects one key (like space or f6), not modifiers only."
            }
            return "Unsupported key. Use a single character, named key, arrow, or F1-F24."
        }
        return nil
    }

    /// Whether the hotkey draft has unapplied changes relative to the current config.
    static func hasHotkeyDraftChangesToApply(draft: String, currentKey: String, currentModifiers: Set<ParsedModifier>) -> Bool {
        guard let parsed = parseHotkeyDraft(draft) else { return false }
        let sanitizedKey = sanitizeKeyValue(parsed.key)
        let keyChanged = sanitizedKey != sanitizeKeyValue(currentKey)
        let modifiersChanged: Bool
        if let modifiers = parsed.requiredModifiers {
            modifiersChanged = modifiers != currentModifiers
        } else {
            modifiersChanged = false
        }
        return keyChanged || modifiersChanged
    }

    /// Preview string for the canonical hotkey draft (e.g. "⌘+⇧+Space").
    static func canonicalHotkeyDraftPreview(draft: String, currentModifiers: Set<ParsedModifier>) -> String? {
        guard let parsed = parseHotkeyDraft(draft) else { return nil }
        let sanitized = sanitizeKeyValue(parsed.key)
        guard HotkeyDisplay.isSupportedKey(sanitized) else { return nil }
        let previewModifiers = parsed.requiredModifiers ?? currentModifiers
        var parts: [String] = []
        if previewModifiers.contains(.command) { parts.append("⌘") }
        if previewModifiers.contains(.shift) { parts.append("⇧") }
        if previewModifiers.contains(.option) { parts.append("⌥") }
        if previewModifiers.contains(.control) { parts.append("⌃") }
        if previewModifiers.contains(.capsLock) { parts.append("⇪") }
        parts.append(HotkeyDisplay.displayKey(sanitized))
        return parts.joined(separator: "+")
    }

    /// Summary of modifier overrides from the draft vs current config, nil if no difference.
    static func hotkeyDraftModifierOverrideSummary(draft: String, currentModifiers: Set<ParsedModifier>) -> String? {
        guard let parsed = parseHotkeyDraft(draft),
              let modifiers = parsed.requiredModifiers,
              modifiers != currentModifiers else { return nil }
        let ordered: [(ParsedModifier, String)] = [
            (.command, "⌘ Command"), (.shift, "⇧ Shift"), (.option, "⌥ Option"),
            (.control, "⌃ Control"), (.capsLock, "⇪ Caps Lock")
        ]
        let active = ordered.filter { modifiers.contains($0.0) }.map(\.1)
        return active.isEmpty ? "none" : active.joined(separator: " + ")
    }

    /// Notice about fn/globe non-configurable modifiers, nil if not applicable.
    static func hotkeyDraftNonConfigurableModifierNotice(draft: String) -> String? {
        guard let parsed = parseHotkeyDraft(draft),
              parsed.containsNonConfigurableModifiers else { return nil }
        return "Fn/Globe modifiers aren't configurable yet. We'll apply the trigger key and keep your existing required modifiers."
    }

    /// Summary of missing hotkey permissions.
    static func hotkeyMissingPermissionSummary(accessibilityAuthorized: Bool, inputMonitoringAuthorized: Bool) -> String? {
        var missing: [String] = []
        if !accessibilityAuthorized { missing.append("Accessibility") }
        if !inputMonitoringAuthorized { missing.append("Input Monitoring") }
        guard !missing.isEmpty else { return nil }
        return missing.joined(separator: " + ")
    }

    // MARK: - ContentView extracted logic

    /// Title for the insert/copy button.
    static func insertButtonTitle(
        canInsertDirectly: Bool,
        insertTargetAppName: String?,
        insertTargetUsesFallback: Bool,
        shouldSuggestRetarget: Bool,
        isInsertTargetStale: Bool,
        liveFrontAppName: String?
    ) -> String {
        if canInsertDirectly {
            guard let target = insertTargetAppName, !target.isEmpty else {
                if let liveFront = liveFrontAppName, !liveFront.isEmpty {
                    return "Insert → \(abbreviatedAppName(liveFront))"
                }
                return "Copy → Clipboard"
            }
            let targetLabel = insertTargetUsesFallback
                ? "\(abbreviatedAppName(target)) (recent)"
                : abbreviatedAppName(target)
            if shouldSuggestRetarget || isInsertTargetStale {
                return "Insert → \(targetLabel) ⚠︎"
            }
            return "Insert → \(targetLabel)"
        }
        return "Copy → Clipboard"
    }

    /// Help text for the insert/copy button.
    static func insertButtonHelpText(
        insertActionDisabledReason: String?,
        canInsertDirectly: Bool,
        shouldCopyBecauseTargetUnknown: Bool,
        shouldSuggestRetarget: Bool,
        isInsertTargetStale: Bool,
        insertTargetAppName: String?,
        insertTargetUsesFallback: Bool,
        currentFrontAppName: String?
    ) -> String {
        if let reason = insertActionDisabledReason {
            return "\(reason) before inserting"
        }
        guard canInsertDirectly else {
            if let target = insertTargetAppName, !target.isEmpty {
                return "Accessibility permission is missing, so this will copy text for \(target)"
            }
            return "Accessibility permission is missing, so this will copy transcription to clipboard"
        }
        if shouldCopyBecauseTargetUnknown {
            return "No destination app is currently available, so this will copy transcription to clipboard"
        }
        if shouldSuggestRetarget,
           let currentFront = currentFrontAppName,
           let frozenTarget = insertTargetAppName,
           !frozenTarget.isEmpty {
            return "Current front app is \(currentFront), but Insert is still targeting \(frozenTarget). Use Retarget + Insert if you switched apps after transcription finished."
        }
        if isInsertTargetStale,
           let frozenTarget = insertTargetAppName,
           !frozenTarget.isEmpty {
            return "Insert target \(frozenTarget) was captured a while ago. Retarget before inserting if you changed context."
        }
        guard let target = insertTargetAppName, !target.isEmpty else {
            if let liveFront = currentFrontAppName, !liveFront.isEmpty {
                return "Insert into \(liveFront)"
            }
            return "Insert into the last active app"
        }
        if insertTargetUsesFallback {
            return "Insert into \(target) captured from recent app context"
        }
        return "Insert into \(target)"
    }

    // MARK: - Retarget button

    static func retargetButtonTitle(
        insertTargetAppName: String?,
        insertTargetUsesFallback: Bool
    ) -> String {
        guard let target = insertTargetAppName, !target.isEmpty else {
            return "Retarget"
        }
        if insertTargetUsesFallback {
            return "Retarget → \(abbreviatedAppName(target)) (recent)"
        }
        return "Retarget → \(abbreviatedAppName(target))"
    }

    static func retargetButtonHelpText(
        isRecording: Bool,
        pendingChunkCount: Int
    ) -> String {
        if isRecording {
            return "Finish recording before retargeting insertion"
        }
        if pendingChunkCount > 0 {
            return "Wait for finalization before retargeting insertion"
        }
        return "Refresh insertion target from your current front app"
    }

    // MARK: - Use Current App button

    static func useCurrentAppButtonTitle(
        canInsertDirectly: Bool,
        currentFrontAppName: String?
    ) -> String {
        if canInsertDirectly {
            if let currentFront = currentFrontAppName, !currentFront.isEmpty {
                return "Use Current → \(abbreviatedAppName(currentFront))"
            }
            return "Use Current App"
        }
        return "Use Current + Copy"
    }

    static func useCurrentAppButtonHelpText(
        insertActionDisabledReason: String?,
        canInsertDirectly: Bool
    ) -> String {
        if let reason = insertActionDisabledReason {
            return "\(reason) before using current app"
        }
        if canInsertDirectly {
            return "Retarget to the current front app and insert immediately"
        }
        return "Retarget to the current front app and copy to clipboard"
    }

    // MARK: - Retarget + Insert button

    static func retargetAndInsertButtonTitle(
        canInsertDirectly: Bool,
        currentFrontAppName: String?
    ) -> String {
        if canInsertDirectly {
            if let currentFront = currentFrontAppName, !currentFront.isEmpty {
                return "Retarget + Insert → \(abbreviatedAppName(currentFront))"
            }
            return "Retarget + Insert → Current App"
        }
        return "Retarget + Copy → Clipboard"
    }

    static func retargetAndInsertHelpText(
        insertActionDisabledReason: String?,
        canInsertDirectly: Bool
    ) -> String {
        if let reason = insertActionDisabledReason {
            return "\(reason) before retargeting and inserting"
        }
        guard canInsertDirectly else {
            return "Refresh target app, then copy transcription to clipboard"
        }
        return "Refresh target app from the current front app, then insert"
    }

    // MARK: - Focus Target button

    static func focusTargetButtonTitle(
        insertTargetAppName: String?
    ) -> String {
        guard let target = insertTargetAppName, !target.isEmpty else {
            return "Focus Target"
        }
        return "Focus → \(abbreviatedAppName(target))"
    }

    static func focusTargetButtonHelpText(
        isRecording: Bool,
        pendingChunkCount: Int,
        insertTargetAppName: String?
    ) -> String {
        if isRecording || pendingChunkCount > 0 {
            return "Wait for recording/finalization to finish before focusing the target app"
        }
        if let target = insertTargetAppName, !target.isEmpty {
            return "Bring \(target) to the front before inserting"
        }
        return "No insertion target yet. Switch to your destination app, then click Retarget."
    }

    // MARK: - Focus + Insert button

    static func focusAndInsertButtonTitle(
        canInsertDirectly: Bool,
        insertTargetAppName: String?
    ) -> String {
        if canInsertDirectly {
            if let target = insertTargetAppName, !target.isEmpty {
                return "Focus + Insert → \(abbreviatedAppName(target))"
            }
            return "Focus + Insert"
        }
        return "Focus + Copy"
    }

    static func focusAndInsertButtonHelpText(
        insertActionDisabledReason: String?,
        hasResolvableInsertTarget: Bool,
        canInsertDirectly: Bool
    ) -> String {
        if let reason = insertActionDisabledReason {
            return "\(reason) before focusing and inserting"
        }
        guard hasResolvableInsertTarget else {
            return "No insertion target yet. Switch to your destination app, then click Retarget."
        }
        if canInsertDirectly {
            return "Focus the saved insert target and insert immediately"
        }
        return "Focus the saved insert target and copy to clipboard"
    }

    // MARK: - Computed property helpers

    static func canRetargetInsertTarget(isRecording: Bool, pendingChunkCount: Int) -> Bool {
        !isRecording && pendingChunkCount == 0
    }

    static func hasResolvableInsertTarget(insertTargetAppName: String?) -> Bool {
        guard let target = insertTargetAppName?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        return !target.isEmpty
    }

    // MARK: - Common hotkey key sections (static data)

    /// The categorized list of supported hotkey key names shown in the settings picker.
    static var commonHotkeyKeySections: [(title: String, keys: [String])] {
        [
            (
                title: "Basic",
                keys: ["space", "tab", "return", "escape", "delete", "forwarddelete", "insert", "fn", "globe"]
            ),
            (
                title: "Navigation",
                keys: ["left", "right", "up", "down", "home", "end", "pageup", "pagedown"]
            ),
            (
                title: "Function",
                keys: ["f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20", "f21", "f22", "f23", "f24"]
            ),
            (
                title: "Punctuation",
                keys: ["minus", "equals", "openbracket", "closebracket", "semicolon", "apostrophe", "comma", "period", "slash", "backslash", "backtick", "section"]
            ),
            (
                title: "Keypad",
                keys: ["keypad0", "keypad1", "keypad2", "keypad3", "keypad4", "keypad5", "keypad6", "keypad7", "keypad8", "keypad9", "keypaddecimal", "keypadcomma", "keypadclear", "keypadplus", "keypadminus", "keypadmultiply", "keypaddivide", "keypadenter", "keypadequals"]
            )
        ]
    }

    // MARK: - Insertion probe helpers

    /// Maximum characters for the insertion probe sample text.
    static let insertionProbeMaxCharacters = 200

    /// Whether the trimmed sample text exceeds the max character limit.
    static func insertionProbeSampleTextWillTruncate(_ trimmedText: String) -> Bool {
        trimmedText.count > insertionProbeMaxCharacters
    }

    /// Enforce the character limit on insertion probe sample text, returning the limited version.
    static func enforceInsertionProbeSampleTextLimit(_ text: String) -> String {
        String(text.prefix(insertionProbeMaxCharacters))
    }

    /// The effective sample text for an insertion probe run (trimmed + limited).
    static func insertionProbeSampleTextForRun(_ rawText: String) -> String {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(insertionProbeMaxCharacters))
    }

    /// Whether there is any non-empty sample text for the insertion probe.
    static func hasInsertionProbeSampleText(_ rawText: String) -> Bool {
        !insertionProbeSampleTextForRun(rawText).isEmpty
    }

    // MARK: - Hotkey draft edits detection

    /// Whether the hotkey draft field has any unsaved edits compared to the current key + modifiers.
    static func hasHotkeyDraftEdits(draft: String, currentKey: String, currentModifiers: Set<ParsedModifier>) -> Bool {
        let sanitizedDraft = sanitizeKeyValue(draft)
        if sanitizedDraft != sanitizeKeyValue(currentKey) {
            return true
        }

        guard let parsed = parseHotkeyDraft(draft),
              let modifiers = parsed.requiredModifiers else {
            return false
        }

        return modifiers != currentModifiers
    }

    // MARK: - Effective hotkey risk context

    /// Resolve the effective key + modifiers for risk warnings, considering the draft field.
    static func effectiveHotkeyRiskContext(
        draft: String,
        currentKey: String,
        currentModifiers: Set<ParsedModifier>
    ) -> (requiredModifiers: Set<ParsedModifier>, key: String) {
        if let parsed = parseHotkeyDraft(draft) {
            let parsedKey = sanitizeKeyValue(parsed.key)
            if HotkeyDisplay.isSupportedKey(parsedKey) {
                let modifiers = parsed.requiredModifiers ?? currentModifiers
                return (modifiers, parsedKey)
            }
        }
        return (currentModifiers, sanitizeKeyValue(currentKey))
    }

    // MARK: - Insertion probe status

    /// Map the insertion probe success state to a semantic status category.
    enum InsertionProbeStatus {
        case success
        case failure
        case unknown
    }

    static func insertionProbeStatus(succeeded: Bool?) -> InsertionProbeStatus {
        switch succeeded {
        case true: return .success
        case false: return .failure
        case nil: return .unknown
        }
    }

    // MARK: - Hotkey key-code helpers (extracted for testability)

    /// Known key-code → key-name mapping used during hotkey capture.
    /// Returns `nil` for pure modifier keys (command, shift, etc.).
    static func hotkeyKeyNameForKeyCode(_ keyCode: Int) -> String? {
        switch keyCode {
        // Pure modifier keys – no key name
        case 0x37, 0x38, 0x3C, 0x3A, 0x3D, 0x3B, 0x3E, 0x39: // Cmd, Shift, RShift, Option, ROption, Control, RControl, CapsLock
            return nil
        case 0x3F: return "fn"       // Function key
        case 0x31: return "space"
        case 0x30: return "tab"
        case 0x24: return "return"
        case 0x35: return "escape"
        case 0x33: return "delete"
        case 0x75: return "forwarddelete"
        case 0x72: return "insert"   // Help key
        case 0x7B: return "left"
        case 0x7C: return "right"
        case 0x7E: return "up"
        case 0x7D: return "down"
        case 0x73: return "home"
        case 0x77: return "end"
        case 0x74: return "pageup"
        case 0x79: return "pagedown"
        // F-keys
        case 0x7A: return "f1"
        case 0x78: return "f2"
        case 0x63: return "f3"
        case 0x76: return "f4"
        case 0x60: return "f5"
        case 0x61: return "f6"
        case 0x62: return "f7"
        case 0x64: return "f8"
        case 0x65: return "f9"
        case 0x6D: return "f10"
        case 0x67: return "f11"
        case 0x6F: return "f12"
        case 0x69: return "f13"
        case 0x6B: return "f14"
        case 0x71: return "f15"
        case 0x6A: return "f16"
        case 0x40: return "f17"
        case 0x4F: return "f18"
        case 0x50: return "f19"
        case 0x5A: return "f20"
        default: return nil // caller should fall back to characters
        }
    }

    /// Whether a key code represents a modifier-only key (no printable character).
    static func isModifierOnlyKeyCode(_ keyCode: Int) -> Bool {
        switch keyCode {
        case 0x37, 0x36,  // Command, Right Command
             0x38, 0x3C,  // Shift, Right Shift
             0x3A, 0x3D,  // Option, Right Option
             0x3B, 0x3E,  // Control, Right Control
             0x39,        // CapsLock
             0x3F:        // Function
            return true
        default:
            return false
        }
    }

    /// Build a hotkey summary string from modifier flags and key name.
    static func hotkeySummaryFromModifiers(
        command: Bool, shift: Bool, option: Bool, control: Bool, capsLock: Bool,
        key: String
    ) -> String {
        var parts: [String] = []
        if command { parts.append("⌘") }
        if shift { parts.append("⇧") }
        if option { parts.append("⌥") }
        if control { parts.append("⌃") }
        if capsLock { parts.append("⇪") }
        parts.append(HotkeyDisplay.displayKey(key))
        return parts.joined(separator: "+")
    }

    // MARK: - Settings UI helpers

    /// Whether the auto-paste permission warning should show.
    static func showsAutoPastePermissionWarning(autoPaste: Bool, accessibilityAuthorized: Bool) -> Bool {
        autoPaste && !accessibilityAuthorized
    }

    /// Title for the insertion test button.
    static func runInsertionTestButtonTitle(
        isRunningProbe: Bool,
        canRunTest: Bool,
        autoCaptureTargetName: String?,
        canCaptureAndRun: Bool
    ) -> String {
        if isRunningProbe { return "Running insertion test…" }
        if canRunTest { return "Run insertion test" }
        if let name = autoCaptureTargetName, !name.isEmpty {
            return "Run insertion test (capture \(name))"
        }
        if canCaptureAndRun { return "Run insertion test (auto-capture)" }
        return "Run insertion test"
    }

    /// Whether the focus-insertion-target button should be enabled.
    static func canFocusInsertionTarget(isRecording: Bool, isFinalizingTranscription: Bool, hasInsertionTarget: Bool) -> Bool {
        guard !isRecording else { return false }
        guard !isFinalizingTranscription else { return false }
        return hasInsertionTarget
    }

    /// Whether the clear-insertion-target button should be enabled.
    static func canClearInsertionTarget(isRunningProbe: Bool, hasInsertionTarget: Bool) -> Bool {
        guard !isRunningProbe else { return false }
        return hasInsertionTarget
    }

    /// Whether a capture-activation event should be ignored (debounce within threshold).
    static func shouldIgnoreCaptureActivation(
        elapsedSinceCaptureStart: TimeInterval,
        debounceThreshold: TimeInterval = 0.35,
        keyName: String?,
        hasCommandModifier: Bool,
        hasShiftModifier: Bool,
        hasExtraModifiers: Bool
    ) -> Bool {
        guard elapsedSinceCaptureStart <= debounceThreshold else { return false }
        guard keyName == "k" else { return false }
        return hasCommandModifier && hasShiftModifier && !hasExtraModifiers
    }

    /// Maps a virtual key code (and optional characters string) to a canonical hotkey name.
    /// Returns `nil` for modifier-only key codes (command, shift, option, control, caps lock).
    static func hotkeyKeyNameFromKeyCode(_ keyCode: Int, characters: String? = nil) -> String? {
        switch keyCode {
        case 0x37, 0x38, 0x3C, 0x3A, 0x3D, 0x3B, 0x3E, 0x39:
            return nil
        case 0x3F: return "fn"
        case 0x31: return "space"
        case 0x30: return "tab"
        case 0x24: return "return"
        case 0x35: return "escape"
        case 0x33: return "delete"
        case 0x75: return "forwarddelete"
        case 0x72: return "insert"
        case 0x7B: return "left"
        case 0x7C: return "right"
        case 0x7E: return "up"
        case 0x7D: return "down"
        case 0x73: return "home"
        case 0x77: return "end"
        case 0x74: return "pageup"
        case 0x79: return "pagedown"
        case 0x7A: return "f1"
        case 0x78: return "f2"
        case 0x63: return "f3"
        case 0x76: return "f4"
        case 0x60: return "f5"
        case 0x61: return "f6"
        case 0x62: return "f7"
        case 0x64: return "f8"
        case 0x65: return "f9"
        case 0x6D: return "f10"
        case 0x67: return "f11"
        case 0x6F: return "f12"
        case 0x69: return "f13"
        case 0x6B: return "f14"
        case 0x71: return "f15"
        case 0x6A: return "f16"
        case 0x40: return "f17"
        case 0x4F: return "f18"
        case 0x50: return "f19"
        case 0x5A: return "f20"
        case 0x52: return "keypad0"
        case 0x53: return "keypad1"
        case 0x54: return "keypad2"
        case 0x55: return "keypad3"
        case 0x56: return "keypad4"
        case 0x57: return "keypad5"
        case 0x58: return "keypad6"
        case 0x59: return "keypad7"
        case 0x5B: return "keypad8"
        case 0x5C: return "keypad9"
        case 0x41: return "keypaddecimal"
        case 0x5F: return "keypadcomma"
        case 0x43: return "keypadmultiply"
        case 0x45: return "keypadplus"
        case 0x47: return "keypadclear"
        case 0x4B: return "keypaddivide"
        case 0x4C: return "keypadenter"
        case 0x4E: return "keypadminus"
        case 0x51: return "keypadequals"
        default:
            guard let chars = characters?.lowercased(),
                  let scalar = chars.unicodeScalars.first else {
                return nil
            }
            if scalar.properties.isWhitespace {
                return "space"
            }
            return HotkeyDisplay.canonicalKey(String(scalar))
        }
    }

    // MARK: - Settings insertion test composite helpers

    /// Whether the auto-capture hint should display in Settings.
    static func showsInsertionTestAutoCaptureHint(
        isRunningProbe: Bool,
        canRunTest: Bool,
        canCaptureAndRun: Bool
    ) -> Bool {
        !isRunningProbe && !canRunTest && canCaptureAndRun
    }

    /// Whether a combined capture-and-run insertion test action is available.
    static func canCaptureAndRunInsertionTest(
        canCaptureFrontmostProfile: Bool,
        isRecording: Bool,
        isFinalizingTranscription: Bool,
        isRunningInsertionProbe: Bool,
        hasInsertionProbeSampleText: Bool
    ) -> Bool {
        canCaptureFrontmostProfile
            && !isRecording
            && !isFinalizingTranscription
            && !isRunningInsertionProbe
            && hasInsertionProbeSampleText
    }

    /// Whether a standalone (no auto-capture) insertion test can run.
    static func canRunInsertionTest(
        isRecording: Bool,
        isFinalizingTranscription: Bool,
        isRunningInsertionProbe: Bool,
        hasInsertionTarget: Bool,
        hasInsertionProbeSampleText: Bool
    ) -> Bool {
        !isRecording
            && !isFinalizingTranscription
            && !isRunningInsertionProbe
            && hasInsertionTarget
            && hasInsertionProbeSampleText
    }

    /// Resolves the effective hotkey risk context from draft text or current config.
    static func effectiveHotkeyRiskKey(
        draftKey: String,
        currentKey: String,
        currentModifiers: Set<ParsedModifier>
    ) -> (requiredModifiers: Set<ParsedModifier>, key: String) {
        if let parsed = parseHotkeyDraft(draftKey) {
            let parsedKey = sanitizeKeyValue(parsed.key)
            if HotkeyDisplay.isSupportedKey(parsedKey) {
                let modifiers = parsed.requiredModifiers ?? currentModifiers
                return (modifiers, parsedKey)
            }
        }
        return (currentModifiers, sanitizeKeyValue(currentKey))
    }

    /// Whether an insertion test can run, either standalone or with auto-capture.
    static func canRunInsertionTestWithAutoCapture(
        canRunTest: Bool,
        canCaptureAndRun: Bool
    ) -> Bool {
        canRunTest || canCaptureAndRun
    }

    /// Whether the user can focus the insertion target and then run a test.
    static func canFocusAndRunInsertionTest(
        canFocusTarget: Bool,
        canRunTest: Bool
    ) -> Bool {
        canFocusTarget && canRunTest
    }

    /// Resolves the insertion test auto-capture hint visibility.
    /// Shows when not running a probe, can't run standalone, but can auto-capture.
    static func showsInsertionTestAutoCaptureHintResolved(
        isRunningProbe: Bool,
        canRunTest: Bool,
        canCaptureAndRun: Bool
    ) -> Bool {
        !isRunningProbe && !canRunTest && canCaptureAndRun
    }

    /// Maps insertion probe succeeded state to a status string for display.
    static func insertionProbeStatusLabel(succeeded: Bool?) -> String {
        switch succeeded {
        case true: return "Passed"
        case false: return "Failed"
        case nil: return "Not tested"
        }
    }

    // MARK: - Sentence punctuation helpers

    /// Whether a character is sentence-ending punctuation.
    static func isSentencePunctuation(_ character: Character) -> Bool {
        ".,!?;:…".contains(character)
    }

    /// Extracts trailing sentence punctuation from text, if any.
    static func trailingSentencePunctuation(in text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var punctuation: [Character] = []
        for character in trimmed.reversed() {
            if isSentencePunctuation(character) {
                punctuation.append(character)
                continue
            }
            break
        }

        guard !punctuation.isEmpty else { return nil }
        return String(punctuation.reversed())
    }

    // MARK: - Streaming elapsed time

    /// Format elapsed seconds as "H:MM:SS" or "M:SS" for streaming status.
    static func streamingElapsedStatusSegment(elapsedSeconds: Int) -> String? {
        guard elapsedSeconds >= 0 else { return nil }

        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Model file size

    /// Returns the file size at the given path, or 0 if unavailable.
    static func sizeOfModelFile(atPath path: String) -> Int64 {
        guard !path.isEmpty,
              let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attrs[.size] as? Int64 else {
            return 0
        }
        return size
    }

}
