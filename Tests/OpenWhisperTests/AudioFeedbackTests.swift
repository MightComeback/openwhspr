import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioFeedback", .serialized)
struct AudioFeedbackTests {

    @Test("isEnabled reads from UserDefaults")
    @MainActor func isEnabledReadsDefaults() {
        let key = AppDefaults.Keys.audioFeedbackEnabled
        UserDefaults.standard.set(true, forKey: key)
        #expect(UserDefaults.standard.bool(forKey: key) == true)
        #expect(AudioFeedback.isEnabled == true)
        UserDefaults.standard.set(false, forKey: key)
        #expect(AudioFeedback.isEnabled == false)
    }

    @Test("isEnabled uses correct UserDefaults key")
    func isEnabledUsesCorrectKey() {
        let key = AppDefaults.Keys.audioFeedbackEnabled
        // Verify the key is the one AudioFeedback reads
        let before = AudioFeedback.isEnabled
        UserDefaults.standard.set(!before, forKey: key)
        #expect(AudioFeedback.isEnabled == !before)
        // Restore
        UserDefaults.standard.set(before, forKey: key)
    }

    @Test("play methods do not crash when disabled")
    func playMethodsWhenDisabled() {
        UserDefaults.standard.set(false, forKey: AppDefaults.Keys.audioFeedbackEnabled)
        // These should return immediately without crashing
        AudioFeedback.playStartSound()
        AudioFeedback.playStopSound()
        AudioFeedback.playInsertedSound()
        AudioFeedback.playTextReadySound()
        AudioFeedback.playErrorSound()
    }

    @Test("play methods do not crash when enabled")
    func playMethodsWhenEnabled() {
        UserDefaults.standard.set(true, forKey: AppDefaults.Keys.audioFeedbackEnabled)
        // In CI/test environments sounds may not load, but should not crash
        AudioFeedback.playStartSound()
        AudioFeedback.playStopSound()
        AudioFeedback.playInsertedSound()
        AudioFeedback.playTextReadySound()
        AudioFeedback.playErrorSound()
    }

    @Test("toggling isEnabled between calls does not crash")
    func toggleBetweenCalls() {
        UserDefaults.standard.set(true, forKey: AppDefaults.Keys.audioFeedbackEnabled)
        AudioFeedback.playStartSound()
        UserDefaults.standard.set(false, forKey: AppDefaults.Keys.audioFeedbackEnabled)
        AudioFeedback.playStopSound()
        UserDefaults.standard.set(true, forKey: AppDefaults.Keys.audioFeedbackEnabled)
        AudioFeedback.playInsertedSound()
        UserDefaults.standard.set(false, forKey: AppDefaults.Keys.audioFeedbackEnabled)
        AudioFeedback.playErrorSound()
    }

    @Test("rapid successive calls do not crash")
    func rapidSuccessiveCalls() {
        UserDefaults.standard.set(true, forKey: AppDefaults.Keys.audioFeedbackEnabled)
        for _ in 0..<10 {
            AudioFeedback.playStartSound()
            AudioFeedback.playStopSound()
            AudioFeedback.playInsertedSound()
            AudioFeedback.playTextReadySound()
            AudioFeedback.playErrorSound()
        }
    }

    @Test("each sound method is independent when disabled")
    func independentWhenDisabled() {
        UserDefaults.standard.set(false, forKey: AppDefaults.Keys.audioFeedbackEnabled)
        // Each should early-return independently
        AudioFeedback.playStartSound()
        AudioFeedback.playStopSound()
        AudioFeedback.playInsertedSound()
        AudioFeedback.playTextReadySound()
        AudioFeedback.playErrorSound()
        // If we got here without crash, all guard clauses work
    }

    @Test("isEnabled reflects live UserDefaults changes")
    func liveDefaultsChanges() {
        let key = AppDefaults.Keys.audioFeedbackEnabled
        UserDefaults.standard.set(false, forKey: key)
        #expect(AudioFeedback.isEnabled == false)
        UserDefaults.standard.set(true, forKey: key)
        #expect(AudioFeedback.isEnabled == true)
        UserDefaults.standard.set(false, forKey: key)
        #expect(AudioFeedback.isEnabled == false)
    }
}
