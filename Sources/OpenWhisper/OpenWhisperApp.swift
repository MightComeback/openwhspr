//
//  OpenWhisperApp.swift
//  OpenWhisper
//
//  Basic menu bar SwiftUI app scaffold.
//

import SwiftUI

@main
struct OpenWhisperApp: App {
    var body: some Scene {
        MenuBarExtra("OpenWhisper", systemImage: "mic.fill") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
