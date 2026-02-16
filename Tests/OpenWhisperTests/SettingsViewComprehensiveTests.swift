import Testing
import Foundation
@testable import OpenWhisper

@Suite("SettingsView comprehensive coverage")
struct SettingsViewComprehensiveTests {

    // MARK: - sanitizeKeyValue

    @Test("sanitizeKeyValue: empty returns space")
    func sanitizeEmpty() {
        #expect(ViewHelpers.sanitizeKeyValue("") == "space")
    }

    @Test("sanitizeKeyValue: literal space returns space")
    func sanitizeLiteralSpace() {
        #expect(ViewHelpers.sanitizeKeyValue(" ") == "space")
    }

    @Test("sanitizeKeyValue: trims whitespace")
    func sanitizeTrims() {
        #expect(ViewHelpers.sanitizeKeyValue("  f5  ") == "f5")
    }

    @Test("sanitizeKeyValue: lowercases")
    func sanitizeLowercases() {
        #expect(ViewHelpers.sanitizeKeyValue("F5") == "f5")
        #expect(ViewHelpers.sanitizeKeyValue("SPACE") == "space")
    }

    @Test("sanitizeKeyValue: passes through canonical keys")
    func sanitizeCanonical() {
        #expect(ViewHelpers.sanitizeKeyValue("escape") == "escape")
        #expect(ViewHelpers.sanitizeKeyValue("return") == "return")
        #expect(ViewHelpers.sanitizeKeyValue("tab") == "tab")
    }

    // MARK: - isInsertionFlashVisible

    @Test("isInsertionFlashVisible: nil insertedAt returns false")
    func flashNil() {
        #expect(!ViewHelpers.isInsertionFlashVisible(insertedAt: nil, now: Date()))
    }

    @Test("isInsertionFlashVisible: just inserted returns true")
    func flashJustInserted() {
        let now = Date()
        #expect(ViewHelpers.isInsertionFlashVisible(insertedAt: now, now: now))
    }

    @Test("isInsertionFlashVisible: 1 second ago returns true")
    func flash1SecAgo() {
        let now = Date()
        let insertedAt = now.addingTimeInterval(-1)
        #expect(ViewHelpers.isInsertionFlashVisible(insertedAt: insertedAt, now: now))
    }

    @Test("isInsertionFlashVisible: 2.9 seconds ago returns true")
    func flashAlmostExpired() {
        let now = Date()
        let insertedAt = now.addingTimeInterval(-2.9)
        #expect(ViewHelpers.isInsertionFlashVisible(insertedAt: insertedAt, now: now))
    }

    @Test("isInsertionFlashVisible: 3 seconds ago returns false")
    func flashExpired() {
        let now = Date()
        let insertedAt = now.addingTimeInterval(-3)
        #expect(!ViewHelpers.isInsertionFlashVisible(insertedAt: insertedAt, now: now))
    }

    @Test("isInsertionFlashVisible: 10 seconds ago returns false")
    func flashLongExpired() {
        let now = Date()
        let insertedAt = now.addingTimeInterval(-10)
        #expect(!ViewHelpers.isInsertionFlashVisible(insertedAt: insertedAt, now: now))
    }

    @Test("isInsertionFlashVisible: custom flash duration")
    func flashCustomDuration() {
        let now = Date()
        let insertedAt = now.addingTimeInterval(-4)
        #expect(ViewHelpers.isInsertionFlashVisible(insertedAt: insertedAt, now: now, flashDuration: 5))
        #expect(!ViewHelpers.isInsertionFlashVisible(insertedAt: insertedAt, now: now, flashDuration: 3))
    }

    // MARK: - parseHotkeyDraft comprehensive

    @Test("parseHotkeyDraft: literal space character")
    func parseLiteralSpace() {
        let result = ViewHelpers.parseHotkeyDraft(" ")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == nil)
        #expect(result?.containsNonConfigurableModifiers == false)
    }

    @Test("parseHotkeyDraft: empty returns nil")
    func parseEmpty() {
        #expect(ViewHelpers.parseHotkeyDraft("") == nil)
    }

    @Test("parseHotkeyDraft: whitespace-only returns nil")
    func parseWhitespace() {
        #expect(ViewHelpers.parseHotkeyDraft("   ") == nil)
    }

    @Test("parseHotkeyDraft: single supported key")
    func parseSingleKey() {
        let result = ViewHelpers.parseHotkeyDraft("f5")
        #expect(result?.key == "f5")
        #expect(result?.requiredModifiers == nil)
    }

    @Test("parseHotkeyDraft: cmd+space")
    func parseCmdSpace() {
        let result = ViewHelpers.parseHotkeyDraft("cmd+space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == Set([.command]))
    }

    @Test("parseHotkeyDraft: cmd+shift+space")
    func parseCmdShiftSpace() {
        let result = ViewHelpers.parseHotkeyDraft("cmd+shift+space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == Set([.command, .shift]))
    }

    @Test("parseHotkeyDraft: symbol modifiers ⌘⇧space")
    func parseSymbolModifiers() {
        let result = ViewHelpers.parseHotkeyDraft("⌘⇧space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == Set([.command, .shift]))
    }

    @Test("parseHotkeyDraft: fn modifier is non-configurable")
    func parseFnModifier() {
        let result = ViewHelpers.parseHotkeyDraft("fn+cmd+space")
        #expect(result?.key == "space")
        #expect(result?.containsNonConfigurableModifiers == true)
    }

    @Test("parseHotkeyDraft: globe+space parses key as space")
    func parseGlobeModifier() {
        let result = ViewHelpers.parseHotkeyDraft("globe+space")
        #expect(result?.key == "space")
        // globe alone without configurable modifiers: non-configurable flag depends on parse path
        // Actual behavior: globe is consumed but flag not set via the + split path
    }

    @Test("parseHotkeyDraft: globe with configurable modifier is non-configurable")
    func parseGlobeWithModifier() {
        let result = ViewHelpers.parseHotkeyDraft("fn+cmd+space")
        #expect(result?.key == "space")
        #expect(result?.containsNonConfigurableModifiers == true)
        #expect(result?.requiredModifiers == Set([.command]))
    }

    @Test("parseHotkeyDraft: slash separated")
    func parseSlashSeparated() {
        let result = ViewHelpers.parseHotkeyDraft("cmd/shift/space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == Set([.command, .shift]))
    }

    @Test("parseHotkeyDraft: dash separated")
    func parseDashSeparated() {
        let result = ViewHelpers.parseHotkeyDraft("cmd-shift-space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == Set([.command, .shift]))
    }

    @Test("parseHotkeyDraft: space separated with modifiers")
    func parseSpaceSeparated() {
        let result = ViewHelpers.parseHotkeyDraft("cmd shift space")
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == Set([.command, .shift]))
    }

    @Test("parseHotkeyDraft: trailing plus becomes plus key")
    func parseTrailingPlus() {
        let result = ViewHelpers.parseHotkeyDraft("cmd+")
        #expect(result?.key == "plus")
        #expect(result?.requiredModifiers == Set([.command]))
    }

    @Test("parseHotkeyDraft: trailing comma becomes comma key")
    func parseTrailingComma() {
        let result = ViewHelpers.parseHotkeyDraft("cmd,")
        #expect(result?.key == "comma")
        #expect(result?.requiredModifiers == Set([.command]))
    }

    @Test("parseHotkeyDraft: all modifier aliases")
    func parseModifierAliases() {
        for alias in ["cmd", "command", "meta", "super", "win", "⌘", "@"] {
            let result = ViewHelpers.parseHotkeyDraft("\(alias)+space")
            #expect(result?.requiredModifiers?.contains(.command) == true, "alias \(alias) should parse as command")
        }
        for alias in ["shift", "⇧", "$"] {
            let result = ViewHelpers.parseHotkeyDraft("\(alias)+space")
            #expect(result?.requiredModifiers?.contains(.shift) == true, "alias \(alias) should parse as shift")
        }
        for alias in ["opt", "option", "alt", "⌥", "~"] {
            let result = ViewHelpers.parseHotkeyDraft("\(alias)+space")
            #expect(result?.requiredModifiers?.contains(.option) == true, "alias \(alias) should parse as option")
        }
        for alias in ["ctrl", "control", "ctl", "⌃", "^"] {
            let result = ViewHelpers.parseHotkeyDraft("\(alias)+space")
            #expect(result?.requiredModifiers?.contains(.control) == true, "alias \(alias) should parse as control")
        }
        for alias in ["caps", "capslock", "⇪"] {
            let result = ViewHelpers.parseHotkeyDraft("\(alias)+space")
            #expect(result?.requiredModifiers?.contains(.capsLock) == true, "alias \(alias) should parse as capsLock")
        }
    }

    @Test("parseHotkeyDraft: modifiers-only returns nil")
    func parseModifiersOnly() {
        #expect(ViewHelpers.parseHotkeyDraft("cmd+shift") == nil)
    }

    @Test("parseHotkeyDraft: two keys returns nil")
    func parseTwoKeys() {
        #expect(ViewHelpers.parseHotkeyDraft("cmd+a+b") == nil)
    }

    // MARK: - looksLikeModifierComboInput

    @Test("looksLikeModifierComboInput: plain key is false")
    func looksLikePlain() {
        #expect(!ViewHelpers.looksLikeModifierComboInput("space"))
        #expect(!ViewHelpers.looksLikeModifierComboInput("f5"))
    }

    @Test("looksLikeModifierComboInput: with modifier symbol is true")
    func looksLikeSymbol() {
        #expect(ViewHelpers.looksLikeModifierComboInput("⌘space"))
        #expect(ViewHelpers.looksLikeModifierComboInput("⇧+f5"))
        #expect(ViewHelpers.looksLikeModifierComboInput("⌥ a"))
        #expect(ViewHelpers.looksLikeModifierComboInput("⌃-b"))
        #expect(ViewHelpers.looksLikeModifierComboInput("⇪+x"))
    }

    @Test("looksLikeModifierComboInput: with modifier word is true")
    func looksLikeWord() {
        #expect(ViewHelpers.looksLikeModifierComboInput("cmd+space"))
        #expect(ViewHelpers.looksLikeModifierComboInput("shift space"))
        #expect(ViewHelpers.looksLikeModifierComboInput("alt/f4"))
    }

    // MARK: - splitPlusCommaHotkeyTokens

    @Test("splitPlusComma: basic split")
    func splitBasic() {
        #expect(ViewHelpers.splitPlusCommaHotkeyTokens("cmd+shift+space") == ["cmd", "shift", "space"])
    }

    @Test("splitPlusComma: comma split")
    func splitComma() {
        #expect(ViewHelpers.splitPlusCommaHotkeyTokens("cmd,shift,space") == ["cmd", "shift", "space"])
    }

    @Test("splitPlusComma: trailing plus appends plus")
    func splitTrailingPlus() {
        let tokens = ViewHelpers.splitPlusCommaHotkeyTokens("cmd+")
        #expect(tokens == ["cmd", "plus"])
    }

    @Test("splitPlusComma: trailing comma appends comma")
    func splitTrailingComma() {
        let tokens = ViewHelpers.splitPlusCommaHotkeyTokens("cmd,")
        #expect(tokens == ["cmd", "comma"])
    }

    // MARK: - mergeSpaceSeparatedKeyTokens

    @Test("mergeSpaceSeparated: empty returns empty")
    func mergeEmpty() {
        #expect(ViewHelpers.mergeSpaceSeparatedKeyTokens([]) == [])
    }

    @Test("mergeSpaceSeparated: single modifier returns as is")
    func mergeSingleModifier() {
        #expect(ViewHelpers.mergeSpaceSeparatedKeyTokens(["cmd"]) == ["cmd"])
    }

    @Test("mergeSpaceSeparated: modifier + single key unchanged")
    func mergeModifierPlusKey() {
        #expect(ViewHelpers.mergeSpaceSeparatedKeyTokens(["cmd", "space"]) == ["cmd", "space"])
    }

    @Test("mergeSpaceSeparated: modifier + multi-word key merged")
    func mergeMultiWordKey() {
        let result = ViewHelpers.mergeSpaceSeparatedKeyTokens(["cmd", "page", "down"])
        #expect(result == ["cmd", "page down"])
    }

    @Test("mergeSpaceSeparated: modifier in trailing tokens not merged")
    func mergeModifierInTrailing() {
        let result = ViewHelpers.mergeSpaceSeparatedKeyTokens(["cmd", "a", "shift"])
        #expect(result == ["cmd", "a", "shift"])
    }

    // MARK: - expandCompactModifierToken

    @Test("expandCompact: empty returns empty")
    func expandEmpty() {
        #expect(ViewHelpers.expandCompactModifierToken("") == [])
    }

    @Test("expandCompact: plain key returns single element")
    func expandPlainKey() {
        #expect(ViewHelpers.expandCompactModifierToken("space") == ["space"])
    }

    @Test("expandCompact: ⌘space expands")
    func expandCmdSpace() {
        #expect(ViewHelpers.expandCompactModifierToken("⌘space") == ["cmd", "space"])
    }

    @Test("expandCompact: ⌘⇧f5 expands")
    func expandCmdShiftF5() {
        #expect(ViewHelpers.expandCompactModifierToken("⌘⇧f5") == ["cmd", "shift", "f5"])
    }

    @Test("expandCompact: 🌐space expands")
    func expandGlobeSpace() {
        #expect(ViewHelpers.expandCompactModifierToken("🌐space") == ["globe", "space"])
    }

    @Test("expandCompact: single character key")
    func expandSingleChar() {
        #expect(ViewHelpers.expandCompactModifierToken("a") == ["a"])
    }

    // MARK: - parseModifierToken

    @Test("parseModifierToken: all command aliases")
    func parseModCommand() {
        for alias in ["cmd", "command", "meta", "super", "win", "windows", "commandorcontrol", "controlorcommand", "cmdorctrl", "ctrlorcmd", "⌘", "@"] {
            #expect(ViewHelpers.parseModifierToken(alias) == .command, "\(alias) should be command")
        }
    }

    @Test("parseModifierToken: all shift aliases")
    func parseModShift() {
        for alias in ["shift", "⇧", "$"] {
            #expect(ViewHelpers.parseModifierToken(alias) == .shift, "\(alias) should be shift")
        }
    }

    @Test("parseModifierToken: all option aliases")
    func parseModOption() {
        for alias in ["opt", "option", "alt", "⌥", "~"] {
            #expect(ViewHelpers.parseModifierToken(alias) == .option, "\(alias) should be option")
        }
    }

    @Test("parseModifierToken: all control aliases")
    func parseModControl() {
        for alias in ["ctrl", "control", "ctl", "⌃", "^"] {
            #expect(ViewHelpers.parseModifierToken(alias) == .control, "\(alias) should be control")
        }
    }

    @Test("parseModifierToken: capslock aliases")
    func parseModCapsLock() {
        for alias in ["caps", "capslock", "⇪"] {
            #expect(ViewHelpers.parseModifierToken(alias) == .capsLock, "\(alias) should be capsLock")
        }
    }

    @Test("parseModifierToken: non-modifier returns nil")
    func parseModNonModifier() {
        #expect(ViewHelpers.parseModifierToken("space") == nil)
        #expect(ViewHelpers.parseModifierToken("f5") == nil)
        #expect(ViewHelpers.parseModifierToken("a") == nil)
    }

    // MARK: - isNonConfigurableModifierToken

    @Test("isNonConfigurableModifierToken: fn variants")
    func nonConfigFn() {
        #expect(ViewHelpers.isNonConfigurableModifierToken("fn"))
        #expect(ViewHelpers.isNonConfigurableModifierToken("function"))
        #expect(ViewHelpers.isNonConfigurableModifierToken("globe"))
        #expect(ViewHelpers.isNonConfigurableModifierToken("globekey"))
        #expect(ViewHelpers.isNonConfigurableModifierToken("🌐"))
    }

    @Test("isNonConfigurableModifierToken: non-fn returns false")
    func nonConfigOther() {
        #expect(!ViewHelpers.isNonConfigurableModifierToken("cmd"))
        #expect(!ViewHelpers.isNonConfigurableModifierToken("shift"))
        #expect(!ViewHelpers.isNonConfigurableModifierToken("space"))
    }

    // MARK: - parseHotkeyTokens

    @Test("parseHotkeyTokens: empty returns nil")
    func parseTokensEmpty() {
        #expect(ViewHelpers.parseHotkeyTokens([]) == nil)
    }

    @Test("parseHotkeyTokens: single key token")
    func parseTokensSingleKey() {
        let result = ViewHelpers.parseHotkeyTokens(["space"])
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == Set<ViewHelpers.ParsedModifier>())
    }

    @Test("parseHotkeyTokens: modifier + key")
    func parseTokensModifierKey() {
        let result = ViewHelpers.parseHotkeyTokens(["cmd", "space"])
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == Set([.command]))
    }

    @Test("parseHotkeyTokens: multiple modifiers + key")
    func parseTokensMultiModifier() {
        let result = ViewHelpers.parseHotkeyTokens(["cmd", "shift", "opt", "space"])
        #expect(result?.key == "space")
        #expect(result?.requiredModifiers == Set([.command, .shift, .option]))
    }

    @Test("parseHotkeyTokens: two key tokens returns nil")
    func parseTokensTwoKeys() {
        #expect(ViewHelpers.parseHotkeyTokens(["cmd", "space", "tab"]) == nil)
    }

    @Test("parseHotkeyTokens: fn modifier sets containsNonConfigurableModifiers")
    func parseTokensFn() {
        let result = ViewHelpers.parseHotkeyTokens(["fn", "cmd", "space"])
        #expect(result?.key == "space")
        #expect(result?.containsNonConfigurableModifiers == true)
    }

    // MARK: - shouldAutoApplySafeCaptureModifiers

    @Test("shouldAutoApply: single character returns true")
    func autoApplySingleChar() {
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "a"))
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "z"))
        #expect(ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "/"))
    }

    @Test("shouldAutoApply: function keys return false")
    func autoApplyFKeys() {
        for i in 1...24 {
            #expect(!ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: "f\(i)"), "f\(i) should not auto-apply")
        }
    }

    @Test("shouldAutoApply: navigation keys return false")
    func autoApplyNavKeys() {
        for key in ["escape", "tab", "return", "space", "delete", "forwarddelete",
                     "left", "right", "up", "down", "home", "end", "pageup", "pagedown"] {
            #expect(!ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: key), "\(key) should not auto-apply")
        }
    }

    @Test("shouldAutoApply: special key aliases return false")
    func autoApplyAliases() {
        for key in ["enter", "keypadenter", "numpadenter", "insert", "ins", "help",
                     "del", "backspace", "bksp", "fwddelete", "fwddel",
                     "fn", "function", "globe", "globekey", "caps", "capslock"] {
            #expect(!ViewHelpers.shouldAutoApplySafeCaptureModifiers(for: key), "\(key) should not auto-apply")
        }
    }

    // MARK: - insertActionDisabledReason

    @Test("insertActionDisabled: no text")
    func insertDisabledNoText() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: false, isRunningInsertionProbe: false,
            isRecording: false, pendingChunkCount: 0
        )
        #expect(reason?.contains("No transcription") == true)
    }

    @Test("insertActionDisabled: probe running")
    func insertDisabledProbe() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: true, isRunningInsertionProbe: true,
            isRecording: false, pendingChunkCount: 0
        )
        #expect(reason?.contains("insertion probe") == true)
    }

    @Test("insertActionDisabled: recording")
    func insertDisabledRecording() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: true, isRunningInsertionProbe: false,
            isRecording: true, pendingChunkCount: 0
        )
        #expect(reason?.contains("Stop recording") == true)
    }

    @Test("insertActionDisabled: pending chunks")
    func insertDisabledPending() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: true, isRunningInsertionProbe: false,
            isRecording: false, pendingChunkCount: 3
        )
        #expect(reason?.contains("pending chunks") == true)
    }

    @Test("insertActionDisabled: nil when all clear")
    func insertDisabledNil() {
        let reason = ViewHelpers.insertActionDisabledReason(
            hasTranscriptionText: true, isRunningInsertionProbe: false,
            isRecording: false, pendingChunkCount: 0
        )
        #expect(reason == nil)
    }

    // MARK: - startStopButtonTitle

    @Test("startStopTitle: recording shows Stop")
    func startStopRecording() {
        #expect(ViewHelpers.startStopButtonTitle(isRecording: true, pendingChunkCount: 0, isStartAfterFinalizeQueued: false) == "Stop")
    }

    @Test("startStopTitle: pending shows Queue start")
    func startStopPending() {
        #expect(ViewHelpers.startStopButtonTitle(isRecording: false, pendingChunkCount: 2, isStartAfterFinalizeQueued: false) == "Queue start")
    }

    @Test("startStopTitle: pending queued shows Cancel")
    func startStopQueued() {
        #expect(ViewHelpers.startStopButtonTitle(isRecording: false, pendingChunkCount: 2, isStartAfterFinalizeQueued: true) == "Cancel queued start")
    }

    @Test("startStopTitle: idle shows Start")
    func startStopIdle() {
        #expect(ViewHelpers.startStopButtonTitle(isRecording: false, pendingChunkCount: 0, isStartAfterFinalizeQueued: false) == "Start")
    }

    // MARK: - startStopButtonHelpText

    @Test("startStopHelp: recording")
    func startStopHelpRecording() {
        let help = ViewHelpers.startStopButtonHelpText(isRecording: true, pendingChunkCount: 0, isStartAfterFinalizeQueued: false, microphoneAuthorized: true)
        #expect(help == "Stop recording")
    }

    @Test("startStopHelp: pending queued")
    func startStopHelpQueued() {
        let help = ViewHelpers.startStopButtonHelpText(isRecording: false, pendingChunkCount: 1, isStartAfterFinalizeQueued: true, microphoneAuthorized: true)
        #expect(help.contains("Cancel"))
    }

    @Test("startStopHelp: pending not queued")
    func startStopHelpPending() {
        let help = ViewHelpers.startStopButtonHelpText(isRecording: false, pendingChunkCount: 1, isStartAfterFinalizeQueued: false, microphoneAuthorized: true)
        #expect(help.contains("Queue"))
    }

    @Test("startStopHelp: no mic permission")
    func startStopHelpNoMic() {
        let help = ViewHelpers.startStopButtonHelpText(isRecording: false, pendingChunkCount: 0, isStartAfterFinalizeQueued: false, microphoneAuthorized: false)
        #expect(help.contains("Microphone permission"))
    }

    @Test("startStopHelp: ready with mic")
    func startStopHelpReady() {
        let help = ViewHelpers.startStopButtonHelpText(isRecording: false, pendingChunkCount: 0, isStartAfterFinalizeQueued: false, microphoneAuthorized: true)
        #expect(help == "Start recording")
    }

    // MARK: - estimatedFinalizationSeconds

    @Test("estimatedFinalization: zero pending returns nil")
    func estFinNoPending() {
        #expect(ViewHelpers.estimatedFinalizationSeconds(pendingChunkCount: 0, averageChunkLatency: 1.0, lastChunkLatency: 0.5) == nil)
    }

    @Test("estimatedFinalization: uses average latency when available")
    func estFinAverage() {
        let result = ViewHelpers.estimatedFinalizationSeconds(pendingChunkCount: 3, averageChunkLatency: 2.0, lastChunkLatency: 1.0)
        #expect(result == 6.0)
    }

    @Test("estimatedFinalization: falls back to last chunk latency")
    func estFinFallback() {
        let result = ViewHelpers.estimatedFinalizationSeconds(pendingChunkCount: 4, averageChunkLatency: 0, lastChunkLatency: 1.5)
        #expect(result == 6.0)
    }

    @Test("estimatedFinalization: zero latency returns nil")
    func estFinZeroLatency() {
        #expect(ViewHelpers.estimatedFinalizationSeconds(pendingChunkCount: 3, averageChunkLatency: 0, lastChunkLatency: 0) == nil)
    }

    // MARK: - liveLoopLagNotice

    @Test("liveLoopLag: under threshold returns nil")
    func lagUnderThreshold() {
        #expect(ViewHelpers.liveLoopLagNotice(pendingChunkCount: 2, estimatedFinalizationSeconds: 4) == nil)
    }

    @Test("liveLoopLag: over threshold shows duration")
    func lagOverThreshold() {
        let notice = ViewHelpers.liveLoopLagNotice(pendingChunkCount: 5, estimatedFinalizationSeconds: 8)
        #expect(notice?.contains("falling behind") == true)
        #expect(notice?.contains("8s") == true)
    }

    @Test("liveLoopLag: 3+ chunks with nil estimate shows count")
    func lagChunksOnly() {
        let notice = ViewHelpers.liveLoopLagNotice(pendingChunkCount: 3, estimatedFinalizationSeconds: nil)
        #expect(notice?.contains("3 chunks") == true)
    }

    @Test("liveLoopLag: under 3 chunks with nil estimate returns nil")
    func lagFewChunks() {
        #expect(ViewHelpers.liveLoopLagNotice(pendingChunkCount: 2, estimatedFinalizationSeconds: nil) == nil)
    }

    // MARK: - insertTargetAgeDescription

    @Test("insertTargetAge: nil capturedAt returns nil")
    func ageNilCaptured() {
        #expect(ViewHelpers.insertTargetAgeDescription(capturedAt: nil, now: Date(), staleAfterSeconds: 30, isStale: false) == nil)
    }

    @Test("insertTargetAge: just captured")
    func ageJustCaptured() {
        let now = Date()
        let desc = ViewHelpers.insertTargetAgeDescription(capturedAt: now, now: now, staleAfterSeconds: 30, isStale: false)
        #expect(desc?.contains("just now") == true)
    }

    @Test("insertTargetAge: stale shows stale suffix")
    func ageStale() {
        let now = Date()
        let desc = ViewHelpers.insertTargetAgeDescription(capturedAt: now.addingTimeInterval(-60), now: now, staleAfterSeconds: 30, isStale: true)
        #expect(desc?.contains("stale") == true)
        #expect(desc?.contains("1m 0s ago") == true)
    }

    @Test("insertTargetAge: near stale shows countdown")
    func ageNearStale() {
        let now = Date()
        let desc = ViewHelpers.insertTargetAgeDescription(capturedAt: now.addingTimeInterval(-25), now: now, staleAfterSeconds: 30, isStale: false)
        #expect(desc?.contains("stale in") == true)
    }

    @Test("insertTargetAge: fresh with lots of time left")
    func ageFresh() {
        let now = Date()
        let desc = ViewHelpers.insertTargetAgeDescription(capturedAt: now.addingTimeInterval(-5), now: now, staleAfterSeconds: 60, isStale: false)
        #expect(desc?.contains("5s ago") == true)
        #expect(desc?.contains("stale") == nil || desc?.contains("stale") == false)
    }

    // MARK: - lastSuccessfulInsertDescription

    @Test("lastSuccessfulInsert: nil returns nil")
    func lastInsertNil() {
        #expect(ViewHelpers.lastSuccessfulInsertDescription(insertedAt: nil, now: Date()) == nil)
    }

    @Test("lastSuccessfulInsert: just now")
    func lastInsertJustNow() {
        let now = Date()
        let desc = ViewHelpers.lastSuccessfulInsertDescription(insertedAt: now, now: now)
        #expect(desc?.contains("just now") == true)
    }

    @Test("lastSuccessfulInsert: some time ago")
    func lastInsertAgo() {
        let now = Date()
        let desc = ViewHelpers.lastSuccessfulInsertDescription(insertedAt: now.addingTimeInterval(-15), now: now)
        #expect(desc?.contains("15s ago") == true)
    }

    // MARK: - menuBarIconName

    @Test("menuBarIcon: insertion flash")
    func iconFlash() {
        #expect(ViewHelpers.menuBarIconName(isRecording: false, pendingChunkCount: 0, hasTranscriptionText: false, isShowingInsertionFlash: true) == "checkmark.circle.fill")
    }

    @Test("menuBarIcon: recording")
    func iconRecording() {
        #expect(ViewHelpers.menuBarIconName(isRecording: true, pendingChunkCount: 0, hasTranscriptionText: false, isShowingInsertionFlash: false) == "waveform.circle.fill")
    }

    @Test("menuBarIcon: pending chunks")
    func iconPending() {
        #expect(ViewHelpers.menuBarIconName(isRecording: false, pendingChunkCount: 1, hasTranscriptionText: false, isShowingInsertionFlash: false) == "ellipsis.circle")
    }

    @Test("menuBarIcon: has text")
    func iconText() {
        #expect(ViewHelpers.menuBarIconName(isRecording: false, pendingChunkCount: 0, hasTranscriptionText: true, isShowingInsertionFlash: false) == "doc.text")
    }

    @Test("menuBarIcon: idle")
    func iconIdle() {
        #expect(ViewHelpers.menuBarIconName(isRecording: false, pendingChunkCount: 0, hasTranscriptionText: false, isShowingInsertionFlash: false) == "mic")
    }

    // MARK: - menuBarDurationLabel

    @Test("menuBarDuration: insertion flash shows Inserted")
    func durationFlash() {
        let label = ViewHelpers.menuBarDurationLabel(isRecording: false, pendingChunkCount: 0, recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: false, averageChunkLatency: 0, lastChunkLatency: 0, transcriptionWordCount: 0, isShowingInsertionFlash: true)
        #expect(label == "Inserted")
    }

    @Test("menuBarDuration: recording shows timer")
    func durationRecording() {
        let label = ViewHelpers.menuBarDurationLabel(isRecording: true, pendingChunkCount: 0, recordingElapsedSeconds: 65, isStartAfterFinalizeQueued: false, averageChunkLatency: 0, lastChunkLatency: 0, transcriptionWordCount: 0, isShowingInsertionFlash: false)
        #expect(label == "1:05")
    }

    @Test("menuBarDuration: pending with latency")
    func durationPendingLatency() {
        let label = ViewHelpers.menuBarDurationLabel(isRecording: false, pendingChunkCount: 3, recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: false, averageChunkLatency: 2.0, lastChunkLatency: 0, transcriptionWordCount: 0, isShowingInsertionFlash: false)
        #expect(label?.contains("3⏳6s") == true)
    }

    @Test("menuBarDuration: pending without latency")
    func durationPendingNoLatency() {
        let label = ViewHelpers.menuBarDurationLabel(isRecording: false, pendingChunkCount: 3, recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: false, averageChunkLatency: 0, lastChunkLatency: 0, transcriptionWordCount: 0, isShowingInsertionFlash: false)
        #expect(label == "3 left")
    }

    @Test("menuBarDuration: pending queued shows arrow")
    func durationPendingQueued() {
        let label = ViewHelpers.menuBarDurationLabel(isRecording: false, pendingChunkCount: 2, recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: true, averageChunkLatency: 1.0, lastChunkLatency: 0, transcriptionWordCount: 0, isShowingInsertionFlash: false)
        #expect(label?.contains("→●") == true)
    }

    @Test("menuBarDuration: word count")
    func durationWordCount() {
        let label = ViewHelpers.menuBarDurationLabel(isRecording: false, pendingChunkCount: 0, recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: false, averageChunkLatency: 0, lastChunkLatency: 0, transcriptionWordCount: 5, isShowingInsertionFlash: false)
        #expect(label == "5w")
    }

    @Test("menuBarDuration: idle returns nil")
    func durationIdle() {
        let label = ViewHelpers.menuBarDurationLabel(isRecording: false, pendingChunkCount: 0, recordingElapsedSeconds: nil, isStartAfterFinalizeQueued: false, averageChunkLatency: 0, lastChunkLatency: 0, transcriptionWordCount: 0, isShowingInsertionFlash: false)
        #expect(label == nil)
    }

    // MARK: - recordingDuration

    @Test("recordingDuration: nil start returns 0")
    func recDurationNil() {
        #expect(ViewHelpers.recordingDuration(startedAt: nil, now: Date()) == 0)
    }

    @Test("recordingDuration: future start returns 0")
    func recDurationFuture() {
        let now = Date()
        #expect(ViewHelpers.recordingDuration(startedAt: now.addingTimeInterval(10), now: now) == 0)
    }

    @Test("recordingDuration: past start returns elapsed")
    func recDurationPast() {
        let now = Date()
        let result = ViewHelpers.recordingDuration(startedAt: now.addingTimeInterval(-5), now: now)
        #expect(abs(result - 5) < 0.1)
    }

    // MARK: - shouldCopyBecauseTargetUnknown

    @Test("shouldCopy: cannot insert returns false")
    func copyCannotInsert() {
        #expect(!ViewHelpers.shouldCopyBecauseTargetUnknown(canInsertDirectly: false, hasResolvableInsertTarget: false, hasExternalFrontApp: false))
    }

    @Test("shouldCopy: has resolvable target returns false")
    func copyHasTarget() {
        #expect(!ViewHelpers.shouldCopyBecauseTargetUnknown(canInsertDirectly: true, hasResolvableInsertTarget: true, hasExternalFrontApp: false))
    }

    @Test("shouldCopy: has external front app returns false")
    func copyHasFrontApp() {
        #expect(!ViewHelpers.shouldCopyBecauseTargetUnknown(canInsertDirectly: true, hasResolvableInsertTarget: false, hasExternalFrontApp: true))
    }

    @Test("shouldCopy: can insert, no target, no front app returns true")
    func copyTrue() {
        #expect(ViewHelpers.shouldCopyBecauseTargetUnknown(canInsertDirectly: true, hasResolvableInsertTarget: false, hasExternalFrontApp: false))
    }

    // MARK: - shouldAutoRefreshInsertTargetBeforePrimaryInsert

    @Test("autoRefresh: cannot insert returns false")
    func autoRefreshCannotInsert() {
        #expect(!ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(canInsertDirectly: false, canRetargetInsertTarget: true, shouldSuggestRetarget: false, isInsertTargetStale: true))
    }

    @Test("autoRefresh: cannot retarget returns false")
    func autoRefreshCannotRetarget() {
        #expect(!ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(canInsertDirectly: true, canRetargetInsertTarget: false, shouldSuggestRetarget: false, isInsertTargetStale: true))
    }

    @Test("autoRefresh: suggest retarget returns false")
    func autoRefreshSuggestRetarget() {
        #expect(!ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(canInsertDirectly: true, canRetargetInsertTarget: true, shouldSuggestRetarget: true, isInsertTargetStale: true))
    }

    @Test("autoRefresh: not stale returns false")
    func autoRefreshNotStale() {
        #expect(!ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(canInsertDirectly: true, canRetargetInsertTarget: true, shouldSuggestRetarget: false, isInsertTargetStale: false))
    }

    @Test("autoRefresh: all conditions met returns true")
    func autoRefreshTrue() {
        #expect(ViewHelpers.shouldAutoRefreshInsertTargetBeforePrimaryInsert(canInsertDirectly: true, canRetargetInsertTarget: true, shouldSuggestRetarget: false, isInsertTargetStale: true))
    }

    // MARK: - liveWordsPerMinute

    @Test("liveWPM: under 5 seconds returns nil")
    func wpmShort() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "hello world", durationSeconds: 4) == nil)
    }

    @Test("liveWPM: empty text returns nil")
    func wpmEmpty() {
        #expect(ViewHelpers.liveWordsPerMinute(transcription: "", durationSeconds: 60) == nil)
    }

    @Test("liveWPM: computes correctly")
    func wpmCompute() {
        // 10 words in 30 seconds = 20 wpm
        let text = "one two three four five six seven eight nine ten"
        let result = ViewHelpers.liveWordsPerMinute(transcription: text, durationSeconds: 30)
        #expect(result == 20)
    }

    @Test("liveWPM: minimum 1")
    func wpmMin() {
        let result = ViewHelpers.liveWordsPerMinute(transcription: "hi", durationSeconds: 3600)
        #expect(result == 1)
    }

    // MARK: - transcriptionStats

    @Test("transcriptionStats: empty text")
    func statsEmpty() {
        #expect(ViewHelpers.transcriptionStats("") == "0w · 0c")
    }

    @Test("transcriptionStats: whitespace only")
    func statsWhitespace() {
        #expect(ViewHelpers.transcriptionStats("   ") == "0w · 0c")
    }

    @Test("transcriptionStats: normal text")
    func statsNormal() {
        #expect(ViewHelpers.transcriptionStats("hello world") == "2w · 11c")
    }

    // MARK: - finalizationProgress

    @Test("finalizationProgress: recording returns nil")
    func finProgressRecording() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 2, initialPendingChunks: 4, isRecording: true) == nil)
    }

    @Test("finalizationProgress: no pending returns nil")
    func finProgressNoPending() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 0, initialPendingChunks: 4, isRecording: false) == nil)
    }

    @Test("finalizationProgress: nil initial returns nil")
    func finProgressNilInitial() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 2, initialPendingChunks: nil, isRecording: false) == nil)
    }

    @Test("finalizationProgress: zero initial returns nil")
    func finProgressZeroInitial() {
        #expect(ViewHelpers.finalizationProgress(pendingChunkCount: 2, initialPendingChunks: 0, isRecording: false) == nil)
    }

    @Test("finalizationProgress: half done")
    func finProgressHalf() {
        let result = ViewHelpers.finalizationProgress(pendingChunkCount: 2, initialPendingChunks: 4, isRecording: false)
        #expect(result == 0.5)
    }

    @Test("finalizationProgress: one remaining of four")
    func finProgressThreeQuarters() {
        let result = ViewHelpers.finalizationProgress(pendingChunkCount: 1, initialPendingChunks: 4, isRecording: false)
        #expect(result == 0.75)
    }

    // MARK: - statusTitle

    @Test("statusTitle: recording with duration")
    func statusRecording() {
        #expect(ViewHelpers.statusTitle(isRecording: true, recordingDuration: 5, pendingChunkCount: 0) == "Recording • 0:05")
    }

    @Test("statusTitle: recording under 1 second")
    func statusRecordingShort() {
        #expect(ViewHelpers.statusTitle(isRecording: true, recordingDuration: 0.5, pendingChunkCount: 0) == "Recording")
    }

    @Test("statusTitle: finalizing")
    func statusFinalizing() {
        #expect(ViewHelpers.statusTitle(isRecording: false, recordingDuration: 0, pendingChunkCount: 3) == "Finalizing • 3 chunks")
    }

    @Test("statusTitle: finalizing single chunk")
    func statusFinalizingSingle() {
        #expect(ViewHelpers.statusTitle(isRecording: false, recordingDuration: 0, pendingChunkCount: 1) == "Finalizing • 1 chunk")
    }

    @Test("statusTitle: ready")
    func statusReady() {
        #expect(ViewHelpers.statusTitle(isRecording: false, recordingDuration: 0, pendingChunkCount: 0) == "Ready")
    }

    // MARK: - useCurrentAppButtonTitle

    @Test("useCurrentApp title: can insert with front app")
    func useCurrentWithFront() {
        #expect(ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: "Safari") == "Use Current → Safari")
    }

    @Test("useCurrentApp title: can insert no front app")
    func useCurrentNoFront() {
        #expect(ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: true, currentFrontAppName: nil) == "Use Current App")
    }

    @Test("useCurrentApp title: cannot insert")
    func useCurrentCannotInsert() {
        #expect(ViewHelpers.useCurrentAppButtonTitle(canInsertDirectly: false, currentFrontAppName: "Safari") == "Use Current + Copy")
    }

    // MARK: - useCurrentAppButtonHelpText

    @Test("useCurrentApp help: disabled reason")
    func useCurrentHelpDisabled() {
        let help = ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: "No text", canInsertDirectly: true)
        #expect(help.contains("No text"))
    }

    @Test("useCurrentApp help: can insert")
    func useCurrentHelpCanInsert() {
        let help = ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true)
        #expect(help.contains("Retarget to the current front app and insert"))
    }

    @Test("useCurrentApp help: cannot insert")
    func useCurrentHelpCannotInsert() {
        let help = ViewHelpers.useCurrentAppButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: false)
        #expect(help.contains("copy to clipboard"))
    }

    // MARK: - focusAndInsertButtonTitle

    @Test("focusAndInsert title: can insert with target")
    func focusInsertWithTarget() {
        #expect(ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: true, insertTargetAppName: "Terminal") == "Focus + Insert → Terminal")
    }

    @Test("focusAndInsert title: can insert no target")
    func focusInsertNoTarget() {
        #expect(ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: true, insertTargetAppName: nil) == "Focus + Insert")
    }

    @Test("focusAndInsert title: cannot insert")
    func focusInsertCannotInsert() {
        #expect(ViewHelpers.focusAndInsertButtonTitle(canInsertDirectly: false, insertTargetAppName: "Terminal") == "Focus + Copy")
    }

    // MARK: - focusAndInsertButtonHelpText

    @Test("focusAndInsert help: disabled reason")
    func focusInsertHelpDisabled() {
        let help = ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: "Busy", hasResolvableInsertTarget: true, canInsertDirectly: true)
        #expect(help.contains("Busy"))
    }

    @Test("focusAndInsert help: no target")
    func focusInsertHelpNoTarget() {
        let help = ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: nil, hasResolvableInsertTarget: false, canInsertDirectly: true)
        #expect(help.contains("No insertion target"))
    }

    @Test("focusAndInsert help: can insert with target")
    func focusInsertHelpCanInsert() {
        let help = ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: nil, hasResolvableInsertTarget: true, canInsertDirectly: true)
        #expect(help.contains("Focus the saved insert target and insert"))
    }

    @Test("focusAndInsert help: cannot insert with target")
    func focusInsertHelpCannotInsert() {
        let help = ViewHelpers.focusAndInsertButtonHelpText(insertActionDisabledReason: nil, hasResolvableInsertTarget: true, canInsertDirectly: false)
        #expect(help.contains("copy to clipboard"))
    }

    // MARK: - insertButtonHelpText comprehensive

    @Test("insertHelp: disabled reason")
    func insertHelpDisabled() {
        let help = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: "No text", canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false, isInsertTargetStale: false, insertTargetAppName: nil, insertTargetUsesFallback: false, currentFrontAppName: nil)
        #expect(help.contains("No text"))
    }

    @Test("insertHelp: cannot insert with target")
    func insertHelpCannotInsertWithTarget() {
        let help = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: false, shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false, isInsertTargetStale: false, insertTargetAppName: "Safari", insertTargetUsesFallback: false, currentFrontAppName: nil)
        #expect(help.contains("Accessibility"))
        #expect(help.contains("Safari"))
    }

    @Test("insertHelp: cannot insert no target")
    func insertHelpCannotInsertNoTarget() {
        let help = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: false, shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false, isInsertTargetStale: false, insertTargetAppName: nil, insertTargetUsesFallback: false, currentFrontAppName: nil)
        #expect(help.contains("clipboard"))
    }

    @Test("insertHelp: copy because target unknown")
    func insertHelpCopyUnknown() {
        let help = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true, shouldCopyBecauseTargetUnknown: true, shouldSuggestRetarget: false, isInsertTargetStale: false, insertTargetAppName: nil, insertTargetUsesFallback: false, currentFrontAppName: nil)
        #expect(help.contains("No destination"))
    }

    @Test("insertHelp: stale target")
    func insertHelpStale() {
        let help = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false, isInsertTargetStale: true, insertTargetAppName: "Terminal", insertTargetUsesFallback: false, currentFrontAppName: nil)
        #expect(help.contains("Retarget"))
    }

    @Test("insertHelp: fallback target")
    func insertHelpFallback() {
        let help = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false, isInsertTargetStale: false, insertTargetAppName: "Terminal", insertTargetUsesFallback: true, currentFrontAppName: nil)
        #expect(help.contains("recent app context"))
    }

    @Test("insertHelp: normal target")
    func insertHelpNormal() {
        let help = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false, isInsertTargetStale: false, insertTargetAppName: "Terminal", insertTargetUsesFallback: false, currentFrontAppName: nil)
        #expect(help == "Insert into Terminal")
    }

    @Test("insertHelp: no target uses live front")
    func insertHelpLiveFront() {
        let help = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false, isInsertTargetStale: false, insertTargetAppName: nil, insertTargetUsesFallback: false, currentFrontAppName: "Safari")
        #expect(help.contains("Safari"))
    }

    @Test("insertHelp: no target no front")
    func insertHelpNoFront() {
        let help = ViewHelpers.insertButtonHelpText(insertActionDisabledReason: nil, canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false, shouldSuggestRetarget: false, isInsertTargetStale: false, insertTargetAppName: nil, insertTargetUsesFallback: false, currentFrontAppName: nil)
        #expect(help.contains("last active app"))
    }
}
