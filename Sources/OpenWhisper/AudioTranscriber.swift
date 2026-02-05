import AVFoundation
import Foundation
import SwiftWhisper

final class AudioTranscriber: ObservableObject {
    @Published var transcription: String = ""
    @Published var isRecording: Bool = false
    @Published var statusMessage: String = "Idle"
    @Published var lastError: String? = nil

    private let sampleRate: Double = 16_000
    private let chunkSeconds: Double = 5
    private let bufferQueue = DispatchQueue(label: "OpenWhisper.AudioBuffer")
    private var audioBuffer: [Float] = []
    private var isTranscribing: Bool = false

    private let engine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private var whisper: Whisper?

    init() {
        loadModel()
    }

    func requestPermissions() {
        AVCaptureDevice.requestAccess(for: .audio) { _ in }
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        guard !isRecording else { return }

        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        guard status == .authorized else {
            statusMessage = "Microphone permission required"
            requestPermissions()
            return
        }

        let input = engine.inputNode
        let inputFormat = input.inputFormat(forBus: 0)
        let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: false)

        guard let targetFormat else {
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

    private func stopRecording() {
        guard isRecording else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRecording = false
        statusMessage = "Stopped"

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

    private func queueTranscription(for samples: [Float]) {
        guard !samples.isEmpty else { return }
        guard !isTranscribing else { return }
        isTranscribing = true

        Task {
            await self.transcribe(samples: samples)
            await MainActor.run {
                self.isTranscribing = false
            }
        }
    }

    private func transcribe(samples: [Float]) async {
        guard let whisper else {
            await MainActor.run {
                self.lastError = "Whisper model unavailable"
            }
            return
        }

        do {
            let segments = try await whisper.transcribe(audioFrames: samples)
            let text = segments.map { $0.text }.joined()
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await MainActor.run {
                    if self.transcription.isEmpty {
                        self.transcription = text
                    } else {
                        self.transcription += " " + text
                    }
                    self.statusMessage = "Transcribed \(segments.count) segment(s)"
                }
            }
        } catch {
            await MainActor.run {
                self.lastError = "Transcription failed: \(error.localizedDescription)"
            }
        }
    }

    private func flushRemainingAudio() {
        bufferQueue.async { [weak self] in
            guard let self else { return }
            let remaining = self.audioBuffer
            self.audioBuffer.removeAll()
            if !remaining.isEmpty {
                Task { @MainActor in
                    self.queueTranscription(for: remaining)
                }
            }
        }
    }

    private func loadModel() {
        guard let modelURL = Bundle.module.url(forResource: "ggml-tiny", withExtension: "bin") else {
            lastError = "Missing ggml-tiny.bin in Resources"
            return
        }

        if let size = (try? FileManager.default.attributesOfItem(atPath: modelURL.path)[.size]) as? NSNumber, size.intValue == 0 {
            lastError = "Model file is empty. Download ggml-tiny.bin from whisper.cpp releases."
            return
        }

        whisper = Whisper(fromFileURL: modelURL)
        statusMessage = "Model loaded"
    }
}
