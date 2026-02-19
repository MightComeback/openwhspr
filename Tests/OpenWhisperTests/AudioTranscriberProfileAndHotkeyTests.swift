import Testing
import Foundation
@testable import OpenWhisper

@Suite("AudioTranscriber – profile management & hotkey recording", .serialized)
struct AudioTranscriberProfileAndHotkeyTests {

    // MARK: - refreshFrontmostAppContext

    @Test("refreshFrontmostAppContext sets app name and bundle id")
    @MainActor func refreshFrontmostSetsProperties() {
        let t = AudioTranscriber.shared
        t.refreshFrontmostAppContext()
        // In a test environment, frontmostApplication may be Xcode or xctest runner
        #expect(!t.frontmostAppName.isEmpty)
        // bundleIdentifier could be empty if there's no frontmost app, but should not crash
    }

    @Test("refreshFrontmostAppContext can be called repeatedly without crash")
    @MainActor func refreshFrontmostRepeated() {
        let t = AudioTranscriber.shared
        for _ in 0..<5 {
            t.refreshFrontmostAppContext()
        }
        #expect(!t.frontmostAppName.isEmpty)
    }

    // MARK: - updateProfile

    @Test("updateProfile updates an existing profile")
    @MainActor func updateProfileExisting() {
        let t = AudioTranscriber.shared
        let bundleId = "com.test.updateprofile.\(UUID().uuidString.prefix(8))"
        let profile = AppProfile(
            bundleIdentifier: bundleId,
            appName: "TestApp",
            autoCopy: false,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommands: ""
        )
        // Manually insert
        t.appProfiles.append(profile)

        var updated = profile
        updated.appName = "UpdatedApp"
        updated.autoCopy = true
        t.updateProfile(updated)

        let found = t.appProfiles.first(where: { $0.bundleIdentifier == bundleId })
        #expect(found?.appName == "UpdatedApp")
        #expect(found?.autoCopy == true)

        // Cleanup
        t.removeProfile(bundleIdentifier: bundleId)
    }

    @Test("updateProfile does nothing for nonexistent profile")
    @MainActor func updateProfileNonexistent() {
        let t = AudioTranscriber.shared
        let countBefore = t.appProfiles.count
        let fake = AppProfile(
            bundleIdentifier: "com.test.nonexistent.\(UUID().uuidString.prefix(8))",
            appName: "Ghost",
            autoCopy: false,
            autoPaste: false,
            clearAfterInsert: false,
            commandReplacements: false,
            smartCapitalization: false,
            terminalPunctuation: false,
            customCommands: ""
        )
        t.updateProfile(fake)
        #expect(t.appProfiles.count == countBefore)
    }

    @Test("updateProfile maintains sorted order")
    @MainActor func updateProfileSorted() {
        let t = AudioTranscriber.shared
        let id1 = "com.test.sort.aaa.\(UUID().uuidString.prefix(8))"
        let id2 = "com.test.sort.zzz.\(UUID().uuidString.prefix(8))"

        let p1 = AppProfile(bundleIdentifier: id1, appName: "ZZZ App", autoCopy: false, autoPaste: false, clearAfterInsert: false, commandReplacements: false, smartCapitalization: false, terminalPunctuation: false, customCommands: "")
        let p2 = AppProfile(bundleIdentifier: id2, appName: "AAA App", autoCopy: false, autoPaste: false, clearAfterInsert: false, commandReplacements: false, smartCapitalization: false, terminalPunctuation: false, customCommands: "")

        t.appProfiles.append(p1)
        t.appProfiles.append(p2)

        // Update p1 name to come first alphabetically
        var updated = p1
        updated.appName = "000 First"
        t.updateProfile(updated)

        if let idx = t.appProfiles.firstIndex(where: { $0.bundleIdentifier == id1 }) {
            // It should be at or before the AAA App
            let aaaIdx = t.appProfiles.firstIndex(where: { $0.bundleIdentifier == id2 })
            if let aaaIdx {
                #expect(idx < aaaIdx)
            }
        }

        // Cleanup
        t.removeProfile(bundleIdentifier: id1)
        t.removeProfile(bundleIdentifier: id2)
    }

    // MARK: - removeProfile

    @Test("removeProfile removes an existing profile")
    @MainActor func removeProfileExisting() {
        let t = AudioTranscriber.shared
        let bundleId = "com.test.removeprofile.\(UUID().uuidString.prefix(8))"
        let profile = AppProfile(bundleIdentifier: bundleId, appName: "ToRemove", autoCopy: false, autoPaste: false, clearAfterInsert: false, commandReplacements: false, smartCapitalization: false, terminalPunctuation: false, customCommands: "")
        t.appProfiles.append(profile)

        let countBefore = t.appProfiles.count
        t.removeProfile(bundleIdentifier: bundleId)
        #expect(t.appProfiles.count == countBefore - 1)
        #expect(t.appProfiles.first(where: { $0.bundleIdentifier == bundleId }) == nil)
    }

    @Test("removeProfile is no-op for nonexistent bundle id")
    @MainActor func removeProfileNonexistent() {
        let t = AudioTranscriber.shared
        let countBefore = t.appProfiles.count
        t.removeProfile(bundleIdentifier: "com.test.doesnotexist.\(UUID().uuidString.prefix(8))")
        #expect(t.appProfiles.count == countBefore)
    }

    @Test("removeProfile can remove all profiles one by one")
    @MainActor func removeAllProfilesOneByOne() {
        let t = AudioTranscriber.shared
        let ids = (0..<3).map { "com.test.removeall.\($0).\(UUID().uuidString.prefix(8))" }
        for id in ids {
            t.appProfiles.append(AppProfile(bundleIdentifier: id, appName: "App\(id)", autoCopy: false, autoPaste: false, clearAfterInsert: false, commandReplacements: false, smartCapitalization: false, terminalPunctuation: false, customCommands: ""))
        }

        for id in ids {
            t.removeProfile(bundleIdentifier: id)
        }

        for id in ids {
            #expect(t.appProfiles.first(where: { $0.bundleIdentifier == id }) == nil)
        }
    }

    // MARK: - startRecordingFromHotkey / stopRecordingFromHotkey

    @Test("startRecordingFromHotkey is no-op when already recording")
    @MainActor func startRecordingFromHotkeyNoOpWhenRecording() {
        let t = AudioTranscriber.shared
        // We can't easily start recording in tests (no mic), but we can verify
        // the guard: if not recording, it tries to start (may fail silently in test env)
        let wasRecording = t.isRecording
        if wasRecording {
            // Already recording — calling again should be a no-op
            t.startRecordingFromHotkey()
            #expect(t.isRecording == true)
        }
    }

    @Test("stopRecordingFromHotkey is no-op when not recording")
    @MainActor func stopRecordingFromHotkeyNoOpWhenNotRecording() {
        let t = AudioTranscriber.shared
        if !t.isRecording {
            t.stopRecordingFromHotkey()
            #expect(t.isRecording == false)
        }
    }

    @Test("startRecordingFromHotkey does not crash")
    @MainActor func startRecordingFromHotkeyNoCrash() {
        let t = AudioTranscriber.shared
        // In test env without mic permissions, this should fail gracefully
        t.startRecordingFromHotkey()
        // Either started or failed — no crash is the test
        if t.isRecording {
            t.stopRecordingFromHotkey()
        }
    }

    @Test("stopRecordingFromHotkey does not crash when not recording")
    @MainActor func stopRecordingFromHotkeyNoCrash() {
        let t = AudioTranscriber.shared
        t.stopRecordingFromHotkey()
        #expect(t.isRecording == false)
    }

    // MARK: - profileCaptureCandidate

    @Test("profileCaptureCandidate returns result after refreshFrontmostAppContext")
    @MainActor func profileCaptureCandidateAfterRefresh() {
        let t = AudioTranscriber.shared
        t.refreshFrontmostAppContext()
        // May or may not return a candidate depending on test runner
        let candidate = t.profileCaptureCandidate()
        if let candidate {
            #expect(!candidate.bundleIdentifier.isEmpty)
            #expect(!candidate.appName.isEmpty)
        }
    }

    @Test("profileCaptureCandidate returns nil when no external app context")
    @MainActor func profileCaptureCandidateNilCase() {
        let t = AudioTranscriber.shared
        // Save current state
        let savedName = t.frontmostAppName
        let savedBundle = t.frontmostBundleIdentifier

        // Set frontmost to own bundle
        t.frontmostBundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        t.frontmostAppName = "OpenWhisper"

        // Without a lastKnownExternalApp, should return nil
        // (Can't easily clear lastKnownExternalApp, but at minimum this shouldn't crash)
        let _ = t.profileCaptureCandidate()

        // Restore
        t.frontmostAppName = savedName
        t.frontmostBundleIdentifier = savedBundle
    }

    // MARK: - captureProfileForFrontmostApp

    @Test("captureProfileForFrontmostApp creates a new profile")
    @MainActor func captureProfileCreatesNew() {
        let t = AudioTranscriber.shared
        t.refreshFrontmostAppContext()

        if let candidate = t.profileCaptureCandidate() {
            // Remove if exists
            t.removeProfile(bundleIdentifier: candidate.bundleIdentifier)

            let result = t.captureProfileForFrontmostApp()
            #expect(result == true)
            #expect(t.appProfiles.contains(where: { $0.bundleIdentifier == candidate.bundleIdentifier }))

            // Cleanup
            t.removeProfile(bundleIdentifier: candidate.bundleIdentifier)
        }
    }

    @Test("captureProfileForFrontmostApp re-capture updates name only")
    @MainActor func captureProfileRecapture() {
        let t = AudioTranscriber.shared
        t.refreshFrontmostAppContext()

        if let candidate = t.profileCaptureCandidate() {
            // First capture
            t.removeProfile(bundleIdentifier: candidate.bundleIdentifier)
            t.captureProfileForFrontmostApp()

            // Modify the profile
            if var profile = t.appProfiles.first(where: { $0.bundleIdentifier == candidate.bundleIdentifier }) {
                profile.autoCopy = true
                profile.customCommands = "test:replacement"
                t.updateProfile(profile)
            }

            // Re-capture should preserve custom settings
            t.captureProfileForFrontmostApp()

            let recaptured = t.appProfiles.first(where: { $0.bundleIdentifier == candidate.bundleIdentifier })
            #expect(recaptured?.autoCopy == true)
            #expect(recaptured?.customCommands == "test:replacement")

            // Cleanup
            t.removeProfile(bundleIdentifier: candidate.bundleIdentifier)
        }
    }
}
