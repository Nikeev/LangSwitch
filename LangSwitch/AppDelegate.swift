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
    let longPressThreshold: TimeInterval = 0.2;
    
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
        
        var anotherClicked = false;
        var lastPressTime = Date();
        
        // Register for Fn button press events
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
            if (event.keyCode == 63 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.function)) {
                anotherClicked = false;
                lastPressTime = Date();
            }
            
            if (!event.modifierFlags.intersection([.shift, .control, .option, .command]).isEmpty) {
                anotherClicked = true;
            }

            if (event.keyCode == 63 &&
                !anotherClicked &&
                event.modifierFlags.intersection(.deviceIndependentFlagsMask) == []) {
                var timePassed = Date().timeIntervalSince(lastPressTime);
                if (timePassed < self.longPressThreshold) {
                    self.switchKeyboardLanguage();
                }
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
        guard let inputSources = getInputSources() as? [TISInputSource],
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
        let nextIndex = (currentIndex + 1) % inputSources.count
        
        // Retrieve the next input source
        let nextSource = inputSources[nextIndex]
        
        // Switch to the next input source
        TISSelectInputSource(nextSource)
        
        // Print the new input source's name
        let newSourceName = Unmanaged<CFString>.fromOpaque(TISGetInputSourceProperty(nextSource, kTISPropertyLocalizedName)).takeUnretainedValue() as String
        print("Switched to: \(newSourceName)")
    }
    
    func getInputSources() -> [TISInputSource] {
        let inputSourceNSArray = TISCreateInputSourceList(nil, false)
            .takeRetainedValue() as NSArray
        var inputSourceList = inputSourceNSArray as! [TISInputSource]
        
        inputSourceList = inputSourceList.filter({
            $0.category == TISInputSource.Category.keyboardInputSource
        })
        
        let inputSources = inputSourceList.filter(
            {
                $0.isSelectable
            })
        
        return inputSources
    }
}

extension TISInputSource {
    enum Category {
        static var keyboardInputSource: String {
            return kTISCategoryKeyboardInputSource as String
        }
    }
    
    private func getProperty(_ key: CFString) -> AnyObject? {
        let cfType = TISGetInputSourceProperty(self, key)
        if (cfType != nil) {
            return Unmanaged<AnyObject>.fromOpaque(cfType!)
                .takeUnretainedValue()
        } else {
            return nil
        }
    }
    
    var category: String {
        return getProperty(kTISPropertyInputSourceCategory) as! String
    }
    
    var isSelectable: Bool {
        return getProperty(kTISPropertyInputSourceIsSelectCapable) as! Bool
    }
}
