// ContentView.swift
// Placeholder UI for dictation status

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "mic")
                .font(.system(size: 50))
            Text("OpenWhisper")
                .font(.title)
            Text("Ready for dictation")
                .font(.headline)
            Button("Test") {
                print("Test clicked")
            }
        }
        .frame(width: 300, height: 200)
    }
}

#Preview {
    ContentView()
}