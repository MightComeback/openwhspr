@preconcurrency import AppKit
import Foundation

/// Plays short system sounds to confirm hotkey-triggered recording events.
///
/// Users pressing a global hotkey from another app need audible confirmation
/// that recording started or stopped, since the menu bar popover is not visible.
enum AudioFeedback {

    /// Play a short "recording started" sound.
    static func playStartSound() {
        guard isEnabled else { return }
        // "Tink" is a brief, distinct tap — ideal for "armed" feedback.
        playSystemSound(named: "Tink")
    }

    /// Play a short "recording stopped / finalized" sound.
    static func playStopSound() {
        guard isEnabled else { return }
        // "Pop" is a soft confirmation — signals recording ended.
        playSystemSound(named: "Pop")
    }

    /// Play a short "text inserted successfully" sound.
    ///
    /// Users triggering dictation via global hotkey from another app cannot see
    /// the menu bar popover, so an audible cue confirms that auto-paste into the
    /// target app completed successfully.
    static func playInsertedSound() {
        guard isEnabled else { return }
        // "Purr" is a subtle, satisfying confirmation — signals text landed.
        playSystemSound(named: "Purr")
    }

    /// Play a short "action failed / needs attention" sound.
    static func playErrorSound() {
        guard isEnabled else { return }
        // "Basso" is macOS's standard error tone — signals something went wrong.
        playSystemSound(named: "Basso")
    }

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: AppDefaults.Keys.audioFeedbackEnabled)
    }

    private static func playSystemSound(named name: String) {
        guard let sound = NSSound(named: name) else { return }
        sound.stop()
        sound.play()
    }
}
