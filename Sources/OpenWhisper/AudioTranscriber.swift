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

    private let sampleRate: Double = 16_000
    private let chunkSeconds: Double = 4
    private let bufferQueue = DispatchQueue(label: "OpenWhisper.AudioBuffer")

    private var audioBuffer: [Float] = []
    private var pendingChunks: [[Float]] = []
    private var isTranscribing: Bool = false
    private var pendingSessionFinalize: Bool = false

    private let engine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private var whisper: Whisper?

    static let shared = AudioTranscriber()

    private init() {
        loadModel()
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
    func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { _ in }
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
        let normalized = applyTextReplacements(to: transcription).trimmingCharacters(in: .whitespacesAndNewlines)
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
        let normalized = applyTextReplacements(to: transcription).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return false }
        transcription = normalized

        guard copyToPasteboard(normalized) else { return false }
        guard pasteIntoFocusedApp() else {
            lastError = "Failed to paste into active app. Check Accessibility permissions."
            return false
        }

        appendHistoryEntry(normalized)
        statusMessage = "Inserted into active app"
        if UserDefaults.standard.bool(forKey: AppDefaults.Keys.outputClearAfterInsert) {
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
        pendingSessionFinalize = false
        pendingChunks.removeAll()

        bufferQueue.async { [weak self] in
            self?.audioBuffer.removeAll()
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
            lastError = "Failed to start audio engine: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func stopRecording() {
        guard isRecording else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRecording = false
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

            while self.audioBuffer.count >= chunkSize {
                let chunk = Array(self.audioBuffer.prefix(chunkSize))
                self.audioBuffer.removeFirst(chunkSize)
                Task { @MainActor in
                    self.queueTranscription(for: chunk)
                }
            }
        }
    }

    @MainActor
    private func queueTranscription(for samples: [Float]) {
        guard !samples.isEmpty else { return }
        pendingChunks.append(samples)
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

        Task {
            let text = await self.transcribe(samples: nextChunk)
            await MainActor.run {
                self.consumeTranscribedText(text)
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

    private func flushRemainingAudio() {
        bufferQueue.async { [weak self] in
            guard let self else { return }
            let remaining = self.audioBuffer
            self.audioBuffer.removeAll()

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
        pendingSessionFinalize = false
        inputLevel = 0

        let finalText = applyTextReplacements(to: transcription).trimmingCharacters(in: .whitespacesAndNewlines)
        transcription = finalText

        guard !finalText.isEmpty else {
            statusMessage = "Ready"
            return
        }

        appendHistoryEntry(finalText)

        let defaults = UserDefaults.standard
        let shouldAutoCopy = defaults.bool(forKey: AppDefaults.Keys.outputAutoCopy)
        let shouldAutoPaste = defaults.bool(forKey: AppDefaults.Keys.outputAutoPaste)
        let clearAfterInsert = defaults.bool(forKey: AppDefaults.Keys.outputClearAfterInsert)

        if shouldAutoCopy || shouldAutoPaste {
            _ = copyToPasteboard(finalText)
        }

        if shouldAutoPaste {
            if pasteIntoFocusedApp() {
                statusMessage = "Inserted into active app"
                if clearAfterInsert {
                    transcription = ""
                }
            } else {
                statusMessage = "Transcribed, paste failed"
                lastError = "Failed to paste into active app. Check Accessibility permissions."
            }
            return
        }

        statusMessage = shouldAutoCopy ? "Copied to clipboard" : "Ready"
    }

    @MainActor
    private func applyTextReplacements(to text: String) -> String {
        var output = text
        for replacement in replacementPairs() {
            output = output.replacingOccurrences(of: replacement.from, with: replacement.to)
        }
        return output
    }

    private func replacementPairs() -> [(from: String, to: String)] {
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
    @discardableResult
    private func copyToPasteboard(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }

    @MainActor
    @discardableResult
    private func pasteIntoFocusedApp() -> Bool {
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false) else {
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }

    private func loadModel() {
        guard let modelURL = Bundle.module.url(forResource: "ggml-tiny", withExtension: "bin") else {
            lastError = "Missing ggml-tiny.bin in Resources"
            return
        }

        if let size = (try? FileManager.default.attributesOfItem(atPath: modelURL.path)[.size]) as? NSNumber,
           size.intValue == 0 {
            lastError = "Model file is empty. Download ggml-tiny.bin from whisper.cpp releases."
            return
        }

        whisper = Whisper(fromFileURL: modelURL)
        statusMessage = "Model loaded"
    }
}
