import Testing
import Foundation
@testable import OpenWhisper

@Suite("ContentView extracted logic (ViewHelpers)")
struct ContentViewExtractedTests {

    // MARK: - insertButtonTitle

    @Test("cannot insert directly returns Copy → Clipboard")
    func titleCopyOnly() {
        #expect(ViewHelpers.insertButtonTitle(
            canInsertDirectly: false, insertTargetAppName: "Safari",
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: nil
        ) == "Copy → Clipboard")
    }

    @Test("can insert with target shows Insert → target")
    func titleInsertTarget() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: "Safari",
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: nil
        )
        #expect(title == "Insert → Safari")
    }

    @Test("fallback target shows (recent)")
    func titleFallbackTarget() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: "Safari",
            insertTargetUsesFallback: true, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: nil
        )
        #expect(title.contains("(recent)"))
    }

    @Test("retarget suggested shows warning")
    func titleRetargetWarning() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: "Safari",
            insertTargetUsesFallback: false, shouldSuggestRetarget: true,
            isInsertTargetStale: false, liveFrontAppName: nil
        )
        #expect(title.contains("⚠︎"))
    }

    @Test("stale target shows warning")
    func titleStaleWarning() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: "Safari",
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: true, liveFrontAppName: nil
        )
        #expect(title.contains("⚠︎"))
    }

    @Test("no target but live front app shows Insert → frontApp")
    func titleLiveFrontApp() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: nil,
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: "Notes"
        )
        #expect(title == "Insert → Notes")
    }

    @Test("no target no front app shows Copy → Clipboard")
    func titleNoTargetNoFront() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: nil,
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: nil
        )
        #expect(title == "Copy → Clipboard")
    }

    @Test("empty target name treated as no target")
    func titleEmptyTarget() {
        let title = ViewHelpers.insertButtonTitle(
            canInsertDirectly: true, insertTargetAppName: "",
            insertTargetUsesFallback: false, shouldSuggestRetarget: false,
            isInsertTargetStale: false, liveFrontAppName: "Notes"
        )
        #expect(title == "Insert → Notes")
    }

    // MARK: - insertButtonHelpText

    @Test("disabled reason prepended")
    func helpDisabledReason() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: "Stop recording",
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: nil, insertTargetUsesFallback: false, currentFrontAppName: nil
        )
        #expect(help == "Stop recording before inserting")
    }

    @Test("no accessibility with target")
    func helpNoAccessibilityWithTarget() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: false, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: "Safari", insertTargetUsesFallback: false, currentFrontAppName: nil
        )
        #expect(help.contains("Accessibility permission is missing"))
        #expect(help.contains("Safari"))
    }

    @Test("no accessibility without target")
    func helpNoAccessibilityNoTarget() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: false, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: nil, insertTargetUsesFallback: false, currentFrontAppName: nil
        )
        #expect(help.contains("copy transcription to clipboard"))
    }

    @Test("copy because target unknown")
    func helpCopyBecauseUnknown() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: true,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: nil, insertTargetUsesFallback: false, currentFrontAppName: nil
        )
        #expect(help.contains("No destination app"))
    }

    @Test("retarget suggested shows both apps")
    func helpRetargetSuggested() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: true, isInsertTargetStale: false,
            insertTargetAppName: "Safari", insertTargetUsesFallback: false, currentFrontAppName: "Notes"
        )
        #expect(help.contains("Notes"))
        #expect(help.contains("Safari"))
        #expect(help.contains("Retarget"))
    }

    @Test("stale target shows warning")
    func helpStaleTarget() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: true,
            insertTargetAppName: "Safari", insertTargetUsesFallback: false, currentFrontAppName: nil
        )
        #expect(help.contains("captured a while ago"))
    }

    @Test("fallback target shows captured context")
    func helpFallbackTarget() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: "Safari", insertTargetUsesFallback: true, currentFrontAppName: nil
        )
        #expect(help.contains("recent app context"))
    }

    @Test("normal insert shows target name")
    func helpNormalInsert() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: "Safari", insertTargetUsesFallback: false, currentFrontAppName: nil
        )
        #expect(help == "Insert into Safari")
    }

    @Test("no target with live front app")
    func helpNoTargetWithFront() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: nil, insertTargetUsesFallback: false, currentFrontAppName: "Notes"
        )
        #expect(help == "Insert into Notes")
    }

    @Test("no target no front app")
    func helpNoTargetNoFront() {
        let help = ViewHelpers.insertButtonHelpText(
            insertActionDisabledReason: nil,
            canInsertDirectly: true, shouldCopyBecauseTargetUnknown: false,
            shouldSuggestRetarget: false, isInsertTargetStale: false,
            insertTargetAppName: nil, insertTargetUsesFallback: false, currentFrontAppName: nil
        )
        #expect(help == "Insert into the last active app")
    }
}
