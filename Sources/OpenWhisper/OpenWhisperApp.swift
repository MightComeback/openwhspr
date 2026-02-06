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
    var hotkeyMonitor: HotkeyMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "🎤"
        statusItem?.button?.action = #selector(toggleDictation)
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Dictation", action: #selector(toggleDictation), keyEquivalent: "d"))
        menu.addItem(NSMenuItem.separator())
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu

        // Close any open windows to make it pure menu bar app
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApplication.shared.windows.forEach { window in
                if window.title != "Settings" {  // Keep settings open if somehow open
                    window.close()
                }
            }
        }

        AudioTranscriber.shared.requestPermissions()
        let hotkeyMonitor = HotkeyMonitor()
        hotkeyMonitor.setTranscriber(AudioTranscriber.shared)
        self.hotkeyMonitor = hotkeyMonitor
    }

    @objc func toggleDictation() {
        AudioTranscriber.shared.toggleRecording()
    }

    @MainActor @objc func openSettings() {
        let hostingController = NSHostingController(rootView: SettingsView(transcriber: AudioTranscriber.shared))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 420),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
}
