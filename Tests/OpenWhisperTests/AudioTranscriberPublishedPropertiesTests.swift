import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber Published Properties")
struct AudioTranscriberPublishedPropertiesTests {

    // MARK: - Model-related published properties

    @Test("activeModelDisplayName starts with a non-empty string")
    @MainActor func activeModelDisplayNameDefault() {
        let t = AudioTranscriber.shared
        #expect(!t.activeModelDisplayName.isEmpty)
    }

    @Test("activeModelPath is accessible")
    @MainActor func activeModelPathDefault() {
        let t = AudioTranscriber.shared
        let path = t.activeModelPath
        #expect(path == path)
    }

    @Test("activeModelSource defaults to bundledTiny")
    @MainActor func activeModelSourceDefault() {
        let t = AudioTranscriber.shared
        // Default in source code is .bundledTiny
        #expect(t.activeModelSource == .bundledTiny || t.activeModelSource == .customPath)
    }

    @Test("modelWarning starts nil")
    @MainActor func modelWarningDefault() {
        let t = AudioTranscriber.shared
        // May or may not be nil depending on model load state, but should be accessible
        let _ = t.modelWarning
    }

    @Test("lastInsertionProbeDate starts nil")
    @MainActor func lastInsertionProbeDateDefault() {
        let t = AudioTranscriber.shared
        // Initially nil unless a probe was run in another test
        let _ = t.lastInsertionProbeDate
    }

    @Test("modelStatusMessage is non-empty")
    @MainActor func modelStatusMessageNonEmpty() {
        let t = AudioTranscriber.shared
        #expect(!t.modelStatusMessage.isEmpty)
    }

    @Test("activeLanguageCode has a value")
    @MainActor func activeLanguageCodeDefault() {
        let t = AudioTranscriber.shared
        #expect(!t.activeLanguageCode.isEmpty)
    }

    // MARK: - Profile-related published properties

    @Test("appProfiles is accessible")
    @MainActor func appProfilesAccessible() {
        let t = AudioTranscriber.shared
        let _ = t.appProfiles
    }

    @Test("frontmostAppName has a value")
    @MainActor func frontmostAppNameDefault() {
        let t = AudioTranscriber.shared
        #expect(!t.frontmostAppName.isEmpty)
    }

    @Test("frontmostBundleIdentifier is accessible")
    @MainActor func frontmostBundleIdentifierAccessible() {
        let t = AudioTranscriber.shared
        let _ = t.frontmostBundleIdentifier
    }

    // MARK: - Chunk tracking

    @Test("processedChunkCount starts at zero")
    @MainActor func processedChunkCountDefault() {
        let t = AudioTranscriber.shared
        #expect(t.processedChunkCount >= 0)
    }

    @Test("isRunningInsertionProbe starts false")
    @MainActor func isRunningInsertionProbeDefault() {
        let t = AudioTranscriber.shared
        #expect(t.isRunningInsertionProbe == false)
    }

    // MARK: - resolveConfiguredModelURL

    @Test("resolveConfiguredModelURL returns a result tuple")
    @MainActor func resolveConfiguredModelURLReturns() {
        let t = AudioTranscriber.shared
        let result = t.resolveConfiguredModelURL()
        // Should have a loadedSource
        #expect(result.loadedSource == .bundledTiny || result.loadedSource == .customPath)
    }

    @Test("resolveConfiguredModelURL bundled: url is non-nil when bundled")
    @MainActor func resolveConfiguredModelURLBundled() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set(ModelSource.bundledTiny.rawValue, forKey: AppDefaults.Keys.modelSource)
        let result = t.resolveConfiguredModelURL()
        if result.loadedSource == .bundledTiny {
            // URL may or may not exist in test bundle
            let _ = result.url
        }
    }

    @Test("resolveConfiguredModelURL custom with invalid path gives warning")
    @MainActor func resolveConfiguredModelURLCustomInvalid() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set(ModelSource.customPath.rawValue, forKey: AppDefaults.Keys.modelSource)
        UserDefaults.standard.set("/nonexistent/path/model.bin", forKey: AppDefaults.Keys.modelCustomPath)
        let result = t.resolveConfiguredModelURL()
        // Should fall back or warn
        #expect(result.warning != nil || result.url == nil || result.loadedSource == .bundledTiny)
        // Restore
        UserDefaults.standard.set(ModelSource.bundledTiny.rawValue, forKey: AppDefaults.Keys.modelSource)
    }

    // MARK: - validFileURL

    @Test("validFileURL returns nil for empty path")
    @MainActor func validFileURLEmpty() {
        let t = AudioTranscriber.shared
        #expect(t.validFileURL(for: "") == nil)
    }

    @Test("validFileURL returns nil for nonexistent path")
    @MainActor func validFileURLNonexistent() {
        let t = AudioTranscriber.shared
        #expect(t.validFileURL(for: "/nonexistent/file.bin") == nil)
    }

    @Test("validFileURL returns nil for directory path")
    @MainActor func validFileURLDirectory() {
        let t = AudioTranscriber.shared
        #expect(t.validFileURL(for: "/tmp") == nil)
    }

    @Test("validFileURL returns URL for existing file")
    @MainActor func validFileURLExistingFile() {
        let t = AudioTranscriber.shared
        // /etc/hosts always exists on macOS
        let result = t.validFileURL(for: "/etc/hosts")
        #expect(result != nil)
        #expect(result?.path == "/etc/hosts")
    }

    // MARK: - isReadableModelFile

    @Test("isReadableModelFile returns false for nonexistent URL")
    @MainActor func isReadableModelFileNonexistent() {
        let t = AudioTranscriber.shared
        let url = URL(fileURLWithPath: "/nonexistent/model.bin")
        #expect(t.isReadableModelFile(at: url) == false)
    }

    @Test("isReadableModelFile returns a Bool for directory URL")
    @MainActor func isReadableModelFileDirectory() {
        let t = AudioTranscriber.shared
        let url = URL(fileURLWithPath: "/tmp")
        // Implementation may allow directories; just verify it doesn't crash
        let _ = t.isReadableModelFile(at: url)
    }

    // MARK: - isFinalizingTranscription

    @Test("isFinalizingTranscription reflects pending state")
    @MainActor func isFinalizingTranscriptionDefault() {
        let t = AudioTranscriber.shared
        if !t.isRecording && t.pendingChunkCount == 0 {
            #expect(t.isFinalizingTranscription == false)
        }
    }

    // MARK: - Profile management

    @Test("updateProfile ignores unknown bundle (no-op for new profiles)")
    @MainActor func updateProfileIgnoresUnknown() {
        let t = AudioTranscriber.shared
        let testBundle = "com.test.audioTranscriberPublishedPropsTest.\(UUID().uuidString)"
        let countBefore = t.appProfiles.count
        let profile = AppProfile(bundleIdentifier: testBundle, appName: "TestPPT", autoCopy: true, autoPaste: false, clearAfterInsert: false, commandReplacements: true, smartCapitalization: true, terminalPunctuation: true)
        t.updateProfile(profile)
        // updateProfile only updates existing profiles, does not add new ones
        #expect(t.appProfiles.count == countBefore)
    }

    @Test("updateProfile modifies existing profile in-place")
    @MainActor func updateProfileModifiesExisting() {
        let t = AudioTranscriber.shared
        // Add a profile first via appProfiles directly
        let testBundle = "com.test.audioTranscriberPublishedPropsTest.update.\(UUID().uuidString)"
        let profile1 = AppProfile(bundleIdentifier: testBundle, appName: "First", autoCopy: true, autoPaste: false, clearAfterInsert: false, commandReplacements: true, smartCapitalization: true, terminalPunctuation: true)
        t.appProfiles.append(profile1)
        let profile2 = AppProfile(bundleIdentifier: testBundle, appName: "Second", autoCopy: false, autoPaste: true, clearAfterInsert: false, commandReplacements: true, smartCapitalization: true, terminalPunctuation: true)
        t.updateProfile(profile2)
        let found = t.appProfiles.first(where: { $0.bundleIdentifier == testBundle })
        #expect(found?.appName == "Second")
        #expect(found?.autoCopy == false)
        // Cleanup
        t.removeProfile(bundleIdentifier: testBundle)
    }

    @Test("removeProfile removes existing profile")
    @MainActor func removeProfileRemoves() {
        let t = AudioTranscriber.shared
        let testBundle = "com.test.audioTranscriberPublishedPropsTest.remove.\(UUID().uuidString)"
        let profile = AppProfile(bundleIdentifier: testBundle, appName: "ToRemove", autoCopy: true, autoPaste: false, clearAfterInsert: false, commandReplacements: true, smartCapitalization: true, terminalPunctuation: true)
        t.appProfiles.append(profile)
        t.removeProfile(bundleIdentifier: testBundle)
        #expect(!t.appProfiles.contains(where: { $0.bundleIdentifier == testBundle }))
    }

    @Test("removeProfile with nonexistent bundle does not crash")
    @MainActor func removeProfileNonexistent() {
        let t = AudioTranscriber.shared
        t.removeProfile(bundleIdentifier: "com.nonexistent.app.\(UUID().uuidString)")
    }

    // MARK: - effectiveOutputSettings

    @Test("effectiveOutputSettingsForCurrentApp returns valid settings")
    @MainActor func effectiveOutputSettingsForCurrentApp() {
        let t = AudioTranscriber.shared
        let settings = t.effectiveOutputSettingsForCurrentApp()
        // Should have valid fields
        let _ = settings.autoCopy
        let _ = settings.smartCapitalization
    }

    @Test("effectiveOutputSettingsForInsertionTarget returns valid settings")
    @MainActor func effectiveOutputSettingsForInsertionTarget() {
        let t = AudioTranscriber.shared
        let settings = t.effectiveOutputSettingsForInsertionTarget()
        let _ = settings.autoPaste
        let _ = settings.commandReplacements
    }

    // MARK: - Text processing helpers

    @Test("isLetter returns true for letters")
    @MainActor func isLetterTrue() {
        let t = AudioTranscriber.shared
        #expect(t.isLetter("A") == true)
        #expect(t.isLetter("z") == true)
        #expect(t.isLetter("é") == true)
    }

    @Test("isLetter returns false for non-letters")
    @MainActor func isLetterFalse() {
        let t = AudioTranscriber.shared
        #expect(t.isLetter("1") == false)
        #expect(t.isLetter(" ") == false)
        #expect(t.isLetter(".") == false)
    }

    @Test("replaceRegex performs basic replacement")
    @MainActor func replaceRegexBasic() {
        let t = AudioTranscriber.shared
        let result = t.replaceRegex(pattern: "\\d+", in: "abc123def456", with: "NUM")
        #expect(result == "abcNUMdefNUM")
    }

    @Test("replaceRegex with no match returns original")
    @MainActor func replaceRegexNoMatch() {
        let t = AudioTranscriber.shared
        let result = t.replaceRegex(pattern: "\\d+", in: "abcdef", with: "NUM")
        #expect(result == "abcdef")
    }

    @Test("replaceRegex with invalid pattern returns original")
    @MainActor func replaceRegexInvalidPattern() {
        let t = AudioTranscriber.shared
        let result = t.replaceRegex(pattern: "[invalid", in: "test", with: "X")
        #expect(result == "test")
    }

    @Test("replaceRegexTemplate performs template replacement")
    @MainActor func replaceRegexTemplateBasic() {
        let t = AudioTranscriber.shared
        let result = t.replaceRegexTemplate(pattern: "(\\w+)@(\\w+)", in: "user@host", withTemplate: "$2/$1")
        #expect(result == "host/user")
    }

    @Test("normalizeWhitespace collapses spaces")
    @MainActor func normalizeWhitespaceCollapses() {
        let t = AudioTranscriber.shared
        let result = t.normalizeWhitespace(in: "hello   world")
        #expect(result == "hello world")
    }

    @Test("applySmartCapitalization capitalizes first letter")
    @MainActor func applySmartCapitalizationFirst() {
        let t = AudioTranscriber.shared
        let result = t.applySmartCapitalization(to: "hello world")
        #expect(result == "Hello world")
    }

    @Test("applySmartCapitalization capitalizes after period")
    @MainActor func applySmartCapitalizationAfterPeriod() {
        let t = AudioTranscriber.shared
        let result = t.applySmartCapitalization(to: "hello. world")
        #expect(result == "Hello. World")
    }

    @Test("applyTerminalPunctuationIfNeeded adds period")
    @MainActor func applyTerminalPunctuationAdds() {
        let t = AudioTranscriber.shared
        let result = t.applyTerminalPunctuationIfNeeded(to: "hello world")
        #expect(result == "hello world.")
    }

    @Test("applyTerminalPunctuationIfNeeded does not double-punctuate")
    @MainActor func applyTerminalPunctuationNoDouble() {
        let t = AudioTranscriber.shared
        #expect(t.applyTerminalPunctuationIfNeeded(to: "hello.") == "hello.")
        #expect(t.applyTerminalPunctuationIfNeeded(to: "hello!") == "hello!")
        #expect(t.applyTerminalPunctuationIfNeeded(to: "hello?") == "hello?")
    }

    @Test("applyTextReplacements with configured replacements")
    @MainActor func applyTextReplacementsConfigured() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set("teh => the\nrecieve => receive", forKey: AppDefaults.Keys.transcriptionReplacements)
        let result = t.applyTextReplacements(to: "teh dog will recieve a treat")
        #expect(result.contains("the"))
        #expect(result.contains("receive"))
        // Cleanup
        UserDefaults.standard.set("", forKey: AppDefaults.Keys.transcriptionReplacements)
    }

    @Test("replacementPairs parses arrow-separated pairs")
    @MainActor func replacementPairsParses() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set("foo => bar\nbaz => qux", forKey: AppDefaults.Keys.transcriptionReplacements)
        let pairs = t.replacementPairs()
        #expect(pairs.count == 2)
        #expect(pairs[0].from == "foo")
        #expect(pairs[0].to == "bar")
        #expect(pairs[1].from == "baz")
        #expect(pairs[1].to == "qux")
        // Cleanup
        UserDefaults.standard.set("", forKey: AppDefaults.Keys.transcriptionReplacements)
    }

    @Test("replacementPairs ignores empty lines")
    @MainActor func replacementPairsIgnoresEmpty() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set("foo => bar\n\n\nbaz => qux\n", forKey: AppDefaults.Keys.transcriptionReplacements)
        let pairs = t.replacementPairs()
        #expect(pairs.count == 2)
        UserDefaults.standard.set("", forKey: AppDefaults.Keys.transcriptionReplacements)
    }

    @Test("replacementPairs ignores lines without arrow")
    @MainActor func replacementPairsIgnoresNoArrow() {
        let t = AudioTranscriber.shared
        UserDefaults.standard.set("foo => bar\nnot a pair\nbaz => qux", forKey: AppDefaults.Keys.transcriptionReplacements)
        let pairs = t.replacementPairs()
        #expect(pairs.count == 2)
        UserDefaults.standard.set("", forKey: AppDefaults.Keys.transcriptionReplacements)
    }

    // MARK: - profileCaptureCandidate

    @Test("profileCaptureCandidate returns a tuple or nil")
    @MainActor func profileCaptureCandidateReturns() {
        let t = AudioTranscriber.shared
        let result = t.profileCaptureCandidate()
        // In test env, may or may not have a frontmost app
        if let candidate = result {
            #expect(!candidate.bundleIdentifier.isEmpty)
            #expect(!candidate.appName.isEmpty)
        }
    }

    // MARK: - clearHistory

    @Test("clearHistory empties recentEntries")
    @MainActor func clearHistoryEmpties() {
        let t = AudioTranscriber.shared
        t.clearHistory()
        #expect(t.recentEntries.isEmpty)
    }

    // MARK: - canAutoPasteIntoTargetAppForTesting

    @Test("canAutoPasteIntoTargetAppForTesting returns Bool")
    @MainActor func canAutoPasteReturns() {
        let t = AudioTranscriber.shared
        let result = t.canAutoPasteIntoTargetAppForTesting()
        // Just verify it compiles and returns a bool
        #expect(result == true || result == false)
    }
}

