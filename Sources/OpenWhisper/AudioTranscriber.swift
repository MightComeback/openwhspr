@preconcurrency import AVFoundation
@preconcurrency import AppKit
@preconcurrency import ApplicationServices
import Carbon.HIToolbox
import Foundation
import SwiftWhisper

final class AudioTranscriber: @unchecked Sendable, ObservableObject {
    @Published var transcription: String = ""
    @Published var recentEntries: [TranscriptionEntry] = []
    @Published var isRecording: Bool = false
    @Published var statusMessage: String = "Idle"
    @Published var lastError: String? = nil
    @Published var inputLevel: Float = 0
    @Published var modelStatusMessage: String = "Loading model…"
    @Published var modelWarning: String? = nil
    @Published var activeModelDisplayName: String = "Unavailable"
    @Published var activeModelPath: String = ""
    @Published var activeModelSource: ModelSource = .bundledTiny
    @Published var appProfiles: [AppProfile] = []
    @Published var frontmostAppName: String = "Unknown App"
    @Published var frontmostBundleIdentifier: String = ""
    @Published var pendingChunkCount: Int = 0
    @Published var processedChunkCount: Int = 0
    @Published var lastChunkLatencySeconds: Double = 0
    @Published var recordingStartedAt: Date? = nil

    private var recordingOutputSettings: EffectiveOutputSettings? = nil
    private var insertionTargetApp: NSRunningApplication?
    private var lastKnownExternalApp: NSRunningApplication?
    private var workspaceActivationObserver: NSObjectProtocol?

    private let sampleRate: Double = 16_000
    private let chunkSeconds: Double = 4
    private let bufferQueue = DispatchQueue(label: "OpenWhisper.AudioBuffer")

    private var audioBuffer: [Float] = []
    private var audioBufferHead: Int = 0
    private var pendingChunks: [[Float]] = []
    private var pendingChunkEnqueueTimes: [Date] = []
    private var isTranscribing: Bool = false
    private var pendingSessionFinalize: Bool = false

    private let engine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private var whisper: Whisper?

    static let shared = AudioTranscriber()

    struct EffectiveOutputSettings {
        var autoCopy: Bool
        var autoPaste: Bool
        var clearAfterInsert: Bool
        var commandReplacements: Bool
        var smartCapitalization: Bool
        var terminalPunctuation: Bool
        var customCommandsRaw: String
    }

    private init() {
        Task { @MainActor in
            self.registerWorkspaceActivationObserver()
            self.reloadProfiles()
            self.refreshFrontmostAppContext()
            self.reloadConfiguredModel()
        }
    }

    deinit {
        if let observer = workspaceActivationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    @MainActor
    func clearTranscription() {
        transcription = ""
        lastError = nil
    }

    @MainActor
    func clearHistory() {
        recentEntries.removeAll()
    }

    @MainActor
    private func registerWorkspaceActivationObserver() {
        if let existing = workspaceActivationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(existing)
        }

        workspaceActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            guard app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return }
            self.lastKnownExternalApp = app
        }
    }

    @MainActor
    func refreshFrontmostAppContext() {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            frontmostAppName = "Unknown App"
            frontmostBundleIdentifier = ""
            return
        }

        frontmostAppName = app.localizedName ?? "Unknown App"
        frontmostBundleIdentifier = app.bundleIdentifier ?? ""

        if app.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            lastKnownExternalApp = app
        }
    }

    @MainActor
    private func captureInsertionTargetApp() {
        if let app = NSWorkspace.shared.frontmostApplication,
           app.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            insertionTargetApp = app
            lastKnownExternalApp = app
            return
        }

        if let fallback = lastKnownExternalApp,
           fallback.isTerminated == false {
            insertionTargetApp = fallback
            return
        }

        insertionTargetApp = nil
    }

    @MainActor
    func captureProfileForFrontmostApp() {
        refreshFrontmostAppContext()
        guard !frontmostBundleIdentifier.isEmpty else {
            lastError = "Cannot capture profile: frontmost app has no bundle identifier."
            return
        }

        let currentDefaults = defaultOutputSettings()
        let profile = AppProfile(
            bundleIdentifier: frontmostBundleIdentifier,
            appName: frontmostAppName,
            autoCopy: currentDefaults.autoCopy,
            autoPaste: currentDefaults.autoPaste,
            clearAfterInsert: currentDefaults.clearAfterInsert,
            commandReplacements: currentDefaults.commandReplacements,
            smartCapitalization: currentDefaults.smartCapitalization,
            terminalPunctuation: currentDefaults.terminalPunctuation,
            customCommands: ""
        )

        if let index = appProfiles.firstIndex(where: { $0.bundleIdentifier == profile.bundleIdentifier }) {
            appProfiles[index] = profile
        } else {
            appProfiles.append(profile)
        }

        appProfiles.sort { $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending }
        persistProfiles()
        statusMessage = "Saved profile for \(profile.appName)"
        lastError = nil
    }

    @MainActor
    func updateProfile(_ profile: AppProfile) {
        guard let index = appProfiles.firstIndex(where: { $0.bundleIdentifier == profile.bundleIdentifier }) else {
            return
        }
        appProfiles[index] = profile
        appProfiles.sort { $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending }
        persistProfiles()
    }

    @MainActor
    func removeProfile(bundleIdentifier: String) {
        appProfiles.removeAll { $0.bundleIdentifier == bundleIdentifier }
        persistProfiles()
    }

    @MainActor
    func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { _ in }
    }

    @MainActor
    func reloadConfiguredModel() {
        if isRecording {
            stopRecording()
        }
        loadConfiguredModel()
    }

    @MainActor
    func setModelSource(_ source: ModelSource) {
        UserDefaults.standard.set(source.rawValue, forKey: AppDefaults.Keys.modelSource)
        if source == .bundledTiny {
            modelWarning = nil
        }
        reloadConfiguredModel()
    }

    @MainActor
    func setCustomModelPath(_ path: String) {
        let normalized = path.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(normalized, forKey: AppDefaults.Keys.modelCustomPath)
        UserDefaults.standard.set(ModelSource.customPath.rawValue, forKey: AppDefaults.Keys.modelSource)
        reloadConfiguredModel()
    }

    @MainActor
    func clearCustomModelPath() {
        UserDefaults.standard.set("", forKey: AppDefaults.Keys.modelCustomPath)
        reloadConfiguredModel()
    }

    @MainActor
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    @MainActor
    func startRecordingFromHotkey() {
        guard !isRecording else { return }
        startRecording()
    }

    @MainActor
    func stopRecordingFromHotkey() {
        guard isRecording else { return }
        stopRecording()
    }

    @MainActor
    @discardableResult
    func copyTranscriptionToClipboard() -> Bool {
        let settings = effectiveOutputSettingsForCurrentApp()
        let normalized = normalizeOutputText(transcription, settings: settings)
        guard !normalized.isEmpty else { return false }
        transcription = normalized
        let copied = copyToPasteboard(normalized)
        if copied {
            statusMessage = "Copied to clipboard"
        }
        return copied
    }

    @MainActor
    @discardableResult
    func insertTranscriptionIntoFocusedApp() -> Bool {
        let settings = effectiveOutputSettingsForCurrentApp()
        let normalized = normalizeOutputText(transcription, settings: settings)
        guard !normalized.isEmpty else { return false }
        transcription = normalized

        // Manual insert should target the app currently in front, not the app
        // that happened to be active when recording started.
        captureInsertionTargetApp()
        let resolvedTargetName = resolveInsertionTargetApp()?.localizedName

        let pasted = withTemporaryPasteboardString(normalized) {
            pasteIntoFocusedApp()
        }

        guard pasted else {
            if let resolvedTargetName, !resolvedTargetName.isEmpty {
                lastError = "Failed to paste into \(resolvedTargetName). Check Accessibility permissions."
            } else {
                lastError = "Failed to paste into active app. Check Accessibility permissions."
            }
            return false
        }

        appendHistoryEntry(normalized)
        lastError = nil
        if let resolvedTargetName, !resolvedTargetName.isEmpty {
            statusMessage = "Inserted into \(resolvedTargetName)"
        } else {
            statusMessage = "Inserted into active app"
        }
        if settings.clearAfterInsert {
            transcription = ""
        }
        return true
    }

    @MainActor
    private func startRecording() {
        guard whisper != nil else {
            statusMessage = "Model unavailable"
            return
        }

        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        guard status == .authorized else {
            statusMessage = "Microphone permission required"
            requestMicrophonePermission()
            return
        }

        lastError = nil
        inputLevel = 0
        captureInsertionTargetApp()
        recordingOutputSettings = effectiveOutputSettingsForCurrentApp()
        pendingSessionFinalize = false
        pendingChunks.removeAll()
        pendingChunkEnqueueTimes.removeAll()
        pendingChunkCount = 0
        processedChunkCount = 0
        lastChunkLatencySeconds = 0
        recordingStartedAt = Date()

        bufferQueue.async { [weak self] in
            self?.audioBuffer.removeAll(keepingCapacity: true)
            self?.audioBufferHead = 0
        }

        let input = engine.inputNode
        let inputFormat = input.inputFormat(forBus: 0)
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            lastError = "Failed to create target audio format"
            return
        }

        converter = AVAudioConverter(from: inputFormat, to: targetFormat)

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.process(buffer: buffer, targetFormat: targetFormat)
        }

        do {
            try engine.start()
            isRecording = true
            statusMessage = "Listening…"
        } catch {
            recordingStartedAt = nil
            recordingOutputSettings = nil
            lastError = "Failed to start audio engine: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func stopRecording() {
        guard isRecording else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRecording = false
        recordingStartedAt = nil
        statusMessage = "Finalizing…"
        flushRemainingAudio()
    }

    private func process(buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
        guard let converter else { return }

        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }

        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        converter.convert(to: pcmBuffer, error: &error, withInputFrom: inputBlock)

        if let error {
            Task { @MainActor in
                self.lastError = "Audio conversion failed: \(error.localizedDescription)"
            }
            return
        }

        guard let channel = pcmBuffer.floatChannelData?.pointee else { return }
        let frameCount = Int(pcmBuffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channel, count: frameCount))

        if frameCount > 0 {
            let averageEnergy = samples.reduce(Float.zero) { partial, sample in
                partial + (sample * sample)
            } / Float(frameCount)
            let level = min(max(sqrt(averageEnergy) * 6.5, 0), 1)
            Task { @MainActor in
                self.inputLevel = level
            }
        }

        bufferQueue.async { [weak self] in
            guard let self else { return }
            self.audioBuffer.append(contentsOf: samples)
            let chunkSize = Int(self.sampleRate * self.chunkSeconds)

            while (self.audioBuffer.count - self.audioBufferHead) >= chunkSize {
                let start = self.audioBufferHead
                let end = start + chunkSize
                let chunk = Array(self.audioBuffer[start..<end])
                self.audioBufferHead = end
                Task { @MainActor in
                    self.queueTranscription(for: chunk)
                }
            }

            self.compactAudioBufferIfNeeded()
        }
    }

    @MainActor
    private func queueTranscription(for samples: [Float]) {
        guard !samples.isEmpty else { return }
        pendingChunks.append(samples)
        pendingChunkEnqueueTimes.append(Date())
        pendingChunkCount = pendingChunks.count
        processTranscriptionQueueIfNeeded()
    }

    @MainActor
    private func processTranscriptionQueueIfNeeded() {
        guard !isTranscribing else { return }

        guard !pendingChunks.isEmpty else {
            if pendingSessionFinalize {
                finalizeSessionIfNeeded()
            }
            return
        }

        isTranscribing = true
        let nextChunk = pendingChunks.removeFirst()
        let queuedAt = pendingChunkEnqueueTimes.isEmpty ? Date() : pendingChunkEnqueueTimes.removeFirst()
        pendingChunkCount = pendingChunks.count

        Task {
            let text = await self.transcribe(samples: nextChunk)
            await MainActor.run {
                self.consumeTranscribedText(text)
                self.processedChunkCount += 1
                self.lastChunkLatencySeconds = max(0, Date().timeIntervalSince(queuedAt))
                self.isTranscribing = false
                self.processTranscriptionQueueIfNeeded()
            }
        }
    }

    private func transcribe(samples: [Float]) async -> String {
        guard let whisper else {
            await MainActor.run {
                self.lastError = "Whisper model unavailable"
            }
            return ""
        }

        do {
            let segments = try await whisper.transcribe(audioFrames: samples)
            return segments
                .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            await MainActor.run {
                self.lastError = "Transcription failed: \(error.localizedDescription)"
            }
            return ""
        }
    }

    @MainActor
    private func consumeTranscribedText(_ text: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        if transcription.isEmpty {
            transcription = cleaned
        } else if transcription.hasSuffix(" ") {
            transcription += cleaned
        } else {
            transcription += " \(cleaned)"
        }

        statusMessage = "Transcribing…"
    }

    private func compactAudioBufferIfNeeded() {
        guard audioBufferHead > 0 else { return }

        // Avoid O(n) removeFirst on every chunk. Instead consume with a head index
        // and compact occasionally once enough prefix data has been consumed.
        let shouldCompact = audioBufferHead >= 16_000 && audioBufferHead >= (audioBuffer.count / 2)
        guard shouldCompact else { return }

        audioBuffer.removeFirst(audioBufferHead)
        audioBufferHead = 0
    }

    private func flushRemainingAudio() {
        bufferQueue.async { [weak self] in
            guard let self else { return }

            let remaining: [Float]
            if self.audioBufferHead < self.audioBuffer.count {
                remaining = Array(self.audioBuffer[self.audioBufferHead..<self.audioBuffer.count])
            } else {
                remaining = []
            }

            self.audioBuffer.removeAll(keepingCapacity: true)
            self.audioBufferHead = 0

            Task { @MainActor in
                if !remaining.isEmpty {
                    self.queueTranscription(for: remaining)
                }
                self.pendingSessionFinalize = true
                self.processTranscriptionQueueIfNeeded()
            }
        }
    }

    @MainActor
    private func finalizeSessionIfNeeded() {
        defer { recordingOutputSettings = nil }
        pendingSessionFinalize = false
        inputLevel = 0
        pendingChunkCount = 0

        let settings = recordingOutputSettings ?? effectiveOutputSettingsForCurrentApp()
        let finalText = normalizeOutputText(transcription, settings: settings)
        transcription = finalText

        guard !finalText.isEmpty else {
            statusMessage = "Ready"
            return
        }

        appendHistoryEntry(finalText)

        let shouldAutoCopy = settings.autoCopy
        let shouldAutoPaste = settings.autoPaste
        let clearAfterInsert = settings.clearAfterInsert

        if shouldAutoCopy || shouldAutoPaste {
            _ = copyToPasteboard(finalText)
        }

        if shouldAutoPaste {
            let resolvedTargetName = resolveInsertionTargetApp()?.localizedName

            if pasteIntoFocusedApp() {
                lastError = nil
                if let resolvedTargetName, !resolvedTargetName.isEmpty {
                    statusMessage = "Inserted into \(resolvedTargetName)"
                } else {
                    statusMessage = "Inserted into active app"
                }
                if clearAfterInsert {
                    transcription = ""
                }
            } else {
                statusMessage = "Transcribed, paste failed"
                if let resolvedTargetName, !resolvedTargetName.isEmpty {
                    lastError = "Failed to paste into \(resolvedTargetName). Check Accessibility permissions."
                } else {
                    lastError = "Failed to paste into active app. Check Accessibility permissions."
                }
            }
            return
        }

        lastError = nil
        statusMessage = shouldAutoCopy ? "Copied to clipboard" : "Ready"
    }

    @MainActor
    func normalizeOutputText(_ text: String, settings: EffectiveOutputSettings) -> String {
        var output = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !output.isEmpty else { return "" }

        if settings.commandReplacements {
            output = applyCommandReplacements(to: output, settings: settings)
        }

        output = applyTextReplacements(to: output)
        output = normalizeWhitespace(in: output)

        if settings.smartCapitalization {
            output = applySmartCapitalization(to: output)
        }

        if settings.terminalPunctuation {
            output = applyTerminalPunctuationIfNeeded(to: output)
        }

        return output.trimmingCharacters(in: .whitespaces)
    }

    func applyCommandReplacements(to text: String, settings: EffectiveOutputSettings) -> String {
        var output = text

        var rules = BuiltInCommandRules.all
        rules.append(contentsOf: CommandRuleParser.parse(raw: settings.customCommandsRaw))
        rules.sort { $0.phrase.count > $1.phrase.count }

        for rule in rules {
            let tokens = rule.phrase
                .split(separator: " ")
                .map { NSRegularExpression.escapedPattern(for: String($0)) }
                .joined(separator: "\\s+")
            let pattern = "(?i)\\b\(tokens)\\b"
            output = replaceRegex(pattern: pattern, in: output, with: rule.replacement)
        }

        return output
    }

    func normalizeWhitespace(in text: String) -> String {
        var output = text
        output = replaceRegex(pattern: "[\\t ]+", in: output, with: " ")
        output = replaceRegex(pattern: " *\\n *", in: output, with: "\n")
        output = replaceRegex(pattern: "\\n{3,}", in: output, with: "\n\n")
        output = replaceRegex(pattern: "\\s+([,.;:!?])", in: output, with: "$1")
        return output
    }

    func applySmartCapitalization(to text: String) -> String {
        var output = ""
        output.reserveCapacity(text.count)

        var shouldCapitalize = true
        for character in text {
            if shouldCapitalize, isLetter(character) {
                output.append(contentsOf: String(character).uppercased())
                shouldCapitalize = false
                continue
            }

            output.append(character)

            if character == "." || character == "!" || character == "?" || character == "\n" {
                shouldCapitalize = true
            } else if !character.isWhitespace {
                shouldCapitalize = false
            }
        }

        return output
    }

    func applyTerminalPunctuationIfNeeded(to text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let lastCharacter = trimmed.last else { return trimmed }

        if [".", "!", "?", ":", ";"].contains(lastCharacter) {
            return trimmed
        }

        if lastCharacter == "\n" {
            return trimmed
        }

        if isLetter(lastCharacter) || lastCharacter.isNumber {
            return trimmed + "."
        }

        return trimmed
    }

    func replaceRegex(pattern: String, in text: String, with template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return text
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let literalTemplate = NSRegularExpression.escapedTemplate(for: template)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: literalTemplate)
    }

    func isLetter(_ character: Character) -> Bool {
        character.unicodeScalars.contains { CharacterSet.letters.contains($0) }
    }

    @MainActor
    func effectiveOutputSettingsForCurrentApp() -> EffectiveOutputSettings {
        refreshFrontmostAppContext()
        let defaults = defaultOutputSettings()

        guard !frontmostBundleIdentifier.isEmpty,
              let profile = appProfiles.first(where: { $0.bundleIdentifier == frontmostBundleIdentifier }) else {
            return defaults
        }

        return resolveOutputSettings(defaults: defaults, profile: profile)
    }

    func defaultOutputSettings() -> EffectiveOutputSettings {
        let defaults = UserDefaults.standard
        return EffectiveOutputSettings(
            autoCopy: defaults.bool(forKey: AppDefaults.Keys.outputAutoCopy),
            autoPaste: defaults.bool(forKey: AppDefaults.Keys.outputAutoPaste),
            clearAfterInsert: defaults.bool(forKey: AppDefaults.Keys.outputClearAfterInsert),
            commandReplacements: defaults.bool(forKey: AppDefaults.Keys.outputCommandReplacements),
            smartCapitalization: defaults.bool(forKey: AppDefaults.Keys.outputSmartCapitalization),
            terminalPunctuation: defaults.bool(forKey: AppDefaults.Keys.outputTerminalPunctuation),
            customCommandsRaw: defaults.string(forKey: AppDefaults.Keys.outputCustomCommands) ?? ""
        )
    }

    @MainActor
    func applyTextReplacements(to text: String) -> String {
        var output = text
        for replacement in replacementPairs() {
            output = output.replacingOccurrences(of: replacement.from, with: replacement.to)
        }
        return output
    }

    func replacementPairs() -> [(from: String, to: String)] {
        let raw = UserDefaults.standard.string(forKey: AppDefaults.Keys.transcriptionReplacements) ?? ""
        let lines = raw.components(separatedBy: .newlines)
        var pairs: [(from: String, to: String)] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            if let range = trimmed.range(of: "=>") {
                let from = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let to = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !from.isEmpty {
                    pairs.append((from: from, to: to))
                }
                continue
            }

            if let range = trimmed.range(of: "=") {
                let from = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let to = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !from.isEmpty {
                    pairs.append((from: from, to: to))
                }
            }
        }

        return pairs
    }

    @MainActor
    private func appendHistoryEntry(_ text: String) {
        if recentEntries.first?.text == text {
            return
        }

        recentEntries.insert(TranscriptionEntry(text: text), at: 0)
        let configuredLimit = UserDefaults.standard.integer(forKey: AppDefaults.Keys.transcriptionHistoryLimit)
        let maxEntries = max(1, configuredLimit)
        if recentEntries.count > maxEntries {
            recentEntries = Array(recentEntries.prefix(maxEntries))
        }
    }

    @MainActor
    private func withTemporaryPasteboardString(_ text: String, perform: () -> Bool) -> Bool {
        guard !text.isEmpty else { return false }

        let pasteboard = NSPasteboard.general
        let originalItems = pasteboard.pasteboardItems

        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else { return false }

        let result = perform()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let pb = NSPasteboard.general

            // Restore the previous clipboard contents if we still appear to "own" the pasteboard.
            // Some apps can mutate the pasteboard during paste (bumping changeCount) without the
            // user actually copying something new. Checking the current string is a safer heuristic.
            let currentString = pb.string(forType: .string)
            guard currentString == text else { return }

            pb.clearContents()
            if let originalItems {
                _ = pb.writeObjects(originalItems)
            }
        }

        return result
    }

    @MainActor
    @discardableResult
    private func copyToPasteboard(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }

    @MainActor
    private func resolveInsertionTargetApp() -> NSRunningApplication? {
        if insertionTargetApp?.isTerminated != false,
           let fallback = lastKnownExternalApp,
           fallback.isTerminated == false {
            insertionTargetApp = fallback
        }

        if insertionTargetApp?.isTerminated != false,
           let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            insertionTargetApp = frontmost
            lastKnownExternalApp = frontmost
        }

        guard let targetApp = insertionTargetApp,
              targetApp.isTerminated == false else {
            return nil
        }

        return targetApp
    }

    @MainActor
    @discardableResult
    private func pasteIntoFocusedApp() -> Bool {
        guard let targetApp = resolveInsertionTargetApp() else {
            return false
        }

        let targetPID = targetApp.processIdentifier

        _ = targetApp.activate()
        _ = waitForFrontmostApp(pid: targetPID, timeout: 0.2)

        if NSWorkspace.shared.frontmostApplication?.processIdentifier != targetPID {
            _ = targetApp.activate()
            _ = waitForFrontmostApp(pid: targetPID, timeout: 0.35)
        }

        guard postPasteKeystroke() else {
            return false
        }

        return true
    }

    @MainActor
    private func postPasteKeystroke() -> Bool {
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false) else {
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        // Some apps are flaky if the key down/up events are posted back-to-back.
        // A tiny delay makes insertion noticeably more reliable without impacting UX.
        keyDown.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.01)
        keyUp.post(tap: .cghidEventTap)
        return true
    }

    @MainActor
    private func waitForFrontmostApp(pid: pid_t, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if NSWorkspace.shared.frontmostApplication?.processIdentifier == pid {
                return true
            }
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01))
        }
        return NSWorkspace.shared.frontmostApplication?.processIdentifier == pid
    }

    @MainActor
    private func reloadProfiles() {
        let raw = UserDefaults.standard.string(forKey: AppDefaults.Keys.appProfiles) ?? "[]"
        guard let data = raw.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([AppProfile].self, from: data) else {
            appProfiles = []
            return
        }
        appProfiles = decoded.sorted { $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending }
    }

    @MainActor
    private func persistProfiles() {
        guard let data = try? JSONEncoder().encode(appProfiles),
              let json = String(data: data, encoding: .utf8) else {
            return
        }
        UserDefaults.standard.set(json, forKey: AppDefaults.Keys.appProfiles)
    }

    @MainActor
    private func loadConfiguredModel() {
        let resolved = resolveConfiguredModelURL()
        activeModelSource = resolved.loadedSource
        modelWarning = resolved.warning

        guard let modelURL = resolved.url else {
            whisper = nil
            activeModelDisplayName = "Unavailable"
            activeModelPath = ""
            modelStatusMessage = "No usable model file found"
            lastError = "Missing bundled model and custom model path is invalid."
            statusMessage = "Model unavailable"
            return
        }

        guard isReadableModelFile(at: modelURL) else {
            whisper = nil
            activeModelDisplayName = modelURL.lastPathComponent
            activeModelPath = modelURL.path
            modelStatusMessage = "Model file is invalid or unreadable"
            lastError = "Model file is invalid: \(modelURL.path)"
            statusMessage = "Model unavailable"
            return
        }

        whisper = Whisper(fromFileURL: modelURL)
        activeModelDisplayName = modelURL.lastPathComponent
        activeModelPath = modelURL.path
        modelStatusMessage = "Loaded \(modelURL.lastPathComponent)"
        if resolved.warning == nil {
            lastError = nil
        }
        if let warning = resolved.warning {
            statusMessage = warning
        } else {
            statusMessage = "Model loaded"
        }
    }

    func resolveConfiguredModelURL() -> (url: URL?, loadedSource: ModelSource, warning: String?) {
        let defaults = UserDefaults.standard
        let selectedSourceRaw = defaults.string(forKey: AppDefaults.Keys.modelSource) ?? ModelSource.bundledTiny.rawValue
        let selectedSource = ModelSource(rawValue: selectedSourceRaw) ?? .bundledTiny

        if selectedSource == .customPath {
            let customPath = (defaults.string(forKey: AppDefaults.Keys.modelCustomPath) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !customPath.isEmpty, let customURL = validFileURL(for: customPath) {
                return (customURL, .customPath, nil)
            }

            let warning: String
            if customPath.isEmpty {
                warning = "Custom model path is empty. Using bundled model."
            } else {
                warning = "Custom model not found at \(customPath). Using bundled model."
            }

            if let bundled = bundledModelURL() {
                return (bundled, .bundledTiny, warning)
            }

            return (nil, .customPath, warning)
        }

        if let bundled = bundledModelURL() {
            return (bundled, .bundledTiny, nil)
        }

        return (nil, .bundledTiny, "Bundled model is missing.")
    }

    private func bundledModelURL() -> URL? {
        Bundle.module.url(forResource: "ggml-tiny", withExtension: "bin")
    }

    func validFileURL(for path: String) -> URL? {
        var isDirectory = ObjCBool(false)
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), !isDirectory.boolValue else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }

    func isReadableModelFile(at url: URL) -> Bool {
        guard FileManager.default.isReadableFile(atPath: url.path) else { return false }
        if let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size]) as? NSNumber,
           size.intValue > 0 {
            return true
        }
        return false
    }

    func resolveOutputSettings(defaults: EffectiveOutputSettings, profile: AppProfile?) -> EffectiveOutputSettings {
        guard let profile else { return defaults }

        let combinedCustomCommands: String
        if defaults.customCommandsRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            combinedCustomCommands = profile.customCommands
        } else if profile.customCommands.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            combinedCustomCommands = defaults.customCommandsRaw
        } else {
            combinedCustomCommands = defaults.customCommandsRaw + "\n" + profile.customCommands
        }

        return EffectiveOutputSettings(
            autoCopy: profile.autoCopy,
            autoPaste: profile.autoPaste,
            clearAfterInsert: profile.clearAfterInsert,
            commandReplacements: profile.commandReplacements,
            smartCapitalization: profile.smartCapitalization,
            terminalPunctuation: profile.terminalPunctuation,
            customCommandsRaw: combinedCustomCommands
        )
    }
}
