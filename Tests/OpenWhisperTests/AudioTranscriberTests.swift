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

    func testMergeChunkAttachesStandalonePunctuationWithoutExtraSpace() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting(".", into: "hello world")
        XCTAssertEqual(merged, "hello world.")
    }

    func testMergeChunkSkipsStandalonePunctuationWhenTranscriptAlreadyEndsWithPunctuation() {
        let transcriber = AudioTranscriber.shared
        let merged = transcriber.mergeChunkForTesting("!", into: "hello world!")
        XCTAssertEqual(merged, "hello world!")
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
}
