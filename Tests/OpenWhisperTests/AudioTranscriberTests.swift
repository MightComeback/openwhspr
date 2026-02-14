import XCTest
@testable import OpenWhisper

final class AudioTranscriberTests: XCTestCase {
    private func withStandardDefaults(_ values: [String: Any], _ body: () async throws -> Void) async rethrows {
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

    func testResolveConfiguredModelURLUsesBundledWhenCustomMissing() async throws {
        try await withStandardDefaults([
            AppDefaults.Keys.modelSource: ModelSource.customPath.rawValue,
            AppDefaults.Keys.modelCustomPath: ""
        ]) {
            let transcriber = AudioTranscriber.shared
            let resolved = transcriber.resolveConfiguredModelURL()
            XCTAssertEqual(resolved.loadedSource, .bundledTiny)
            XCTAssertNotNil(resolved.url)
            XCTAssertNotNil(resolved.warning)
        }
    }

    func testResolveConfiguredModelURLUsesCustomWhenValid() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try "model".data(using: .utf8)!.write(to: tempURL)

        try await withStandardDefaults([
            AppDefaults.Keys.modelSource: ModelSource.customPath.rawValue,
            AppDefaults.Keys.modelCustomPath: tempURL.path
        ]) {
            let transcriber = AudioTranscriber.shared
            let resolved = transcriber.resolveConfiguredModelURL()
            XCTAssertEqual(resolved.loadedSource, .customPath)
            XCTAssertEqual(resolved.url?.path, tempURL.path)
            XCTAssertNil(resolved.warning)
        }
    }

    func testResolveConfiguredModelURLWarnsOnInvalidPath() async throws {
        let invalidPath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try await withStandardDefaults([
            AppDefaults.Keys.modelSource: ModelSource.customPath.rawValue,
            AppDefaults.Keys.modelCustomPath: invalidPath
        ]) {
            let transcriber = AudioTranscriber.shared
            let resolved = transcriber.resolveConfiguredModelURL()
            XCTAssertEqual(resolved.loadedSource, .bundledTiny)
            XCTAssertNotNil(resolved.warning)
        }
    }

    func testIsReadableModelFileRejectsEmptyFile() throws {
        let transcriber = AudioTranscriber.shared
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        FileManager.default.createFile(atPath: tempURL.path, contents: Data(), attributes: nil)
        XCTAssertFalse(transcriber.isReadableModelFile(at: tempURL))
    }

    func testNormalizeOutputTextAppliesCommandReplacement() async throws {
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
            let output = await MainActor.run {
                transcriber.normalizeOutputText("new line", settings: settings)
            }
            XCTAssertEqual(output, "\n")
        }
    }

    func testNormalizeOutputTextAppliesSmartCapitalization() async throws {
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
            let output = await MainActor.run {
                transcriber.normalizeOutputText("hello. world", settings: settings)
            }
            XCTAssertEqual(output, "Hello. World")
        }
    }

    func testNormalizeOutputTextAppliesTerminalPunctuation() async throws {
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
            let output = await MainActor.run {
                transcriber.normalizeOutputText("hello", settings: settings)
            }
            XCTAssertEqual(output, "hello.")
        }
    }

    func testNormalizeOutputTextDoesNotDuplicateTerminalPunctuation() async throws {
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
            let output = await MainActor.run {
                transcriber.normalizeOutputText("hello!", settings: settings)
            }
            XCTAssertEqual(output, "hello!")
        }
    }

    func testNormalizeOutputTextTreatsEllipsisAsTerminalPunctuation() async throws {
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
            let output = await MainActor.run {
                transcriber.normalizeOutputText("hello…", settings: settings)
            }
            XCTAssertEqual(output, "hello…")
        }
    }

    func testNormalizeOutputTextAppliesTextReplacements() async throws {
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
            let output = await MainActor.run {
                transcriber.normalizeOutputText("foo test", settings: settings)
            }
            XCTAssertEqual(output, "bar test")
        }
    }

    func testMergeChunkPrefersPunctuatedVariantInsteadOfAppendingDotToken() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("hello world.", into: "hello world")
        XCTAssertEqual(merged, "hello world.")
    }

    func testMergeChunkTreatsWhitespaceOnlyDifferencesAsDuplicate() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("hello   world", into: "hello world")
        XCTAssertEqual(merged, "hello world")
    }

    func testMergeChunkStillAppendsNewContentWithOverlap() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("world from swift", into: "hello world")
        XCTAssertEqual(merged, "hello world from swift")
    }

    func testMergeChunkSkipsDuplicateFragmentFoundInsideTranscript() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("world from", into: "hello world from swift")
        XCTAssertEqual(merged, "hello world from swift")
    }

    func testMergeChunkStillAppendsShortNonDuplicateChunks() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("new", into: "hello world")
        XCTAssertEqual(merged, "hello world new")
    }

    func testMergeChunkIgnoresTinyOverlapThatWouldCorruptWords() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("atlas", into: "cat")
        XCTAssertEqual(merged, "cat atlas")
    }

    func testMergeChunkUsesThreeCharacterOverlapWhenLegitimate() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("def ghi", into: "abc def")
        XCTAssertEqual(merged, "abc def ghi")
    }

    func testMergeChunkPrefersExpandedChunkWhenItExtendsPartialTail() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("hello world", into: "hello wor")
        XCTAssertEqual(merged, "hello world")
    }

    func testMergeChunkCollapsesSpacedPunctuationWhenChunkRestatesFullSentence() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("hello world .", into: "hello world")
        XCTAssertEqual(merged, "hello world.")
    }

    func testMergeChunkPreservesExistingCapitalizationWhenAddingTrailingPunctuation() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("hello world.", into: "Hello world")
        XCTAssertEqual(merged, "Hello world.")
    }

    func testMergeChunkPreservesExistingCapitalizationForMultiCharacterTrailingPunctuation() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("hello world?!", into: "Hello world")
        XCTAssertEqual(merged, "Hello world?!")
    }

    func testMergeChunkAttachesStandalonePunctuationWithoutExtraSpace() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting(".", into: "hello world")
        XCTAssertEqual(merged, "hello world.")
    }

    func testMergeChunkAttachesStandalonePunctuationAfterTrailingWhitespace() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting(".", into: "hello world ")
        XCTAssertEqual(merged, "hello world.")
    }

    func testMergeChunkSkipsStandalonePunctuationWhenTranscriptAlreadyEndsWithPunctuation() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("!", into: "hello world!")
        XCTAssertEqual(merged, "hello world!")
    }

    func testMergeChunkAppendsNovelPunctuationSuffixWhenTranscriptAlreadyHasPunctuation() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("!?", into: "hello world!")
        XCTAssertEqual(merged, "hello world!?")
    }

    func testMergeChunkSkipsPunctuationFragmentThatIsPrefixOfExistingTail() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("!", into: "hello world!?")
        XCTAssertEqual(merged, "hello world!?")
    }

    func testMergeChunkAttachesLeadingCommaWithoutExtraSpace() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting(", and then continue", into: "hello world")
        XCTAssertEqual(merged, "hello world, and then continue")
    }

    func testMergeChunkSkipsDuplicateEllipsisPunctuationFragment() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("…", into: "hello world…")
        XCTAssertEqual(merged, "hello world…")
    }

    func testMergeChunkTreatsEllipsisVariantAsDuplicate() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("hello world…", into: "hello world")
        XCTAssertEqual(merged, "hello world…")
    }

    func testSetAccessibilityPermissionCheckerForTestingOverridesChecker() async {
        let transcriber = AudioTranscriber.shared
        transcriber.setAccessibilityPermissionCheckerForTesting { false }
        defer {
            transcriber.setAccessibilityPermissionCheckerForTesting { true }
        }

        let canPaste = await MainActor.run {
            transcriber.canAutoPasteIntoTargetAppForTesting()
        }

        XCTAssertFalse(canPaste)
    }

    func testCopyTranscriptionToClipboardShowsStatusWhenTextIsEmpty() async {
        let transcriber = AudioTranscriber.shared

        await MainActor.run {
            transcriber.transcription = "   "
            let copied = transcriber.copyTranscriptionToClipboard()
            XCTAssertFalse(copied)
            XCTAssertEqual(transcriber.statusMessage, "Nothing to copy")
        }
    }

    func testCopyTranscriptionToClipboardClearsPreviousErrorOnSuccess() async {
        let transcriber = AudioTranscriber.shared

        await MainActor.run {
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
            XCTAssertTrue(copied)
            XCTAssertEqual(transcriber.statusMessage, "Copied to clipboard")
            XCTAssertNil(transcriber.lastError)
        }
    }

    func testInsertTranscriptionShowsStatusWhenTextIsEmpty() async {
        let transcriber = AudioTranscriber.shared

        await MainActor.run {
            transcriber.transcription = "\n\n"
            let inserted = transcriber.insertTranscriptionIntoFocusedApp()
            XCTAssertFalse(inserted)
            XCTAssertEqual(transcriber.statusMessage, "Nothing to insert")
        }
    }

    func testInsertTranscriptionBlockedWhileFinalizingPendingChunks() async {
        let transcriber = AudioTranscriber.shared

        await MainActor.run {
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
            XCTAssertFalse(inserted)
            XCTAssertEqual(transcriber.statusMessage, "Wait for live transcription to finish finalizing before inserting text. (1 chunk pending.)")
            XCTAssertEqual(transcriber.lastError, "Wait for live transcription to finish finalizing before inserting text. (1 chunk pending.)")
        }
    }

    func testInsertTranscriptionBlockedWhileFinalizingWithoutQueuedChunks() async {
        let transcriber = AudioTranscriber.shared

        await MainActor.run {
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
            XCTAssertFalse(inserted)
            XCTAssertEqual(transcriber.statusMessage, "Wait for live transcription to finish finalizing before inserting text.")
            XCTAssertEqual(transcriber.lastError, "Wait for live transcription to finish finalizing before inserting text.")
        }
    }

    func testInsertTranscriptionReturnsSuccessWhenAccessibilityFallbackCopiesText() async {
        let transcriber = AudioTranscriber.shared

        await MainActor.run {
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

            XCTAssertTrue(inserted)
            XCTAssertGreaterThanOrEqual(transcriber.recentEntries.count, previousHistoryCount)
            XCTAssertEqual(transcriber.recentEntries.first?.text, insertedText)
            XCTAssertTrue(transcriber.statusMessage.hasPrefix("Copied to clipboard"))
        }
    }

    func testToggleRecordingDefersNewSessionWhileFinalizing() async {
        let transcriber = AudioTranscriber.shared

        await MainActor.run {
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

            XCTAssertFalse(transcriber.isRecording)
            XCTAssertEqual(transcriber.statusMessage, "Finalizing previous recording… next recording queued")
            XCTAssertTrue(transcriber.startRecordingAfterFinalizeRequestedForTesting)

            transcriber.toggleRecording()

            XCTAssertEqual(transcriber.statusMessage, "Finalizing previous recording… queued start canceled")
            XCTAssertFalse(transcriber.startRecordingAfterFinalizeRequestedForTesting)
        }
    }

    func testRefreshStreamingStatusKeepsQueuedStartHintWhileFinalizing() async {
        let transcriber = AudioTranscriber.shared

        await MainActor.run {
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

            XCTAssertTrue(transcriber.startRecordingAfterFinalizeRequestedForTesting)
            XCTAssertTrue(transcriber.statusMessage.contains("Finalizing… 2 chunks left"))
            XCTAssertTrue(transcriber.statusMessage.contains("next recording queued"))
        }
    }

    func testCancelQueuedStartAfterFinalizeFromHotkeyClearsQueuedStart() async {
        let transcriber = AudioTranscriber.shared

        await MainActor.run {
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

            XCTAssertTrue(transcriber.startRecordingAfterFinalizeRequestedForTesting)

            let canceled = transcriber.cancelQueuedStartAfterFinalizeFromHotkey()

            XCTAssertTrue(canceled)
            XCTAssertFalse(transcriber.startRecordingAfterFinalizeRequestedForTesting)
            XCTAssertEqual(transcriber.statusMessage, "Finalizing previous recording… queued start canceled")
        }
    }

    func testRefreshStreamingStatusShowsHourAwareElapsedTime() async {
        let transcriber = AudioTranscriber.shared

        await MainActor.run {
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

            XCTAssertTrue(transcriber.statusMessage.contains("1:01:01"))
        }
    }

    func testRunInsertionProbeBlockedWhenSampleTextIsEmpty() async {
        let transcriber = AudioTranscriber.shared

        await MainActor.run {
            let originalStatusMessage = transcriber.statusMessage
            let originalLastError = transcriber.lastError

            defer {
                transcriber.statusMessage = originalStatusMessage
                transcriber.lastError = originalLastError
            }

            let success = transcriber.runInsertionProbe(sampleText: "   ")

            XCTAssertFalse(success)
            XCTAssertEqual(transcriber.statusMessage, "Insertion test text is empty. Enter sample text and try again.")
            XCTAssertEqual(transcriber.lastError, "Insertion test text is empty. Enter sample text and try again.")
        }
    }

    func testRunInsertionProbeBlockedWhenAnotherProbeIsRunning() async {
        let transcriber = AudioTranscriber.shared

        await MainActor.run {
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

            XCTAssertFalse(success)
            XCTAssertEqual(transcriber.statusMessage, "Insertion test already running.")
            XCTAssertEqual(transcriber.lastError, "Insertion test already running.")
        }
    }

    func testRunInsertionProbeBlockedWhileRecording() async {
        let transcriber = AudioTranscriber.shared

        await MainActor.run {
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

            XCTAssertFalse(success)
            XCTAssertEqual(transcriber.statusMessage, "Stop recording before running an insertion test.")
            XCTAssertEqual(transcriber.lastError, "Stop recording before running an insertion test.")
        }
    }

    func testRunInsertionProbeBlockedWhileFinalizingPendingChunks() async {
        let transcriber = AudioTranscriber.shared

        await MainActor.run {
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

            XCTAssertFalse(success)
            XCTAssertEqual(transcriber.statusMessage, "Wait for live transcription to finish finalizing before running an insertion test. (2 chunks pending.)")
            XCTAssertEqual(transcriber.lastError, "Wait for live transcription to finish finalizing before running an insertion test. (2 chunks pending.)")
        }
    }

    func testRunInsertionProbeBlockedWhileFinalizingWithoutQueuedChunks() async {
        let transcriber = AudioTranscriber.shared

        await MainActor.run {
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

            XCTAssertFalse(success)
            XCTAssertEqual(transcriber.statusMessage, "Wait for live transcription to finish finalizing before running an insertion test.")
            XCTAssertEqual(transcriber.lastError, "Wait for live transcription to finish finalizing before running an insertion test.")
        }
    }

    // MARK: - Whitespace normalization

    func testNormalizeWhitespaceCollapsesSpaceBeforePunctuation() async throws {
        let transcriber = AudioTranscriber.shared
        let result = transcriber.normalizeWhitespace(in: "hello , world .")
        XCTAssertEqual(result, "hello, world.")
    }

    func testNormalizeWhitespacePreservesPunctuationCharacter() async throws {
        let transcriber = AudioTranscriber.shared
        // Verify that the $1 backreference works — punctuation is kept, not replaced with literal "$1".
        let result = transcriber.normalizeWhitespace(in: "wait ! really ?")
        XCTAssertEqual(result, "wait! really?")
    }

    func testNormalizeWhitespaceCollapsesMultipleSpaces() async throws {
        let transcriber = AudioTranscriber.shared
        let result = transcriber.normalizeWhitespace(in: "hello    world")
        XCTAssertEqual(result, "hello world")
    }

    func testNormalizeWhitespaceCollapsesExcessiveNewlines() async throws {
        let transcriber = AudioTranscriber.shared
        let result = transcriber.normalizeWhitespace(in: "hello\n\n\n\nworld")
        XCTAssertEqual(result, "hello\n\nworld")
    }
}
