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


class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusBarItem: NSStatusItem?
    var aboutWindow: NSWindow?
    var launchAtLoginMenuItem: NSMenuItem?
    let longPressThreshold: TimeInterval = 0.2
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create a status bar item with a system icon
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem?.button?.image = NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
        statusBarItem?.isVisible = true
        
        // Add a menu to the status bar item
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(withTitle: "About LangSwitch", action: #selector(showAboutWindow), keyEquivalent: "")
        menu.addItem(.separator())
        launchAtLoginMenuItem = menu.addItem(withTitle: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginMenuItem?.target = self
        refreshLaunchAtLoginMenuItem()
        menu.addItem(.separator())
        menu.addItem(withTitle: "Exit", action: #selector(exitAction), keyEquivalent: "")
        statusBarItem?.menu = menu

        NSApp.setActivationPolicy(.accessory)
        NSApp.hide(nil)
        
        var anotherClicked = false
        var lastPressTime = Date()
        
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
    
    func menuWillOpen(_ menu: NSMenu) {
        refreshLaunchAtLoginMenuItem()
    }

    func refreshLaunchAtLoginMenuItem() {
        guard let item = launchAtLoginMenuItem else {
            return
        }

        if #available(macOS 13.0, *) {
            switch SMAppService.mainApp.status {
            case .enabled:
                item.title = "Launch at Login"
                item.state = .on
                item.isEnabled = true
            case .notRegistered:
                item.title = "Launch at Login"
                item.state = .off
                item.isEnabled = true
            case .requiresApproval:
                item.title = "Launch at Login (Needs Approval)"
                item.state = .mixed
                item.isEnabled = true
            case .notFound:
                item.title = "Launch at Login (Unavailable)"
                item.state = .off
                item.isEnabled = false
            @unknown default:
                item.title = "Launch at Login (Unknown)"
                item.state = .off
                item.isEnabled = false
            }
        } else {
            item.title = "Launch at Login (Requires macOS 13)"
            item.state = .off
            item.isEnabled = false
        }
    }

    @objc func toggleLaunchAtLogin() {
        guard #available(macOS 13.0, *) else {
            showAlert(message: "Launch at Login requires macOS 13 or later.")
            return
        }

        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
            refreshLaunchAtLoginMenuItem()
        } catch {
            refreshLaunchAtLoginMenuItem()
            showAlert(message: "Failed to update Launch at Login: \(error.localizedDescription)")
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

                    guard let latest = SemanticVersion(latestVersion),
                          let current = SemanticVersion(currentVersion) else {
                        self.showAlert(message: "Unable to compare update versions.")
                        return
                    }

                    if latest > current {
                        self.showAlert(message: "New version \(latestVersion) is available! Download it from GitHub.")
                    } else {
                        self.showAlert(message: "You're up to date.")
                    }
                } else {
                    self.showAlert(message: "Error parsing update information.")
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
        let inputSources = getInputSources()
        guard !inputSources.isEmpty else {
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
        let newSourceName = nextSource.localizedName ?? "Unknown input source"
        print("Switched to: \(newSourceName)")
    }
    
    func getInputSources() -> [TISInputSource] {
        let inputSourceNSArray = TISCreateInputSourceList(nil, false)
            .takeRetainedValue() as NSArray
        let inputSourceList = inputSourceNSArray.compactMap { $0 as? TISInputSource }
        
        return inputSourceList.filter {
            $0.category == TISInputSource.Category.keyboardInputSource && $0.isSelectable
        }
    }
}

private struct SemanticVersion: Comparable {
    private let components: [Int]

    init?(_ string: String) {
        var core = string.trimmingCharacters(in: .whitespacesAndNewlines)

        if let firstCharacter = core.first,
           firstCharacter == "v" || firstCharacter == "V" {
            core.removeFirst()
        }

        if let suffixIndex = core.firstIndex(where: { $0 == "-" || $0 == "+" }) {
            core = String(core[..<suffixIndex])
        }

        let parsedComponents = core.split(separator: ".").map { Int($0) }

        guard !parsedComponents.isEmpty, parsedComponents.allSatisfy({ $0 != nil }) else {
            return nil
        }

        components = parsedComponents.compactMap { $0 }
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let componentCount = max(lhs.components.count, rhs.components.count)

        for index in 0..<componentCount {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0

            if left != right {
                return left < right
            }
        }

        return false
    }
}

extension TISInputSource {
    enum Category {
        static var keyboardInputSource: String {
            return kTISCategoryKeyboardInputSource as String
        }
    }
    
    private func getProperty(_ key: CFString) -> AnyObject? {
        guard let cfType = TISGetInputSourceProperty(self, key) else {
            return nil
        }

        return Unmanaged<AnyObject>.fromOpaque(cfType).takeUnretainedValue()
    }
    
    var category: String? {
        return getProperty(kTISPropertyInputSourceCategory) as? String
    }
    
    var isSelectable: Bool {
        return getProperty(kTISPropertyInputSourceIsSelectCapable) as? Bool ?? false
    }

    var localizedName: String? {
        return getProperty(kTISPropertyLocalizedName) as? String
    }
}
