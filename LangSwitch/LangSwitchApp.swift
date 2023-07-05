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
        // IMPORTANT
        Settings {
            EmptyView().frame(width:.zero)
        }
    }
    
//    var body: some Scene {
//        EmptyView().frame(width: 0, height: 0)
//    }
}
