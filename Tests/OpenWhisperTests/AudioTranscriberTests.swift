import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber")
struct AudioTranscriberSwiftTests {
    @MainActor
    private func withStandardDefaults(_ values: [String: Any], _ body: @MainActor () async throws -> Void) async rethrows {
        let defaults = UserDefaults.standard
        var previous: [String: Any?] = [:]
        for (key, value) in values {
            previous[key] = defaults.object(forKey: key)
            defaults.set(value, forKey: key)
        }
        defer {
            for (key, value) in previous {
                if let value {
                    defaults.set(value, forKey: key)
                } else {
                    defaults.removeObject(forKey: key)
                }
            }
        }
        try await body()
    }

    @Test
    func resolveConfiguredModelURLUsesBundledWhenCustomMissing() async throws {
        try await withStandardDefaults([
            AppDefaults.Keys.modelSource: ModelSource.customPath.rawValue,
            AppDefaults.Keys.modelCustomPath: ""
        ]) {
            let transcriber = AudioTranscriber.shared
            let resolved = transcriber.resolveConfiguredModelURL()
            #expect(resolved.loadedSource == .bundledTiny)
            #expect(resolved.url != nil)
            #expect(resolved.warning != nil)
        }
    }

    @Test
    func resolveConfiguredModelURLUsesCustomWhenValid() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try "model".data(using: .utf8)!.write(to: tempURL)

        try await withStandardDefaults([
            AppDefaults.Keys.modelSource: ModelSource.customPath.rawValue,
            AppDefaults.Keys.modelCustomPath: tempURL.path
        ]) {
            let transcriber = AudioTranscriber.shared
            let resolved = transcriber.resolveConfiguredModelURL()
            #expect(resolved.loadedSource == .customPath)
            #expect(resolved.url?.path == tempURL.path)
            #expect(resolved.warning == nil)
        }
    }

    @Test
    func resolveConfiguredModelURLWarnsOnInvalidPath() async throws {
        let invalidPath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try await withStandardDefaults([
            AppDefaults.Keys.modelSource: ModelSource.customPath.rawValue,
            AppDefaults.Keys.modelCustomPath: invalidPath
        ]) {
            let transcriber = AudioTranscriber.shared
            let resolved = transcriber.resolveConfiguredModelURL()
            #expect(resolved.loadedSource == .bundledTiny)
            #expect(resolved.warning != nil)
        }
    }

    @Test
    func isReadableModelFileRejectsEmptyFile() throws {
        let transcriber = AudioTranscriber.shared
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        FileManager.default.createFile(atPath: tempURL.path, contents: Data(), attributes: nil)
        #expect(!transcriber.isReadableModelFile(at: tempURL))
    }

    @Test @MainActor
    func normalizeOutputTextAppliesCommandReplacement() async throws {
        try await withStandardDefaults([
            AppDefaults.Keys.transcriptionReplacements: "",
            AppDefaults.Keys.outputCommandReplacements: true
        ]) {
            let transcriber = AudioTranscriber.shared
            let settings = AudioTranscriber.EffectiveOutputSettings(
                autoCopy: false,
                autoPaste: false,
                clearAfterInsert: false,
                commandReplacements: true,
                smartCapitalization: false,
                terminalPunctuation: false,
                customCommandsRaw: ""
            )
            let output = transcriber.normalizeOutputText("new line", settings: settings)
            #expect(output == "\n")
        }
    }

    @Test @MainActor
    func normalizeOutputTextAppliesSmartCapitalization() async throws {
        try await withStandardDefaults([
            AppDefaults.Keys.transcriptionReplacements: ""
        ]) {
            let transcriber = AudioTranscriber.shared
            let settings = AudioTranscriber.EffectiveOutputSettings(
                autoCopy: false,
                autoPaste: false,
                clearAfterInsert: false,
                commandReplacements: false,
                smartCapitalization: true,
                terminalPunctuation: false,
                customCommandsRaw: ""
            )
            let output = transcriber.normalizeOutputText("hello. world", settings: settings)
            #expect(output == "Hello. World")
        }
    }

    @Test @MainActor
    func normalizeOutputTextAppliesTerminalPunctuation() async throws {
        try await withStandardDefaults([
            AppDefaults.Keys.transcriptionReplacements: ""
        ]) {
            let transcriber = AudioTranscriber.shared
            let settings = AudioTranscriber.EffectiveOutputSettings(
                autoCopy: false,
                autoPaste: false,
                clearAfterInsert: false,
                commandReplacements: false,
                smartCapitalization: false,
                terminalPunctuation: true,
                customCommandsRaw: ""
            )
            let output = transcriber.normalizeOutputText("hello", settings: settings)
            #expect(output == "hello.")
        }
    }

    @Test @MainActor
    func normalizeOutputTextDoesNotDuplicateTerminalPunctuation() async throws {
        try await withStandardDefaults([
            AppDefaults.Keys.transcriptionReplacements: ""
        ]) {
            let transcriber = AudioTranscriber.shared
            let settings = AudioTranscriber.EffectiveOutputSettings(
                autoCopy: false,
                autoPaste: false,
                clearAfterInsert: false,
                commandReplacements: false,
                smartCapitalization: false,
                terminalPunctuation: true,
                customCommandsRaw: ""
            )
            let output = transcriber.normalizeOutputText("hello!", settings: settings)
            #expect(output == "hello!")
        }
    }

    @Test @MainActor
    func normalizeOutputTextTreatsEllipsisAsTerminalPunctuation() async throws {
        try await withStandardDefaults([
            AppDefaults.Keys.transcriptionReplacements: ""
        ]) {
            let transcriber = AudioTranscriber.shared
            let settings = AudioTranscriber.EffectiveOutputSettings(
                autoCopy: false,
                autoPaste: false,
                clearAfterInsert: false,
                commandReplacements: false,
                smartCapitalization: false,
                terminalPunctuation: true,
                customCommandsRaw: ""
            )
            let output = transcriber.normalizeOutputText("hello…", settings: settings)
            #expect(output == "hello…")
        }
    }

    @Test @MainActor
    func normalizeOutputTextAppliesTextReplacements() async throws {
        try await withStandardDefaults([
            AppDefaults.Keys.transcriptionReplacements: "foo=bar"
        ]) {
            let transcriber = AudioTranscriber.shared
            let settings = AudioTranscriber.EffectiveOutputSettings(
                autoCopy: false,
                autoPaste: false,
                clearAfterInsert: false,
                commandReplacements: false,
                smartCapitalization: false,
                terminalPunctuation: false,
                customCommandsRaw: ""
            )
            let output = transcriber.normalizeOutputText("foo test", settings: settings)
            #expect(output == "bar test")
        }
    }

    @Test
    func mergeChunkPrefersPunctuatedVariantInsteadOfAppendingDotToken() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("hello world.", into: "hello world")
        #expect(merged == "hello world.")
    }

    @Test
    func mergeChunkTreatsWhitespaceOnlyDifferencesAsDuplicate() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("hello   world", into: "hello world")
        #expect(merged == "hello world")
    }

    @Test
    func mergeChunkStillAppendsNewContentWithOverlap() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("world from swift", into: "hello world")
        #expect(merged == "hello world from swift")
    }

    @Test
    func mergeChunkSkipsDuplicateFragmentFoundInsideTranscript() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("world from", into: "hello world from swift")
        #expect(merged == "hello world from swift")
    }

    @Test
    func mergeChunkStillAppendsShortNonDuplicateChunks() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("new", into: "hello world")
        #expect(merged == "hello world new")
    }

    @Test
    func mergeChunkIgnoresTinyOverlapThatWouldCorruptWords() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("atlas", into: "cat")
        #expect(merged == "cat atlas")
    }

    @Test
    func mergeChunkUsesThreeCharacterOverlapWhenLegitimate() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("def ghi", into: "abc def")
        #expect(merged == "abc def ghi")
    }

    @Test
    func mergeChunkPrefersExpandedChunkWhenItExtendsPartialTail() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("hello world", into: "hello wor")
        #expect(merged == "hello world")
    }

    @Test
    func mergeChunkCollapsesSpacedPunctuationWhenChunkRestatesFullSentence() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("hello world .", into: "hello world")
        #expect(merged == "hello world.")
    }

    @Test
    func mergeChunkPreservesExistingCapitalizationWhenAddingTrailingPunctuation() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("hello world.", into: "Hello world")
        #expect(merged == "Hello world.")
    }

    @Test
    func mergeChunkPreservesExistingCapitalizationForMultiCharacterTrailingPunctuation() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("hello world?!", into: "Hello world")
        #expect(merged == "Hello world?!")
    }

    @Test
    func mergeChunkAttachesStandalonePunctuationWithoutExtraSpace() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting(".", into: "hello world")
        #expect(merged == "hello world.")
    }

    @Test
    func mergeChunkAttachesStandalonePunctuationAfterTrailingWhitespace() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting(".", into: "hello world ")
        #expect(merged == "hello world.")
    }

    @Test
    func mergeChunkSkipsStandalonePunctuationWhenTranscriptAlreadyEndsWithPunctuation() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("!", into: "hello world!")
        #expect(merged == "hello world!")
    }

    @Test
    func mergeChunkAppendsNovelPunctuationSuffixWhenTranscriptAlreadyHasPunctuation() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("!?", into: "hello world!")
        #expect(merged == "hello world!?")
    }

    @Test
    func mergeChunkSkipsPunctuationFragmentThatIsPrefixOfExistingTail() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("!", into: "hello world!?")
        #expect(merged == "hello world!?")
    }

    @Test
    func mergeChunkAttachesLeadingCommaWithoutExtraSpace() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting(", and then continue", into: "hello world")
        #expect(merged == "hello world, and then continue")
    }

    @Test
    func mergeChunkSkipsDuplicateEllipsisPunctuationFragment() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("…", into: "hello world…")
        #expect(merged == "hello world…")
    }

    @Test
    func mergeChunkTreatsEllipsisVariantAsDuplicate() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("hello world…", into: "hello world")
        #expect(merged == "hello world…")
    }

    @Test @MainActor
    func setAccessibilityPermissionCheckerForTestingOverridesChecker() {
        let transcriber = AudioTranscriber.shared
        transcriber.setAccessibilityPermissionCheckerForTesting { false }
        defer {
            transcriber.setAccessibilityPermissionCheckerForTesting { true }
        }

        let canPaste = transcriber.canAutoPasteIntoTargetAppForTesting()
        #expect(!canPaste)
    }

    @Test @MainActor
    func copyTranscriptionToClipboardShowsStatusWhenTextIsEmpty() {
        let transcriber = AudioTranscriber.shared
        transcriber.transcription = "   "
        let copied = transcriber.copyTranscriptionToClipboard()
        #expect(!copied)
        #expect(transcriber.statusMessage == "Nothing to copy")
    }

    @Test @MainActor
    func copyTranscriptionToClipboardClearsPreviousErrorOnSuccess() {
        let transcriber = AudioTranscriber.shared

        let originalTranscription = transcriber.transcription
        let originalStatusMessage = transcriber.statusMessage
        let originalLastError = transcriber.lastError

        defer {
            transcriber.transcription = originalTranscription
            transcriber.statusMessage = originalStatusMessage
            transcriber.lastError = originalLastError
        }

        transcriber.transcription = "hello world"
        transcriber.lastError = "old insertion error"

        let copied = transcriber.copyTranscriptionToClipboard()
        #expect(copied)
        #expect(transcriber.statusMessage == "Copied to clipboard")
        #expect(transcriber.lastError == nil)
    }

    @Test @MainActor
    func insertTranscriptionShowsStatusWhenTextIsEmpty() {
        let transcriber = AudioTranscriber.shared
        transcriber.transcription = "\n\n"
        let inserted = transcriber.insertTranscriptionIntoFocusedApp()
        #expect(!inserted)
        #expect(transcriber.statusMessage == "Nothing to insert")
    }

    @Test @MainActor
    func insertTranscriptionBlockedWhileFinalizingPendingChunks() {
        let transcriber = AudioTranscriber.shared

        let originalIsRecording = transcriber.isRecording
        let originalPendingChunkCount = transcriber.pendingChunkCount
        let originalRecordingStartedAt = transcriber.recordingStartedAt
        let originalPendingSessionFinalize = transcriber.pendingSessionFinalizeForTesting
        let originalTranscription = transcriber.transcription
        let originalStatusMessage = transcriber.statusMessage
        let originalLastError = transcriber.lastError

        defer {
            transcriber.isRecording = originalIsRecording
            transcriber.pendingChunkCount = originalPendingChunkCount
            transcriber.recordingStartedAt = originalRecordingStartedAt
            transcriber.setPendingSessionFinalizeForTesting(originalPendingSessionFinalize)
            transcriber.transcription = originalTranscription
            transcriber.statusMessage = originalStatusMessage
            transcriber.lastError = originalLastError
        }

        transcriber.isRecording = false
        transcriber.pendingChunkCount = 1
        transcriber.recordingStartedAt = Date()
        transcriber.setPendingSessionFinalizeForTesting(false)
        transcriber.transcription = "hello world"

        let inserted = transcriber.insertTranscriptionIntoFocusedApp()
        #expect(!inserted)
        #expect(transcriber.statusMessage == "Wait for live transcription to finish finalizing before inserting text. (1 chunk pending.)")
        #expect(transcriber.lastError == "Wait for live transcription to finish finalizing before inserting text. (1 chunk pending.)")
    }

    @Test @MainActor
    func insertTranscriptionBlockedWhileFinalizingWithoutQueuedChunks() {
        let transcriber = AudioTranscriber.shared

        let originalIsRecording = transcriber.isRecording
        let originalPendingChunkCount = transcriber.pendingChunkCount
        let originalPendingSessionFinalize = transcriber.pendingSessionFinalizeForTesting
        let originalTranscription = transcriber.transcription
        let originalStatusMessage = transcriber.statusMessage
        let originalLastError = transcriber.lastError

        defer {
            transcriber.isRecording = originalIsRecording
            transcriber.pendingChunkCount = originalPendingChunkCount
            transcriber.setPendingSessionFinalizeForTesting(originalPendingSessionFinalize)
            transcriber.transcription = originalTranscription
            transcriber.statusMessage = originalStatusMessage
            transcriber.lastError = originalLastError
        }

        transcriber.isRecording = false
        transcriber.pendingChunkCount = 0
        transcriber.setPendingSessionFinalizeForTesting(true)
        transcriber.transcription = "hello world"

        let inserted = transcriber.insertTranscriptionIntoFocusedApp()
        #expect(!inserted)
        #expect(transcriber.statusMessage == "Wait for live transcription to finish finalizing before inserting text. (Preparing final chunk.)")
        #expect(transcriber.lastError == "Wait for live transcription to finish finalizing before inserting text. (Preparing final chunk.)")
    }

    @Test @MainActor
    func insertTranscriptionBlockedWhileFinalizingShowsQueuedStartHint() {
        let transcriber = AudioTranscriber.shared

        let originalIsRecording = transcriber.isRecording
        let originalPendingChunkCount = transcriber.pendingChunkCount
        let originalRecordingStartedAt = transcriber.recordingStartedAt
        let originalPendingSessionFinalize = transcriber.pendingSessionFinalizeForTesting
        let originalTranscription = transcriber.transcription
        let originalStatusMessage = transcriber.statusMessage
        let originalLastError = transcriber.lastError

        defer {
            if transcriber.startRecordingAfterFinalizeRequestedForTesting {
                transcriber.toggleRecording()
            }
            transcriber.isRecording = originalIsRecording
            transcriber.pendingChunkCount = originalPendingChunkCount
            transcriber.recordingStartedAt = originalRecordingStartedAt
            transcriber.setPendingSessionFinalizeForTesting(originalPendingSessionFinalize)
            transcriber.transcription = originalTranscription
            transcriber.statusMessage = originalStatusMessage
            transcriber.lastError = originalLastError
        }

        transcriber.isRecording = false
        transcriber.pendingChunkCount = 1
        transcriber.recordingStartedAt = Date()
        transcriber.setPendingSessionFinalizeForTesting(false)
        transcriber.transcription = "hello world"

        if transcriber.startRecordingAfterFinalizeRequestedForTesting {
            transcriber.toggleRecording()
        }
        transcriber.toggleRecording()

        let inserted = transcriber.insertTranscriptionIntoFocusedApp()
        #expect(!inserted)
        #expect(transcriber.statusMessage == "Wait for live transcription to finish finalizing before inserting text. (1 chunk pending.) Next recording is already queued.")
        #expect(transcriber.lastError == "Wait for live transcription to finish finalizing before inserting text. (1 chunk pending.) Next recording is already queued.")
    }

    @Test @MainActor
    func insertTranscriptionReturnsSuccessWhenAccessibilityFallbackCopiesText() {
        let transcriber = AudioTranscriber.shared

        let originalIsRecording = transcriber.isRecording
        let originalPendingChunkCount = transcriber.pendingChunkCount
        let originalPendingSessionFinalize = transcriber.pendingSessionFinalizeForTesting
        let originalTranscription = transcriber.transcription
        let originalStatusMessage = transcriber.statusMessage
        let originalLastError = transcriber.lastError
        let originalHistory = transcriber.recentEntries

        defer {
            transcriber.isRecording = originalIsRecording
            transcriber.pendingChunkCount = originalPendingChunkCount
            transcriber.setPendingSessionFinalizeForTesting(originalPendingSessionFinalize)
            transcriber.transcription = originalTranscription
            transcriber.statusMessage = originalStatusMessage
            transcriber.lastError = originalLastError
            transcriber.recentEntries = originalHistory
            transcriber.setAccessibilityPermissionCheckerForTesting { true }
        }

        transcriber.setAccessibilityPermissionCheckerForTesting { false }
        transcriber.isRecording = false
        transcriber.pendingChunkCount = 0
        transcriber.setPendingSessionFinalizeForTesting(false)

        let insertedText = "accessibility fallback \(UUID().uuidString)"
        transcriber.transcription = insertedText

        let previousHistoryCount = transcriber.recentEntries.count
        let inserted = transcriber.insertTranscriptionIntoFocusedApp()

        #expect(inserted)
        #expect(transcriber.recentEntries.count >= previousHistoryCount)
        #expect(transcriber.recentEntries.first?.text == transcriber.transcription)
        #expect(transcriber.statusMessage.hasPrefix("Copied to clipboard"))
        #expect(transcriber.lastError == nil)
    }

    @Test @MainActor
    func toggleRecordingDefersNewSessionWhileFinalizing() {
        let transcriber = AudioTranscriber.shared

        let originalStartedAt = transcriber.recordingStartedAt
        let originalPendingChunkCount = transcriber.pendingChunkCount
        let originalStatusMessage = transcriber.statusMessage
        let originalIsRecording = transcriber.isRecording

        defer {
            if transcriber.startRecordingAfterFinalizeRequestedForTesting {
                transcriber.isRecording = false
                transcriber.recordingStartedAt = Date()
                transcriber.pendingChunkCount = max(1, transcriber.pendingChunkCount)
                transcriber.toggleRecording()
            }
            transcriber.recordingStartedAt = originalStartedAt
            transcriber.pendingChunkCount = originalPendingChunkCount
            transcriber.statusMessage = originalStatusMessage
            transcriber.isRecording = originalIsRecording
        }

        transcriber.isRecording = false
        transcriber.recordingStartedAt = Date()
        transcriber.pendingChunkCount = 1

        if transcriber.startRecordingAfterFinalizeRequestedForTesting {
            transcriber.toggleRecording()
        }

        transcriber.toggleRecording()

        #expect(!transcriber.isRecording)
        #expect(transcriber.statusMessage == "Finalizing previous recording… next recording queued")
        #expect(transcriber.startRecordingAfterFinalizeRequestedForTesting)

        transcriber.toggleRecording()

        #expect(transcriber.statusMessage == "Finalizing previous recording… queued start canceled")
        #expect(!transcriber.startRecordingAfterFinalizeRequestedForTesting)
    }

    @Test @MainActor
    func refreshStreamingStatusKeepsQueuedStartHintWhileFinalizing() {
        let transcriber = AudioTranscriber.shared

        let originalStartedAt = transcriber.recordingStartedAt
        let originalPendingChunkCount = transcriber.pendingChunkCount
        let originalStatusMessage = transcriber.statusMessage
        let originalIsRecording = transcriber.isRecording

        defer {
            if transcriber.startRecordingAfterFinalizeRequestedForTesting {
                transcriber.isRecording = false
                transcriber.recordingStartedAt = Date()
                transcriber.pendingChunkCount = max(1, transcriber.pendingChunkCount)
                transcriber.toggleRecording()
            }
            transcriber.recordingStartedAt = originalStartedAt
            transcriber.pendingChunkCount = originalPendingChunkCount
            transcriber.statusMessage = originalStatusMessage
            transcriber.isRecording = originalIsRecording
        }

        transcriber.isRecording = false
        transcriber.recordingStartedAt = Date()
        transcriber.pendingChunkCount = 2

        if transcriber.startRecordingAfterFinalizeRequestedForTesting {
            transcriber.toggleRecording()
        }

        transcriber.toggleRecording()
        transcriber.refreshStreamingStatusForTesting()

        #expect(transcriber.startRecordingAfterFinalizeRequestedForTesting)
        #expect(transcriber.statusMessage.contains("Finalizing… 2 chunks left"))
        #expect(transcriber.statusMessage.contains("next recording queued"))
    }

    @Test @MainActor
    func cancelQueuedStartAfterFinalizeFromHotkeyClearsQueuedStart() {
        let transcriber = AudioTranscriber.shared

        let originalStartedAt = transcriber.recordingStartedAt
        let originalPendingChunkCount = transcriber.pendingChunkCount
        let originalStatusMessage = transcriber.statusMessage
        let originalIsRecording = transcriber.isRecording

        defer {
            transcriber.recordingStartedAt = originalStartedAt
            transcriber.pendingChunkCount = originalPendingChunkCount
            transcriber.statusMessage = originalStatusMessage
            transcriber.isRecording = originalIsRecording
        }

        transcriber.isRecording = false
        transcriber.recordingStartedAt = Date()
        transcriber.pendingChunkCount = 1
        transcriber.toggleRecording()

        #expect(transcriber.startRecordingAfterFinalizeRequestedForTesting)

        let canceled = transcriber.cancelQueuedStartAfterFinalizeFromHotkey()

        #expect(canceled)
        #expect(!transcriber.startRecordingAfterFinalizeRequestedForTesting)
        #expect(transcriber.statusMessage == "Finalizing previous recording… queued start canceled")
    }

    @Test @MainActor
    func refreshStreamingStatusShowsHourAwareElapsedTime() {
        let transcriber = AudioTranscriber.shared

        let originalStatusMessage = transcriber.statusMessage
        let originalIsRecording = transcriber.isRecording
        let originalRecordingStartedAt = transcriber.recordingStartedAt
        let originalPendingChunkCount = transcriber.pendingChunkCount
        let originalProcessedChunkCount = transcriber.processedChunkCount
        let originalLastChunkLatency = transcriber.lastChunkLatencySeconds
        let originalAverageChunkLatency = transcriber.averageChunkLatencySeconds

        defer {
            transcriber.statusMessage = originalStatusMessage
            transcriber.isRecording = originalIsRecording
            transcriber.recordingStartedAt = originalRecordingStartedAt
            transcriber.pendingChunkCount = originalPendingChunkCount
            transcriber.processedChunkCount = originalProcessedChunkCount
            transcriber.lastChunkLatencySeconds = originalLastChunkLatency
            transcriber.averageChunkLatencySeconds = originalAverageChunkLatency
        }

        transcriber.isRecording = true
        transcriber.recordingStartedAt = Date().addingTimeInterval(-3661)
        transcriber.pendingChunkCount = 0
        transcriber.processedChunkCount = 0
        transcriber.lastChunkLatencySeconds = 0
        transcriber.averageChunkLatencySeconds = 0

        transcriber.refreshStreamingStatusForTesting()

        #expect(transcriber.statusMessage.contains("1:01:01"))
    }

    @Test @MainActor
    func refreshStreamingStatusShowsFinalizingEstimateFromLatency() {
        let transcriber = AudioTranscriber.shared

        let originalStatusMessage = transcriber.statusMessage
        let originalIsRecording = transcriber.isRecording
        let originalRecordingStartedAt = transcriber.recordingStartedAt
        let originalPendingChunkCount = transcriber.pendingChunkCount
        let originalProcessedChunkCount = transcriber.processedChunkCount
        let originalLastChunkLatency = transcriber.lastChunkLatencySeconds
        let originalAverageChunkLatency = transcriber.averageChunkLatencySeconds

        defer {
            transcriber.statusMessage = originalStatusMessage
            transcriber.isRecording = originalIsRecording
            transcriber.recordingStartedAt = originalRecordingStartedAt
            transcriber.pendingChunkCount = originalPendingChunkCount
            transcriber.processedChunkCount = originalProcessedChunkCount
            transcriber.lastChunkLatencySeconds = originalLastChunkLatency
            transcriber.averageChunkLatencySeconds = originalAverageChunkLatency
        }

        transcriber.isRecording = false
        transcriber.recordingStartedAt = Date()
        transcriber.pendingChunkCount = 2
        transcriber.processedChunkCount = 3
        transcriber.lastChunkLatencySeconds = 0.8
        transcriber.averageChunkLatencySeconds = 1.2

        transcriber.refreshStreamingStatusForTesting()

        #expect(transcriber.statusMessage.contains("Finalizing… 2 chunks left"))
        #expect(transcriber.statusMessage.contains("~3s remaining"))
    }

    @Test @MainActor
    func runInsertionProbeBlockedWhenSampleTextIsEmpty() {
        let transcriber = AudioTranscriber.shared

        let originalStatusMessage = transcriber.statusMessage
        let originalLastError = transcriber.lastError

        defer {
            transcriber.statusMessage = originalStatusMessage
            transcriber.lastError = originalLastError
        }

        let success = transcriber.runInsertionProbe(sampleText: "   ")

        #expect(!success)
        #expect(transcriber.statusMessage == "Insertion test text is empty. Enter sample text and try again.")
        #expect(transcriber.lastError == "Insertion test text is empty. Enter sample text and try again.")
    }

    @Test @MainActor
    func runInsertionProbeBlockedWhenAnotherProbeIsRunning() {
        let transcriber = AudioTranscriber.shared

        let originalIsRunningInsertionProbe = transcriber.isRunningInsertionProbe
        let originalStatusMessage = transcriber.statusMessage
        let originalLastError = transcriber.lastError

        defer {
            transcriber.isRunningInsertionProbe = originalIsRunningInsertionProbe
            transcriber.statusMessage = originalStatusMessage
            transcriber.lastError = originalLastError
        }

        transcriber.isRunningInsertionProbe = true
        let success = transcriber.runInsertionProbe(sampleText: "probe")

        #expect(!success)
        #expect(transcriber.statusMessage == "Insertion test already running.")
        #expect(transcriber.lastError == "Insertion test already running.")
    }

    @Test @MainActor
    func runInsertionProbeBlockedWhileRecording() {
        let transcriber = AudioTranscriber.shared

        let originalIsRecording = transcriber.isRecording
        let originalStatusMessage = transcriber.statusMessage
        let originalLastError = transcriber.lastError

        defer {
            transcriber.isRecording = originalIsRecording
            transcriber.statusMessage = originalStatusMessage
            transcriber.lastError = originalLastError
        }

        transcriber.isRecording = true
        let success = transcriber.runInsertionProbe(sampleText: "probe")

        #expect(!success)
        #expect(transcriber.statusMessage == "Stop recording before running an insertion test.")
        #expect(transcriber.lastError == "Stop recording before running an insertion test.")
    }

    @Test @MainActor
    func runInsertionProbeBlockedWhileFinalizingPendingChunks() {
        let transcriber = AudioTranscriber.shared

        let originalIsRecording = transcriber.isRecording
        let originalPendingChunkCount = transcriber.pendingChunkCount
        let originalRecordingStartedAt = transcriber.recordingStartedAt
        let originalStatusMessage = transcriber.statusMessage
        let originalLastError = transcriber.lastError

        defer {
            transcriber.isRecording = originalIsRecording
            transcriber.pendingChunkCount = originalPendingChunkCount
            transcriber.recordingStartedAt = originalRecordingStartedAt
            transcriber.statusMessage = originalStatusMessage
            transcriber.lastError = originalLastError
        }

        transcriber.isRecording = false
        transcriber.recordingStartedAt = Date()
        transcriber.pendingChunkCount = 2
        let success = transcriber.runInsertionProbe(sampleText: "probe")

        #expect(!success)
        #expect(transcriber.statusMessage == "Wait for live transcription to finish finalizing before running an insertion test. (2 chunks pending.)")
        #expect(transcriber.lastError == "Wait for live transcription to finish finalizing before running an insertion test. (2 chunks pending.)")
    }

    @Test @MainActor
    func runInsertionProbeBlockedWhileFinalizingWithoutQueuedChunks() {
        let transcriber = AudioTranscriber.shared

        let originalIsRecording = transcriber.isRecording
        let originalPendingChunkCount = transcriber.pendingChunkCount
        let originalRecordingStartedAt = transcriber.recordingStartedAt
        let originalStatusMessage = transcriber.statusMessage
        let originalLastError = transcriber.lastError

        defer {
            transcriber.isRecording = originalIsRecording
            transcriber.pendingChunkCount = originalPendingChunkCount
            transcriber.recordingStartedAt = originalRecordingStartedAt
            transcriber.statusMessage = originalStatusMessage
            transcriber.lastError = originalLastError
        }

        transcriber.isRecording = false
        transcriber.pendingChunkCount = 0
        transcriber.recordingStartedAt = Date()
        let success = transcriber.runInsertionProbe(sampleText: "probe")

        #expect(!success)
        #expect(transcriber.statusMessage == "Wait for live transcription to finish finalizing before running an insertion test.")
        #expect(transcriber.lastError == "Wait for live transcription to finish finalizing before running an insertion test.")
    }

    @Test @MainActor
    func runInsertionProbeBlockedWhilePendingFinalizeFlagSet() {
        let transcriber = AudioTranscriber.shared

        let originalIsRecording = transcriber.isRecording
        let originalPendingChunkCount = transcriber.pendingChunkCount
        let originalRecordingStartedAt = transcriber.recordingStartedAt
        let originalPendingSessionFinalize = transcriber.pendingSessionFinalizeForTesting
        let originalStatusMessage = transcriber.statusMessage
        let originalLastError = transcriber.lastError

        defer {
            transcriber.isRecording = originalIsRecording
            transcriber.pendingChunkCount = originalPendingChunkCount
            transcriber.recordingStartedAt = originalRecordingStartedAt
            transcriber.setPendingSessionFinalizeForTesting(originalPendingSessionFinalize)
            transcriber.statusMessage = originalStatusMessage
            transcriber.lastError = originalLastError
        }

        transcriber.isRecording = false
        transcriber.pendingChunkCount = 0
        transcriber.recordingStartedAt = nil
        transcriber.setPendingSessionFinalizeForTesting(true)
        let success = transcriber.runInsertionProbe(sampleText: "probe")

        #expect(!success)
        #expect(transcriber.statusMessage == "Wait for live transcription to finish finalizing before running an insertion test. (Preparing final chunk.)")
        #expect(transcriber.lastError == "Wait for live transcription to finish finalizing before running an insertion test. (Preparing final chunk.)")
    }

    @Test @MainActor
    func runInsertionProbeBlockedWhileFinalizingShowsQueuedStartHint() {
        let transcriber = AudioTranscriber.shared

        let originalIsRecording = transcriber.isRecording
        let originalPendingChunkCount = transcriber.pendingChunkCount
        let originalRecordingStartedAt = transcriber.recordingStartedAt
        let originalStatusMessage = transcriber.statusMessage
        let originalLastError = transcriber.lastError

        defer {
            if transcriber.startRecordingAfterFinalizeRequestedForTesting {
                transcriber.toggleRecording()
            }
            transcriber.isRecording = originalIsRecording
            transcriber.pendingChunkCount = originalPendingChunkCount
            transcriber.recordingStartedAt = originalRecordingStartedAt
            transcriber.statusMessage = originalStatusMessage
            transcriber.lastError = originalLastError
        }

        transcriber.isRecording = false
        transcriber.pendingChunkCount = 2
        transcriber.recordingStartedAt = Date()

        if transcriber.startRecordingAfterFinalizeRequestedForTesting {
            transcriber.toggleRecording()
        }
        transcriber.toggleRecording()

        let success = transcriber.runInsertionProbe(sampleText: "probe")

        #expect(!success)
        #expect(transcriber.statusMessage == "Wait for live transcription to finish finalizing before running an insertion test. (2 chunks pending.) Next recording is already queued.")
        #expect(transcriber.lastError == "Wait for live transcription to finish finalizing before running an insertion test. (2 chunks pending.) Next recording is already queued.")
    }

    // MARK: - Whitespace normalization

    @Test
    func normalizeWhitespaceCollapsesSpaceBeforePunctuation() {
        let transcriber = AudioTranscriber.shared
        let result = transcriber.normalizeWhitespace(in: "hello , world .")
        #expect(result == "hello, world.")
    }

    @Test
    func normalizeWhitespacePreservesPunctuationCharacter() {
        let transcriber = AudioTranscriber.shared
        let result = transcriber.normalizeWhitespace(in: "wait ! really ?")
        #expect(result == "wait! really?")
    }

    @Test
    func normalizeWhitespaceCollapsesMultipleSpaces() {
        let transcriber = AudioTranscriber.shared
        let result = transcriber.normalizeWhitespace(in: "hello    world")
        #expect(result == "hello world")
    }

    @Test
    func normalizeWhitespaceCollapsesExcessiveNewlines() {
        let transcriber = AudioTranscriber.shared
        let result = transcriber.normalizeWhitespace(in: "hello\n\n\n\nworld")
        #expect(result == "hello\n\nworld")
    }

    @Test
    func normalizeWhitespaceCollapsesSpacedAsciiApostrophesInContractions() {
        let transcriber = AudioTranscriber.shared
        let result = transcriber.normalizeWhitespace(in: "don ' t stop")
        #expect(result == "don't stop")
    }

    @Test
    func normalizeWhitespaceCollapsesSpacedCurlyApostrophesInContractions() {
        let transcriber = AudioTranscriber.shared
        let result = transcriber.normalizeWhitespace(in: "we \u{2019} re live")
        #expect(result == "we're live")
    }
}
