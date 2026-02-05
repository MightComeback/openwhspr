import SwiftUI

@main
struct OpenWhisperApp: App {
    @StateObject private var transcriber = AudioTranscriber()

    var body: some Scene {
        WindowGroup {
            ContentView(transcriber: transcriber)
        }
    }
}
