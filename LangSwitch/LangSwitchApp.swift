//
//  LangSwitchApp.swift
//  LangSwitch
//
//  Created by ANTON NIKEEV on 05.07.2023.
//

import SwiftUI

@main
struct LangSwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView().frame(width:.zero)
        }
    }
}
