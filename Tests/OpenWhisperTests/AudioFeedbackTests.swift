import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioFeedback")
struct AudioFeedbackTests {

    @Test("isEnabled reads from UserDefaults")
    func isEnabledReadsDefaults() {
        let key = AppDefaults.Keys.audioFeedbackEnabled
        UserDefaults.standard.set(true, forKey: key)
        #expect(AudioFeedback.isEnabled == true)
        UserDefaults.standard.set(false, forKey: key)
        #expect(AudioFeedback.isEnabled == false)
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
}
