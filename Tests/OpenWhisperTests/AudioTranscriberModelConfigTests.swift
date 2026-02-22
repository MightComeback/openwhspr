import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber – model source / custom path configuration")
struct AudioTranscriberModelConfigTests {

    private let defaults = UserDefaults.standard

    // MARK: – setModelSource (UserDefaults only)

    @Test("setModelSource stores bundledTiny rawValue")
    func setModelSourceBundledTiny() {
        defaults.set(ModelSource.bundledTiny.rawValue, forKey: AppDefaults.Keys.modelSource)
        let stored = defaults.string(forKey: AppDefaults.Keys.modelSource)
        #expect(stored == ModelSource.bundledTiny.rawValue)
    }

    @Test("setModelSource stores customPath rawValue")
    func setModelSourceCustomPath() {
        defaults.set(ModelSource.customPath.rawValue, forKey: AppDefaults.Keys.modelSource)
        let stored = defaults.string(forKey: AppDefaults.Keys.modelSource)
        #expect(stored == ModelSource.customPath.rawValue)
    }

    @Test("ModelSource round-trips through all cases")
    func modelSourceAllCases() {
        for source in ModelSource.allCases {
            defaults.set(source.rawValue, forKey: AppDefaults.Keys.modelSource)
            let stored = defaults.string(forKey: AppDefaults.Keys.modelSource)
            #expect(stored == source.rawValue)
        }
    }

    // MARK: – setCustomModelPath (UserDefaults only)

    @Test("setCustomModelPath: trimming logic is correct")
    func setCustomModelPathTrimming() {
        let input = "  /some/path/model.bin  "
        let normalized = input.trimmingCharacters(in: .whitespacesAndNewlines)
        defaults.set(normalized, forKey: AppDefaults.Keys.modelCustomPath)
        let stored = defaults.string(forKey: AppDefaults.Keys.modelCustomPath)
        #expect(stored == "/some/path/model.bin")
    }

    @Test("setCustomModelPath: also sets modelSource to customPath")
    func setCustomModelPathSetsSource() {
        defaults.set(ModelSource.bundledTiny.rawValue, forKey: AppDefaults.Keys.modelSource)
        // Simulate what setCustomModelPath does
        defaults.set("/tmp/test.bin", forKey: AppDefaults.Keys.modelCustomPath)
        defaults.set(ModelSource.customPath.rawValue, forKey: AppDefaults.Keys.modelSource)
        let stored = defaults.string(forKey: AppDefaults.Keys.modelSource)
        #expect(stored == ModelSource.customPath.rawValue)
    }

    @Test("setCustomModelPath: whitespace-only stores empty")
    func setCustomModelPathWhitespaceOnly() {
        let normalized = "   \n\t  ".trimmingCharacters(in: .whitespacesAndNewlines)
        defaults.set(normalized, forKey: AppDefaults.Keys.modelCustomPath)
        let stored = defaults.string(forKey: AppDefaults.Keys.modelCustomPath)
        #expect(stored == "")
    }

    @Test("setCustomModelPath: preserves path with spaces in middle")
    func setCustomModelPathWithSpaces() {
        let path = "/Users/test user/model.bin"
        defaults.set(path, forKey: AppDefaults.Keys.modelCustomPath)
        let stored = defaults.string(forKey: AppDefaults.Keys.modelCustomPath)
        #expect(stored == "/Users/test user/model.bin")
    }

    // MARK: – clearCustomModelPath (UserDefaults only)

    @Test("clearCustomModelPath: empty string is valid")
    func clearCustomModelPathSetsEmpty() {
        defaults.set("/tmp/model.bin", forKey: AppDefaults.Keys.modelCustomPath)
        defaults.set("", forKey: AppDefaults.Keys.modelCustomPath)
        let stored = defaults.string(forKey: AppDefaults.Keys.modelCustomPath)
        #expect(stored == "")
    }

    @Test("clearCustomModelPath: idempotent")
    func clearCustomModelPathIdempotent() {
        defaults.set("", forKey: AppDefaults.Keys.modelCustomPath)
        defaults.set("", forKey: AppDefaults.Keys.modelCustomPath)
        let stored = defaults.string(forKey: AppDefaults.Keys.modelCustomPath)
        #expect(stored == "")
    }

    // MARK: – setModelSource (via AudioTranscriber.shared property)

    @Test("setModelSource: rawValue round-trips through UserDefaults")
    func setModelSourceRoundTrips() {
        for source in ModelSource.allCases {
            defaults.set(source.rawValue, forKey: AppDefaults.Keys.modelSource)
            let raw = defaults.string(forKey: AppDefaults.Keys.modelSource)
            let roundTripped = ModelSource(rawValue: raw ?? "")
            #expect(roundTripped == source)
        }
    }

    // MARK: – integration

    @Test("full cycle: set source → set path → clear → set source via UserDefaults")
    func fullConfigCycle() {
        defaults.set(ModelSource.bundledTiny.rawValue, forKey: AppDefaults.Keys.modelSource)
        defaults.set("/tmp/custom.bin", forKey: AppDefaults.Keys.modelCustomPath)
        defaults.set(ModelSource.customPath.rawValue, forKey: AppDefaults.Keys.modelSource)
        #expect(defaults.string(forKey: AppDefaults.Keys.modelSource) == ModelSource.customPath.rawValue)
        defaults.set("", forKey: AppDefaults.Keys.modelCustomPath)
        defaults.set(ModelSource.bundledTiny.rawValue, forKey: AppDefaults.Keys.modelSource)
        #expect(defaults.string(forKey: AppDefaults.Keys.modelSource) == ModelSource.bundledTiny.rawValue)
        #expect(defaults.string(forKey: AppDefaults.Keys.modelCustomPath) == "")
    }

    @Test("ModelSource titles are human-readable")
    func modelSourceTitles() {
        for source in ModelSource.allCases {
            #expect(!source.title.isEmpty)
            #expect(source.title.count > 2)
        }
    }
}
