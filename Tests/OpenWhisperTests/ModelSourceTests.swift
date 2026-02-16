import Testing
@testable import OpenWhisper

@Suite("ModelSource")
struct ModelSourceTests {

    @Test("All cases exist")
    func allCases() {
        let cases = ModelSource.allCases
        #expect(cases.count == 2)
        #expect(cases.contains(.bundledTiny))
        #expect(cases.contains(.customPath))
    }

    @Test("id equals rawValue")
    func idMatchesRawValue() {
        for source in ModelSource.allCases {
            #expect(source.id == source.rawValue)
        }
    }

    @Test("titles are human-readable")
    func titles() {
        #expect(ModelSource.bundledTiny.title == "Bundled tiny model")
        #expect(ModelSource.customPath.title == "Custom local model")
    }

    @Test("rawValues are stable")
    func rawValues() {
        #expect(ModelSource.bundledTiny.rawValue == "bundledTiny")
        #expect(ModelSource.customPath.rawValue == "customPath")
    }

    @Test("init from rawValue round-trips")
    func rawValueRoundTrip() {
        for source in ModelSource.allCases {
            #expect(ModelSource(rawValue: source.rawValue) == source)
        }
    }

    @Test("invalid rawValue returns nil")
    func invalidRawValue() {
        #expect(ModelSource(rawValue: "nonexistent") == nil)
    }
}
