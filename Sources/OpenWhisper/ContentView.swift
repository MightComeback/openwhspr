//
//  ContentView.swift
//  OpenWhisper
//
//  Placeholder content.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "mic.fill")
                .imageScale(.large)
                .foregroundStyle(.tertiary)
            
            Text("OpenWhisper")
                .font(.title2)
            
            Text("Ready for dictation.")
                .foregroundStyle(.secondary)
                .padding(.top)
        }
        .padding()
        .frame(width: 200)
    }
}

#Preview {
    ContentView()
}
