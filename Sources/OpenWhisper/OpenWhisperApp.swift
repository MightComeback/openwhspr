// OpenWhisperApp.swift
// Basic menu bar app structure for OpenWhisper

import SwiftUI

@main
struct OpenWhisperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "🎤"
        statusItem?.button?.action = #selector(toggleDictation)
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Start Dictation", action: #selector(startDictation), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Stop Dictation", action: #selector(stopDictation), keyEquivalent: "e"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc func toggleDictation() {
        // Placeholder for global hotkey toggle
        print("Toggle dictation")
    }

    @objc func startDictation() {
        print("Start dictation")
    }

    @objc func stopDictation() {
        print("Stop dictation")
    }
}