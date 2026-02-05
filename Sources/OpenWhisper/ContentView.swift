import SwiftUI

struct ContentView: View {
    @ObservedObject var transcriber: AudioTranscriber
    @StateObject private var hotkeyMonitor: HotkeyMonitor

    init(transcriber: AudioTranscriber) {
        self.transcriber = transcriber
        _hotkeyMonitor = StateObject(wrappedValue: HotkeyMonitor {
            transcriber.toggleRecording()
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("OpenWhisper")
                .font(.system(size: 28, weight: .bold))

            TextField("Transcription", text: $transcriber.transcription, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(6, reservesSpace: true)

            HStack(spacing: 12) {
                Button(transcriber.isRecording ? "Stop" : "Start") {
                    transcriber.toggleRecording()
                }
                .keyboardShortcut(.defaultAction)

                Text(transcriber.statusMessage)
                    .foregroundStyle(transcriber.isRecording ? .green : .secondary)

                Spacer()

                Text("Hotkey: ⌘⇧D")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Keyword highlight")
                    .font(.headline)

                HighlightedTextView(text: transcriber.transcription)
                    .frame(minHeight: 120, alignment: .topLeading)
                    .padding(8)
                    .background(.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if let errorMessage = transcriber.lastError {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .padding(20)
        .frame(minWidth: 640, minHeight: 420)
        .onAppear {
            hotkeyMonitor.start()
            transcriber.requestPermissions()
        }
    }
}

struct HighlightedTextView: View {
    private let keywords = ["urgent", "todo", "action", "whisper", "dictation"]
    let text: String

    var body: some View {
        Text(highlighted(text))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func highlighted(_ input: String) -> AttributedString {
        var attributed = AttributedString(input)
        let lowercased = input.lowercased()

        for keyword in keywords {
            var searchStart = lowercased.startIndex
            while let range = lowercased.range(of: keyword, options: [.caseInsensitive], range: searchStart..<lowercased.endIndex) {
                if let attrRange = Range(range, in: attributed) {
                    attributed[attrRange].backgroundColor = .yellow.opacity(0.4)
                    attributed[attrRange].foregroundColor = .primary
                }
                searchStart = range.upperBound
            }
        }

        return attributed
    }
}
