import Testing
@testable import OpenWhisper

@Suite("HotkeyMode")
struct HotkeyModeTests {

    @Test("All cases exist")
    func allCases() {
        let cases = HotkeyMode.allCases
        #expect(cases.count == 2)
        #expect(cases.contains(.toggle))
        #expect(cases.contains(.hold))
    }

    @Test("id equals rawValue")
    func idMatchesRawValue() {
        for mode in HotkeyMode.allCases {
            #expect(mode.id == mode.rawValue)
        }
    }

    @Test("titles are human-readable")
    func titles() {
        #expect(HotkeyMode.toggle.title == "Toggle")
        #expect(HotkeyMode.hold.title == "Hold to talk")
    }

    @Test("rawValues are stable")
    func rawValues() {
        #expect(HotkeyMode.toggle.rawValue == "toggle")
        #expect(HotkeyMode.hold.rawValue == "hold")
    }

    @Test("init from rawValue round-trips")
    func rawValueRoundTrip() {
        for mode in HotkeyMode.allCases {
            #expect(HotkeyMode(rawValue: mode.rawValue) == mode)
        }
    }

    @Test("invalid rawValue returns nil")
    func invalidRawValue() {
        #expect(HotkeyMode(rawValue: "push") == nil)
    }
}
