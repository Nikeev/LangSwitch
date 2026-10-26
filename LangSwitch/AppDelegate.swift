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
import IOKit.hid
import ServiceManagement


class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var aboutWindow: NSWindow?
    let longPressThreshold: TimeInterval = 0.2;
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // launch at login
        launchAtLogin()
        
        // Create a status bar item with a system icon
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem?.button?.image = NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
        statusBarItem?.isVisible = true
        
        // Add a menu to the status bar item
        let menu = NSMenu()
        menu.addItem(withTitle: "About LangSwitch", action: #selector(showAboutWindow), keyEquivalent: "")
        menu.addItem(withTitle: "Hide Icon", action: #selector(hideStatusBarIcon), keyEquivalent: "")
        menu.addItem(withTitle: "Exit", action: #selector(exitAction), keyEquivalent: "")
        statusBarItem?.menu = menu
        
        // hide menu bar if the button was pressed once
        let userDefaults = UserDefaults.standard
        if userDefaults.bool(forKey: "hideStatusBarIcon") {
            statusBarItem?.isVisible = false
        }
        
        NSApp.setActivationPolicy(.accessory)
        NSApp.hide(nil)
        
        var anotherClicked = false;
        var lastPressTime = Date();
        
        // Register for Fn button press events
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
            guard event.keyCode == 63 else {
                return
            }

            if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.function) {
                anotherClicked = false
                lastPressTime = Date()
            }

            if !event.modifierFlags.intersection([.shift, .control, .option, .command]).isEmpty {
                anotherClicked = true
            }

            let allowedFlags: NSEvent.ModifierFlags = [.capsLock]
            let remainingFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting(allowedFlags)
            if remainingFlags.isEmpty && !anotherClicked {
                let timePassed = Date().timeIntervalSince(lastPressTime)
                if timePassed < self.longPressThreshold {
                    self.switchKeyboardLanguage()
                }
            }
        }
    }
    
    @objc func showAboutWindow() {
        if aboutWindow == nil {
            let windowWidth: CGFloat = 300
            let windowHeight: CGFloat = 180
            
            let windowContent = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown version"

            let versionLabel = NSTextField(labelWithString: "LangSwitch v\(version)")
            versionLabel.frame = NSRect(x: (windowWidth - 150) / 2, y: 130, width: 150, height: 20)
            versionLabel.alignment = .center // Центрирование текста
            windowContent.addSubview(versionLabel)
            
            let gitHubButton = NSButton(title: "GitHub Page", target: self, action: #selector(openGitHub))
            gitHubButton.frame = NSRect(x: (windowWidth - 100) / 2, y: 90, width: 100, height: 30)
            windowContent.addSubview(gitHubButton)

            let checkUpdatesButton = NSButton(title: "Check for Updates", target: self, action: #selector(checkForUpdates))
            checkUpdatesButton.frame = NSRect(x: (windowWidth - 150) / 2, y: 50, width: 150, height: 30)
            windowContent.addSubview(checkUpdatesButton)

            aboutWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
                                   styleMask: [.titled, .closable],
                                   backing: .buffered,
                                   defer: false)
            aboutWindow?.contentView = windowContent
            aboutWindow?.center()
        }
        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func launchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    // do nothing
                    print("Login item already registered.")
                } else {
                    try SMAppService.mainApp.register()
                }
            } catch {
                print("Failed to enable login item: \(error)")
            }
        } else {
            // Fallback on earlier versions
            print("Login item functionality is not available on this version of macOS.")
        }
    }


    @objc func openGitHub() {
        if let url = URL(string: "https://github.com/Nikeev/LangSwitch") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func checkForUpdates() {
        guard let url = URL(string: "https://api.github.com/repos/Nikeev/LangSwitch/releases/latest") else { return }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                self.showAlert(message: "Failed to check for updates.")
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let latestVersion = json["tag_name"] as? String {
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"

                    if latestVersion > "v\(currentVersion)" {
                        self.showAlert(message: "New version \(latestVersion) is available! Download it from GitHub.")
                    } else {
                        self.showAlert(message: "You're up to date.")
                    }
                }
            } catch {
                self.showAlert(message: "Error parsing update information.")
            }
        }
        task.resume()
    }
    
    func showAlert(message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = message
            alert.runModal()
        }
    }
    
    @objc func hideStatusBarIcon() {
        statusBarItem?.isVisible = false
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "hideStatusBarIcon")
        UserDefaults.standard.synchronize()
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
        
        // Switching the input source makes macOS turn Caps Lock off, so restore it afterwards
        let capsLockWasOn = getCapsLockState()

        // Switch to the next input source
        TISSelectInputSource(nextSource)

        if capsLockWasOn {
            setCapsLockState(true)
        }

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

    func getCapsLockState() -> Bool {
        var state = false
        withHIDSystemConnection { connection in
            IOHIDGetModifierLockState(connection, Int32(kIOHIDCapsLockState), &state)
        }
        return state
    }

    func setCapsLockState(_ state: Bool) {
        withHIDSystemConnection { connection in
            IOHIDSetModifierLockState(connection, Int32(kIOHIDCapsLockState), state)
        }
    }

    func withHIDSystemConnection(_ body: (io_connect_t) -> Void) {
        // MACH_PORT_NULL selects the default main port and, unlike kIOMainPortDefault, works on macOS 11
        let service = IOServiceGetMatchingService(mach_port_t(MACH_PORT_NULL), IOServiceMatching(kIOHIDSystemClass))
        guard service != 0 else {
            print("Failed to find IOHIDSystem service.")
            return
        }
        defer { IOObjectRelease(service) }

        var connection: io_connect_t = 0
        let result = IOServiceOpen(service, mach_task_self_, UInt32(kIOHIDParamConnectType), &connection)
        guard result == KERN_SUCCESS else {
            print("Failed to open IOHIDSystem connection: \(result)")
            return
        }
        defer { IOServiceClose(connection) }

        body(connection)
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
