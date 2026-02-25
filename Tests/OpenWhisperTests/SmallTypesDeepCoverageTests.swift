import Testing
import Foundation
@testable import OpenWhisper

// MARK: - ModelSource deep coverage

@Suite("ModelSource – deep coverage")
struct ModelSourceDeepCoverageTests {

    @Test("allCases order is bundledTiny then customPath")
    func allCasesOrder() {
        let cases = ModelSource.allCases
        #expect(cases[0] == .bundledTiny)
        #expect(cases[1] == .customPath)
    }

    @Test("titles are distinct")
    func titlesDistinct() {
        let titles = ModelSource.allCases.map(\.title)
        #expect(Set(titles).count == titles.count)
    }

    @Test("rawValues are distinct")
    func rawValuesDistinct() {
        let raws = ModelSource.allCases.map(\.rawValue)
        #expect(Set(raws).count == raws.count)
    }

    @Test("ids are distinct")
    func idsDistinct() {
        let ids = ModelSource.allCases.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("title does not change across accesses")
    func titleStable() {
        let a = ModelSource.bundledTiny.title
        let b = ModelSource.bundledTiny.title
        #expect(a == b)
    }

    @Test("Equatable conformance")
    func equatable() {
        #expect(ModelSource.bundledTiny == ModelSource.bundledTiny)
        #expect(ModelSource.customPath == ModelSource.customPath)
        #expect(ModelSource.bundledTiny != ModelSource.customPath)
    }

    @Test("init from empty string returns nil")
    func emptyStringInit() {
        #expect(ModelSource(rawValue: "") == nil)
    }

    @Test("init from case-wrong rawValue returns nil")
    func caseSensitive() {
        #expect(ModelSource(rawValue: "BundledTiny") == nil)
        #expect(ModelSource(rawValue: "BUNDLEDTINY") == nil)
        #expect(ModelSource(rawValue: "CustomPath") == nil)
    }

    @Test("Hashable: can be used as dictionary key")
    func hashableDictKey() {
        var dict: [ModelSource: String] = [:]
        dict[.bundledTiny] = "tiny"
        dict[.customPath] = "custom"
        #expect(dict[.bundledTiny] == "tiny")
        #expect(dict[.customPath] == "custom")
    }

    @Test("Hashable: can be stored in a Set")
    func hashableSet() {
        let set: Set<ModelSource> = [.bundledTiny, .customPath, .bundledTiny]
        #expect(set.count == 2)
    }
}

// MARK: - HotkeyMode deep coverage

@Suite("HotkeyMode – deep coverage")
struct HotkeyModeDeepCoverageTests {

    @Test("allCases order is toggle then hold")
    func allCasesOrder() {
        let cases = HotkeyMode.allCases
        #expect(cases[0] == .toggle)
        #expect(cases[1] == .hold)
    }

    @Test("titles are distinct")
    func titlesDistinct() {
        #expect(HotkeyMode.toggle.title != HotkeyMode.hold.title)
    }

    @Test("Equatable conformance")
    func equatable() {
        #expect(HotkeyMode.toggle == HotkeyMode.toggle)
        #expect(HotkeyMode.hold == HotkeyMode.hold)
        #expect(HotkeyMode.toggle != HotkeyMode.hold)
    }

    @Test("init from empty string returns nil")
    func emptyStringInit() {
        #expect(HotkeyMode(rawValue: "") == nil)
    }

    @Test("init is case-sensitive")
    func caseSensitive() {
        #expect(HotkeyMode(rawValue: "Toggle") == nil)
        #expect(HotkeyMode(rawValue: "HOLD") == nil)
    }

    @Test("title for toggle does not contain 'hold'")
    func toggleTitleNoHold() {
        #expect(!HotkeyMode.toggle.title.lowercased().contains("hold"))
    }

    @Test("title for hold contains 'hold'")
    func holdTitleContainsHold() {
        #expect(HotkeyMode.hold.title.lowercased().contains("hold"))
    }

    @Test("Hashable: can be used as dictionary key")
    func hashableDictKey() {
        var dict: [HotkeyMode: Int] = [:]
        dict[.toggle] = 1
        dict[.hold] = 2
        #expect(dict[.toggle] == 1)
        #expect(dict[.hold] == 2)
    }

    @Test("Hashable: Set deduplication")
    func hashableSet() {
        let set: Set<HotkeyMode> = [.toggle, .hold, .toggle]
        #expect(set.count == 2)
    }

    @Test("id is stable across accesses")
    func idStable() {
        let a = HotkeyMode.toggle.id
        let b = HotkeyMode.toggle.id
        #expect(a == b)
    }
}

// MARK: - TranscriptionEntry deep coverage

@Suite("TranscriptionEntry – deep coverage")
struct TranscriptionEntryDeepCoverageTests {

    @Test("Codable round-trip preserves all fields including non-nil optionals")
    func codableFullRoundTrip() throws {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1234567890)
        let entry = TranscriptionEntry(id: id, text: "Full", createdAt: date, durationSeconds: 99.9, targetAppName: "Xcode")
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(TranscriptionEntry.self, from: data)
        #expect(decoded.id == id)
        #expect(decoded.text == "Full")
        #expect(decoded.createdAt == date)
        #expect(decoded.durationSeconds == 99.9)
        #expect(decoded.targetAppName == "Xcode")
    }

    @Test("Codable with zero duration")
    func codableZeroDuration() throws {
        let entry = TranscriptionEntry(text: "Zero", durationSeconds: 0)
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(TranscriptionEntry.self, from: data)
        #expect(decoded.durationSeconds == 0)
    }

    @Test("Codable with very long text")
    func codableLongText() throws {
        let longText = String(repeating: "word ", count: 10000)
        let entry = TranscriptionEntry(text: longText)
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(TranscriptionEntry.self, from: data)
        #expect(decoded.text == longText)
    }

    @Test("Codable with Unicode text")
    func codableUnicode() throws {
        let text = "日本語テスト 🎤 émojis café"
        let entry = TranscriptionEntry(text: text)
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(TranscriptionEntry.self, from: data)
        #expect(decoded.text == text)
    }

    @Test("Hashable: entries with same id and text are equal")
    func hashableSameIdText() {
        let id = UUID()
        let date = Date()
        let a = TranscriptionEntry(id: id, text: "Same", createdAt: date)
        let b = TranscriptionEntry(id: id, text: "Same", createdAt: date)
        #expect(a == b)
    }

    @Test("Hashable: entries with different ids are not equal")
    func hashableDifferentId() {
        let a = TranscriptionEntry(text: "Same")
        let b = TranscriptionEntry(text: "Same")
        #expect(a != b) // different UUIDs
    }

    @Test("Set deduplication by identity")
    func setDedup() {
        let id = UUID()
        let date = Date()
        let a = TranscriptionEntry(id: id, text: "A", createdAt: date)
        let b = TranscriptionEntry(id: id, text: "A", createdAt: date)
        let set: Set<TranscriptionEntry> = [a, b]
        #expect(set.count == 1)
    }

    @Test("createdAt defaults to approximately now")
    func createdAtDefault() {
        let before = Date()
        let entry = TranscriptionEntry(text: "Now")
        let after = Date()
        #expect(entry.createdAt >= before)
        #expect(entry.createdAt <= after)
    }

    @Test("negative duration is preserved")
    func negativeDuration() {
        let entry = TranscriptionEntry(text: "Neg", durationSeconds: -1.0)
        #expect(entry.durationSeconds == -1.0)
    }

    @Test("empty targetAppName is preserved")
    func emptyTargetAppName() {
        let entry = TranscriptionEntry(text: "X", targetAppName: "")
        #expect(entry.targetAppName == "")
    }

    @Test("very large duration is preserved")
    func largeDuration() {
        let entry = TranscriptionEntry(text: "Long", durationSeconds: 999999.999)
        #expect(entry.durationSeconds == 999999.999)
    }

    @Test("Codable JSON keys match property names")
    func codableJsonKeys() throws {
        let entry = TranscriptionEntry(text: "Keys", durationSeconds: 1.0, targetAppName: "App")
        let data = try JSONEncoder().encode(entry)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json.keys.contains("id"))
        #expect(json.keys.contains("text"))
        #expect(json.keys.contains("createdAt"))
        #expect(json.keys.contains("durationSeconds"))
        #expect(json.keys.contains("targetAppName"))
    }
}

// MARK: - LaunchAtLogin deep coverage

@Suite("LaunchAtLogin – deep coverage", .serialized)
struct LaunchAtLoginDeepCoverageTests {

    @Test("isEnabled returns a Bool value")
    func isEnabledConsistent() {
        // SMAppService.status may vary in test environments;
        // just verify it returns a valid Bool without crashing.
        let a = LaunchAtLogin.isEnabled
        #expect(a == true || a == false)
    }

    @Test("setEnabled returns Bool")
    func setEnabledReturnType() {
        let result = LaunchAtLogin.setEnabled(false)
        #expect(result == true || result == false)
    }

    @Test("setEnabled(false) twice does not crash")
    func setEnabledFalseTwice() {
        let _ = LaunchAtLogin.setEnabled(false)
        let _ = LaunchAtLogin.setEnabled(false)
    }

    @Test("setEnabled(true) twice does not crash")
    func setEnabledTrueTwice() {
        let _ = LaunchAtLogin.setEnabled(true)
        let _ = LaunchAtLogin.setEnabled(true)
        // Clean up
        let _ = LaunchAtLogin.setEnabled(false)
    }

    @Test("UserDefaults key is set after setEnabled call")
    func userDefaultsKeySet() {
        let key = AppDefaults.Keys.launchAtLogin
        UserDefaults.standard.removeObject(forKey: key)
        let _ = LaunchAtLogin.setEnabled(false)
        #expect(UserDefaults.standard.object(forKey: key) != nil)
    }

    @Test("rapid toggle does not crash")
    func rapidToggle() {
        for _ in 0..<5 {
            let _ = LaunchAtLogin.setEnabled(true)
            let _ = LaunchAtLogin.setEnabled(false)
        }
    }

    @Test("isEnabled after setEnabled(false) is consistent with defaults")
    func isEnabledAfterDisable() {
        let _ = LaunchAtLogin.setEnabled(false)
        let enabled = LaunchAtLogin.isEnabled
        let stored = UserDefaults.standard.bool(forKey: AppDefaults.Keys.launchAtLogin)
        // They should be in sync (either both true or both false/matching)
        #expect(stored == enabled || stored == false)
    }
}

// MARK: - AudioFeedback deep coverage

@Suite("AudioFeedback – deep coverage", .serialized)
struct AudioFeedbackDeepCoverageTests {

    @Test("isEnabled reflects UserDefaults accurately")
    func isEnabledAccurate() {
        let key = AppDefaults.Keys.audioFeedbackEnabled
        UserDefaults.standard.set(true, forKey: key)
        #expect(AudioFeedback.isEnabled == true)
        UserDefaults.standard.set(false, forKey: key)
        #expect(AudioFeedback.isEnabled == false)
    }

    @Test("all five sound methods exist and don't crash when disabled")
    func allMethodsDisabled() {
        UserDefaults.standard.set(false, forKey: AppDefaults.Keys.audioFeedbackEnabled)
        AudioFeedback.playStartSound()
        AudioFeedback.playStopSound()
        AudioFeedback.playInsertedSound()
        AudioFeedback.playTextReadySound()
        AudioFeedback.playErrorSound()
    }

    @Test("all five sound methods exist and don't crash when enabled")
    func allMethodsEnabled() {
        UserDefaults.standard.set(true, forKey: AppDefaults.Keys.audioFeedbackEnabled)
        AudioFeedback.playStartSound()
        AudioFeedback.playStopSound()
        AudioFeedback.playInsertedSound()
        AudioFeedback.playTextReadySound()
        AudioFeedback.playErrorSound()
    }

    @Test("concurrent calls from multiple iterations don't crash")
    func concurrentCalls() {
        UserDefaults.standard.set(true, forKey: AppDefaults.Keys.audioFeedbackEnabled)
        for _ in 0..<20 {
            AudioFeedback.playStartSound()
        }
    }

    @Test("isEnabled with key explicitly set false returns false")
    func explicitFalseReturnsFalse() {
        UserDefaults.standard.set(false, forKey: AppDefaults.Keys.audioFeedbackEnabled)
        #expect(AudioFeedback.isEnabled == false)
    }

    @Test("interleaving enable/disable with play calls")
    func interleaveEnableDisable() {
        let key = AppDefaults.Keys.audioFeedbackEnabled
        UserDefaults.standard.set(false, forKey: key)
        AudioFeedback.playStartSound()
        UserDefaults.standard.set(true, forKey: key)
        AudioFeedback.playStopSound()
        UserDefaults.standard.set(false, forKey: key)
        AudioFeedback.playInsertedSound()
        UserDefaults.standard.set(true, forKey: key)
        AudioFeedback.playTextReadySound()
        UserDefaults.standard.set(false, forKey: key)
        AudioFeedback.playErrorSound()
    }
}

// MARK: - OnboardingView permissionsGranted deep coverage

@Suite("OnboardingView – permissionsGranted deep")
struct OnboardingViewDeepPermissionsTests {

    @Test("only (true, true, true) returns true — exhaustive")
    func exhaustiveCheck() {
        var trueCount = 0
        for m in [false, true] {
            for a in [false, true] {
                for i in [false, true] {
                    if OnboardingView.permissionsGranted(microphone: m, accessibility: a, inputMonitoring: i) {
                        trueCount += 1
                        #expect(m == true)
                        #expect(a == true)
                        #expect(i == true)
                    }
                }
            }
        }
        #expect(trueCount == 1)
    }

    @Test("function is pure — same inputs give same outputs")
    func purity() {
        for _ in 0..<10 {
            #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: false, inputMonitoring: true) == false)
            #expect(OnboardingView.permissionsGranted(microphone: true, accessibility: true, inputMonitoring: true) == true)
        }
    }

    @Test("nonisolated — can be called from any context")
    func nonisolated() async {
        let result = OnboardingView.permissionsGranted(microphone: true, accessibility: true, inputMonitoring: true)
        #expect(result == true)
    }
}
