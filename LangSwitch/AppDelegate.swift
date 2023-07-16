//
//  ContentView.swift
//  LangSwitch
//
//  Created by ANTON NIKEEV on 05.07.2023.
//

import SwiftUI
import Carbon
import Foundation
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create a status bar item with a system icon
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem?.button?.image = NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
        
        // Add a menu to the status bar item
        let menu = NSMenu()
        menu.addItem(withTitle: "Exit", action: #selector(exitAction), keyEquivalent: "")
        statusBarItem?.menu = menu
        
        NSApp.setActivationPolicy(.accessory)
        NSApp.hide(nil)
        
        // Register for Fn button press events
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
            if event.modifierFlags.contains(.function) {
                // Call the function to handle "Fn" button press
                self.switchKeyboardLanguage()
            }
        }
    }
    
    @objc func exitAction() {
        NSApplication.shared.terminate(nil)
    }
    
    func switchKeyboardLanguage() {
        // Get the current keyboard input source
        guard let currentSource = TISCopyCurrentKeyboardInputSource()?.takeUnretainedValue() else {
            print("Failed to switch keyboard language.")
            return
        }
        
        // Get all enabled keyboard input sources
        guard let inputSources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource],
              !inputSources.isEmpty else {
            print("Failed to switch keyboard language.")
            return
        }
        
        // Find the index of the current input source
        guard let currentIndex = inputSources.firstIndex(where: { $0 == currentSource }) else {
            print("Failed to switch keyboard language.")
            return
        }
        
        // Calculate the index of the next input source
        var nextIndex = (currentIndex + 1) % inputSources.count
        
        // Skip the emoji keyboard
        while let nextSource = inputSources[nextIndex] as TISInputSource? {
            let sourceName = Unmanaged<CFString>.fromOpaque(TISGetInputSourceProperty(nextSource, kTISPropertyLocalizedName)).takeUnretainedValue() as String
            if sourceName != "Emoji & Symbols" && sourceName != "com.apple.PressAndHold" {
                break
            }
            nextIndex = (nextIndex + 1) % inputSources.count
        }
        
        // Retrieve the next input source
        let nextSource = inputSources[nextIndex] as! TISInputSource
        
        // Switch to the next input source
        TISSelectInputSource(nextSource)
        
        // Print the new input source's name
        let newSourceName = Unmanaged<CFString>.fromOpaque(TISGetInputSourceProperty(nextSource, kTISPropertyLocalizedName)).takeUnretainedValue() as String
        print("Switched to: \(newSourceName)")
    }
}
